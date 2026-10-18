import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/audio_button.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  final QuizCategory category;
  final List<QuizQuestion> questions;
  final ProgressService progressService;

  const QuizPlayScreen({
    super.key,
    required this.category,
    required this.questions,
    required this.progressService,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _hasAnswered = false;
  final AudioService _audioService = AudioService();

  late AnimationController _feedbackAnim;

  QuizQuestion get _currentQuestion => widget.questions[_currentIndex];

  @override
  void initState() {
    super.initState();
    _feedbackAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentQuestion();
    });
  }

  void _speakCurrentQuestion() {
    if (!mounted) return;
    _audioService.stopAll();
    _audioService.playTamilAudio(_currentQuestion.question);
  }

  @override
  void dispose() {
    _audioService.stopAll();
    _feedbackAnim.dispose();
    super.dispose();
  }

  void _onAnswerTap(int index) {
    if (_hasAnswered) return;

    final isCorrect = index == _currentQuestion.correctIndex;
    final selectedOption = _currentQuestion.options[index];

    setState(() {
      _selectedAnswerIndex = index;
      _hasAnswered = true;
      if (isCorrect) {
        _score++;
        _audioService.playSuccessFeedback(context);
      } else {
        _audioService.playRetryFeedback(context);
      }
    });

    // Speak selected answer
    _audioService.playTamilAudio(selectedOption);

    _feedbackAnim.forward(from: 0.0);
  }

  void _goToNext() {
    _audioService.stopAll();
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerIndex = null;
        _hasAnswered = false;
      });
      _speakCurrentQuestion();
    } else {
      final starsEarned = (_score >= widget.questions.length ? 4 : (_score > 0 ? 2 : 1));
      widget.progressService.recordQuizScore(
        _score,
        starsEarned,
        quizId: widget.category.id,
        totalQuestions: widget.questions.length,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            score: _score,
            totalQuestions: widget.questions.length,
            starsEarned: starsEarned,
            onRetry: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPlayScreen(
                    category: widget.category,
                    questions: widget.questions,
                    progressService: widget.progressService,
                  ),
                ),
              );
            },
            onHome: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    final total = widget.questions.length;
    final isCorrect = _selectedAnswerIndex == q.correctIndex;

    return Scaffold(
      appBar: KidAppBar(
        title: widget.category.title,
        starCount: widget.progressService.stars,
      ),
      body: KidScaffoldBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Progress & Score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'வினா ${_currentIndex + 1} / $total',
                          style: AppTextStyles.bodyTextBold.copyWith(color: AppColors.textMuted, fontSize: 14),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'மதிப்பெண்: $_score',
                              style: AppTextStyles.bodyTextBold.copyWith(color: AppColors.primaryDark, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: AppColors.starGold, size: 20),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / total,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF0F0F2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question Card with Quiz Mascot
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          MascotWidget(
                            pose: _hasAnswered
                                ? (isCorrect ? MascotPose.game : MascotPose.welcome)
                                : MascotPose.quiz,
                            size: MascotSize.small,
                            customHeight: 90,
                            animate: true,
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: _speakCurrentQuestion,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      q.question,
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 19,
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w800,
                                        height: 1.35,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AudioButton(
                                    letter: q.question,
                                    word: q.question,
                                    size: 42,
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    iconColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4 MCQ Answer Choice Options
                    ...List.generate(q.options.length, (idx) {
                      final option = q.options[idx];
                      final isSelected = _selectedAnswerIndex == idx;
                      final isThisCorrect = idx == q.correctIndex;

                      Color bgColor = Colors.white;
                      Color borderColor = AppColors.borderLight;
                      Color textColor = AppColors.textDark;

                      if (_hasAnswered) {
                        if (isThisCorrect) {
                          bgColor = const Color(0xFFD8F3DC);
                          borderColor = AppColors.mintGreen;
                          textColor = const Color(0xFF081C15);
                        } else if (isSelected) {
                          bgColor = const Color(0xFFFFE5E5);
                          borderColor = AppColors.playfulPink;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: _hasAnswered ? () => _audioService.playTamilAudio(option) : () => _onAnswerTap(idx),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: borderColor, width: 2.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: borderColor.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: borderColor.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 18,
                                        color: textColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Kid-friendly audio speaker button to hear option pronunciation
                                  AudioButton(
                                    letter: option,
                                    word: option,
                                    size: 38,
                                    color: _hasAnswered
                                        ? (isThisCorrect
                                            ? AppColors.mintGreen
                                            : (isSelected
                                                ? AppColors.playfulPink
                                                : const Color(0xFFFF9800).withValues(alpha: 0.15)))
                                        : const Color(0xFFFF9800).withValues(alpha: 0.15),
                                    iconColor: _hasAnswered
                                        ? (isThisCorrect || isSelected ? Colors.white : const Color(0xFFE65100))
                                        : const Color(0xFFE65100),
                                  ),
                                  if (_hasAnswered && isThisCorrect) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle_rounded, color: AppColors.mintGreen, size: 28),
                                  ] else if (_hasAnswered && isSelected && !isThisCorrect) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.cancel_rounded, color: AppColors.playfulPink, size: 28),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Immediate Feedback & Next Button
                    if (_hasAnswered) ...[
                      const SizedBox(height: 6),
                      ScaleTransition(
                        scale: _feedbackAnim,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isCorrect ? AppColors.mintGreen : AppColors.primary,
                              width: 2.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                isCorrect ? 'சரியான விடை! மிகச் சிறப்பு!' : 'மீண்டும் முயற்சி செய்யலாம்!',
                                style: AppTextStyles.bodyTextBold.copyWith(
                                  fontSize: 15,
                                  color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                q.explanation,
                                style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BouncyButton(
                        onPressed: _goToNext,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.orangeGradient),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == total - 1 ? 'மதிப்பெண் பார்க்க' : 'அடுத்த வினா',
                                style: AppTextStyles.buttonText,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
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
