import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../data/uyir_data.dart';
import '../../models/car_racing_game_model.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/mascot_widget.dart';

class CarRacingGame extends StatefulWidget {
  final ProgressService progressService;
  final RacingGameMode mode;

  const CarRacingGame({
    super.key,
    required this.progressService,
    this.mode = RacingGameMode.uyir,
  });

  @override
  State<CarRacingGame> createState() => CarRacingGameState();
}

class CarRacingGameState extends State<CarRacingGame>
    with TickerProviderStateMixin {
  // Services
  final AudioService _audioService = AudioService.instance;

  // Single Game Loop Ticker
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Round & Target Pools
  late List<RacingTarget> _targetPool;
  late List<RacingTarget> _roundQueue;
  int _currentRoundIndex = 0;
  int _score = 0;
  int _correctCatches = 0;
  bool _isGameOver = false;
  bool _isGameCompleted = false;
  bool _isMuted = false;
  bool _isRoundTransitioning = false;

  // Car Physics & Lane Management
  int _currentLane = 1; // 0: Left, 1: Center, 2: Right
  double _carAnimatedLane = 1.0; // Smooth visual interpolation
  double _carSteerTilt = 0.0; // Steering tilt angle in radians
  double _timeElapsed = 0.0;

  // Car Shake Animation for Wrong Items / Cones
  late AnimationController _carShakeController;
  late Animation<double> _carShakeAnim;

  // Score Bump Animation
  late AnimationController _scoreBumpController;
  late Animation<double> _scoreBumpAnim;

  // Road Scrolling State
  double _roadScrollOffset = 0.0;
  double _baseSpeed = 220.0; // Pixels per second
  double _speedModifier = 1.0;

  // Active Road Items
  final List<RacingRoadItem> _roadItems = [];
  int _nextItemId = 0;
  final Random _rng = Random();

  // Particle Effects (Confetti & Stars)
  final List<_RacingParticle> _particles = [];

  // Feedback Toasts
  String? _feedbackText;
  Color _feedbackColor = AppColors.mintGreen;
  double _feedbackOpacity = 0.0;

  // Color Palette for Items
  static const List<Color> _bubbleColors = [
    Color(0xFFFFE0B2),
    Color(0xFFE8F5E9),
    Color(0xFFE1F5FE),
    Color(0xFFFFF9C4),
    Color(0xFFF3E5F5),
    Color(0xFFFFCDD2),
  ];

  static const List<Color> _bubbleBorders = [
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFF03A9F4),
    Color(0xFFFBC02D),
    Color(0xFFAB47BC),
    Color(0xFFE91E63),
  ];

  // Public Test Helpers
  RacingTarget get currentTarget => _roundQueue[_currentRoundIndex];
  List<RacingRoadItem> get roadItems => _roadItems;
  int get score => _score;
  int get currentLane => _currentLane;
  bool get isGameCompleted => _isGameCompleted;

  void moveCarLeft() => _steerToLane(_currentLane - 1);
  void moveCarRight() => _steerToLane(_currentLane + 1);
  void setLane(int lane) => _steerToLane(lane);

  void handleCorrectCollection(RacingRoadItem item, double x, double y) =>
      _handleCorrectCatch(item, x, y);
  void handleWrongCollection(RacingRoadItem item) => _handleWrongCatch(item);

  @override
  void initState() {
    super.initState();
    _isMuted = _audioService.isMuted;

    _initAnimations();
    _setupGameData();

    // Start 60fps Ticker Loop
    _ticker = createTicker(_onTick)..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playTargetSound();
    });
  }

  void _initAnimations() {
    _carShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _carShakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_carShakeController);

    _scoreBumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scoreBumpAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _scoreBumpController, curve: Curves.elasticOut),
    );
  }

  void _setupGameData() {
    // Strictly Uyir Letters (12 vowels: அ, ஆ, இ, ஈ, உ, ஊ, எ, ஏ, ஐ, ஒ, ஓ, ஔ)
    _targetPool = uyirLettersList.map((u) {
      return RacingTarget(
        id: u.id,
        text: u.letter,
        clue: u.word,
        audioPath: u.audioPath,
        isWord: false,
      );
    }).toList();

    // Shuffle 10 distinct targets for 10 rounds
    _roundQueue = List<RacingTarget>.from(_targetPool)..shuffle(_rng);
    if (_roundQueue.length > 10) {
      _roundQueue = _roundQueue.sublist(0, 10);
    }

    _currentRoundIndex = 0;
    _score = 0;
    _correctCatches = 0;
    _currentLane = 1;
    _carAnimatedLane = 1.0;
    _isGameOver = false;
    _isGameCompleted = false;
    _isRoundTransitioning = false;
    _roadItems.clear();
    _particles.clear();

    _spawnWaveForCurrentRound();
  }

  void _steerToLane(int lane) {
    if (lane < 0 || lane > 2 || _isGameOver || _isGameCompleted) return;
    setState(() {
      _currentLane = lane;
    });
  }

  void _playTargetSound() {
    if (!mounted || _isMuted) return;
    final target = currentTarget;
    // Play genuine Tamil letter sound clearly without showing on-screen letter popup
    _audioService.playLetterSound(
      context,
      letter: target.text,
      audioPath: target.audioPath,
      showIndicator: false,
    );
  }

  /// Spawns 1 guaranteed target + distinct distractors across the 3 lanes
  void _spawnWaveForCurrentRound() {
    _roadItems.clear();
    final target = currentTarget;

    // Pick 2 distinct distractors from remaining pool (excluding target)
    final otherTargets = _targetPool.where((t) => t.text != target.text).toList()..shuffle(_rng);
    final distractors = otherTargets.take(2).toList();

    // Exactly 3 unique items for the 3 lanes (1 target + 2 distractors)
    final waveItems = [target, ...distractors]..shuffle(_rng);

    // Speed scales gently with round progression
    _baseSpeed = 220.0 + (_currentRoundIndex * 12.0);

    for (int lane = 0; lane < 3; lane++) {
      final itemData = waveItems[lane];
      final colorIdx = _rng.nextInt(_bubbleColors.length);

      // Add a slight obstacle (cone) or bonus star rarely in higher rounds
      final bool spawnCone = _currentRoundIndex >= 3 && _rng.nextDouble() < 0.18 && itemData.text != target.text;
      final bool spawnStar = _rng.nextDouble() < 0.12 && itemData.text != target.text;

      _roadItems.add(
        RacingRoadItem(
          id: _nextItemId++,
          text: spawnCone ? '🚧' : (spawnStar ? '⭐' : itemData.text),
          isTarget: itemData.text == target.text && !spawnCone && !spawnStar,
          isObstacle: spawnCone,
          isBonusStar: spawnStar,
          lane: lane,
          y: -0.15 - (_rng.nextDouble() * 0.05), // Start just above horizon
          bubbleColor: spawnCone
              ? const Color(0xFFFFCC80)
              : (spawnStar ? const Color(0xFFFFF59D) : _bubbleColors[colorIdx]),
          borderColor: spawnCone
              ? const Color(0xFFE65100)
              : (spawnStar ? const Color(0xFFFBC02D) : _bubbleBorders[colorIdx]),
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
    _timeElapsed += dt;

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
    // Smooth lane steering interpolation
    final laneDiff = _currentLane.toDouble() - _carAnimatedLane;
    _carAnimatedLane += laneDiff * (dt * 12.0);
    _carSteerTilt = (laneDiff * 0.22).clamp(-0.25, 0.25);

    // Road scroll
    final currentSpeed = _baseSpeed * _speedModifier;
    _roadScrollOffset = (_roadScrollOffset + (dt * currentSpeed)) % 80.0;

    // Reset temporary speed modifier smoothly back to 1.0
    if (_speedModifier < 1.0) {
      _speedModifier = min(1.0, _speedModifier + (dt * 0.6));
    }

    if (_isRoundTransitioning) {
      _updateParticles(dt);
      _fadeFeedback(dt);
      return;
    }

    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    // Road bounds
    final roadWidth = screenWidth * 0.86;
    final roadLeft = (screenWidth - roadWidth) / 2;
    final laneWidth = roadWidth / 3;

    // Car collision area (normalized Y between 0.70 and 0.84)
    const carYFractionStart = 0.68;
    const carYFractionEnd = 0.82;

    bool hasTargetOnRoad = false;

    for (int i = _roadItems.length - 1; i >= 0; i--) {
      final item = _roadItems[i];
      if (item.isCollected) continue;

      // Item speed in normalized Y/sec
      final normalizedSpeed = (currentSpeed / screenHeight);
      item.y += normalizedSpeed * dt;

      // Collision Check: item intersects with car's Y zone & lane
      final overlapsY = (item.y >= carYFractionStart && item.y <= carYFractionEnd);
      final carCurrentLaneRounded = _carAnimatedLane.round();

      if (overlapsY && item.lane == carCurrentLaneRounded) {
        item.isCollected = true;

        final itemPixelX = roadLeft + (item.lane * laneWidth) + (laneWidth / 2);
        final itemPixelY = item.y * screenHeight;

        if (item.isTarget) {
          _roadItems.removeAt(i);
          _handleCorrectCatch(item, itemPixelX, itemPixelY);
          return;
        } else if (item.isBonusStar) {
          _roadItems.removeAt(i);
          _handleBonusStar(itemPixelX, itemPixelY);
          continue;
        } else if (item.isObstacle) {
          _roadItems.removeAt(i);
          _handleObstacle(itemPixelX, itemPixelY);
          continue;
        } else {
          // Wrong Tamil letter / word
          _roadItems.removeAt(i);
          _handleWrongCatch(item);
          continue;
        }
      }

      // Check if item scrolled past bottom of road
      if (item.y > 1.15) {
        _roadItems.removeAt(i);
      } else {
        if (item.isTarget) {
          hasTargetOnRoad = true;
        }
      }
    }

    // If target item passed without being collected, automatically respawn wave!
    if (!hasTargetOnRoad && !_isRoundTransitioning && !_isGameOver && !_isGameCompleted) {
      _spawnWaveForCurrentRound();
    }

    _updateParticles(dt);
    _fadeFeedback(dt);
  }

  void _handleCorrectCatch(RacingRoadItem item, double hitX, double hitY) {
    if (_isRoundTransitioning) return;
    _isRoundTransitioning = true;

    _score += 10;
    _correctCatches++;
    _scoreBumpController.forward(from: 0.0);

    // Sparkles & Star Particles
    _spawnConfetti(hitX, hitY);

    _audioService.playSuccessFeedback(context);
    _audioService.playLetterSound(
      context,
      letter: item.text,
      showIndicator: false,
    );

    const praises = ['சூப்பர்!', 'அருமை!', 'சபாஷ்!', 'அற்புதம்!'];
    _showFeedback(praises[_rng.nextInt(praises.length)], AppColors.mintGreen);

    // Auto-advance to next round smoothly
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      _advanceToNextRound();
    });
  }

  void _handleWrongCatch(RacingRoadItem item) {
    _carShakeController.forward(from: 0.0);
    _audioService.playLetterSound(
      context,
      letter: item.text,
      showIndicator: false,
    );
    _audioService.playRetryFeedback(context);
    _showFeedback('மீண்டும் முயற்சி செய்!', AppColors.playfulPink);
  }

  void _handleBonusStar(double hitX, double hitY) {
    _score += 5;
    _scoreBumpController.forward(from: 0.0);
    _audioService.playStarReward(context);
    _spawnConfetti(hitX, hitY, count: 12);
    _showFeedback('+5 போனஸ்!', const Color(0xFFFFB300));
  }

  void _handleObstacle(double hitX, double hitY) {
    _speedModifier = 0.45; // Temporary slowdown
    _carShakeController.forward(from: 0.0);
    _audioService.playRetryFeedback(context);
    _showFeedback('கவனம்!', const Color(0xFFFF7043));
  }

  void _advanceToNextRound() {
    _roadItems.clear();

    if (_currentRoundIndex + 1 < _roundQueue.length) {
      _currentRoundIndex++;
      _isRoundTransitioning = false;
      _spawnWaveForCurrentRound();
      _playTargetSound();
      setState(() {});
    } else {
      // Completed all 10 racing targets!
      _isGameCompleted = true;
      _isRoundTransitioning = false;
      _ticker.stop();
      _audioService.playStarReward(context);

      final stars = _score >= 90 ? 3 : (_score >= 60 ? 2 : 1);
      widget.progressService.recordGameCompleted(stars);

      final size = MediaQuery.of(context).size;
      _spawnConfetti(size.width * 0.5, size.height * 0.4, count: 45);
      setState(() {});
    }
  }

  void _spawnConfetti(double x, double y, {int count = 18}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80.0 + (_rng.nextDouble() * 190.0);
      _particles.add(
        _RacingParticle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 50,
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
      p.vy += 220 * dt;
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

  void _showFeedback(String text, Color color) {
    setState(() {
      _feedbackText = text;
      _feedbackColor = color;
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
    _carShakeController.dispose();
    _scoreBumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final roadWidth = screenWidth * 0.86;
    final roadLeft = (screenWidth - roadWidth) / 2;
    final laneWidth = roadWidth / 3;

    // Car X coordinate derived from animated lane
    final carCenterX = roadLeft + (_carAnimatedLane * laneWidth) + (laneWidth / 2);
    final carCenterY = screenHeight * 0.74;

    return Scaffold(
      body: Container(
        color: const Color(0xFF81C784), // Cheerful roadside grass green
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Horizontal swipe controls
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -180) {
                  moveCarLeft();
                } else if (details.primaryVelocity! > 180) {
                  moveCarRight();
                }
              }
            },
            // Direct lane tapping
            onTapDown: (details) {
              final tapX = details.localPosition.dx;
              if (tapX >= roadLeft && tapX <= roadLeft + roadWidth) {
                final selectedLane = ((tapX - roadLeft) / laneWidth).floor().clamp(0, 2);
                _steerToLane(selectedLane);
              }
            },
            child: Stack(
              children: [
                // 1. Roadside Animated Scenery (Trees, Flowers, Clouds)
                _buildRoadsideScenery(screenWidth, screenHeight),

                // 2. Asphalt Cartoon Highway & Scrolling Dashed Markings
                Positioned(
                  left: roadLeft,
                  top: 0,
                  bottom: 0,
                  width: roadWidth,
                  child: _buildHighwayTrack(roadWidth, laneWidth),
                ),

                // 3. Falling/Approaching Tamil Road Items
                ..._roadItems.map((item) {
                  final itemCenterX = roadLeft + (item.lane * laneWidth) + (laneWidth / 2);
                  final itemPixelY = item.y * screenHeight;

                  return Positioned(
                    left: itemCenterX - 45,
                    top: itemPixelY - 35,
                    child: _buildRoadItemWidget(item),
                  );
                }),

                // 4. Cute Cartoon Racing Car
                Positioned(
                  left: carCenterX - 40,
                  top: carCenterY - 45,
                  child: AnimatedBuilder(
                    animation: _carShakeAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_carShakeAnim.value, sin(_timeElapsed * 14) * 2.2),
                        child: Transform.rotate(
                          angle: _carSteerTilt,
                          child: child,
                        ),
                      );
                    },
                    child: _buildCartoonCar(),
                  ),
                ),

                // 5. Confetti & Star Particle Canvas
                CustomPaint(
                  painter: _RacingParticlePainter(_particles),
                  size: Size.infinite,
                ),

                // 6. Floating Praise Toast
                if (_feedbackText != null && _feedbackOpacity > 0.0)
                  Positioned(
                    top: screenHeight * 0.40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Opacity(
                        opacity: _feedbackOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _feedbackColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _feedbackText!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 7. Top HUD Bar & Instruction Banner
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

                // 8. Bottom Steer Touch Buttons
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: _buildBottomControls(),
                ),

                // 9. Celebration Result Modal
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
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏎️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    'உயிர் எழுத்து கார் பந்தயம்',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 14,
                      color: const Color(0xFFBF360C),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Mute Button
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

            // Progress Indicator (e.g. 1/10)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF81C784), width: 1.5),
              ),
              child: Text(
                '${_currentRoundIndex + 1}/${_roundQueue.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E7D32),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF7043), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Audio Listening Icon
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7043), Color(0xFFE64A19)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE64A19).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.headphones_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          // Tamil Audio Listening Guidance (No letter text revealed)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ஒலியைக் கேட்டு காரை ஓட்டுங்கள்! 🚗',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD84315),
                  ),
                ),
                Text(
                  'சரியான உயிர் எழுத்தை சேகரியுங்கள்! 🎵',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Audio Speaker Replay Button
          BouncyButton(
            onPressed: _playTargetSound,
            scaleFactor: 0.9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'மீண்டும் கேள்',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighwayTrack(double roadWidth, double laneWidth) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF263238), // Dark Asphalt
        border: Border.symmetric(
          vertical: BorderSide(color: Colors.amber.shade400, width: 4),
        ),
      ),
      child: Stack(
        children: [
          // Dashed Divider between Lane 0 & Lane 1
          Positioned(
            left: laneWidth - 2,
            top: 0,
            bottom: 0,
            width: 4,
            child: CustomPaint(
              painter: _DashedLinePainter(_roadScrollOffset),
            ),
          ),
          // Dashed Divider between Lane 1 & Lane 2
          Positioned(
            left: (laneWidth * 2) - 2,
            top: 0,
            bottom: 0,
            width: 4,
            child: CustomPaint(
              painter: _DashedLinePainter(_roadScrollOffset),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadsideScenery(double screenWidth, double screenHeight) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Left roadside trees
          Positioned(
            top: 140 + (_roadScrollOffset * 1.5) % (screenHeight * 0.7),
            left: 6,
            child: const Text('🌳', style: TextStyle(fontSize: 28)),
          ),
          Positioned(
            top: 360 + (_roadScrollOffset * 1.5) % (screenHeight * 0.7),
            left: 4,
            child: const Text('🌸', style: TextStyle(fontSize: 24)),
          ),
          // Right roadside trees
          Positioned(
            top: 220 + (_roadScrollOffset * 1.5) % (screenHeight * 0.7),
            right: 6,
            child: const Text('🌲', style: TextStyle(fontSize: 28)),
          ),
          Positioned(
            top: 450 + (_roadScrollOffset * 1.5) % (screenHeight * 0.7),
            right: 4,
            child: const Text('🌻', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadItemWidget(RacingRoadItem item) {
    if (item.isObstacle) {
      return Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: const Text('🚧', style: TextStyle(fontSize: 42)),
      );
    }

    if (item.isBonusStar) {
      return Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: const Icon(Icons.star_rounded, size: 44, color: Color(0xFFFFD166)),
      );
    }

    final isWord = item.text.length > 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWord ? 14 : 16,
        vertical: isWord ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: item.bubbleColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: item.borderColor, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: item.borderColor.withValues(alpha: 0.35),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.text,
            style: TextStyle(
              fontSize: isWord ? 19 : 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF263238),
            ),
          ),
          if (isWord) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.volume_up_rounded,
              size: 16,
              color: item.borderColor.withValues(alpha: 0.85),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartoonCar() {
    return SizedBox(
      width: 80,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Headlight Beams glowing ahead
          Positioned(
            top: -24,
            child: Container(
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow.withValues(alpha: 0.35),
                    Colors.yellow.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
          ),

          // 4 Cartoon Tires
          Positioned(left: 2, top: 12, child: _buildTire()),
          Positioned(right: 2, top: 12, child: _buildTire()),
          Positioned(left: 2, bottom: 12, child: _buildTire()),
          Positioned(right: 2, bottom: 12, child: _buildTire()),

          // Car Main Chassis / Body
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB71C1C), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Sporty Racing Stripe down center
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 12,
                    height: double.infinity,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                // Cute Windshield Glass
                Positioned(
                  top: 18,
                  left: 8,
                  right: 8,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF81D4FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Cute blinking eyes on windshield
                        _buildCarEye(),
                        const SizedBox(width: 12),
                        _buildCarEye(),
                      ],
                    ),
                  ),
                ),
                // Headlights
                Positioned(
                  top: 4,
                  left: 6,
                  child: Container(
                    width: 10,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEB3B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEB3B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTire() {
    return Container(
      width: 10,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildCarEye() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF1A237E),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Steer Left Button
        BouncyButton(
          onPressed: moveCarLeft,
          scaleFactor: 0.9,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                SizedBox(width: 4),
                Text(
                  'இடது',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Steer Right Button
        BouncyButton(
          onPressed: moveCarRight,
          scaleFactor: 0.9,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Text(
                  'வலது',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionOverlay() {
    final starsEarned = _score >= 90 ? 3 : (_score >= 60 ? 2 : 1);

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
              'பந்தயம் முடிந்தது! 🎉',
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

            // Star Rating
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
                          child: Text('சேகரித்தவை', maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF795548))),
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
                    scaleFactor: 0.94,
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
                    scaleFactor: 0.94,
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

// Dashed road lane lines painter
class _DashedLinePainter extends CustomPainter {
  final double scrollOffset;

  _DashedLinePainter(this.scrollOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = size.width
      ..style = PaintingStyle.stroke;

    const dashHeight = 28.0;
    const dashSpace = 24.0;
    const totalPattern = dashHeight + dashSpace;

    double startY = -totalPattern + (scrollOffset % totalPattern);
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += totalPattern;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => true;
}

// Particle system for Confetti & Stars
class _RacingParticle {
  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  final double size;
  double life;

  _RacingParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });
}

class _RacingParticlePainter extends CustomPainter {
  final List<_RacingParticle> particles;

  _RacingParticlePainter(this.particles);

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
  bool shouldRepaint(covariant _RacingParticlePainter oldDelegate) => true;
}
