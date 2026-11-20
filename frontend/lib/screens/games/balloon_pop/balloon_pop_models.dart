import 'dart:math';
import 'package:flutter/material.dart';

/// Available realistic latex balloon colors
enum BalloonColor {
  red,
  blue,
  yellow,
  green,
  purple,
  orange,
  pink,
}

/// Color theme properties for realistic 3D latex shading
class BalloonColorTheme {
  final Color highlightColor;   // Specular / light reflection tint
  final Color baseColor;        // Main inflated latex color
  final Color shadowColor;      // Deep 3D sphere gradient shadow
  final Color darkEdgeColor;    // Darkest rim & crease shadow
  final Color textColor;        // High contrast letter text color
  final Color stringColor;      // Tied thread / string color

  const BalloonColorTheme({
    required this.highlightColor,
    required this.baseColor,
    required this.shadowColor,
    required this.darkEdgeColor,
    required this.textColor,
    required this.stringColor,
  });

  static BalloonColorTheme forColor(BalloonColor color) {
    switch (color) {
      case BalloonColor.red:
        return const BalloonColorTheme(
          highlightColor: Color(0xFFFF8DA1),
          baseColor: Color(0xFFE52D4B),
          shadowColor: Color(0xFF990B22),
          darkEdgeColor: Color(0xFF5C0010),
          textColor: Colors.white,
          stringColor: Color(0xFFFFCDD2),
        );
      case BalloonColor.blue:
        return const BalloonColorTheme(
          highlightColor: Color(0xFF90CAF9),
          baseColor: Color(0xFF1E88E5),
          shadowColor: Color(0xFF0D47A1),
          darkEdgeColor: Color(0xFF051E4E),
          textColor: Colors.white,
          stringColor: Color(0xFFBBDEFB),
        );
      case BalloonColor.yellow:
        return const BalloonColorTheme(
          highlightColor: Color(0xFFFFFDE7),
          baseColor: Color(0xFFFFC107),
          shadowColor: Color(0xFFE65100),
          darkEdgeColor: Color(0xFFBF360C),
          textColor: Color(0xFF3E2723), // Dark rich brown for high contrast on yellow
          stringColor: Color(0xFFFFECB3),
        );
      case BalloonColor.green:
        return const BalloonColorTheme(
          highlightColor: Color(0xFFA5D6A7),
          baseColor: Color(0xFF43A047),
          shadowColor: Color(0xFF1B5E20),
          darkEdgeColor: Color(0xFF0A300E),
          textColor: Colors.white,
          stringColor: Color(0xFFC8E6C9),
        );
      case BalloonColor.purple:
        return const BalloonColorTheme(
          highlightColor: Color(0xFFE1BEE7),
          baseColor: Color(0xFF8E24AA),
          shadowColor: Color(0xFF4A148C),
          darkEdgeColor: Color(0xFF26054D),
          textColor: Colors.white,
          stringColor: Color(0xFFE1BEE7),
        );
      case BalloonColor.orange:
        return const BalloonColorTheme(
          highlightColor: Color(0xFFFFE0B2),
          baseColor: Color(0xFFFB8C00),
          shadowColor: Color(0xFFBF360C),
          darkEdgeColor: Color(0xFF6D1B00),
          textColor: Colors.white,
          stringColor: Color(0xFFFFE0B2),
        );
      case BalloonColor.pink:
        return const BalloonColorTheme(
          highlightColor: Color(0xFFF8BBD0),
          baseColor: Color(0xFFE91E63),
          shadowColor: Color(0xFF880E4F),
          darkEdgeColor: Color(0xFF430325),
          textColor: Colors.white,
          stringColor: Color(0xFFF8BBD0),
        );
    }
  }

  static BalloonColor randomColor([Random? rng]) {
    final r = rng ?? Random();
    const colors = BalloonColor.values;
    return colors[r.nextInt(colors.length)];
  }
}

/// Active floating balloon entity in the game arena
class FloatingBalloon {
  final int id;
  final String letter;
  final BalloonColor color;
  final double radius;         // Visual size scale (typical 42.0 to 48.0)
  final double speed;          // Floating speed in px/sec
  final double swayAmplitude;  // Horizontal sinusoidal sway amplitude
  final double swayFrequency;  // Horizontal sinusoidal sway frequency
  final double phase;          // Initial wave phase

  double x;                    // Current center X
  double y;                    // Current center Y
  double baseX;                // Base horizontal center around which it sways
  double age;                  // Age in seconds for continuous oscillation
  bool isPopping;              // Currently undergoing pop animation
  double popProgress;          // 0.0 to 1.0 pop burst progress
  double wrongWobbleTimer;     // Wobble timer on wrong tap

  FloatingBalloon({
    required this.id,
    required this.letter,
    required this.color,
    required this.radius,
    required this.speed,
    required this.swayAmplitude,
    required this.swayFrequency,
    required this.phase,
    required this.x,
    required this.y,
  })  : baseX = x,
        age = 0.0,
        isPopping = false,
        popProgress = 0.0,
        wrongWobbleTimer = 0.0;

  /// Check if a touch point hits this balloon (accounting for realistic teardrop shape)
  bool hitTest(Offset point) {
    if (isPopping) return false;
    final dx = (point.dx - x);
    // Balloon center of gravity is slightly above geometric center
    final dy = (point.dy - (y - radius * 0.1));
    // Elliptical hit test matching teardrop envelope
    final rx = radius * 1.05;
    final ry = radius * 1.35;
    return ((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry)) <= 1.0;
  }
}

/// Popping rubber fragment particle
class PopShard {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double rotation;
  double vRot;
  Color color;
  double opacity;

  PopShard({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.vRot,
    required this.color,
    this.opacity = 1.0,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 380 * dt; // Gravity
    vx *= 0.98;     // Air friction
    rotation += vRot * dt;
    opacity = (opacity - 1.8 * dt).clamp(0.0, 1.0);
  }
}

/// Sparkle / star burst particle
class SparkleParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double opacity;

  SparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 120 * dt;
    opacity = (opacity - 2.2 * dt).clamp(0.0, 1.0);
  }
}

/// Floating positive Tamil feedback message
class FloatingFeedback {
  final String text;
  double x;
  double y;
  double opacity;
  double scale;

  FloatingFeedback({
    required this.text,
    required this.x,
    required this.y,
    this.opacity = 1.0,
    this.scale = 0.6,
  });

  void update(double dt) {
    y -= 50 * dt; // Float up
    if (scale < 1.0) {
      scale = (scale + 3.0 * dt).clamp(0.0, 1.0);
    }
    opacity = (opacity - 1.4 * dt).clamp(0.0, 1.0);
  }
}
