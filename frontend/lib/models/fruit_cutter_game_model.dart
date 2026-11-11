import 'dart:ui';
import '../models/letter_model.dart';

/// Available fruit types for slicing
enum FruitType {
  watermelon,
  orange,
  mango,
  apple,
  strawberry,
  pineapple,
  banana,
  lemon,
  pomegranate,
}

/// Metadata and color profiles for each fruit
class FruitMeta {
  final FruitType type;
  final String nameTa;
  final String nameEn;
  final Color primaryColor;
  final Color secondaryColor;
  final Color pulpColor;
  final Color juiceColor;
  final double defaultRadius;
  final int points;

  const FruitMeta({
    required this.type,
    required this.nameTa,
    required this.nameEn,
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulpColor,
    required this.juiceColor,
    this.defaultRadius = 46.0,
    this.points = 10,
  });

  static const Map<FruitType, FruitMeta> fruitCatalog = {
    FruitType.watermelon: FruitMeta(
      type: FruitType.watermelon,
      nameTa: 'தர்பூசணி',
      nameEn: 'Watermelon',
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF1B5E20),
      pulpColor: Color(0xFFFF1744),
      juiceColor: Color(0xFFFF1744),
      defaultRadius: 52.0,
      points: 10,
    ),
    FruitType.orange: FruitMeta(
      type: FruitType.orange,
      nameTa: 'ஆரஞ்சு',
      nameEn: 'Orange',
      primaryColor: Color(0xFFFF9800),
      secondaryColor: Color(0xFFE65100),
      pulpColor: Color(0xFFFFB74D),
      juiceColor: Color(0xFFFF9800),
      defaultRadius: 44.0,
      points: 10,
    ),
    FruitType.mango: FruitMeta(
      type: FruitType.mango,
      nameTa: 'மாம்பழம்',
      nameEn: 'Mango',
      primaryColor: Color(0xFFFFB300),
      secondaryColor: Color(0xFFFF6F00),
      pulpColor: Color(0xFFFFCA28),
      juiceColor: Color(0xFFFFB300),
      defaultRadius: 48.0,
      points: 15,
    ),
    FruitType.apple: FruitMeta(
      type: FruitType.apple,
      nameTa: 'ஆப்பிள்',
      nameEn: 'Apple',
      primaryColor: Color(0xFFE53935),
      secondaryColor: Color(0xFFB71C1C),
      pulpColor: Color(0xFFFFFDE7),
      juiceColor: Color(0xFFFF5252),
      defaultRadius: 45.0,
      points: 10,
    ),
    FruitType.strawberry: FruitMeta(
      type: FruitType.strawberry,
      nameTa: 'செம்புற்று',
      nameEn: 'Strawberry',
      primaryColor: Color(0xFFE91E63),
      secondaryColor: Color(0xFF880E4F),
      pulpColor: Color(0xFFFF80AB),
      juiceColor: Color(0xFFE91E63),
      defaultRadius: 40.0,
      points: 12,
    ),
    FruitType.pineapple: FruitMeta(
      type: FruitType.pineapple,
      nameTa: 'அன்னாசி',
      nameEn: 'Pineapple',
      primaryColor: Color(0xFFFFA000),
      secondaryColor: Color(0xFF795548),
      pulpColor: Color(0xFFFFF176),
      juiceColor: Color(0xFFFFD54F),
      defaultRadius: 50.0,
      points: 15,
    ),
    FruitType.banana: FruitMeta(
      type: FruitType.banana,
      nameTa: 'வாழைப்பழம்',
      nameEn: 'Banana',
      primaryColor: Color(0xFFFFEB3B),
      secondaryColor: Color(0xFFFBC02D),
      pulpColor: Color(0xFFFFFDE7),
      juiceColor: Color(0xFFFFF9C4),
      defaultRadius: 46.0,
      points: 12,
    ),
    FruitType.lemon: FruitMeta(
      type: FruitType.lemon,
      nameTa: 'எலுமிச்சை',
      nameEn: 'Lemon',
      primaryColor: Color(0xFFFFEE58),
      secondaryColor: Color(0xFFFDD835),
      pulpColor: Color(0xFFFFF59D),
      juiceColor: Color(0xFFFFF176),
      defaultRadius: 42.0,
      points: 10,
    ),
    FruitType.pomegranate: FruitMeta(
      type: FruitType.pomegranate,
      nameTa: 'மாதுளை',
      nameEn: 'Pomegranate',
      primaryColor: Color(0xFFC2185B),
      secondaryColor: Color(0xFF880E4F),
      pulpColor: Color(0xFFFF4081),
      juiceColor: Color(0xFFE91E63),
      defaultRadius: 45.0,
      points: 12,
    ),
  };
}

/// Active flying or sliced fruit entity
class ActiveFruit {
  final int id;
  final FruitType type;
  final LetterModel letterModel;

  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double angularVelocity;
  final double radius;

  bool isSliced;
  double sliceAngle;
  double sliceProgress;
  double half1X;
  double half1Y;
  double half1Vx;
  double half1Vy;
  double half1Rotation;
  double half1AngularVelocity;

  double half2X;
  double half2Y;
  double half2Vx;
  double half2Vy;
  double half2Rotation;
  double half2AngularVelocity;

  ActiveFruit({
    required this.id,
    required this.type,
    required this.letterModel,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    this.rotation = 0.0,
    this.angularVelocity = 0.02,
    this.isSliced = false,
    this.sliceAngle = 0.0,
    this.sliceProgress = 0.0,
    this.half1X = 0.0,
    this.half1Y = 0.0,
    this.half1Vx = 0.0,
    this.half1Vy = 0.0,
    this.half1Rotation = 0.0,
    this.half1AngularVelocity = 0.0,
    this.half2X = 0.0,
    this.half2Y = 0.0,
    this.half2Vx = 0.0,
    this.half2Vy = 0.0,
    this.half2Rotation = 0.0,
    this.half2AngularVelocity = 0.0,
  });

  FruitMeta get meta => FruitMeta.fruitCatalog[type]!;
}

/// Flying juice splatter particle
class JuiceDrop {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  final Color color;

  JuiceDrop({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
  });
}

/// Splat on the backdrop
class JuiceSplatDecal {
  final double x;
  final double y;
  final double radius;
  final Color color;
  double opacity;

  JuiceSplatDecal({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    this.opacity = 0.45,
  });
}

/// Floating popup banner when a letter is revealed
class LetterRevealPop {
  final String letter;
  final String word;
  final FruitType fruitType;
  double x;
  double y;
  double vy;
  double scale;
  double opacity;
  int lifeMs;

  LetterRevealPop({
    required this.letter,
    required this.word,
    required this.fruitType,
    required this.x,
    required this.y,
    this.vy = -1.8,
    this.scale = 0.5,
    this.opacity = 1.0,
    this.lifeMs = 1200,
  });
}

/// Touch swipe trail point with decay
class BladePoint {
  final Offset position;
  final int timestampMs;

  const BladePoint({required this.position, required this.timestampMs});
}
