/**
 * Seed all 5 Tamil Quizzes, Questions, and Options into the Database
 * (Uyir, Mei, Aytham, Uyirmei, Reading)
 */
const { pool } = require('../config/db');

const quizzesData = [
  {
    id: 'quiz_uyir',
    title: 'உயிர் எழுத்துகள் வினாடி வினா',
    subtitle: '12 உயிர் எழுத்துகளின் வினாடி வினா',
    icon_emoji: '🍎',
    category: 'uyir',
    question_count: 4,
    pass_marks: 3,
    stars_reward: 5,
    display_order: 1,
    is_active: true,
    questions: [
      {
        id: 'qu_1',
        question_text: 'தமிழ் உயிர் எழுத்துகள் மொத்தம் எத்தனை?',
        visual_hint: '🔢',
        explanation: 'தமிழ் மொழியில் மொத்தம் 12 உயிர் எழுத்துகள் உள்ளன (அ முதல் ஔ வரை).',
        marks: 1,
        display_order: 1,
        options: [
          { text: '10', isCorrect: false },
          { text: '12', isCorrect: true },
          { text: '18', isCorrect: false },
          { text: '216', isCorrect: false },
        ],
      },
      {
        id: 'qu_2',
        question_text: '"அ" எழுத்தில் தொடங்கும் சொல் எது?',
        visual_hint: '👩‍👧',
        explanation: '"அ" - அம்மா.',
        marks: 1,
        display_order: 2,
        options: [
          { text: 'ஆடு', isCorrect: false },
          { text: 'இலை', isCorrect: false },
          { text: 'அம்மா', isCorrect: true },
          { text: 'உரல்', isCorrect: false },
        ],
      },
      {
        id: 'qu_3',
        question_text: 'இவற்றுள் நெடில் எழுத்து எது?',
        visual_hint: '🎵',
        explanation: '"ஆ" என்பது நீண்ட ஓசையுடைய நெடில் எழுத்து.',
        marks: 1,
        display_order: 3,
        options: [
          { text: 'அ', isCorrect: false },
          { text: 'இ', isCorrect: false },
          { text: 'ஆ', isCorrect: true },
          { text: 'எ', isCorrect: false },
        ],
      },
      {
        id: 'qu_4',
        question_text: 'கடைசி உயிர் எழுத்து எது?',
        visual_hint: '👵',
        explanation: '"ஔ" என்பது 12வது மற்றும் கடைசி உயிர் எழுத்து.',
        marks: 1,
        display_order: 4,
        options: [
          { text: 'ஒ', isCorrect: false },
          { text: 'ஓ', isCorrect: false },
          { text: 'ஔ', isCorrect: true },
          { text: 'ஐ', isCorrect: false },
        ],
      },
    ],
  },
  {
    id: 'quiz_mei',
    title: 'மெய் எழுத்துகள் வினாடி வினா',
    subtitle: '18 மெய் எழுத்துகளின் வினாடி வினா',
    icon_emoji: '🎡',
    category: 'mei',
    question_count: 4,
    pass_marks: 3,
    stars_reward: 5,
    display_order: 2,
    is_active: true,
    questions: [
      {
        id: 'qm_1',
        question_text: 'தமிழ் மெய் எழுத்துகள் மொத்தம் எத்தனை?',
        visual_hint: '✨',
        explanation: 'மெய் எழுத்துகள் மொத்தம் 18 உள்ளன (க் முதல் ன் வரை).',
        marks: 1,
        display_order: 1,
        options: [
          { text: '12', isCorrect: false },
          { text: '18', isCorrect: true },
          { text: '24', isCorrect: false },
          { text: '30', isCorrect: false },
        ],
      },
      {
        id: 'qm_2',
        question_text: 'மெய் எழுத்துகளை எவ்வாறு அடையாளம் காணலாம்?',
        visual_hint: '📍',
        explanation: 'மெய் எழுத்துகளின் தலையில் புள்ளி வைக்கப்பட்டிருக்கும்.',
        marks: 1,
        display_order: 2,
        options: [
          { text: 'மேலே புள்ளி இருக்கும்', isCorrect: true },
          { text: 'கீழே கோடு இருக்கும்', isCorrect: false },
          { text: 'சுழி இருக்கும்', isCorrect: false },
          { text: 'வட்டமாக இருக்கும்', isCorrect: false },
        ],
      },
      {
        id: 'qm_3',
        question_text: '"கண்" என்ற சொல்லில் உள்ள மெய் எழுத்து எது?',
        visual_hint: '👁️',
        explanation: '"ண்" என்பது கண் என்ற சொல்லில் உள்ள மெய் எழுத்து.',
        marks: 1,
        display_order: 3,
        options: [
          { text: 'க', isCorrect: false },
          { text: 'ண்', isCorrect: true },
          { text: 'ஆ', isCorrect: false },
          { text: 'த்', isCorrect: false },
        ],
      },
      {
        id: 'qm_4',
        question_text: 'தமிழ் மொழிக்கே உரிய சிறப்பு மெய் எழுத்து எது?',
        visual_hint: '🎻',
        explanation: '"ழ்" என்பது தமிழுக்கே உரிய சிறப்பு ழகரம்.',
        marks: 1,
        display_order: 4,
        options: [
          { text: 'ல்', isCorrect: false },
          { text: 'ள்', isCorrect: false },
          { text: 'ழ்', isCorrect: true },
          { text: 'ர்', isCorrect: false },
        ],
      },
    ],
  },
  {
    id: 'quiz_aytham',
    title: 'ஆய்த எழுத்து வினாடி வினா',
    subtitle: 'ஃ எழுத்து பற்றிய வினாடி வினா',
    icon_emoji: '🛡️',
    category: 'aytham',
    question_count: 3,
    pass_marks: 2,
    stars_reward: 5,
    display_order: 3,
    is_active: true,
    questions: [
      {
        id: 'qa_1',
        question_text: 'ஆய்த எழுத்து எது?',
        visual_hint: '🛡️',
        explanation: '"ஃ" என்பது ஆய்த எழுத்து ஆகும்.',
        marks: 1,
        display_order: 1,
        options: [
          { text: 'அ', isCorrect: false },
          { text: 'க்', isCorrect: false },
          { text: 'ஃ', isCorrect: true },
          { text: 'க', isCorrect: false },
        ],
      },
      {
        id: 'qa_2',
        question_text: 'ஆய்த எழுத்தில் எத்தனை புள்ளிகள் உள்ளன?',
        visual_hint: '🎯',
        explanation: 'ஆய்த எழுத்து மூன்று புள்ளிகளைக் கொண்டது (முப்புள்ளி).',
        marks: 1,
        display_order: 2,
        options: [
          { text: '1', isCorrect: false },
          { text: '2', isCorrect: false },
          { text: '3', isCorrect: true },
          { text: '4', isCorrect: false },
        ],
      },
      {
        id: 'qa_3',
        question_text: 'ஆய்த எழுத்து இடம்பெறும் சொல் எது?',
        visual_hint: '⚔️',
        explanation: '"எஃகு" என்ற சொல்லில் நடுவில் "ஃ" இடம்பெற்றுள்ளது.',
        marks: 1,
        display_order: 3,
        options: [
          { text: 'அம்மா', isCorrect: false },
          { text: 'எஃகு', isCorrect: true },
          { text: 'பட்டம்', isCorrect: false },
          { text: 'மீன்', isCorrect: false },
        ],
      },
    ],
  },
  {
    id: 'quiz_uyirmei',
    title: 'உயிர்மெய் எழுத்துகள் வினாடி வினா',
    subtitle: 'உயிர் + மெய் கூட்டு எழுத்துகள்',
    icon_emoji: '🌱',
    category: 'uyirmei',
    question_count: 4,
    pass_marks: 3,
    stars_reward: 5,
    display_order: 4,
    is_active: true,
    questions: [
      {
        id: 'qum_1',
        question_text: 'க் + அ = என்ன எழுத்து?',
        visual_hint: '➕',
        explanation: 'க் + அ = க.',
        marks: 1,
        display_order: 1,
        options: [
          { text: 'கா', isCorrect: false },
          { text: 'க', isCorrect: true },
          { text: 'கி', isCorrect: false },
          { text: 'கு', isCorrect: false },
        ],
      },
      {
        id: 'qum_2',
        question_text: 'மொத்த உயிர்மெய் எழுத்துகள் எத்தனை?',
        visual_hint: '🌈',
        explanation: '18 மெய் x 12 உயிர் = 216 உயிர்மெய் எழுத்துகள்.',
        marks: 1,
        display_order: 2,
        options: [
          { text: '12', isCorrect: false },
          { text: '18', isCorrect: false },
          { text: '100', isCorrect: false },
          { text: '216', isCorrect: true },
        ],
      },
      {
        id: 'qum_3',
        question_text: 'க் + ஆ = என்ன எழுத்து?',
        visual_hint: '🦅',
        explanation: 'க் + ஆ = கா.',
        marks: 1,
        display_order: 3,
        options: [
          { text: 'கா', isCorrect: true },
          { text: 'கி', isCorrect: false },
          { text: 'கீ', isCorrect: false },
          { text: 'க', isCorrect: false },
        ],
      },
      {
        id: 'qum_4',
        question_text: 'ம் + அ = என்ன எழுத்து?',
        visual_hint: '🌳',
        explanation: 'ம் + அ = ம.',
        marks: 1,
        display_order: 4,
        options: [
          { text: 'மி', isCorrect: false },
          { text: 'மா', isCorrect: false },
          { text: 'ம', isCorrect: true },
          { text: 'மு', isCorrect: false },
        ],
      },
    ],
  },
  {
    id: 'quiz_reading',
    title: 'வாசிப்பு வினாடி வினா',
    subtitle: 'கதை மற்றும் சொற்கள் புரிதல்',
    icon_emoji: '📖',
    category: 'reading',
    question_count: 3,
    pass_marks: 2,
    stars_reward: 5,
    display_order: 5,
    is_active: true,
    questions: [
      {
        id: 'qr_1',
        question_text: '"முயலும் ஆமையும்" கதையில் பந்தயத்தில் வென்றது யார்?',
        visual_hint: '🏆',
        explanation: 'தொடர்ந்து விடாமுயற்சியுடன் சென்ற ஆமை வெற்றி பெற்றது.',
        marks: 1,
        display_order: 1,
        options: [
          { text: 'முயல்', isCorrect: false },
          { text: 'ஆமை', isCorrect: true },
          { text: 'நரி', isCorrect: false },
          { text: 'மான்', isCorrect: false },
        ],
      },
      {
        id: 'qr_2',
        question_text: 'முயல் ஏன் பந்தயத்தில் தோற்றது?',
        visual_hint: '😴',
        explanation: 'அலட்சியமாக மரத்தடியில் தூங்கியதால் முயல் தோற்றது.',
        marks: 1,
        display_order: 2,
        options: [
          { text: 'பயந்துவிட்டது', isCorrect: false },
          { text: 'தூங்கிவிட்டது', isCorrect: true },
          { text: 'வழி தவறியது', isCorrect: false },
          { text: 'கால் வலித்தது', isCorrect: false },
        ],
      },
      {
        id: 'qr_3',
        question_text: 'இக்கதை நமக்குக் கற்றுத்தரும் நீதி என்ன?',
        visual_hint: '💡',
        explanation: 'பொறுமையும் தொடர் முயற்சியும் எப்போதும் வெற்றி தரும்.',
        marks: 1,
        display_order: 3,
        options: [
          { text: 'வேகமே சிறந்தது', isCorrect: false },
          { text: 'விடாமுயற்சி வெற்றி தரும்', isCorrect: true },
          { text: 'தூங்குவது நல்லது', isCorrect: false },
          { text: 'பந்தயம் கூடாது', isCorrect: false },
        ],
      },
    ],
  },
];

