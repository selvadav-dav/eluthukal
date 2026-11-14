import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/mei_data.dart';
import '../../data/uyir_data.dart';
import '../../models/fruit_cutter_game_model.dart';
import '../../models/letter_model.dart';
import '../../services/audio_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';

class FruitCutterGame extends StatefulWidget {
  final ProgressService progressService;

  const FruitCutterGame({super.key, required this.progressService});

  @override
  State<FruitCutterGame> createState() => _FruitCutterGameState();
}

class _FruitCutterGameState extends State<FruitCutterGame>
    with TickerProviderStateMixin {
  final Random _rng = Random();
  final AudioService _audioService = AudioService.instance;

  // 60 FPS Ticker
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  // Game state
  bool _isPlaying = true;
  bool _isGameOver = false;
  bool _isMuted = false;
  int _score = 0;
  int _cutCount = 0;
  int _starsEarned = 0;
  int _comboCount = 0;
  int _maxCombo = 0;
  DateTime _lastSliceTime = DateTime.now();

  // Missed fruits tracking (Game Over at 10 misses)
  int _missedFruits = 0;
  static const int _maxMisses = 10;

  // Mode: 0: Uyir, 1: Mei, 2: All
  int _selectedLetterMode = 0;

  // Entities
  final List<ActiveFruit> _activeFruits = [];
  final List<JuiceDrop> _juiceDrops = [];
  final List<JuiceSplatDecal> _splatDecals = [];
  final List<LetterRevealPop> _letterPops = [];
  final List<BladePoint> _bladePoints = [];

  // Spawning timer (gentle, relaxed pace for kids)
  double _timeUntilNextSpawn = 1.6;
  int _fruitIdSeq = 0;

  // Size of game arena
  Size _canvasSize = const Size(400, 700);

  @override
  void initState() {
    super.initState();
    _isMuted = _audioService.isMuted;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  List<LetterModel> _getCurrentLetterPool() {
    if (_selectedLetterMode == 0) {
      return uyirLettersList;
    } else if (_selectedLetterMode == 1) {
      return meiLettersList;
    } else {
      return [...uyirLettersList, ...meiLettersList];
    }
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _cutCount = 0;
      _starsEarned = 0;
      _comboCount = 0;
      _maxCombo = 0;
      _missedFruits = 0;
      _isGameOver = false;
      _isPlaying = true;
      _activeFruits.clear();
      _juiceDrops.clear();
      _splatDecals.clear();
      _letterPops.clear();
      _bladePoints.clear();
      _timeUntilNextSpawn = 1.6;
    });
  }

  // --------------------------------------------------------------------------
  // GAME LOOP (60 FPS)
  // --------------------------------------------------------------------------
  void _onTick(Duration elapsed) {
    if (!mounted || !_isPlaying || _isGameOver) return;

    final double dt = _lastElapsed == Duration.zero
        ? 0.016
        : (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    final double clampedDt = dt.clamp(0.001, 0.045);

    // 1. Blade trail decay (remove points older than 180ms)
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _bladePoints.removeWhere((p) => nowMs - p.timestampMs > 180);

    // 2. Spawn fruits (only if not game over - calm, slower pace)
    if (!_isGameOver) {
      _timeUntilNextSpawn -= clampedDt;
      if (_timeUntilNextSpawn <= 0) {
        _spawnWave();
        _timeUntilNextSpawn = 2.0 + _rng.nextDouble() * 1.2;
      }
    }

    // 3. Update fruits
    final List<ActiveFruit> toRemoveFruits = [];
    for (final fruit in _activeFruits) {
      if (!fruit.isSliced) {
        // Whole fruit physics (slower, floaty arc)
        fruit.x += fruit.vx;
        fruit.y += fruit.vy;
        fruit.vy += 0.18; // gentle gravity
        fruit.rotation += fruit.angularVelocity;

        // If fell below screen after rising (MISSED FRUIT)
        if (fruit.y > _canvasSize.height + 60 && fruit.vy > 0) {
          toRemoveFruits.add(fruit);
          _handleMissedFruit();
        }
      } else {
        // Sliced halves physics
        fruit.sliceProgress = (fruit.sliceProgress + clampedDt * 2.0).clamp(0.0, 1.0);

        fruit.half1X += fruit.half1Vx;
        fruit.half1Y += fruit.half1Vy;
        fruit.half1Vy += 0.22;
        fruit.half1Rotation += fruit.half1AngularVelocity;

        fruit.half2X += fruit.half2Vx;
        fruit.half2Y += fruit.half2Vy;
        fruit.half2Vy += 0.22;
        fruit.half2Rotation += fruit.half2AngularVelocity;

        if (fruit.half1Y > _canvasSize.height + 100 && fruit.half2Y > _canvasSize.height + 100) {
          toRemoveFruits.add(fruit);
        }
      }
    }
    _activeFruits.removeWhere((f) => toRemoveFruits.contains(f));

    // 4. Update juice droplets
    final List<JuiceDrop> toRemoveDrops = [];
    for (final drop in _juiceDrops) {
      drop.x += drop.vx;
      drop.y += drop.vy;
      drop.vy += 0.45;
      drop.opacity -= clampedDt * 1.5;
      if (drop.opacity <= 0 || drop.y > _canvasSize.height) {
        toRemoveDrops.add(drop);
      }
    }
    _juiceDrops.removeWhere((d) => toRemoveDrops.contains(d));

    // 5. Update background splat decals (fade slowly)
    for (final splat in _splatDecals) {
      splat.opacity -= clampedDt * 0.08;
    }
    _splatDecals.removeWhere((s) => s.opacity <= 0.02);

    // 6. Update letter pops
    final List<LetterRevealPop> toRemovePops = [];
    for (final pop in _letterPops) {
      pop.y += pop.vy;
      pop.vy *= 0.94;
      pop.scale = (pop.scale + clampedDt * 2.8).clamp(0.5, 1.15);
      pop.lifeMs -= (clampedDt * 1000).toInt();
      if (pop.lifeMs < 350) {
        pop.opacity = (pop.lifeMs / 350.0).clamp(0.0, 1.0);
      }
      if (pop.lifeMs <= 0) {
        toRemovePops.add(pop);
      }
    }
    _letterPops.removeWhere((p) => toRemovePops.contains(p));

    // Reset combo if gap > 700ms
    if (_comboCount > 0 && DateTime.now().difference(_lastSliceTime).inMilliseconds > 700) {
      _comboCount = 0;
    }

    setState(() {});
  }

  void _handleMissedFruit() {
    _missedFruits++;
    HapticFeedback.lightImpact();

    if (_missedFruits >= _maxMisses && !_isGameOver) {
      _triggerGameOver();
    }
  }

  void _triggerGameOver() {
    _isGameOver = true;
    _comboCount = 0;
    HapticFeedback.heavyImpact();
    widget.progressService.recordGameCompleted(_starsEarned);
  }

  // --------------------------------------------------------------------------
  // SPAWN FRUITS WAVE
  // --------------------------------------------------------------------------
  void _spawnWave() {
    final pool = _getCurrentLetterPool();
    if (pool.isEmpty) return;

    final fruitTypes = FruitType.values;
    // Launch mostly 1 fruit, occasionally 2 for a gentle slow pace
    final count = _rng.nextDouble() < 0.75 ? 1 : 2;

    for (int i = 0; i < count; i++) {
      final letter = pool[_rng.nextInt(pool.length)];
      final type = fruitTypes[_rng.nextInt(fruitTypes.length)];
      final meta = FruitMeta.fruitCatalog[type]!;

      // Spawn x position evenly across middle 70% of screen
      final margin = _canvasSize.width * 0.15;
      final usableWidth = _canvasSize.width - (margin * 2);
      final startX = margin + _rng.nextDouble() * usableWidth;
      final startY = _canvasSize.height + 40 + (i * 25);

      // Arc towards center
      final targetX = _canvasSize.width * 0.5 + (_rng.nextDouble() - 0.5) * (_canvasSize.width * 0.5);
      final peakHeight = _canvasSize.height * (0.30 + _rng.nextDouble() * 0.22);
      final double distanceUp = startY - peakHeight;

      // Physics formula for apex height with gentle gravity (g = 0.18)
      final double initialVy = -sqrt(2 * 0.18 * distanceUp);
      final double timeToPeak = -initialVy / 0.18;
      final double initialVx = (targetX - startX) / (timeToPeak * 1.05);

      _activeFruits.add(
        ActiveFruit(
          id: _fruitIdSeq++,
          type: type,
          letterModel: letter,
          x: startX,
          y: startY,
          vx: initialVx,
          vy: initialVy,
          radius: meta.defaultRadius,
          angularVelocity: (_rng.nextDouble() - 0.5) * 0.035,
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // SLICING INTERACTION
  // --------------------------------------------------------------------------
  void _onPanStart(DragStartDetails details) {
    if (_isGameOver) return;
    _recordBladePoint(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isGameOver) return;
    final p2 = details.localPosition;
    _recordBladePoint(p2);

    if (_bladePoints.length >= 2) {
      final p1 = _bladePoints[_bladePoints.length - 2].position;
      _checkFruitCut(p1, p2);
    }
  }

  void _onPanEnd(DragEndDetails details) {}

  void _recordBladePoint(Offset p) {
    _bladePoints.add(
      BladePoint(
        position: p,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _checkFruitCut(Offset p1, Offset p2) {
    for (final fruit in _activeFruits) {
      if (fruit.isSliced) continue;

      final d = _distToSegment(Offset(fruit.x, fruit.y), p1, p2);
      if (d <= fruit.radius + 12) {
        _sliceFruit(fruit, p1, p2);
      }
    }
  }

  double _distToSegment(Offset p, Offset v, Offset w) {
    final l2 = (v - w).distanceSquared;
    if (l2 == 0) return (p - v).distance;
    final t = (((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2).clamp(0.0, 1.0);
    final projection = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
    return (p - projection).distance;
  }

  void _sliceFruit(ActiveFruit fruit, Offset p1, Offset p2) {
    fruit.isSliced = true;
    _cutCount++;

    // Cut angle
    final cutAngle = atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    fruit.sliceAngle = cutAngle;

    // Normal vector perpendicular to cut line for outward separation
    final nx = -sin(cutAngle);
    final ny = cos(cutAngle);

    final impulse = 4.2 + _rng.nextDouble() * 2.5;
    fruit.half1X = fruit.x;
    fruit.half1Y = fruit.y;
    fruit.half1Vx = fruit.vx + (nx * impulse) - 1.5;
    fruit.half1Vy = fruit.vy + (ny * impulse) - 2.0;
    fruit.half1Rotation = fruit.rotation;
    fruit.half1AngularVelocity = -0.15 - _rng.nextDouble() * 0.2;

    fruit.half2X = fruit.x;
    fruit.half2Y = fruit.y;
    fruit.half2Vx = fruit.vx - (nx * impulse) + 1.5;
    fruit.half2Vy = fruit.vy - (ny * impulse) - 2.0;
    fruit.half2Rotation = fruit.rotation;
    fruit.half2AngularVelocity = 0.15 + _rng.nextDouble() * 0.2;

    // Juice droplets
    final juiceColor = fruit.meta.juiceColor;
    final int dropCount = 18 + _rng.nextInt(10);
    for (int i = 0; i < dropCount; i++) {
      final angle = cutAngle + (_rng.nextDouble() - 0.5) * pi * 0.9;
      final speed = 3.5 + _rng.nextDouble() * 6.5;
      _juiceDrops.add(
        JuiceDrop(
          x: fruit.x + (_rng.nextDouble() - 0.5) * 16,
          y: fruit.y + (_rng.nextDouble() - 0.5) * 16,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: 4.0 + _rng.nextDouble() * 6.5,
          color: juiceColor,
        ),
      );
    }

    // Splat decal on the wooden cutting board backdrop
    _splatDecals.add(
      JuiceSplatDecal(
        x: fruit.x,
        y: fruit.y,
        radius: fruit.radius * (1.1 + _rng.nextDouble() * 0.45),
        color: juiceColor.withValues(alpha: 0.35),
      ),
    );

    // Letter reveal pop (pops upward with letter pronunciation)
    _letterPops.add(
      LetterRevealPop(
        letter: fruit.letterModel.letter,
        word: fruit.letterModel.word,
        fruitType: fruit.type,
        x: fruit.x,
        y: fruit.y - 10,
      ),
    );

    // Pronounce the Tamil letter
    _audioService.playLetterSound(
      context,
      letter: fruit.letterModel.letter,
      word: fruit.letterModel.word,
    );

    // Combo & scoring
    final now = DateTime.now();
    if (now.difference(_lastSliceTime).inMilliseconds < 650) {
      _comboCount++;
      if (_comboCount > _maxCombo) {
        _maxCombo = _comboCount;
      }
    } else {
      _comboCount = 1;
    }
    _lastSliceTime = now;

    final comboBonus = _comboCount > 1 ? (_comboCount * 5) : 0;
    _score += fruit.meta.points + comboBonus;

    // Award 1 star every 5 fruits sliced
    if (_cutCount % 5 == 0) {
      _starsEarned++;
      widget.progressService.addStars(1);
    }

    // Mark letter learned in progress
    widget.progressService.markLetterCompleted(fruit.letterModel.letter);

    HapticFeedback.mediumImpact();
  }

  // --------------------------------------------------------------------------
  // BUILD METHOD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isEn = LanguageService.instance.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFF381A07),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              // 1. Beautiful Warm Wooden Cutting Board Background
              Positioned.fill(
                child: CustomPaint(
                  painter: _WoodBoardBackgroundPainter(),
                ),
              ),

              // 2. Interactive Game Area (GestureDetector & CustomPainter)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    size: _canvasSize,
                    painter: _FruitNinjaScenePainter(
                      activeFruits: _activeFruits,
                      juiceDrops: _juiceDrops,
                      splatDecals: _splatDecals,
                      letterPops: _letterPops,
                      bladePoints: _bladePoints,
                    ),
                  ),
                ),
              ),

              // 3. Top HUD: Back Button, Header, Lives/Missed counter, Stars, Score
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopHeader(isEn),
                        const SizedBox(height: 6),
                        _buildSubHeader(isEn),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Combo Flame Badge
              if (_comboCount >= 2 && !_isGameOver)
                Positioned(
                  top: 125,
                  right: 20,
                  child: _buildComboBadge(),
                ),

              // 5. Game Over Modal Overlay (When 10 fruits missed)
              if (_isGameOver)
                Positioned.fill(
                  child: _buildGameOverOverlay(isEn),
                ),
            ],
          );
        },
      ),
    );
  }

  // Row 1: Back Button, Title ("பழம் வெட்டு!"), Score, Stars, Sound Toggle
  Widget _buildTopHeader(bool isEn) {
    return Row(
      children: [
        // Back Button
        BouncyButton(
          onPressed: () {
            widget.progressService.recordGameCompleted(_starsEarned);
            Navigator.pop(context);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 8),

        // Title (Auto scales down on small screens, never wraps or overflows)
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isEn ? 'Fruit Slice' : 'பழம் வெட்டு!',
              style: GoogleFonts.notoSansTamil(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Score Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6D00),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: 14),
              const SizedBox(width: 2),
              Text(
                '$_score',
                style: GoogleFonts.notoSansTamil(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),

        // Stars Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
              const SizedBox(width: 2),
              Text(
                '${widget.progressService.stars}',
                style: GoogleFonts.notoSansTamil(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF78350F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),

        // Sound Toggle
        BouncyButton(
          onPressed: () {
            setState(() {
              _isMuted = !_isMuted;
              widget.progressService.toggleSound(!_isMuted);
            });
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ],
    );
  }

  // Row 2: Missed fruits counter + Letter Mode Selector
  Widget _buildSubHeader(bool isEn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Missed fruits counter (10 Max)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _missedFruits >= 7
                ? const Color(0xFFD32F2F).withValues(alpha: 0.9)
                : const Color(0xFF2E1C14).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _missedFruits >= 7 ? Colors.redAccent : Colors.white.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.close_rounded,
                color: _missedFruits >= 7 ? Colors.white : const Color(0xFFFF5252),
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                '$_missedFruits/$_maxMisses',
                style: GoogleFonts.notoSansTamil(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Mode Selector: உயிர் / மெய் / அனைத்தும் (Auto scales down on small screens)
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: _buildModeSelector(isEn),
          ),
        ),
      ],
    );
  }

  // Mode Selector: Uyir / Mei / All
  Widget _buildModeSelector(bool isEn) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModePill(0, isEn ? 'Uyir' : 'உயிர்'),
          _buildModePill(1, isEn ? 'Mei' : 'மெய்'),
          _buildModePill(2, isEn ? 'All' : 'அனைத்தும்'),
        ],
      ),
    );
  }

  Widget _buildModePill(int modeIndex, String label) {
    final bool isSel = _selectedLetterMode == modeIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLetterMode = modeIndex;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF00E676) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansTamil(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
            color: isSel ? const Color(0xFF1B5E20) : Colors.white70,
          ),
        ),
      ),
    );
  }

  // Combo Streak Badge
  Widget _buildComboBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD600), Color(0xFFFF6D00)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6D00).withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 4),
          Text(
            '$_comboCount COMBO!',
            style: GoogleFonts.notoSansTamil(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Game Over Dialog / Overlay
  Widget _buildGameOverOverlay(bool isEn) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42210B), Color(0xFF2E1506)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFB300), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFE65100)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🍉', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  isEn ? 'Game Over!' : 'ஆட்டம் முடிந்தது!',
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? '10 fruits were missed'
                      : '10 பழங்கள் தவறவிடப்பட்டன!',
                  style: GoogleFonts.notoSansTamil(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFAB91),
                  ),
                ),
                const SizedBox(height: 20),

                // Score Card Stats Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('⚡', isEn ? 'Score' : 'மதிப்பெண்', '$_score'),
                      _buildStatColumn('🍉', isEn ? 'Sliced' : 'வெட்டியவை', '$_cutCount'),
                      _buildStatColumn('⭐', isEn ? 'Stars' : 'நட்சத்திரம்', '+$_starsEarned'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Play Again Button
                BouncyButton(
                  onPressed: _restartGame,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isEn ? 'Play Again' : 'மீண்டும் விளையாடு',
                          style: GoogleFonts.notoSansTamil(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Exit Button
                BouncyButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Center(
                      child: Text(
                        isEn ? 'Exit' : 'வெளியேறு',
                        style: GoogleFonts.notoSansTamil(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String emoji, String title, String val) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          val,
          style: GoogleFonts.notoSansTamil(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFD54F),
          ),
        ),
        Text(
          title,
          style: GoogleFonts.notoSansTamil(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------
// WARM WOODEN CUTTING BOARD BACKGROUND PAINTER
// --------------------------------------------------------------------------
class _WoodBoardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base rich mahogany / cedar gradient
    final baseRect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF5D3012),
          Color(0xFF45220A),
          Color(0xFF2E1505),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect);
    canvas.drawRect(baseRect, basePaint);

    // 2. Warm ambient spotlight in upper-center (illuminating the cutting arena)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.85,
        colors: [
          const Color(0xFF8D4B1C).withValues(alpha: 0.55),
          const Color(0xFF6B3714).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(baseRect);
    canvas.drawRect(baseRect, glowPaint);

    // 3. Vertical wooden planks
    const double plankWidth = 100.0;
    final plankCount = (size.width / plankWidth).ceil() + 1;

    final grooveDark = Paint()
      ..color = const Color(0xFF1E0D03).withValues(alpha: 0.75)
      ..strokeWidth = 2.0;

    final grooveHighlight = Paint()
      ..color = const Color(0xFFFFB74D).withValues(alpha: 0.16)
      ..strokeWidth = 1.0;

    final grainPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < plankCount; i++) {
      final double x = i * plankWidth;

      // Dark joint seam
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grooveDark);
      // Subtle golden bevel highlight on the plank edge
      canvas.drawLine(Offset(x + 1.5, 0), Offset(x + 1.5, size.height), grooveHighlight);

      // Wood grain lines inside each plank
      final double gx1 = x + plankWidth * 0.3;
      final double gx2 = x + plankWidth * 0.7;

      final path1 = Path()
        ..moveTo(gx1, 0)
        ..quadraticBezierTo(gx1 + 15, size.height * 0.5, gx1, size.height);
      canvas.drawPath(path1, grainPaint);

      final path2 = Path()
        ..moveTo(gx2, 0)
        ..quadraticBezierTo(gx2 - 12, size.height * 0.4, gx2 + 5, size.height);
      canvas.drawPath(path2, grainPaint);
    }

    // 4. Subtle corner vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.1,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.38),
        ],
      ).createShader(baseRect);
    canvas.drawRect(baseRect, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _WoodBoardBackgroundPainter oldDelegate) => false;
}

