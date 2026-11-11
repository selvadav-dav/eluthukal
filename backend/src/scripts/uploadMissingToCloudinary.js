/**
 * Script to upload all remaining missing media assets (Game JPGs, GIFs, images)
 * to Cloudinary and update mapping JSONs, Dart service, and database records.
 */
const fs = require('fs');
const path = require('path');
const cloudinary = require('../config/cloudinary');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const MAP_BACKEND = path.join(__dirname, '../../database/cloudinary_image_map.json');
const MAP_FRONTEND = path.join(__dirname, '../../../frontend/assets/cloudinary_image_map.json');

const DIRS = [
  {
    dir: path.join(__dirname, '../../../frontend/assets/images/games'),
    folder: 'agaram_media/games',
    prefix: 'assets/images/games/',
    subPrefix: 'games/',
    idPrefix: 'game_'
  },
  {
    dir: path.join(__dirname, '../../../frontend/assets/Gif'),
    folder: 'agaram_media/gifs',
    prefix: 'assets/Gif/',
    subPrefix: 'Gif/',
    idPrefix: 'gif_'
  },
  {
    dir: path.join(__dirname, '../../../frontend/assets/images'),
    folder: 'agaram_media/images',
    prefix: 'assets/images/',
    subPrefix: '',
    idPrefix: 'frontend_'
  }
];

const VALID_EXTS = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];

async function uploadFileWithRetry(filePath, folder, customPublicId, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const result = await cloudinary.uploader.upload(filePath, {
        folder: folder,
        public_id: customPublicId,
        overwrite: true,
        resource_type: 'image', // handles both static images and animated GIFs
      });
      return result.secure_url;
    } catch (err) {
      const msg = err?.message || err?.error?.message || JSON.stringify(err);
      console.error(`  ⚠️ Attempt ${attempt} failed for ${path.basename(filePath)}: ${msg}`);
      if (attempt === maxRetries) {
        return null;
      }
      // wait 2 seconds before retry
      await new Promise(r => setTimeout(r, 2000));
    }
  }
}

async function run() {
  console.log('====================================================');
  console.log('☁️ Uploading Missing Media Assets to Cloudinary');
  console.log('====================================================');

  let currentMap = {};
  if (fs.existsSync(MAP_BACKEND)) {
    try {
      currentMap = JSON.parse(fs.readFileSync(MAP_BACKEND, 'utf8'));
    } catch (e) {
      console.warn('Could not parse existing map, starting fresh:', e.message);
    }
  }

  const newUploads = [];
  const failedUploads = [];

  for (const group of DIRS) {
    if (!fs.existsSync(group.dir)) continue;

    const files = fs.readdirSync(group.dir);
    for (const file of files) {
      const ext = path.extname(file).toLowerCase();
      if (!VALID_EXTS.includes(ext)) continue;

      const fullPath = path.join(group.dir, file);
      if (fs.statSync(fullPath).isDirectory()) continue;

      const fullKey = `${group.prefix}${file}`;
      // Check if already mapped
      if (currentMap[fullKey]) {
        console.log(`⏩ Already mapped: ${fullKey}`);
        continue;
      }

      const cleanName = path.basename(file, ext)
        .replace(/[^a-zA-Z0-9_-]/g, '_')
        .toLowerCase()
        .substring(0, 60);
      const publicId = `${group.idPrefix}${cleanName}`;

      console.log(`⬆️ Uploading: ${fullKey} (${(fs.statSync(fullPath).size / 1024).toFixed(1)} KB)...`);
      const secureUrl = await uploadFileWithRetry(fullPath, group.folder, publicId);

      if (secureUrl) {
        console.log(`   ✅ ${secureUrl}`);
        currentMap[fullKey] = secureUrl;
        if (group.subPrefix) {
          currentMap[`${group.subPrefix}${file}`] = secureUrl;
        }
        // Also map bare filename if not already mapped
        if (!currentMap[file]) {
          currentMap[file] = secureUrl;
        }
        newUploads.push({ file, key: fullKey, url: secureUrl });
      } else {
        console.error(`   ❌ FAILED: ${fullKey}`);
        failedUploads.push(fullKey);
      }
    }
  }

  console.log('\n====================================================');
  console.log(`🎉 New uploads completed: ${newUploads.length}`);
  console.log(`❌ Failed uploads: ${failedUploads.length}`);
  console.log(`📊 Total keys in map: ${Object.keys(currentMap).length}`);
  console.log('====================================================');

  // Save back to JSON files
  const jsonStr = JSON.stringify(currentMap, null, 2);
  fs.writeFileSync(MAP_BACKEND, jsonStr, 'utf8');
  console.log(`💾 Saved backend map: ${MAP_BACKEND}`);

  fs.writeFileSync(MAP_FRONTEND, jsonStr, 'utf8');
  console.log(`💾 Saved frontend map: ${MAP_FRONTEND}`);

  // Try updating database if MySQL is configured and reachable
  try {
    const DB_CONFIG = {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 3306,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || 'root',
      database: process.env.DB_NAME || 'agaram_db',
      connectTimeout: 4000,
    };
    const conn = await mysql.createConnection(DB_CONFIG);
    console.log('📡 Connected to MySQL, updating database image records...');

    for (const item of newUploads) {
      await conn.query('UPDATE letters SET image_path = ? WHERE image_path = ? OR image_path LIKE ?', [
        item.url, item.key, `%${item.file}`
      ]);
      await conn.query('UPDATE games SET clue_image = ? WHERE clue_image = ? OR clue_image LIKE ?', [
        item.url, item.key, `%${item.file}`
      ]);
      await conn.query('UPDATE quiz_questions SET visual_image = ? WHERE visual_image = ? OR visual_image LIKE ?', [
        item.url, item.key, `%${item.file}`
      ]);
    }
    await conn.end();
    console.log('✅ Database records updated successfully!');
  } catch (dbErr) {
    console.log('ℹ️ Local MySQL update skipped (or offline):', dbErr.message);
  }

  console.log('\n✨ Upload process complete!');
}

run().catch(err => {
  console.error('Fatal upload error:', err);
  process.exit(1);
});
