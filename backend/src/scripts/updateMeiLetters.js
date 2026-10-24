/**
 * Updates Mei letters in MySQL database to match user requirements:
 * - 'ச்' -> 'எலுமிச்சை'
 * - 'ர்' -> 'தேர்'
 * - 'வ்' -> 'செவ்வானம்'
 * - 'ற்' -> 'வெற்றிலை'
 */
const { pool } = require('../config/db');
const LetterModel = require('../models/letterModel');

async function run() {
  console.log('🔄 Updating Mei letters in database...');

  await LetterModel.update('mei_ich', {
    word: 'எலுமிச்சை',
    meaning: 'புளிப்பான எலுமிச்சை',
    phonetic: 'Ich',
    icon_emoji: '🍋',
    image_path: 'assets/images/lemon.jpg',
    explanation: 'மெய் எழுத்து "ச்". (எலுமிச்சை)',
  });

  await LetterModel.update('mei_ir', {
    word: 'தேர்',
    meaning: 'கோவில் தேர்',
    phonetic: 'Ir',
    icon_emoji: '🛕',
    image_path: 'assets/images/ther.jpg',
    explanation: 'மெய் எழுத்து "ர்". (தேர்)',
  });

  await LetterModel.update('mei_iv', {
    word: 'செவ்வானம்',
    meaning: 'மாலைச் செவ்வானம்',
    phonetic: 'Iv',
    icon_emoji: '🌅',
    image_path: 'assets/images/sevvaanam.jpg',
    explanation: 'மெய் எழுத்து "வ்". (செவ்வானம்)',
  });

  await LetterModel.update('mei_irr', {
    word: 'வெற்றிலை',
    meaning: 'பச்சை வெற்றிலை',
    phonetic: 'Irr',
    icon_emoji: '🍃',
    image_path: 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1791177419/agaram_media/images/frontend_leaf.jpg',
    explanation: 'மெய் எழுத்து "ற்". (வெற்றிலை)',
  });

  const [rows] = await pool.query(
    "SELECT id, letter, word, meaning, icon_emoji, image_path FROM letters WHERE id IN ('mei_ich', 'mei_ir', 'mei_iv', 'mei_irr')"
  );
  console.log('✅ Updated database rows:');
  console.log(JSON.stringify(rows, null, 2));

  await pool.end();
}

run().catch((err) => {
  console.error('❌ Failed:', err);
  process.exit(1);
});
