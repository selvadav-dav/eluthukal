import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/progress_service.dart';

class LevelProgress {
  final bool isCompleted;
  final int stars; // 0 to 3
  final int highScore;

  const LevelProgress({
    this.isCompleted = false,
    this.stars = 0,
    this.highScore = 0,
  });

  Map<String, dynamic> toJson() => {
        'isCompleted': isCompleted,
        'stars': stars,
        'highScore': highScore,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        isCompleted: json['isCompleted'] as bool? ?? false,
        stars: json['stars'] as int? ?? 0,
        highScore: json['highScore'] as int? ?? 0,
      );
}

class BalloonPopProgressService extends ChangeNotifier {
  static const String _storageKey = 'agaram_balloon_pop_progress_v1';

  int _unlockedLevel = 1; // 1 to 3
  final Map<int, LevelProgress> _levels = {
    1: const LevelProgress(),
    2: const LevelProgress(),
    3: const LevelProgress(),
  };

  int get unlockedLevel => _unlockedLevel;

  bool isLevelUnlocked(int levelNumber) {
    if (levelNumber <= 1) return true;
    return levelNumber <= _unlockedLevel;
  }

  bool isLevelCompleted(int levelNumber) {
    return _levels[levelNumber]?.isCompleted ?? false;
  }

  int getLevelStars(int levelNumber) {
    return _levels[levelNumber]?.stars ?? 0;
  }

  int getLevelHighScore(int levelNumber) {
    return _levels[levelNumber]?.highScore ?? 0;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        _unlockedLevel = (data['unlockedLevel'] as int?) ?? 1;
        if (_unlockedLevel < 1) _unlockedLevel = 1;
        if (_unlockedLevel > 3) _unlockedLevel = 3;

        final levelsMap = data['levels'] as Map<String, dynamic>?;
        if (levelsMap != null) {
          for (int i = 1; i <= 3; i++) {
            if (levelsMap.containsKey(i.toString())) {
              _levels[i] = LevelProgress.fromJson(
                levelsMap[i.toString()] as Map<String, dynamic>,
              );
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading balloon pop progress: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'unlockedLevel': _unlockedLevel,
        'levels': _levels.map((k, v) => MapEntry(k.toString(), v.toJson())),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving balloon pop progress: $e');
    }
  }

  /// Complete a level: update stars, high score, and unlock next level
  Future<void> completeLevel({
    required int levelNumber,
    required int score,
    required int stars,
    required ProgressService progressService,
  }) async {
    final prev = _levels[levelNumber] ?? const LevelProgress();
    final newStars = stars > prev.stars ? stars : prev.stars;
    final newHighScore = score > prev.highScore ? score : prev.highScore;

    _levels[levelNumber] = LevelProgress(
      isCompleted: true,
      stars: newStars,
      highScore: newHighScore,
    );

    // Sequentially unlock next level if this was the latest unlocked level
    if (levelNumber == _unlockedLevel && _unlockedLevel < 3) {
      _unlockedLevel = levelNumber + 1;
    }

    notifyListeners();
    await _save();

    // Sync with global progress service (record game played and award stars)
    progressService.recordGameCompleted(stars);
  }
}
