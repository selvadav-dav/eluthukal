import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import '../../widgets/star_counter.dart';
import '../language/language_selection_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../writing/writing_practice_screen.dart';

class HomeScreen extends StatelessWidget {
  final ProgressService progressService;
  final Function(int) onTabSelect;

  const HomeScreen({
    super.key,
    required this.progressService,
    required this.onTabSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([progressService, LanguageService.instance]),
      builder: (context, _) {
        final langService = LanguageService.instance;
        final isEn = langService.isEnglish;
        final childName = progressService.childName;
        final stars = progressService.stars;
        final completedLetters = progressService.completedLettersCount;
        final quizScore = progressService.quizHighScore;

        return Scaffold(
          body: KidScaffoldBackground(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top App Bar: Brand Logo & Star Counter & Settings
                        _buildTopHeader(context, stars),
                        const SizedBox(height: 16),

                        // Hero Welcome Card with AGARAM Mascot (welcome.png)
                        _buildMascotHeroCard(childName),
                        const SizedBox(height: 22),

                        // Destinations Title
                        Text(
                          langService.learningWorldsTitle,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Destination 1: Lessons / கற்றுக்கொள்வோம் (Features reading.gif)
                        _buildDestinationCard(
                          title: langService.lessonsHeading,
                          subtitle: isEn
                              ? 'Learn Tamil with joy!'
                              : 'தமிழை மகிழ்ச்சியாக கற்போம்!',
                          tag: isEn
                              ? '12 Vowels • 18 Consonants • 216 Combinations'
                              : '12 உயிர் • 18 மெய் • 216 உயிர்மெய்',
                          imageAsset: 'assets/images/reading.gif',
                          gradient: const [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
                          borderColor: const Color(0xFFFF9F1C),
                          onTap: () => onTabSelect(1),
                        ),
                        const SizedBox(height: 14),

                        // Destination 2: Games / விளையாடிக் கற்போம் (Features play.gif)
                        _buildDestinationCard(
                          title: langService.gamesHeading,
                          subtitle: isEn
                              ? 'Learn Tamil through fun games!'
                              : 'விளையாடி தமிழை கற்போம்!',
                          tag: isEn
                              ? 'Word Car Race • Letter Basket'
                              : 'சொல் கார் பந்தயம் • எழுத்துக் கூடை',
                          imageAsset: 'assets/images/play.gif',
                          gradient: const [Color(0xFF8338EC), Color(0xFF3A86FF)],
                          borderColor: const Color(0xFF8338EC),
                          onTap: () => onTabSelect(2),
                        ),
                        const SizedBox(height: 14),

                        // Destination 3: Videos / காணொளிகள் (Features video.gif)
                        _buildDestinationCard(
                          title: langService.videosHeading,
                          subtitle: isEn
                              ? 'Watch and learn!'
                              : 'பார்த்து கற்றுக்கொள்வோம்!',
                          tag: isEn
                              ? 'Vowels • Consonants • Aytham'
                              : 'உயிர் • மெய் • ஆய்த எழுத்துகள்',
                          imageAsset: 'assets/images/video.gif',
                          gradient: const [Color(0xFF2EC4B6), Color(0xFF0F9F90)],
                          borderColor: const Color(0xFF2EC4B6),
                          onTap: () => onTabSelect(3),
                        ),
                        const SizedBox(height: 14),

                        // Destination 4: Quiz / வினாடி வினா (Features quiz.gif)
                        _buildDestinationCard(
                          title: langService.quizHeading,
                          subtitle: isEn
                              ? 'Test what we learned!'
                              : 'நாம் கற்றதை சோதிப்போம்!',
                          tag: isEn
                              ? '5 Quiz Categories • Badges'
                              : '5 வினாடி வினா பிரிவுகள் • பதக்கங்கள்',
                          imageAsset: 'assets/images/quiz.gif',
                          gradient: const [Color(0xFF4361EE), Color(0xFF4CC9F0)],
                          borderColor: const Color(0xFF4361EE),
                          onTap: () => onTabSelect(4),
                        ),
                        const SizedBox(height: 14),

                        // Destination 5: Writing Practice / எழுதிப் பழகு (Features writing.gif)
                        _buildDestinationCard(
                          title: langService.writingHeading,
                          subtitle: isEn
                              ? 'Practice writing with your finger!'
                              : 'விரலால் எழுதிப் பழகுவோம்!',
                          tag: isEn
                              ? 'Vowels • Consonants • Combined'
                              : 'உயிர் • மெய் • உயிர்மெய் எழுத்துகள்',
                          imageAsset: 'assets/images/writing.gif',
                          gradient: const [Color(0xFFFF006E), Color(0xFFFF70A6)],
                          borderColor: const Color(0xFFFF006E),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WritingPracticeScreen(
                                  progressService: progressService,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 22),

                        // Today's Progress: "இன்றைய முன்னேற்றம்"
                        _buildProgressSection(completedLetters, stars, quizScore),
                        const SizedBox(height: 20),
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

  Widget _buildTopHeader(BuildContext context, int stars) {
    final langService = LanguageService.instance;

    return Row(
      children: [
        // Brand logo
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                langService.brandTitle,
                style: AppTextStyles.brandTitle.copyWith(
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Language Switcher Chip: [ 🇮🇳 தமிழ் ▾ ]
        BouncyButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LanguageSelectionScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3A86FF), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A86FF).withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(langService.currentLanguage.flagEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  langService.currentLanguage.nativeName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF1D4ED8)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Star Counter
        StarCounter(count: stars),
        const SizedBox(width: 8),

        // Profile Button: "என் சுயவிவரம்"
        BouncyButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(progressService: progressService),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF9F1C), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFFFF9F1C), size: 22),
          ),
        ),
        const SizedBox(width: 8),

        // Settings Button
        BouncyButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(progressService: progressService),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.settings_rounded, color: AppColors.textDark, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildMascotHeroCard(String childName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF3CD),
            Color(0xFFFFE5B4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFD166), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 120, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speech Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${LanguageService.instance.greeting} $childName!',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  LanguageService.instance.currentLanguageCode == 'te'
                      ? 'తెలుగు సులభంగా నేర్చుకుందాం!'
                      : (LanguageService.instance.currentLanguageCode == 'en' ? 'Let\'s learn together!' : 'தமிழை எளிதாகக் கற்கலாம் வா!'),
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LanguageService.instance.currentLanguageCode == 'te'
                      ? '“అక్షరాలతో మొదలు, జ్ఞానంతో ముందుకు!”'
                      : (LanguageService.instance.currentLanguageCode == 'en' ? '“Start with letters, soar with knowledge!”' : '“அகரத்தில் தொடங்கி, தமிழில் சிறக்க!”'),
                  style: AppTextStyles.tagLine.copyWith(
                    fontSize: 12.5,
                    color: const Color(0xFF7A4400),
                  ),
                ),
              ],
            ),
          ),

          // AGARAM Mascot (welcome.png) placed prominently
          Positioned(
            right: 8,
            bottom: -6,
            child: const MascotWidget(
              pose: MascotPose.welcome,
              size: MascotSize.medium,
              customHeight: 150,
              showGlow: true,
              animate: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard({
    required String title,
    required String subtitle,
    required String tag,
    required String imageAsset,
    required List<Color> gradient,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor.withValues(alpha: 0.35), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient[0].withValues(alpha: 0.0),
                        gradient[1].withValues(alpha: 0.18),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.star_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTextStyles.cardSubtitle.copyWith(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: gradient[0].withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: gradient[0],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: gradient[0],
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(int lettersCount, int stars, int quizScore) {
    final langService = LanguageService.instance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFE5B4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                langService.todayProgressTitle,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildProgressStat(
                  langService.completedLessonsLabel,
                  '$lettersCount',
                  Icons.auto_stories_rounded,
                  AppColors.secondary,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  langService.starsLabel,
                  '$stars',
                  Icons.star_rounded,
                  AppColors.starGold,
                ),
              ),
              Expanded(
                child: _buildProgressStat(
                  langService.quizScoreLabel,
                  '$quizScore',
                  Icons.emoji_events_rounded,
                  AppColors.candyPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon, Color accent) {
    return Column(
      children: [
        Icon(icon, color: accent, size: 24),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 19,
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
