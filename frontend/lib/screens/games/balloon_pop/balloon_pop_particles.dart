import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'balloon_pop_models.dart';

/// Painter for popping effects: exploding rubber shards, glittering sparkles,
/// and floating positive Tamil feedback words.
class BalloonPopParticlePainter extends CustomPainter {
  final List<PopShard> shards;
  final List<SparkleParticle> sparkles;
  final List<FloatingFeedback> feedbacks;

  BalloonPopParticlePainter({
    required this.shards,
    required this.sparkles,
    required this.feedbacks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw rubber shards
    for (final s in shards) {
      if (s.opacity <= 0.0) continue;
      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.rotation);

      final shardPaint = Paint()
        ..color = s.color.withValues(alpha: s.opacity)
        ..style = PaintingStyle.fill;

      // Realistic irregular curved rubber fragment
      final shardPath = Path();
      final halfS = s.size / 2;
      shardPath.moveTo(-halfS, -halfS * 0.6);
      shardPath.quadraticBezierTo(0, -halfS * 1.2, halfS, -halfS * 0.4);
      shardPath.lineTo(halfS * 0.8, halfS * 0.8);
      shardPath.quadraticBezierTo(0, halfS * 0.4, -halfS * 0.9, halfS * 0.7);
      shardPath.close();

      canvas.drawPath(shardPath, shardPaint);

      // Add shiny gloss highlight on shard edge
      final glossPaint = Paint()
        ..color = Colors.white.withValues(alpha: s.opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(shardPath, glossPaint);

      canvas.restore();
    }

    // 2. Draw sparkling stars and glitter particles
    for (final p in sparkles) {
      if (p.opacity <= 0.0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      // Draw 4-point star sparkle
      _drawStar(canvas, p.x, p.y, p.size, paint);
    }

    // 3. Draw floating positive Tamil feedback phrases
    for (final f in feedbacks) {
      if (f.opacity <= 0.0) continue;

      final textStyle = GoogleFonts.catamaran(
        fontSize: 22 * f.scale,
        fontWeight: FontWeight.w900,
        color: const Color(0xFFFF6F00).withValues(alpha: f.opacity),
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: f.opacity * 0.9),
            blurRadius: 8,
          ),
          Shadow(
            color: Colors.black.withValues(alpha: f.opacity * 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );

      final span = TextSpan(text: f.text, style: textStyle);
      final tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(f.x - tp.width / 2, f.y - tp.height / 2));
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double radius, Paint paint) {
    final path = Path();
    final innerRadius = radius * 0.35;
    const numPoints = 4;
    final angleStep = pi / numPoints;

    for (int i = 0; i < numPoints * 2; i++) {
      final r = (i % 2 == 0) ? radius : innerRadius;
      final angle = i * angleStep - pi / 2;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BalloonPopParticlePainter oldDelegate) => true;
}

/// Helper to generate explosion particles when a balloon pops
class BalloonPopExplosionFactory {
  static void spawn({
    required Offset center,
    required BalloonColor color,
    required List<PopShard> shards,
    required List<SparkleParticle> sparkles,
  }) {
    final rng = Random();
    final theme = BalloonColorTheme.forColor(color);

    // 1. Spawn 14 rubber shards flying in all directions
    const shardCount = 14;
    for (int i = 0; i < shardCount; i++) {
      final angle = (i / shardCount) * 2 * pi + (rng.nextDouble() - 0.5) * 0.4;
      final speed = 160.0 + rng.nextDouble() * 260.0;
      final size = 10.0 + rng.nextDouble() * 12.0;

      shards.add(
        PopShard(
          x: center.dx,
          y: center.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 60.0, // slight upward kick
          size: size,
          rotation: rng.nextDouble() * 2 * pi,
          vRot: (rng.nextDouble() - 0.5) * 12.0,
          color: rng.nextBool() ? theme.baseColor : theme.highlightColor,
        ),
      );
    }

    // 2. Spawn 16 glittering stars & sparkles
    const sparkleCount = 16;
    for (int i = 0; i < sparkleCount; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 80.0 + rng.nextDouble() * 200.0;
      final size = 6.0 + rng.nextDouble() * 8.0;

      sparkles.add(
        SparkleParticle(
          x: center.dx,
          y: center.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: size,
          color: rng.nextBool()
              ? const Color(0xFFFFD700) // Golden star
              : Colors.white,
        ),
      );
    }
  }
}
