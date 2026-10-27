/**
 * Educational Videos Routes
 */
const express = require('express');
const { body, param } = require('express-validator');
const VideoController = require('../controllers/videoController');
const { verifyToken, requireRole } = require('../middleware/authMiddleware');
const { validateRequest } = require('../middleware/validateMiddleware');

const router = express.Router();

// Public: Stream proxy by URL query
router.get('/stream/proxy', VideoController.streamByUrl);

// Public: Stream video by ID (Cloudinary proxy)
router.get('/:id/stream', VideoController.streamById);

// Public: List videos (optional query: ?category=பாடல்)
router.get('/', VideoController.getAll);

// Public: Get single video
router.get('/:id', VideoController.getById);

// Admin: Create video
router.post(
  '/',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body().custom((value, { req }) => {
      const vUrl = req.body.video_url || req.body.videoUrl;
      if (!vUrl || (typeof vUrl === 'string' && !vUrl.trim())) {
        throw new Error('Video URL or video file path is required');
      }
      return true;
    }),
    validateRequest,
  ],
  VideoController.create
);

// Admin: Update video
router.put(
  '/:id',
  verifyToken,
  requireRole('super_admin', 'content_admin'),
  [param('id').notEmpty().withMessage('Video ID is required'), validateRequest],
  VideoController.update
);

// Admin: Delete video
router.delete(
  '/:id',
  verifyToken,
  requireRole('super_admin'),
  [param('id').notEmpty().withMessage('Video ID is required'), validateRequest],
  VideoController.delete
);

module.exports = router;
