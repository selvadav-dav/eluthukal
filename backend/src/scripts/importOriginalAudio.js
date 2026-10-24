const fs = require('fs');
const path = require('path');

const FRONTEND_DIR = path.resolve(__dirname, '../../../frontend');
const ORIGINAL_AUDIO_DIR = path.join(FRONTEND_DIR, 'assets/sounds/original audio');
const AUDIO_BASE_DIR = path.join(FRONTEND_DIR, 'assets/audio/tamil');
const SOUNDS_DIR = path.join(FRONTEND_DIR, 'assets/sounds');
const MANIFEST_FILE = path.join(AUDIO_BASE_DIR, 'audio_manifest.json');

const MEI_LETTERS = [
  { letter: 'க்', slug: 'mei_01_ik', baseKey: 'k' },
  { letter: 'ங்', slug: 'mei_02_ing', baseKey: 'ng' },
  { letter: 'ச்', slug: 'mei_03_ich', baseKey: 'c' },
  { letter: 'ஞ்', slug: 'mei_04_inj', baseKey: 'nj' },
  { letter: 'ட்', slug: 'mei_05_it', baseKey: 't' },
  { letter: 'ண்', slug: 'mei_06_inn', baseKey: 'nn' },
  { letter: 'த்', slug: 'mei_07_ith', baseKey: 'th' },
  { letter: 'ந்', slug: 'mei_08_inth', baseKey: 'nth' },
  { letter: 'ப்', slug: 'mei_09_ip', baseKey: 'p' },
  { letter: 'ம்', slug: 'mei_10_im', baseKey: 'm' },
  { letter: 'ய்', slug: 'mei_11_iy', baseKey: 'y' },
  { letter: 'ர்', slug: 'mei_12_ir', baseKey: 'r' },
  { letter: 'ல்', slug: 'mei_13_il', baseKey: 'l' },
  { letter: 'வ்', slug: 'mei_14_iv', baseKey: 'v' },
  { letter: 'ழ்', slug: 'mei_15_izh', baseKey: 'zh' },
  { letter: 'ள்', slug: 'mei_16_ill', baseKey: 'll' },
  { letter: 'ற்', slug: 'mei_17_irr', baseKey: 'rr' },
  { letter: 'ன்', slug: 'mei_18_in', baseKey: 'n' },
];

const UYIRMEI_SERIES = {
  'க்': ['க', 'கா', 'கி', 'கீ', 'கு', 'கூ', 'கெ', 'கே', 'கை', 'கொ', 'கோ', 'கௌ'],
  'ங்': ['ங', 'ஙா', 'ஙி', 'ஙீ', 'ஙு', 'ஙூ', 'ஙெ', 'ஙே', 'ஙை', 'ஙொ', 'ஙோ', 'ஙௌ'],
  'ச்': ['ச', 'சா', 'சி', 'சீ', 'சு', 'சூ', 'செ', 'சே', 'சை', 'சொ', 'சோ', 'சௌ'],
  'ஞ்': ['ஞ', 'ஞா', 'ஞி', 'ஞீ', 'ஞு', 'ஞூ', 'ஞெ', 'ஞே', 'ஞை', 'ஞொ', 'ஞோ', 'ஞௌ'],
  'ட்': ['ட', 'டா', 'டி', 'டீ', 'டு', 'டூ', 'டெ', 'டே', 'டை', 'டொ', 'டோ', 'டௌ'],
  'ண்': ['ண', 'ணா', 'ணி', 'ணீ', 'ணு', 'ணூ', 'ணெ', 'ணே', 'ணை', 'ணொ', 'ணோ', 'ணௌ'],
  'த்': ['த', 'தா', 'தி', 'தீ', 'து', 'தூ', 'தெ', 'தே', 'தை', 'தொ', 'தோ', 'தௌ'],
  'ந்': ['ந', 'நா', 'நி', 'நீ', 'நு', 'நூ', 'நெ', 'நே', 'நை', 'நொ', 'நோ', 'நௌ'],
  'ப்': ['ப', 'பா', 'பி', 'பீ', 'பு', 'பூ', 'பெ', 'பே', 'பை', 'பொ', 'போ', 'பௌ'],
  'ம்': ['ம', 'மா', 'மி', 'மீ', 'மு', 'மூ', 'மெ', 'மே', 'மை', 'மொ', 'மோ', 'மௌ'],
  'ய்': ['ய', 'யா', 'யி', 'யீ', 'யு', 'யூ', 'யெ', 'யே', 'யை', 'யொ', 'யோ', 'யௌ'],
  'ர்': ['ர', 'ரா', 'ரி', 'ரீ', 'ரு', 'ரூ', 'ரெ', 'ரே', 'ரை', 'ரொ', 'ரோ', 'ரௌ'],
  'ல்': ['ல', 'லா', 'லி', 'லீ', 'லு', 'லூ', 'லெ', 'லே', 'லை', 'லொ', 'லோ', 'லௌ'],
  'வ்': ['வ', 'வா', 'வி', 'வீ', 'வு', 'வூ', 'வெ', 'வே', 'வை', 'வொ', 'வோ', 'வௌ'],
  'ழ்': ['ழ', 'ழா', 'ழி', 'ழீ', 'ழு', 'ழூ', 'ழெ', 'ழே', 'ழை', 'ழொ', 'ழோ', 'ழௌ'],
  'ள்': ['ள', 'ளா', 'ளி', 'ளீ', 'ளு', 'ளூ', 'ளெ', 'ளே', 'ளை', 'ளொ', 'ளோ', 'ளௌ'],
  'ற்': ['ற', 'றா', 'றி', 'றீ', 'று', 'றூ', 'றெ', 'றே', 'றை', 'றொ', 'றோ', 'றௌ'],
  'ன்': ['ன', 'னா', 'னி', 'னீ', 'னு', 'னூ', 'னெ', 'னே', 'னை', 'னொ', 'னோ', 'னௌ'],
};

