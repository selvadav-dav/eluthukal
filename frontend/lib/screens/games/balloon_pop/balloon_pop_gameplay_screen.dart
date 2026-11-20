import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/audio_service.dart';
import '../../../services/progress_service.dart';
import '../../../widgets/bouncy_button.dart';
import 'balloon_pop_data.dart';
import 'balloon_pop_models.dart';
import 'balloon_pop_particles.dart';
import 'balloon_pop_progress.dart';
import 'realistic_balloon_painter.dart';

class BalloonPopGameplayScreen extends StatefulWidget {
  final int levelNumber;
  final ProgressService progressService;
  final BalloonPopProgressService balloonProgress;

  const BalloonPopGameplayScreen({
    super.key,
    required this.levelNumber,
    required this.progressService,
    required this.balloonProgress,
  });

  @override
  State<BalloonPopGameplayScreen> createState() =>
      _BalloonPopGameplayScreenState();
}

class _BalloonPopGameplayScreenState extends State<BalloonPopGameplayScreen>
    with TickerProviderStateMixin {
  final Random _rng = Random();
  final AudioService _audioService = AudioService.instance;

  // 60 FPS Ticker
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  // Arena dimensions
  Size _arenaSize = const Size(360, 640);

  // Entities
  final List<FloatingBalloon> _balloons = [];
  final List<PopShard> _shards = [];
  final List<SparkleParticle> _sparkles = [];
  final List<FloatingFeedback> _feedbacks = [];

  // Spawning & flow
  int _nextBalloonId = 1;
  double _spawnTimer = 0.0;
  bool _isPaused = false;
  bool _isGameOver = false;

  // Game Progress
  late final int _levelNumber;
  late final BalloonLevelInfo _levelInfo;
  int _targetIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _correctPops = 0;
  int _wrongAttempts = 0;

  // Targets Pool
  List<String> _targetLetters = [];
  List<WordChallenge> _wordChallenges = [];
  String _currentTargetLetter = '';
  WordChallenge? _currentWordChallenge;

  @override
  void initState() {
    super.initState();
    _levelNumber = widget.levelNumber;
    _levelInfo = BalloonLevelInfo.levels.firstWhere(
      (l) => l.levelNumber == _levelNumber,
      orElse: () => BalloonLevelInfo.levels[0],
    );

    _initLevelData();
    _ticker = createTicker(_onTick)..start();

    // Play target letter sound on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentTarget();
    });
  }

  void _initLevelData() {
    _targetIndex = 0;
    _correctPops = 0;
    _score = 0;
    _streak = 0;
    _wrongAttempts = 0;
    _isGameOver = false;

    if (_levelNumber == 1) {
      _targetLetters = List<String>.from(BalloonPopData.uyirLetters);
      _currentTargetLetter = _targetLetters[0];
    } else if (_levelNumber == 2) {
      _targetLetters = List<String>.from(BalloonPopData.meiLetters);
      _currentTargetLetter = _targetLetters[0];
    } else if (_levelNumber == 3) {
      // 24 progressive Uyirmei letters for this session
      final pool = List<String>.from(BalloonPopData.allUyirmeiLetters)..shuffle(_rng);
      _targetLetters = pool.take(24).toList();
      _currentTargetLetter = _targetLetters[0];
    } else {
      // Level 4: Word Discovery
      _wordChallenges = List<WordChallenge>.from(BalloonPopData.wordChallenges);
      _currentWordChallenge = _wordChallenges[0];
      _currentTargetLetter = _currentWordChallenge!.targetLetter;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _speakCurrentTarget() {
    if (_currentTargetLetter.isNotEmpty) {
      _audioService.playTamilAudio(_currentTargetLetter);
    }
  }

  // --------------------------------------------------------------------------
  // Core Physics & Ticker Loop (60 FPS)
  // --------------------------------------------------------------------------
  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final double dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.001, 0.05);
    _lastElapsed = elapsed;

    if (_isPaused || _isGameOver) return;

    setState(() {
      _updatePhysics(dt);
    });
  }

  void _updatePhysics(double dt) {
    // 1. Spawning balloons
    _spawnTimer -= dt;
    final int maxBalloons = _levelNumber == 1 ? 4 : (_levelNumber == 2 ? 5 : 6);
    if (_spawnTimer <= 0 && _balloons.length < maxBalloons) {
      _spawnBalloon();
      _spawnTimer = _levelNumber == 1
          ? (1.2 + _rng.nextDouble() * 0.8)
          : (0.9 + _rng.nextDouble() * 0.7);
    }

    // 2. Update floating balloons
    for (int i = _balloons.length - 1; i >= 0; i--) {
      final b = _balloons[i];
      b.age += dt;

      if (b.isPopping) {
        b.popProgress += dt * 3.5;
        if (b.popProgress >= 1.0) {
          _balloons.removeAt(i);
        }
        continue;
      }

      // Vertical movement
      b.y -= b.speed * dt;

      // Horizontal sinusoidal sway
      b.x = b.baseX + sin(b.age * b.swayFrequency + b.phase) * b.swayAmplitude;

      // Clamp within arena boundaries
      b.x = b.x.clamp(b.radius + 8, _arenaSize.width - b.radius - 8);

      // Wrong tap wobble timer decay
      if (b.wrongWobbleTimer > 0) {
        b.wrongWobbleTimer = max(0.0, b.wrongWobbleTimer - dt);
      }

      // Despawn when floated above top screen boundary
      if (b.y < -b.radius * 2.5) {
        _balloons.removeAt(i);
      }
    }

    // 3. Update popping particles
    for (int i = _shards.length - 1; i >= 0; i--) {
      _shards[i].update(dt);
      if (_shards[i].opacity <= 0.0) _shards.removeAt(i);
    }
    for (int i = _sparkles.length - 1; i >= 0; i--) {
      _sparkles[i].update(dt);
      if (_sparkles[i].opacity <= 0.0) _sparkles.removeAt(i);
    }
    for (int i = _feedbacks.length - 1; i >= 0; i--) {
      _feedbacks[i].update(dt);
      if (_feedbacks[i].opacity <= 0.0) _feedbacks.removeAt(i);
    }
  }

  void _spawnBalloon() {
    if (_arenaSize.width <= 0) return;

    // Decide if this balloon should carry the target letter
    final bool hasTargetAlready =
        _balloons.any((b) => b.letter == _currentTargetLetter && !b.isPopping);
    String letter;
    if (!hasTargetAlready && _rng.nextDouble() < 0.65) {
      letter = _currentTargetLetter;
    } else {
      letter = _getRandomDistractorLetter();
    }

    final color = BalloonColorTheme.randomColor(_rng);
    final radius = 38.0 + _rng.nextDouble() * 8.0;

    // Speeds based on level
    double baseSpeed = 80.0;
    if (_levelNumber == 2) baseSpeed = 100.0;
    if (_levelNumber == 3) baseSpeed = 125.0;
    if (_levelNumber == 4) baseSpeed = 105.0;
    final speed = baseSpeed + _rng.nextDouble() * 30.0;

    // Spawn X position avoiding close overlap
    final margin = radius + 14.0;
    double spawnX = margin + _rng.nextDouble() * (_arenaSize.width - margin * 2);

    _balloons.add(
      FloatingBalloon(
        id: _nextBalloonId++,
        letter: letter,
        color: color,
        radius: radius,
        speed: speed,
        swayAmplitude: 14.0 + _rng.nextDouble() * 12.0,
        swayFrequency: 1.6 + _rng.nextDouble() * 0.8,
        phase: _rng.nextDouble() * 2 * pi,
        x: spawnX,
        y: _arenaSize.height + radius * 2.0,
      ),
    );
  }

  String _getRandomDistractorLetter() {
    if (_levelNumber == 1) {
      final pool = BalloonPopData.uyirLetters.where((l) => l != _currentTargetLetter).toList();
      return pool[_rng.nextInt(pool.length)];
    } else if (_levelNumber == 2) {
      final pool = BalloonPopData.meiLetters.where((l) => l != _currentTargetLetter).toList();
      return pool[_rng.nextInt(pool.length)];
    } else if (_levelNumber == 3) {
      final pool = BalloonPopData.allUyirmeiLetters.where((l) => l != _currentTargetLetter).toList();
      return pool[_rng.nextInt(pool.length)];
    } else {
      final pool = BalloonPopData.allUyirmeiLetters.where((l) => l != _currentTargetLetter).toList();
      return pool[_rng.nextInt(pool.length)];
    }
  }

  // --------------------------------------------------------------------------
  // User Tap Handler
  // --------------------------------------------------------------------------
  void _onTapDown(TapDownDetails details) {
    if (_isPaused || _isGameOver) return;
    final pos = details.localPosition;

    // Find tapped balloon (topmost first)
    FloatingBalloon? tapped;
    for (int i = _balloons.length - 1; i >= 0; i--) {
      if (_balloons[i].hitTest(pos)) {
        tapped = _balloons[i];
        break;
      }
    }

    if (tapped == null) return;

    if (tapped.letter == _currentTargetLetter) {
      // ✅ CORRECT BALLOON POPPED!
      _handleCorrectPop(tapped);
    } else {
      // ❌ WRONG BALLOON TAPPED!
      _handleWrongTap(tapped);
    }
  }

  void _handleCorrectPop(FloatingBalloon b) {
    b.isPopping = true;
    _correctPops++;
    _streak++;

    // Calculate score: base 10 + streak bonus
    final int points = 10 + (_streak > 1 ? min(15, _streak * 2).toInt() : 0);
    _score += points;

    // Spawn popping explosion particles
    BalloonPopExplosionFactory.spawn(
      center: Offset(b.x, b.y),
      color: b.color,
      shards: _shards,
      sparkles: _sparkles,
    );

    // Spawn floating positive Tamil feedback
    final feedback = BalloonPopData.positiveFeedbacks[
        _rng.nextInt(BalloonPopData.positiveFeedbacks.length)];
    _feedbacks.add(
      FloatingFeedback(
        text: feedback,
        x: b.x.clamp(50.0, _arenaSize.width - 50.0),
        y: b.y - 20,
      ),
    );

    // Audio & Haptics
    HapticFeedback.mediumImpact();
    _audioService.playTamilAudio(_currentTargetLetter);

    // Check level completion
    final totalTargets = _levelNumber == 4
        ? _wordChallenges.length
        : _targetLetters.length;

    if (_correctPops >= totalTargets) {
      _onLevelVictory();
    } else {
      // Advance to next target letter
      _targetIndex++;
      if (_levelNumber == 4) {
        _currentWordChallenge = _wordChallenges[_targetIndex];
        _currentTargetLetter = _currentWordChallenge!.targetLetter;
      } else {
        _currentTargetLetter = _targetLetters[_targetIndex];
      }

      // Pronounce new target letter
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_isGameOver) {
          _speakCurrentTarget();
        }
      });
    }
  }

  void _handleWrongTap(FloatingBalloon b) {
    b.wrongWobbleTimer = 0.6;
    _wrongAttempts++;
    _streak = 0; // Reset streak

    HapticFeedback.lightImpact();

    // Show encouraging feedback
    final feedback = BalloonPopData.tryAgainFeedbacks[
        _rng.nextInt(BalloonPopData.tryAgainFeedbacks.length)];
    _feedbacks.add(
      FloatingFeedback(
        text: feedback,
        x: b.x.clamp(60.0, _arenaSize.width - 60.0),
        y: b.y - 15,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Victory Celebration & Save Progress
  // --------------------------------------------------------------------------
  void _onLevelVictory() {
    _isGameOver = true;

    // Calculate stars: 3 stars if <= 2 errors, 2 stars if <= 5 errors, 1 star otherwise
    int stars = 3;
    if (_wrongAttempts > 5) {
      stars = 1;
    } else if (_wrongAttempts > 2) {
      stars = 2;
    }

    // Save level completion in persistent storage
    widget.balloonProgress.completeLevel(
      levelNumber: _levelNumber,
      score: _score,
      stars: stars,
      progressService: widget.progressService,
    );

    // Cheerful sound
    _audioService.playStarReward(context);

    // Show victory modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildVictoryDialog(ctx, stars),
    );
  }

  Widget _buildVictoryDialog(BuildContext ctx, int stars) {
    String message = 'அருமை! இந்த நிலையை வெற்றிகரமாக முடித்துவிட்டாய்!';
    if (_levelNumber == 1) {
      message = 'அருமை! உயிரெழுத்துகளை வெற்றிகரமாக முடித்துவிட்டாய்! 🌟\nவாழ்த்துகள்! இப்போது மெய்யெழுத்து நிலையை விளையாடலாம்!';
    } else if (_levelNumber == 2) {
      message = 'சபாஷ்! மெய்யெழுத்துகளை வெற்றிகரமாக முடித்துவிட்டாய்! 🎉\nவாழ்த்துகள்! இப்போது உயிர்மெய் நிலையை விளையாடலாம்!';
    } else if (_levelNumber == 3) {
      message = 'அற்புதம்! உயிர்மெய் எழுத்துகளை வெற்றிகரமாக முடித்துவிட்டாய்! 🔥\nவாழ்த்துகள்! இப்போது சொல் கண்டுபிடி நிலையை விளையாடலாம்!';
    } else if (_levelNumber == 4) {
      message = 'மாபெரும் வெற்றி! சொல் கண்டுபிடி நிலையை வென்று சாதித்துவிட்டாய்! 🏆👑';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 12,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Victory Icon
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE082),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 46,
                color: Color(0xFFFF8F00),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'வெற்றி! (Victory)',
              style: GoogleFonts.catamaran(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 8),

            // Stars Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final earned = index < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    earned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: earned ? const Color(0xFFFFB300) : Colors.grey.shade400,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Score Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECB3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'மதிப்பெண்: $_score புள்ளிகள்',
                style: GoogleFonts.catamaran(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFBF360C),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Congratulatory message
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.catamaran(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF37474F),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                // Replay Button
                Expanded(
                  child: BouncyButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _balloons.clear();
                        _shards.clear();
                        _sparkles.clear();
                        _feedbacks.clear();
                        _initLevelData();
                        _isGameOver = false;
                      });
                      _speakCurrentTarget();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCFD8DC), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'மீண்டும்',
                        style: GoogleFonts.catamaran(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF455A64),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Next Level / Levels Button
                Expanded(
                  flex: 2,
                  child: BouncyButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (_levelNumber < 4) {
                        // Advance to next unlocked level
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BalloonPopGameplayScreen(
                              levelNumber: _levelNumber + 1,
                              progressService: widget.progressService,
                              balloonProgress: widget.balloonProgress,
                            ),
                          ),
                        );
                      } else {
                        // Exit back to level select
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _levelNumber < 4 ? 'அடுத்த நிலை ➔' : 'முடிந்தது ✓',
                        style: GoogleFonts.catamaran(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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

  // --------------------------------------------------------------------------
  // Build Method
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final totalTargets = _levelNumber == 4
        ? _wordChallenges.length
        : _targetLetters.length;
    final progressFraction = (_correctPops / totalTargets).clamp(0.0, 1.0);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          _arenaSize = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Sky & Clouds Background
              _buildSkyBackground(),

              // 2. Active Realistic Floating Balloons Layer
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _onTapDown,
                child: CustomPaint(
                  size: _arenaSize,
                  painter: _BalloonsLayerPainter(balloons: _balloons),
                ),
              ),

              // 3. Popping Explosion Particles & Floating Words Layer
              IgnorePointer(
                child: CustomPaint(
                  size: _arenaSize,
                  painter: BalloonPopParticlePainter(
                    shards: _shards,
                    sparkles: _sparkles,
                    feedbacks: _feedbacks,
                  ),
                ),
              ),

              // 4. Top Header & Target Letter HUD
              SafeArea(
                child: Column(
                  children: [
                    _buildTopHud(),
                    const SizedBox(height: 8),
                    _buildTargetBanner(),
                  ],
                ),
              ),

              // 5. Bottom Instructions & Progress Footer
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: _buildBottomFooter(progressFraction, totalTargets),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkyBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF29B6F6), // Vibrant sky cyan
            Color(0xFF81D4FA), // Mid sky blue
            Color(0xFFE1F5FE), // Soft cloud tint at horizon
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Sun glow top-right
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFF59D).withValues(alpha: 0.8),
                    const Color(0xFFFFF9C4).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Soft floating background clouds
          Positioned(
            top: 70,
            left: 20,
            child: _buildCloud(width: 120, height: 45),
          ),
          Positioned(
            top: 150,
            right: 15,
            child: _buildCloud(width: 95, height: 38),
          ),
          Positioned(
            top: 290,
            left: 35,
            child: _buildCloud(width: 110, height: 42),
          ),
        ],
      ),
    );
  }

  Widget _buildCloud({required double width, required double height}) {
    return Opacity(
      opacity: 0.45,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Back Button
          BouncyButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0277BD), size: 18),
            ),
          ),
          const SizedBox(width: 10),

          // Level Title badge
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(_levelInfo.icon, size: 20, color: _levelInfo.gradientColors.first),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'நிலை $_levelNumber: ${_levelInfo.nameTa}',
                      style: GoogleFonts.catamaran(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF01579B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Score Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 18, color: Color(0xFFE65100)),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: GoogleFonts.catamaran(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFBF360C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Audio speaker / mute toggle
          BouncyButton(
            onPressed: () {
              setState(() {
                widget.progressService.toggleSound(!widget.progressService.soundEnabled);
              });
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.progressService.soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: const Color(0xFF0277BD),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF81D4FA), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0288D1).withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Target Letter Spotlight Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _levelInfo.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _levelInfo.gradientColors.first.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _currentTargetLetter,
                style: GoogleFonts.catamaran(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Instruction Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_levelNumber == 4 && _currentWordChallenge != null) ...[
                    Row(
                      children: [
                        Text(
                          _currentWordChallenge!.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentWordChallenge!.word,
                          style: GoogleFonts.catamaran(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF01579B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentWordChallenge!.hintTa,
                      style: GoogleFonts.catamaran(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0288D1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    Text(
                      'இலக்கு எழுத்து:',
                      style: GoogleFonts.catamaran(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF546E7A),
                      ),
                    ),
                    Text(
                      'இந்த பலூனை உடைக்கவும்! 🎈',
                      style: GoogleFonts.catamaran(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF01579B),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Re-play audio speaker icon button
            BouncyButton(
              onPressed: _speakCurrentTarget,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB3E5FC)),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFF0288D1),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomFooter(double progressFraction, int totalTargets) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB3E5FC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'முன்னேற்றம் (Progress):',
                style: GoogleFonts.catamaran(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF546E7A),
                ),
              ),
              Text(
                '$_correctPops / $totalTargets',
                style: GoogleFonts.catamaran(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF01579B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 8,
              backgroundColor: const Color(0xFFE1F5FE),
              valueColor: AlwaysStoppedAnimation<Color>(
                _levelInfo.gradientColors.first,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders all currently floating realistic balloons
class _BalloonsLayerPainter extends CustomPainter {
  final List<FloatingBalloon> balloons;

  _BalloonsLayerPainter({required this.balloons});

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in balloons) {
      canvas.save();
      canvas.translate(b.x, b.y);

      // Render individual realistic latex balloon
      final painter = RealisticBalloonPainter(
        letter: b.letter,
        color: b.color,
        radius: b.radius,
        wobble: b.wrongWobbleTimer > 0
            ? sin(b.wrongWobbleTimer * 28.0) * 0.4
            : sin(b.age * 1.8 + b.phase) * 0.08,
        popProgress: b.popProgress,
      );

      painter.paint(canvas, Size(b.radius * 2, b.radius * 2.5));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonsLayerPainter oldDelegate) => true;
}
