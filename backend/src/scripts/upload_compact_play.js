const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

const filePath = path.join(__dirname, '../../../frontend/assets/images/play.gif');

async function upload() {
  console.log('Uploading compact play.gif to Cloudinary...');
  const res = await cloudinary.uploader.upload(filePath, {
    public_id: 'gif_play',
    folder: 'agaram_media/gifs',
    resource_type: 'image',
    overwrite: true,
    invalidate: true
  });
  console.log('Upload successful! Secure URL:', res.secure_url);

  // Update cloudinary_image_map.json
  const mapPath = path.join(__dirname, '../../database/cloudinary_image_map.json');
  const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'));

  const keysToUpdate = [
    'Gif/play.gif',
    'Gif/play_transparent.gif',
    'assets/Gif/games.gif',
    'assets/Gif/play.gif',
    'assets/Gif/play_transparent.gif',
    'assets/images/games.gif',
    'assets/images/play.gif',
    'games.gif',
    'play.gif',
    'play_transparent.gif'
  ];

  for (const k of keysToUpdate) {
    map[k] = res.secure_url;
  }

  fs.writeFileSync(mapPath, JSON.stringify(map, null, 2), 'utf8');
  console.log('Updated cloudinary_image_map.json');

  // Regenerate cloudinary_media.dart
  require('./generateCloudinaryDart.js');
  console.log('Regenerated cloudinary_media.dart successfully!');
}

upload().catch(err => {
  console.error('Upload failed:', err);
  process.exit(1);
});

