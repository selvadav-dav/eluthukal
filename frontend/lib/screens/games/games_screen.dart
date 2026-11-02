import 'package:flutter/material.dart';
import '../../models/car_racing_game_model.dart';
import '../../models/letter_basket_game_model.dart';
import '../../models/letter_fishing_game_model.dart';
import '../../services/language_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_scaffold_background.dart';
import 'agaram_run_game.dart';
import 'car_racing_game.dart';
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
  // Category filter: 'all', 'new', 'uyir', 'mei'
  String _selectedCategory = 'all';

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

                      // 2. Category Filter Pills Row
                      _buildCategoryFilterRow(isEn),
                      const SizedBox(height: 14),

                      // 3. Scrollable Games Grid & Coming Soon
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
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
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(3),
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
            child: Image.asset(
              'assets/images/play.gif',
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const Icon(
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

  // Horizontal category filter pills
  Widget _buildCategoryFilterRow(bool isEn) {
    final categories = [
      {'id': 'all', 'label': isEn ? 'All' : 'அனைத்தும்'},
      {'id': 'new', 'label': isEn ? 'New' : 'புதியவை'},
      {'id': 'uyir', 'label': isEn ? 'Uyir' : 'உயிர்'},
      {'id': 'mei', 'label': isEn ? 'Mei' : 'மெய்'},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat['id']!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E1B2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E1B2E) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E1B2E).withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Text(
                cat['label']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Games content displaying our core games with attractive game-specific illustration backgrounds
  Widget _buildGamesContent(BuildContext context, bool isEn) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        const double spacing = 11.0;

        // Our core grid games with game-specific artwork illustrations
        final ourGridGames = [
          // Game 3: உயிர் எழுத்து கார் பந்தயம் (Car Racing Game)
          _GameTileModel(
            id: 'car_racing',
            titleTa: 'உயிர் எழுத்து\nகார் பந்தயம்',
            titleEn: 'Car Racing\n(Uyir)',
            icon: Icons.directions_car_rounded,
            imagePath: 'assets/Gif/car game.gif',
            gradientColors: const [Color(0xFFFF5252), Color(0xFFC62828)],
            categories: const ['all', 'new', 'uyir'],
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

          // Game 4: எழுத்து மீன்பிடி (Letter Fishing Game)
          _GameTileModel(
            id: 'letter_fishing',
            titleTa: 'எழுத்து\nமீன்பிடி',
            titleEn: 'Letter\nFishing',
            icon: Icons.water_rounded,
            imagePath: 'assets/Gif/fish game.gif',
            hasDot: true,
            dotColor: const Color(0xFFFFD54F),
            gradientColors: const [Color(0xFF29B6F6), Color(0xFF0288D1)],
            categories: const ['all', 'uyir'],
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

          // Game 5: எழுத்துக் கூடை - உயிர் எழுத்துகள் (Letter Basket Uyir)
          _GameTileModel(
            id: 'basket_uyir',
            titleTa: 'எழுத்துக் கூடை\n(உயிர்)',
            titleEn: 'Letter Basket\n(Uyir)',
            icon: Icons.shopping_basket_rounded,
            imagePath: 'assets/Gif/uyir eluthu kudai game.gif',
            gradientColors: const [Color(0xFFFFA726), Color(0xFFE65100)],
            categories: const ['all', 'uyir'],
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

          // Game 6: எழுத்துக் கூடை - மெய் எழுத்துகள் (Letter Basket Mei)
          _GameTileModel(
            id: 'basket_mei',
            titleTa: 'எழுத்துக் கூடை\n(மெய்)',
            titleEn: 'Letter Basket\n(Mei)',
            icon: Icons.shopping_basket_rounded,
            imagePath: 'assets/Gif/Mei eluthu kudai game.gif',
            gradientColors: const [Color(0xFF26A69A), Color(0xFF00695C)],
            categories: const ['all', 'mei'],
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

        // Filter our grid games based on active category
        final filteredGrid = ourGridGames
            .where((item) => item.categories.contains(_selectedCategory))
            .toList();

        // Check if Row 1 featured games (Candy & Agaram Run) match filter
        final showCandy = _selectedCategory == 'all' || _selectedCategory == 'new';
        final showRun = _selectedCategory == 'all' || _selectedCategory == 'new' || _selectedCategory == 'uyir';

        // Dimension calculations
        // When there are 4 items (or 2 items), 2 columns gives a perfectly balanced layout
        final int numCols = (filteredGrid.length == 4 || filteredGrid.length == 2) ? 2 : (filteredGrid.length == 1 ? 1 : 3);
        final double colWidth = (totalWidth - (spacing * (numCols - 1))) / numCols;
        final double cardHeight = numCols == 2 ? 118.0 : (numCols == 1 ? 100.0 : (totalWidth - (spacing * 2)) / 3 * 1.08);

        // Row 1 featured dimensions
        final double candyWidth = showRun ? (totalWidth - spacing) * 0.38 : totalWidth;
        const double featuredHeight = 118.0;

        // Locked Coming Soon games with matching illustrations
        final comingSoonList = [
          _LockedTileModel(
            id: 'racing_mei',
            titleTa: 'மெய் கார்\nபந்தயம்',
            titleEn: 'Mei Car\nRacing',
            imagePath: 'assets/images/games/car_racing_mei.jpg',
            categories: const ['all', 'mei'],
          ),
          _LockedTileModel(
            id: 'story',
            titleTa: 'கதை\nசொல்',
            titleEn: 'Story\nTime',
            imagePath: 'assets/images/games/story_time.jpg',
            categories: const ['all'],
          ),
          _LockedTileModel(
            id: 'proverbs',
            titleTa: 'பழமொழி\nபுதிர்',
            titleEn: 'Proverbs\nPuzzle',
            imagePath: 'assets/images/games/proverbs_puzzle.jpg',
            categories: const ['all'],
          ),
        ];

        final filteredComingSoon = comingSoonList
            .where((item) => item.categories.contains(_selectedCategory))
            .toList();

        final double csColWidth = (totalWidth - (spacing * 2)) / 3;
        final double csCardHeight = csColWidth * 1.08;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Featured Letter Candy + Agaram Run
            if (showCandy || showRun) ...[
              Row(
                children: [
                  // Left: தமிழ் எழுத்து மிட்டாய் (Tamil Letter Candy)
                  if (showCandy)
                    SizedBox(
                      width: candyWidth,
                      height: featuredHeight,
                      child: _buildCandyTile(context, isEn),
                    ),
                  if (showCandy && showRun) const SizedBox(width: spacing),
                  // Right: அகரம் ஓட்டம் (Agaram Run - Banner width with running boy)
                  if (showRun)
                    Expanded(
                      child: SizedBox(
                        height: featuredHeight,
                        child: _buildRunTile(context, isEn),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: spacing),
            ],

            // Rows of our core grid games
            for (int i = 0; i < filteredGrid.length; i += numCols) ...[
              if (i > 0) const SizedBox(height: spacing),
              Builder(
                builder: (context) {
                  final chunk = filteredGrid.sublist(
                    i,
                    (i + numCols > filteredGrid.length) ? filteredGrid.length : i + numCols,
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

            // Coming Soon Section: "விரைவில் வருபவை"
            if (filteredComingSoon.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEn ? 'Coming Soon' : 'விரைவில் வருபவை',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B2E),
                    ),
                  ),
                  Text(
                    '${filteredComingSoon.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (int i = 0; i < filteredComingSoon.length; i++) ...[
                    if (i > 0) const SizedBox(width: spacing),
                    SizedBox(
                      width: csColWidth,
                      height: csCardHeight,
                      child: _buildLockedTile(context, filteredComingSoon[i], isEn),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // Row 1 - Left: தமிழ் எழுத்து மிட்டாய் (Tamil Letter Candy Tile with Illustration)
  Widget _buildCandyTile(BuildContext context, bool isEn) {
    return BouncyButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TamilLetterCandyGame(
              progressService: widget.progressService,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFAB47BC).withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B1FA2).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Game Specific Candy Animated GIF
              Image.asset(
                'assets/Gif/candy crush game.gif',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // 2. Content overlay: Frosted icon on top
              Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E).withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 20,
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

  // Row 1 - Right: அகரம் ஓட்டம் (Agaram Run Tile with Running AGARAM Boy Illustration)
  Widget _buildRunTile(BuildContext context, bool isEn) {
    return BouncyButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AgaramRunGame(
              progressService: widget.progressService,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Agaram Letter Run Animated GIF
              Image.asset(
                'assets/Gif/agaram run game.gif',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // 2. Content overlay: Frosted icon on top and White pill play button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B2E).withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                      ),
                      child: const Icon(
                        Icons.directions_run_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    // White pill play button: ▶ விளையாடலாம்
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.3), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF1B5E20),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isEn ? 'Play' : 'விளையாடலாம்',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
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

  // Standard colorful game card tile with Game-Specific Illustration (Clean, bright, no shadow)
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
              Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Container(
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
            ],
          ),
        ),
      ),
    );
  }

  // Locked game card tile for Coming Soon with Matching Illustration
  Widget _buildLockedTile(BuildContext context, _LockedTileModel item, bool isEn) {
    return BouncyButton(
      onPressed: () {
        _showComingSoonSnackBar(context, isEn ? item.titleEn : item.titleTa);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade400.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Artwork illustration
              Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF9E9E9E), Color(0xFF757575)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // 2. Light translucent overlay for locked mystery effect
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // 3. Content: Frosted Lock icon at top
              Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E).withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 20,
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

  void _showComingSoonSnackBar(BuildContext context, String title) {
    final cleanTitle = title.replaceAll('\n', ' ');
    final isEn = LanguageService.instance.isEnglish;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEn ? '$cleanTitle is coming soon! 🚀' : '$cleanTitle விரைவில் வருகிறது! 🚀',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
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
  final List<String> categories;
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
    required this.categories,
    this.hasDot = false,
    this.dotColor,
    required this.onTap,
  });
}

// Model for locked Coming Soon tiles with specific illustration art
class _LockedTileModel {
  final String id;
  final String titleTa;
  final String titleEn;
  final String imagePath;
  final List<String> categories;

  const _LockedTileModel({
    required this.id,
    required this.titleTa,
    required this.titleEn,
    required this.imagePath,
    required this.categories,
  });
}
