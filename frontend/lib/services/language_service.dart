import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final String brandTitle;
  final String greeting;
  final String vowelsTitle;
  final String consonantsTitle;

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    required this.brandTitle,
    required this.greeting,
    required this.vowelsTitle,
    required this.consonantsTitle,
  });
}

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();
  factory LanguageService() => instance;
  LanguageService._internal();

  static const String _prefKey = 'selected_language_code';

  static const Map<String, LanguageInfo> supportedLanguages = {
    'ta': LanguageInfo(
      code: 'ta',
      name: 'Tamil',
      nativeName: 'தமிழ்',
      flagEmoji: '🇮🇳',
      brandTitle: 'அகரம்',
      greeting: 'வணக்கம்',
      vowelsTitle: 'உயிர் எழுத்துகள்',
      consonantsTitle: 'மெய் எழுத்துகள்',
    ),
    'te': LanguageInfo(
      code: 'te',
      name: 'Telugu',
      nativeName: 'తెలుగు',
      flagEmoji: '🇮🇳',
      brandTitle: 'అక్షరం',
      greeting: 'నమస్కారం',
      vowelsTitle: 'అచ్చులు (Achulu)',
      consonantsTitle: 'హల్లులు (Hallulu)',
    ),
    'en': LanguageInfo(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagEmoji: '🇬🇧',
      brandTitle: 'AGARAM',
      greeting: 'Hello',
      vowelsTitle: 'Vowels (Uyir)',
      consonantsTitle: 'Consonants (Mei)',
    ),
  };

  String _currentLanguageCode = 'ta';
  bool _isInitialized = false;
  bool _hasSelectedLanguage = false;

  String get currentLanguageCode => _currentLanguageCode;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get isInitialized => _isInitialized;

  bool get isEnglish => _currentLanguageCode == 'en';
  bool get isTamil => _currentLanguageCode == 'ta';
  bool get isTelugu => _currentLanguageCode == 'te';

  LanguageInfo get currentLanguage =>
      supportedLanguages[_currentLanguageCode] ?? supportedLanguages['ta']!;

  String get brandTitle => currentLanguage.brandTitle;
  String get greeting => currentLanguage.greeting;
  String get vowelsTitle => currentLanguage.vowelsTitle;
  String get consonantsTitle => currentLanguage.consonantsTitle;

  // Localized Headings for Main Sections
  String get lessonsHeading => isEnglish ? 'Lessons' : (isTelugu ? 'పాఠాలు' : 'கற்றுக்கொள்வோம்');
  String get gamesHeading => isEnglish ? 'Play & Learn' : (isTelugu ? 'ఆటలు' : 'விளையாடிக் கற்போம்');
  String get videosHeading => isEnglish ? 'Videos' : (isTelugu ? 'వీడియోలు' : 'காணொளிகள்');
  String get quizHeading => isEnglish ? 'Quiz' : (isTelugu ? 'క్విజ్' : 'வினாடி வினா');
  String get writingHeading => isEnglish ? 'Writing Practice' : (isTelugu ? 'రాయడం నేర్చుకోండి' : 'எழுதிப் பழகு');
  String get storiesHeading => isEnglish ? 'Stories' : (isTelugu ? 'కథలు' : 'வாசிப்பு');

  String get learningWorldsTitle => isEnglish ? 'Learning Worlds' : (isTelugu ? 'నేర్చుకునే ప్రపంచాలు' : 'கற்றல் உலகங்கள்');
  String get todayProgressTitle => isEnglish ? "Today's Progress" : (isTelugu ? 'ఈ రోజు పురోగతి' : 'இன்றைய முன்னேற்றம்');
  String get completedLessonsLabel => isEnglish ? 'Completed' : (isTelugu ? 'పూర్తయినవి' : 'கற்ற பாடங்கள்');
  String get starsLabel => isEnglish ? 'Stars' : (isTelugu ? 'నక్షత్రాలు' : 'நட்சத்திரங்கள்');
  String get quizScoreLabel => isEnglish ? 'Quiz Points' : (isTelugu ? 'క్విజ్ పాయింట్లు' : 'வினாடி வினா');

  String get aythamHeading => isEnglish ? 'Aytham Letter (ஃ)' : 'ஆய்த எழுத்து';
  String get uyirmeiHeading => isEnglish ? 'Combined Letters (Uyirmei)' : 'உயிர்மெய் எழுத்துகள்';

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && supportedLanguages.containsKey(savedCode)) {
        _currentLanguageCode = savedCode;
        _hasSelectedLanguage = true;
      } else {
        _hasSelectedLanguage = false;
        _currentLanguageCode = 'ta';
      }
    } catch (_) {
      _currentLanguageCode = 'ta';
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (!supportedLanguages.containsKey(code)) return;
    _currentLanguageCode = code;
    _hasSelectedLanguage = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }
}
