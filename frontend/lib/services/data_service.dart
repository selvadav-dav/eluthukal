import '../models/letter_model.dart';
import '../models/story_model.dart';
import '../models/game_model.dart';
import '../models/video_model.dart';
import '../models/quiz_model.dart';

import '../data/uyir_data.dart';
import '../data/mei_data.dart';
import '../data/aytham_data.dart';
import '../data/uyirmei_data.dart';
import '../data/story_data.dart';
import '../data/game_data.dart';
import '../data/video_data.dart';
import '../data/quiz_data.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

import '../data/telugu_letters_data.dart';
import 'language_service.dart';

abstract class IDataRepository {
  Future<List<LetterModel>> getUyirLetters();
  Future<List<LetterModel>> getMeiLetters();
  Future<LetterModel> getAythamLetter();
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase);
  Future<List<String>> getMeiGroupBases();
  Future<StoryModel> getFeaturedStory();
  Future<List<GameQuestion>> getGameQuestions();
  Future<List<VideoItem>> getVideoLessons();
  Future<List<QuizCategory>> getQuizCategories();
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId);
}

class LocalDataRepository implements IDataRepository {
  @override
  Future<List<LetterModel>> getUyirLetters() async {
    if (LanguageService.instance.currentLanguageCode == 'te') {
      return teluguAchuluList;
    }
    return uyirLettersList;
  }

  @override
  Future<List<LetterModel>> getMeiLetters() async {
    if (LanguageService.instance.currentLanguageCode == 'te') {
      return teluguHalluluList;
    }
    return meiLettersList;
  }

  @override
  Future<LetterModel> getAythamLetter() async {
    return aythamLetterData;
  }

  @override
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase) async {
    return uyirmeiLettersMap[meiBase] ?? [];
  }

  @override
  Future<List<String>> getMeiGroupBases() async {
    return uyirmeiGroupBases;
  }

  @override
  Future<StoryModel> getFeaturedStory() async {
    return hareAndTortoiseStory;
  }

  @override
  Future<List<GameQuestion>> getGameQuestions() async {
    return letterPuzzleQuestions;
  }

  @override
  Future<List<VideoItem>> getVideoLessons() async {
    return tamilVideoLessonsList;
  }

  @override
  Future<List<QuizCategory>> getQuizCategories() async {
    return tamilQuizCategories;
  }

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId) async {
    return tamilQuizQuestionsMap[categoryId] ?? [];
  }
}

class ApiDataRepository implements IDataRepository {
  final LocalDataRepository _fallback = LocalDataRepository();
  Map<String, List<LetterModel>>? _cachedUyirmeiMap;
  List<LetterModel>? _cachedUyir;
  List<LetterModel>? _cachedMei;
  String? _cachedLang;

  void _checkLanguageCache() {
    final curLang = LanguageService.instance.currentLanguageCode;
    if (_cachedLang != curLang) {
      _cachedUyir = null;
      _cachedMei = null;
      _cachedUyirmeiMap = null;
      _cachedLang = curLang;
    }
  }

  LetterModel _enrichWithLocalAssets(LetterModel letter) {
    if (letter.imagePath == null ||
        letter.imagePath!.isEmpty ||
        letter.imagePath == 'assets/images/welcome.png' ||
        letter.imagePath!.contains('pic__tura_de_ap___s__n__toas')) {
      final List<LetterModel> sourceList = letter.type == LetterType.uyir
          ? (LanguageService.instance.currentLanguageCode == 'te' ? teluguAchuluList : uyirLettersList)
          : (letter.type == LetterType.mei ? (LanguageService.instance.currentLanguageCode == 'te' ? teluguHalluluList : meiLettersList) : []);
      
      final localMatch = sourceList.firstWhere(
        (l) => (l.letter == letter.letter || l.id == letter.id) && l.word == letter.word,
        orElse: () => letter,
      );

      if (localMatch != letter && localMatch.imagePath != null && localMatch.imagePath != 'assets/images/welcome.png') {
        return LetterModel(
          id: letter.id,
          letter: letter.letter,
          type: letter.type,
          word: letter.word,
          meaning: letter.meaning.isNotEmpty ? letter.meaning : localMatch.meaning,
          phonetic: letter.phonetic.isNotEmpty ? letter.phonetic : localMatch.phonetic,
          iconEmoji: letter.iconEmoji.isNotEmpty && letter.iconEmoji != '⭐'
              ? letter.iconEmoji
              : localMatch.iconEmoji,
          imagePath: localMatch.imagePath,
          audioPath: letter.audioPath ?? localMatch.audioPath,
          videoUrl: letter.videoUrl,
          explanation: letter.explanation ?? localMatch.explanation,
          meiBase: letter.meiBase,
          uyirBase: letter.uyirBase,
        );
      }
    }
    return letter;
  }

