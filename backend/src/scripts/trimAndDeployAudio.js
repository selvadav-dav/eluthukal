const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const ffmpeg = require('ffmpeg-static');

const FRONTEND_DIR = path.resolve(__dirname, '../../../frontend');
const ORIGINAL_AUDIO_DIR = path.join(FRONTEND_DIR, 'assets/sounds/original audio');
const BACKUP_DIR = path.join(FRONTEND_DIR, 'assets/sounds/original audio raw backup');
const AUDIO_BASE_DIR = path.join(FRONTEND_DIR, 'assets/audio/tamil');
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

// Lookup mapping
const targetMap = {};
targetMap['ஃ'] = {
  category: 'aytham',
  slug: 'aytham_01_ak',
  destRelative: 'assets/audio/tamil/aytham/aytham_01_ak.mp3',
  extraDestRelatives: ['assets/sounds/aytham_ஃ.mp3']
};

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

function trimAndDeployAll() {
  console.log('======================================================================');
  console.log('✂️  TRIMMING LEADING SILENCE & DEPLOYING ORIGINAL AUDIO FILES');
  console.log('======================================================================\n');

  // Step 1: Backup raw original files once
  if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
    console.log(`📦 Creating safety backup in "${BACKUP_DIR}"...`);
    const allFiles = fs.readdirSync(ORIGINAL_AUDIO_DIR);
    for (const f of allFiles) {
      fs.copyFileSync(path.join(ORIGINAL_AUDIO_DIR, f), path.join(BACKUP_DIR, f));
    }
    console.log(`✅ Backed up ${allFiles.length} raw files.`);
  }

  const files = fs.readdirSync(ORIGINAL_AUDIO_DIR);
  let processedCount = 0;
  let totalTimeSavedSec = 0;

  console.log(`Processing ${files.length} audio files...`);

  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    const rawPath = path.join(BACKUP_DIR, file);
    const targetOriginalPath = path.join(ORIGINAL_AUDIO_DIR, file);

    // Source from backup to avoid re-trimming already trimmed files
    const srcInput = fs.existsSync(rawPath) ? rawPath : targetOriginalPath;
    const tempTrimmed = targetOriginalPath + '.trimmed.mp3';

    // Filter: removes silence before speech, then applies clean 40ms attack padding
    const filter = 'silenceremove=start_periods=1:start_duration=0.02:start_threshold=-40dB,adelay=40|40';

    const res = spawnSync(ffmpeg, [
      '-y',
      '-i', srcInput,
      '-af', filter,
      '-c:a', 'libmp3lame',
      '-q:a', '2',
      tempTrimmed
    ]);

    if (res.status === 0 && fs.existsSync(tempTrimmed) && fs.statSync(tempTrimmed).size > 1000) {
      const oldSize = fs.statSync(srcInput).size;
      const newSize = fs.statSync(tempTrimmed).size;
      fs.renameSync(tempTrimmed, targetOriginalPath);
      processedCount++;
    } else {
      if (fs.existsSync(tempTrimmed)) fs.unlinkSync(tempTrimmed);
      console.warn(`⚠️ Warning: Trim skipped or failed for ${file}`);
    }
  }

  console.log(`\n🎉 Successfully trimmed leading silence for ${processedCount} audio files.`);

  // Step 2: Deploy trimmed files to canonical app locations and update manifest
  console.log('\n🚀 Deploying trimmed files to app runtime paths...');

  const matched = [];
  const filesNow = fs.readdirSync(ORIGINAL_AUDIO_DIR);

  for (const file of filesNow) {
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

    if (isDuplicate) continue;

    if (letter && targetMap[letter]) {
      matched.push({
        sourceFile: file,
        originalLabel: clean,
        letter: letter,
        target: targetMap[letter]
      });
    }
  }

  let manifest = { generatedAt: new Date().toISOString(), totalEntries: 0, audio: {} };
  if (fs.existsSync(MANIFEST_FILE)) {
    try {
      manifest = JSON.parse(fs.readFileSync(MANIFEST_FILE, 'utf8'));
      manifest.audio = manifest.audio || {};
    } catch (_) {}
  }

  for (const item of matched) {
    const srcPath = path.join(ORIGINAL_AUDIO_DIR, item.sourceFile);
    const destPath = path.join(FRONTEND_DIR, item.target.destRelative);

    copyFileSafe(srcPath, destPath);

    if (item.target.extraDestRelatives) {
      for (const extraRel of item.target.extraDestRelatives) {
        copyFileSafe(srcPath, path.join(FRONTEND_DIR, extraRel));
      }
    }

    manifest.audio[item.letter] = item.target.destRelative;
    if (item.originalLabel !== item.letter) {
      manifest.audio[item.originalLabel] = item.target.destRelative;
    }
  }

  manifest.lastUpdated = new Date().toISOString();
  manifest.totalEntries = Object.keys(manifest.audio).length;
  fs.writeFileSync(MANIFEST_FILE, JSON.stringify(manifest, null, 2), 'utf8');

  console.log(`✅ Deployed ${matched.length} letters to frontend app.`);
  console.log(`✅ Manifest updated with ${manifest.totalEntries} entries.`);
  console.log('\n======================================================================');
  console.log('✨ ALL LEADING SILENCE ELIMINATED! AUDIO NOW PLAYS INSTANTLY ON TAP! ✨');
  console.log('======================================================================');
}

trimAndDeployAll();
