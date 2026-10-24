import 'package:flutter/material.dart';

import '../../models/letter_model.dart';
import '../../models/video_model.dart';
import '../../services/audio_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/custom_audio_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
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
            title: letter.letter,
            starCount: widget.progressService.stars,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Mascot Companion (writing.png)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const MascotWidget(
                          pose: MascotPose.writing,
                          size: MascotSize.small,
                          customHeight: 115,
                          showGlow: true,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: 0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              isEn
                                  ? 'Let\'s practice pronouncing letter "${letter.letter}"!'
                                  : 'எழுத்து "${letter.letter}" ஐ உச்சரித்துப் பழகுவோம்!',
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Giant Collectible Letter Card
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.22),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Illustration Image or Emoji Icon (Tappable to hear letter sound)
                            BouncyButton(
                              onPressed: _playAudio,
                              child: Container(
                                width: 150,
                                height: 150,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: letter.imagePath != null
                                      ? Colors.white
                                      : color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.35),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(21),
                                  child: LetterMediaImage(
                                    imagePath: letter.imagePath,
                                    iconEmoji: letter.iconEmoji,
                                    fit: BoxFit.contain,
                                    emojiSize: 60,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Large Tamil Letter (Tappable to hear letter sound)
                            BouncyButton(
                              onPressed: _playAudio,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  letter.letter,
                                  style: AppTextStyles.tamilLetterLarge
                                      .copyWith(
                                        fontSize: 84,
                                        color: color,
                                        fontWeight: FontWeight.w900,
                                        height: 1.0,
                                      ),
                                ),
                              ),
                            ),

                            // Example Word with target letter highlighted (e.g. ச[க்]கரம்) - Tappable to hear WORD sound
                            if (letter.word.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              BouncyButton(
                                onPressed: () => _audioService.playLetterSound(
                                  context,
                                  letter: letter.word,
                                  showIndicator: true,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.volume_up_rounded,
                                        color: color,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildHighlightedWord(
                                        letter.word,
                                        letter.letter,
                                        color,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Audio Action Buttons (No overflow)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: CustomAudioButton(
                            label: isEn ? 'Listen' : 'கேட்போம்',
                            color: color,
                            onTap: _playAudio,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: CustomAudioButton(
                            label: isEn ? 'Replay' : 'மீண்டும்',
                            color: color,
                            isSecondary: true,
                            onTap: _playAudio,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Direct Writing Practice Shortcut
                    BouncyButton(
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
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF006E), Color(0xFFFF70A6)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF006E)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEn ? 'Practice Writing' : 'எழுதிப் பழகுவோம்',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Teaching Video Button (if video_url is present from Admin Panel)
                    if (letter.videoUrl != null &&
                        letter.videoUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      BouncyButton(
                        onPressed: () {
                          final isMei = letter.type == LetterType.mei;
                          final videoItem = VideoItem(
                            id: 'letter_video_${letter.id}',
                            title: '${letter.letter} - ${letter.word} காணொளி',
                            description:
                                '${letter.letter} எழுத்து கற்பிக்கும் சிறப்பு காணொளி பாடம்',
                            category: isMei
                                ? 'மெய் எழுத்துகள்'
                                : 'உயிர் எழுத்துகள்',
                            duration: '1:30',
                            thumbnailEmoji: '',
                            videoUrl: letter.videoUrl!,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                video: videoItem,
                                progressService: widget.progressService,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B1FA2)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEn
                                      ? 'Watch Video Lesson'
                                      : 'காணொளி பாடம் (Watch Video)',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // Previous / Next Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hasPrev)
                          Flexible(
                            child: BouncyButton(
                              onPressed: _goToPrevious,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppColors.borderLight,
                                    width: 2,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'முந்தையது',
                                        style: AppTextStyles.bodyTextBold
                                            .copyWith(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.letterList.length}',
                            style: AppTextStyles.bodyTextBold.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (hasNext)
                          Flexible(
                            child: BouncyButton(
                              onPressed: _goToNext,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color,
                                      color.withValues(alpha: 0.85),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
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
                                        'அடுத்தது',
                                        style: AppTextStyles.bodyTextBold
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
