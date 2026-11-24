const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });
const cloudinary = require('../config/cloudinary');

const filePath = 'F:\\games\\balloon game.gif';
const MAP_BACKEND = path.join(__dirname, '../../database/cloudinary_image_map.json');
const MAP_FRONTEND = path.join(__dirname, '../../../frontend/assets/cloudinary_image_map.json');

async function upload() {
  console.log('Uploading F:\\games\\balloon game.gif to Cloudinary...');
  const result = await cloudinary.uploader.upload(filePath, {
    folder: 'agaram_media/gifs',
    public_id: 'gif_balloon_game',
    overwrite: true,
    resource_type: 'image',
  });

  console.log('Upload Success! Secure URL:', result.secure_url);

  const keys = [
    'assets/Gif/balloon game.gif',
    'Gif/balloon game.gif',
    'balloon game.gif',
  ];

  if (fs.existsSync(MAP_BACKEND)) {
    const map = JSON.parse(fs.readFileSync(MAP_BACKEND, 'utf8'));
    for (const k of keys) {
      map[k] = result.secure_url;
    }
    fs.writeFileSync(MAP_BACKEND, JSON.stringify(map, null, 2), 'utf8');
    console.log('Updated backend mapping');
  }

  if (fs.existsSync(MAP_FRONTEND)) {
    const map = JSON.parse(fs.readFileSync(MAP_FRONTEND, 'utf8'));
    for (const k of keys) {
      map[k] = result.secure_url;
    }
    fs.writeFileSync(MAP_FRONTEND, JSON.stringify(map, null, 2), 'utf8');
    console.log('Updated frontend mapping');
  }

  console.log('Cloudinary upload and mapping completed successfully.');
}

upload().catch(console.error);
