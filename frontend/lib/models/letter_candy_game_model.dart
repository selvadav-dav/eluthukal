import 'package:flutter/material.dart';
import 'letter_model.dart';

/// Candy tile power-up types
enum CandySpecialType {
  none,
  rowBlast, // Clears entire row
  colBlast, // Clears entire column
  bomb,     // 3x3 blast or color burst
}

/// Represents an individual candy piece on the board
class CandyTile {
  final int id;
  LetterModel letterModel;
  int row;
  int col;
  CandySpecialType specialType;
  
  // Animation & Rendering state
  bool isSelected;
  bool isMatched;
  double scale;
  double opacity;
  double offsetX; // Drag/swipe pixel offset
  double offsetY; // Drag/swipe pixel offset
  double fallOffset; // Falling distance from above in rows

  // Visual appearance
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final Color textColor;

  CandyTile({
    required this.id,
    required this.letterModel,
    required this.row,
    required this.col,
    this.specialType = CandySpecialType.none,
    this.isSelected = false,
    this.isMatched = false,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.fallOffset = 0.0,
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    this.textColor = Colors.white,
  });

  String get letter => letterModel.letter;
  String get word => letterModel.word;
  String? get audioPath => letterModel.audioPath;

  CandyTile copyWith({
    int? id,
    LetterModel? letterModel,
    int? row,
    int? col,
    CandySpecialType? specialType,
    bool? isSelected,
    bool? isMatched,
    double? scale,
    double? opacity,
    double? offsetX,
    double? offsetY,
    double? fallOffset,
    List<Color>? gradientColors,
    Color? borderColor,
    Color? shadowColor,
    Color? textColor,
  }) {
    return CandyTile(
      id: id ?? this.id,
      letterModel: letterModel ?? this.letterModel,
      row: row ?? this.row,
      col: col ?? this.col,
      specialType: specialType ?? this.specialType,
      isSelected: isSelected ?? this.isSelected,
      isMatched: isMatched ?? this.isMatched,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      fallOffset: fallOffset ?? this.fallOffset,
      gradientColors: gradientColors ?? this.gradientColors,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      textColor: textColor ?? this.textColor,
    );
  }
}

/// Particle for candy pop explosion
class CandySparkleParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double life;
  double maxLife;
  bool isStar;
  bool isCandyPiece;

  CandySparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
    required this.maxLife,
    this.isStar = false,
    this.isCandyPiece = false,
  });

  double get progress => (1.0 - (life / maxLife)).clamp(0.0, 1.0);
}

/// Level specification model
class CandyGameLevel {
  final int levelNumber;
  final String title;
  final String subtitle;
  final String description;
  final List<LetterModel> letterPool;
  final int targetScore;
  final int maxMoves;
  final int? timeLimitSeconds; // null for move-based levels

  const CandyGameLevel({
    required this.levelNumber,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.letterPool,
    required this.targetScore,
    this.maxMoves = 22,
    this.timeLimitSeconds,
  });

  bool get isTimed => timeLimitSeconds != null && timeLimitSeconds! > 0;
}

/// Visual theme and styling specification for an individual candy letter tile
class CandyLetterStyle {
  final Color primaryColor;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final Color textColor;

  const CandyLetterStyle({
    required this.primaryColor,
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    this.textColor = Colors.white,
  });
}

