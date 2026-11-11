/**
 * Script to remove green screen from new boy+girl GIFs in F:\gif,
 * deploy them to frontend assets, upload them to Cloudinary CDN,
 * and update the image map and Dart helper.
 */
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const ffmpeg = require('../../../backend/node_modules/ffmpeg-static');
const cloudinary = require('../config/cloudinary');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const SRC_DIR = 'F:/gif';
const FRONTEND_DIR = path.resolve(__dirname, '../../../frontend');
const GIF_DIR = path.join(FRONTEND_DIR, 'assets/Gif');
const IMAGES_DIR = path.join(FRONTEND_DIR, 'assets/images');
const MAP_BACKEND = path.join(__dirname, '../../database/cloudinary_image_map.json');
const MAP_FRONTEND = path.join(FRONTEND_DIR, 'assets/cloudinary_image_map.json');

const GIF_CONFIGS = [
  {
    src: 'vanakam.gif',
    publicId: 'gif_vanakam',
    targets: [
      path.join(IMAGES_DIR, 'vanakam.gif'),
      path.join(GIF_DIR, 'vanakam.gif'),
      path.join(GIF_DIR, 'vanakam_transparent.gif'),
    ],
    mapKeys: [
      'assets/images/vanakam.gif',
      'assets/Gif/vanakam.gif',
      'assets/Gif/vanakam_transparent.gif',
      'vanakam.gif',
      'vanakam_transparent.gif',
    ]
  },
  {
    src: 'reading.gif',
    publicId: 'gif_reading',
    targets: [
      path.join(IMAGES_DIR, 'reading.gif'),
      path.join(GIF_DIR, 'reading.gif'),
      path.join(GIF_DIR, 'reading_transparent.gif'),
    ],
    mapKeys: [
      'assets/images/reading.gif',
      'assets/Gif/reading.gif',
      'assets/Gif/reading_transparent.gif',
      'reading.gif',
      'reading_transparent.gif',
    ]
  },
  {
    src: 'writing.gif',
    publicId: 'gif_writing',
    targets: [
      path.join(IMAGES_DIR, 'writing.gif'),
      path.join(GIF_DIR, 'writing.gif'),
      path.join(GIF_DIR, 'writing_transparent.gif'),
    ],
    mapKeys: [
      'assets/images/writing.gif',
      'assets/Gif/writing.gif',
      'assets/Gif/writing_transparent.gif',
      'writing.gif',
      'writing_transparent.gif',
    ]
  },
  {
    src: 'games.gif',
    publicId: 'gif_play',
    targets: [
      path.join(IMAGES_DIR, 'play.gif'),
      path.join(IMAGES_DIR, 'games.gif'),
      path.join(GIF_DIR, 'play.gif'),
      path.join(GIF_DIR, 'games.gif'),
      path.join(GIF_DIR, 'play_transparent.gif'),
    ],
    mapKeys: [
      'assets/images/play.gif',
      'assets/images/games.gif',
      'assets/Gif/play.gif',
      'assets/Gif/games.gif',
      'assets/Gif/play_transparent.gif',
      'play.gif',
      'games.gif',
      'play_transparent.gif',
    ]
  },
  {
    src: 'video.gif',
    publicId: 'gif_video',
    targets: [
      path.join(IMAGES_DIR, 'video.gif'),
      path.join(GIF_DIR, 'video.gif'),
      path.join(GIF_DIR, 'video_transparent.gif'),
    ],
    mapKeys: [
      'assets/images/video.gif',
      'assets/Gif/video.gif',
      'assets/Gif/video_transparent.gif',
      'video.gif',
      'video_transparent.gif',
    ]
  },
  {
    src: 'question.gif',
    publicId: 'gif_quiz',
    targets: [
      path.join(IMAGES_DIR, 'quiz.gif'),
      path.join(IMAGES_DIR, 'question.gif'),
      path.join(GIF_DIR, 'quiz.gif'),
      path.join(GIF_DIR, 'question.gif'),
      path.join(GIF_DIR, 'quiz_transparent.gif'),
    ],
    mapKeys: [
      'assets/images/quiz.gif',
      'assets/images/question.gif',
      'assets/Gif/quiz.gif',
      'assets/Gif/question.gif',
      'assets/Gif/quiz_transparent.gif',
      'quiz.gif',
      'question.gif',
      'quiz_transparent.gif',
    ]
  }
];

