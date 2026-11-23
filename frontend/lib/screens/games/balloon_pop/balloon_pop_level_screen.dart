import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/audio_service.dart';
import '../../../services/progress_service.dart';
import '../../../widgets/bouncy_button.dart';
import 'balloon_pop_data.dart';
import 'balloon_pop_gameplay_screen.dart';
import 'balloon_pop_models.dart';
import 'balloon_pop_progress.dart';
import 'realistic_balloon_painter.dart';

class BalloonPopLevelScreen extends StatefulWidget {
  final ProgressService progressService;

  const BalloonPopLevelScreen({
    super.key,
    required this.progressService,
  });

  @override
  State<BalloonPopLevelScreen> createState() => _BalloonPopLevelScreenState();
}

class _BalloonPopLevelScreenState extends State<BalloonPopLevelScreen>
    with SingleTickerProviderStateMixin {
  late final BalloonPopProgressService _balloonProgress;
  late final AnimationController _cloudController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _balloonProgress = BalloonPopProgressService();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _loadData();
  }

  Future<void> _loadData() async {
    await _balloonProgress.load();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  int get _totalStarsEarned {
    int count = 0;
    for (int i = 1; i <= 3; i++) {
      count += _balloonProgress.getLevelStars(i);
    }
    return count;
  }

  void _onLevelTap(int levelNumber, bool isUnlocked) {
    if (!isUnlocked) {
      HapticFeedback.lightImpact();
      final levelInfo = balloonLevels[levelNumber - 1];
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  levelInfo.lockRequirementTa,
                  style: GoogleFonts.catamaran(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF37474F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    AudioService.instance.playPopSound();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BalloonPopGameplayScreen(
          levelNumber: levelNumber,
          progressService: widget.progressService,
          balloonProgress: _balloonProgress,
        ),
      ),
    ).then((_) {
      // Refresh progress upon returning
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4FC3F7),
      body: Stack(
        children: [
          // 1. Sky & Soft Clouds Animated Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF29B6F6),
                    Color(0xFF4FC3F7),
                    Color(0xFF81D4FA),
                    Color(0xFFE1F5FE),
                  ],
                  stops: [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Animated drifting clouds
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LevelCloudsPainter(_cloudController.value),
                );
              },
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          children: [
                            for (int i = 0; i < balloonLevels.length; i++) ...[
                              _buildLevelCard(balloonLevels[i]),
                              const SizedBox(height: 16),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          BouncyButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF0277BD),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'பலூன் உடைத்தல்',
                    style: GoogleFonts.catamaran(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'நிலையைத் தேர்ந்தெடுங்கள்',
                    style: GoogleFonts.catamaran(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // Stars badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_totalStarsEarned/9',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BalloonLevelInfo level) {
    final bool isUnlocked = _balloonProgress.isLevelUnlocked(level.levelNumber);
    final bool isCompleted =
        _balloonProgress.isLevelCompleted(level.levelNumber);
    final int stars = _balloonProgress.getLevelStars(level.levelNumber);
    final int highScore =
        _balloonProgress.getLevelHighScore(level.levelNumber);

    // Color theme per level
    final List<Color> unlockedColors;
    final Color accentColor;
    final String sampleLetter;
    final BalloonPalette previewPalette;

    switch (level.levelNumber) {
      case 1:
        unlockedColors = [const Color(0xFFFF5252), const Color(0xFFFF7A00)];
        accentColor = const Color(0xFFFF5252);
        sampleLetter = 'அ';
        previewPalette = BalloonPalettes.red;
        break;
      case 2:
        unlockedColors = [const Color(0xFF7C4DFF), const Color(0xFF536DFE)];
        accentColor = const Color(0xFF7C4DFF);
        sampleLetter = 'க்';
        previewPalette = BalloonPalettes.purple;
        break;
      case 3:
      default:
        unlockedColors = [const Color(0xFF00B0FF), const Color(0xFF00BFA5)];
        accentColor = const Color(0xFF00B0FF);
        sampleLetter = 'க';
        previewPalette = BalloonPalettes.blue;
        break;
    }

    return BouncyButton(
      onPressed: () => _onLevelTap(level.levelNumber, isUnlocked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isUnlocked
              ? LinearGradient(
                  colors: unlockedColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? accentColor.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isUnlocked ? 14 : 8,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isUnlocked
                ? Colors.white.withValues(alpha: 0.4)
                : const Color(0xFFB0BEC5),
            width: isUnlocked ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Subtle background gloss shine
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(
                      alpha: isUnlocked ? 0.12 : 0.06,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Level Badge, Completion Tag & Lock / Stars
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Level number bubble
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'நிலை ${level.levelNumber}',
                            style: GoogleFonts.catamaran(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isUnlocked
                                  ? Colors.white
                                  : const Color(0xFF546E7A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Completed badge
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'முடிந்தது',
                                  style: GoogleFonts.catamaran(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const Spacer(),

                        // If locked: lock icon
                        if (!isUnlocked)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF78909C),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Middle row: Realistic Balloon Preview + Large Clear Tamil Title (Single Unbroken Line)
                    Row(
                      children: [
                        // Realistic 3D Balloon graphic preview
                        SizedBox(
                          width: 64,
                          height: 76,
                          child: isUnlocked
                              ? CustomPaint(
                                  painter: RealisticBalloonPainter(
                                    letter: sampleLetter,
                                    palette: previewPalette,
                                    wobble: 0.0,
                                    scale: 1.1,
                                    opacity: 1.0,
                                  ),
                                )
                              : Opacity(
                                  opacity: 0.45,
                                  child: CustomPaint(
                                    painter: RealisticBalloonPainter(
                                      letter: sampleLetter,
                                      palette: BalloonPalettes.purple,
                                      wobble: 0.0,
                                      scale: 0.95,
                                      opacity: 0.5,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),

                        // Title: Large, bold and clear Tamil text on a single line
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              level.nameTa,
                              style: GoogleFonts.catamaran(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isUnlocked
                                    ? Colors.white
                                    : const Color(0xFF455A64),
                                shadows: isUnlocked
                                    ? [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Bottom row: Status message or Play Button
                    if (!isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB0BEC5).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFF546E7A),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                level.lockRequirementTa,
                                style: GoogleFonts.catamaran(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF37474F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          if (highScore > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.military_tech_rounded,
                                    color: Color(0xFFFFD54F),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'உயர்ந்த புள்ளி: $highScore',
                                    style: GoogleFonts.catamaran(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),

                          // Play / Replay Action Button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.replay_rounded
                                      : Icons.play_arrow_rounded,
                                  color: accentColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isCompleted ? 'மீண்டும்' : 'விளையாடு',
                                  style: GoogleFonts.catamaran(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drifting decorative sky clouds painter
class _LevelCloudsPainter extends CustomPainter {
  final double animationValue;

  _LevelCloudsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final cloudPositions = [
      Offset((animationValue * size.width * 1.5) % (size.width + 160) - 80, 40),
      Offset(((animationValue + 0.35) * size.width * 1.2) % (size.width + 160) - 80, 140),
      Offset(((animationValue + 0.7) * size.width * 1.4) % (size.width + 160) - 80, 280),
      Offset(((animationValue + 0.5) * size.width * 1.1) % (size.width + 160) - 80, 460),
    ];

    for (final pos in cloudPositions) {
      _drawCloud(canvas, pos, cloudPaint);
    }
  }

  void _drawCloud(Canvas canvas, Offset pos, Paint paint) {
    canvas.drawCircle(pos, 28, paint);
    canvas.drawCircle(pos.translate(-22, 6), 20, paint);
    canvas.drawCircle(pos.translate(22, 6), 22, paint);
    canvas.drawCircle(pos.translate(0, 8), 24, paint);
  }

  @override
  bool shouldRepaint(covariant _LevelCloudsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
