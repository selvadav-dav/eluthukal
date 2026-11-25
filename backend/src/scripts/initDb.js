/**
 * AGARAM Database Initialization Script
 * Connects to MySQL, creates eluthukal, and executes schema & seeds safely.
 */
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'root',
  multipleStatements: true,
};

const DB_NAME = process.env.DB_NAME || 'eluthukal';

async function initDatabase() {
  console.log('====================================================');
  console.log('🚀 Initializing AGARAM Database on MySQL...');
  console.log(`📡 Connecting to host: ${DB_CONFIG.host}:${DB_CONFIG.port} as user: ${DB_CONFIG.user}`);
  console.log('====================================================');

  let connection;
  try {
    connection = await mysql.createConnection(DB_CONFIG);
    console.log('✅ Connected to MySQL server successfully.');

    // 1. Create fresh database
    console.log(`📦 Recreating clean database '${DB_NAME}'...`);
    await connection.query(`DROP DATABASE IF EXISTS \`${DB_NAME}\`;`);
    await connection.query(
      `CREATE DATABASE \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
    );
    await connection.query(`USE \`${DB_NAME}\`;`);
    console.log(`✅ Using database '${DB_NAME}'.`);

    // 2. Read schema file
    const schemaPath = path.join(__dirname, '../../database/schema.sql');
    if (!fs.existsSync(schemaPath)) {
      throw new Error(`Schema file not found at: ${schemaPath}`);
    }
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');

    // 3. Execute schema
    console.log('🔨 Executing schema and initial seed data...');
    // Split SQL into individual statements while removing comments
    const statements = schemaSql
      .replace(/--.*$/gm, '')
      .split(';')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    for (const stmt of statements) {
      try {
        await connection.query(stmt);
      } catch (stmtErr) {
        console.error('❌ Failed SQL Statement:');
        console.error(stmt.substring(0, 300));
        throw stmtErr;
      }
    }
    console.log('✅ Tables, foreign keys, indexes, and initial content created.');

    // 4. Ensure admin password hash is fresh & valid
    const salt = await bcrypt.genSalt(10);
    const superAdminPassword = process.env.SUPERADMIN_PASSWORD || 'Admin@123';
    const hash = await bcrypt.hash(superAdminPassword, salt);

    await connection.query(
      `INSERT INTO admins (username, email, password_hash, role, full_name, is_active)
       VALUES (?, ?, ?, 'super_admin', 'ELUTHUKAL Super Admin', TRUE)
       ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash);`,
      ['superadmin', 'admin@agaram.app', hash]
    );
    console.log(`👤 Super Admin verified. Username: 'superadmin', Default Password: '${superAdminPassword}'`);

    // 5. Seed Cloudinary Letter Videos
    try {
      const seedVideosScript = path.join(__dirname, 'seedCloudinaryVideos.js');
      if (fs.existsSync(seedVideosScript)) {
        console.log('🎬 Seeding Cloudinary letter videos...');
        const { execSync } = require('child_process');
        execSync(`node "${seedVideosScript}"`, { stdio: 'inherit' });
      }
    } catch (vidErr) {
      console.warn('⚠️ Video seeding notice:', vidErr.message);
    }

    console.log('====================================================');
    console.log('🎉 AGARAM Database setup completed successfully!');
    console.log('====================================================');
  } catch (error) {
    console.error('❌ Database initialization error:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.error('👉 Make sure MySQL service is running on your system.');
    } else if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('👉 Please check DB_USER and DB_PASSWORD in backend/.env.');
    }
    process.exitCode = 1;
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

if (require.main === module) {
  initDatabase();
}

module.exports = initDatabase;
