/**
 * Script to upload all app images (frontend assets and backend uploads) to Cloudinary
 * and generate a JSON mapping + update database records.
 */
const fs = require('fs');
const path = require('path');
const cloudinary = require('../config/cloudinary');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const FRONTEND_IMAGES_DIR = path.join(__dirname, '../../../frontend/assets/images');
const BACKEND_IMAGES_DIR = path.join(__dirname, '../../uploads/images');

const DB_CONFIG = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'root',
  database: process.env.DB_NAME || 'eluthukal',
};

async function uploadFile(filePath, customPublicId) {
  try {
    const result = await cloudinary.uploader.upload(filePath, {
      folder: 'agaram_media/images',
      public_id: customPublicId,
      overwrite: true,
      resource_type: 'image',
    });
    return result.secure_url;
  } catch (err) {
    console.error(`❌ Failed to upload ${filePath}:`, err.message);
    return null;
  }
}

async function run() {
  console.log('====================================================');
  console.log('☁️ Starting Cloudinary Image Upload for AGARAM');
  console.log('====================================================');

  const imageMap = {};
  const failedUploads = [];

  // 1. Frontend assets
  if (fs.existsSync(FRONTEND_IMAGES_DIR)) {
    const frontendFiles = fs.readdirSync(FRONTEND_IMAGES_DIR);
    console.log(`📁 Found ${frontendFiles.length} files in frontend assets/images`);

    for (const file of frontendFiles) {
      const ext = path.extname(file).toLowerCase();
      if (!['.png', '.jpg', '.jpeg', '.webp', '.svg', '.gif'].includes(ext)) {
        continue;
      }
      const fullPath = path.join(FRONTEND_IMAGES_DIR, file);
      const baseName = path.basename(file, ext).replace(/[^a-zA-Z0-9_-]/g, '_');
      const publicId = `frontend_${baseName}`;

      console.log(`⬆️ Uploading frontend asset: ${file} ...`);
      const url = await uploadFile(fullPath, publicId);
      if (url) {
        imageMap[`assets/images/${file}`] = url;
        imageMap[file] = url;
        console.log(`   ✅ ${url}`);
      } else {
        failedUploads.push(file);
      }
    }
  }

  // 2. Backend uploads
  if (fs.existsSync(BACKEND_IMAGES_DIR)) {
    const backendFiles = fs.readdirSync(BACKEND_IMAGES_DIR);
    console.log(`📁 Found ${backendFiles.length} files in backend uploads/images`);

    for (const file of backendFiles) {
      const ext = path.extname(file).toLowerCase();
      if (!['.png', '.jpg', '.jpeg', '.webp', '.svg', '.gif'].includes(ext)) {
        continue;
      }
      const fullPath = path.join(BACKEND_IMAGES_DIR, file);
      const baseName = path.basename(file, ext).replace(/[^a-zA-Z0-9_-]/g, '_');
      const publicId = `backend_${baseName}`.substring(0, 80);

      console.log(`⬆️ Uploading backend upload: ${file} ...`);
      const url = await uploadFile(fullPath, publicId);
      if (url) {
        imageMap[`uploads/images/${file}`] = url;
        imageMap[file] = url;
        console.log(`   ✅ ${url}`);
      } else {
        failedUploads.push(file);
      }
    }
  }

  console.log('====================================================');
  console.log(`🎉 Total images uploaded: ${Object.keys(imageMap).length}`);
  if (failedUploads.length > 0) {
    console.warn(`⚠️ Failed: ${failedUploads.length} files`);
  }
  console.log('====================================================');

  // Save mapping to JSON files
  const mapJsonStr = JSON.stringify(imageMap, null, 2);
  const outBackend = path.join(__dirname, '../../database/cloudinary_image_map.json');
  fs.writeFileSync(outBackend, mapJsonStr, 'utf8');
  console.log(`💾 Saved mapping to: ${outBackend}`);

  const outFrontend = path.join(__dirname, '../../../frontend/assets/cloudinary_image_map.json');
  fs.writeFileSync(outFrontend, mapJsonStr, 'utf8');
  console.log(`💾 Saved mapping to: ${outFrontend}`);

  // Try updating database if MySQL is available
  try {
    const conn = await mysql.createConnection(DB_CONFIG);
    console.log('📡 Connected to MySQL, updating image_path in database...');

    for (const [key, url] of Object.entries(imageMap)) {
      if (key.startsWith('assets/images/') || key.startsWith('uploads/images/')) {
        // Update letters
        await conn.query('UPDATE letters SET image_path = ? WHERE image_path = ? OR image_path LIKE ?', [
          url,
          key,
          `%${path.basename(key)}`,
        ]);
        // Update reading stories
        await conn.query('UPDATE reading_stories SET cover_image = ? WHERE cover_image = ? OR cover_image LIKE ?', [
          url,
          key,
          `%${path.basename(key)}`,
        ]);
        // Update reading story pages
        await conn.query('UPDATE reading_story_pages SET image_path = ? WHERE image_path = ? OR image_path LIKE ?', [
          url,
          key,
          `%${path.basename(key)}`,
        ]);
        // Update games
        await conn.query('UPDATE games SET clue_image = ? WHERE clue_image = ? OR clue_image LIKE ?', [
          url,
          key,
          `%${path.basename(key)}`,
        ]);
        // Update quiz questions
        await conn.query('UPDATE quiz_questions SET visual_image = ? WHERE visual_image = ? OR visual_image LIKE ?', [
          url,
          key,
          `%${path.basename(key)}`,
        ]);
        // Update videos
        await conn.query('UPDATE videos SET thumbnail_image = ? WHERE thumbnail_image = ? OR thumbnail_image LIKE ?', [
          url,
          key,
          `%${path.basename(key)}`,
        ]);
      }
    }
    console.log('✅ Database records updated with Cloudinary URLs!');
    await conn.end();
  } catch (dbErr) {
    console.warn('⚠️ Could not update MySQL DB directly (MySQL might not be running or different config):', dbErr.message);
  }
}

run().catch(console.error);
