const { pool } = require('../config/db');

async function check() {
  const [rows] = await pool.query("SELECT id, letter, word, audio_path FROM letters WHERE type = 'uyir' ORDER BY display_order");
  console.log('Uyir DB audio paths:');
  console.log(JSON.stringify(rows, null, 2));
  await pool.end();
}

check().catch(console.error);

