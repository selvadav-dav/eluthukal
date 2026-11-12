/**
 * Script to sync all 30 Cloudinary letter videos into production PostgreSQL / live API server
 */
const https = require('https');

const API_BASE = 'https://eluthukkal-api.macvelsoftware.com/api/v1';

const UYIR_LETTERS = [
  { letter: 'அ', word: 'அம்மா' },
  { letter: 'ஆ', word: 'ஆடு' },
  { letter: 'இ', word: 'இலை' },
  { letter: 'ஈ', word: 'ஈ' },
  { letter: 'உ', word: 'உரல்' },
  { letter: 'ஊ', word: 'ஊஞ்சல்' },
  { letter: 'எ', word: 'எலி' },
  { letter: 'ஏ', word: 'ஏணி' },
  { letter: 'ஐ', word: 'ஐந்து' },
  { letter: 'ஒ', word: 'ஒட்டகம்' },
  { letter: 'ஓ', word: 'ஓடம்' },
  { letter: 'ஔ', word: 'ஔவையார்' },
];

const MEI_LETTERS = [
  { letter: 'க்', word: 'காக்கை' },
  { letter: 'ங்', word: 'தங்கம்' },
  { letter: 'ச்', word: 'பச்சை' },
  { letter: 'ஞ்', word: 'ஊஞ்சல்' },
  { letter: 'ட்', word: 'பட்டம்' },
  { letter: 'ண்', word: 'வண்டி' },
  { letter: 'த்', word: 'நத்தை' },
  { letter: 'ந்', word: 'பந்து' },
  { letter: 'ப்', word: 'கப்பல்' },
  { letter: 'ம்', word: 'மரம்' },
  { letter: 'ய்', word: 'பாய்' },
  { letter: 'ர்', word: 'தேர்' },
  { letter: 'ல்', word: 'சேவல்' },
  { letter: 'வ்', word: 'செவ்வானம்' },
  { letter: 'ழ்', word: 'யாழ்' },
  { letter: 'ள்', word: 'வாள்' },
  { letter: 'ற்', word: 'வெற்றிலை' },
  { letter: 'ன்', word: 'மீன்' },
];

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

function request(url, options, bodyData) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = {
      hostname: u.hostname,
      port: u.port || 443,
      path: u.pathname + u.search,
      method: options.method || 'GET',
      headers: options.headers || {},
    };

    const req = https.request(opts, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch (_) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });

    req.on('error', reject);
    if (bodyData) {
      req.write(typeof bodyData === 'string' ? bodyData : JSON.stringify(bodyData));
    }
    req.end();
  });
}

async function run() {
  console.log('🔐 Logging in to remote production server...');
  const loginRes = await request(`${API_BASE}/auth/admin/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  }, {
    username: 'admin@gmail.com',
    password: 'Admin@123',
  });

  if (loginRes.status !== 200 || !loginRes.data?.data?.token) {
    throw new Error('Failed to login: ' + JSON.stringify(loginRes));
  }

  const token = loginRes.data.data.token;
  console.log('✅ Logged in successfully!');

  // Check current videos
  console.log('📹 Fetching existing videos on production server...');
  const existingRes = await request(`${API_BASE}/videos?all=true`, {});
  const existingList = existingRes.data?.data || [];
  console.log(`Found ${existingList.length} videos currently.`);

  // Clean up dummy videos if present
  for (const v of existingList) {
    if (v.id.startsWith('vid_uyir_song') || v.id.startsWith('vid_mei_rhyme') || v.id.startsWith('vid_tamil_intro')) {
      console.log(`🗑️ Deleting dummy video: ${v.id} (${v.title})...`);
      await request(`${API_BASE}/videos/${v.id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
    }
  }

  // 1. Sync 12 Uyir Videos
  console.log('✨ Syncing 12 Uyir videos...');
  for (let i = 0; i < UYIR_LETTERS.length; i++) {
    const item = UYIR_LETTERS[i];
    const videoUrl = CLOUDINARY_VIDEOS[i];
    const id = `vid_uyir_${i + 1}`;
    const title = item.letter;
    const description = `உயிர் எழுத்து ${item.letter}`;
    const category = 'உயிர் எழுத்துகள்';
    const displayOrder = i + 1;

    // Check if exists
    const exists = existingList.some((x) => x.id === id);
    if (exists) {
      console.log(`  Updating ${id} (${title})...`);
      await request(`${API_BASE}/videos/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, {
        title,
        description,
        category,
        duration: '00:15',
        thumbnail_emoji: `🎬${item.letter}`,
        video_url: videoUrl,
        display_order: displayOrder,
        is_published: true,
      });
    } else {
      console.log(`  Creating ${id} (${title})...`);
      const createRes = await request(`${API_BASE}/videos`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, {
        id,
        title,
        description,
        category,
        duration: '00:15',
        thumbnail_emoji: `🎬${item.letter}`,
        video_url: videoUrl,
        display_order: displayOrder,
        is_published: true,
      });
      if (createRes.status >= 300) {
        console.error(`  ❌ Failed to create ${id}:`, createRes);
      }
    }
  }

  // 2. Sync 18 Mei Videos
  console.log('✨ Syncing 18 Mei videos...');
  for (let i = 0; i < MEI_LETTERS.length; i++) {
    const item = MEI_LETTERS[i];
    const videoUrl = CLOUDINARY_VIDEOS[12 + i];
    const id = `vid_mei_${i + 1}`;
    const title = item.letter;
    const description = `மெய் எழுத்து ${item.letter}`;
    const category = 'மெய் எழுத்துகள்';
    const displayOrder = i + 1;

    const exists = existingList.some((x) => x.id === id);
    if (exists) {
      console.log(`  Updating ${id} (${title})...`);
      await request(`${API_BASE}/videos/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, {
        title,
        description,
        category,
        duration: '00:15',
        thumbnail_emoji: `✍️${item.letter}`,
        video_url: videoUrl,
        display_order: displayOrder,
        is_published: true,
      });
    } else {
      console.log(`  Creating ${id} (${title})...`);
      const createRes = await request(`${API_BASE}/videos`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, {
        id,
        title,
        description,
        category,
        duration: '00:15',
        thumbnail_emoji: `✍️${item.letter}`,
        video_url: videoUrl,
        display_order: displayOrder,
        is_published: true,
      });
      if (createRes.status >= 300) {
        console.error(`  ❌ Failed to create ${id}:`, createRes);
      }
    }
  }

  console.log('🎉 Done syncing videos! Fetching count...');
  const afterRes = await request(`${API_BASE}/videos?all=true`, {});
  console.log(`Total videos now on production server: ${afterRes.data?.data?.length}`);
}

run().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
