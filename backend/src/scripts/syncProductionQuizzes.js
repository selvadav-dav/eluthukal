/**
 * Sync all 5 Tamil Quizzes and Questions to Live Production Server
 * (https://eluthukkal-api.macvelsoftware.com/api/v1)
 */
const https = require('https');

const API_BASE = 'https://eluthukkal-api.macvelsoftware.com/api/v1';

const QUIZZES = [
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
    questions: [
      {
        id: 'qu_1',
        questionText: 'தமிழ் உயிர் எழுத்துகள் மொத்தம் எத்தனை?',
        visualHint: '🔢',
        explanation: 'தமிழ் மொழியில் மொத்தம் 12 உயிர் எழுத்துகள் உள்ளன (அ முதல் ஔ வரை).',
        marks: 1,
        displayOrder: 1,
        options: [
          { optionText: '10', isCorrect: false, displayOrder: 1 },
          { optionText: '12', isCorrect: true, displayOrder: 2 },
          { optionText: '18', isCorrect: false, displayOrder: 3 },
          { optionText: '216', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qu_2',
        questionText: '"அ" எழுத்தில் தொடங்கும் சொல் எது?',
        visualHint: '👩‍👧',
        explanation: '"அ" - அம்மா.',
        marks: 1,
        displayOrder: 2,
        options: [
          { optionText: 'ஆடு', isCorrect: false, displayOrder: 1 },
          { optionText: 'இலை', isCorrect: false, displayOrder: 2 },
          { optionText: 'அம்மா', isCorrect: true, displayOrder: 3 },
          { optionText: 'உரல்', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qu_3',
        questionText: 'இவற்றுள் நெடில் எழுத்து எது?',
        visualHint: '🎵',
        explanation: '"ஆ" என்பது நீண்ட ஓசையுடைய நெடில் எழுத்து.',
        marks: 1,
        displayOrder: 3,
        options: [
          { optionText: 'அ', isCorrect: false, displayOrder: 1 },
          { optionText: 'இ', isCorrect: false, displayOrder: 2 },
          { optionText: 'ஆ', isCorrect: true, displayOrder: 3 },
          { optionText: 'எ', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qu_4',
        questionText: 'கடைசி உயிர் எழுத்து எது?',
        visualHint: '👵',
        explanation: '"ஔ" என்பது 12வது மற்றும் கடைசி உயிர் எழுத்து.',
        marks: 1,
        displayOrder: 4,
        options: [
          { optionText: 'ஒ', isCorrect: false, displayOrder: 1 },
          { optionText: 'ஓ', isCorrect: false, displayOrder: 2 },
          { optionText: 'ஔ', isCorrect: true, displayOrder: 3 },
          { optionText: 'ஐ', isCorrect: false, displayOrder: 4 },
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
    questions: [
      {
        id: 'qm_1',
        questionText: 'தமிழ் மெய் எழுத்துகள் மொத்தம் எத்தனை?',
        visualHint: '✨',
        explanation: 'மெய் எழுத்துகள் மொத்தம் 18 உள்ளன (க் முதல் ன் வரை).',
        marks: 1,
        displayOrder: 1,
        options: [
          { optionText: '12', isCorrect: false, displayOrder: 1 },
          { optionText: '18', isCorrect: true, displayOrder: 2 },
          { optionText: '24', isCorrect: false, displayOrder: 3 },
          { optionText: '30', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qm_2',
        questionText: 'மெய் எழுத்துகளை எவ்வாறு அடையாளம் காணலாம்?',
        visualHint: '📍',
        explanation: 'மெய் எழுத்துகளின் தலையில் புள்ளி வைக்கப்பட்டிருக்கும்.',
        marks: 1,
        displayOrder: 2,
        options: [
          { optionText: 'மேலே புள்ளி இருக்கும்', isCorrect: true, displayOrder: 1 },
          { optionText: 'கீழே கோடு இருக்கும்', isCorrect: false, displayOrder: 2 },
          { optionText: 'சுழி இருக்கும்', isCorrect: false, displayOrder: 3 },
          { optionText: 'வட்டமாக இருக்கும்', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qm_3',
        questionText: '"கண்" என்ற சொல்லில் உள்ள மெய் எழுத்து எது?',
        visualHint: '👁️',
        explanation: '"ண்" என்பது கண் என்ற சொல்லில் உள்ள மெய் எழுத்து.',
        marks: 1,
        displayOrder: 3,
        options: [
          { optionText: 'க', isCorrect: false, displayOrder: 1 },
          { optionText: 'ண்', isCorrect: true, displayOrder: 2 },
          { optionText: 'ஆ', isCorrect: false, displayOrder: 3 },
          { optionText: 'த்', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qm_4',
        questionText: 'தமிழ் மொழிக்கே உரிய சிறப்பு மெய் எழுத்து எது?',
        visualHint: '🎻',
        explanation: '"ழ்" என்பது தமிழுக்கே உரிய சிறப்பு ழகரம்.',
        marks: 1,
        displayOrder: 4,
        options: [
          { optionText: 'ல்', isCorrect: false, displayOrder: 1 },
          { optionText: 'ள்', isCorrect: false, displayOrder: 2 },
          { optionText: 'ழ்', isCorrect: true, displayOrder: 3 },
          { optionText: 'ர்', isCorrect: false, displayOrder: 4 },
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
    questions: [
      {
        id: 'qa_1',
        questionText: 'ஆய்த எழுத்து எது?',
        visualHint: '🛡️',
        explanation: '"ஃ" என்பது ஆய்த எழுத்து ஆகும்.',
        marks: 1,
        displayOrder: 1,
        options: [
          { optionText: 'அ', isCorrect: false, displayOrder: 1 },
          { optionText: 'க்', isCorrect: false, displayOrder: 2 },
          { optionText: 'ஃ', isCorrect: true, displayOrder: 3 },
          { optionText: 'க', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qa_2',
        questionText: 'ஆய்த எழுத்தில் எத்தனை புள்ளிகள் உள்ளன?',
        visualHint: '🎯',
        explanation: 'ஆய்த எழுத்து மூன்று புள்ளிகளைக் கொண்டது (முப்புள்ளி).',
        marks: 1,
        displayOrder: 2,
        options: [
          { optionText: '1', isCorrect: false, displayOrder: 1 },
          { optionText: '2', isCorrect: false, displayOrder: 2 },
          { optionText: '3', isCorrect: true, displayOrder: 3 },
          { optionText: '4', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qa_3',
        questionText: 'ஆய்த எழுத்து இடம்பெறும் சொல் எது?',
        visualHint: '⚔️',
        explanation: '"எஃகு" என்ற சொல்லில் நடுவில் "ஃ" இடம்பெற்றுள்ளது.',
        marks: 1,
        displayOrder: 3,
        options: [
          { optionText: 'அம்மா', isCorrect: false, displayOrder: 1 },
          { optionText: 'எஃகு', isCorrect: true, displayOrder: 2 },
          { optionText: 'பட்டம்', isCorrect: false, displayOrder: 3 },
          { optionText: 'மீன்', isCorrect: false, displayOrder: 4 },
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
    questions: [
      {
        id: 'qum_1',
        questionText: 'க் + அ = என்ன எழுத்து?',
        visualHint: '➕',
        explanation: 'க் + அ = க.',
        marks: 1,
        displayOrder: 1,
        options: [
          { optionText: 'கா', isCorrect: false, displayOrder: 1 },
          { optionText: 'க', isCorrect: true, displayOrder: 2 },
          { optionText: 'கி', isCorrect: false, displayOrder: 3 },
          { optionText: 'கு', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qum_2',
        questionText: 'மொத்த உயிர்மெய் எழுத்துகள் எத்தனை?',
        visualHint: '🌈',
        explanation: '18 மெய் x 12 உயிர் = 216 உயிர்மெய் எழுத்துகள்.',
        marks: 1,
        displayOrder: 2,
        options: [
          { optionText: '12', isCorrect: false, displayOrder: 1 },
          { optionText: '18', isCorrect: false, displayOrder: 2 },
          { optionText: '100', isCorrect: false, displayOrder: 3 },
          { optionText: '216', isCorrect: true, displayOrder: 4 },
        ],
      },
      {
        id: 'qum_3',
        questionText: 'க் + ஆ = என்ன எழுத்து?',
        visualHint: '🦅',
        explanation: 'க் + ஆ = கா.',
        marks: 1,
        displayOrder: 3,
        options: [
          { optionText: 'கா', isCorrect: true, displayOrder: 1 },
          { optionText: 'கி', isCorrect: false, displayOrder: 2 },
          { optionText: 'கீ', isCorrect: false, displayOrder: 3 },
          { optionText: 'க', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qum_4',
        questionText: 'ம் + அ = என்ன எழுத்து?',
        visualHint: '🌳',
        explanation: 'ம் + அ = ம.',
        marks: 1,
        displayOrder: 4,
        options: [
          { optionText: 'மி', isCorrect: false, displayOrder: 1 },
          { optionText: 'மா', isCorrect: false, displayOrder: 2 },
          { optionText: 'ம', isCorrect: true, displayOrder: 3 },
          { optionText: 'மு', isCorrect: false, displayOrder: 4 },
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
    questions: [
      {
        id: 'qr_1',
        questionText: '"முயலும் ஆமையும்" கதையில் பந்தயத்தில் வென்றது யார்?',
        visualHint: '🏆',
        explanation: 'தொடர்ந்து விடாமுயற்சியுடன் சென்ற ஆமை வெற்றி பெற்றது.',
        marks: 1,
        displayOrder: 1,
        options: [
          { optionText: 'முயல்', isCorrect: false, displayOrder: 1 },
          { optionText: 'ஆமை', isCorrect: true, displayOrder: 2 },
          { optionText: 'நரி', isCorrect: false, displayOrder: 3 },
          { optionText: 'மான்', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qr_2',
        questionText: 'முயல் ஏன் பந்தயத்தில் தோற்றது?',
        visualHint: '😴',
        explanation: 'அலட்சியமாக மரத்தடியில் தூங்கியதால் முயல் தோற்றது.',
        marks: 1,
        displayOrder: 2,
        options: [
          { optionText: 'பயந்துவிட்டது', isCorrect: false, displayOrder: 1 },
          { optionText: 'தூங்கிவிட்டது', isCorrect: true, displayOrder: 2 },
          { optionText: 'வழி தவறியது', isCorrect: false, displayOrder: 3 },
          { optionText: 'கால் வலித்தது', isCorrect: false, displayOrder: 4 },
        ],
      },
      {
        id: 'qr_3',
        questionText: 'இக்கதை நமக்குக் கற்றுத்தரும் நீதி என்ன?',
        visualHint: '💡',
        explanation: 'பொறுமையும் தொடர் முயற்சியும் எப்போதும் வெற்றி தரும்.',
        marks: 1,
        displayOrder: 3,
        options: [
          { optionText: 'வேகமே சிறந்தது', isCorrect: false, displayOrder: 1 },
          { optionText: 'விடாமுயற்சி வெற்றி தரும்', isCorrect: true, displayOrder: 2 },
          { optionText: 'தூங்குவது நல்லது', isCorrect: false, displayOrder: 3 },
          { optionText: 'பந்தயம் கூடாது', isCorrect: false, displayOrder: 4 },
        ],
      },
    ],
  },
];

function request(url, options = {}, bodyData = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const opts = {
      hostname: urlObj.hostname,
      port: urlObj.port || (urlObj.protocol === 'https:' ? 443 : 80),
      path: urlObj.pathname + urlObj.search,
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
  console.log('🔐 Logging in to live production server...');
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

  // Check current quizzes
  console.log('🔍 Fetching existing quizzes on production server...');
  const existingRes = await request(`${API_BASE}/quizzes?all=true`, {});
  const existingList = existingRes.data?.data || [];
  console.log(`Found ${existingList.length} quizzes currently:`, existingList.map((q) => `${q.id} (${q.title})`));

  for (const q of QUIZZES) {
    const exists = existingList.some((x) => x.id === q.id);
    const quizPayload = {
      id: q.id,
      title: q.title,
      subtitle: q.subtitle,
      iconEmoji: q.icon_emoji,
      icon_emoji: q.icon_emoji,
      category: q.category,
      questionCount: q.question_count,
      question_count: q.question_count,
      passMarks: q.pass_marks,
      pass_marks: q.pass_marks,
      starsReward: q.stars_reward,
      stars_reward: q.stars_reward,
      isActive: true,
      is_active: true,
      displayOrder: q.display_order,
      display_order: q.display_order,
    };

    if (exists) {
      console.log(`📝 Updating quiz: ${q.title} (${q.id})...`);
      const updateRes = await request(`${API_BASE}/admin/quizzes/${q.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, quizPayload);
      console.log(`   Update result: ${updateRes.status}`);
    } else {
      console.log(`✨ Creating quiz: ${q.title} (${q.id})...`);
      const createRes = await request(`${API_BASE}/admin/quizzes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      }, quizPayload);
      console.log(`   Create result: ${createRes.status}`);
      if (createRes.status >= 300) {
        console.error('   Error creating quiz:', createRes);
      }
    }

    // Now check questions for this quiz
    console.log(`   Checking questions for ${q.id}...`);
    const quizDetailsRes = await request(`${API_BASE}/quizzes/${q.id}?includeAnswers=true`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const currentQuestions = quizDetailsRes.data?.data?.questions || [];
    console.log(`   Quiz ${q.id} currently has ${currentQuestions.length} questions.`);

    // If quiz has old dummy questions (like q_uyir_1, 2, 3), delete them
    if (q.id === 'quiz_uyir') {
      for (const oldQ of currentQuestions) {
        if (oldQ.id.startsWith('q_uyir_')) {
          console.log(`   🗑️ Deleting old dummy question ${oldQ.id}...`);
          await request(`${API_BASE}/admin/quizzes/${q.id}/questions/${oldQ.id}`, {
            method: 'DELETE',
            headers: { Authorization: `Bearer ${token}` },
          });
        }
      }
    }

    // Refetch after possible deletion
    const freshRes = await request(`${API_BASE}/quizzes/${q.id}?includeAnswers=true`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const freshQuestions = freshRes.data?.data?.questions || [];

    for (const quest of q.questions) {
      const alreadyHasQuestion = freshQuestions.some(
        (x) => x.id === quest.id || x.question === quest.questionText
      );

      if (!alreadyHasQuestion) {
        console.log(`   ➕ Adding question: "${quest.questionText}"...`);
        const addQRes = await request(`${API_BASE}/admin/quizzes/${q.id}/questions`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
        }, {
          id: quest.id,
          questionText: quest.questionText,
          visualHint: quest.visualHint,
          explanation: quest.explanation,
          marks: quest.marks,
          displayOrder: quest.displayOrder,
          options: quest.options,
        });

        if (addQRes.status >= 300) {
          console.error(`   ❌ Failed to add question:`, addQRes);
        } else {
          console.log(`   ✓ Question added successfully.`);
        }
      } else {
        console.log(`   ✓ Question already exists: "${quest.questionText}"`);
      }
    }
  }

  console.log('\n🎉 Done syncing quizzes to production!');
  const finalRes = await request(`${API_BASE}/quizzes?all=true`, {});
  console.log(`Total quizzes now on production: ${finalRes.data?.data?.length}`);
  finalRes.data?.data?.forEach((q) => {
    console.log(` - [${q.display_order}] ${q.icon_emoji} ${q.title} (${q.category}) - ${q.actual_question_count} questions`);
  });
}

run().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
