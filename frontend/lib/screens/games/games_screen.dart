import 'package:flutter/material.dart';
import '../../models/car_racing_game_model.dart';
import '../../models/letter_basket_game_model.dart';
import '../../models/letter_fishing_game_model.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/app_media_image.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../writing/writing_practice_screen.dart';
import 'agaram_run_game.dart';
import 'car_racing_game.dart';
import 'fruit_cutter_game.dart';
import 'letter_basket_game.dart';
import 'letter_candy_game.dart';
import 'letter_fishing_game.dart';

class GamesScreen extends StatefulWidget {
  final ProgressService progressService;

  const GamesScreen({super.key, required this.progressService});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.progressService, LanguageService.instance]),
      builder: (context, _) {
        final isEn = LanguageService.instance.isEnglish;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: KidScaffoldBackground(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // 1. Top Bar Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildTopHeader(context, isEn),
                      ),
                      const SizedBox(height: 14),

                      // 2. Navigation Switch: விளையாட்டுகள் | எழுதிப் பழகு
                      _buildTwoOptionSwitch(context, isEn),
                      const SizedBox(height: 14),

                      // 3. Scrollable Games Grid
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 95),
                          children: [
                            _buildGamesContent(context, isEn),
                          ],
                        ),
                      ),
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

  // Top Header: Games GIF (play.gif) + Title ("விளையாட்டு அரங்கம்") + Controller count + Stars count
  Widget _buildTopHeader(BuildContext context, bool isEn) {
    return Row(
      children: [
        if (Navigator.canPop(context)) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: Color(0xFF1E1B2E)),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
        ],
        // Vilayattu Animated Mascot GIF (assets/images/play.gif)
        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7F6),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD1C4E9), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: ClipOval(
            child: AppMediaImage(
              path: 'assets/images/play.gif',
              preferNetwork: true,
              fit: BoxFit.contain,
              fallback: const Icon(
                Icons.sports_esports_rounded,
                size: 26,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Screen Title: "விளையாட்டு அரங்கம்"
        Expanded(
          child: Text(
            isEn ? 'Games Arena' : 'விளையாட்டு\nஅரங்கம்',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1B2E),
              height: 1.15,
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Games played badge: 🎮 count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7F6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD1C4E9).withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_esports_rounded, size: 16, color: Color(0xFF5E35B1)),
              const SizedBox(width: 5),
              Text(
                '${widget.progressService.progress.gamesPlayed}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF311B92),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Stars count badge: ★ count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 17, color: Color(0xFFD97706)),
              const SizedBox(width: 3),
              Text(
                '${widget.progressService.stars}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF78350F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Two Options Switch: விளையாட்டுகள் (Active) | எழுதிப் பழகு (Directly navigates to Writing Practice)
  Widget _buildTwoOptionSwitch(BuildContext context, bool isEn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. விளையாட்டுகள் (Active Option)
          Expanded(
            child: BouncyButton(
              onPressed: () {},
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B2E),
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1B2E).withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sports_esports_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'Games' : 'விளையாட்டுகள்',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. எழுதிப் பழகு (Tapping navigates directly to Writing Practice)
          Expanded(
            child: BouncyButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WritingPracticeScreen(
                      progressService: widget.progressService,
                    ),
                  ),
                );
              },
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 22,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEn ? 'Writing Practice' : 'எழுதிப் பழகு',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Games content displaying our core games with attractive game-specific illustration backgrounds
  Widget _buildGamesContent(BuildContext context, bool isEn) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        const double spacing = 12.0;

        // All 7 core games with game-specific animated GIF artwork
        final ourGridGames = [
          // Game 1: தமிழ் எழுத்து மிட்டாய் (Tamil Letter Candy)
          _GameTileModel(
            id: 'candy_crush',
            titleTa: 'எழுத்து மிட்டாய்',
            titleEn: 'Letter Candy',
            icon: Icons.grid_view_rounded,
            imagePath: 'assets/Gif/candy crush game.gif',
            gradientColors: const [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TamilLetterCandyGame(
                    progressService: widget.progressService,
                  ),
                ),
              );
            },
          ),

          // Game 2: அகரம் ஓட்டம் (Agaram Run)
          _GameTileModel(
            id: 'agaram_run',
            titleTa: 'அகரம் ஓட்டம்',
            titleEn: 'Agaram Run',
            icon: Icons.directions_run_rounded,
            imagePath: 'assets/Gif/agaram run game.gif',
            gradientColors: const [Color(0xFF43A047), Color(0xFF1B5E20)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgaramRunGame(
                    progressService: widget.progressService,
                  ),
                ),
              );
            },
          ),

          // Game 3: பழம் வெட்டு (Fruit Cutter Game)
          _GameTileModel(
            id: 'fruit_cutter',
            titleTa: 'பழம் வெட்டு',
            titleEn: 'Fruit Cutter',
            icon: Icons.restaurant_rounded,
            imagePath: 'assets/Gif/fruit cutter game.gif',
            gradientColors: const [Color(0xFFFF5722), Color(0xFFE91E63)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FruitCutterGame(
                    progressService: widget.progressService,
                  ),
                ),
              );
            },
          ),

          // Game 4: உயிர் எழுத்து கார் பந்தயம் (Car Racing Game)
          _GameTileModel(
            id: 'car_racing',
            titleTa: 'கார் பந்தயம்',
            titleEn: 'Car Racing',
            icon: Icons.directions_car_rounded,
            imagePath: 'assets/Gif/car game.gif',
            gradientColors: const [Color(0xFFFF5252), Color(0xFFC62828)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarRacingGame(
                    progressService: widget.progressService,
                    mode: RacingGameMode.uyir,
                  ),
                ),
              );
            },
          ),

          // Game 5: எழுத்து மீன்பிடி (Letter Fishing Game)
          _GameTileModel(
            id: 'letter_fishing',
            titleTa: 'எழுத்து மீன்பிடி',
            titleEn: 'Letter Fishing',
            icon: Icons.water_rounded,
            imagePath: 'assets/Gif/fish game.gif',
            hasDot: true,
            dotColor: const Color(0xFFFFD54F),
            gradientColors: const [Color(0xFF29B6F6), Color(0xFF0288D1)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LetterFishingGame(
                    progressService: widget.progressService,
                    mode: FishingGameMode.uyir,
                  ),
                ),
              );
            },
          ),

          // Game 6: எழுத்துக் கூடை - உயிர் எழுத்துகள் (Letter Basket Uyir)
          _GameTileModel(
            id: 'basket_uyir',
            titleTa: 'கூடை (உயிர்)',
            titleEn: 'Basket (Uyir)',
            icon: Icons.shopping_basket_rounded,
            imagePath: 'assets/Gif/uyir eluthu kudai game.gif',
            gradientColors: const [Color(0xFFFFA726), Color(0xFFE65100)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LetterBasketGame(
                    progressService: widget.progressService,
                    mode: BasketGameMode.uyir,
                  ),
                ),
              );
            },
          ),

          // Game 7: எழுத்துக் கூடை - மெய் எழுத்துகள் (Letter Basket Mei)
          _GameTileModel(
            id: 'basket_mei',
            titleTa: 'கூடை (மெய்)',
            titleEn: 'Basket (Mei)',
            icon: Icons.shopping_basket_rounded,
            imagePath: 'assets/Gif/Mei eluthu kudai game.gif',
            gradientColors: const [Color(0xFF26A69A), Color(0xFF00695C)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LetterBasketGame(
                    progressService: widget.progressService,
                    mode: BasketGameMode.mei,
                  ),
                ),
              );
            },
          ),
        ];

        const int numCols = 2;
        final double colWidth = (totalWidth - spacing) / 2;
        const double cardHeight = 158.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rows of core 2x2 grid games - all tiles exact same size
            for (int i = 0; i < ourGridGames.length; i += numCols) ...[
              if (i > 0) const SizedBox(height: spacing),
              Builder(
                builder: (context) {
                  final chunk = ourGridGames.sublist(
                    i,
                    (i + numCols > ourGridGames.length) ? ourGridGames.length : i + numCols,
                  );

                  return Row(
                    children: [
                      for (int j = 0; j < numCols; j++) ...[
                        if (j > 0) const SizedBox(width: spacing),
                        if (j < chunk.length)
                          SizedBox(
                            width: colWidth,
                            height: cardHeight,
                            child: _buildStandardTile(context, chunk[j], isEn),
                          )
                        else
                          SizedBox(width: colWidth, height: cardHeight),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  // Standard colorful game card tile with Game-Specific Illustration & Cute Name Badge
  Widget _buildStandardTile(BuildContext context, _GameTileModel item, bool isEn) {
    return BouncyButton(
      onPressed: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: item.gradientColors.first.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: item.gradientColors.first.withValues(alpha: 0.32),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Game Specific Illustration / Animated GIF Background
              AppMediaImage(
                path: item.imagePath,
                preferNetwork: true,
                fit: BoxFit.cover,
                fallback: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // 2. Content: Frosted Icon badge at top
              Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B2E).withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                        ),
                        child: Icon(
                          item.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (item.hasDot)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: item.dotColor ?? const Color(0xFFFFD54F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Cute & neat game title badge at the bottom
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2E).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isEn ? item.titleEn : item.titleTa,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.1,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model for standard colorful game tiles with specific illustration art
class _GameTileModel {
  final String id;
  final String titleTa;
  final String titleEn;
  final IconData icon;
  final String imagePath;
  final List<Color> gradientColors;
  final bool hasDot;
  final Color? dotColor;
  final VoidCallback onTap;

  const _GameTileModel({
    required this.id,
    required this.titleTa,
    required this.titleEn,
    required this.icon,
    required this.imagePath,
    required this.gradientColors,
    this.hasDot = false,
    this.dotColor,
    required this.onTap,
  });
}
