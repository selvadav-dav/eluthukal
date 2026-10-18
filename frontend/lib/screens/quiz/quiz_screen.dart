import 'package:flutter/material.dart';
import '../../data/quiz_data.dart';
import '../../models/quiz_model.dart';
import '../../services/audio_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import 'quiz_play_screen.dart';

class QuizScreen extends StatelessWidget {
  final ProgressService progressService;

  const QuizScreen({super.key, required this.progressService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([progressService, LanguageService.instance]),
      builder: (context, _) {
        final isEn = LanguageService.instance.isEnglish;
        return Scaffold(
          appBar: KidAppBar(
            title: LanguageService.instance.quizHeading,
            starCount: progressService.stars,
            showBack: false,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      // Hero Card with Quiz Mascot
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF9FA8DA), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.meiColor.withValues(alpha: 0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isEn ? 'Quiz Arena' : 'அறிவு அரங்கம்',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.meiColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isEn ? 'Test what we learned!' : 'நாம் கற்றதை சோதிப்போம்!',
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 18,
                                      color: const Color(0xFF1A237E),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isEn
                                            ? 'High Score: ${progressService.quizHighScore}'
                                            : 'உயர் மதிப்பெண்: ${progressService.quizHighScore}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF283593),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.star_rounded, color: AppColors.starGold, size: 18),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const MascotWidget(
                              pose: MascotPose.quiz,
                              size: MascotSize.small,
                              customHeight: 110,
                              showGlow: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Categories list
                      ...tamilQuizCategories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildCategoryCard(context, category),
                        );
                      }),
                      const SizedBox(height: 20),
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

  IconData _getCategoryIcon(String id) {
    switch (id) {
      case 'quiz_uyir':
        return Icons.menu_book_rounded;
      case 'quiz_mei':
        return Icons.auto_stories_rounded;
      case 'quiz_words':
        return Icons.translate_rounded;
      case 'quiz_general':
        return Icons.lightbulb_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  Widget _buildCategoryCard(BuildContext context, QuizCategory category) {
    return BouncyButton(
      onPressed: () {
        AudioService.instance.playTamilAudio(category.title);
        final questions = tamilQuizQuestionsMap[category.id] ?? [];
        if (questions.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizPlayScreen(
                category: category,
                questions: questions,
                progressService: progressService,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.meiColor.withValues(alpha: 0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(
                _getCategoryIcon(category.id),
                color: AppColors.primaryDark,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category.title,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => AudioService.instance.playTamilAudio(category.title),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volume_up_rounded,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.subtitle,
                    style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${category.questionCount} வினாக்கள் • +${category.questionCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star_rounded, color: AppColors.starGold, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.meiColor, size: 18),
          ],
        ),
      ),
    );
  }
}
