import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import 'aytham_screen.dart';
import 'mei_screen.dart';
import '../reading/reading_screen.dart';
import 'uyir_screen.dart';
import 'uyirmei_screen.dart';

class LearningScreen extends StatelessWidget {
  final ProgressService progressService;

  const LearningScreen({super.key, required this.progressService});

  void _navigateToCategory(BuildContext context, String routeName) {
    Widget target;
    switch (routeName) {
      case '/uyir':
        target = UyirScreen(progressService: progressService);
        break;
      case '/mei':
        target = MeiScreen(progressService: progressService);
        break;
      case '/aytham':
        target = AythamScreen(progressService: progressService);
        break;
      case '/uyirmei':
        target = UyirmeiScreen(progressService: progressService);
        break;
      case '/reading':
        target = ReadingScreen(progressService: progressService);
        break;
      default:
        target = UyirScreen(progressService: progressService);
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => target));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([progressService, LanguageService.instance]),
      builder: (context, _) {
        final completedCount = progressService.completedLettersCount;
        final langService = LanguageService.instance;
        final isEn = langService.isEnglish;
        final isTe = langService.isTelugu;

        return Scaffold(
          appBar: KidAppBar(
            title: langService.lessonsHeading,
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
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                    children: [
                      // Top Hero Mascot Card (learn.png - child reading book)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF81C784), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mintGreen.withValues(alpha: 0.2),
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.school_rounded, color: Color(0xFF2E7D32), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          isTe ? 'పాఠశాల' : (isEn ? 'School' : 'பாடசாலை'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isTe
                                        ? 'తెలుగు సులభంగా చదువుదాం!'
                                        : (isEn ? 'Learn Tamil easily together!' : 'தமிழை எளிதாகப் படிப்போம்!'),
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 18,
                                      color: const Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isTe
                                        ? 'పూర్తయిన పాఠాలు: $completedCount'
                                        : (isEn ? 'Completed lessons: $completedCount' : 'கற்ற பாடங்கள்: $completedCount'),
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
                              customHeight: 110,
                              showGlow: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. Vowels Category (உயிர் எழுத்துகள் / அచ్చులు)
                      _buildCategoryCard(
                        context,
                        title: langService.vowelsTitle,
                        subtitle: isTe
                            ? 'అ నుండి అః వరకు మధురంగా నేర్చుకుందాం'
                            : (isEn ? 'Learn vowels from அ to ஔ' : 'அ முதல் ஔ வரை இனிமையாக கற்போம்'),
                        badge: isTe
                            ? '16 అచ్చులు'
                            : (isEn ? '12 Vowels' : '12 எழுத்துகள்'),
                        letterBadge: isTe ? 'అ' : 'அ',
                        progressFraction: (completedCount / 12).clamp(0.0, 1.0),
                        gradient: AppColors.pinkGradient,
                        onTap: () => _navigateToCategory(context, '/uyir'),
                      ),
                      const SizedBox(height: 16),

                      // 2. Consonants Category (மெய் எழுத்துகள் / హల్లులు)
                      _buildCategoryCard(
                        context,
                        title: langService.consonantsTitle,
                        subtitle: isTe
                            ? 'క నుండి హ వరకు హల్లులు'
                            : (isEn ? 'Learn dotted consonants from க் to ன்' : 'க் முதல் ன் வரை புள்ளியிட்ட எழுத்துகள்'),
                        badge: isTe
                            ? '36 హల్లులు'
                            : (isEn ? '18 Consonants' : '18 எழுத்துகள்'),
                        letterBadge: isTe ? 'క' : 'க்',
                        progressFraction: (completedCount / 30).clamp(0.0, 1.0),
                        gradient: AppColors.blueGradient,
                        onTap: () => _navigateToCategory(context, '/mei'),
                      ),
                      const SizedBox(height: 16),

                      // 3. Tamil-specific categories (ஆய்த எழுத்து & உயிர்மெய்)
                      if (!isTe) ...[
                        _buildCategoryCard(
                          context,
                          title: langService.aythamHeading,
                          subtitle: isEn
                              ? 'Unique three-dotted Tamil letter (ஃ)'
                              : 'முப்புள்ளி கொண்ட தனித்தமிழ் எழுத்து (ஃ)',
                          badge: isEn ? 'Aytham – 1' : 'ஆய்தம் – 1',
                          letterBadge: 'ஃ',
                          progressFraction: progressService.isLetterCompleted('aytham_1') ? 1.0 : 0.0,
                          gradient: AppColors.purpleGradient,
                          onTap: () => _navigateToCategory(context, '/aytham'),
                        ),
                        const SizedBox(height: 16),

                        _buildCategoryCard(
                          context,
                          title: langService.uyirmeiHeading,
                          subtitle: isEn
                              ? '216 melodious letters in 18 rows'
                              : '18 வரிசைகளில் 216 இனிய எழுத்துகள்',
                          badge: isEn ? '216 Letters' : '216 எழுத்துகள்',
                          letterBadge: 'க',
                          progressFraction: 0.35,
                          gradient: AppColors.greenGradient,
                          onTap: () => _navigateToCategory(context, '/uyirmei'),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 4. Stories / Reading
                      _buildCategoryCard(
                        context,
                        title: langService.storiesHeading,
                        subtitle: isTe
                            ? 'కుందేలు మరియు తాబేలు కథ'
                            : (isEn ? 'The Hare and the Tortoise - Illustrated Story' : 'முயலும் ஆமையும் - படக்கதை'),
                        badge: isTe ? 'చిన్న కథలు' : (isEn ? 'Short Stories' : 'சிறு கதைகள்'),
                        icon: Icons.auto_stories_rounded,
                        progressFraction: progressService.completedStoriesCount > 0 ? 1.0 : 0.0,
                        gradient: AppColors.orangeGradient,
                        onTap: () => _navigateToCategory(context, '/reading'),
                      ),
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

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    String? letterBadge,
    IconData? icon,
    required double progressFraction,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: gradient.first.withValues(alpha: 0.35), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon / Letter box
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: letterBadge != null
                      ? Text(
                          letterBadge,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        )
                      : Icon(icon ?? Icons.star_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),

                // Title, Subtitle & Badge
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: gradient.first.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: gradient.first,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 18),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressFraction,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF0F0F2),
                      valueColor: AlwaysStoppedAnimation<Color>(gradient.first),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progressFraction * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: gradient.first,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
