import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bouncy_button.dart';
import 'games/games_screen.dart';
import 'home/home_screen.dart';
import 'learning/learning_screen.dart';
import 'quiz/quiz_screen.dart';
import 'videos/videos_screen.dart';

import '../services/language_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final ProgressService progressService;

  const MainNavigationScreen({super.key, required this.progressService});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressTime;

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _tabHistory.add(index);
      });
    }
  }

  void _handleBackPress() {
    // 1. If any modal route / popup can pop, let Navigator pop it
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    // 2. If on any tab other than Home, navigate back towards Home page
    if (_selectedIndex != 0) {
      setState(() {
        while (_tabHistory.isNotEmpty && _tabHistory.last == _selectedIndex) {
          _tabHistory.removeLast();
        }
        _selectedIndex = _tabHistory.isNotEmpty ? _tabHistory.last : 0;
      });
      return;
    }

    // 3. User is on the Home page (index == 0):
    // Only exit when clicking back button from the Home page.
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      final lang = LanguageService.instance.currentLanguageCode;
      final isTamil = lang == 'ta';

      final message = isTamil
          ? 'செயலியை விட்டு வெளியேற மீண்டும் அழுத்தவும்'
          : 'Press back again to exit Agaram';

      final exitLabel = isTamil ? 'வெளியேறு' : 'Exit';

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: exitLabel,
            textColor: Colors.yellowAccent,
            onPressed: () => SystemNavigator.pop(),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } else {
      // Second back press on Home page -> Exit app cleanly
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        progressService: widget.progressService,
        onTabSelect: _onTabSelected,
      ),
      LearningScreen(progressService: widget.progressService),
      GamesScreen(progressService: widget.progressService),
      VideosScreen(progressService: widget.progressService),
      QuizScreen(progressService: widget.progressService),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) {
          return Scaffold(
            extendBody: true,
            body: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
            bottomNavigationBar: _buildCustomNavBar(),
          );
        },
      ),
    );
  }

  Widget _buildCustomNavBar() {
    final lang = LanguageService.instance.currentLanguageCode;
    final labels = lang == 'en'
        ? ['Home', 'Learn', 'Games', 'Videos', 'Quiz']
        : ['முகப்பு', 'கற்றல்', 'விளையாட்டு', 'காணொளி', 'வினாடி வினா'];

    final items = [
      _NavItem(icon: Icons.home_rounded, label: labels[0], color: AppColors.primary),
      _NavItem(icon: Icons.menu_book_rounded, label: labels[1], color: AppColors.secondary),
      _NavItem(icon: Icons.sports_esports_rounded, label: labels[2], color: AppColors.candyPurple),
      _NavItem(icon: Icons.play_circle_filled_rounded, label: labels[3], color: AppColors.playfulPink),
      _NavItem(icon: Icons.quiz_rounded, label: labels[4], color: AppColors.meiColor),
    ];

    return SafeArea(
      child: Container(
        height: 70,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFFE5B4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = _selectedIndex == index;

            return Expanded(
              child: BouncyButton(
                onPressed: () => _onTabSelected(index),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 10 : 6,
                          vertical: isSelected ? 4 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? item.color.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected ? item.color : AppColors.textMuted.withValues(alpha: 0.7),
                          size: isSelected ? 24 : 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: isSelected ? 10.5 : 9.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? item.color : AppColors.textMuted,
                            ),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
