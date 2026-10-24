import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/uyirmei_data.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../services/tamil_audio_service.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';

class UyirmeiMethod2Screen extends StatefulWidget {
  final ProgressService progressService;

  const UyirmeiMethod2Screen({super.key, required this.progressService});

  @override
  State<UyirmeiMethod2Screen> createState() => _UyirmeiMethod2ScreenState();
}

class _UyirmeiMethod2ScreenState extends State<UyirmeiMethod2Screen> {
  // Currently selected Uyir (vowel) letter. Defaults to 'அ' as in reference diagram.
  String _selectedUyir = 'அ';

  // Scroll controllers for the columns
  final ScrollController _uyirScrollController = ScrollController();
  final ScrollController _tableScrollController = ScrollController();

  // Auto reading sequence state
  bool _isAutoReading = false;
  int _activeRowIndex = -1;
  int _sequenceId = 0;

  // Active equation tooltip from tap
  String? _equationTooltip;

  @override
  void initState() {
    super.initState();
    // Record initial progress for exploring Method 2
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordProgress();
    });
  }

  @override
  void dispose() {
    _sequenceId++;
    _uyirScrollController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  void _recordProgress() {
    final letterId = 'uyirmei_method2_$_selectedUyir';
    if (!widget.progressService.isLetterCompleted(letterId)) {
      widget.progressService.markLetterCompleted(letterId);
    }
  }

  /// When child touches a vowel in Column 1 ("உயிர்")
  Future<void> _onSelectUyir(String uyir) async {
    HapticFeedback.lightImpact();
    if (_isAutoReading) {
      _stopAutoRead();
    }

    setState(() {
      _selectedUyir = uyir;
      _equationTooltip = 'உயிர்: $uyir';
    });

    _recordProgress();

    // Play Uyir pronunciation sound
    await TamilAudioService.instance.playLetterSound(
      context,
      letter: uyir,
      showIndicator: true,
    );
  }

  /// When child touches a Mei letter in Column 2 ("மெய்")
  Future<void> _onSelectMei(String mei, int rowIndex) async {
    HapticFeedback.lightImpact();
    final uyirmei = getUyirmeiLetter(mei, _selectedUyir);

    setState(() {
      _activeRowIndex = rowIndex;
      _equationTooltip = '$mei + $_selectedUyir = $uyirmei';
    });

    await TamilAudioService.instance.playLetterSound(
      context,
      letter: mei,
      showIndicator: true,
    );
  }

  /// When child touches a Uyirmei letter in Column 3 ("உயிர் மெய்")
  Future<void> _onSelectUyirmei(String mei, String uyirmei, int rowIndex) async {
    HapticFeedback.mediumImpact();
    final sample = getSampleWord(uyirmei);

    setState(() {
      _activeRowIndex = rowIndex;
      _equationTooltip = '$mei + $_selectedUyir = $uyirmei ($sample)';
    });

    final letterId = 'uyirmei_${mei}_$_selectedUyir';
    if (!widget.progressService.isLetterCompleted(letterId)) {
      widget.progressService.markLetterCompleted(letterId);
    }

    await TamilAudioService.instance.playLetterSound(
      context,
      letter: uyirmei,
      showIndicator: true,
    );
    if (!mounted) return;
    await TamilAudioService.instance.playStarReward(context);
  }

  /// Plays full equation for a row: Mei + Uyir = Uyirmei
  Future<void> _playRowEquation(String mei, int rowIndex) async {
    HapticFeedback.selectionClick();
    if (_isAutoReading) _stopAutoRead();

    final currentSeq = ++_sequenceId;
    final uyirmei = getUyirmeiLetter(mei, _selectedUyir);

    setState(() {
      _activeRowIndex = rowIndex;
      _equationTooltip = '$mei + $_selectedUyir = $uyirmei';
    });

    // 1. Mei sound
    await TamilAudioService.instance.playLetterSound(context, letter: mei, showIndicator: true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || currentSeq != _sequenceId) return;

    // 2. Plus sound
    await TamilAudioService.instance.playPlusSound(context);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted || currentSeq != _sequenceId) return;

    // 3. Uyir sound
    await TamilAudioService.instance.playLetterSound(context, letter: _selectedUyir, showIndicator: true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || currentSeq != _sequenceId) return;

    // 4. Uyirmei result sound
    await TamilAudioService.instance.playLetterSound(context, letter: uyirmei, showIndicator: true);
    if (!mounted || currentSeq != _sequenceId) return;
    await TamilAudioService.instance.playStarReward(context);
  }

  /// Automatically reads through all 18 rows sequentially for current vowel
  Future<void> _startAutoRead() async {
    HapticFeedback.heavyImpact();
    final currentSeq = ++_sequenceId;

    setState(() {
      _isAutoReading = true;
      _activeRowIndex = 0;
    });

    // Play intro: Selected Uyir sound first
    await TamilAudioService.instance.playLetterSound(context, letter: _selectedUyir, showIndicator: true);
    await Future.delayed(const Duration(milliseconds: 900));

    for (int i = 0; i < uyirmeiGroupBases.length; i++) {
      if (!mounted || currentSeq != _sequenceId || !_isAutoReading) break;

      final mei = uyirmeiGroupBases[i];
      final uyirmei = getUyirmeiLetter(mei, _selectedUyir);

      setState(() {
        _activeRowIndex = i;
        _equationTooltip = '$mei + $_selectedUyir = $uyirmei';
      });

      // Auto scroll to make active row visible
      if (_tableScrollController.hasClients) {
        final targetOffset = (i * 58.0).clamp(0.0, _tableScrollController.position.maxScrollExtent);
        _tableScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      // Read Mei letter
      await TamilAudioService.instance.playLetterSound(context, letter: mei);
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted || currentSeq != _sequenceId || !_isAutoReading) break;

      // Read Uyirmei letter
      await TamilAudioService.instance.playLetterSound(context, letter: uyirmei, showIndicator: true);
      await Future.delayed(const Duration(milliseconds: 900));
    }

    if (mounted && currentSeq == _sequenceId) {
      await TamilAudioService.instance.playStarReward(context);
      setState(() {
        _isAutoReading = false;
        _activeRowIndex = -1;
      });
    }
  }

  void _stopAutoRead() {
    _sequenceId++;
    TamilAudioService.instance.stopAll();
    if (mounted) {
      setState(() {
        _isAutoReading = false;
        _activeRowIndex = -1;
      });
    }
  }

  void _goToNextVowel() {
    final currentIndex = uyirVowelList.indexOf(_selectedUyir);
    final nextIndex = (currentIndex + 1) % uyirVowelList.length;
    _onSelectUyir(uyirVowelList[nextIndex]);
    _ensureUyirVisible(nextIndex);
  }

  void _goToPrevVowel() {
    final currentIndex = uyirVowelList.indexOf(_selectedUyir);
    final prevIndex = (currentIndex - 1 + uyirVowelList.length) % uyirVowelList.length;
    _onSelectUyir(uyirVowelList[prevIndex]);
    _ensureUyirVisible(prevIndex);
  }

  void _ensureUyirVisible(int index) {
    if (_uyirScrollController.hasClients) {
      final target = (index * 52.0).clamp(0.0, _uyirScrollController.position.maxScrollExtent);
      _uyirScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.progressService, LanguageService.instance]),
      builder: (context, _) {
        final isEn = LanguageService.instance.isEnglish;

        return Scaffold(
          appBar: KidAppBar(
            title: isEn ? 'Learning Method 2' : 'கற்றல் முறை 2',
            starCount: widget.progressService.stars,
            showBack: true,
          ),
          body: KidScaffoldBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // 1. Selected Vowel & Formula Bar with Auto Read Controls
                  _buildTopControlsBanner(isEn: isEn),

                  // 2. Main 3-Column Table Notebook matching the reference drawing
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                      child: _buildNotebookTable(isEn: isEn),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Formula banner + Vowel Stepper + Auto Read Button
  Widget _buildTopControlsBanner({required bool isEn}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Prev Vowel Button
          BouncyButton(
            onPressed: _goToPrevVowel,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF334155)),
            ),
          ),

          const SizedBox(width: 8),

          // Active Vowel Badge
          GestureDetector(
            onTap: () => _onSelectUyir(_selectedUyir),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_up_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    _selectedUyir,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Next Vowel Button
          BouncyButton(
            onPressed: _goToNextVowel,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF334155)),
            ),
          ),

          const Spacer(),

          // Formula / Tooltip Text
          if (_equationTooltip != null) ...[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Text(
                  _equationTooltip!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Auto Read All Button
          BouncyButton(
            onPressed: _isAutoReading ? _stopAutoRead : _startAutoRead,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isAutoReading
                      ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                      : const [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_isAutoReading ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                        .withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isAutoReading ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isAutoReading
                        ? (isEn ? 'Stop' : 'நிறுத்து')
                        : (isEn ? 'Read All' : 'வாசி'),
                    style: const TextStyle(
                      fontSize: 12,
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

  /// The Main 3-Column School Table matching the user's sketch:
  /// Column 1: உயிர் (12 vowels)
  /// Divider Line
  /// Column 2: மெய் (18 consonants)
  /// Divider Line
  /// Column 3: உயிர் மெய் (18 combined letters aligned horizontally opposite each Mei letter)
  Widget _buildNotebookTable({required bool isEn}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF93C5FD), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Table Header Bar: [ உயிர் ] | [ மெய் ] | [ உயிர் மெய் ]
            _buildTableHeaderBar(isEn: isEn),

            // Continuous Table Separator Line below Header
            Container(height: 2, color: const Color(0xFF93C5FD)),

            // Table Content: Column 1 on left, synchronized Column 2 & 3 on right
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // COLUMN 1: உயிர் (12 Vowels)
                  _buildUyirColumn(),

                  // Vertical Divider 1 (matching the blue drawn line)
                  Container(
                    width: 2,
                    color: const Color(0xFF93C5FD),
                  ),

                  // COLUMNS 2 & 3: மெய் (18) and உயிர் மெய் (18) aligned row-by-row
                  Expanded(
                    child: _buildMeiAndUyirmeiRows(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header row with 3 column titles separated by vertical divider marks
  Widget _buildTableHeaderBar({required bool isEn}) {
    return Container(
      color: const Color(0xFFF0F9FF),
      height: 48,
      child: Row(
        children: [
          // Header 1: உயிர்
          SizedBox(
            width: 76,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isEn ? 'Uyir (12)' : 'உயிர்',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFBE123C),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider 1
          Container(width: 2, color: const Color(0xFF93C5FD)),

          // Header 2: மெய்
          Expanded(
            flex: 5,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isEn ? 'Mei (18)' : 'மெய்',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0369A1),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider 2
          Container(width: 2, color: const Color(0xFF93C5FD)),

          // Header 3: உயிர் மெய்
          Expanded(
            flex: 6,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isEn ? 'Uyir Mei (18)' : 'உயிர் மெய்',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                      letterSpacing: 0.3,
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

  /// Column 1: Vertical list of 12 Uyir vowels
  /// The selected vowel has a distinct rectangular box around it (matching the photo!)
  Widget _buildUyirColumn() {
    return Container(
      width: 76,
      color: const Color(0xFFFAF5FF),
      child: ListView.separated(
        controller: _uyirScrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: uyirVowelList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final uyir = uyirVowelList[index];
          final isSelected = uyir == _selectedUyir;

          return BouncyButton(
            onPressed: () => _onSelectUyir(uyir),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                // When selected: Boxed with distinct border, mimicking the box drawn around 'அ' in user's image!
                color: isSelected ? const Color(0xFFFCE7F3) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
                  width: isSelected ? 2.5 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  uyir,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected ? const Color(0xFFBE123C) : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Columns 2 and 3: 18 Mei letters paired side-by-side with resulting Uyirmei letters
  /// Row i has: [ Mei Letter ] | [ Uyirmei Letter ]
  /// This guarantees exact horizontal alignment across the dividing line!
  Widget _buildMeiAndUyirmeiRows() {
    return ListView.separated(
      controller: _tableScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: uyirmeiGroupBases.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final mei = uyirmeiGroupBases[index];
        final uyirmei = getUyirmeiLetter(mei, _selectedUyir);
        final isActiveRow = index == _activeRowIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 52,
          decoration: BoxDecoration(
            color: isActiveRow ? const Color(0xFFFEF3C7) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActiveRow ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
              width: isActiveRow ? 2.2 : 1.2,
            ),
            boxShadow: isActiveRow
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Left cell: Mei Letter (e.g. க்)
              Expanded(
                flex: 5,
                child: BouncyButton(
                  onPressed: () => _onSelectMei(mei, index),
                  child: Container(
                    height: double.infinity,
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        mei,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Middle Divider with sound/formula play button
              GestureDetector(
                onTap: () => _playRowEquation(mei, index),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isActiveRow ? const Color(0xFFFDE68A) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),

              // Right cell: Uyirmei Letter (e.g. க when 'அ' is chosen, கா when 'ஆ' is chosen)
              Expanded(
                flex: 6,
                child: BouncyButton(
                  onPressed: () => _onSelectUyirmei(mei, uyirmei, index),
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Text(
                        uyirmei,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
