/**
 * Seed all 31 Cloudinary uploaded videos into MySQL database
 * - 12 Uyir letters (அ முதல் ஔ)
 * - 18 Mei letters (க் முதல் ன்)
 * - 1 Aytham letter (ஃ)
 * - Plus existing sample videos (பாடல்கள் & கதைகள்)
 */
const { pool } = require('../config/db');

const UYIR_LETTERS = [
  { letter: 'அ', word: 'அம்மா', meaning: 'Mother' },
  { letter: 'ஆ', word: 'ஆடு', meaning: 'Goat' },
  { letter: 'இ', word: 'இலை', meaning: 'Leaf' },
  { letter: 'ஈ', word: 'ஈ', meaning: 'Housefly' },
  { letter: 'உ', word: 'உரல்', meaning: 'Mortar' },
  { letter: 'ஊ', word: 'ஊஞ்சல்', meaning: 'Swing' },
  { letter: 'எ', word: 'எலி', meaning: 'Rat' },
  { letter: 'ஏ', word: 'ஏணி', meaning: 'Ladder' },
  { letter: 'ஐ', word: 'ஐந்து', meaning: 'Five' },
  { letter: 'ஒ', word: 'ஒட்டகம்', meaning: 'Camel' },
  { letter: 'ஓ', word: 'ஓடம்', meaning: 'Boat' },
  { letter: 'ஔ', word: 'ஔவையார்', meaning: 'Avvaiyar' },
];

const MEI_LETTERS = [
  { letter: 'க்', word: 'காக்கை', meaning: 'Crow' },
  { letter: 'ங்', word: 'தங்கம்', meaning: 'Gold' },
  { letter: 'ச்', word: 'பச்சை', meaning: 'Green' },
  { letter: 'ஞ்', word: 'ஊஞ்சல்', meaning: 'Swing' },
  { letter: 'ட்', word: 'பட்டம்', meaning: 'Kite' },
  { letter: 'ண்', word: 'வண்டி', meaning: 'Cart' },
  { letter: 'த்', word: 'நத்தை', meaning: 'Snail' },
  { letter: 'ந்', word: 'பந்து', meaning: 'Ball' },
  { letter: 'ப்', word: 'கப்பல்', meaning: 'Ship' },
  { letter: 'ம்', word: 'மரம்', meaning: 'Tree' },
  { letter: 'ய்', word: 'பாய்', meaning: 'Mat' },
  { letter: 'ர்', word: 'தேர்', meaning: 'Chariot' },
  { letter: 'ல்', word: 'சேவல்', meaning: 'Rooster' },
  { letter: 'வ்', word: 'செவ்வானம்', meaning: 'Sunset' },
  { letter: 'ழ்', word: 'யாழ்', meaning: 'Harp' },
  { letter: 'ள்', word: 'வாள்', meaning: 'Sword' },
  { letter: 'ற்', word: 'வெற்றிலை', meaning: 'Betel leaf' },
  { letter: 'ன்', word: 'மீன்', meaning: 'Fish' },
];