async function run() {
  console.log('======================================================================');
  console.log('🎬 PROCESSING NEW BOY+GIRL GREENSCREEN GIFS');
  console.log('======================================================================\n');

  const tempDir = path.join(__dirname, 'temp_gif_processed');
  if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir, { recursive: true });

  const deployedGifs = [];

  for (const item of GIF_CONFIGS) {
    const srcPath = path.join(SRC_DIR, item.src);
    if (!fs.existsSync(srcPath)) {
      console.warn(`⚠️ Source file not found: ${srcPath}, skipping...`);
      continue;
    }

    console.log(`\n🔄 Processing ${item.src} (removing greenscreen)...`);
    const tempOut = path.join(tempDir, `clean_${item.src}`);

    // FFmpeg colorkey filter + transparent palette
    const filter = '[0:v] colorkey=0x00d800:0.38:0.1,split [a][b]; [a] palettegen=reserve_transparent=on:transparency_color=00ff00 [p]; [b][p] paletteuse=alpha_threshold=128:dither=bayer';

    const res = spawnSync(ffmpeg, [
      '-y',
      '-i', srcPath,
      '-filter_complex', filter,
      tempOut
    ]);

    if (res.status !== 0 || !fs.existsSync(tempOut)) {
      console.error(`❌ Failed to process ${item.src}:`, res.stderr?.toString());
      continue;
    }

    const stat = fs.statSync(tempOut);
    console.log(`   ✨ Generated transparent GIF: ${(stat.size / 1024 / 1024).toFixed(2)} MB`);

    // Copy to all target locations
    for (const targetPath of item.targets) {
      const parentDir = path.dirname(targetPath);
      if (!fs.existsSync(parentDir)) fs.mkdirSync(parentDir, { recursive: true });
      fs.copyFileSync(tempOut, targetPath);
      console.log(`   📁 Saved: ${targetPath}`);
    }

    deployedGifs.push({
      config: item,
      localFile: tempOut
    });
  }

  // Upload to Cloudinary
  console.log('\n======================================================================');
  console.log('☁️ UPLOADING PROCESSED GIFS TO CLOUDINARY');
  console.log('======================================================================');

  let currentMap = {};
  if (fs.existsSync(MAP_BACKEND)) {
    try {
      currentMap = JSON.parse(fs.readFileSync(MAP_BACKEND, 'utf8'));
    } catch (_) {}
  }

  for (const d of deployedGifs) {
    const { config, localFile } = d;
    console.log(`⬆️ Uploading ${config.src} to Cloudinary (public_id: ${config.publicId})...`);
    try {
      const result = await cloudinary.uploader.upload(localFile, {
        folder: 'agaram_media/gifs',
        public_id: config.publicId,
        overwrite: true,
        resource_type: 'image',
      });
      const secureUrl = result.secure_url;
      console.log(`   ✅ Cloudinary URL: ${secureUrl}`);

      // Update map keys
      for (const k of config.mapKeys) {
        currentMap[k] = secureUrl;
      }
    } catch (uploadErr) {
      console.error(`   ❌ Cloudinary upload failed for ${config.src}:`, uploadErr.message);
    }
  }

  // Save updated map JSON files
  const mapStr = JSON.stringify(currentMap, null, 2);
  fs.writeFileSync(MAP_BACKEND, mapStr, 'utf8');
  console.log(`\n💾 Saved: ${MAP_BACKEND}`);
  fs.writeFileSync(MAP_FRONTEND, mapStr, 'utf8');
  console.log(`💾 Saved: ${MAP_FRONTEND}`);

  // Clean temp dir
  fs.rmSync(tempDir, { recursive: true, force: true });

  console.log('\n======================================================================');
  console.log('🎉 ALL 6 BOY+GIRL GIFS PROCESSED, DEPLOYED & CLOUDINARY UPDATED!');
  console.log('======================================================================');
}

run().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});

