import 'package:flutter/material.dart';

import '../../models/avatar_model.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../services/tamil_transliteration_service.dart';
import '../../services/writing_practice_repository.dart';
import '../auth/login_screen.dart';
import '../writing/writing_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ProgressService? progressService;

  const ProfileScreen({super.key, this.progressService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final WritingPracticeRepository _repo = LocalWritingPracticeRepository();
  final AuthService _authService = AuthService();
  UserProfile _profile = UserProfile.defaultProfile();
  int _practicedLetters = 0;
  int _totalPractices = 0;
  bool _isLoading = true;

  void _showLogoutDialog() {
    final isEn = LanguageService.instance.isEnglish;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          isEn ? 'Logout of account?' : 'கணக்கிலிருந்து வெளியேறவா?',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          isEn
              ? 'You will need to log in again after logging out.'
              : 'வெளியேறிய பின் மீண்டும் உள்நுழைய வேண்டும்.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'வேண்டாம்'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(
                      authService: _authService,
                      progressService:
                          widget.progressService ?? ProgressService(),
                    ),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(isEn ? 'Logout' : 'வெளியேறு'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await _repo.getUserProfile();
    final practicedCount = await _repo.getPracticedLettersCount();
    final totalCount = await _repo.getTotalPracticesCount();

    if (mounted) {
      setState(() {
        _profile = profile;
        _practicedLetters = practicedCount;
        _totalPractices = totalCount;
        _isLoading = false;
      });
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _profile.name);
    int selectedAge = _profile.age;
    String selectedAvatar = _profile.avatarAsset;
    String liveTamilPreview = TamilTransliterationService.toTamil(
      _profile.name,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'சுயவிவரத்தைத் திருத்து',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avatar Selection (Character Mascot Avatars)
                    const Text(
                      'அவதாரத்தைத் தேர்ந்தெடுங்கள்',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (
                            int index = 0;
                            index < AppAvatar.list.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 32),
                            Builder(
                              builder: (context) {
                                final avatar = AppAvatar.list[index];
                                final isSelected =
                                    selectedAvatar == avatar.assetPath;

                                return GestureDetector(
                                  onTap: () => setModalState(
                                    () => selectedAvatar = avatar.assetPath,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFFF9F1C)
                                                : Colors.transparent,
                                            width: 3.5,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFFFF9F1C,
                                                    ).withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: CircleAvatar(
                                          radius: 34,
                                          backgroundColor: const Color(
                                            0xFFFFF3CD,
                                          ),
                                          backgroundImage: AssetImage(
                                            avatar.assetPath,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        avatar.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFFFF9F1C)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Child's Name
                    const Text(
                      'குழந்தையின் பெயர் (ஆங்கிலத்திலும் தட்டச்சு செய்யலாம்)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          liveTamilPreview =
                              TamilTransliterationService.toTamil(val);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'எ.கா: selva அல்லது செல்வா',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFFFF9F1C),
                        ),
                      ),
                    ),
                    if (liveTamilPreview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF9F1C)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'தமிழ் வடிவம்: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF78350F),
                              ),
                            ),
                            Text(
                              liveTamilPreview,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Child's Age
                    const Text(
                      'வயது',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [3, 4, 5, 6, 7, 8].map((age) {
                          final isSelected = selectedAge == age;
                          return ChoiceChip(
                            label: Text(
                              '$age',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFF9F1C),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (_) =>
                                setModalState(() => selectedAge = age),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06D6A0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () async {
                          final rawName = nameController.text.trim();
                          final convertedName =
                              TamilTransliterationService.toTamil(
                                rawName.isNotEmpty ? rawName : 'குட்டி',
                              );

                          final updated = _profile.copyWith(
                            name: convertedName,
                            age: selectedAge,
                            avatarAsset: selectedAvatar,
                          );
                          await _repo.saveUserProfile(updated);

                          if (widget.progressService != null) {
                            widget.progressService!.updateProfile(
                              name: convertedName,
                              avatarIndex: AppAvatar.getIndex(selectedAvatar),
                              age: selectedAge,
                            );
                          }

                          if (mounted) {
                            setState(() => _profile = updated);
                          }
                          if (modalContext.mounted) {
                            Navigator.pop(modalContext);
                          }
                        },
                        child: const Text(
                          'சேமிக்க',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppBar(
        title: const Text(
          'என் சுயவிவரம்',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Child Avatar & Mascot Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD166), Color(0xFFFF9F1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9F1C)
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: const Color(0xFFE0F2FE),
                            backgroundImage: AssetImage(_profile.avatarAsset),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Child Name (Always in Tamil)
                        Text(
                          _profile.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Child Age
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'வயது: ${_profile.age}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Edit Button
                        ElevatedButton.icon(
                          onPressed: _showEditProfileDialog,
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text(
                            'சுயவிவரத்தைத் திருத்து',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF9F1C),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress & Achievements
                  Row(
                    children: [
                      const Text(
                        'கற்றல் முன்னேற்றம்',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stat Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.stars_rounded,
                          iconColor: const Color(0xFFFFD166),
                          title: 'மொத்த நட்சத்திரங்கள்',
                          value:
                              '${widget.progressService?.stars ?? _profile.totalStars}',
                          bgColor: const Color(0xFFFFFBEB),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.menu_book_rounded,
                          iconColor: const Color(0xFF3A86FF),
                          title: 'கற்ற எழுத்துகள்',
                          value:
                              '${widget.progressService?.completedLettersCount ?? 24}',
                          bgColor: const Color(0xFFEFF6FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.edit_note_rounded,
                          iconColor: const Color(0xFF06D6A0),
                          title: 'எழுதிப் பழகியது',
                          value: '$_practicedLetters எழுத்துகள்',
                          bgColor: const Color(0xFFECFDF5),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.history_rounded,
                          iconColor: const Color(0xFFFF6B6B),
                          title: 'மொத்த பயிற்சிகள்',
                          value: '$_totalPractices முறை',
                          bgColor: const Color(0xFFFFF1F2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Parent Writing History Tile
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3A86FF), Color(0xFF4895EF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3A86FF).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WritingHistoryScreen(),
                            ),
                          ).then((_) => _loadProfileData());
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.history_edu_rounded,
                                  color: Color(0xFF3A86FF),
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'எழுத்துப் பயிற்சி பதிவுகள்',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'பெற்றோருக்கான கையெழுத்துப் பதிவுகள்',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFDBEAFE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF4D4D),
                        backgroundColor: const Color(0xFFFFF0F3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: Color(0xFFFFC5C5),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(
                        LanguageService.instance.isEnglish
                            ? 'Logout'
                            : 'கணக்கிலிருந்து வெளியேறு (Logout)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.2),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
