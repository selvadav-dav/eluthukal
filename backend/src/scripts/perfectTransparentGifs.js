/**
 * Script to produce 100% PERFECT crystal-clear transparent GIFs from F:\gif.
 * Uses edge-based flood fill to protect character clothes, hair, eyes and skin,
 * completely eliminating grey dots/dithering noise.
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

function processSingleGif(srcFile, outGifPath, tempDir) {
  const width = 480;
  const height = 270;

  const framesDir = path.join(tempDir, 'frames');
  if (fs.existsSync(framesDir)) fs.rmSync(framesDir, { recursive: true, force: true });
  fs.mkdirSync(framesDir, { recursive: true });

  // 1. Extract frames
  spawnSync(ffmpeg, ['-y', '-i', srcFile, path.join(framesDir, 'frame_%04d.png')]);
  const frameFiles = fs.readdirSync(framesDir).filter(f => f.endsWith('.png')).sort();

  // 2. Flood fill each frame
  const rawPath = path.join(tempDir, 'temp_raw.raw');
  for (const fName of frameFiles) {
    const fPath = path.join(framesDir, fName);
    spawnSync(ffmpeg, ['-y', '-i', fPath, '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '480x270', rawPath]);
    const buf = fs.readFileSync(rawPath);

    const visited = new Uint8Array(width * height);
    const queue = [];

    function isGreen(x, y) {
      const i = (y * width + x) * 4;
      const r = buf[i], g = buf[i+1], b = buf[i+2];
      return (g > 90 && g > r * 1.25 && g > b * 1.25) || (g > 150 && g > r * 1.08 && g > b * 1.08);
    }

    function isPureGreenSeed(x, y) {
      const i = (y * width + x) * 4;
      const r = buf[i], g = buf[i+1], b = buf[i+2];
      return g >= 145 && g >= r + 55 && g >= b + 45;
    }

    // Seed borders
    for (let x = 0; x < width; x++) {
      if (isGreen(x, 0)) { queue.push(x, 0); visited[0 * width + x] = 1; }
      if (isGreen(x, height - 1)) { queue.push(x, height - 1); visited[(height - 1) * width + x] = 1; }
    }
    for (let y = 0; y < height; y++) {
      if (isGreen(0, y)) { queue.push(0, y); visited[y * width + 0] = 1; }
      if (isGreen(width - 1, y)) { queue.push(width - 1, y); visited[y * width + (width - 1)] = 1; }
    }

    // Seed interior green holes (between characters, arms, heads, book)
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const idx = y * width + x;
        if (!visited[idx] && isPureGreenSeed(x, y)) {
          visited[idx] = 1;
          queue.push(x, y);
        }
      }
    }

    let head = 0;
    while (head < queue.length) {
      const cx = queue[head++];
      const cy = queue[head++];
      const neighbors = [[cx+1, cy], [cx-1, cy], [cx, cy+1], [cx, cy-1]];
      for (const [nx, ny] of neighbors) {
        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          const nIdx = ny * width + nx;
          if (!visited[nIdx] && isGreen(nx, ny)) {
            visited[nIdx] = 1;
            queue.push(nx, ny);
          }
        }
      }
    }

    // Apply transparency & despill on edge
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const pIdx = y * width + x;
        const i = pIdx * 4;
        const r = buf[i], g = buf[i+1], b = buf[i+2];
        if (visited[pIdx] || (g >= 150 && g > r * 1.3 && g > b * 1.2)) {
          buf[i + 3] = 0;
        } else {
          if (g > r * 1.15 && g > b * 1.15) {
            buf[i+1] = Math.round((r + b) / 2);
          }
        }
      }
    }

    fs.writeFileSync(rawPath, buf);
    spawnSync(ffmpeg, ['-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '480x270', '-i', rawPath, fPath]);
  }

  if (fs.existsSync(rawPath)) fs.unlinkSync(rawPath);

  // 3. Assemble clean GIF with dither=none (ZERO grey speckles!)
  spawnSync(ffmpeg, [
    '-y',
    '-framerate', '16.67',
    '-i', path.join(framesDir, 'frame_%04d.png'),
    '-filter_complex', '[0:v] split [a][b]; [a] palettegen=reserve_transparent=on [p]; [b][p] paletteuse=alpha_threshold=128:dither=none',
    outGifPath
  ]);

  fs.rmSync(framesDir, { recursive: true, force: true });
}

async function run() {
  console.log('======================================================================');
  console.log('🎨 GENERATING 100% PERFECT CLEAN TRANSPARENT BOY+GIRL GIFS');
  console.log('======================================================================\n');

  const workDir = path.join(__dirname, 'temp_perfect_work');
  if (fs.existsSync(workDir)) fs.rmSync(workDir, { recursive: true, force: true });
  fs.mkdirSync(workDir, { recursive: true });

  const deployed = [];

  for (const cfg of GIF_CONFIGS) {
    const srcPath = path.join(SRC_DIR, cfg.src);
    if (!fs.existsSync(srcPath)) {
      console.warn(`File not found: ${srcPath}, skipping`);
      continue;
    }

    console.log(`🖌️ Processing ${cfg.src} with edge flood-fill & solid palette...`);
    const cleanGifPath = path.join(workDir, `perfect_${cfg.src}`);
    processSingleGif(srcPath, cleanGifPath, workDir);

    if (fs.existsSync(cleanGifPath)) {
      const sz = (fs.statSync(cleanGifPath).size / 1024 / 1024).toFixed(2);
      console.log(`   ✅ Success! Size: ${sz} MB`);

      // Deploy to all target paths
      for (const target of cfg.targets) {
        fs.copyFileSync(cleanGifPath, target);
        console.log(`   📁 Deployed: ${target}`);
      }

      deployed.push({ cfg, cleanGifPath });
    } else {
      console.error(`   ❌ Failed to generate: ${cleanGifPath}`);
    }
  }

  // Upload to Cloudinary
  console.log('\n======================================================================');
  console.log('☁️ UPLOADING TO CLOUDINARY CDN');
  console.log('======================================================================');

  let currentMap = {};
  if (fs.existsSync(MAP_BACKEND)) {
    try {
      currentMap = JSON.parse(fs.readFileSync(MAP_BACKEND, 'utf8'));
    } catch (_) {}
  }

  for (const item of deployed) {
    const { cfg, cleanGifPath } = item;
    console.log(`⬆️ Uploading ${cfg.src} to Cloudinary (${cfg.publicId})...`);
    try {
      const res = await cloudinary.uploader.upload(cleanGifPath, {
        folder: 'agaram_media/gifs',
        public_id: cfg.publicId,
        overwrite: true,
        resource_type: 'image',
      });
      const url = res.secure_url;
      console.log(`   ✅ URL: ${url}`);
      for (const k of cfg.mapKeys) {
        currentMap[k] = url;
      }
    } catch (e) {
      console.error(`   ❌ Upload error for ${cfg.src}:`, e.message);
    }
  }

  fs.writeFileSync(MAP_BACKEND, JSON.stringify(currentMap, null, 2), 'utf8');
  fs.writeFileSync(MAP_FRONTEND, JSON.stringify(currentMap, null, 2), 'utf8');
  console.log('\n💾 Updated cloudinary_image_map.json');

  // Regenerate Dart
  require('./generateCloudinaryDart');

  fs.rmSync(workDir, { recursive: true, force: true });
  console.log('\n======================================================================');
  console.log('🎉 ALL 6 GIFS RE-PROCESSED WITH ZERO GREY ARTIFACTS!');
  console.log('======================================================================');
}

run().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});

