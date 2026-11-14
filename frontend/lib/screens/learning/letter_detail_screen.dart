import 'package:flutter/material.dart';

import '../../data/video_data.dart';
import '../../models/letter_model.dart';
import '../../models/video_model.dart';
import '../../services/audio_service.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/custom_audio_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/letter_media_image.dart';
import '../videos/video_player_screen.dart';
import '../writing/writing_practice_screen.dart';

class LetterDetailScreen extends StatefulWidget {
  final List<LetterModel> letterList;
  final int initialIndex;
  final Color accentColor;
  final ProgressService progressService;

  const LetterDetailScreen({
    super.key,
    required this.letterList,
    required this.initialIndex,
    required this.accentColor,
    required this.progressService,
  });

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final AudioService _audioService = AudioService();

  LetterModel get _currentLetter => widget.letterList[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.forward();
    _markCompleted();
  }

  @override
  void dispose() {
    _audioService.stopAll();
    _animController.dispose();
    super.dispose();
  }

  void _markCompleted() {
    widget.progressService.markLetterCompleted(_currentLetter.id);
  }

  void _playAudio() {
    _audioService.playLetterSound(
      context,
      letter: _currentLetter.letter,
      word: _currentLetter.word,
      audioPath: _currentLetter.audioPath,
    );
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _audioService.stopAll();
      setState(() {
        _currentIndex--;
      });
      _animController.forward(from: 0.0);
      _markCompleted();
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.letterList.length - 1) {
      _audioService.stopAll();
      setState(() {
        _currentIndex++;
      });
      _animController.forward(from: 0.0);
      _markCompleted();
    }
  }

  Future<VideoItem?> _resolveVideoForLetter(LetterModel letter) async {
    // 1. If explicit videoUrl is configured on the letter
    if (letter.videoUrl != null && letter.videoUrl!.trim().isNotEmpty) {
      final isMei = letter.type == LetterType.mei;
      return VideoItem(
        id: 'letter_video_${letter.id}',
        title: '${letter.letter} - ${letter.word} காணொளி',
        description: '${letter.letter} எழுத்து கற்பிக்கும் சிறப்பு காணொளி பாடம்',
        category: isMei ? 'மெய் எழுத்துகள்' : 'உயிர் எழுத்துகள்',
        duration: '00:15',
        thumbnailEmoji: '🎬${letter.letter}',
        videoUrl: letter.videoUrl!,
      );
    }

    // 2. Fetch all videos from DataService or fallback list
    List<VideoItem> videos = [];
    try {
      videos = await DataService.instance.getVideoLessons();
    } catch (_) {}
    if (videos.isEmpty) {
      videos = tamilVideoLessonsList;
    }

    final char = letter.letter.trim();

    // Match 1: Direct title equality (e.g. 'அ', 'ஆ', 'க்')
    for (final v in videos) {
      if (v.title.trim() == char) return v;
    }

    // Match 2: Special Aytham 'ஃ'
    if (char == 'ஃ') {
      for (final v in videos) {
        if (v.title.contains('ஆயுத') ||
            v.category.contains('ஆய்த') ||
            v.thumbnailEmoji.contains('ஃ') ||
            v.description.contains('ஃ')) {
          return v;
        }
      }
    }

    // Match 3: Description with the letter
    for (final v in videos) {
      if (v.description.contains('($char)') ||
          v.description.contains(' $char(') ||
          v.description.contains(' $char ') ||
          v.description.contains('($char') ||
          v.description.contains('$char)')) {
        return v;
      }
    }

    // Match 4: Word matching (e.g. 'அம்மா', 'காக்கை')
    if (letter.word.isNotEmpty) {
      for (final v in videos) {
        if (v.description.contains(letter.word) || v.title.contains(letter.word)) {
          return v;
        }
      }
    }

    // Match 5: Fallback search in hardcoded tamilVideoLessonsList
    for (final v in tamilVideoLessonsList) {
      if (v.title.trim() == char) return v;
    }

    return null;
  }

  void _playVideoForLetter(BuildContext context, LetterModel letter) async {
    _audioService.stopAll();

    final videoItem = await _resolveVideoForLetter(letter);

    if (!context.mounted) return;

    if (videoItem != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            video: videoItem,
            progressService: widget.progressService,
          ),
        ),
      );
    } else {
      final isEn = LanguageService.instance.isEnglish;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Video for "${letter.letter}" will be added soon!'
                : '"${letter.letter}" எழுத்திற்கான காணொளி விரைவில் சேர்க்கப்படும்!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildHighlightedWord(
    String word,
    String targetLetter,
    Color highlightColor,
  ) {
    if (word.isEmpty) return const SizedBox.shrink();

    final spans = <TextSpan>[];
    final index = word.indexOf(targetLetter);

    if (index != -1) {
      // Leading part of the word
      if (index > 0) {
        spans.add(
          TextSpan(
            text: word.substring(0, index),
            style: AppTextStyles.wordLarge.copyWith(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      // Target letter highlighted in vibrant color!
      spans.add(
        TextSpan(
          text: targetLetter,
          style: AppTextStyles.wordLarge.copyWith(
            color: highlightColor,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      );
      // Trailing part of the word
      final remaining = word.substring(index + targetLetter.length);
      if (remaining.isNotEmpty) {
        spans.add(
          TextSpan(
            text: remaining,
            style: AppTextStyles.wordLarge.copyWith(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
    } else {
      // Fallback
      spans.add(
        TextSpan(
          text: word,
          style: AppTextStyles.wordLarge.copyWith(
            color: AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final letter = _currentLetter;
    final color = widget.accentColor;
    final hasPrev = _currentIndex > 0;
    final hasNext = _currentIndex < widget.letterList.length - 1;

    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final isEn = LanguageService.instance.isEnglish;
        return Scaffold(
          appBar: KidAppBar(
            title: '',
            starCount: widget.progressService.stars,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Giant Collectible Letter Card (Big Card as requested)
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 22,
                              horizontal: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: color.withValues(alpha: 0.4),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.2),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Illustration Image (Large 240x240 image tile)
                                BouncyButton(
                                  onPressed: _playAudio,
                                  child: Container(
                                    width: 240,
                                    height: 240,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: letter.imagePath != null
                                          ? Colors.white
                                          : color.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.35),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.14),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(23),
                                      child: LetterMediaImage(
                                        imagePath: letter.imagePath,
                                        iconEmoji: letter.iconEmoji,
                                        fit: BoxFit.contain,
                                        emojiSize: 90,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Large Tamil Letter (88px)
                                BouncyButton(
                                  onPressed: _playAudio,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      letter.letter,
                                      style: AppTextStyles.tamilLetterLarge.copyWith(
                                        fontSize: 88,
                                        color: color,
                                        fontWeight: FontWeight.w800,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Bottom Card Row: Word Audio on LEFT, Video Play Button on RIGHT
                                Row(
                                  children: [
                                    // Left: Word audio button (e.g. 🔊 அம்மா)
                                    Expanded(
                                      child: BouncyButton(
                                        onPressed: () => _audioService.playLetterSound(
                                          context,
                                          letter: letter.word.isNotEmpty
                                              ? letter.word
                                              : letter.letter,
                                          showIndicator: true,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: color.withValues(alpha: 0.35),
                                              width: 1.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.volume_up_rounded,
                                                color: color,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 5),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: _buildHighlightedWord(
                                                    letter.word.isNotEmpty
                                                        ? letter.word
                                                        : letter.letter,
                                                    letter.letter,
                                                    color,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Right: Video Play Button with clear video aesthetics
                                    Expanded(
                                      child: BouncyButton(
                                        onPressed: () =>
                                            _playVideoForLetter(context, letter),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF3366),
                                                Color(0xFFFF5E7E),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF3366)
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 26,
                                                height: 26,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 3,
                                                      offset: Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: Color(0xFFFF3366),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    isEn ? 'Video' : 'காணொளி',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.white,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. Action Buttons Row: [கேட்போம்] and [எழுதிப் பழகுவோம்] (RIGHT BELOW CARD)
                        Row(
                          children: [
                            Expanded(
                              child: CustomAudioButton(
                                label: isEn ? 'Listen' : 'கேட்போம்',
                                color: color,
                                onTap: _playAudio,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: BouncyButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WritingPracticeScreen(
                                        progressService: widget.progressService,
                                        initialLetter: letter.letter,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF006E),
                                        Color(0xFFFF70A6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF006E)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isEn ? 'Practice Writing' : 'எழுதிப் பழகுவோம்',
                                          style: AppTextStyles.buttonText.copyWith(
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 3. Navigation Footer Row: [< முந்தையது] ... [2 / 12] ... [அடுத்தது >]
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (hasPrev)
                              Flexible(
                                child: BouncyButton(
                                  onPressed: _goToPrevious,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: AppColors.borderLight,
                                        width: 1.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            size: 14,
                                            color: AppColors.textDark,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isEn ? 'Previous' : 'முந்தையது',
                                            style: AppTextStyles.bodyTextBold.copyWith(
                                              fontSize: 13,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 32),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.borderLight, width: 1.2),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / ${widget.letterList.length}',
                                style: AppTextStyles.bodyTextBold.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (hasNext)
                              Flexible(
                                child: BouncyButton(
                                  onPressed: _goToNext,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color,
                                          color.withValues(alpha: 0.88)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isEn ? 'Next' : 'அடுத்தது',
                                            style: AppTextStyles.bodyTextBold.copyWith(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Flexible(
                                child: BouncyButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isEn ? 'Done' : 'முடிந்தது',
                                            style: AppTextStyles.bodyTextBold.copyWith(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
