import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../data/uyir_data.dart';
import '../../data/mei_data.dart';
import '../../models/letter_model.dart';
import '../../models/letter_basket_game_model.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/mascot_widget.dart';

class LetterBasketGame extends StatefulWidget {
  final ProgressService progressService;
  final BasketGameMode mode;

  const LetterBasketGame({
    super.key,
    required this.progressService,
    this.mode = BasketGameMode.uyir,
  });

  @override
  State<LetterBasketGame> createState() => LetterBasketGameState();
}

class LetterBasketGameState extends State<LetterBasketGame>
    with TickerProviderStateMixin {
  // Public test helpers
  LetterModel get currentTarget => _currentTarget;
  List<FallingLetter> get fallingLetters => _fallingLetters;
  int get score => _score;
  bool get isGameOver => _isGameOver;
  bool get isGameCompleted => _isGameCompleted;
  void handleCorrectCatch(FallingLetter letter, double hitX, double hitY) => _handleCorrectCatch(letter, hitX, hitY);
  void handleWrongCatch(FallingLetter letter, double hitX, double hitY) => _handleWrongCatch(letter, hitX, hitY);
  // Services
  final AudioService _audioService = AudioService.instance;

  // Game Loop Ticker
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Game State
  late List<LetterModel> _letterPool;
  late List<LetterModel> _roundQueue;
  int _currentRoundIndex = 0;
  int _score = 0;
  int _correctCatches = 0;
  int _hearts = 3;
  bool _isGameOver = false;
  bool _isGameCompleted = false;
  bool _isMuted = false;
  bool _isRoundTransitioning = false;

  // Basket Physics & Positioning
  double _basketXFraction = 0.5; // 0.0 (left) to 1.0 (right)
  final double _basketWidth = 120.0;
  final double _basketHeight = 78.0;
  final double _letterSize = 64.0;

  // Active Falling Letters in Current Wave
  final List<FallingLetter> _fallingLetters = [];
  int _nextLetterId = 0;
  final Random _rng = Random();

  // Feedback & Micro-Animations
  String? _feedbackText;
  Color _feedbackColor = AppColors.mintGreen;
  Offset? _feedbackPosition;
  double _feedbackOpacity = 0.0;

  // Basket Shake Animation
  late AnimationController _basketShakeController;
  late Animation<double> _basketShakeAnim;

  // Score Bump Animation
  late AnimationController _scoreBumpController;
  late Animation<double> _scoreBumpAnim;

  // Particle Effects for Confetti / Sparkles
  final List<_Particle> _particles = [];

  // Color Palette for Letters
  static const List<Color> _bubbleColors = [
    Color(0xFFFFE8D6),
    Color(0xFFE8F5E9),
    Color(0xFFE1F5FE),
    Color(0xFFFFF3E0),
    Color(0xFFF3E5F5),
    Color(0xFFFFFDE7),
  ];

  static const List<Color> _bubbleBorders = [
    Color(0xFFFF8A65),
    Color(0xFF4CAF50),
    Color(0xFF03A9F4),
    Color(0xFFFF9800),
    Color(0xFFAB47BC),
    Color(0xFFFFC107),
  ];

  @override
  void initState() {
    super.initState();
    _isMuted = _audioService.isMuted;

    _initAnimations();
    _setupGameData();

    // Start 60fps Game Engine Ticker
    _ticker = createTicker(_onTick)..start();

    // Play pronunciation of initial target letter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playTargetSound();
    });
  }

  void _initAnimations() {
    _basketShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _basketShakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_basketShakeController);

    _scoreBumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scoreBumpAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _scoreBumpController, curve: Curves.elasticOut),
    );
  }

  void _setupGameData() {
    if (widget.mode == BasketGameMode.mei) {
      _letterPool = List<LetterModel>.from(meiLettersList);
    } else {
      _letterPool = List<LetterModel>.from(uyirLettersList);
    }

    // Select 10 distinct rounds from the letter pool (guarantees different targets)
    _roundQueue = List<LetterModel>.from(_letterPool)..shuffle(_rng);
    if (_roundQueue.length > 10) {
      _roundQueue = _roundQueue.sublist(0, 10);
    }

    _currentRoundIndex = 0;
    _score = 0;
    _correctCatches = 0;
    _hearts = 3;
    _isGameOver = false;
    _isGameCompleted = false;
    _isRoundTransitioning = false;
    _fallingLetters.clear();
    _particles.clear();

    _spawnWaveForCurrentRound();
  }

  LetterModel get _currentTarget => _roundQueue[_currentRoundIndex];

  void _playTargetSound() {
    if (!mounted || _isMuted) return;
    _audioService.playLetterSound(
      context,
      letter: _currentTarget.letter,
      word: _currentTarget.word,
      audioPath: _currentTarget.audioPath,
      showIndicator: true,
    );
  }

  /// Spawns a guaranteed wave containing the target letter and distinct distractors
  void _spawnWaveForCurrentRound() {
    _fallingLetters.clear();
    final target = _currentTarget;

    // Pick 4 unique distractor letters from pool (excluding target)
    final otherLetters = _letterPool.where((l) => l.letter != target.letter).toList()..shuffle(_rng);
    final distractorsCount = min(4, otherLetters.length);
    final selectedDistractors = otherLetters.take(distractorsCount).toList();

    // Wave contains target + unique distractors (all letters are distinct!)
    final waveLetters = [target, ...selectedDistractors]..shuffle(_rng);

    // Calculate distinct non-overlapping horizontal lanes
    final count = waveLetters.length;
    final List<double> lanes = [];
    for (int i = 0; i < count; i++) {
      final baseLane = 0.14 + (i * (0.72 / max(1, count - 1)));
      final jitter = (_rng.nextDouble() - 0.5) * 0.03;
      lanes.add((baseLane + jitter).clamp(0.12, 0.88));
    }
    lanes.shuffle(_rng);

    // Base falling speed scales smoothly with round index
    final double baseSpeed = 125.0 + (_currentRoundIndex * 7.0);

    for (int i = 0; i < waveLetters.length; i++) {
      final letterData = waveLetters[i];
      final colorIdx = _rng.nextInt(_bubbleColors.length);

      // Cascade / stagger vertical drop positions so letters do not overlap
      final double startY = -_letterSize - (i * 70.0) - (_rng.nextDouble() * 25.0);
      final double speed = baseSpeed + (_rng.nextDouble() * 25.0);

      _fallingLetters.add(
        FallingLetter(
          id: _nextLetterId++,
          letter: letterData.letter,
          word: letterData.word,
          isTarget: letterData.letter == target.letter,
          x: lanes[i],
          y: startY,
          speed: speed,
          wobbleOffset: _rng.nextDouble() * 2 * pi,
          bubbleColor: _bubbleColors[colorIdx],
          borderColor: _bubbleBorders[colorIdx],
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (_isGameOver || _isGameCompleted) {
      _updateParticles(dt);
      _fadeFeedback(dt);
      setState(() {});
      return;
    }

    _updateGame(dt);
    setState(() {});
  }

  void _updateGame(double dt) {
    if (_isRoundTransitioning) {
      _updateParticles(dt);
      _fadeFeedback(dt);
      return;
    }

    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Basket top coordinate
    final basketTop = screenHeight - 145.0;
    final basketLeft = (_basketXFraction * screenWidth) - (_basketWidth / 2);
    final basketRight = basketLeft + _basketWidth;

    bool hasTargetInWave = false;

    // Check collisions and positions safely from back to front
    for (int i = _fallingLetters.length - 1; i >= 0; i--) {
      final item = _fallingLetters[i];
      if (item.isCaught) continue;

      item.y += item.speed * dt;

      final letterCenterPixelX = item.x * screenWidth;
      final letterBottom = item.y + _letterSize;
      final letterTop = item.y;

      // Check Collision with Basket
      final overlapsX = (letterCenterPixelX + (_letterSize / 2) >= basketLeft + 15) &&
          (letterCenterPixelX - (_letterSize / 2) <= basketRight - 15);
      final overlapsY = (letterBottom >= basketTop) && (letterTop <= basketTop + 25);

      if (overlapsX && overlapsY) {
        item.isCaught = true;
        if (item.isTarget) {
          // Immediately remove caught letter and handle correct catch
          _fallingLetters.removeAt(i);
          _handleCorrectCatch(item, letterCenterPixelX, basketTop);
          return; // Exit update cycle immediately as round transition commences
        } else {
          // Wrong letter caught: remove ONLY this letter, continue game smoothly
          _fallingLetters.removeAt(i);
          _handleWrongCatch(item, letterCenterPixelX, basketTop);
          continue;
        }
      }

      // Check if letter fell past screen bottom
      if (item.y > screenHeight + 40) {
        _fallingLetters.removeAt(i);
      } else {
        if (item.isTarget) {
          hasTargetInWave = true;
        }
      }
    }

    // If target letter fell off screen without being caught or wave is exhausted, respawn wave for same target!
    if (!hasTargetInWave && !_isRoundTransitioning && !_isGameOver && !_isGameCompleted) {
      _spawnWaveForCurrentRound();
    }

    _updateParticles(dt);
    _fadeFeedback(dt);
  }

  void _handleCorrectCatch(FallingLetter letter, double hitX, double hitY) {
    if (_isRoundTransitioning) return;
    _isRoundTransitioning = true;

    // 1. Update score & feedback
    _score += 10;
    _correctCatches++;
    _scoreBumpController.forward(from: 0.0);

    // 2. Trigger Confetti & Sparkles
    _spawnConfetti(hitX, hitY);

    // 3. Cheerful Audio Feedback
    _audioService.playSuccessFeedback(context);
    _audioService.playLetterSound(
      context,
      letter: letter.letter,
      word: letter.word,
      showIndicator: false,
    );

    // 4. Positive Tamil Praise
    const praises = ['சூப்பர்! 🎉', 'அற்புதம்! 🌟', 'சபாஷ்! ✨', 'மிக நன்று! 👏'];
    _showFeedback(praises[_rng.nextInt(praises.length)], AppColors.mintGreen, Offset(hitX, hitY - 40));

    // 5. Clean, automatic transition to the next round after brief celebration
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      _advanceToNextRound();
    });
  }

  void _handleWrongCatch(FallingLetter letter, double hitX, double hitY) {
    // Basket gentle shake animation
    _basketShakeController.forward(from: 0.0);
    _audioService.playLetterSound(
      context,
      letter: letter.letter,
      word: letter.word,
      showIndicator: false,
    );
    _audioService.playRetryFeedback(context);

    // Gentle encouraging message without ending or freezing the game
    _showFeedback('மீண்டும் முயற்சி செய்! 😊', AppColors.playfulPink, Offset(hitX, hitY - 40));
  }

  void _advanceToNextRound() {
    _fallingLetters.clear();

    if (_currentRoundIndex + 1 < _roundQueue.length) {
      _currentRoundIndex++;
      _isRoundTransitioning = false;
      _spawnWaveForCurrentRound();
      _playTargetSound();
      setState(() {});
    } else {
      // Completed all 10 rounds!
      _isGameCompleted = true;
      _isRoundTransitioning = false;
      _ticker.stop();
      _audioService.playStarReward(context);

      // Award 1-3 stars based on score
      final stars = _score >= 80 ? 3 : (_score >= 50 ? 2 : 1);
      widget.progressService.recordGameCompleted(stars);

      // Full celebration confetti explosion
      final size = MediaQuery.of(context).size;
      _spawnConfetti(size.width * 0.5, size.height * 0.4, count: 50);
      setState(() {});
    }
  }

  void _spawnConfetti(double x, double y, {int count = 18}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80.0 + (_rng.nextDouble() * 200.0);
      _particles.add(
        _Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 60,
          color: [
            AppColors.sunnyYellow,
            AppColors.playfulPink,
            AppColors.skyBlue,
            AppColors.candyPurple,
            AppColors.mintGreen,
            Colors.white,
          ][_rng.nextInt(6)],
          size: 6.0 + (_rng.nextDouble() * 7.0),
          life: 1.0,
        ),
      );
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 220 * dt; // gravity
      p.life -= dt * 1.3;
      if (p.life <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  void _fadeFeedback(double dt) {
    if (_feedbackOpacity > 0.0) {
      _feedbackOpacity = max(0.0, _feedbackOpacity - (dt * 1.5));
    }
  }

  void _showFeedback(String text, Color color, Offset position) {
    setState(() {
      _feedbackText = text;
      _feedbackColor = color;
      _feedbackPosition = position;
      _feedbackOpacity = 1.0;
    });
  }

  void _restartGame() {
    setState(() {
      _setupGameData();
    });
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
    _playTargetSound();
  }

  @override
  void dispose() {
    _audioService.stopAll();
    _ticker.dispose();
    _basketShakeController.dispose();
    _scoreBumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE1F5FE), // Soft sky blue
              Color(0xFFFFF9C4), // Warm sunlight yellow
              Color(0xFFFCE4EC), // Gentle rose pink
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              setState(() {
                final deltaFrac = details.delta.dx / screenWidth;
                _basketXFraction = (_basketXFraction + deltaFrac).clamp(0.12, 0.88);
              });
            },
            child: Stack(
              children: [
                // 1. Floating Background Clouds & Decorative Stars
                const _BackgroundDecorations(),

                // 2. Falling Tamil Letters
                ..._fallingLetters.map((letter) {
                  return Positioned(
                    left: (letter.x * screenWidth) - (_letterSize / 2),
                    top: letter.y,
                    child: _buildLetterBubble(letter),
                  );
                }),

                // 3. Cute Cartoon Basket
                Positioned(
                  left: (_basketXFraction * screenWidth) - (_basketWidth / 2),
                  bottom: 30,
                  child: AnimatedBuilder(
                    animation: _basketShakeAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_basketShakeAnim.value, 0),
                        child: child,
                      );
                    },
                    child: _buildCuteBasket(),
                  ),
                ),

                // 4. Confetti & Sparkles
                CustomPaint(
                  painter: _ParticlePainter(_particles),
                  size: Size.infinite,
                ),

                // 5. In-Game Float Feedback Toast
                if (_feedbackText != null && _feedbackOpacity > 0.0)
                  Positioned(
                    left: (_feedbackPosition?.dx ?? screenWidth / 2) - 100,
                    top: _feedbackPosition?.dy ?? 200,
                    child: Opacity(
                      opacity: _feedbackOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _feedbackColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _feedbackText!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 6. Top Game HUD Bar & Instruction
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 6),
                      _buildTargetBanner(),
                    ],
                  ),
                ),

                // 7. Game Over / Friendly Retry Dialog
                if (_isGameOver) _buildGameOverOverlay(),

                // 8. Game Completed Celebration Dialog
                if (_isGameCompleted) _buildCompletionOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFE65100), size: 24),
              ),
            ),

            const SizedBox(width: 8),

            // Game Title Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧺', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    'எழுத்துக் கூடை',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 15,
                      color: const Color(0xFFBF360C),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Sound Toggle Button
            GestureDetector(
              onTap: () {
                setState(() {
                  _isMuted = !_isMuted;
                  _audioService.setMuted(_isMuted);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: const Color(0xFFF57F17),
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Hearts (Non-punishing attempt indicator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return Icon(
                    index < _hearts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: const Color(0xFFE91E63),
                    size: 18,
                  );
                }),
              ),
            ),

            const SizedBox(width: 8),

            // Score Badge
            ScaleTransition(
              scale: _scoreBumpAnim,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF7043), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Letter Target Badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                _currentTarget.letter,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Tamil Instruction Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentTarget.letter} எழுத்தைப் பிடி!',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD84315),
                  ),
                ),
                Text(
                  '${_currentTarget.word} (${_currentRoundIndex + 1}/${_roundQueue.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Pronunciation Speaker Icon
          BouncyButton(
            onPressed: _playTargetSound,
            scaleFactor: 0.9,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFFE65100),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterBubble(FallingLetter letter) {
    return Container(
      width: _letterSize,
      height: _letterSize,
      decoration: BoxDecoration(
        color: letter.bubbleColor,
        shape: BoxShape.circle,
        border: Border.all(color: letter.borderColor, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: letter.borderColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          const BoxShadow(
            color: Colors.white70,
            blurRadius: 4,
            offset: Offset(-2, -2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bubble light reflection highlight
          Positioned(
            top: 6,
            left: 10,
            child: Container(
              width: 14,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Tamil Letter Typography
          Text(
            letter.letter,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2E3440),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuteBasket() {
    return SizedBox(
      width: _basketWidth,
      height: _basketHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Basket Wicker Body with Gradient
          Container(
            width: _basketWidth,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF8F00), Color(0xFFE65100)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border.all(color: const Color(0xFFBF360C), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBF360C).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Basket Wicker Crosshatch Lines (Custom kid pattern)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WickerPatternPainter(),
                  ),
                ),
                // Cute Smiling Cartoon Face on Basket
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left Eye
                      _buildCartoonEye(),
                      const SizedBox(width: 24),
                      // Right Eye
                      _buildCartoonEye(),
                    ],
                  ),
                ),
                // Cute Smile
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF795548),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                // Rosy Cheeks
                Positioned(
                  bottom: 18,
                  left: 20,
                  child: Container(
                    width: 10,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF80AB).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  right: 20,
                  child: Container(
                    width: 10,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF80AB).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Basket Top Opening Rim
          Positioned(
            top: 8,
            child: Container(
              width: _basketWidth + 8,
              height: 14,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBF360C), width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartoonEye() {
    return Container(
      width: 11,
      height: 11,
      decoration: const BoxDecoration(
        color: Color(0xFF3E2723),
        shape: BoxShape.circle,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          margin: const EdgeInsets.only(top: 2, left: 2),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFFF8A65), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotWidget(
              pose: MascotPose.learn,
              size: MascotSize.small,
              customHeight: 100,
            ),
            const SizedBox(height: 12),
            const Text(
              'அற்புதம்! முயற்சி செய்வோம்!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFFD84315),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'மதிப்பெண்: $_score',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6D4C41),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: BouncyButton(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Text(
                          'வெளியேறு',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF455A64),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BouncyButton(
                    onPressed: _restartGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'மீண்டும் விளையாடு 🎮',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay() {
    final starsEarned = _score >= 80 ? 3 : (_score >= 50 ? 2 : 1);

    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFFFB300), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotWidget(
              pose: MascotPose.game,
              size: MascotSize.small,
              customHeight: 110,
              showGlow: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'வாழ்த்துகள்! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFBF360C),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'நீங்கள் சிறப்பாக விளையாடினீர்கள்!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 16),

            // Star Rating (1-3 stars)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final earned = index < starsEarned;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: earned ? const Color(0xFFFFF8E1) : const Color(0xFFECEFF1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: earned ? const Color(0xFFFFD54F) : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: earned ? const Color(0xFFFFB300) : Colors.grey.shade400,
                    size: 34,
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Stats Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('மதிப்பெண்', maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF795548))),
                        ),
                        const SizedBox(height: 2),
                        Text('$_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: Colors.orange.shade200),
                  Expanded(
                    child: Column(
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('பிடித்தவை', maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF795548))),
                        ),
                        const SizedBox(height: 2),
                        Text('$_correctCatches', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: Colors.orange.shade200),
                  Expanded(
                    child: Column(
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('நட்சத்திரம்', maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF795548))),
                        ),
                        const SizedBox(height: 2),
                        Text('+$starsEarned', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFF57F17))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: BouncyButton(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCFD8DC)),
                      ),
                      child: const Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'விளையாட்டுகள்',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF455A64),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BouncyButton(
                    onPressed: _restartGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'மீண்டும் விளையாடு',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Basket crosshatch texture painter
class _WickerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE65100).withValues(alpha: 0.25)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += 14) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
      canvas.drawLine(Offset(i + size.height, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Background clouds and decorations
class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 120,
            left: 20,
            child: _buildCloud(80, 44),
          ),
          Positioned(
            top: 170,
            right: 30,
            child: _buildCloud(100, 52),
          ),
          Positioned(
            top: 300,
            left: 40,
            child: _buildCloud(70, 38),
          ),
          Positioned(
            top: 220,
            left: 140,
            child: _buildSparkle(const Color(0xFFFFD54F), 18),
          ),
          Positioned(
            top: 140,
            right: 120,
            child: _buildSparkle(const Color(0xFFFF80AB), 16),
          ),
          Positioned(
            top: 380,
            right: 50,
            child: _buildSparkle(const Color(0xFF4FC3F7), 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCloud(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Widget _buildSparkle(Color color, double size) {
    return Icon(Icons.auto_awesome_rounded, color: color.withValues(alpha: 0.6), size: size);
  }
}

// Particle system for celebration & sparkles
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  final double size;
  double life;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
