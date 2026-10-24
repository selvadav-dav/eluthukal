const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const ffmpeg = require('ffmpeg-static');

const FRONTEND_DIR = path.resolve(__dirname, '../../../frontend');
const GIF_DIR = path.join(FRONTEND_DIR, 'assets/Gif');
const IMAGES_DIR = path.join(FRONTEND_DIR, 'assets/images');
const INPUT_GIF = path.join(GIF_DIR, 'vanakam.gif');
const BACKUP_RAW_GIF = path.join(GIF_DIR, 'vanakam_raw_greenscreen.gif');

const TEMP_FRAMES_DIR = path.join(__dirname, 'temp_vanakam_frames');
const TEMP_CLEAN_DIR = path.join(__dirname, 'temp_vanakam_clean');

function run() {
  console.log('======================================================================');
  console.log('🎬 REMOVING GREEN BACKGROUND FROM vanakam.gif');
  console.log('======================================================================\n');

  if (!fs.existsSync(INPUT_GIF)) {
    console.error('File not found:', INPUT_GIF);
    process.exit(1);
  }

  // Backup original green-screen gif
  if (!fs.existsSync(BACKUP_RAW_GIF)) {
    fs.copyFileSync(INPUT_GIF, BACKUP_RAW_GIF);
    console.log(`📦 Saved backup to ${BACKUP_RAW_GIF}`);
  }

  // Clean temp dirs
  [TEMP_FRAMES_DIR, TEMP_CLEAN_DIR].forEach(dir => {
    if (fs.existsSync(dir)) {
      fs.rmSync(dir, { recursive: true, force: true });
    }
    fs.mkdirSync(dir, { recursive: true });
  });

  // 1. Extract all frames
  console.log('Extracting frames from vanakam.gif...');
  const extractRes = spawnSync(ffmpeg, [
    '-y',
    '-i', BACKUP_RAW_GIF,
    path.join(TEMP_FRAMES_DIR, 'frame_%04d.png')
  ]);
  if (extractRes.status !== 0) {
    console.error('Failed to extract frames:', extractRes.stderr.toString());
    process.exit(1);
  }

  const frameFiles = fs.readdirSync(TEMP_FRAMES_DIR).filter(f => f.endsWith('.png')).sort();
  console.log(`Extracted ${frameFiles.length} frames.`);

  // 2. Process each frame
  console.log('Processing each frame with edge-preserving flood fill...');
  const width = 270;
  const height = 480;

  for (let idx = 0; idx < frameFiles.length; idx++) {
    const fName = frameFiles[idx];
    const inFramePath = path.join(TEMP_FRAMES_DIR, fName);
    const rawFrameIn = path.join(TEMP_FRAMES_DIR, 'temp_raw.raw');
    const outFramePath = path.join(TEMP_CLEAN_DIR, fName);

    // Convert frame to raw RGBA
    spawnSync(ffmpeg, ['-y', '-i', inFramePath, '-f', 'rawvideo', '-pix_fmt', 'rgba', rawFrameIn]);

    const buf = fs.readFileSync(rawFrameIn);
    const visited = new Uint8Array(width * height);
    const queue = [];

    function isGreenPixel(x, y) {
      const i = (y * width + x) * 4;
      const r = buf[i];
      const g = buf[i+1];
      const b = buf[i+2];

      // Green screen background: G is dominant over both R and B
      return (g > 65 && g > r * 1.15 && g > b * 1.15) || (g > 150 && g > r && g > b);
    }

    // Seed borders
    for (let x = 0; x < width; x++) {
      if (isGreenPixel(x, 0)) { queue.push(x, 0); visited[0 * width + x] = 1; }
      if (isGreenPixel(x, height - 1)) { queue.push(x, height - 1); visited[(height - 1) * width + x] = 1; }
    }
    for (let y = 0; y < height; y++) {
      if (isGreenPixel(0, y)) { queue.push(0, y); visited[y * width + 0] = 1; }
      if (isGreenPixel(width - 1, y)) { queue.push(width - 1, y); visited[y * width + (width - 1)] = 1; }
    }

    // BFS Flood Fill
    let head = 0;
    while (head < queue.length) {
      const cx = queue[head++];
      const cy = queue[head++];

      const neighbors = [
        [cx + 1, cy],
        [cx - 1, cy],
        [cx, cy + 1],
        [cx, cy - 1]
      ];

      for (const [nx, ny] of neighbors) {
        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          const nIdx = ny * width + nx;
          if (!visited[nIdx] && isGreenPixel(nx, ny)) {
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
        if (visited[pIdx]) {
          buf[i + 3] = 0; // Transparent
        } else {
          // Despill green fringe around boundary
          const r = buf[i];
          const g = buf[i+1];
          const b = buf[i+2];
          if (g > r * 1.05 && g > b * 1.05) {
            buf[i+1] = Math.max(r, b);
          }
        }
      }
    }

    // Write back RGBA PNG
    const rawFrameOut = path.join(TEMP_FRAMES_DIR, 'temp_out.raw');
    fs.writeFileSync(rawFrameOut, buf);

    spawnSync(ffmpeg, [
      '-y',
      '-f', 'rawvideo',
      '-pix_fmt', 'rgba',
      '-s', `${width}x${height}`,
      '-i', rawFrameOut,
      outFramePath
    ]);

    fs.unlinkSync(rawFrameIn);
    fs.unlinkSync(rawFrameOut);

    if ((idx + 1) % 15 === 0 || idx === frameFiles.length - 1) {
      console.log(`  Processed frame ${idx + 1} / ${frameFiles.length}`);
    }
  }

  // 3. Assemble frames into Transparent GIF
  console.log('\nAssembling transparent frames into high quality GIF with palette optimization...');
  const tempOutGif = path.join(__dirname, 'vanakam_transparent_result.gif');

  // Palettegen & paletteuse filter with transparency
  const filter = '[0:v] split [a][b]; [a] palettegen=reserve_transparent=on:transparency_color=00ff00 [p]; [b][p] paletteuse=alpha_threshold=128:dither=bayer';

  const assembleRes = spawnSync(ffmpeg, [
    '-y',
    '-framerate', '16.67',
    '-i', path.join(TEMP_CLEAN_DIR, 'frame_%04d.png'),
    '-filter_complex', filter,
    tempOutGif
  ]);

  if (assembleRes.status !== 0 || !fs.existsSync(tempOutGif)) {
    console.error('Failed to assemble transparent GIF:', assembleRes.stderr.toString());
    process.exit(1);
  }

  const statResult = fs.statSync(tempOutGif);
  console.log(`Generated transparent GIF: ${(statResult.size / (1024 * 1024)).toFixed(2)} MB`);

  // 4. Copy to target destinations
  const targets = [
    path.join(GIF_DIR, 'vanakam_transparent.gif'),
    path.join(GIF_DIR, 'vanakam.gif'),
    path.join(IMAGES_DIR, 'vanakam.gif')
  ];

  for (const t of targets) {
    fs.copyFileSync(tempOutGif, t);
    console.log(`✅ Saved to: ${t}`);
  }

  // Clean temp dirs
  fs.rmSync(TEMP_FRAMES_DIR, { recursive: true, force: true });
  fs.rmSync(TEMP_CLEAN_DIR, { recursive: true, force: true });
  fs.unlinkSync(tempOutGif);

  console.log('\n======================================================================');
  console.log('🎉 BACKGROUND REMOVAL COMPLETE & DEPLOYED!');
  console.log('======================================================================');
}

run();
