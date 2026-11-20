import 'package:flutter/material.dart';

class WordChallenge {
  final String word;
  final String targetLetter;
  final String hintTa;
  final String emoji;

  const WordChallenge({
    required this.word,
    required this.targetLetter,
    required this.hintTa,
    required this.emoji,
  });
}

class BalloonPopData {
  // 12 Uyir Letters (Level 1)
  static const List<String> uyirLetters = [
    'அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ',
    'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ',
  ];

  // 18 Mei Letters (Level 2)
  static const List<String> meiLetters = [
    'க்', 'ங்', 'ச்', 'ஞ்', 'ட்', 'ண்',
    'த்', 'ந்', 'ப்', 'ம்', 'ய்', 'ர்',
    'ல்', 'வ்', 'ழ்', 'ள்', 'ற்', 'ன்',
  ];

  // All 216 Uyirmei Letters (Level 3)
  static const List<String> allUyirmeiLetters = [
    // க் series
    'க', 'கா', 'கி', 'கீ', 'கு', 'கூ', 'கெ', 'கே', 'கை', 'கொ', 'கோ', 'கௌ',
    // ங் series
    'ங', 'ஙா', 'ஙி', 'ஙீ', 'ஙு', 'ஙூ', 'ஙெ', 'ஙே', 'ஙை', 'ஙொ', 'ஙோ', 'ஙௌ',
    // ச் series
    'ச', 'சா', 'சி', 'சீ', 'சு', 'சூ', 'செ', 'சே', 'சை', 'சொ', 'சோ', 'சௌ',
    // ஞ் series
    'ஞ', 'ஞா', 'ஞி', 'ஞீ', 'ஞு', 'ஞூ', 'ஞெ', 'ஞே', 'ஞை', 'ஞொ', 'ஞோ', 'ஞௌ',
    // ட் series
    'ட', 'டா', 'டி', 'டீ', 'டு', 'டூ', 'டெ', 'டே', 'டை', 'டொ', 'டோ', 'டௌ',
    // ண் series
    'ண', 'ணா', 'ணி', 'ணீ', 'ணு', 'ணூ', 'ணெ', 'ணே', 'ணை', 'ணொ', 'ணோ', 'ணௌ',
    // த் series
    'த', 'தா', 'தி', 'தீ', 'து', 'தூ', 'தெ', 'தே', 'தை', 'தொ', 'தோ', 'தௌ',
    // ந் series
    'ந', 'நா', 'நி', 'நீ', 'நு', 'நூ', 'நெ', 'நே', 'நை', 'நொ', 'நோ', 'நௌ',
    // ப் series
    'ப', 'பா', 'பி', 'பீ', 'பு', 'பூ', 'பெ', 'பே', 'பை', 'பொ', 'போ', 'பௌ',
    // ம் series
    'ம', 'மா', 'மி', 'மீ', 'மு', 'மூ', 'மெ', 'மே', 'மை', 'மொ', 'மோ', 'மௌ',
    // ய் series
    'ய', 'யா', 'யி', 'யீ', 'யு', 'யூ', 'யெ', 'யே', 'யை', 'யொ', 'யோ', 'யௌ',
    // ர் series
    'ர', 'ரா', 'ரி', 'ரீ', 'ரு', 'ரூ', 'ரெ', 'ரே', 'ரை', 'ரொ', 'ரோ', 'ரௌ',
    // ல் series
    'ல', 'லா', 'லி', 'லீ', 'லு', 'லூ', 'லெ', 'லே', 'லை', 'லொ', 'லோ', 'லௌ',
    // வ் series
    'வ', 'வா', 'வி', 'வீ', 'வு', 'வூ', 'வெ', 'வே', 'வை', 'வொ', 'வோ', 'வௌ',
    // ழ் series
    'ழ', 'ழா', 'ழி', 'ழீ', 'ழு', 'ழூ', 'ழெ', 'ழே', 'ழை', 'ழொ', 'ழோ', 'ழௌ',
    // ள் series
    'ள', 'ளா', 'ளி', 'ளீ', 'ளு', 'ளூ', 'ளெ', 'ளே', 'ளை', 'ளொ', 'ளோ', 'ளௌ',
    // ற் series
    'ற', 'றா', 'றி', 'றீ', 'று', 'றூ', 'றெ', 'றே', 'றை', 'றொ', 'றோ', 'றௌ',
    // ன் series
    'ன', 'னா', 'னி', 'னீ', 'னு', 'னூ', 'னெ', 'னே', 'னை', 'னொ', 'னோ', 'னௌ',
  ];

