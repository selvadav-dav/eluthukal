import 'dart:convert';

/// Model representing an interactive, tappable vocabulary word within a story page.
class StoryInteractiveWord {
  final String word; // exact word or word form in the sentence, e.g. "காட்டில்" or "முயல்"
  final String displayLabel; // Child friendly label in Tamil, e.g. "காடு"
  final String? imagePath; // Asset path or network URL for the illustration
  final String? emoji; // Emoji representation, e.g. "🌲"
  final String? meaning; // Tamil and English meaning explanation
  final String? audioPath; // Audio pronunciation path or text

  const StoryInteractiveWord({
    required this.word,
    required this.displayLabel,
    this.imagePath,
    this.emoji,
    this.meaning,
    this.audioPath,
  });

  factory StoryInteractiveWord.fromJson(Map<String, dynamic> json) {
    return StoryInteractiveWord(
      word: json['word'] as String? ?? '',
      displayLabel: json['displayLabel'] as String? ??
          json['display_label'] as String? ??
          json['label'] as String? ??
          json['word'] as String? ??
          '',
      imagePath: json['imagePath'] as String? ?? json['image_path'] as String?,
      emoji: json['emoji'] as String?,
      meaning: json['meaning'] as String?,
      audioPath: json['audioPath'] as String? ?? json['audio_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'displayLabel': displayLabel,
      if (imagePath != null) 'imagePath': imagePath,
      if (emoji != null) 'emoji': emoji,
      if (meaning != null) 'meaning': meaning,
      if (audioPath != null) 'audioPath': audioPath,
    };
  }
}

/// Model representing a single page/scene in the reading story.
class StoryPageModel {
  final int pageNumber;
  final String text;
  final String emojiIllustration;
  final String characterName;
  final String? narratorAudio;
  final String? imagePath;
  final List<StoryInteractiveWord> interactiveWords;

  const StoryPageModel({
    required this.pageNumber,
    required this.text,
    required this.emojiIllustration,
    required this.characterName,
    this.narratorAudio,
    this.imagePath,
    this.interactiveWords = const [],
  });

  factory StoryPageModel.fromJson(Map<String, dynamic> json) {
    var wordsList = <StoryInteractiveWord>[];
    if (json['interactiveWords'] != null && json['interactiveWords'] is List) {
      wordsList = (json['interactiveWords'] as List)
          .map((w) => StoryInteractiveWord.fromJson(w as Map<String, dynamic>))
          .toList();
    } else if (json['interactive_words'] != null) {
      if (json['interactive_words'] is List) {
        wordsList = (json['interactive_words'] as List)
            .map((w) => StoryInteractiveWord.fromJson(w as Map<String, dynamic>))
            .toList();
      } else if (json['interactive_words'] is String &&
          (json['interactive_words'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(json['interactive_words'] as String);
          if (decoded is List) {
            wordsList = decoded
                .map((w) => StoryInteractiveWord.fromJson(w as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {}
      }
    }

    return StoryPageModel(
      pageNumber: json['pageNumber'] as int? ?? json['page_number'] as int? ?? 1,
      text: (json['text'] as String? ?? '').replaceAll(r'\n', '\n'),
      emojiIllustration: json['emojiIllustration'] as String? ??
          json['emoji_illustration'] as String? ??
          '📖',
      characterName: json['characterName'] as String? ??
          json['character_name'] as String? ??
          '',
      narratorAudio: json['narratorAudio'] as String? ?? json['narrator_audio'] as String?,
      imagePath: json['imagePath'] as String? ?? json['image_path'] as String?,
      interactiveWords: wordsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'text': text,
      'emojiIllustration': emojiIllustration,
      'characterName': characterName,
      if (narratorAudio != null) 'narratorAudio': narratorAudio,
      if (imagePath != null) 'imagePath': imagePath,
      'interactiveWords': interactiveWords.map((w) => w.toJson()).toList(),
    };
  }
}

/// Model representing a reading story.
class StoryModel {
  final String id;
  final String title;
  final String subtitle;
  final String coverEmoji;
  final String? coverImage;
  final String moral;
  final List<StoryPageModel> pages;

  const StoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverEmoji,
    this.coverImage,
    required this.moral,
    required this.pages,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    var pagesList = <StoryPageModel>[];
    if (json['pages'] != null && json['pages'] is List) {
      pagesList = (json['pages'] as List)
          .map((p) => StoryPageModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return StoryModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      coverEmoji: json['coverEmoji'] as String? ?? json['cover_emoji'] as String? ?? '📖',
      coverImage: json['coverImage'] as String? ?? json['cover_image'] as String?,
      moral: json['moral'] as String? ?? '',
      pages: pagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'coverEmoji': coverEmoji,
      if (coverImage != null) 'coverImage': coverImage,
      'moral': moral,
      'pages': pages.map((p) => p.toJson()).toList(),
    };
  }
}
