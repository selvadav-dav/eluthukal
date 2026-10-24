import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import 'uyirmei_method2_screen.dart';
import 'uyirmei_screen.dart';

class UyirmeiSelectionScreen extends StatelessWidget {
  final ProgressService progressService;

  const UyirmeiSelectionScreen({super.key, required this.progressService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([progressService, LanguageService.instance]),
      builder: (context, _) {
        final langService = LanguageService.instance;
        final isEn = langService.isEnglish;

        return Scaffold(
          appBar: KidAppBar(
            title: isEn ? 'Consonant-Vowel Combinations' : 'உயிர்மெய் எழுத்துகள்',
            starCount: progressService.stars,
            showBack: true,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                    children: [
                      // Top Hero Mascot Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: const Color(0xFF81C784),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintGreen.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? 'Consonant-Vowel Combinations' : 'உயிர்மெய் கற்றல்',
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: isEn ? 17 : 20,
                                      color: const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEn
                                        ? 'Select a method to learn'
                                        : 'கற்றல் முறையைத் தேர்வுசெய்க',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF388E3C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const MascotWidget(
                              pose: MascotPose.learn,
                              size: MascotSize.small,
                              customHeight: 85,
                              showGlow: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Card 1: கற்றல் முறை 1
                      _buildMethodCard(
                        context,
                        title: isEn ? 'Learning Method 1' : 'கற்றல் முறை 1',
                        gradientColors: const [
                          Color(0xFF845EC2),
                          Color(0xFFD65DB1),
                        ],
                        icon: Icons.flip_camera_android_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UyirmeiScreen(
                                progressService: progressService,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // Card 2: கற்றல் முறை 2
                      _buildMethodCard(
                        context,
                        title: isEn ? 'Learning Method 2' : 'கற்றல் முறை 2',
                        gradientColors: const [
                          Color(0xFF0052D4),
                          Color(0xFF4364F7),
                        ],
                        icon: Icons.table_chart_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UyirmeiMethod2Screen(
                                progressService: progressService,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required List<Color> gradientColors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: gradientColors.first.withValues(alpha: 0.35),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 18),
            // Title: "கற்றல் முறை 1" or "கற்றல் முறை 2"
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ),
            // Arrow indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: gradientColors.first.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: gradientColors.first,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
