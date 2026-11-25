/**
 * Database Connection Pool
 * Supports both MySQL (Local) and PostgreSQL (Production / Server)
 */
const config = require('./env');
const logger = require('../utils/logger');

const isPostgres = config.db.client === 'postgres' || config.db.client === 'postgresql';

let pool;

if (isPostgres) {
  const { Pool } = require('pg');
  const pgPool = new Pool({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database: config.db.name,
    max: config.db.connectionLimit,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5001,
  });

  // Query translator from MySQL to PostgreSQL
  function translateQuery(sql) {
    let converted = sql;

    // 1. MySQL JOIN in UPDATE
    converted = converted.replace(
      /UPDATE\s+users\s+u\s+JOIN\s+user_stars\s+s\s+ON\s+u\.id\s*=\s*s\.user_id\s+SET\s+u\.total_stars\s*=\s*s\.total_stars\s+WHERE\s+u\.id\s*=\s*\?/i,
      'UPDATE users SET total_stars = s.total_stars FROM user_stars s WHERE users.id = s.user_id AND users.id = ?'
    );

    // 2. ON DUPLICATE KEY UPDATE conversions
    if (/INSERT\s+INTO\s+user_stars/i.test(converted)) {
      converted = converted.replace(/ON\s+DUPLICATE\s+KEY\s+UPDATE\s+user_id\s*=\s*user_id/i, 'ON CONFLICT (user_id) DO NOTHING');
      converted = converted.replace(/ON\s+DUPLICATE\s+KEY\s+UPDATE/i, 'ON CONFLICT (user_id) DO UPDATE SET');
    } else if (/INSERT\s+INTO\s+user_progress/i.test(converted)) {
      converted = converted.replace(/ON\s+DUPLICATE\s+KEY\s+UPDATE/i, 'ON CONFLICT (user_id, content_type, content_id) DO UPDATE SET');
    } else if (/INSERT\s+INTO\s+users/i.test(converted)) {
      converted = converted.replace(/ON\s+DUPLICATE\s+KEY\s+UPDATE/i, 'ON CONFLICT (id) DO UPDATE SET');
    }

    // Replace VALUES(column) with EXCLUDED.column
    converted = converted.replace(/VALUES\((\w+)\)/gi, 'EXCLUDED.$1');

    // 3. Auto RETURNING id for inserts on tables with SERIAL primary keys
    if (/INSERT\s+INTO\s+(admins|quizzes|quiz_results|reading_stories)\b/i.test(converted) && !/RETURNING/i.test(converted)) {
      converted = converted.trim().replace(/;?$/, ' RETURNING id;');
    }

    // 4. Convert ? placeholders to $1, $2, $3...
    let paramIndex = 1;
    converted = converted.replace(/\?/g, () => `$${paramIndex++}`);

    return converted;
  }

  pool = {
    async query(sql, params = []) {
      const pgSql = translateQuery(sql);
      const res = await pgPool.query(pgSql, params);
      const meta = {
        affectedRows: res.rowCount,
        insertId: res.rows?.[0]?.id || 0,
        fields: res.fields,
      };
      return [res.rows, meta];
    },

    async getConnection() {
      const client = await pgPool.connect();
      return {
        async query(sql, params = []) {
          const pgSql = translateQuery(sql);
          const res = await client.query(pgSql, params);
          const meta = {
            affectedRows: res.rowCount,
            insertId: res.rows?.[0]?.id || 0,
            fields: res.fields,
          };
          return [res.rows, meta];
        },
        release() {
          client.release();
        },
      };
    },

    rawPool: pgPool,
  };
} else {
  // MySQL2 Connection Pool (Default for local development)
  const mysql = require('mysql2/promise');
  pool = mysql.createPool({
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    database: config.db.name,
    waitForConnections: true,
    connectionLimit: config.db.connectionLimit,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0,
  });
}

async function testConnection() {
  try {
    const connection = await pool.getConnection();
    const dbType = isPostgres ? 'PostgreSQL' : 'MySQL';
    logger.info(`✅ Connected to ${dbType} database '${config.db.name}' successfully.`);
    connection.release();
    return true;
  } catch (error) {
    const dbType = isPostgres ? 'PostgreSQL' : 'MySQL';
    logger.error(`❌ ${dbType} database connection failed:`, error.message);
    if (error.code === 'ER_BAD_DB_ERROR' || error.code === '3D000') {
      logger.warn(`💡 Database '${config.db.name}' does not exist yet. Run the init script to create and seed it.`);
    } else if (error.code === 'ECONNREFUSED') {
      logger.warn(`💡 Ensure ${dbType} is running on ${config.db.host}:${config.db.port}.`);
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR' || error.code === '28P01') {
      logger.warn(`💡 Check your DB_USER / DB_PASSWORD credentials in backend/.env.`);
    }
    return false;
  }
}

module.exports = {
  pool,
  testConnection,
};