async function seedAllQuizzes() {
  console.log('🌱 Starting Seeding: 5 Tamil Quizzes & Questions...');

  // Remove obsolete placeholder questions from old initial seed if present
  try {
    await pool.query("DELETE FROM quiz_questions WHERE id IN ('q_uyir_1', 'q_uyir_2', 'q_uyir_3')");
  } catch (_) {}

  for (const q of quizzesData) {
    // 1. Insert or update quiz
    await pool.query(
      `INSERT INTO quizzes (id, title, subtitle, icon_emoji, category, question_count, pass_marks, stars_reward, is_active, display_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         title = VALUES(title),
         subtitle = VALUES(subtitle),
         icon_emoji = VALUES(icon_emoji),
         category = VALUES(category),
         question_count = VALUES(question_count),
         pass_marks = VALUES(pass_marks),
         stars_reward = VALUES(stars_reward),
         is_active = VALUES(is_active),
         display_order = VALUES(display_order)`,
      [
        q.id,
        q.title,
        q.subtitle,
        q.icon_emoji,
        q.category,
        q.question_count,
        q.pass_marks,
        q.stars_reward,
        q.is_active ? 1 : 0,
        q.display_order,
      ]
    );

    console.log(`  ✓ Quiz seeded: ${q.title} (${q.id})`);

    // 2. Insert or update questions
    for (const quest of q.questions) {
      await pool.query(
        `INSERT INTO quiz_questions (id, quiz_id, question_text, visual_hint, visual_image, explanation, marks, display_order, is_active)
         VALUES (?, ?, ?, ?, NULL, ?, ?, ?, TRUE)
         ON DUPLICATE KEY UPDATE
           question_text = VALUES(question_text),
           visual_hint = VALUES(visual_hint),
           explanation = VALUES(explanation),
           marks = VALUES(marks),
           display_order = VALUES(display_order)`,
        [quest.id, q.id, quest.question_text, quest.visual_hint, quest.explanation, quest.marks, quest.display_order]
      );

      // Remove existing options to re-insert clean list
      await pool.query('DELETE FROM quiz_options WHERE question_id = ?', [quest.id]);

      // 3. Insert options
      for (let i = 0; i < quest.options.length; i++) {
        const opt = quest.options[i];
        await pool.query(
          `INSERT INTO quiz_options (question_id, option_text, is_correct, display_order)
           VALUES (?, ?, ?, ?)`,
          [quest.id, opt.text, opt.isCorrect ? 1 : 0, i + 1]
        );
      }
    }
  }

  console.log('✅ Successfully seeded all 5 Quizzes, Questions, and Options into the Database!');
}

if (require.main === module) {
  seedAllQuizzes()
    .then(() => {
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Failed to seed quizzes:', err);
      process.exit(1);
    });
}

module.exports = { seedAllQuizzes, quizzesData };