// Chronological 31 videos from Cloudinary (agaram_media/videos)
const CLOUDINARY_VIDEOS = [
  // 12 Uyir
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790841742/agaram_media/videos/lyai8f00wea5mpvknty5.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849387/agaram_media/videos/yileko0mif4cuduhy3ty.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849484/agaram_media/videos/pskdcrc7xqmdsqbgh9no.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849525/agaram_media/videos/lhylws8eq0iijt9azfhp.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849570/agaram_media/videos/srteaw6jwtppkt0e6esl.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849604/agaram_media/videos/mvtffw845vapnhrhokcu.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849714/agaram_media/videos/losz1xmdpogdsyb3kfkb.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849774/agaram_media/videos/ctcqwju9p8xcdppwxogk.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849825/agaram_media/videos/abyi5xu4ffymff9ioosy.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790854598/agaram_media/videos/ranfb0lwkaspm4mffrqp.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790854646/agaram_media/videos/gv3wggfnpbus8n2fol4c.mp4',
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790855080/agaram_media/videos/btefhsc3k9n0kgfhmcrn.mp4',

  // 18 Mei (Updated Nov 10, 2026)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296004/agaram_media/videos/pqpts1qxtzsdcyukwdxz.mp4', // க் (காக்கை)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296030/agaram_media/videos/bopiqpsmufwaw2msbect.mp4', // ங் (தங்கம்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296047/agaram_media/videos/pxiam1h6h5vcalsc41dg.mp4', // ச் (பச்சை)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296067/agaram_media/videos/u5wjop3dstrkytbpmcra.mp4', // ஞ் (ஊஞ்சல்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296084/agaram_media/videos/f5ehl4mzblzx6dlxby6n.mp4', // ட் (பட்டம்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296110/agaram_media/videos/s0sdihyms20tkdbemxfh.mp4', // ண் (வண்டி)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296126/agaram_media/videos/cytnbojzsyusmhepnc22.mp4', // த் (நத்தை)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296145/agaram_media/videos/c7bpoyobw4z6iu68meww.mp4', // ந் (பந்து)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296168/agaram_media/videos/atvobggfaee5eyjutnbj.mp4', // ப் (கப்பல்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296184/agaram_media/videos/zc3vvfhpzipuaa9imdfs.mp4', // ம் (மரம்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296205/agaram_media/videos/mjlpp8nvsdumyzgmijax.mp4', // ய் (பாய்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296223/agaram_media/videos/k1hg62yufq8k0xgdtft7.mp4', // ர் (தேர்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296242/agaram_media/videos/ydotvfwaszlrdncnytt9.mp4', // ல் (சேவல்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296267/agaram_media/videos/kjtralqggt2sfdjrhikd.mp4', // வ் (செவ்வானம்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296300/agaram_media/videos/ce9bczrowclxnupywuul.mp4', // ழ் (யாழ்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296323/agaram_media/videos/raul5bd6ak5gdepl7len.mp4', // ள் (வாள்)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296347/agaram_media/videos/iglzk3luumpgfsq2bq35.mp4', // ற் (வெற்றிலை)
  'https://res.cloudinary.com/dy8bu8suk/video/upload/v1794296366/agaram_media/videos/dgtpxplitixesbfjnnsv.mp4', // ன் (மீன்)
];

async function seedVideos() {
  console.log('🎬 Seeding Cloudinary videos into MySQL database...');

  // 1. Seed 12 Uyir Videos
  for (let i = 0; i < UYIR_LETTERS.length; i++) {
    const item = UYIR_LETTERS[i];
    const videoUrl = CLOUDINARY_VIDEOS[i];
    const id = `vid_uyir_${i + 1}`;
    const title = item.letter;
    const description = `உயிர் எழுத்து ${item.letter}`;
    const category = 'உயிர் எழுத்துகள்';
    const displayOrder = i + 1;

    await pool.query(
      `INSERT INTO videos (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
       VALUES (?, ?, ?, ?, '00:15', ?, ?, ?, TRUE)
       ON DUPLICATE KEY UPDATE 
         title = VALUES(title), 
         description = VALUES(description), 
         category = VALUES(category), 
         video_url = VALUES(video_url),
         display_order = VALUES(display_order),
         is_published = TRUE`,
      [id, title, description, category, `🎬${item.letter}`, videoUrl, displayOrder]
    );
  }
  console.log('✅ 12 Uyir videos seeded.');

  // 2. Seed 18 Mei Videos
  for (let i = 0; i < MEI_LETTERS.length; i++) {
    const item = MEI_LETTERS[i];
    const videoUrl = CLOUDINARY_VIDEOS[12 + i];
    const id = `vid_mei_${i + 1}`;
    const title = item.letter;
    const description = `மெய் எழுத்து ${item.letter}`;
    const category = 'மெய் எழுத்துகள்';
    const displayOrder = i + 1;

    await pool.query(
      `INSERT INTO videos (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
       VALUES (?, ?, ?, ?, '00:15', ?, ?, ?, TRUE)
       ON DUPLICATE KEY UPDATE 
         title = VALUES(title), 
         description = VALUES(description), 
         category = VALUES(category), 
         video_url = VALUES(video_url),
         display_order = VALUES(display_order),
         is_published = TRUE`,
      [id, title, description, category, `✍️${item.letter}`, videoUrl, displayOrder]
    );
  }
  console.log('✅ 18 Mei videos seeded.');

  // Ensure Aytham video is not present
  await pool.query("DELETE FROM videos WHERE id = 'vid_aytham_1' OR title = 'ஃ' OR category = 'ஆய்த எழுத்து'");

  const [count] = await pool.query('SELECT COUNT(*) as total FROM videos');
  console.log(`🎉 Total videos in MySQL database: ${count[0].total}`);
  process.exit(0);
}

seedVideos().catch((err) => {
  console.error('❌ Error seeding videos:', err);
  process.exit(1);
});
