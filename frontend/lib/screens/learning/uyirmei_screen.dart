import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/uyirmei_data.dart';
import '../../services/progress_service.dart';
import '../../services/tamil_audio_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';

class UyirmeiScreen extends StatefulWidget {
  final ProgressService progressService;

  const UyirmeiScreen({super.key, required this.progressService});

  @override
  State<UyirmeiScreen> createState() => _UyirmeiScreenState();
}

class _UyirmeiScreenState extends State<UyirmeiScreen>
    with TickerProviderStateMixin {
  String _selectedMei = 'க்';
  String _selectedUyir = 'அ';

  // Animation controller for the 3D card flip
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  // Pulse / Celebration animation for resulting letter
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Handwriting / Stroke Drawing Animation Controller
  late AnimationController _writingController;
  late Animation<double> _writingAnimation;

  // Scroll controllers for left and right columns
  final ScrollController _meiScrollController = ScrollController();
  final ScrollController _uyirScrollController = ScrollController();

  bool _isAutoPlaying = false;
  int _activeFormulaStep = 0; // 0: none, 1: Mei, 2: Plus, 3: Uyir, 4: Result
  int _sequenceCounter = 0;

  @override
  void initState() {
    super.initState();

    // 3D Card Flip
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOutBack,
      ),
    );

    // Letter Floating Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Handwriting / Animated Writing Effect
    _writingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _writingAnimation = CurvedAnimation(
      parent: _writingController,
      curve: Curves.easeInOutCubic,
    );

    // Initial state: Card is flipped to show resulting letter 'க' with writing animation
    _flipController.value = 1.0;
    _writingController.forward(from: 0.0);

    // Award progress for starting Uyirmei
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordProgress();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pulseController.dispose();
    _writingController.dispose();
    _meiScrollController.dispose();
    _uyirScrollController.dispose();
    super.dispose();
  }

  String get _currentUyirmei => getUyirmeiLetter(_selectedMei, _selectedUyir);

  bool get _isUorOoSeries => _selectedUyir == 'உ' || _selectedUyir == 'ஊ';

  void _recordProgress() {
    final letterId = 'uyirmei_${_selectedMei}_$_selectedUyir';
    if (!widget.progressService.isLetterCompleted(letterId)) {
      widget.progressService.markLetterCompleted(letterId);
    }
  }

  /// Trigger live animated handwriting of the letter
  void _replayWritingAnimation() {
    HapticFeedback.selectionClick();
    _writingController.forward(from: 0.0);
  }

  /// When child taps a Mei letter on the left
  Future<void> _onSelectMei(String mei) async {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMei = mei;
    });
    _recordProgress();
    await _playFullSequence();
  }

  /// When child taps a Uyir letter on the right
  Future<void> _onSelectUyir(String uyir) async {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedUyir = uyir;
    });
    _recordProgress();
    await _playFullSequence();
  }

  /// Plays sequential letter sound breakdown:
  /// Audio 1: க் (Mei)
  /// Audio 2: + (கூட்டல்)
  /// Audio 3: அ (Uyir)
  /// -> Smooth flip to result card -> Audio 4: க (Uyirmei) with handwriting animation & star reward
  Future<void> _playFullSequence() async {
    final int currentSeq = ++_sequenceCounter;
    await TamilAudioService.instance.stopAll();

    setState(() {
      _isAutoPlaying = true;
      _activeFormulaStep = 0;
    });

    try {
      // Step 1: Smoothly flip to equation side if currently showing result
      if (_flipController.value > 0.0) {
        await _flipController.reverse();
        await Future.delayed(const Duration(milliseconds: 180));
      }
      if (!mounted || currentSeq != _sequenceCounter) return;

      // Audio 1: Play Mei sound (e.g. க்)
      setState(() => _activeFormulaStep = 1);
      await TamilAudioService.instance.playLetterSound(
        context,
        letter: _selectedMei,
        showIndicator: true,
      );
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted || currentSeq != _sequenceCounter) return;

      // Audio 2: Play Plus sound ('+' / 'கூட்டல்')
      setState(() => _activeFormulaStep = 2);
      await TamilAudioService.instance.playPlusSound(context);
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted || currentSeq != _sequenceCounter) return;

      // Audio 3: Play Uyir sound (e.g. அ)
      setState(() => _activeFormulaStep = 3);
      await TamilAudioService.instance.playLetterSound(
        context,
        letter: _selectedUyir,
        showIndicator: true,
      );
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted || currentSeq != _sequenceCounter) return;

      // Step 2: Smoothly flip to result side and animate handwriting
      setState(() => _activeFormulaStep = 4);
      _writingController.forward(from: 0.0);
      await _flipController.forward();
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || currentSeq != _sequenceCounter) return;

      // Audio 4: Play result letter sound (e.g. க)
      await TamilAudioService.instance.playLetterSound(
        context,
        letter: _currentUyirmei,
        showIndicator: true,
      );
      if (!mounted || currentSeq != _sequenceCounter) return;
      await TamilAudioService.instance.playStarReward(context);
    } finally {
      if (mounted && currentSeq == _sequenceCounter) {
        setState(() {
          _isAutoPlaying = false;
          _activeFormulaStep = 0;
        });
      }
    }
  }

  /// Toggles flip / replays full sequence when tapping the center card
  void _toggleFlipCard() {
    HapticFeedback.selectionClick();
    _playFullSequence();
  }

  void _goToNextVowel() {
    final currentIndex = uyirVowelList.indexOf(_selectedUyir);
    final nextIndex = (currentIndex + 1) % uyirVowelList.length;
    _onSelectUyir(uyirVowelList[nextIndex]);
  }

  void _goToPrevVowel() {
    final currentIndex = uyirVowelList.indexOf(_selectedUyir);
    final prevIndex =
        (currentIndex - 1 + uyirVowelList.length) % uyirVowelList.length;
    _onSelectUyir(uyirVowelList[prevIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KidAppBar(
        title: 'உயிர்மெய் எழுத்துகள்',
        starCount: widget.progressService.stars,
      ),
      body: KidScaffoldBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Formula Bar
              _buildTopFormulaBanner(),

              // Main 3-Column Interactive Layout
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT COLUMN: Mei Letters (18)
                      _buildMeiColumn(),

                      const SizedBox(width: 8),

                      // CENTER COLUMN: The Magic Flip Card & Animated Writing Area
                      Expanded(
                        child: _buildCenterInteractiveArea(),
                      ),

                      const SizedBox(width: 8),

                      // RIGHT COLUMN: Uyir Letters (12)
                      _buildUyirColumn(),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation & Actions Bar (Responsive - No Overflow)
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Top formula banner showing: மெய் + உயிர் = உயிர்மெய்
  Widget _buildTopFormulaBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                TamilAudioService.instance.playLetterSound(context, letter: _selectedMei, showIndicator: true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.meiColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'மெய்',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.meiColor,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                TamilAudioService.instance.playPlusSound(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8338EC).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8338EC),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                TamilAudioService.instance.playLetterSound(context, letter: _selectedUyir, showIndicator: true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.uyirColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'உயிர்',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.uyirColor,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('➔', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.greenGradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'உயிர்மெய்',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Left Column: 18 Mei Letters (க், ங், ச் ...)
  Widget _buildMeiColumn() {
    return SizedBox(
      width: 66,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.meiColor.withValues(alpha: 0.25), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.meiColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Column Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.meiColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.stars_rounded, size: 14, color: AppColors.meiColor),
                  SizedBox(height: 1),
                  Text(
                    'மெய் (18)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.meiColor,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable list of 18 Mei letters
            Expanded(
              child: ListView.builder(
                controller: _meiScrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                itemCount: uyirmeiGroupBases.length,
                itemBuilder: (context, index) {
                  final mei = uyirmeiGroupBases[index];
                  final isSelected = _selectedMei == mei;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: BouncyButton(
                      onPressed: () => _onSelectMei(mei),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF4361EE), Color(0xFF4CC9F0)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.meiColor.withValues(alpha: 0.3),
                            width: isSelected ? 0 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppColors.meiColor.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            mei,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Right Column: 12 Uyir Letters (அ, ஆ, இ ...)
  Widget _buildUyirColumn() {
    return SizedBox(
      width: 66,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.uyirColor.withValues(alpha: 0.25), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.uyirColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Column Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.uyirColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.stars_rounded, size: 14, color: AppColors.uyirColor),
                  SizedBox(height: 1),
                  Text(
                    'உயிர் (12)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.uyirColor,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable list of 12 Uyir letters
            Expanded(
              child: ListView.builder(
                controller: _uyirScrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                itemCount: uyirVowelList.length,
                itemBuilder: (context, index) {
                  final uyir = uyirVowelList[index];
                  final isSelected = _selectedUyir == uyir;
                  final isSpecialU = uyir == 'உ' || uyir == 'ஊ';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: BouncyButton(
                      onPressed: () => _onSelectUyir(uyir),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? (isSpecialU
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF007F), Color(0xFFFF9F1C)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFFFF6B6B), Color(0xFFFF9F1C)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ))
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isSpecialU
                                    ? const Color(0xFFFF007F).withValues(alpha: 0.45)
                                    : AppColors.uyirColor.withValues(alpha: 0.3)),
                            width: isSelected ? 0 : (isSpecialU ? 2.0 : 1.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? (isSpecialU
                                      ? const Color(0xFFFF007F).withValues(alpha: 0.45)
                                      : AppColors.uyirColor.withValues(alpha: 0.4))
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            uyir,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? Colors.white
                                  : (isSpecialU
                                      ? const Color(0xFFD81159)
                                      : AppColors.textDark),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Center Column: The Magic 3D Flip Card & Animated Writing Area
  Widget _buildCenterInteractiveArea() {
    return Column(
      children: [
        // Live Equation Tag at Top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isUorOoSeries
                  ? const Color(0xFFFF007F).withValues(alpha: 0.4)
                  : AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isUorOoSeries
                    ? const Color(0xFFFF007F).withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.04),
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
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    TamilAudioService.instance.playLetterSound(context, letter: _selectedMei, showIndicator: true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _activeFormulaStep == 1 ? AppColors.meiColor.withValues(alpha: 0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_selectedMei ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _activeFormulaStep == 1 ? const Color(0xFF2563EB) : AppColors.meiColor,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    TamilAudioService.instance.playPlusSound(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _activeFormulaStep == 2 ? const Color(0xFF8338EC) : const Color(0xFF8338EC).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _activeFormulaStep == 2 ? Colors.white : const Color(0xFF8338EC),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    TamilAudioService.instance.playLetterSound(context, letter: _selectedUyir, showIndicator: true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _activeFormulaStep == 3 ? AppColors.uyirColor.withValues(alpha: 0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ' $_selectedUyir ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _activeFormulaStep == 3
                            ? const Color(0xFFEA580C)
                            : (_isUorOoSeries ? const Color(0xFFFF007F) : AppColors.uyirColor),
                      ),
                    ),
                  ),
                ),
                const Text('= ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    TamilAudioService.instance.playLetterSound(context, letter: _currentUyirmei, showIndicator: true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _activeFormulaStep == 4 ? AppColors.secondaryDark.withValues(alpha: 0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _currentUyirmei,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _activeFormulaStep == 4
                            ? const Color(0xFF059669)
                            : (_isUorOoSeries ? const Color(0xFFD81159) : AppColors.secondaryDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // The 3D Flip Card
        Expanded(
          child: GestureDetector(
            onTap: _toggleFlipCard,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                // Compute 3D rotation angle
                final angle = _flipAnimation.value * math.pi;
                final isUnder = angle > (math.pi / 2);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0018) // Realistic 3D perspective
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: isUnder
                      ? Transform(
                          // Invert back card so it doesn't show mirrored
                          transform: Matrix4.identity()..rotateY(math.pi),
                          alignment: Alignment.center,
                          child: _buildResultCardBack(),
                        )
                      : _buildFormulaCardFront(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Front of Card: Formula View ( [க்] + [அ] )
  Widget _buildFormulaCardFront() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFC4B5FD), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Title Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF7C3AED)),
                SizedBox(width: 4),
                Text(
                  'சேர்க்கை',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),

          // Big Formula Row: [க்] + [அ]
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mei Box
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    TamilAudioService.instance.playLetterSound(
                      context,
                      letter: _selectedMei,
                      showIndicator: true,
                    );
                  },
                  child: AnimatedScale(
                    scale: _activeFormulaStep == 1 ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4361EE), Color(0xFF4CC9F0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeFormulaStep == 1 ? const Color(0xFFFFD166) : Colors.white.withValues(alpha: 0.3),
                          width: _activeFormulaStep == 1 ? 3.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_activeFormulaStep == 1 ? const Color(0xFFFFD166) : AppColors.meiColor).withValues(alpha: 0.45),
                            blurRadius: _activeFormulaStep == 1 ? 14 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _selectedMei,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Plus (+) Button with Audio
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    TamilAudioService.instance.playPlusSound(context);
                  },
                  child: AnimatedScale(
                    scale: _activeFormulaStep == 2 ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: _activeFormulaStep == 2
                            ? const LinearGradient(
                                colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFEDE9FE)],
                              ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _activeFormulaStep == 2
                              ? const Color(0xFFFFD166)
                              : const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                          width: _activeFormulaStep == 2 ? 3.0 : 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_activeFormulaStep == 2
                                    ? const Color(0xFF8338EC)
                                    : const Color(0xFF7C3AED))
                                .withValues(alpha: _activeFormulaStep == 2 ? 0.5 : 0.18),
                            blurRadius: _activeFormulaStep == 2 ? 14 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 26,
                        color: _activeFormulaStep == 2 ? Colors.white : const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),

                // Uyir Box (Special highlight if 'உ' or 'ஊ')
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    TamilAudioService.instance.playLetterSound(
                      context,
                      letter: _selectedUyir,
                      showIndicator: true,
                    );
                  },
                  child: AnimatedScale(
                    scale: _activeFormulaStep == 3 ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: _isUorOoSeries
                            ? const LinearGradient(
                                colors: [Color(0xFFFF007F), Color(0xFFFF9F1C)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF9F1C)],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeFormulaStep == 3 ? const Color(0xFFFFD166) : Colors.white.withValues(alpha: 0.3),
                          width: _activeFormulaStep == 3 ? 3.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_activeFormulaStep == 3
                                    ? const Color(0xFFFFD166)
                                    : (_isUorOoSeries ? const Color(0xFFFF007F) : AppColors.uyirColor))
                                .withValues(alpha: 0.45),
                            blurRadius: _activeFormulaStep == 3 ? 14 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _selectedUyir,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Flip / Play full sequence button
          BouncyButton(
            onPressed: _playFullSequence,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8338EC).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'முழு ஒலி கேட்க ▶',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Back of Card: Animated Handwriting of Resulting Uyirmei Letter
  Widget _buildResultCardBack() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: _isUorOoSeries
              ? const LinearGradient(
                  colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E6), Color(0xFFFFF7ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFDCEDC8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isUorOoSeries
                ? const Color(0xFFFF4D8D)
                : const Color(0xFF66BB6A),
            width: 2.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (_isUorOoSeries
                      ? const Color(0xFFFF007F)
                      : const Color(0xFF2E7D32))
                  .withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Top Badge: Equation info (tappable for full pronunciation)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _playFullSequence();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isUorOoSeries
                        ? const Color(0xFFFF4D8D).withValues(alpha: 0.3)
                        : const Color(0xFF66BB6A).withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                      const Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFF8338EC)),
                      const SizedBox(width: 5),
                      Text(
                        '$_selectedMei + $_selectedUyir = $_currentUyirmei',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _isUorOoSeries
                              ? const Color(0xFFD81159)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Animated Handwriting Display of Uyirmei Letter
            _buildAnimatedWritingLetterArea(),

            // Prominent Centered Play Button in Card
            _buildCardCenterPlayButton(),
          ],
        ),
      ),
    );
  }

  /// Prominent Play Button centered in the card
  Widget _buildCardCenterPlayButton() {
    final isSpecial = _isUorOoSeries;
    return BouncyButton(
      onPressed: _playFullSequence,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          gradient: _isAutoPlaying
              ? const LinearGradient(
                  colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                )
              : (isSpecial
                  ? const LinearGradient(
                      colors: [Color(0xFFFF007F), Color(0xFFFF7A00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: (_isAutoPlaying
                      ? Colors.grey
                      : (isSpecial ? const Color(0xFFFF007F) : const Color(0xFF8338EC)))
                  .withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAutoPlaying) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ஒலி கேட்கிறது...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: isSpecial
                        ? const Color(0xFFFF007F)
                        : const Color(0xFF8338EC),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'முழு ஒலி கேட்க ▶',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Magical Handwriting Animated Display
  /// Live pencil tracing + stroke reveal + tailored dual-color for 'உ' / 'ஊ' curl
  Widget _buildAnimatedWritingLetterArea() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _replayWritingAnimation();
        _playFullSequence();
      },
      child: AnimatedBuilder(
        animation: _writingAnimation,
        builder: (context, child) {
          final progress = _writingAnimation.value;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Adaptive White Capsule Card
              Container(
                constraints: const BoxConstraints(minWidth: 86, minHeight: 82),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: _isUorOoSeries
                        ? const Color(0xFFFF007F).withValues(alpha: 0.35)
                        : const Color(0xFF81C784).withValues(alpha: 0.35),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isUorOoSeries
                              ? const Color(0xFFFF007F)
                              : const Color(0xFF43A047))
                          .withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) {
                      if (_isUorOoSeries) {
                        // Precise Dual-Color Highlighting for 'உ' and 'ஊ':
                        // Top base consonant: Dark Emerald Green (#1B5E20)
                        // The entire bottom loop, curl, and tail: Vibrant Bright Hot Pink (#FF007F)
                        return const LinearGradient(
                          colors: [
                            Color(0xFF1B5E20), // Top base consonant (Dark Green)
                            Color(0xFF1B5E20),
                            Color(0xFFFF007F), // The entire bottom loop / swirl stroke (Hot Pink)
                            Color(0xFFFF007F),
                          ],
                          stops: [0.0, 0.34, 0.46, 1.0],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds);
                      } else {
                        // Standard vibrant green/teal gradient for other letters
                        return const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF00796B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds);
                      }
                    },
                    child: ClipRect(
                      clipper: _WritingProgressClipper(progress: progress),
                      child: Text(
                        _currentUyirmei,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Animated Pencil / Sparkle writing pointer that follows the write head
              if (progress < 1.0 && progress > 0.02)
                Positioned(
                  right: 18 + (1.0 - progress) * 60,
                  bottom: 12 + math.sin(progress * math.pi * 3) * 16,
                  child: Transform.rotate(
                    angle: -0.3 + math.sin(progress * math.pi * 4) * 0.2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isUorOoSeries
                                    ? const Color(0xFFFF007F)
                                    : const Color(0xFFFFD166))
                                .withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),

              // Replay writing tip icon when fully written
              if (progress >= 1.0)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isUorOoSeries
                            ? const Color(0xFFFF007F)
                            : AppColors.secondary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Bottom Interactive Action Bar (Responsive - No render overflow on any screen)
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      child: Row(
        children: [
          // Previous Uyir Button
          Expanded(
            flex: 3,
            child: BouncyButton(
              onPressed: _goToPrevVowel,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios_rounded, size: 13, color: AppColors.textDark),
                      SizedBox(width: 3),
                      Text(
                        'முந்தையது',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Big Sound Replay Button (plays full form audio sequence)
          Expanded(
            flex: 4,
            child: BouncyButton(
              onPressed: _playFullSequence,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  gradient: _isUorOoSeries
                      ? const LinearGradient(
                          colors: [Color(0xFFFF007F), Color(0xFFFF9F1C)],
                        )
                      : const LinearGradient(colors: AppColors.orangeGradient),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (_isUorOoSeries
                              ? const Color(0xFFFF007F)
                              : AppColors.primary)
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        _isAutoPlaying ? 'ஒலி கேட்கிறது...' : 'ஒலி கேட்க',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Next Uyir Button
          Expanded(
            flex: 3,
            child: BouncyButton(
              onPressed: _goToNextVowel,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'அடுத்தது',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Clipper that dynamically reveals the letter as it is being written
class _WritingProgressClipper extends CustomClipper<Rect> {
  final double progress;

  _WritingProgressClipper({required this.progress});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress.clamp(0.0, 1.0), size.height);
  }

  @override
  bool shouldReclip(_WritingProgressClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
