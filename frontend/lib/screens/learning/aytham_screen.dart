import 'package:flutter/material.dart';

import '../../data/aytham_data.dart';
import '../../data/video_data.dart';
import '../../services/audio_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/custom_audio_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../videos/video_player_screen.dart';
import '../writing/writing_practice_screen.dart';

class AythamScreen extends StatefulWidget {
  final ProgressService progressService;

  const AythamScreen({super.key, required this.progressService});

  @override
  State<AythamScreen> createState() => _AythamScreenState();
}

class _AythamScreenState extends State<AythamScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.progressService.markLetterCompleted(aythamLetterData.id);
  }

  @override
  void dispose() {
    _audioService.stopAll();
    _pulseController.dispose();
    super.dispose();
  }

  void _playAudio() {
    _audioService.playLetterSound(
      context,
      letter: aythamLetterData.letter,
      word: aythamLetterData.word,
      audioPath: aythamLetterData.audioPath,
    );
  }

  void _playVideoForAytham(BuildContext context) {
    _audioService.stopAll();
    final aythamVideo = tamilVideoLessonsList.firstWhere(
      (v) =>
          v.id == 'vid_1794304563578' ||
          v.category.contains('ஆய்த') ||
          v.title.contains('ஆயுத') ||
          v.title.contains('ஆய்த'),
      orElse: () => tamilVideoLessonsList.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: aythamVideo,
          progressService: widget.progressService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // Giant Card for ஃ
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.symmetric(
                              vertical: 32,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                color: AppColors.aythamColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.aythamColor.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  aythamLetterData.letter,
                                  style: AppTextStyles.tamilLetterLarge
                                      .copyWith(
                                        fontSize: 110,
                                        color: AppColors.aythamColor,
                                        fontWeight: FontWeight.w900,
                                        height: 1.0,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.aythamColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    size: 56,
                                    color: AppColors.aythamColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isEn
                                      ? 'Aytham Letter (ஃ)'
                                      : 'ஆய்த எழுத்து (ஃ)',
                                  style: AppTextStyles.cardTitle.copyWith(
                                    color: AppColors.textDark,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isEn
                                      ? 'Example: எஃகு (Steel Sword)'
                                      : 'எடுத்துக்காட்டு: எஃகு (வாள்)',
                                  style: AppTextStyles.cardSubtitle.copyWith(
                                    fontSize: 17,
                                    color: AppColors.aythamColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Bottom Card Row: Left [🔊 எஃகு], Right [▶ காணொளி]
                                Row(
                                  children: [
                                    Expanded(
                                      child: BouncyButton(
                                        onPressed: () => _audioService.playLetterSound(
                                          context,
                                          letter: aythamLetterData.word,
                                          showIndicator: true,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.aythamColor
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            border: Border.all(
                                              color: AppColors.aythamColor
                                                  .withValues(alpha: 0.35),
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.volume_up_rounded,
                                                color: AppColors.aythamColor,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    'எஃகு',
                                                    style: AppTextStyles
                                                        .wordLarge
                                                        .copyWith(
                                                      color:
                                                          AppColors.aythamColor,
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: BouncyButton(
                                        onPressed: () =>
                                            _playVideoForAytham(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
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
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF3366)
                                                    .withValues(alpha: 0.36),
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
                                                width: 28,
                                                height: 28,
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
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    isEn ? 'Video' : 'காணொளி',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
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
                        const SizedBox(height: 24),

                        // Action Buttons: [கேட்போம்] and [எழுதிப் பழகுவோம்]
                        Row(
                          children: [
                            Expanded(
                              child: CustomAudioButton(
                                label: isEn ? 'Listen' : 'கேட்போம்',
                                color: AppColors.aythamColor,
                                onTap: _playAudio,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BouncyButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WritingPracticeScreen(
                                        progressService: widget.progressService,
                                        initialLetter: 'ஃ',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
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
                        const SizedBox(height: 24),

                        // Fact Cards
                        _buildFactTile(
                          isEn ? 'Three Dots' : 'மூன்று புள்ளிகள்',
                          isEn
                              ? 'Known as Muppulli, unique three-dotted letter.'
                              : 'இது முப்புள்ளி அல்லது முப்பாற்புள்ளி எனப்படும்.',
                          Icons.auto_awesome_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildFactTile(
                          isEn ? 'Special Letter' : 'தனித்தமிழ் எழுத்து',
                          isEn
                              ? 'It never appears at the start; only in the middle of words.'
                              : 'இது சொல்லின் முதலில் வராது; இடையில் மட்டுமே வரும்.',
                          Icons.menu_book_rounded,
                        ),
                        const SizedBox(height: 24),
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

  Widget _buildFactTile(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.aythamColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.aythamColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
