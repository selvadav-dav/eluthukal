/**
 * Child User Profile & Authentication Routes (/api/v1/users)
 */
const express = require('express');
const { body, param } = require('express-validator');
const UserAuthController = require('../controllers/userAuthController');
const AccessController = require('../controllers/accessController');
const { validateRequest } = require('../middleware/validateMiddleware');
const { verifyToken } = require('../middleware/authMiddleware');

const router = express.Router();

// User Registration with Name, Email, Phone, Password
router.post(
  '/register',
  [
    body('email').trim().isEmail().withMessage('சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும் (Valid email required)'),
    body('password').isLength({ min: 6 }).withMessage('கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும் (Password must be at least 6 characters)'),
    body('phone').optional().trim(),
    validateRequest,
  ],
  UserAuthController.register
);

// User Login with Email or Username and Password
router.post(
  '/login',
  [
    body('email').trim().notEmpty().withMessage('மின்னஞ்சல் அல்லது பயனர் பெயர் தேவை (Email or username required)'),
    body('password').notEmpty().withMessage('கடவுச்சொல் தேவை (Password required)'),
    validateRequest,
  ],
  UserAuthController.login
);

// Google Sign-In & Registration
router.post('/google-login', UserAuthController.googleLogin);

// Get Currently Authenticated User
router.get('/me', verifyToken, UserAuthController.me);

// Content access (scratch code / payment) - unlocked once per user
router.get('/access', verifyToken, AccessController.status);
router.post('/access/unlock', verifyToken, AccessController.unlock);

// Legacy Guest Init Route
router.post('/init', UserAuthController.registerOrInit);

// Get child profile by ID
router.get(
  '/profile/:id',
  [param('id').notEmpty().withMessage('User ID is required'), validateRequest],
  UserAuthController.getProfile
);

// Update child profile
router.put(
  '/profile/:id',
  [
    param('id').notEmpty().withMessage('User ID is required'),
    body('age').optional().isInt({ min: 2, max: 15 }).withMessage('Age must be between 2 and 15'),
    validateRequest,
  ],
  UserAuthController.updateProfile
);

module.exports = router;
