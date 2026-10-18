import 'package:flutter/material.dart';
import '../../data/story_data.dart';
import '../../models/story_model.dart';
import '../../services/audio_service.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../services/tamil_tts_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/celebration_dialog.dart';
import '../../widgets/custom_audio_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';

class ReadingScreen extends StatefulWidget {
  final ProgressService progressService;

  const ReadingScreen({super.key, required this.progressService});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  int _currentPage = 0;
  StoryModel _story = hareAndTortoiseStory;
  final AudioService _audioService = AudioService();

  StoryPageModel get _page => _story.pages[_currentPage];

  @override
  void initState() {
    super.initState();
    _fetchStory();
  }

  Future<void> _fetchStory() async {
    try {
      final story = await DataService.instance.getFeaturedStory();
      if (mounted && story.pages.isNotEmpty) {
        setState(() {
          _story = story;
          if (_currentPage >= _story.pages.length) {
            _currentPage = 0;
          }
        });
      }
    } catch (_) {
      // Gracefully maintain local hareAndTortoiseStory
    }
  }

  void _onNext() {
    _audioService.stopAll();
    TamilTtsService.stopSpeech();
    if (_currentPage < _story.pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      // Story completed!
      widget.progressService.completeStory();
      final isEn = LanguageService.instance.isEnglish;
      CelebrationDialog.show(
        context,
        title: isEn ? 'Story Completed!' : 'கதை முடிந்தது!',
        message: isEn
            ? '${_story.moral}\n\nYou completed reading the story wonderfully!'
            : '${_story.moral}\n\nமிக அருமையாகக் கதையை வாசித்து முடித்தாய்!',
        starsEarned: 5,
        buttonText: isEn ? 'Go to Home' : 'முகப்புக்குச் செல்',
        onContinue: () {
          Navigator.of(context).pop();
        },
      );
    }
  }

