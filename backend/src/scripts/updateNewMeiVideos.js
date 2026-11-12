/**
 * Script to update database with the NEW Mei Eluthu videos (Nov 10)
 * and delete the OLD Mei Eluthu videos (Oct 5) from Cloudinary.
 */
const { pool } = require('../config/db');
const cloudinary = require('cloudinary').v2;
const config = require('../config/env');

cloudinary.config({
  cloud_name: config.cloudinary.cloudName,
  api_key: config.cloudinary.apiKey,
  api_secret: config.cloudinary.apiSecret,
});

const NEW_MEI_VIDEOS = [
  { id: 'vid_mei_1', letter: 'க்', word: 'காக்கை', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296004/agaram_media/videos/pqpts1qxtzsdcyukwdxz.mp4' },
  { id: 'vid_mei_2', letter: 'ங்', word: 'தங்கம்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296030/agaram_media/videos/bopiqpsmufwaw2msbect.mp4' },
  { id: 'vid_mei_3', letter: 'ச்', word: 'பச்சை', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296047/agaram_media/videos/pxiam1h6h5vcalsc41dg.mp4' },
  { id: 'vid_mei_4', letter: 'ஞ்', word: 'ஊஞ்சல்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296067/agaram_media/videos/u5wjop3dstrkytbpmcra.mp4' },
  { id: 'vid_mei_5', letter: 'ட்', word: 'பட்டம்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296084/agaram_media/videos/f5ehl4mzblzx6dlxby6n.mp4' },
  { id: 'vid_mei_6', letter: 'ண்', word: 'வண்டி', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296110/agaram_media/videos/s0sdihyms20tkdbemxfh.mp4' },
  { id: 'vid_mei_7', letter: 'த்', word: 'நத்தை', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296126/agaram_media/videos/cytnbojzsyusmhepnc22.mp4' },
  { id: 'vid_mei_8', letter: 'ந்', word: 'பந்து', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296145/agaram_media/videos/c7bpoyobw4z6iu68meww.mp4' },
  { id: 'vid_mei_9', letter: 'ப்', word: 'கப்பல்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296168/agaram_media/videos/atvobggfaee5eyjutnbj.mp4' },
  { id: 'vid_mei_10', letter: 'ம்', word: 'மரம்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296184/agaram_media/videos/zc3vvfhpzipuaa9imdfs.mp4' },
  { id: 'vid_mei_11', letter: 'ய்', word: 'பாய்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296205/agaram_media/videos/mjlpp8nvsdumyzgmijax.mp4' },
  { id: 'vid_mei_12', letter: 'ர்', word: 'தேர்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296223/agaram_media/videos/k1hg62yufq8k0xgdtft7.mp4' },
  { id: 'vid_mei_13', letter: 'ல்', word: 'சேவல்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296242/agaram_media/videos/ydotvfwaszlrdncnytt9.mp4' },
  { id: 'vid_mei_14', letter: 'வ்', word: 'செவ்வானம்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296267/agaram_media/videos/kjtralqggt2sfdjrhikd.mp4' },
  { id: 'vid_mei_15', letter: 'ழ்', letterName: 'யாழ்', word: 'யாழ்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296300/agaram_media/videos/ce9bczrowclxnupywuul.mp4' },
  { id: 'vid_mei_16', letter: 'ள்', word: 'வாள்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296323/agaram_media/videos/raul5bd6ak5gdepl7len.mp4' },
  { id: 'vid_mei_17', letter: 'ற்', word: 'வெற்றிலை', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296347/agaram_media/videos/iglzk3luumpgfsq2bq35.mp4' },
  { id: 'vid_mei_18', letter: 'ன்', word: 'மீன்', url: 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296366/agaram_media/videos/dgtpxplitixesbfjnnsv.mp4' },
];

const OLD_MEI_PUBLIC_IDS = [
  'agaram_media/videos/fg18xjxo2q4p9wsyfvpo',
  'agaram_media/videos/zjmzubpswzwhlkvl5ojn',
  'agaram_media/videos/fsagxkudps6vh6lybuno',
  'agaram_media/videos/ykprwmafp4al32alrsa6',
  'agaram_media/videos/sd0kk4jfqz572vowz63j',
  'agaram_media/videos/mrj9929eyumtpsvwvk49',
  'agaram_media/videos/xayiuz964o3qwkbtpjkr',
  'agaram_media/videos/jb0av76qcjimjylof1oh',
  'agaram_media/videos/hgdp4p7sjj4zuemigges',
  'agaram_media/videos/rvu5tcop5a4inyy2myty',
  'agaram_media/videos/pzjgq9yxjcf3xcyaxbbh',
  'agaram_media/videos/k4tqtli6kuwysaqx7muw',
  'agaram_media/videos/p8fcozkulcpzcpvdcsgd',
  'agaram_media/videos/jkhfxzw7ksobhb7hawpv',
  'agaram_media/videos/iinovuxh3dnlsajorpsp',
  'agaram_media/videos/ibjoez182v1nsagtyedb',
  'agaram_media/videos/umbutwkkjznope99qwnw',
  'agaram_media/videos/asrp5x7m9ynstmklzx40',
];

async function updateVideos() {
  console.log('🔄 1. Updating MySQL database with new Mei Eluthu videos...');
  for (let i = 0; i < NEW_MEI_VIDEOS.length; i++) {
    const item = NEW_MEI_VIDEOS[i];
    const displayOrder = i + 1;
    const description = `மெய் எழுத்து ${item.letter} (${item.word})`;

    await pool.query(
      `INSERT INTO videos 
        (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
       VALUES (?, ?, ?, 'மெய் எழுத்துகள்', '00:15', ?, ?, ?, TRUE)
       ON DUPLICATE KEY UPDATE 
         title = VALUES(title),
         description = VALUES(description),
         category = VALUES(category),
         video_url = VALUES(video_url),
         thumbnail_emoji = VALUES(thumbnail_emoji),
         display_order = VALUES(display_order),
         is_published = TRUE`,
      [item.id, item.letter, description, `✍️${item.letter}`, item.url, displayOrder]
    );
    console.log(`  ✅ Updated ${item.id} -> ${item.letter} (${item.word})`);
  }

  // Ensure Aytham video is in MySQL
  await pool.query(
    `INSERT INTO videos 
      (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
     VALUES (?, ?, ?, 'ஆய்த எழுத்து', '00:12', '🎬ஃ', ?, 31, TRUE)
     ON DUPLICATE KEY UPDATE 
       title = VALUES(title),
       description = VALUES(description),
       category = VALUES(category),
       video_url = VALUES(video_url),
       display_order = 31,
       is_published = TRUE`,
    [
      'vid_1794304563578',
      'ஆயுத எழுத்துப் பாடல்',
      'முப்புள்ளி கொண்ட தனித்தமிழ் ஆய்த எழுத்து ஃ சிறப்புப் பாடல்',
      'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794304503/agaram_media/videos/kw0jpwrizojzqaqjght8.mp4',
    ]
  );
  console.log('  ✅ Verified Aytham video in MySQL');

  // Verify database count
  const [dbVideos] = await pool.query('SELECT id, title, category, video_url FROM videos ORDER BY display_order ASC');
  console.log(`\n📊 Total videos now in MySQL: ${dbVideos.length}`);

  // Delete old videos from Cloudinary
  console.log('\n🗑️ 2. Deleting old Mei Eluthu videos from Cloudinary...');
  for (const pubId of OLD_MEI_PUBLIC_IDS) {
    try {
      const delRes = await cloudinary.uploader.destroy(pubId, { resource_type: 'video' });
      console.log(`  Deleted ${pubId}: ${delRes.result}`);
    } catch (err) {
      console.warn(`  Failed to delete ${pubId}:`, err.message);
    }
  }

  console.log('\n🎉 Finished updating videos in MySQL and deleting old videos from Cloudinary!');
  process.exit(0);
}

updateVideos().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});