// --------------------------------------------------------------------------
// MAIN SCENE PAINTER
// --------------------------------------------------------------------------
class _FruitNinjaScenePainter extends CustomPainter {
  final List<ActiveFruit> activeFruits;
  final List<JuiceDrop> juiceDrops;
  final List<JuiceSplatDecal> splatDecals;
  final List<LetterRevealPop> letterPops;
  final List<BladePoint> bladePoints;

  _FruitNinjaScenePainter({
    required this.activeFruits,
    required this.juiceDrops,
    required this.splatDecals,
    required this.letterPops,
    required this.bladePoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Splat decals on the board
    _drawSplatDecals(canvas);

    // 2. Active fruits (whole or sliced halves)
    for (final fruit in activeFruits) {
      if (!fruit.isSliced) {
        _drawWholeFruit(canvas, fruit);
      } else {
        _drawSlicedFruit(canvas, fruit);
      }
    }

    // 3. Juice droplets flying
    _drawJuiceDroplets(canvas);

    // 4. Letter reveal popup banners
    _drawLetterPops(canvas);

    // 5. Blade swipe trail
    _drawBladeTrail(canvas);
  }

  // Draw background splats
  void _drawSplatDecals(Canvas canvas) {
    for (final splat in splatDecals) {
      final paint = Paint()
        ..color = splat.color.withValues(alpha: splat.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(splat.x, splat.y), splat.radius, paint);

      // Smaller satellite splat drops
      final satPaint = Paint()..color = splat.color.withValues(alpha: splat.opacity * 0.7);
      for (int i = 0; i < 5; i++) {
        final angle = i * (pi * 2 / 5);
        final dist = splat.radius * 1.35;
        canvas.drawCircle(
          Offset(splat.x + cos(angle) * dist, splat.y + sin(angle) * dist),
          splat.radius * 0.18,
          satPaint,
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // HYPER-REALISTIC WHOLE FRUIT DRAWINGS (No letters stamped on outside!)
  // --------------------------------------------------------------------------
  void _drawWholeFruit(Canvas canvas, ActiveFruit fruit) {
    canvas.save();
    canvas.translate(fruit.x, fruit.y);
    canvas.rotate(fruit.rotation);

    final r = fruit.radius;

    // Drop shadow under the fruit
    canvas.drawCircle(
      Offset(r * 0.1, r * 0.18),
      r * 0.92,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Draw realistic fruit based on type
    switch (fruit.type) {
      case FruitType.watermelon:
        _drawWholeWatermelon(canvas, r);
        break;
      case FruitType.orange:
        _drawWholeOrange(canvas, r);
        break;
      case FruitType.mango:
        _drawWholeMango(canvas, r);
        break;
      case FruitType.apple:
        _drawWholeApple(canvas, r);
        break;
      case FruitType.strawberry:
        _drawWholeStrawberry(canvas, r);
        break;
      case FruitType.pineapple:
        _drawWholePineapple(canvas, r);
        break;
      case FruitType.banana:
        _drawWholeBanana(canvas, r);
        break;
      case FruitType.lemon:
        _drawWholeLemon(canvas, r);
        break;
      case FruitType.pomegranate:
        _drawWholePomegranate(canvas, r);
        break;
    }

    canvas.restore();
  }

  // Realistic Watermelon
  void _drawWholeWatermelon(Canvas canvas, double r) {
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      ).createShader(rect);
    canvas.drawCircle(Offset.zero, r, bodyPaint);

    // Dark forest-green wavy rind stripes
    final stripePaint = Paint()
      ..color = const Color(0xFF0F3818)
      ..strokeWidth = r * 0.18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = -2; i <= 2; i++) {
      final x = i * (r * 0.35);
      final p = Path()
        ..moveTo(x, -r * 0.88)
        ..quadraticBezierTo(x + (i.isEven ? 9 : -9), 0, x, r * 0.88);
      canvas.drawPath(p, stripePaint);
    }

    // Curled stem at top
    final stemPaint = Paint()
      ..color = const Color(0xFF33691E)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final stemPath = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(r * 0.25, -r * 1.25, r * 0.1, -r * 1.35);
    canvas.drawPath(stemPath, stemPaint);

    _drawSpecularArc(canvas, r);
  }

  // Realistic Orange
  void _drawWholeOrange(Canvas canvas, double r) {
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: [Color(0xFFFFA726), Color(0xFFFF9800), Color(0xFFE65100)],
      ).createShader(rect);
    canvas.drawCircle(Offset.zero, r, bodyPaint);

    // Dimpled citrus texture (tiny subtle pores)
    final porePaint = Paint()..color = const Color(0xFFBF360C).withValues(alpha: 0.18);
    for (int i = 0; i < 24; i++) {
      final angle = (i * 0.27) * pi * 2;
      final dist = (r * 0.25) + ((i % 5) * (r * 0.14));
      canvas.drawCircle(Offset(cos(angle) * dist, sin(angle) * dist), 1.3, porePaint);
    }

    // Top green star calyx & twig
    final calyxPaint = Paint()..color = const Color(0xFF2E7D32);
    final p = Path()
      ..moveTo(0, -r * 0.95)
      ..lineTo(-5, -r * 0.85)
      ..lineTo(-3, -r * 0.8)
      ..lineTo(3, -r * 0.8)
      ..lineTo(5, -r * 0.85)
      ..close();
    canvas.drawPath(p, calyxPaint);

    // Leaf
    final leafPaint = Paint()..color = const Color(0xFF43A047);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(r * 0.25, -r * 0.92), width: r * 0.45, height: r * 0.2),
      leafPaint,
    );

    _drawSpecularArc(canvas, r);
  }

  // Realistic Apple
  void _drawWholeApple(Canvas canvas, double r) {
    final path = Path()
      ..moveTo(0, -r * 0.75)
      ..cubicTo(r * 0.8, -r * 1.05, r * 1.15, -r * 0.2, r * 0.95, r * 0.6)
      ..cubicTo(r * 0.8, r * 1.08, r * 0.2, r * 0.95, 0, r * 0.82)
      ..cubicTo(-r * 0.2, r * 0.95, -r * 0.8, r * 1.08, -r * 0.95, r * 0.6)
      ..cubicTo(-r * 1.15, -r * 0.2, -r * 0.8, -r * 1.05, 0, -r * 0.75)
      ..close();

    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        radius: 0.95,
        colors: [
          Color(0xFFFF5252),
          Color(0xFFE53935),
          Color(0xFFB71C1C),
          Color(0xFF7F0000),
        ],
      ).createShader(rect);
    canvas.drawPath(path, bodyPaint);

    // Golden blush streaks
    final blushPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(r * 0.2, -r * 0.3), Offset(r * 0.4, r * 0.4), blushPaint);

