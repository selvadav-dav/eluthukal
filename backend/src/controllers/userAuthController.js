/**
 * Child User Profile & Session Controller
 */
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');
const config = require('../config/env');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class UserAuthController {
  /**
   * Register a new user with Name, Email, Password
   */
  static async register(req, res, next) {
    try {
      const { name, childName, email, password, age, avatarAsset } = req.body;
      const fullName = (name || childName || '').trim();

      if (!fullName) {
        return errorResponse(res, 'உங்கள் பெயரை உள்ளிடவும் (Name is required)', null, 400);
      }

      if (!email || !email.includes('@')) {
        return errorResponse(res, 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும் (Valid email is required)', null, 400);
      }

      if (!password || password.length < 6) {
        return errorResponse(res, 'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும் (Password must be at least 6 characters)', null, 400);
      }

      // Check if email already registered
      const existingUser = await UserModel.findByEmail(email);
      if (existingUser) {
        return errorResponse(res, 'இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது. (Email already registered)', null, 409);
      }

      // Hash password
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(password, salt);

      // Unique user ID
      const userId = `user_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

      const user = await UserModel.create({
        id: userId,
        name: fullName,
        email: email.trim().toLowerCase(),
        passwordHash,
        age: age || 5,
        avatarAsset: avatarAsset || 'assets/images/welcome.png',
      });

      // Generate JWT
      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          name: user.child_name,
          role: 'user',
        },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn || '30d' }
      );

      return successResponse(
        res,
        'பதிவு வெற்றிகரமாக முடிந்தது! (Registration successful)',
        {
          token,
          user: {
            id: user.id,
            name: user.child_name,
            child_name: user.child_name,
            email: user.email,
            age: user.age,
            avatarAsset: user.avatar_asset,
            avatar_asset: user.avatar_asset,
            totalStars: user.total_stars,
            total_stars: user.total_stars,
            createdAt: user.created_at,
          },
        },
        201
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Login with Email and Password
   */
  static async login(req, res, next) {
    try {
      const { email, username, identifier, password } = req.body;
      const credential = (email || username || identifier || req.body.name || '').trim();

      if (!credential || !password) {
        return errorResponse(res, 'மின்னஞ்சல் அல்லது பயனர் பெயர் மற்றும் கடவுச்சொல் தேவை (Username/Email and password are required)', null, 400);
      }

      const user = await UserModel.findByEmail(credential);
      if (!user || !user.is_active) {
        return errorResponse(res, 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது. (Invalid email or password)', null, 401);
      }

      if (!user.password_hash) {
        return errorResponse(res, 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது. (Invalid credentials)', null, 401);
      }

      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        return errorResponse(res, 'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறாக உள்ளது. (Invalid email or password)', null, 401);
      }

      // Generate JWT
      const token = jwt.sign(
        {
          id: user.id,
          email: user.email,
          name: user.child_name,
          role: 'user',
        },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn || '30d' }
      );

      return successResponse(res, 'உள்நுழைவு வெற்றிகரமாக முடிந்தது! (Login successful)', {
        token,
        user: {
          id: user.id,
          name: user.child_name,
          child_name: user.child_name,
          email: user.email,
          age: user.age,
          avatarAsset: user.avatar_asset,
          avatar_asset: user.avatar_asset,
          totalStars: user.total_stars,
          total_stars: user.total_stars,
          createdAt: user.created_at,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Current Authenticated User Profile
   */
  static async me(req, res, next) {
    try {
      const user = await UserModel.findById(req.user.id);
      if (!user) {
        return errorResponse(res, 'பயனர் விவரம் கிடைக்கவில்லை (User not found)', null, 404);
      }

      return successResponse(res, 'Profile fetched successfully', {
        id: user.id,
        name: user.child_name,
        child_name: user.child_name,
        email: user.email,
        age: user.age,
        avatarAsset: user.avatar_asset,
        avatar_asset: user.avatar_asset,
        totalStars: user.total_stars,
        total_stars: user.total_stars,
        createdAt: user.created_at,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Legacy Register or Initialize Child Profile (Guest session support)
   */
  static async registerOrInit(req, res, next) {
    try {
      // If password and email are provided, delegate to real register
      if (req.body.password && req.body.email) {
        return UserAuthController.register(req, res, next);
      }

      const { id, childName, age, avatarAsset } = req.body;
      const userId = id || `child_${Date.now()}`;

      const user = await UserModel.createOrUpdate({
        id: userId,
        childName,
        age,
        avatarAsset,
      });

      return successResponse(res, 'Child profile saved successfully', user, 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetch Profile by ID
   */
  static async getProfile(req, res, next) {
    try {
      const { id } = req.params;
      const user = await UserModel.findById(id);

      if (!user) {
        return errorResponse(res, 'Child profile not found', null, 404);
      }

      return successResponse(res, 'Profile fetched successfully', user);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update Child Profile
   */
  static async updateProfile(req, res, next) {
    try {
      const { id } = req.params;
      const { childName, age, avatarAsset, totalStars, stars } = req.body;

      const user = await UserModel.updateProfile(id, {
        childName,
        age,
        avatarAsset,
        totalStars,
        stars,
      });

      if (!user) {
        return errorResponse(res, 'Child profile not found', null, 404);
      }

      return successResponse(res, 'Profile updated successfully', user);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = UserAuthController;
