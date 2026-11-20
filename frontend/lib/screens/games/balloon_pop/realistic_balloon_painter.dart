import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'balloon_pop_models.dart';

/// Highly realistic 3D inflated latex balloon custom painter.
/// Features true teardrop volume, multi-layer glossy reflections,
/// spherical depth shading, tied knot, and fluttering thread.
class RealisticBalloonPainter extends CustomPainter {
  final String letter;
  final BalloonColor color;
  final double radius;
  final double wobble; // Gentle sway / wobble angle in radians
  final double popProgress; // 0.0 = intact, >0 = bursting

  RealisticBalloonPainter({
    required this.letter,
    required this.color,
    required this.radius,
    this.wobble = 0.0,
    this.popProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (popProgress >= 0.85) return; // Completely popped

    final theme = BalloonColorTheme.forColor(color);
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Apply gentle elastic wobble and tilt
    canvas.save();
    canvas.translate(cx, cy);
    if (wobble != 0.0) {
      canvas.rotate(wobble * 0.12);
      final squish = sin(wobble * 2.0) * 0.04;
      canvas.scale(1.0 + squish, 1.0 - squish);
    }

    if (popProgress > 0.0) {
      // Flash expand slightly before fragmenting
      final popScale = 1.0 + popProgress * 0.35;
      canvas.scale(popScale, popScale);
    }

    final double w = radius * 2.0;
    final double h = radius * 2.55; // Natural teardrop ratio
    final double left = -w / 2;
    final double top = -h / 2;

    // 1. Generate Realistic Inflated Teardrop Path
    final balloonPath = _createBalloonPath(w, h, top);

    // 2. Soft Ambient Drop Shadow for floating depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.save();
    canvas.translate(2.0, 10.0);
    canvas.drawPath(balloonPath, shadowPaint);
    canvas.restore();

    // 3. Base 3D Spherical Volume (Radial Gradient offset to top-left light source)
    final lightFocalX = -w * 0.18;
    final lightFocalY = top + h * 0.30;
    final sphereGradient = RadialGradient(
      center: Alignment(lightFocalX / (w / 2), (lightFocalY - top) / (h / 2) - 1.0),
      radius: 0.95,
      colors: [
        Color.lerp(theme.baseColor, Colors.white, 0.55)!, // Bright specular core
        Color.lerp(theme.baseColor, Colors.white, 0.18)!, // Soft illuminated latex
        theme.baseColor,                                  // True saturated latex
        theme.shadowColor,                                // 3D Spherical shadow
        theme.darkEdgeColor,                              // Deep edge curvature
      ],
      stops: const [0.0, 0.22, 0.52, 0.82, 1.0],
    );

    final basePaint = Paint()
      ..shader = sphereGradient.createShader(
        Rect.fromLTWH(left, top, w, h),
      );
    canvas.drawPath(balloonPath, basePaint);

    // 4. Crescent Edge Depth (Dark inner shadow along bottom-right edge)
    canvas.save();
    canvas.clipPath(balloonPath);

    final edgeShadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.45, 0.55),
        radius: 0.85,
        colors: [
          Colors.transparent,
          theme.darkEdgeColor.withValues(alpha: 0.45),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Rect.fromLTWH(left, top, w, h));
    canvas.drawRect(Rect.fromLTWH(left, top, w, h), edgeShadowPaint);

    // 5. Translucent Latex Rim Light (Soft glowing edge reflecting sky)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.transparent,
          theme.highlightColor.withValues(alpha: 0.40),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(left, top, w, h));
    canvas.drawPath(balloonPath, rimPaint);

    // 6. Primary Curved Glossy Specular Highlight (The signature shiny latex reflection!)
    _drawGlossySpecularHighlight(canvas, w, h, top);