const VOWEL_SUFFIXES = ['a', 'aa', 'i', 'ee', 'u', 'oo', 'e', 'ae', 'ai', 'o', 'oo_long', 'au'];

// Build lookup tables
const targetMap = {};

// Aytham
targetMap['ஃ'] = {
  category: 'aytham',
  slug: 'aytham_01_ak',
  destRelative: 'assets/audio/tamil/aytham/aytham_01_ak.mp3',
  extraDestRelatives: [
    'assets/sounds/aytham_ஃ.mp3'
  ]
};

// Mei
for (const mei of MEI_LETTERS) {
  const shortSlug = mei.slug.replace(/_\d+_/, '_');
  targetMap[mei.letter] = {
    category: 'mei',
    slug: mei.slug,
    destRelative: `assets/audio/tamil/mei/${mei.slug}.mp3`,
    extraDestRelatives: [
      `assets/sounds/mei/${shortSlug}.mp3`,
      `assets/sounds/mei/${mei.slug}.mp3`,
      `assets/sounds/mei/${mei.letter}.mp3`
    ]
  };
}

// Uyirmei
let count = 0;
for (const mei of MEI_LETTERS) {
  const combos = UYIRMEI_SERIES[mei.letter];
  for (let i = 0; i < 12; i++) {
    count++;
    const letter = combos[i];
    const indexStr = String(count).padStart(3, '0');
    const suffix = VOWEL_SUFFIXES[i];
    const slug = `uyirmei_${indexStr}_${mei.baseKey}_${suffix}`;
    targetMap[letter] = {
      category: 'uyirmei',
      slug: slug,
      destRelative: `assets/audio/tamil/uyirmei/${slug}.mp3`,
      extraDestRelatives: [
        `assets/sounds/uyirmei/${letter}.mp3`,
        `assets/sounds/uyirmei/${slug}.mp3`
      ]
    };
  }
}

// Map mei + au (e.g. 'ள் ஒள' -> 'ளௌ')
// Both U+0B94 (ஔ) and composite U+0B92 U+0BB3 (ஒள)
const auMap = {
  'ங் ஒள': 'ஙௌ', 'ங் ஔ': 'ஙௌ',
  'ஞ் ஒள': 'ஞௌ', 'ஞ் ஔ': 'ஞௌ',
  'ண் ஒள': 'ணௌ', 'ண் ஔ': 'ணௌ',
  'ந் ஒள': 'நௌ', 'ந் ஔ': 'நௌ',
  'ன் ஒள': 'னௌ', 'ன் ஔ': 'னௌ',
  'ற் ஒள': 'றௌ', 'ற் ஔ': 'றௌ',
  'ல் ஒள': 'லௌ', 'ல் ஔ': 'லௌ',
  'ள் ஒள': 'ளௌ', 'ள் ஔ': 'ளௌ',
  'ழ் ஒள': 'ழௌ', 'ழ் ஔ': 'ழௌ',
};

