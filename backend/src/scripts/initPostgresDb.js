/**
 * AGARAM PostgreSQL Database Initialization Script
 * Connects to PostgreSQL, creates eluthukal if not exists, and executes schema.postgres.sql.
 */
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = parseInt(process.env.DB_PORT, 10) || 5432;
const DB_USER = process.env.DB_USER || process.env.DB_USERNAME || 'postgres';
const DB_PASSWORD = process.env.DB_PASSWORD || process.env.DB_PSSWORD || 'root';
const DB_NAME = process.env.DB_NAME || process.env.DB_DATABASE || 'eluthukal';

async function initPostgresDatabase() {
  console.log('====================================================');
  console.log('🚀 Initializing AGARAM Database on PostgreSQL...');
  console.log(`📡 Connecting to host: ${DB_HOST}:${DB_PORT} as user: ${DB_USER}`);
  console.log('====================================================');

  // 1. Connect to postgres to ensure eluthukal exists
  let createdDb = false;
  try {
    const adminClient = new Client({
      host: DB_HOST,
      port: DB_PORT,
      user: DB_USER,
      password: DB_PASSWORD,
      database: 'postgres',
    });
    await adminClient.connect();
    console.log('✅ Connected to PostgreSQL server.');

    const checkDb = await adminClient.query(
      `SELECT 1 FROM pg_database WHERE datname = $1`,
      [DB_NAME]
    );

    if (checkDb.rows.length === 0) {
      console.log(`📦 Creating database '${DB_NAME}'...`);
      await adminClient.query(`CREATE DATABASE "${DB_NAME}"`);
      console.log(`✅ Database '${DB_NAME}' created.`);
    } else {
      console.log(`ℹ️ Database '${DB_NAME}' already exists.`);
    }
    await adminClient.end();
  } catch (err) {
    console.warn(`⚠️ Note: Could not auto-create database via 'postgres' db: ${err.message}. Will attempt direct connection to '${DB_NAME}'.`);
  }

  // 2. Connect to target eluthukal
  const dbClient = new Client({
    host: DB_HOST,
    port: DB_PORT,
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME,
  });

  try {
    await dbClient.connect();
    console.log(`✅ Connected directly to '${DB_NAME}'.`);

    const schemaPath = path.join(__dirname, '../../database/schema.postgres.sql');
    if (!fs.existsSync(schemaPath)) {
      throw new Error(`Schema file not found at: ${schemaPath}`);
    }
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');

    console.log('🔨 Executing PostgreSQL schema and seed data...');
    await dbClient.query(schemaSql);
    console.log('✅ Schema and seed data executed successfully!');

    // 3. Ensure superadmin password hash is verified
    const bcrypt = require('bcryptjs');
    const salt = await bcrypt.genSalt(10);
    const superAdminPassword = process.env.SUPERADMIN_PASSWORD || 'Admin@123';
    const hash = await bcrypt.hash(superAdminPassword, salt);
    await dbClient.query(
      `INSERT INTO admins (username, email, password_hash, role, full_name, is_active)
       VALUES ('superadmin', 'admin@agaram.app', $1, 'super_admin', 'AGARAM Super Admin', TRUE)
       ON CONFLICT (username) DO UPDATE SET password_hash = EXCLUDED.password_hash;`,
      [hash]
    );

    // Verify row counts
    const letterCount = await dbClient.query('SELECT COUNT(*) as count FROM letters');
    const userCount = await dbClient.query('SELECT COUNT(*) as count FROM users');
    const adminCount = await dbClient.query('SELECT COUNT(*) as count FROM admins');

    console.log('----------------------------------------------------');
    console.log(`📊 Letters Seeded : ${letterCount.rows[0].count}`);
    console.log(`📊 Users Seeded   : ${userCount.rows[0].count}`);
    console.log(`📊 Admins Seeded  : ${adminCount.rows[0].count}`);
    console.log(`👤 Super Admin verified: Username: 'superadmin', Password: '${superAdminPassword}'`);
    console.log('====================================================');
    console.log('🎉 PostgreSQL Database is ready for AGARAM!');
    console.log('====================================================');
  } catch (err) {
    console.error('❌ Failed executing schema on target database:', err.message);
    throw err;
  } finally {
    await dbClient.end();
  }
}

initPostgresDatabase().catch((err) => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});
