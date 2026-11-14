/**
 * Updates the 6 letters in the MySQL database:
 * 1. 'ஆ' -> 'ஆடு' with new Cloudinary goat image
 * 2. 'ஈ' -> 'ஈச்ச மரம்' with Cloudinary date palm image
 * 3. 'ஓ' -> 'ஓலைச்சுவடி' with Cloudinary palm leaf manuscript image
 * 4. 'ன்' -> 'கன்னம்' with Cloudinary smiling cheek image
 * 5. 'க்' -> 'காக்கை' with Cloudinary crow image
 * 6. 'ண்' -> 'வண்டி' with Cloudinary bullock cart image
 */
const { pool } = require('../config/db');
const LetterModel = require('../models/letterModel');

const updates = [
  {
    id: 'uyir_aa',
    letter: 'ஆ',
    word: 'ஆடு',
    meaning: 'புல் மேயும் ஆடு',
    phonetic: 'Aadu',
    icon_emoji: '🐐',
    image_path: 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1794553309/agaram_media/images/aadu_goat.jpg',
    explanation: 'துள்ளி விளையாடும் வெள்ளாடு. "ஆ" நெடில் எழுத்து.',
  },
  {
    id: 'uyir_ee',
    letter: 'ஈ',
    word: 'ஈச்ச மரம்',
    meaning: 'தித்திக்கும் ஈச்ச மரம்',
    phonetic: 'Eecha Maram',
    icon_emoji: '🌴',
    image_path: 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1794553310/agaram_media/images/eecha_maram.webp',
    explanation: 'இனிப்பான பேரீச்சம்பழம் தரும் பசுமையான ஈச்ச மரம்.',
  },
  {
    id: 'uyir_oa',
    letter: 'ஓ',
    word: 'ஓலைச்சுவடி',
    meaning: 'பண்டைய ஓலைச்சுவடி',
    phonetic: 'Olaichuvadi',
    icon_emoji: '📜',
    image_path: 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1794553311/agaram_media/images/olaichuvadi.webp',
    explanation: 'பழங்காலத்தில் தமிழ் இலக்கியங்கள் எழுதப்பட்ட வரலாற்று ஓலைச்சுவடி.',
  },
  {
    id: 'mei_in',
    letter: 'ன்',
    word: 'கன்னம்',
    meaning: 'மழலையின் கன்னம்',
    phonetic: 'kannam',
    icon_emoji: '👶',
    image_path: 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1794553312/agaram_media/images/kannam.jpg',
    explanation: 'மெய் எழுத்து "ன்" - இரண்டு சுழி ன். (கன்னம்)',
  },
  {
    id: 'mei_ik',
    letter: 'க்',
    word: 'காக்கை',
    meaning: 'கரையும் காக்கை',
    phonetic: 'kaakkai',
    icon_emoji: '🐦‍⬛',
    image_path: 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1794553342/agaram_media/images/kaakkai.jpg',
    explanation: 'மெய் எழுத்து "க்" - புள்ளியிட்ட எழுத்து. (காக்கை)',
  },
  {
    id: 'mei_inn',
    letter: 'ண்',
    word: 'வண்டி',
    meaning: 'மாட்டு வண்டி',
    phonetic: 'vandi',
    icon_emoji: '🐂',
    image_path: 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1794553341/agaram_media/images/vandi.jpg',
    explanation: 'மெய் எழுத்து "ண்" - மூணு சுழி ண். (வண்டி)',
  },
];

async function run() {
  console.log('🔄 Updating database letters...');
  for (const item of updates) {
    // Check if letter exists by id or letter
    const [rows] = await pool.query('SELECT id FROM letters WHERE id = ? OR (letter = ? AND type = ?)', [
      item.id,
      item.letter,
      item.id.startsWith('uyir') ? 'uyir' : 'mei',
    ]);

    if (rows.length > 0) {
      const targetId = rows[0].id;
      console.log(`Updating ${item.letter} (${targetId}) -> ${item.word}...`);
      await LetterModel.update(targetId, item);
    } else {
      console.log(`Creating ${item.letter} (${item.id}) -> ${item.word}...`);
      await LetterModel.create({
        id: item.id,
        letter: item.letter,
        type: item.id.startsWith('uyir') ? 'uyir' : 'mei',
        ...item,
      });
    }
  }

  const [verifyRows] = await pool.query(
    "SELECT id, letter, type, word, meaning, icon_emoji, image_path FROM letters WHERE letter IN ('ஆ', 'ஈ', 'ஓ', 'ன்', 'க்', 'ண்')"
  );
  console.log('✅ Verified updated database rows:');
  console.log(JSON.stringify(verifyRows, null, 2));

  await pool.end();
}

run().catch((err) => {
  console.error('❌ Failed:', err);
  process.exit(1);
});