function copyFileSafe(src, dest) {
  const destDir = path.dirname(dest);
  if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
  }
  fs.copyFileSync(src, dest);
}

function importAndReplaceAudio() {
  console.log('======================================================================');
  console.log('🔄 STARTING IMPORT & REPLACEMENT OF ORIGINAL AUDIO FILES');
  console.log(`📁 Source: ${ORIGINAL_AUDIO_DIR}`);
  console.log(`📁 Target: ${AUDIO_BASE_DIR}`);
  console.log('======================================================================\n');

  const files = fs.readdirSync(ORIGINAL_AUDIO_DIR);
  const matched = [];
  const duplicates = [];

  for (const file of files) {
    let clean = file.replace(/\.mp3$/i, '').trim();
    const isDuplicate = /\(\d+\)$/.test(clean);
    clean = clean.replace(/\s*\(\d+\)\s*$/, '').trim();

    let letter = null;
    if (clean.toLowerCase() === 'ak') {
      letter = 'ஃ';
    } else if (auMap[clean]) {
      letter = auMap[clean];
    } else if (targetMap[clean]) {
      letter = clean;
    }

    if (isDuplicate) {
      duplicates.push({ file, clean, letter });
      continue;
    }

    if (letter && targetMap[letter]) {
      matched.push({
        sourceFile: file,
        originalLabel: clean,
        letter: letter,
        target: targetMap[letter],
        size: fs.statSync(path.join(ORIGINAL_AUDIO_DIR, file)).size
      });
    } else {
      console.error(`⚠️ Unmapped file found: "${file}"`);
    }
  }

  console.log(`Found ${matched.length} unique original audio files to replace in app.`);
  console.log(`Skipped ${duplicates.length} duplicate copy files:`, duplicates.map(d => d.file));

  // Load manifest
  let manifest = {
    generatedAt: new Date().toISOString(),
    totalEntries: 0,
    audio: {},
  };
  if (fs.existsSync(MANIFEST_FILE)) {
    try {
      manifest = JSON.parse(fs.readFileSync(MANIFEST_FILE, 'utf8'));
      manifest.audio = manifest.audio || {};
    } catch (_) {}
  }

  let replacedCount = 0;
  let totalBytesCopied = 0;

  for (let i = 0; i < matched.length; i++) {
    const item = matched[i];
    const srcPath = path.join(ORIGINAL_AUDIO_DIR, item.sourceFile);
    const destPath = path.join(FRONTEND_DIR, item.target.destRelative);

    let oldSize = 0;
    if (fs.existsSync(destPath)) {
      oldSize = fs.statSync(destPath).size;
    }

    // 1. Copy to primary audio asset path
    copyFileSafe(srcPath, destPath);
    replacedCount++;
    totalBytesCopied += item.size;

    // 2. Copy to extra fallback asset paths
    if (item.target.extraDestRelatives) {
      for (const extraRel of item.target.extraDestRelatives) {
        const extraDestPath = path.join(FRONTEND_DIR, extraRel);
        copyFileSafe(srcPath, extraDestPath);
      }
    }

    // 3. Register in manifest
    manifest.audio[item.letter] = item.target.destRelative;
    if (item.originalLabel !== item.letter) {
      manifest.audio[item.originalLabel] = item.target.destRelative;
    }

    const diffStr = oldSize > 0
      ? `(replaced old ${(oldSize / 1024).toFixed(1)} KB with ${(item.size / 1024).toFixed(1)} KB)`
      : `(new file ${(item.size / 1024).toFixed(1)} KB)`;

    console.log(`✅ [${i + 1}/${matched.length}] "${item.sourceFile}" -> letter '${item.letter}' -> ${item.target.destRelative} ${diffStr}`);
  }

  // Write updated manifest
  manifest.lastUpdated = new Date().toISOString();
  manifest.totalEntries = Object.keys(manifest.audio).length;
  fs.writeFileSync(MANIFEST_FILE, JSON.stringify(manifest, null, 2), 'utf8');

  console.log('\n======================================================================');
  console.log('🎉 REPLACEMENT COMPLETE');
  console.log(`   - Total Letters Replaced: ${replacedCount}`);
  console.log(`   - Total Audio Data: ${(totalBytesCopied / (1024 * 1024)).toFixed(2)} MB`);
  console.log(`   - Manifest Updated: ${MANIFEST_FILE} (${manifest.totalEntries} entries)`);
  console.log('======================================================================');
}

importAndReplaceAudio();
