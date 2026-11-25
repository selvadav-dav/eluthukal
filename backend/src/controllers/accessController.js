/**
 * Content Access Controller (book purchase / scratch code / payment)
 *
 * A user unlocks content ONCE (scratch code or payment). The unlock is stored
 * per user in `user_access`, so after logging in again (any device) they go
 * straight in without being asked a second time.
 *
 * SAMPLE MODE: any scratch code (>= 4 chars) is accepted and "payment" is
 * accepted without a gateway. TODO(server): validate scratch codes against a
 * codes table (mark as used) and verify the payment gateway signature.
 */
const { pool } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const SAMPLE_MODE = process.env.ACCESS_SAMPLE_MODE !== 'false';

let tableReady = false;
async function ensureTable() {
  if (tableReady) return;
  await pool.query(
    `CREATE TABLE IF NOT EXISTS user_access (
       user_id VARCHAR(100) PRIMARY KEY,
       unlocked_via VARCHAR(30) NOT NULL,
       scratch_code VARCHAR(64) NULL,
       payment_ref VARCHAR(128) NULL,
       unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
     )`
  );
  tableReady = true;
}

async function findAccess(userId) {
  await ensureTable();
  const [rows] = await pool.query(
    'SELECT user_id, unlocked_via, unlocked_at FROM user_access WHERE user_id = ? LIMIT 1',
    [userId]
  );
  return rows[0] || null;
}

class AccessController {
  /** GET /users/access -> { unlocked, unlockedVia, unlockedAt } */
  static async status(req, res, next) {
    try {
      const access = await findAccess(req.user.id);
      return successResponse(res, 'Access status', {
        unlocked: !!access,
        unlockedVia: access?.unlocked_via || null,
        unlockedAt: access?.unlocked_at || null,
      });
    } catch (error) {
      next(error);
    }
  }

  /** POST /users/access/unlock  body: { method: 'scratch_code'|'payment', code?, paymentRef? } */
  static async unlock(req, res, next) {
    try {
      const userId = req.user.id;
      const { method, code, paymentRef } = req.body || {};

      const existing = await findAccess(userId);
      if (existing) {
        return successResponse(res, 'ஏற்கனவே திறக்கப்பட்டது (Already unlocked)', { unlocked: true });
      }

      if (method === 'scratch_code') {
        const cleaned = String(code || '').trim().toUpperCase();
        if (cleaned.length < 4) {
          return errorResponse(res, 'குறியீடு சரியாக இல்லை (Invalid code)', null, 400);
        }
        if (!SAMPLE_MODE) {
          // TODO(server): look up `cleaned` in scratch codes table, ensure unused, mark used.
          return errorResponse(res, 'தவறான குறியீடு (Invalid code)', null, 400);
        }
        await pool.query(
          'INSERT INTO user_access (user_id, unlocked_via, scratch_code) VALUES (?, ?, ?)',
          [userId, 'scratch_code', cleaned]
        );
      } else if (method === 'payment') {
        if (!SAMPLE_MODE) {
          // TODO(server): verify payment gateway order/signature using paymentRef.
          return errorResponse(res, 'பணம் சரிபார்க்க முடியவில்லை (Payment not verified)', null, 400);
        }
        await pool.query(
          'INSERT INTO user_access (user_id, unlocked_via, payment_ref) VALUES (?, ?, ?)',
          [userId, 'payment', paymentRef || 'sample']
        );
      } else {
        return errorResponse(res, 'Invalid unlock method', null, 400);
      }

      return successResponse(res, 'பாடங்கள் திறக்கப்பட்டன (Content unlocked)', { unlocked: true });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AccessController;