  void _onPrev() {
    _audioService.stopAll();
    TamilTtsService.stopSpeech();
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _playNarrator() {
    final speechText = _page.text.replaceAll(r'\n', ' ').replaceAll('\n', ' ');
    _audioService.speakText(speechText);
  }

  void _showInteractiveWordDialog(StoryInteractiveWord word) {
    // Speak the Tamil word immediately with voice
    _audioService.playTamilAudio(word.displayLabel, fallbackTamilText: word.word);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.storyColor.withValues(alpha: 0.35), width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row with Word Badge and Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _audioService.playTamilAudio(word.displayLabel, fallbackTamilText: word.word),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              word.displayLabel,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 18,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.primaryDark),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 26),
                      tooltip: 'மூடு',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Word Illustration Image (Tappable for audio!)
                GestureDetector(
                  onTap: () => _audioService.playTamilAudio(word.displayLabel, fallbackTamilText: word.word),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.storyColor.withValues(alpha: 0.2), width: 2),
                      ),
                      child: word.imagePath != null && word.imagePath!.isNotEmpty
                          ? (word.imagePath!.startsWith('http://') || word.imagePath!.startsWith('https://')
                              ? Image.network(
                                  word.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.image_rounded, size: 48, color: AppColors.storyColor),
                                  ),
                                )
                              : Image.asset(
                                  word.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.image_rounded, size: 48, color: AppColors.storyColor),
                                  ),
                                ))
                          : const Center(
                              child: Icon(Icons.image_rounded, size: 48, color: AppColors.storyColor),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Meaning & explanation in Tamil (Tappable for audio!)
                if (word.meaning != null && word.meaning!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _audioService.playTamilAudio(word.meaning ?? word.displayLabel),
                    child: Text(
                      word.meaning!,
                      style: AppTextStyles.bodyTextBold.copyWith(
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Sound pronunciation button
                BouncyButton(
                  onPressed: () => _audioService.playTamilAudio(word.displayLabel, fallbackTamilText: word.word),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.storyColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up_rounded, color: AppColors.storyColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'ஒலிப்பைக் கேட்க',
                          style: AppTextStyles.bodyTextBold.copyWith(
                            fontSize: 14,
                            color: AppColors.storyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Return to Story button
                SizedBox(
                  width: double.infinity,
                  child: BouncyButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.orangeGradient),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'கதைக்குத் திரும்பு',
                            style: AppTextStyles.bodyTextBold.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _audioService.stopAll();
    TamilTtsService.stopSpeech();
    super.dispose();
  }

  StoryInteractiveWord? _findMatchingInteractiveWord(String cleanWord) {
    if (cleanWord.isEmpty || _page.interactiveWords.isEmpty) return null;

    // 1. Exact match in current page's interactiveWords
    for (final iw in _page.interactiveWords) {
      if (iw.word == cleanWord || iw.displayLabel == cleanWord) {
        return iw;
      }
    }

    // 2. Substring / base word match in current page's interactiveWords
    for (final iw in _page.interactiveWords) {
      if (cleanWord.startsWith(iw.word) || iw.word.startsWith(cleanWord) ||
          cleanWord.startsWith(iw.displayLabel) || iw.displayLabel.startsWith(cleanWord)) {
        return iw;
      }
    }

    return null;
  }

  Widget _buildStorySentence() {
    final cleanText = _page.text.replaceAll(r'\n', '\n');
    final lines = cleanText.split('\n');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: lines.map((line) {
        final words = line.trim().split(RegExp(r'\s+'));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 8,
            children: words.map((rawWord) {
              if (rawWord.isEmpty) return const SizedBox.shrink();

              // Extract punctuation from rawWord
              final cleanWord = rawWord.replaceAll(RegExp(r'[.,!?:;"\(\)]'), '').trim();
              final punctuation = rawWord.replaceAll(cleanWord, '').trim();

              final matchedWord = _findMatchingInteractiveWord(cleanWord);

              if (matchedWord != null) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BouncyButton(
                      onPressed: () => _showInteractiveWordDialog(matchedWord),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.storyColor.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.storyColor.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          cleanWord,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.storyColor,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.solid,
                            decorationColor: AppColors.storyColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    if (punctuation.isNotEmpty)
                      Text(
                        punctuation,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 19,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                );
              }

              return Text(
                rawWord,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 20,
                  height: 1.5,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSceneIllustration() {
    return GestureDetector(
      onTap: () {
        TamilTtsService.speak(_page.characterName);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.storyColor.withValues(alpha: 0.25), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(26),
            ),
            child: _page.imagePath != null && _page.imagePath!.isNotEmpty
                ? (_page.imagePath!.startsWith('http://') || _page.imagePath!.startsWith('https://')
                    ? Image.network(
                        _page.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.storyColor),
                        ),
                      )
                    : Image.asset(
                        _page.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.storyColor),
                        ),
                      ))
                : const Center(
                    child: Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.storyColor),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _story.pages.length - 1;
    final isEn = LanguageService.instance.isEnglish;

    return Scaffold(
      appBar: KidAppBar(
        title: isEn ? '${_story.title} (Story)' : _story.title,
        starCount: widget.progressService.stars,
      ),
      body: KidScaffoldBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // Top Mascot Companion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const MascotWidget(
                          pose: MascotPose.story,
                          size: MascotSize.small,
                          customHeight: 110,
                          showGlow: true,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.storyColor.withValues(alpha: 0.4), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.storyColor.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              isEn ? "Let's read the story together!" : 'முயலும் ஆமையும் கதையை வாசிப்போம்!',
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Progress Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_story.pages.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.storyColor : const Color(0xFFDCDCE0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Story Page Card
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Container(
                        key: ValueKey<int>(_currentPage),
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.storyColor.withValues(alpha: 0.35), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.storyColor.withValues(alpha: 0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Scene character tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _page.characterName,
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Cartoon Illustration Image
                            _buildSceneIllustration(),
                            const SizedBox(height: 16),

                            // Short Tamil sentence (Page 1 has 3 interactive words, Pages 2-6 clean text)
                            _buildStorySentence(),
                            const SizedBox(height: 16),

                            // Audio narration button
                            CustomAudioButton(
                              label: isEn ? 'Listen to Story' : 'வாசிப்பைக் கேட்போம்',
                              color: AppColors.storyColor,
                              onTap: _playNarrator,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Page navigation controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          Flexible(
                            child: BouncyButton(
                              onPressed: _onPrev,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.borderLight, width: 2),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                        isEn ? 'Previous' : 'முந்தையது',
                                        style: AppTextStyles.bodyTextBold.copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 44),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            isEn
                                ? 'Page ${_currentPage + 1} / ${_story.pages.length}'
                                : 'பக்கம் ${_currentPage + 1} / ${_story.pages.length}',
                            style: AppTextStyles.bodyTextBold.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Flexible(
                          child: BouncyButton(
                            onPressed: _onNext,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLastPage ? AppColors.greenGradient : AppColors.orangeGradient,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLastPage ? AppColors.mintGreen : AppColors.primary).withValues(alpha: 0.4),
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
                                    Text(
                                      isLastPage
                                          ? (isEn ? 'Finish' : 'முடித்தேன்')
                                          : (isEn ? 'Next' : 'அடுத்தது'),
                                      style: AppTextStyles.bodyTextBold.copyWith(color: Colors.white, fontSize: 14),
                                    ),
                                    if (!isLastPage) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