  // Words for Level 4 (சொல் கண்டுபிடி - Word Discovery)
  static const List<WordChallenge> wordChallenges = [
    WordChallenge(
      word: 'அம்மா',
      targetLetter: 'ம',
      hintTa: "'அம்மா' சொல்லில் உள்ள 'ம' எழுத்தை உடைக்கவும்!",
      emoji: '👩‍👧',
    ),
    WordChallenge(
      word: 'ஆடு',
      targetLetter: 'டு',
      hintTa: "'ஆடு' சொல்லில் உள்ள 'டு' எழுத்தை உடைக்கவும்!",
      emoji: '🐐',
    ),
    WordChallenge(
      word: 'இலை',
      targetLetter: 'லை',
      hintTa: "'இலை' சொல்லில் உள்ள 'லை' எழுத்தை உடைக்கவும்!",
      emoji: '🍃',
    ),
    WordChallenge(
      word: 'உரல்',
      targetLetter: 'ர',
      hintTa: "'உரல்' சொல்லில் உள்ள 'ர' எழுத்தை உடைக்கவும்!",
      emoji: '🥣',
    ),
    WordChallenge(
      word: 'பட்டம்',
      targetLetter: 'ட்',
      hintTa: "'பட்டம்' சொல்லில் உள்ள 'ட்' எழுத்தை உடைக்கவும்!",
      emoji: '🪁',
    ),
    WordChallenge(
      word: 'கப்பல்',
      targetLetter: 'ப்',
      hintTa: "'கப்பல்' சொல்லில் உள்ள 'ப்' எழுத்தை உடைக்கவும்!",
      emoji: '🚢',
    ),
    WordChallenge(
      word: 'மரம்',
      targetLetter: 'ம்',
      hintTa: "'மரம்' சொல்லில் உள்ள 'ம்' எழுத்தை உடைக்கவும்!",
      emoji: '🌳',
    ),
    WordChallenge(
      word: 'பந்து',
      targetLetter: 'ந்',
      hintTa: "'பந்து' சொல்லில் உள்ள 'ந்' எழுத்தை உடைக்கவும்!",
      emoji: '⚽',
    ),
    WordChallenge(
      word: 'மீன்',
      targetLetter: 'மீ',
      hintTa: "'மீன்' சொல்லில் உள்ள 'மீ' எழுத்தை உடைக்கவும்!",
      emoji: '🐟',
    ),
    WordChallenge(
      word: 'காக்கை',
      targetLetter: 'கை',
      hintTa: "'காக்கை' சொல்லில் உள்ள 'கை' எழுத்தை உடைக்கவும்!",
      emoji: '🦅',
    ),
    WordChallenge(
      word: 'நத்தை',
      targetLetter: 'த்',
      hintTa: "'நத்தை' சொல்லில் உள்ள 'த்' எழுத்தை உடைக்கவும்!",
      emoji: '🐌',
    ),
    WordChallenge(
      word: 'வாள்',
      targetLetter: 'ள்',
      hintTa: "'வாள்' சொல்லில் உள்ள 'ள்' எழுத்தை உடைக்கவும்!",
      emoji: '⚔️',
    ),
    WordChallenge(
      word: 'யாழ்',
      targetLetter: 'ழ்',
      hintTa: "'யாழ்' சொல்லில் உள்ள 'ழ்' எழுத்தை உடைக்கவும்!",
      emoji: '🪕',
    ),
    WordChallenge(
      word: 'வெற்றி',
      targetLetter: 'றி',
      hintTa: "'வெற்றி' சொல்லில் உள்ள 'றி' எழுத்தை உடைக்கவும்!",
      emoji: '🏆',
    ),
    WordChallenge(
      word: 'தேர்',
      targetLetter: 'ர்',
      hintTa: "'தேர்' சொல்லில் உள்ள 'ர்' எழுத்தை உடைக்கவும்!",
      emoji: '🛕',
    ),
  ];

