import 'package:flutter/material.dart';

import '../../data/aytham_data.dart';
import '../../services/audio_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_audio_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final isEn = LanguageService.instance.isEnglish;
        return Scaffold(
          appBar: KidAppBar(
            title: isEn ? 'Aytham Letter (1)' : 'ஆய்த எழுத்து (1)',
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
                        // Top Mascot companion
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const MascotWidget(
                              pose: MascotPose.learn,
                              size: MascotSize.small,
                              customHeight: 110,
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
                                    color: AppColors.aythamColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.aythamColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  isEn
                                      ? 'Aytham Letter ஃ - Unique Three-Dot Letter!'
                                      : 'ஆய்த எழுத்து ஃ - முப்புள்ளி!',
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

                        // Giant Card for ஃ
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 380),
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
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Audio buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: CustomAudioButton(
                                label: isEn ? 'Listen' : 'கேட்போம்',
                                color: AppColors.aythamColor,
                                onTap: _playAudio,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: CustomAudioButton(
                                label: isEn ? 'Replay' : 'மீண்டும்',
                                color: AppColors.aythamColor,
                                isSecondary: true,
                                onTap: _playAudio,
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
