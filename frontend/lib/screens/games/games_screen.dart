import 'package:flutter/material.dart';
import '../../models/car_racing_game_model.dart';
import '../../models/letter_basket_game_model.dart';
import '../../models/letter_fishing_game_model.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import 'agaram_run_game.dart';
import 'car_racing_game.dart';
import 'letter_basket_game.dart';
import 'letter_candy_game.dart';
import 'letter_fishing_game.dart';

class GamesScreen extends StatelessWidget {
  final ProgressService progressService;

  const GamesScreen({super.key, required this.progressService});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([progressService, LanguageService.instance]),
      builder: (context, _) {
        final isEn = LanguageService.instance.isEnglish;
        return Scaffold(
          appBar: KidAppBar(
            title: LanguageService.instance.gamesHeading,
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
                      // Hero Card with AGARAM Game Mascot
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFB39DDB), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.candyPurple.withValues(alpha: 0.2),
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
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.sports_esports_rounded, size: 14, color: AppColors.candyPurple),
                                          const SizedBox(width: 4),
                                          Text(
                                            isEn ? 'Games Arena' : 'விளையாட்டு அரங்கம்',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.candyPurple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      isEn ? 'Learn Tamil through games!' : 'விளையாடி தமிழை கற்போம்!',
                                      style: AppTextStyles.cardTitle.copyWith(
                                        fontSize: 18,
                                        color: const Color(0xFF4A148C),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEn
                                        ? 'Games Played: ${progressService.progress.gamesPlayed}'
                                        : 'விளையாடியவை: ${progressService.progress.gamesPlayed}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6A1B9A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const MascotWidget(
                              pose: MascotPose.game,
                              size: MascotSize.small,
                              customHeight: 120,
                              showGlow: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Game 0 (NEW 2D PLATFORMER): அகரம் ஓட்டம் (Agaram Run Game)
                      _buildFeaturedRunGameCard(
                        context,
                        title: 'அகரம் ஓட்டம்',
                        subtitle: 'ஓடி விளையாடி தமிழ் எழுத்துகளை கற்கலாம்!',
                        modeBadge: '2D ஓட்டப் பந்தயம்',
                        starsReward: '+3',
                        onPlay: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgaramRunGame(
                                progressService: progressService,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Game 1: தமிழ் எழுத்து மிட்டாய் (Tamil Letter Candy Game)
                      _buildFeaturedCandyGameCard(
                        context,
                        title: 'தமிழ் எழுத்து மிட்டாய்',
                        subtitle: 'எழுத்துகளை இணைத்து மதிப்பெண் பெறலாம்!',
                        modeBadge: 'Match-3 மிட்டாய்',
                        starsReward: '+3',
                        onPlay: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TamilLetterCandyGame(
                                progressService: progressService,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Game 2: உயிர் எழுத்து கார் பந்தயம் (Car Racing Game - உயிர் எழுத்து ஒலி விளையாட்டு)
                      _buildFeaturedRacingGameCard(
                        context,
                        title: 'உயிர் எழுத்து கார் பந்தயம்',
                        subtitle: 'ஒலியைக் கேட்டு காரை ஓட்டி சரியான உயிர் எழுத்துகளை சேகரியுங்கள்!',
                        modeBadge: 'உயிர் எழுத்துகள்',
                        starsReward: '+3',
                        onPlay: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CarRacingGame(
                                progressService: progressService,
                                mode: RacingGameMode.uyir,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Game 3: எழுத்து மீன்பிடி (Letter Fishing Game - உயிர் எழுத்துகள்)
                      _buildFeaturedFishingGameCard(
                        context,
                        title: 'எழுத்து மீன்பிடி',
                        subtitle: 'நீந்தும் வண்ண மீன்களில் சரியான உயிர் எழுத்துகளைப் பிடித்து மகிழுங்கள்!',
                        modeBadge: 'உயிர் எழுத்துகள்',
                        starsReward: '+3',
                        onPlay: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LetterFishingGame(
                                progressService: progressService,
                                mode: FishingGameMode.uyir,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Game 4: எழுத்துக் கூடை (Letter Basket Game) - உயிர் எழுத்துகள்
                      _buildFeaturedBasketGameCard(
                        context,
                        title: 'எழுத்துக் கூடை',
                        subtitle: 'கூடையை நகர்த்தி சரியான உயிர் எழுத்துகளைப் பிடியுங்கள்!',
                        modeBadge: 'உயிர் எழுத்துகள்',
                        starsReward: '+3',
                        gradient: AppColors.orangeGradient,
                        onPlay: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LetterBasketGame(
                                progressService: progressService,
                                mode: BasketGameMode.uyir,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Game 5: எழுத்துக் கூடை - மெய் எழுத்துகள்
                      _buildSecondaryBasketGameCard(
                        context,
                        title: 'எழுத்துக் கூடை (மெய் எழுத்துகள்)',
                        subtitle: 'புள்ளியிட்ட மெய் எழுத்துகளைக் கூடையில் பிடித்து மகிழுங்கள்!',
                        modeBadge: 'மெய் எழுத்துகள்',
                        starsReward: '+3',
                        icon: Icons.shopping_basket_rounded,
                        gradient: AppColors.tealGradient,
                        onPlay: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LetterBasketGame(
                                progressService: progressService,
                                mode: BasketGameMode.mei,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildFeaturedRunGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String modeBadge,
    required String starsReward,
    required VoidCallback onPlay,
  }) {
    return BouncyButton(
      onPressed: onPlay,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F5E9), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF4CAF50), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Animated-style Runner Thumbnail
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.directions_run_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC8E6C9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                modeBadge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'புதியது',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    starsReward,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF57F17),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF57F17)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 18,
                          color: const Color(0xFF1B5E20),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'விளையாடலாம்',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCandyGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String modeBadge,
    required String starsReward,
    required VoidCallback onPlay,
  }) {
    return BouncyButton(
      onPressed: onPlay,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3E5F5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFAB47BC), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E24AA).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Animated-style Candy Thumbnail
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4081), Color(0xFFAB47BC), Color(0xFF6A1B9A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E24AA).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.grid_view_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1BEE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                modeBadge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6A1B9A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4081),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'புதியது',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    starsReward,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF57F17),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF57F17)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 18,
                          color: const Color(0xFF4A148C),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'விளையாடலாம்',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedFishingGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String modeBadge,
    required String starsReward,
    required VoidCallback onPlay,
  }) {
    return BouncyButton(
      onPressed: onPlay,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE1F5FE), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF29B6F6), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0288D1).withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Animated-style Fishing Thumbnail
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1), Color(0xFF01579B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0288D1).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.water_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB3E5FC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                modeBadge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF01579B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'புதியது',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    starsReward,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF57F17),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF57F17)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 18,
                          color: const Color(0xFF01579B),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0288D1), Color(0xFF01579B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'விளையாடலாம்',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBasketGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String modeBadge,
    required String starsReward,
    required List<Color> gradient,
    required VoidCallback onPlay,
  }) {
    return BouncyButton(
      onPressed: onPlay,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFB74D), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Animated-style Basket Thumbnail
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFF9800), Color(0xFFE65100)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shopping_basket_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0B2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                modeBadge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    starsReward,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF57F17),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF57F17)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFBF360C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Play Button Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'விளையாடலாம்!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedRacingGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String modeBadge,
    required String starsReward,
    required VoidCallback onPlay,
  }) {
    return BouncyButton(
      onPressed: onPlay,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEBEE), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFEF5350), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Racing Car Animated-style Thumbnail
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFE53935), Color(0xFFC62828)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.directions_car_rounded, size: 38, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCDD2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                modeBadge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC62828),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    starsReward,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF57F17),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF57F17)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFB71C1C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Play Button Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_esports_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'பந்தயத்தை தொடங்கு!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryBasketGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String modeBadge,
    required String starsReward,
    IconData icon = Icons.shopping_basket_rounded,
    required List<Color> gradient,
    required VoidCallback onPlay,
  }) {
    return BouncyButton(
      onPressed: onPlay,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: gradient.first.withValues(alpha: 0.35), width: 2),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 30),
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
                          title,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              starsReward,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00695C),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFF00695C)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF00897B), size: 34),
          ],
        ),
      ),
    );
  }
}