  // Positive feedback phrases shown when popping the right balloon
  static const List<String> positiveFeedbacks = [
    'அருமை! 🎉',
    'சூப்பர்! ⭐',
    'மிகச் சரி! 👏',
    'அற்புதம்! ✨',
    'வாழ்த்துகள்! 🌟',
    'சபாஷ்! 🎈',
  ];

  // Encouraging feedback phrases on wrong balloon tap
  static const List<String> tryAgainFeedbacks = [
    'மீண்டும் முயற்சி செய்! 😊',
    'இன்னொரு முறை பார்! 👍',
    'சரியான எழுத்தைத் தேடு! 🔍',
  ];
}

/// Level Info model for Level Selection Screen
class BalloonLevelInfo {
  final int levelNumber;
  final String nameTa;
  final String nameEn;
  final String difficultyTa;
  final String descriptionTa;
  final IconData icon;
  final List<Color> gradientColors;
  final int targetCount;

  const BalloonLevelInfo({
    required this.levelNumber,
    required this.nameTa,
    required this.nameEn,
    required this.difficultyTa,
    required this.descriptionTa,
    required this.icon,
    required this.gradientColors,
    required this.targetCount,
  });

  String get subtitleTa => difficultyTa;

  String get lockRequirementTa {
    switch (levelNumber) {
      case 2:
        return 'முதலில் எளிய நிலையை முடிக்கவும்.';
      case 3:
        return 'முதலில் நடுத்தர நிலையை முடிக்கவும்.';
      default:
        return 'தொடங்கலாம்!';
    }
  }

  static const List<BalloonLevelInfo> levels = [
    BalloonLevelInfo(
      levelNumber: 1,
      nameTa: 'உயிரெழுத்துகள்',
      nameEn: 'Vowels (Uyir)',
      difficultyTa: 'எளிய நிலை (Easy)',
      descriptionTa: '12 உயிர் எழுத்துகளை பலூனில் உடைத்துப் பழகுங்கள்!',
      icon: Icons.favorite_rounded,
      gradientColors: [Color(0xFFE91E63), Color(0xFFFF5252)],
      targetCount: 12,
    ),
    BalloonLevelInfo(
      levelNumber: 2,
      nameTa: 'மெய்யெழுத்துகள்',
      nameEn: 'Consonants (Mei)',
      difficultyTa: 'நடுத்தர நிலை (Medium)',
      descriptionTa: '18 புள்ளி வைத்த மெய் எழுத்துகளை சரியாக உடைக்கவும்!',
      icon: Icons.star_rounded,
      gradientColors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
      targetCount: 18,
    ),
    BalloonLevelInfo(
      levelNumber: 3,
      nameTa: 'உயிர்மெய்யெழுத்துகள்',
      nameEn: 'Compound (Uyirmei)',
      difficultyTa: 'கடின நிலை (Hard)',
      descriptionTa: 'உயிர்மெய் எழுத்துகளை வேகமாய் உடைத்து சாதிக்கவும்!',
      icon: Icons.local_fire_department_rounded,
      gradientColors: [Color(0xFFFF9800), Color(0xFFFF5722)],
      targetCount: 24, // 24 letters per round
    ),
  ];
}

List<BalloonLevelInfo> get balloonLevels => BalloonLevelInfo.levels;

