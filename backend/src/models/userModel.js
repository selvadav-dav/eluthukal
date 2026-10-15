/**
 * User (Child Learner) Data Access Model
 */
const { pool } = require('../config/db');

class UserModel {
  static async findById(id) {
    const [rows] = await pool.query(
      `SELECT u.*, COALESCE(s.total_stars, u.total_stars) as total_stars, 
              COALESCE(s.current_streak, 1) as current_streak,
              COALESCE(s.highest_streak, 1) as highest_streak
       FROM users u
       LEFT JOIN user_stars s ON u.id = s.user_id
       WHERE u.id = ? LIMIT 1`,
      [id]
    );
    return rows[0] || null;
  }

  static async findByEmail(emailOrUsername) {
    if (!emailOrUsername) return null;
    const clean = emailOrUsername.trim().toLowerCase();
    const [rows] = await pool.query(
      `SELECT u.*, COALESCE(s.total_stars, u.total_stars) as total_stars, 
              COALESCE(s.current_streak, 1) as current_streak,
              COALESCE(s.highest_streak, 1) as highest_streak
       FROM users u
       LEFT JOIN user_stars s ON u.id = s.user_id
       WHERE LOWER(u.email) = ? OR LOWER(u.child_name) = ? LIMIT 1`,
      [clean, clean]
    );
    return rows[0] || null;
  }

  static async create({ id, name, email, passwordHash, age = 5, avatarAsset = 'assets/images/welcome.png' }) {
    await pool.query(
      `INSERT INTO users (id, child_name, email, password_hash, age, avatar_asset, total_stars, is_active)
       VALUES (?, ?, ?, ?, ?, ?, 0, TRUE)`,
      [id, name, email ? email.trim().toLowerCase() : null, passwordHash, age, avatarAsset]
    );

    // Ensure stars row exists
    await pool.query(
      `INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak)
       VALUES (?, 0, 1, 1)
       ON DUPLICATE KEY UPDATE user_id = user_id`,
      [id]
    );

    return this.findById(id);
  }

  static async createOrUpdate({ id, childName = 'குழந்தை', email = null, age = 5, avatarAsset = 'assets/images/welcome.png' }) {
    await pool.query(
      `INSERT INTO users (id, child_name, email, age, avatar_asset, total_stars, is_active)
       VALUES (?, ?, ?, ?, ?, 0, TRUE)
       ON DUPLICATE KEY UPDATE 
         child_name = VALUES(child_name),
         email = COALESCE(VALUES(email), users.email),
         age = VALUES(age),
         avatar_asset = VALUES(avatar_asset)`,
      [id, childName, email, age, avatarAsset]
    );

    // Ensure stars row exists
    await pool.query(
      `INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak)
       VALUES (?, 0, 1, 1)
       ON DUPLICATE KEY UPDATE user_id = user_id`,
      [id]
    );

    return this.findById(id);
  }

  static async updateProfile(id, { childName, age, avatarAsset, totalStars, stars }) {
    const updates = [];
    const values = [];

    if (childName !== undefined) {
      updates.push('child_name = ?');
      values.push(childName);
    }
    if (age !== undefined) {
      updates.push('age = ?');
      values.push(age);
    }
    if (avatarAsset !== undefined) {
      updates.push('avatar_asset = ?');
      values.push(avatarAsset);
    }
    const starVal = totalStars !== undefined ? totalStars : stars;
    if (starVal !== undefined && !isNaN(parseInt(starVal, 10))) {
      const starsNum = parseInt(starVal, 10);
      updates.push('total_stars = ?');
      values.push(starsNum);
      // Keep user_stars table synchronized
      await pool.query(
        `INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak)
         VALUES (?, ?, 1, 1)
         ON DUPLICATE KEY UPDATE total_stars = ?`,
        [id, starsNum, starsNum]
      );
    }

    if (updates.length === 0) return this.findById(id);

    values.push(id);
    await pool.query(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, values);
    return this.findById(id);
  }

  static async updateUser(id, { child_name, name, email, age, avatar_asset, total_stars, is_active, passwordHash }) {
    const updates = [];
    const values = [];

    const finalName = child_name || name;
    if (finalName !== undefined) {
      updates.push('child_name = ?');
      values.push(finalName);
    }
    if (email !== undefined) {
      updates.push('email = ?');
      values.push(email ? email.trim().toLowerCase() : null);
    }
    if (age !== undefined) {
      updates.push('age = ?');
      values.push(parseInt(age, 10));
    }
    if (avatar_asset !== undefined) {
      updates.push('avatar_asset = ?');
      values.push(avatar_asset);
    }
    if (total_stars !== undefined) {
      const starsNum = parseInt(total_stars, 10) || 0;
      updates.push('total_stars = ?');
      values.push(starsNum);
      // Also update or insert in user_stars table
      await pool.query(
        `INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak)
         VALUES (?, ?, 1, 1)
         ON DUPLICATE KEY UPDATE total_stars = ?`,
        [id, starsNum, starsNum]
      );
    }
    if (is_active !== undefined) {
      updates.push('is_active = ?');
      values.push(is_active ? 1 : 0);
    }
    if (passwordHash) {
      updates.push('password_hash = ?');
      values.push(passwordHash);
    }

    if (updates.length > 0) {
      values.push(id);
      await pool.query(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, values);
    }

    return this.findById(id);
  }

  static async deleteUser(id) {
    // Delete dependent user progress, stars, and quiz records first
    await pool.query('DELETE FROM user_progress WHERE user_id = ?', [id]);
    await pool.query('DELETE FROM quiz_results WHERE user_id = ?', [id]);
    await pool.query('DELETE FROM user_stars WHERE user_id = ?', [id]);
    const [result] = await pool.query('DELETE FROM users WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  static async listAll({ limit = 100, offset = 0, search = '' } = {}) {
    let query = `
      SELECT u.id, u.child_name, u.email, u.age, u.avatar_asset, u.is_active,
             COALESCE(s.total_stars, u.total_stars, 0) as total_stars,
             COALESCE(s.current_streak, 1) as current_streak,
             COALESCE(s.highest_streak, 1) as highest_streak,
             (SELECT COUNT(*) FROM quiz_results qr WHERE qr.user_id = u.id) as total_quizzes_taken,
             (SELECT COUNT(*) FROM user_progress up WHERE up.user_id = u.id AND up.completion_status = 'completed') as total_completed_items,
             u.created_at, u.updated_at
      FROM users u
      LEFT JOIN user_stars s ON u.id = s.user_id
    `;
    const params = [];
    if (search && search.trim()) {
      query += ` WHERE LOWER(u.child_name) LIKE ? OR LOWER(COALESCE(u.email, '')) LIKE ? OR LOWER(u.id) LIKE ?`;
      const s = `%${search.trim().toLowerCase()}%`;
      params.push(s, s, s);
    }
    query += ` ORDER BY u.created_at DESC LIMIT ? OFFSET ?`;
    params.push(parseInt(limit, 10), parseInt(offset, 10));
    const [rows] = await pool.query(query, params);
    return rows;
  }

  static async countUsers(search = '') {
    if (search && search.trim()) {
      const s = `%${search.trim().toLowerCase()}%`;
      const [rows] = await pool.query(
        'SELECT COUNT(*) as count FROM users WHERE LOWER(child_name) LIKE ? OR LOWER(COALESCE(email, "")) LIKE ? OR LOWER(id) LIKE ?',
        [s, s, s]
      );
      return rows[0].count;
    }
    const [rows] = await pool.query('SELECT COUNT(*) as count FROM users');
    return rows[0].count;
  }
}

module.exports = UserModel;
