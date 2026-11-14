import 'package:flutter/material.dart';
import '../../data/writing_data.dart';
import '../../models/handwriting_ml_model.dart';
import '../../models/writing_practice_model.dart';
import '../../services/audio_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../services/writing_practice_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/audio_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/letter_navigator.dart';
import '../../widgets/star_counter.dart';
import '../../widgets/writing_canvas.dart';
import 'writing_history_screen.dart';

class WritingPracticeScreen extends StatefulWidget {
  final ProgressService progressService;
  final String? initialLetter;

  const WritingPracticeScreen({
    super.key,
    required this.progressService,
    this.initialLetter,
  });

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  final GlobalKey<WritingCanvasState> _canvasKey = GlobalKey<WritingCanvasState>();
  final WritingPracticeRepository _repo = LocalWritingPracticeRepository();

  int _selectedCategoryIndex = 0; // 0: Uyir / Achulu, 1: Mei / Hallulu
  int _letterIndex = 0;
  final WritingCanvasMode _activeMode = WritingCanvasMode.learn; // learn
  final Color _activeColor = const Color(0xFF3A86FF);
  bool _isCanvasDrawing = false;
  final Set<String> _awardedLetters = {};



  List<WritingLetterGuide> get _currentList {
    if (_selectedCategoryIndex == 1) return WritingData.meiGuides;
    if (_selectedCategoryIndex == 2) return WritingData.ayuthamGuides;
    return WritingData.uyirGuides;
  }

  WritingLetterGuide get _currentGuide => _currentList[_letterIndex];

