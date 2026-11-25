/**
 * Central API Router Index (Version 1 - /api/v1)
 */
const express = require('express');
const adminAuthRoutes = require('./adminAuthRoutes');
const userAuthRoutes = require('./userAuthRoutes');
const lessonRoutes = require('./lessonRoutes');
const letterRoutes = require('./letterRoutes');
const storyRoutes = require('./storyRoutes');
const videoRoutes = require('./videoRoutes');
const quizRoutes = require('./quizRoutes');
const gameRoutes = require('./gameRoutes');
const progressRoutes = require('./progressRoutes');
const dashboardRoutes = require('./dashboardRoutes');
const uploadRoutes = require('./uploadRoutes');
const audioRoutes = require('./audioRoutes');
const languageRoutes = require('./languageRoutes');
const integrationRoutes = require('./integrationRoutes');

const router = express.Router();

// Supported Languages (/api/v1/languages)
router.use('/languages', languageRoutes);

// Admin Authentication (/api/v1/auth/admin or /api/v1/admin)
router.use('/auth/admin', adminAuthRoutes);
router.use('/admin/auth', adminAuthRoutes);
router.use('/admin', (req, res, next) => {
  // Direct route for /admin/login convenience
  if (req.path === '/login') {
    return adminAuthRoutes(req, res, next);
  }
  next();
});

// Child User Authentication & Profile (/api/v1/users)
router.use('/users', userAuthRoutes);

// Educational Modules & Lessons (/api/v1/lessons and /api/v1/admin/lessons)
router.use('/lessons', lessonRoutes);
router.use('/admin/lessons', lessonRoutes);

// Letters & Letter Groups (/api/v1/letters and /api/v1/admin/letters)
router.use('/letters', letterRoutes);
router.use('/admin/letters', letterRoutes);

// Reading Stories (/api/v1/stories and /api/v1/admin/stories)
router.use('/stories', storyRoutes);
router.use('/admin/stories', storyRoutes);

// Educational Videos (/api/v1/videos and /api/v1/admin/videos)
router.use('/videos', videoRoutes);
router.use('/admin/videos', videoRoutes);

// Quizzes & Evaluation (/api/v1/quizzes and /api/v1/admin/quizzes)
router.use('/quizzes', quizRoutes);
router.use('/admin/quizzes', quizRoutes);

// Games (/api/v1/games and /api/v1/admin/games)
router.use('/games', gameRoutes);
router.use('/admin/games', gameRoutes);

// Progress & Stars (/api/v1/progress)
router.use('/progress', progressRoutes);

// Admin Dashboard & Audit (/api/v1/admin/dashboard)
router.use('/admin/dashboard', dashboardRoutes);

// File Uploads (/api/v1/admin/upload)
router.use('/admin/upload', uploadRoutes);

// Centralized Tamil Audio Synthesis & Manifest (/api/v1/audio & /api/v1/admin/audio)
router.use('/audio', audioRoutes);
router.use('/admin/audio', audioRoutes);

// Server-to-server: App Builders reads learners for the company admin (/api/v1/integration)
router.use('/integration', integrationRoutes);

module.exports = router;