    // Woody stem
    final stemPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 3.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, -r * 0.75), Offset(r * 0.12, -r * 1.15), stemPaint);

    // Fresh green leaf
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(r * 0.3, -r * 1.0), width: r * 0.45, height: r * 0.22),
      leafPaint,
    );

    _drawSpecularArc(canvas, r);
  }

  // Realistic Mango
  void _drawWholeMango(Canvas canvas, double r) {
    final path = Path()
      ..moveTo(0, -r * 0.95)
      ..cubicTo(r * 0.98, -r * 0.72, r * 1.15, r * 0.48, r * 0.32, r * 0.98)
      ..cubicTo(-r * 0.45, r * 1.18, -r * 1.08, r * 0.3, -r * 0.95, -r * 0.4)
      ..close();

    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.25),
        radius: 0.95,
        colors: [
          Color(0xFFFFEE58),
          Color(0xFFFFB300),
          Color(0xFFFF6D00),
          Color(0xFFE64A19),
        ],
      ).createShader(rect);
    canvas.drawPath(path, bodyPaint);

    // Rosy cheek blush on the shoulder
    final blushPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        radius: 0.5,
        colors: [
          const Color(0xFFFF1744).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawPath(path, blushPaint);

    // Stem and slender mango leaf
    final stemPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, -r * 0.95), Offset(r * 0.08, -r * 1.15), stemPaint);

    final leafPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(r * 0.32, -r * 1.0), width: r * 0.6, height: r * 0.2),
      leafPaint,
    );

    _drawSpecularArc(canvas, r);
  }

  // Realistic Strawberry
  void _drawWholeStrawberry(Canvas canvas, double r) {
    final path = Path()
      ..moveTo(0, -r * 0.8)
      ..cubicTo(r * 0.95, -r * 0.8, r * 0.9, r * 0.3, 0, r * 1.05)
      ..cubicTo(-r * 0.9, r * 0.3, -r * 0.95, -r * 0.8, 0, -r * 0.8)
      ..close();

    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [Color(0xFFFF1744), Color(0xFFD50000), Color(0xFF880E4F)],
      ).createShader(rect);
    canvas.drawPath(path, bodyPaint);

    // Golden seed specks with micro shadows
    final seedPaint = Paint()..color = const Color(0xFFFFF59D);
    final seedShadow = Paint()..color = const Color(0xFF4A0018);
    for (int y = -2; y <= 2; y++) {
      for (int x = -2; x <= 2; x++) {
        final sx = x * (r * 0.32) + (y.isOdd ? 6 : 0);
        final sy = y * (r * 0.32);
        if (sqrt(sx * sx + sy * sy) < r * 0.72) {
          canvas.drawCircle(Offset(sx + 1, sy + 1), 1.8, seedShadow);
          canvas.drawCircle(Offset(sx, sy), 1.5, seedPaint);
        }
      }
    }

    // Leafy green calyx crown
    final capPaint = Paint()..color = const Color(0xFF2E7D32);
    for (int i = 0; i < 5; i++) {
      final a = (i * 72) * pi / 180;
      final leaf = Path()
        ..moveTo(0, -r * 0.8)
        ..lineTo(cos(a) * (r * 0.45), -r * 0.8 + sin(a) * (r * 0.22))
        ..close();
      canvas.drawPath(leaf, capPaint);
    }
    canvas.drawCircle(Offset(0, -r * 0.8), r * 0.22, capPaint);

    _drawSpecularArc(canvas, r);
  }

  // Realistic Pineapple
  void _drawWholePineapple(Canvas canvas, double r) {
    final rect = Rect.fromCenter(center: Offset(0, r * 0.1), width: r * 1.6, height: r * 1.9);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.2),
        radius: 0.95,
        colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFE65100), Color(0xFF5D4037)],
      ).createShader(rect);
    canvas.drawOval(rect, bodyPaint);

    // Cross-hatched diamond scales
    final gridPaint = Paint()
      ..color = const Color(0xFF4E342E).withValues(alpha: 0.5)
      ..strokeWidth = 2.0;
    for (int i = -3; i <= 3; i++) {
      final o = i * (r * 0.38);
      canvas.drawLine(Offset(-r * 0.7 + o, -r * 0.6), Offset(r * 0.7 + o, r * 0.8), gridPaint);
      canvas.drawLine(Offset(r * 0.7 - o, -r * 0.6), Offset(-r * 0.7 - o, r * 0.8), gridPaint);
    }

    // Spiky crown of layered green leaves
    final crownPaint = Paint()..color = const Color(0xFF1B5E20);
    final crownPath = Path()
      ..moveTo(-r * 0.45, -r * 0.65)
      ..lineTo(-r * 0.7, -r * 1.35)
      ..lineTo(-r * 0.2, -r * 1.05)
      ..lineTo(0, -r * 1.5)
      ..lineTo(r * 0.2, -r * 1.05)
      ..lineTo(r * 0.7, -r * 1.35)
      ..lineTo(r * 0.45, -r * 0.65)
      ..close();
    canvas.drawPath(crownPath, crownPaint);
  }

  // Realistic Banana
  void _drawWholeBanana(Canvas canvas, double r) {
    final rect = Rect.fromCircle(center: Offset.zero, radius: r * 1.2);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF176),
          Color(0xFFFFEE58),
          Color(0xFFFBC02D),
          Color(0xFFF57F17),
        ],
      ).createShader(rect);

    // Curved crescent banana path
    final path = Path()
      ..moveTo(-r * 1.1, -r * 0.6)
      ..quadraticBezierTo(-r * 0.1, -r * 0.95, r * 0.9, -r * 0.25)
      ..quadraticBezierTo(r * 1.25, 0, r * 1.15, r * 0.5)
      ..quadraticBezierTo(r * 0.85, r * 0.15, -r * 0.05, -r * 0.35)
      ..quadraticBezierTo(-r * 0.85, -r * 0.45, -r * 1.1, -r * 0.6)
      ..close();
    canvas.drawPath(path, bodyPaint);

    // Facet ridge line
    final ridgePaint = Paint()
      ..color = const Color(0xFFE65100).withValues(alpha: 0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, ridgePaint);

    // Brown stem and tip
    final tipPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawCircle(Offset(-r * 1.1, -r * 0.6), 4.5, tipPaint);
    canvas.drawCircle(Offset(r * 1.15, r * 0.5), 4.0, tipPaint);
  }

  // Realistic Lemon
  void _drawWholeLemon(Canvas canvas, double r) {
    final path = Path()
      ..moveTo(-r * 1.1, 0)
      ..quadraticBezierTo(-r * 0.6, -r * 0.85, 0, -r * 0.85)
      ..quadraticBezierTo(r * 0.6, -r * 0.85, r * 1.1, 0)
      ..quadraticBezierTo(r * 0.6, r * 0.85, 0, r * 0.85)
      ..quadraticBezierTo(-r * 0.6, r * 0.85, -r * 1.1, 0)
      ..close();

    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [Color(0xFFFFF59D), Color(0xFFFFEE58), Color(0xFFFDD835), Color(0xFFF57F17)],
      ).createShader(rect);
    canvas.drawPath(path, bodyPaint);

    // Green leaf at top nub
    final leafPaint = Paint()..color = const Color(0xFF43A047);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(r * 0.9, -r * 0.3), width: r * 0.45, height: r * 0.2),
      leafPaint,
    );

    _drawSpecularArc(canvas, r);
  }

  // Realistic Pomegranate
  void _drawWholePomegranate(Canvas canvas, double r) {
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [Color(0xFFFF1744), Color(0xFFC2185B), Color(0xFF880E4F), Color(0xFF4A148C)],
      ).createShader(rect);
    canvas.drawCircle(Offset.zero, r, bodyPaint);

    // Crown calyx
    final crownPaint = Paint()..color = const Color(0xFFAD1457);
    final crown = Path()
      ..moveTo(-r * 0.28, -r * 0.95)
      ..lineTo(-r * 0.4, -r * 1.25)
      ..lineTo(-r * 0.12, -r * 1.1)
      ..lineTo(0, -r * 1.35)
      ..lineTo(r * 0.12, -r * 1.1)
      ..lineTo(r * 0.4, -r * 1.25)
      ..lineTo(r * 0.28, -r * 0.95)
      ..close();
    canvas.drawPath(crown, crownPaint);

    _drawSpecularArc(canvas, r);
  }

  void _drawSpecularArc(Canvas canvas, double r) {
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset.zero, radius: r * 0.72);
    canvas.drawArc(rect, -pi * 0.85, pi * 0.35, false, shinePaint);
  }

  // --------------------------------------------------------------------------
  // SLICED FRUITS RENDERING (Cut Cross-Sections)
  // --------------------------------------------------------------------------
  void _drawSlicedFruit(Canvas canvas, ActiveFruit fruit) {
    // Half 1
    canvas.save();
    canvas.translate(fruit.half1X, fruit.half1Y);
    canvas.rotate(fruit.half1Rotation);
    _drawFruitHalf(canvas, fruit, isLeft: true);
    canvas.restore();

    // Half 2
    canvas.save();
    canvas.translate(fruit.half2X, fruit.half2Y);
    canvas.rotate(fruit.half2Rotation);
    _drawFruitHalf(canvas, fruit, isLeft: false);
    canvas.restore();
  }

  void _drawFruitHalf(Canvas canvas, ActiveFruit fruit, {required bool isLeft}) {
    final r = fruit.radius;
    canvas.save();

    // Clip half circle along separation line
    final clipPath = Path()
      ..addRect(
        Rect.fromLTRB(
          isLeft ? -r * 1.5 : 0,
          -r * 1.5,
          isLeft ? 0 : r * 1.5,
          r * 1.5,
        ),
      );
    canvas.clipPath(clipPath);

    // Cross-section based on fruit type
    switch (fruit.type) {
      case FruitType.watermelon:
        // Dark rind
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFF1B5E20));
        // White inner rind
        canvas.drawCircle(Offset.zero, r * 0.92, Paint()..color = const Color(0xFFF1F8E9));
        // Succulent red pulp
        canvas.drawCircle(Offset.zero, r * 0.82, Paint()..color = const Color(0xFFFF1744));
        // Black watermelon seeds
        final seedPaint = Paint()..color = const Color(0xFF212121);
        for (int i = 0; i < 4; i++) {
          final a = (i * 0.5 - 0.75) * (isLeft ? -1 : 1);
          final d = r * 0.55;
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cos(a) * d, sin(a) * d), width: 4, height: 6),
            seedPaint,
          );
        }
        break;

      case FruitType.orange:
        // Orange rind
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFE65100));
        // White pith
        canvas.drawCircle(Offset.zero, r * 0.92, Paint()..color = const Color(0xFFFFF3E0));
        // Segments
        final wedgePaint = Paint()..color = const Color(0xFFFF9800);
        canvas.drawCircle(Offset.zero, r * 0.84, wedgePaint);
        // White radial spokes
        final spokePaint = Paint()
          ..color = const Color(0xFFFFF3E0)
          ..strokeWidth = 1.5;
        for (int i = 0; i < 6; i++) {
          final a = i * (pi / 3);
          canvas.drawLine(Offset.zero, Offset(cos(a) * r * 0.84, sin(a) * r * 0.84), spokePaint);
        }
        canvas.drawCircle(Offset.zero, r * 0.14, Paint()..color = const Color(0xFFFFF3E0));
        break;

      case FruitType.apple:
        // Red skin
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFD50000));
        // Crisp ivory flesh
        canvas.drawCircle(Offset.zero, r * 0.94, Paint()..color = const Color(0xFFFFFDE7));
        // Star core with brown seeds
        final seedPaint = Paint()..color = const Color(0xFF3E2723);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(isLeft ? -r * 0.2 : r * 0.2, 0), width: 3.5, height: 7),
          seedPaint,
        );
        break;

      case FruitType.mango:
        // Mango skin
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFFF6D00));
        // Saffron yellow luscious pulp
        canvas.drawCircle(Offset.zero, r * 0.93, Paint()..color = const Color(0xFFFFB300));
        // Seed outline
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 0.45, height: r * 0.75),
          Paint()..color = const Color(0xFFFFF8E1),
        );
        break;

      case FruitType.strawberry:
        // Red exterior
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFC2185B));
        // Pink-white interior
        canvas.drawCircle(Offset.zero, r * 0.90, Paint()..color = const Color(0xFFFFEBEE));
        break;

      case FruitType.pineapple:
        // Golden skin
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFF6D4C41));
        // Sunny yellow flesh
        canvas.drawCircle(Offset.zero, r * 0.90, Paint()..color = const Color(0xFFFFEE58));
        // Core circle
        canvas.drawCircle(Offset.zero, r * 0.28, Paint()..color = const Color(0xFFFFF9C4));
        break;

      case FruitType.banana:
        // Yellow peel
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFFBC02D));
        // Creamy pulp
        canvas.drawCircle(Offset.zero, r * 0.90, Paint()..color = const Color(0xFFFFFDE7));
        // 3 center seed specks
        final dotPaint = Paint()..color = const Color(0xFF3E2723);
        canvas.drawCircle(Offset(isLeft ? -3 : 3, -3), 1.5, dotPaint);
        canvas.drawCircle(Offset(isLeft ? -3 : 3, 3), 1.5, dotPaint);
        break;

      case FruitType.lemon:
        // Yellow peel
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFFDD835));
        // White pith
        canvas.drawCircle(Offset.zero, r * 0.92, Paint()..color = const Color(0xFFFFFDE7));
        // Lemon pulp
        canvas.drawCircle(Offset.zero, r * 0.84, Paint()..color = const Color(0xFFFFF59D));
        break;

      case FruitType.pomegranate:
        // Red skin
        canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFF880E4F));
        // White pith
        canvas.drawCircle(Offset.zero, r * 0.90, Paint()..color = const Color(0xFFFFF9C4));
        // Ruby arils
        final arilPaint = Paint()..color = const Color(0xFFD81B60);
        for (int i = 0; i < 6; i++) {
          final a = i * (pi / 3);
          final d = r * 0.5;
          canvas.drawCircle(Offset(cos(a) * d, sin(a) * d), 4.5, arilPaint);
        }
        break;
    }

    // Cut edge sheen
    final cutEdgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, -r), Offset(0, r), cutEdgePaint);

    canvas.restore();
  }

  // --------------------------------------------------------------------------
  // FLYING JUICE PARTICLES
  // --------------------------------------------------------------------------
  void _drawJuiceDroplets(Canvas canvas) {
    for (final drop in juiceDrops) {
      final paint = Paint()
        ..color = drop.color.withValues(alpha: drop.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(drop.x, drop.y), drop.size, paint);
    }
  }

  // --------------------------------------------------------------------------
  // LETTER REVEAL POPUP BANNERS (Pop from inside sliced fruit!)
  // --------------------------------------------------------------------------
  void _drawLetterPops(Canvas canvas) {
    for (final pop in letterPops) {
      canvas.save();
      canvas.translate(pop.x, pop.y);
      canvas.scale(pop.scale);

      // Glowing aura
      final auraPaint = Paint()
        ..color = const Color(0xFFFFD600).withValues(alpha: 0.45 * pop.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(Offset.zero, 48, auraPaint);

      // Translucent frosted badge background
      final bgPaint = Paint()
        ..color = const Color(0xFF1E1B2E).withValues(alpha: 0.88 * pop.opacity);
      final borderPaint = Paint()
        ..color = const Color(0xFFFFD600).withValues(alpha: pop.opacity)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 88, height: 78),
        const Radius.circular(20),
      );
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);

      // Big Glowing Tamil Letter
      final letterPainter = TextPainter(
        text: TextSpan(
          text: pop.letter,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFD600).withValues(alpha: pop.opacity),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      letterPainter.paint(
        canvas,
        Offset(-letterPainter.width / 2, -30),
      );

      // Tamil Word beneath
      if (pop.word.isNotEmpty) {
        final wordPainter = TextPainter(
          text: TextSpan(
            text: pop.word,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: pop.opacity),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        wordPainter.paint(
          canvas,
          Offset(-wordPainter.width / 2, 10),
        );
      }

      canvas.restore();
    }
  }

  // --------------------------------------------------------------------------
  // BLADE SWIPE TRAIL
  // --------------------------------------------------------------------------
  void _drawBladeTrail(Canvas canvas) {
    if (bladePoints.length < 2) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < bladePoints.length - 1; i++) {
      final p1 = bladePoints[i].position;
      final p2 = bladePoints[i + 1].position;
      final ageMs = nowMs - bladePoints[i].timestampMs;
      final progress = (1.0 - (ageMs / 180.0)).clamp(0.0, 1.0);

      // Outer cyan-white glowing blade
      final glowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: progress * 0.75)
        ..strokeWidth = 9.0 * progress
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(p1, p2, glowPaint);

      // Bright white blade core
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: progress)
        ..strokeWidth = 3.5 * progress
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FruitNinjaScenePainter oldDelegate) => true;
}
