import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isInitialSetup;
  final VoidCallback? onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    this.isInitialSetup = false,
    this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = LanguageService.instance.currentLanguageCode;
  }

  void _onSelect(String code) {
    setState(() {
      _selectedCode = code;
    });
  }

  Future<void> _onConfirm() async {
    await LanguageService.instance.setLanguage(_selectedCode);
    if (widget.onLanguageSelected != null) {
      widget.onLanguageSelected!();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languages = LanguageService.supportedLanguages.values.toList();

    return Scaffold(
      body: KidScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Top Header / Close if not initial
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!widget.isInitialSetup)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      else
                        const SizedBox(width: 48),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.translate_rounded, color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Language / மொழி',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Mascot Hero
                  const MascotWidget(
                    pose: MascotPose.welcome,
                    size: MascotSize.medium,
                    showGlow: true,
                  ),
                  const SizedBox(height: 12),

                  // Title & Subtitle
                  Text(
                    'உங்கள் மொழியைத் தேர்வு செய்க',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle.copyWith(
                      fontSize: 22,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose your language',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Language Option Cards
                  Expanded(
                    flex: 6,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: languages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        final isSelected = _selectedCode == lang.code;

                        return BouncyButton(
                          onPressed: () => _onSelect(lang.code),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                width: isSelected ? 3.0 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.20)
                                      : Colors.black.withValues(alpha: 0.04),
                                  blurRadius: isSelected ? 12 : 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Flag icon circle
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    lang.flagEmoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Native Name & English Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.nativeName,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: isSelected ? AppColors.primary : AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        '${lang.name} • ${lang.brandTitle}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Checkmark radio
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Confirm / Continue Button
                  BouncyButton(
                    onPressed: _onConfirm,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9F1C), Color(0xFFFF5400)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5400).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedCode == 'en' ? 'Continue 🚀' : 'தொடரவும் (Continue) 🚀',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