  String get _currentCategoryCode {
    if (_selectedCategoryIndex == 1) return 'mei';
    if (_selectedCategoryIndex == 2) return 'ayutham';
    return 'uyir';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLetter != null) {
      final idx = WritingData.uyirGuides.indexWhere((g) => g.letter == widget.initialLetter);
      if (idx >= 0) {
        _selectedCategoryIndex = 0;
        _letterIndex = idx;
      } else {
        final meiIdx = WritingData.meiGuides.indexWhere((g) => g.letter == widget.initialLetter);
        if (meiIdx >= 0) {
          _selectedCategoryIndex = 1;
          _letterIndex = meiIdx;
        } else {
          final ayuthaIdx = WritingData.ayuthamGuides.indexWhere((g) => g.letter == widget.initialLetter);
          if (ayuthaIdx >= 0) {
            _selectedCategoryIndex = 2;
            _letterIndex = ayuthaIdx;
          }
        }
      }
    }
  }

  /// Automatically saves the current writing practice if meaningful strokes exist.
  Future<void> _autoSaveCurrentPractice({bool completed = true}) async {
    final canvasState = _canvasKey.currentState;
    if (canvasState == null) return;

    final strokes = canvasState.getNormalizedStrokes();
    final totalPoints = canvasState.totalPointsDrawn;

    // Only save if meaningful strokes were drawn (at least 4 points)
    if (strokes.isEmpty || totalPoints < 4) return;

    final letter = _currentGuide.letter;
    final pastCount = await _repo.getAttemptCountForLetter(letter);

    final practice = WritingPractice(
      id: '${letter}_${DateTime.now().millisecondsSinceEpoch}',
      letter: letter,
      category: _currentCategoryCode,
      strokes: strokes,
      createdAt: DateTime.now(),
      attemptNumber: pastCount + 1,
      completed: completed,
    );

    await _repo.savePractice(practice);
  }

  Future<void> _switchCategory(int index) async {
    if (_selectedCategoryIndex == index) return;
    await _autoSaveCurrentPractice(completed: false);
    setState(() {
      _selectedCategoryIndex = index;
      _letterIndex = 0;
    });
    _canvasKey.currentState?.clearCanvas();
  }

  Future<void> _goToPrevious() async {
    if (_letterIndex > 0) {
      await _autoSaveCurrentPractice(completed: false);
      setState(() => _letterIndex--);
      _canvasKey.currentState?.clearCanvas();
    }
  }

  Future<void> _goToNext() async {
    if (_letterIndex < _currentList.length - 1) {
      await _autoSaveCurrentPractice(completed: false);
      setState(() => _letterIndex++);
      _canvasKey.currentState?.clearCanvas();
    }
  }

  /// Handles "சரிபார் / முடித்தேன்" using the AI Model recognition
  /// [guidedComplete] is true when Learn mode finished every step and each stroke
  /// already passed the start/direction/path/end check in the canvas.
  Future<void> _handleFinishWriting({bool guidedComplete = false}) async {
    final canvasState = _canvasKey.currentState;
    final hasDrawn = canvasState?.hasContent ?? false;

    if (!hasDrawn || (canvasState?.totalPointsDrawn ?? 0) < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF9F1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'விரலால் எழுதிப் பாருங்கள்!',
            style: TextStyle(
              fontFamily: 'Catamaran',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
      return;
    }

    // Learn mode: every stroke was already verified against the stroke guide, so the
    // letter is correct. The ML model is not trained on these guided strokes and must
    // not overrule that. Practice mode (free writing) still uses ML recognition.
    final HandwritingRecognitionResult mlResult = guidedComplete
        ? HandwritingRecognitionResult(
            expectedCharacter: _currentGuide.letter,
            recognizedCharacter: _currentGuide.letter,
            confidence: 1.0,
            strokeCount: canvasState!.strokeCount,
            totalPointCount: canvasState.totalPointsDrawn,
            modelStatus: MLModelStatus.loaded,
            isMatchExplicit: true,
          )
        : await canvasState!.evaluateWithML();

    if (mlResult.isMatch) {
      // Auto-save this successful practice
      await _autoSaveCurrentPractice(completed: true);

      final currentLetter = _currentGuide.letter;
      final starsToAdd = mlResult.stars > 0 ? mlResult.stars : 1;

      if (!_awardedLetters.contains(currentLetter)) {
        _awardedLetters.add(currentLetter);
        widget.progressService.addStars(starsToAdd);
        widget.progressService.markLetterCompleted(currentLetter);
      }

      if (!mounted) return;
      await AudioService.instance.playSuccessFeedback(context);

      if (!mounted) return;
      _showAccuracyResultDialog(mlResult, isSuccess: true);
    } else {
      // Encouraging retry / feedback modal
      if (!mounted) return;
      await AudioService.instance.playRetryFeedback(context);

      if (!mounted) return;
      _showAccuracyResultDialog(mlResult, isSuccess: false);
    }
  }

  /// Displays interactive feedback dialog
  void _showAccuracyResultDialog(HandwritingRecognitionResult result, {required bool isSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final String badgeText = isSuccess ? 'சரியானது' : 'முயற்சி செய்க';

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFFFB703),
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSuccess ? const Color(0xFF10B981) : const Color(0xFFFFB703))
                      .withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Letter with Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSuccess
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFFFF9F1C), const Color(0xFFFF6B6B)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _currentGuide.letter,
                        style: const TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: result.badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: result.badgeColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                            color: result.badgeColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: 'Catamaran',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: result.badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Star rating row if success
                if (isSuccess && result.stars > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (idx) {
                        final filled = idx < result.stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Icon(
                            Icons.star_rounded,
                            color: filled ? const Color(0xFFFFC107) : const Color(0xFFE2E8F0),
                            size: 42,
                          ),
                        );
                      }),
                    ),
                  ),

                // Title
                Text(
                  result.feedbackTitle,
                  style: const TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // Subtitle / Feedback message
                Text(
                  result.feedbackMessage,
                  style: const TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Action Buttons
                if (isSuccess) ...[
                  // Primary Next Button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2EC4B6), Color(0xFF0F9F90)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2EC4B6).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (_letterIndex < _currentList.length - 1) {
                            _goToNext();
                          } else {
                            _canvasKey.currentState?.clearCanvas();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: const Text(
                          'அடுத்த எழுத்து',
                          style: TextStyle(
                            fontFamily: 'Catamaran',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Secondary Retry Button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _canvasKey.currentState?.clearCanvas();
                    },
                    icon: const Icon(Icons.replay_rounded, color: Color(0xFF3A86FF), size: 18),
                    label: const Text(
                      'மீண்டும் இதே எழுத்தை எழுத',
                      style: TextStyle(
                        fontFamily: 'Catamaran',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A86FF),
                      ),
                    ),
                  ),
                ] else ...[
                  // Try Again Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _canvasKey.currentState?.clearCanvas();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9F1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      label: const Text(
                        'மீண்டும் எழுதவும்',
                        style: TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = _currentGuide;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _autoSaveCurrentPractice(completed: false);
        }
      },
      child: Scaffold(
        body: KidScaffoldBackground(
          child: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // Top Action Header
                    _buildTopHeader(context),

                    // Category Switcher Pill Tabs: [உயிர் (12)] & [மெய் (18)]
                    _buildCategorySwitcher(),

                    // Writing Area and Controls
                    Expanded(
                      child: SingleChildScrollView(
                        physics: _isCanvasDrawing
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Column(
                          children: [
                            // Letter Navigator Bar (< அ >)
                            LetterNavigator(
                              currentLetter: guide.letter,
                              currentIndex: _letterIndex,
                              totalCount: _currentList.length,
                              onPrevious: _goToPrevious,
                              onNext: _goToNext,
                            ),
                            const SizedBox(height: 8),

                            // Mode Header: [ கற்றுக்கொள் ]
                            _buildModeSelector(),
                            const SizedBox(height: 12),

                            // Writing Canvas (Learn Mode)
                            AspectRatio(
                              aspectRatio: 1.05,
                              child: WritingCanvas(
                                key: _canvasKey,
                                letter: guide.letter,
                                mode: _activeMode,
                                strokeColor: _activeColor,
                                strokeWidth: 20.0,
                                onStrokeUpdated: (_) {},
                                onLetterCompleted: () {
                                  _handleFinishWriting(guidedComplete: true);
                                },
                                onDrawingStateChanged: (drawing) {
                                  if (_isCanvasDrawing != drawing && mounted) {
                                    setState(() => _isCanvasDrawing = drawing);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Bottom Control Buttons: [ மீண்டும் எழுது ] & [ சரிபார் / முடித்தேன் ]
                            _buildBottomControls(),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                _autoSaveCurrentPractice(completed: false);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD166), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 6),
                  Text(
                    LanguageService.instance.writingHeading,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
          ),

          // Audio Pronunciation Button
          AudioButton(
            letter: _currentGuide.letter,
            word: _currentGuide.sampleWord,
            size: 40,
            color: const Color(0xFFFF9F1C),
          ),
          const SizedBox(width: 8),

          // History Screen Link Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _autoSaveCurrentPractice(completed: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WritingHistoryScreen(
                      initialLetter: _currentGuide.letter,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF3A86FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history_edu_rounded,
                  color: Color(0xFF3A86FF),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Star Counter
          ListenableBuilder(
            listenable: widget.progressService,
            builder: (context, _) => StarCounter(count: widget.progressService.stars),
          ),
        ],
      ),
    );
  }

  /// Category Switcher
  Widget _buildCategorySwitcher() {
    final langService = LanguageService.instance;
    final categories = langService.isEnglish
        ? ['Vowels (12)', 'Consonants (18)', 'Aytham (1)']
        : ['உயிர் (12)', 'மெய் (18)', 'ஆய்தம் (1)'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD166), width: 2),
        ),
        child: Row(
          children: List.generate(categories.length, (idx) {
            final isSelected = _selectedCategoryIndex == idx;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchCategory(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      categories[idx],
                      style: TextStyle(
                        fontFamily: 'Catamaran',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Mode Header: [ கற்றுக்கொள் ]
  Widget _buildModeSelector() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF3A86FF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3A86FF).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              LanguageService.instance.isEnglish ? 'Learn' : 'கற்றுக்கொள்',
              style: const TextStyle(
                fontFamily: 'Catamaran',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomControls() {
    final isEn = LanguageService.instance.isEnglish;
    return Row(
      children: [
        // Clear / Reset Button: "மீண்டும் எழுது"
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: () => _canvasKey.currentState?.clearCanvas(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8F9FA),
              foregroundColor: const Color(0xFF495057),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFCED4DA), width: 2),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isEn ? 'Retry' : 'மீண்டும் எழுது',
                style: const TextStyle(
                  fontFamily: 'Catamaran',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Check & Submit Button: "சரிபார் (Check) ⭐"
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: _activeMode == WritingCanvasMode.practice
                    ? [const Color(0xFF2EC4B6), const Color(0xFF0F9F90)]
                    : [const Color(0xFF3A86FF), const Color(0xFF0056D2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_activeMode == WritingCanvasMode.practice
                          ? const Color(0xFF2EC4B6)
                          : const Color(0xFF3A86FF))
                      .withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _handleFinishWriting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isEn ? 'Check' : 'சரிபார்',
                  style: const TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