    // 7. Secondary Soft Ground Bounce Reflection (Lower right curve)
    final bounceGleamPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.55, 0.40),
        radius: 0.35,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(left, top, w, h));
    canvas.drawCircle(
      Offset(w * 0.22, top + h * 0.62),
      w * 0.18,
      bounceGleamPaint,
    );

    canvas.restore(); // Exit clipPath

    // 8. Tied Latex Neck Flange & Puckered Knot at Bottom
    _drawBalloonKnot(canvas, w, h, top, theme);

    // 9. Floating / Dangling String (Waving naturally with air breeze)
    _drawDanglingString(canvas, w, h, top, theme);

    // 10. Center Tamil Letter with 3D Surface Impression
    _drawTamilLetter(canvas, w, h, top, theme);

    canvas.restore();
  }

  /// Creates a smooth, natural egg/teardrop inflated latex balloon contour
  Path _createBalloonPath(double w, double h, double top) {
    final path = Path();
    final halfW = w * 0.50;
    final shoulderY = top + h * 0.36; // Maximum bulbous width point
    final neckY = top + h * 0.92;     // Where balloon tapers down to knot
    final neckHalfW = w * 0.085;

    // Start at top dome center
    path.moveTo(0, top);

    // Right dome & shoulder
    path.cubicTo(
      halfW * 0.55, top,              // CP1
      halfW, top + h * 0.14,          // CP2
      halfW, shoulderY,               // Right widest point
    );

    // Right lower taper down to narrow neck
    path.cubicTo(
      halfW, top + h * 0.62,          // CP1
      neckHalfW * 2.2, top + h * 0.82,// CP2
      neckHalfW, neckY,               // Right neck base
    );

    // Neck flare lips
    path.lineTo(neckHalfW * 1.3, neckY + h * 0.025);
    path.lineTo(-neckHalfW * 1.3, neckY + h * 0.025);
    path.lineTo(-neckHalfW, neckY);

    // Left lower taper up to shoulder
    path.cubicTo(
      -neckHalfW * 2.2, top + h * 0.82,// CP1
      -halfW, top + h * 0.62,          // CP2
      -halfW, shoulderY,               // Left widest point
    );

    // Left shoulder & top dome
    path.cubicTo(
      -halfW, top + h * 0.14,          // CP1
      -halfW * 0.55, top,              // CP2
      0, top,                          // Close at top center
    );

    path.close();
    return path;
  }

  /// Realistic curved specular highlight matching 3D spherical curvature
  void _drawGlossySpecularHighlight(Canvas canvas, double w, double h, double top) {
    // 1. Primary curved gloss crescent
    final highlightPath = Path();
    final hx = -w * 0.24;
    final hy = top + h * 0.16;

    highlightPath.moveTo(hx, hy);
    highlightPath.cubicTo(
      hx - w * 0.10, hy + h * 0.08,
      hx - w * 0.12, hy + h * 0.22,
      hx - w * 0.04, hy + h * 0.32,
    );
    highlightPath.cubicTo(
      hx - w * 0.08, hy + h * 0.24,
      hx - w * 0.06, hy + h * 0.12,
      hx, hy,
    );
    highlightPath.close();

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.88),
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(-w / 2, top, w, h));

    canvas.drawPath(highlightPath, highlightPaint);

    // 2. Small sharp sun-reflection dot
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-w * 0.18, top + h * 0.13),
        width: w * 0.09,
        height: h * 0.055,
      ),
      dotPaint,
    );
  }

  /// Realistic gathered rubber knot tied at the neck
  void _drawBalloonKnot(
    Canvas canvas,
    double w,
    double h,
    double top,
    BalloonColorTheme theme,
  ) {
    final knotY = top + h * 0.945;
    final knotRadius = w * 0.095;

    // Knot drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(Offset(0, knotY + 2.0), knotRadius, shadowPaint);

    // 3D Knot Sphere Gradient
    final knotPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.8,
        colors: [
          theme.highlightColor,
          theme.baseColor,
          theme.darkEdgeColor,
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(0, knotY), radius: knotRadius),
      );
    canvas.drawCircle(Offset(0, knotY), knotRadius, knotPaint);

    // Knot gather crease line (wrinkle fold)
    final creasePaint = Paint()
      ..color = theme.darkEdgeColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(-knotRadius * 0.55, knotY),
      Offset(knotRadius * 0.55, knotY),
      creasePaint,
    );
  }

  /// Wavy dangling thread/string swinging with natural physics
  void _drawDanglingString(
    Canvas canvas,
    double w,
    double h,
    double top,
    BalloonColorTheme theme,
  ) {
    final startY = top + h * 0.96;
    final stringLength = h * 0.38;

    final stringPath = Path()..moveTo(0, startY);

    // Natural waving cubic bezier curve
    final sway1 = sin(wobble * 1.5) * 8.0;
    final sway2 = cos(wobble * 1.8) * 10.0;

    stringPath.cubicTo(
      sway1, startY + stringLength * 0.30,
      sway2, startY + stringLength * 0.70,
      sway1 * 0.5, startY + stringLength,
    );

    final stringPaint = Paint()
      ..color = const Color(0xFFF1F5F9).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;

    canvas.drawPath(stringPath, stringPaint);
  }

  /// Centers Tamil letter clearly on the front belly with high contrast
  void _drawTamilLetter(
    Canvas canvas,
    double w,
    double h,
    double top,
    BalloonColorTheme theme,
  ) {
    if (letter.isEmpty) return;

    // Centered at natural visual center of balloon belly
    final centerLetterY = top + h * 0.44;

    // Adapt font size dynamically based on Tamil letter length (single vs compound)
    double fontSize = radius * 0.80;
    if (letter.length > 2) {
      fontSize = radius * 0.55;
    } else if (letter.length == 2) {
      fontSize = radius * 0.68;
    }

    final textStyle = GoogleFonts.catamaran(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: theme.textColor,
      shadows: [
        // Soft drop shadow gives 3D printed appearance on rubber skin
        BoxShadow(
          color: Colors.black.withValues(alpha: theme.textColor == Colors.white ? 0.35 : 0.12),
          blurRadius: 4.0,
          offset: const Offset(0, 2.0),
        ),
      ],
    );

    final textSpan = TextSpan(text: letter, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      -textPainter.width / 2,
      centerLetterY - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant RealisticBalloonPainter oldDelegate) {
    return oldDelegate.letter != letter ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.wobble != wobble ||
        oldDelegate.popProgress != popProgress;
  }
}
