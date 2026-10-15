/**
 * Child User Progress & Star Routes
 */
const express = require('express');
const { body, param } = require('express-validator');
const ProgressController = require('../controllers/progressController');
const { validateRequest } = require('../middleware/validateMiddleware');

const router = express.Router();

// Get user progress (compatible with Flutter UserProgressModel)
router.get(
  '/:userId',
  [param('userId').notEmpty().withMessage('userId is required'), validateRequest],
  ProgressController.getUserProgress
);

// Update progress when completing a letter, story, game, or module
router.post(
  '/:userId/update',
  [
    param('userId').notEmpty().withMessage('userId is required'),
    body('contentType').isIn(['letter', 'story', 'game', 'lesson', 'quiz']).withMessage('Invalid contentType'),
    body('contentId').trim().notEmpty().withMessage('contentId is required'),
    validateRequest,
  ],
  ProgressController.updateProgress
);

// Batch synchronize full progress and stars from mobile app
router.post(
  '/:userId/sync',
  [param('userId').notEmpty().withMessage('userId is required'), validateRequest],
  ProgressController.syncProgress
);

// Get user quiz attempt history
router.get(
  '/:userId/quiz-results',
  [param('userId').notEmpty().withMessage('userId is required'), validateRequest],
  ProgressController.getUserQuizResults
);

// Get user total stars and streaks
router.get(
  '/:userId/stars',
  [param('userId').notEmpty().withMessage('userId is required'), validateRequest],
  ProgressController.getUserStars
);

module.exports = router;
