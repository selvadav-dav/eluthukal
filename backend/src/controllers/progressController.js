/**
 * User Progress & Stars Controller
 */
const ProgressModel = require('../models/progressModel');
const ProgressService = require('../services/progressService');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class ProgressController {
  /**
   * Get formatted progress for child user (Flutter compatible)
   */
  static async getUserProgress(req, res, next) {
    try {
      const { userId } = req.params;
      const progress = await ProgressService.getFlutterFormattedProgress(userId);
      return successResponse(res, 'User progress fetched successfully', progress);
    } catch (error) {
      if (error.message.includes('not found')) {
        return errorResponse(res, error.message, null, 404);
      }
      next(error);
    }
  }

  /**
   * Update progress for a completed letter, story, or game
   */
  static async updateProgress(req, res, next) {
    try {
      const { userId } = req.params;
      const { contentType, contentId, completionStatus, completionPercentage, starsEarned } = req.body;

      if (!contentType || !contentId) {
        return errorResponse(res, 'contentType and contentId are required', null, 400);
      }

      const updatedProgress = await ProgressModel.upsertProgress({
        userId,
        contentType,
        contentId,
        completionStatus: completionStatus || 'completed',
        completionPercentage: completionPercentage !== undefined ? completionPercentage : 100,
        starsEarned: starsEarned !== undefined ? starsEarned : 1,
      });

      return successResponse(res, 'Progress updated successfully', updatedProgress);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Batch synchronize progress and stars from mobile app
   */
  static async syncProgress(req, res, next) {
    try {
      const { userId } = req.params;
      const { stars, totalStars, completedLetterIds, completedStories, quizHighScore, gamesPlayed } = req.body;
      const starCount = totalStars !== undefined ? totalStars : stars;

      const progress = await ProgressModel.syncUserProgress({
        userId,
        stars: starCount,
        completedLetterIds,
        completedStories,
        quizHighScore,
        gamesPlayed,
      });

      return successResponse(res, 'Progress synchronized successfully', progress);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get user quiz history
   */
  static async getUserQuizResults(req, res, next) {
    try {
      const { userId } = req.params;
      const results = await ProgressModel.getUserQuizHistory(userId);
      return successResponse(res, 'User quiz history fetched successfully', results);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get user stars
   */
  static async getUserStars(req, res, next) {
    try {
      const { userId } = req.params;
      const progress = await ProgressModel.getUserProgress(userId);
      return successResponse(res, 'Total stars fetched successfully', {
        userId,
        totalStars: progress.stars,
        currentStreak: progress.currentStreak,
        highestStreak: progress.highestStreak,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = ProgressController;
