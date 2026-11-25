/**
 * Integration Routes (/api/v1/integration)
 *
 * Server-to-server endpoints for the App Builders platform. App Builders reads this
 * app's learners so each company admin sees who uses the app on their Users page.
 * Protected by a shared secret: header `X-Integration-Key` must equal INTEGRATION_API_KEY.
 * If INTEGRATION_API_KEY is not set, the endpoints are switched off.
 */
const crypto = require('crypto');
const express = require('express');
require('../config/env'); // loads .env
const { pool } = require('../config/db');
const { successResponse, errorResponse } = require('../utils/apiResponse');

const router = express.Router();

function requireIntegrationKey(req, res, next) {
  const expected = process.env.INTEGRATION_API_KEY || '';
  if (!expected) {
    return errorResponse(res, 'Integration is not enabled on this server', null, 503);
  }
  const given = String(req.get('X-Integration-Key') || '');
  const a = crypto.createHash('sha256').update(given).digest();
  const b = crypto.createHash('sha256').update(expected).digest();
  if (!given || !crypto.timingSafeEqual(a, b)) {
    return errorResponse(res, 'Invalid integration key', null, 401);
  }
  return next();
}

/**
 * GET /integration/users?limit=500&offset=0
 * Returns learners oldest first (the seeded demo learner 'default_child' is left out), so paging stays stable while new people sign up.
 */
router.get('/users', requireIntegrationKey, async (req, res, next) => {
  try {
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 500, 1), 1000);
    const offset = Math.max(parseInt(req.query.offset, 10) || 0, 0);

    const [rows] = await pool.query(
      `SELECT id, child_name AS name, email, is_active, created_at, updated_at
       FROM users
       WHERE id <> 'default_child'
       ORDER BY created_at ASC, id ASC
       LIMIT ? OFFSET ?`,
      [limit, offset]
    );
    const [[{ count }]] = await pool.query("SELECT COUNT(*) AS count FROM users WHERE id <> 'default_child'");

    return successResponse(res, 'Users fetched', {
      total: Number(count),
      limit,
      offset,
      users: rows.map((u) => ({
        id: String(u.id),
        name: u.name,
        email: u.email || null,
        is_active: Boolean(u.is_active),
        created_at: u.created_at,
        updated_at: u.updated_at,
      })),
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