  @override
  Future<List<LetterModel>> getUyirLetters() async {
    _checkLanguageCache();
    if (_cachedUyir != null && _cachedUyir!.isNotEmpty) {
      return _cachedUyir!;
    }
    final lang = LanguageService.instance.currentLanguageCode;
    final queryLang = (lang == 'en') ? 'ta' : lang;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/letters?type=uyir&lang=$queryLang&all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final letters = list
              .map((item) => _enrichWithLocalAssets(LetterModel.fromJson(item as Map<String, dynamic>)))
              .toList();
          if (letters.isNotEmpty) {
            _cachedUyir = letters;
            return letters;
          }
        }
      }
    } catch (_) {
      // Fall back to local data repository
    }
    return _fallback.getUyirLetters();
  }

  @override
  Future<List<LetterModel>> getMeiLetters() async {
    _checkLanguageCache();
    if (_cachedMei != null && _cachedMei!.isNotEmpty) {
      return _cachedMei!;
    }
    final lang = LanguageService.instance.currentLanguageCode;
    final queryLang = (lang == 'en') ? 'ta' : lang;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/letters?type=mei&lang=$queryLang&all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final letters = list
              .map((item) => _enrichWithLocalAssets(LetterModel.fromJson(item as Map<String, dynamic>)))
              .toList();
          if (letters.isNotEmpty) {
            _cachedMei = letters;
            return letters;
          }
        }
      }
    } catch (_) {
      // Fall back to local data repository
    }
    return _fallback.getMeiLetters();
  }

  @override
  Future<LetterModel> getAythamLetter() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/letters?type=aytham&all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List && (data['data'] as List).isNotEmpty) {
          return LetterModel.fromJson((data['data'] as List).first as Map<String, dynamic>);
        }
      }
    } catch (_) {
      // Fall back to local data repository
    }
    return _fallback.getAythamLetter();
  }

  @override
  Future<List<String>> getMeiGroupBases() => _fallback.getMeiGroupBases();

  StoryModel _enrichStoryWithInteractiveData(StoryModel story) {
    final fallbackPages = hareAndTortoiseStory.pages;
    final enrichedPages = <StoryPageModel>[];

    for (int i = 0; i < story.pages.length; i++) {
      final page = story.pages[i];
      final fallbackPage = i < fallbackPages.length ? fallbackPages[i] : null;

      final interactiveWords = (page.interactiveWords.isNotEmpty)
          ? page.interactiveWords
          : (fallbackPage?.interactiveWords ?? const <StoryInteractiveWord>[]);

      final imagePath = (page.imagePath != null && page.imagePath!.isNotEmpty)
          ? page.imagePath
          : fallbackPage?.imagePath;

      enrichedPages.add(StoryPageModel(
        pageNumber: page.pageNumber,
        text: page.text.isNotEmpty ? page.text : (fallbackPage?.text ?? ''),
        emojiIllustration: page.emojiIllustration.isNotEmpty ? page.emojiIllustration : (fallbackPage?.emojiIllustration ?? '📖'),
        characterName: page.characterName.isNotEmpty ? page.characterName : (fallbackPage?.characterName ?? ''),
        narratorAudio: page.narratorAudio ?? fallbackPage?.narratorAudio,
        imagePath: imagePath,
        interactiveWords: interactiveWords,
      ));
    }

    return StoryModel(
      id: story.id,
      title: story.title,
      subtitle: story.subtitle,
      coverEmoji: story.coverEmoji,
      coverImage: story.coverImage ?? hareAndTortoiseStory.coverImage,
      moral: story.moral.isNotEmpty ? story.moral : hareAndTortoiseStory.moral,
      pages: enrichedPages.isNotEmpty ? enrichedPages : hareAndTortoiseStory.pages,
    );
  }

  @override
  Future<StoryModel> getFeaturedStory() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/stories/story_tortoise_rabbit');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final story = StoryModel.fromJson(data['data'] as Map<String, dynamic>);
          return _enrichStoryWithInteractiveData(story);
        }
      }
    } catch (_) {
      // Fall back to local data repository
    }
    return _fallback.getFeaturedStory();
  }

  @override
  Future<List<GameQuestion>> getGameQuestions() => _fallback.getGameQuestions();

  List<VideoItem>? _cachedVideos;

  void clearVideoCache() {
    _cachedVideos = null;
  }

  @override
  Future<List<VideoItem>> getVideoLessons() async {
    if (_cachedVideos != null && _cachedVideos!.isNotEmpty) {
      return _cachedVideos!;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/videos?all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final videos = list.map((item) => VideoItem.fromJson(item as Map<String, dynamic>)).toList();
          _cachedVideos = videos;
          return videos;
        }
      }
    } catch (_) {
      // Fall back to local data repository
    }
    return _cachedVideos ?? _fallback.getVideoLessons();
  }

  @override
  Future<List<QuizCategory>> getQuizCategories() => _fallback.getQuizCategories();

  @override
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId) => _fallback.getQuizQuestions(categoryId);


  @override
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase) async {
    if (_cachedUyirmeiMap != null && _cachedUyirmeiMap!.containsKey(meiBase)) {
      return _cachedUyirmeiMap![meiBase]!;
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/letters?type=uyirmei&all=true');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          final map = <String, List<LetterModel>>{};

          for (final item in list) {
            final model = LetterModel.fromJson(item as Map<String, dynamic>);
            final base = model.meiBase ?? '';
            if (base.isNotEmpty) {
              map.putIfAbsent(base, () => []).add(model);
            }
          }

          if (map.isNotEmpty) {
            _cachedUyirmeiMap = map;
            if (map.containsKey(meiBase)) {
              return map[meiBase]!;
            }
          }
        }
      }
    } catch (_) {
      // Gracefully fall back to local data repository
    }

    return _fallback.getUyirmeiByGroup(meiBase);
  }

  void invalidateCache() {
    _cachedUyirmeiMap = null;
    _cachedUyir = null;
    _cachedMei = null;
    _cachedVideos = null;
  }
}

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  static DataService get instance => _instance;
  DataService._internal();

  IDataRepository _repo = ApiDataRepository();

  void setRepository(IDataRepository customRepo) {
    _repo = customRepo;
  }

  Future<List<LetterModel>> getUyirLetters() => _repo.getUyirLetters();
  Future<List<LetterModel>> getMeiLetters() => _repo.getMeiLetters();
  Future<LetterModel> getAythamLetter() => _repo.getAythamLetter();
  Future<List<LetterModel>> getUyirmeiByGroup(String meiBase) => _repo.getUyirmeiByGroup(meiBase);
  Future<List<String>> getMeiGroupBases() => _repo.getMeiGroupBases();
  Future<StoryModel> getFeaturedStory() => _repo.getFeaturedStory();
  Future<List<GameQuestion>> getGameQuestions() => _repo.getGameQuestions();
  Future<List<VideoItem>> getVideoLessons() => _repo.getVideoLessons();
  Future<List<QuizCategory>> getQuizCategories() => _repo.getQuizCategories();
  Future<List<QuizQuestion>> getQuizQuestions(String categoryId) => _repo.getQuizQuestions(categoryId);

  void clearVideoCache() {
    if (_repo is ApiDataRepository) {
      (_repo as ApiDataRepository).clearVideoCache();
    }
  }

  void invalidateCache() {
    if (_repo is ApiDataRepository) {
      (_repo as ApiDataRepository).invalidateCache();
    }
  }
}