/// Centralized, dedicated color system for Tamil candy tiles.
/// Rule: ONE LETTER = ONE UNIQUE DEDICATED COLOR.
class CandyColorPalette {
  /// Centralized map of Tamil Letter -> Dedicated Primary Color
  static const Map<String, Color> letterColors = {
    // -------------------------------------------------------------
    // 12 Uyir Letters (Vowels) + Aytham
    // -------------------------------------------------------------
    'அ': Color(0xFFFF1744), // Red (Strawberry)
    'ஆ': Color(0xFFFF6D00), // Orange (Tangerine)
    'இ': Color(0xFFFFB300), // Yellow (Honey Gold)
    'ஈ': Color(0xFF00E676), // Lime / Mint Green
    'உ': Color(0xFF00B0FF), // Sky Blue
    'ஊ': Color(0xFFAA00FF), // Royal Purple
    'எ': Color(0xFFFF4081), // Pink (Bubblegum)
    'ஏ': Color(0xFF00897B), // Teal (Ocean)
    'ஐ': Color(0xFF8D4B1E), // Brown (Caramel)
    'ஒ': Color(0xFF3D5AFE), // Indigo (Electric Blue)
    'ஓ': Color(0xFF1B5E20), // Dark Forest Green
    'ஔ': Color(0xFF6A0080), // Violet (Deep Plum)
    'ஃ': Color(0xFF546E7A), // Steel Slate

    // -------------------------------------------------------------
    // 18 Mei Letters (Consonants)
    // -------------------------------------------------------------
    'க்': Color(0xFF00C853), // Emerald Green
    'ங்': Color(0xFFFF6D00), // Tangerine Gold
    'ச்': Color(0xFF0091EA), // Sky Cyan Blue
    'ஞ்': Color(0xFFFF1493), // Rose Pink
    'ட்': Color(0xFF7B1FA2), // Vivid Purple
    'ண்': Color(0xFFFFD600), // Bright Sun Yellow
    'த்': Color(0xFFE53935), // Crimson Scarlet
    'ந்': Color(0xFF00897B), // Deep Teal
    'ப்': Color(0xFFFF5722), // Coral Flame
    'ம்': Color(0xFFFF4081), // Magenta Bubblegum
    'ய்': Color(0xFF00E5FF), // Electric Aqua
    'ர்': Color(0xFF3D5AFE), // Royal Indigo
    'ல்': Color(0xFF76FF03), // Mint Lime
    'வ்': Color(0xFF8D4B1E), // Amber Cinnamon
    'ழ்': Color(0xFFAA00FF), // Violet Amethyst
    'ள்': Color(0xFF1B5E20), // Forest Pine
    'ற்': Color(0xFFF50057), // Hot Fuchsia
    'ன்': Color(0xFF2962FF), // Cobalt Sapphire

    // -------------------------------------------------------------
    // Uyirmei Letters (Ka series)
    // -------------------------------------------------------------
    'க': Color(0xFF00E5FF), // Electric Turquoise
    'கா': Color(0xFFFF5722), // Coral Flame
    'கி': Color(0xFF76FF03), // Lime Chartreuse
    'கீ': Color(0xFFBA68C8), // Orchid Lavender
    'கு': Color(0xFF2979FF), // Cobalt Blue
    'கூ': Color(0xFFD50010), // Crimson Ruby
    'கெ': Color(0xFFF50057), // Hot Pink
    'கே': Color(0xFFFFB300), // Amber Gold
    'கை': Color(0xFF00BFA5), // Mint Jade
    'கொ': Color(0xFF1A237E), // Deep Navy
    'கோ': Color(0xFF004D40), // Emerald Pine
    'கௌ': Color(0xFF4A148C), // Plum Grape
  };

  /// Detailed styling tokens for each letter (Gradient, Border, Shadow, Text)
  static const Map<String, CandyLetterStyle> letterStyles = {
    // -------------------------------------------------------------
    // 12 Uyir Letters (Vowels) + Aytham
    // -------------------------------------------------------------
    'அ': CandyLetterStyle(
      primaryColor: Color(0xFFFF1744),
      gradientColors: [Color(0xFFFF5252), Color(0xFFFF1744), Color(0xFFD50010)],
      borderColor: Color(0xFFFF8A80),
      shadowColor: Color(0xFF8A0000),
    ),
    'ஆ': CandyLetterStyle(
      primaryColor: Color(0xFFFF6D00),
      gradientColors: [Color(0xFFFF9100), Color(0xFFFF6D00), Color(0xFFE65100)],
      borderColor: Color(0xFFFFD180),
      shadowColor: Color(0xFFBF360C),
    ),
    'இ': CandyLetterStyle(
      primaryColor: Color(0xFFFFB300),
      gradientColors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
      borderColor: Color(0xFFFFF9C4),
      shadowColor: Color(0xFFE65100),
    ),
    'ஈ': CandyLetterStyle(
      primaryColor: Color(0xFF00E676),
      gradientColors: [Color(0xFF69F0AE), Color(0xFF00E676), Color(0xFF00C853)],
      borderColor: Color(0xFFB9F6CA),
      shadowColor: Color(0xFF1B5E20),
    ),
    'உ': CandyLetterStyle(
      primaryColor: Color(0xFF00B0FF),
      gradientColors: [Color(0xFF40C4FF), Color(0xFF00B0FF), Color(0xFF01579B)],
      borderColor: Color(0xFF80D8FF),
      shadowColor: Color(0xFF0D47A1),
    ),
    'ஊ': CandyLetterStyle(
      primaryColor: Color(0xFFAA00FF),
      gradientColors: [Color(0xFFE040FB), Color(0xFFAA00FF), Color(0xFF7B1FA2)],
      borderColor: Color(0xFFEA80FC),
      shadowColor: Color(0xFF4A148C),
    ),
    'எ': CandyLetterStyle(
      primaryColor: Color(0xFFFF4081),
      gradientColors: [Color(0xFFFF80AB), Color(0xFFFF4081), Color(0xFFC2185B)],
      borderColor: Color(0xFFFFC1E3),
      shadowColor: Color(0xFF880E4F),
    ),
    'ஏ': CandyLetterStyle(
      primaryColor: Color(0xFF00897B),
      gradientColors: [Color(0xFF26A69A), Color(0xFF00897B), Color(0xFF004D40)],
      borderColor: Color(0xFF80CBC4),
      shadowColor: Color(0xFF00251A),
    ),
    'ஐ': CandyLetterStyle(
      primaryColor: Color(0xFF8D4B1E),
      gradientColors: [Color(0xFFB76E3E), Color(0xFF8D4B1E), Color(0xFF5E2B08)],
      borderColor: Color(0xFFD7CCC8),
      shadowColor: Color(0xFF3E1B05),
    ),
    'ஒ': CandyLetterStyle(
      primaryColor: Color(0xFF3D5AFE),
      gradientColors: [Color(0xFF8C9EFF), Color(0xFF3D5AFE), Color(0xFF1A237E)],
      borderColor: Color(0xFFC5CAE9),
      shadowColor: Color(0xFF0D1B5E),
    ),
    'ஓ': CandyLetterStyle(
      primaryColor: Color(0xFF1B5E20),
      gradientColors: [Color(0xFF43A047), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      borderColor: Color(0xFFA5D6A7),
      shadowColor: Color(0xFF0D3311),
    ),
    'ஔ': CandyLetterStyle(
      primaryColor: Color(0xFF6A0080),
      gradientColors: [Color(0xFF9C27B0), Color(0xFF6A0080), Color(0xFF4A0072)],
      borderColor: Color(0xFFE1BEE7),
      shadowColor: Color(0xFF260033),
    ),
    'ஃ': CandyLetterStyle(
      primaryColor: Color(0xFF546E7A),
      gradientColors: [Color(0xFF90A4AE), Color(0xFF546E7A), Color(0xFF37474F)],
      borderColor: Color(0xFFCFD8DC),
      shadowColor: Color(0xFF212121),
    ),

    // -------------------------------------------------------------
    // 18 Mei Letters (Consonants)
    // -------------------------------------------------------------
    'க்': CandyLetterStyle(
      primaryColor: Color(0xFF00C853),
      gradientColors: [Color(0xFF00E676), Color(0xFF00C853), Color(0xFF1B5E20)],
      borderColor: Color(0xFFB9F6CA),
      shadowColor: Color(0xFF004D40),
    ),
    'ங்': CandyLetterStyle(
      primaryColor: Color(0xFFFF6D00),
      gradientColors: [Color(0xFFFF9800), Color(0xFFFF6D00), Color(0xFFE65100)],
      borderColor: Color(0xFFFFD180),
      shadowColor: Color(0xFFBF360C),
    ),
    'ச்': CandyLetterStyle(
      primaryColor: Color(0xFF0091EA),
      gradientColors: [Color(0xFF40C4FF), Color(0xFF0091EA), Color(0xFF01579B)],
      borderColor: Color(0xFF80D8FF),
      shadowColor: Color(0xFF0D47A1),
    ),
    'ஞ்': CandyLetterStyle(
      primaryColor: Color(0xFFFF1493),
      gradientColors: [Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFC2185B)],
      borderColor: Color(0xFFFFC1E3),
      shadowColor: Color(0xFF880E4F),
    ),
    'ட்': CandyLetterStyle(
      primaryColor: Color(0xFF7B1FA2),
      gradientColors: [Color(0xFFBA68C8), Color(0xFF7B1FA2), Color(0xFF4A148C)],
      borderColor: Color(0xFFE1BEE7),
      shadowColor: Color(0xFF311B92),
    ),
    'ண்': CandyLetterStyle(
      primaryColor: Color(0xFFFFD600),
      gradientColors: [Color(0xFFFFF176), Color(0xFFFFD600), Color(0xFFFF9100)],
      borderColor: Color(0xFFFFFDE7),
      shadowColor: Color(0xFFE65100),
    ),
    'த்': CandyLetterStyle(
      primaryColor: Color(0xFFE53935),
      gradientColors: [Color(0xFFEF5350), Color(0xFFE53935), Color(0xFFB71C1C)],
      borderColor: Color(0xFFFFCDD2),
      shadowColor: Color(0xFF7F0000),
    ),
    'ந்': CandyLetterStyle(
      primaryColor: Color(0xFF00897B),
      gradientColors: [Color(0xFF26A69A), Color(0xFF00897B), Color(0xFF004D40)],
      borderColor: Color(0xFFB2DFDB),
      shadowColor: Color(0xFF00251A),
    ),
    'ப்': CandyLetterStyle(
      primaryColor: Color(0xFFFF5722),
      gradientColors: [Color(0xFFFF8A65), Color(0xFFFF5722), Color(0xFFD84315)],
      borderColor: Color(0xFFFFCCBC),
      shadowColor: Color(0xFF8A1E00),
    ),
    'ம்': CandyLetterStyle(
      primaryColor: Color(0xFFFF4081),
      gradientColors: [Color(0xFFFF80AB), Color(0xFFFF4081), Color(0xFFC51162)],
      borderColor: Color(0xFFFCE4EC),
      shadowColor: Color(0xFF880E4F),
    ),
    'ய்': CandyLetterStyle(
      primaryColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF84FFFF), Color(0xFF00E5FF), Color(0xFF0097A7)],
      borderColor: Color(0xFFE0F7FA),
      shadowColor: Color(0xFF006064),
    ),
    'ர்': CandyLetterStyle(
      primaryColor: Color(0xFF3D5AFE),
      gradientColors: [Color(0xFF8C9EFF), Color(0xFF3D5AFE), Color(0xFF1A237E)],
      borderColor: Color(0xFFC5CAE9),
      shadowColor: Color(0xFF0D1B5E),
    ),
    'ல்': CandyLetterStyle(
      primaryColor: Color(0xFF76FF03),
      gradientColors: [Color(0xFFB2FF59), Color(0xFF76FF03), Color(0xFF33691E)],
      borderColor: Color(0xFFDCEDC8),
      shadowColor: Color(0xFF1B5E20),
    ),
    'வ்': CandyLetterStyle(
      primaryColor: Color(0xFF8D4B1E),
      gradientColors: [Color(0xFFB76E3E), Color(0xFF8D4B1E), Color(0xFF4E260E)],
      borderColor: Color(0xFFD7CCC8),
      shadowColor: Color(0xFF3E1B05),
    ),
    'ழ்': CandyLetterStyle(
      primaryColor: Color(0xFFAA00FF),
      gradientColors: [Color(0xFFE040FB), Color(0xFFAA00FF), Color(0xFF4A148C)],
      borderColor: Color(0xFFEA80FC),
      shadowColor: Color(0xFF311B92),
    ),
    'ள்': CandyLetterStyle(
      primaryColor: Color(0xFF1B5E20),
      gradientColors: [Color(0xFF43A047), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      borderColor: Color(0xFFA5D6A7),
      shadowColor: Color(0xFF0D3311),
    ),
    'ற்': CandyLetterStyle(
      primaryColor: Color(0xFFF50057),
      gradientColors: [Color(0xFFFF4081), Color(0xFFF50057), Color(0xFF880E4F)],
      borderColor: Color(0xFFFF80AB),
      shadowColor: Color(0xFF560027),
    ),
    'ன்': CandyLetterStyle(
      primaryColor: Color(0xFF2962FF),
      gradientColors: [Color(0xFF448AFF), Color(0xFF2962FF), Color(0xFF0D47A1)],
      borderColor: Color(0xFF82B1FF),
      shadowColor: Color(0xFF002171),
    ),

    // -------------------------------------------------------------
    // Uyirmei Letters (Ka series)
    // -------------------------------------------------------------
    'க': CandyLetterStyle(
      primaryColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF84FFFF), Color(0xFF00E5FF), Color(0xFF0097A7)],
      borderColor: Color(0xFFE0F7FA),
      shadowColor: Color(0xFF006064),
    ),
    'கா': CandyLetterStyle(
      primaryColor: Color(0xFFFF5722),
      gradientColors: [Color(0xFFFF8A65), Color(0xFFFF5722), Color(0xFFBF360C)],
      borderColor: Color(0xFFFFCCBC),
      shadowColor: Color(0xFF8A1E00),
    ),
    'கி': CandyLetterStyle(
      primaryColor: Color(0xFF76FF03),
      gradientColors: [Color(0xFFB2FF59), Color(0xFF76FF03), Color(0xFF33691E)],
      borderColor: Color(0xFFDCEDC8),
      shadowColor: Color(0xFF1B5E20),
    ),
    'கீ': CandyLetterStyle(
      primaryColor: Color(0xFFBA68C8),
      gradientColors: [Color(0xFFCE93D8), Color(0xFFBA68C8), Color(0xFF6A1B9A)],
      borderColor: Color(0xFFF3E5F5),
      shadowColor: Color(0xFF4A148C),
    ),
    'கு': CandyLetterStyle(
      primaryColor: Color(0xFF2979FF),
      gradientColors: [Color(0xFF82B1FF), Color(0xFF2979FF), Color(0xFF0D47A1)],
      borderColor: Color(0xFFBBDEFB),
      shadowColor: Color(0xFF002171),
    ),
    'கூ': CandyLetterStyle(
      primaryColor: Color(0xFFD50010),
      gradientColors: [Color(0xFFFF5252), Color(0xFFD50010), Color(0xFF8A0000)],
      borderColor: Color(0xFFFF8A80),
      shadowColor: Color(0xFF560000),
    ),
    'கெ': CandyLetterStyle(
      primaryColor: Color(0xFFF50057),
      gradientColors: [Color(0xFFFF4081), Color(0xFFF50057), Color(0xFF880E4F)],
      borderColor: Color(0xFFFF80AB),
      shadowColor: Color(0xFF560027),
    ),
    'கே': CandyLetterStyle(
      primaryColor: Color(0xFFFFB300),
      gradientColors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF6F00)],
      borderColor: Color(0xFFFFF9C4),
      shadowColor: Color(0xFFC67100),
    ),
    'கை': CandyLetterStyle(
      primaryColor: Color(0xFF00BFA5),
      gradientColors: [Color(0xFF1DE9B6), Color(0xFF00BFA5), Color(0xFF004D40)],
      borderColor: Color(0xFFA7FFEB),
      shadowColor: Color(0xFF00251A),
    ),
    'கொ': CandyLetterStyle(
      primaryColor: Color(0xFF1A237E),
      gradientColors: [Color(0xFF536DFE), Color(0xFF304FFE), Color(0xFF1A237E)],
      borderColor: Color(0xFF8C9EFF),
      shadowColor: Color(0xFF0D1B5E),
    ),
    'கோ': CandyLetterStyle(
      primaryColor: Color(0xFF004D40),
      gradientColors: [Color(0xFF00897B), Color(0xFF00695C), Color(0xFF004D40)],
      borderColor: Color(0xFF80CBC4),
      shadowColor: Color(0xFF00251A),
    ),
    'கௌ': CandyLetterStyle(
      primaryColor: Color(0xFF4A148C),
      gradientColors: [Color(0xFF7B1FA2), Color(0xFF4A148C), Color(0xFF311B92)],
      borderColor: Color(0xFFCE93D8),
      shadowColor: Color(0xFF1A0033),
    ),
  };

  /// Fallback curated candy styles palette for any future dynamic Tamil letters.
  static const List<CandyLetterStyle> dynamicPalette = [
    CandyLetterStyle(
      primaryColor: Color(0xFFFF1744),
      gradientColors: [Color(0xFFFF5252), Color(0xFFFF1744), Color(0xFFD50010)],
      borderColor: Color(0xFFFF8A80),
      shadowColor: Color(0xFF8A0000),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFFF6D00),
      gradientColors: [Color(0xFFFF9100), Color(0xFFFF6D00), Color(0xFFE65100)],
      borderColor: Color(0xFFFFD180),
      shadowColor: Color(0xFFBF360C),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFFFB300),
      gradientColors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
      borderColor: Color(0xFFFFF9C4),
      shadowColor: Color(0xFFE65100),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00E676),
      gradientColors: [Color(0xFF69F0AE), Color(0xFF00E676), Color(0xFF00C853)],
      borderColor: Color(0xFFB9F6CA),
      shadowColor: Color(0xFF1B5E20),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00B0FF),
      gradientColors: [Color(0xFF40C4FF), Color(0xFF00B0FF), Color(0xFF01579B)],
      borderColor: Color(0xFF80D8FF),
      shadowColor: Color(0xFF0D47A1),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFAA00FF),
      gradientColors: [Color(0xFFE040FB), Color(0xFFAA00FF), Color(0xFF7B1FA2)],
      borderColor: Color(0xFFEA80FC),
      shadowColor: Color(0xFF4A148C),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFFF4081),
      gradientColors: [Color(0xFFFF80AB), Color(0xFFFF4081), Color(0xFFC2185B)],
      borderColor: Color(0xFFFFC1E3),
      shadowColor: Color(0xFF880E4F),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00897B),
      gradientColors: [Color(0xFF26A69A), Color(0xFF00897B), Color(0xFF004D40)],
      borderColor: Color(0xFF80CBC4),
      shadowColor: Color(0xFF00251A),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF8D4B1E),
      gradientColors: [Color(0xFFB76E3E), Color(0xFF8D4B1E), Color(0xFF5E2B08)],
      borderColor: Color(0xFFD7CCC8),
      shadowColor: Color(0xFF3E1B05),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF3D5AFE),
      gradientColors: [Color(0xFF8C9EFF), Color(0xFF3D5AFE), Color(0xFF1A237E)],
      borderColor: Color(0xFFC5CAE9),
      shadowColor: Color(0xFF0D1B5E),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF84FFFF), Color(0xFF00E5FF), Color(0xFF0097A7)],
      borderColor: Color(0xFFE0F7FA),
      shadowColor: Color(0xFF006064),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFFF5722),
      gradientColors: [Color(0xFFFF8A65), Color(0xFFFF5722), Color(0xFFBF360C)],
      borderColor: Color(0xFFFFCCBC),
      shadowColor: Color(0xFF8A1E00),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF76FF03),
      gradientColors: [Color(0xFFB2FF59), Color(0xFF76FF03), Color(0xFF33691E)],
      borderColor: Color(0xFFDCEDC8),
      shadowColor: Color(0xFF1B5E20),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFBA68C8),
      gradientColors: [Color(0xFFCE93D8), Color(0xFFBA68C8), Color(0xFF6A1B9A)],
      borderColor: Color(0xFFF3E5F5),
      shadowColor: Color(0xFF4A148C),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF2979FF),
      gradientColors: [Color(0xFF82B1FF), Color(0xFF2979FF), Color(0xFF0D47A1)],
      borderColor: Color(0xFFBBDEFB),
      shadowColor: Color(0xFF002171),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFD50010),
      gradientColors: [Color(0xFFFF5252), Color(0xFFD50010), Color(0xFF8A0000)],
      borderColor: Color(0xFFFF8A80),
      shadowColor: Color(0xFF560000),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFFF50057),
      gradientColors: [Color(0xFFFF4081), Color(0xFFF50057), Color(0xFF880E4F)],
      borderColor: Color(0xFFFF80AB),
      shadowColor: Color(0xFF560027),
    ),
    CandyLetterStyle(
      primaryColor: Color(0xFF00BFA5),
      gradientColors: [Color(0xFF1DE9B6), Color(0xFF00BFA5), Color(0xFF004D40)],
      borderColor: Color(0xFFA7FFEB),
      shadowColor: Color(0xFF00251A),
    ),
  ];

  /// Get the full visual style for a Tamil letter.
  /// Always returns the exact same style for the same letter.
  static CandyLetterStyle getStyleForLetter(String letter) {
    if (letterStyles.containsKey(letter)) {
      return letterStyles[letter]!;
    }
    // Stable deterministic fallback for any unseen Tamil letter
    final hash = letter.runes.fold<int>(0, (prev, rune) => (prev * 31 + rune) & 0x7FFFFFFF);
    final idx = hash % dynamicPalette.length;
    return dynamicPalette[idx];
  }

  /// Get gradient, border, and shadow tokens for tile rendering (backward-compatible record)
  static (List<Color>, Color, Color) getColorForLetter(String letter) {
    final style = getStyleForLetter(letter);
    return (style.gradientColors, style.borderColor, style.shadowColor);
  }

  /// Get dedicated primary color for a letter
  static Color getPrimaryColorForLetter(String letter) {
    if (letterColors.containsKey(letter)) {
      return letterColors[letter]!;
    }
    return getStyleForLetter(letter).primaryColor;
  }
}

