-- =====================================================================
-- AGARAM Tamil Children's Educational Platform
-- PostgreSQL Relational Schema with Foreign Keys, Indexes & Seed Data
-- =====================================================================

DROP TABLE IF EXISTS user_stars CASCADE;
DROP TABLE IF EXISTS quiz_results CASCADE;
DROP TABLE IF EXISTS user_progress CASCADE;
DROP TABLE IF EXISTS quiz_options CASCADE;
DROP TABLE IF EXISTS quiz_questions CASCADE;
DROP TABLE IF EXISTS quizzes CASCADE;
DROP TABLE IF EXISTS games CASCADE;
DROP TABLE IF EXISTS reading_story_pages CASCADE;
DROP TABLE IF EXISTS reading_stories CASCADE;
DROP TABLE IF EXISTS videos CASCADE;
DROP TABLE IF EXISTS letters CASCADE;
DROP TABLE IF EXISTS letter_groups CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS admins CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;
DROP TABLE IF EXISTS languages CASCADE;

-- 0. Table: languages
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS languages (
  id VARCHAR(10) PRIMARY KEY,
  code VARCHAR(10) NOT NULL UNIQUE,
  name VARCHAR(64) NOT NULL,
  native_name VARCHAR(64) NOT NULL,
  brand_title VARCHAR(64) NOT NULL DEFAULT 'அகரம்',
  flag_emoji VARCHAR(32) NOT NULL DEFAULT '🇮🇳',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ---------------------------------------------------------------------
-- 0.1 Table: tenants (Multi-Tenant Organization Support)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tenants (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  subdomain VARCHAR(64) UNIQUE,
  default_language VARCHAR(10) NOT NULL DEFAULT 'ta',
  logo_url VARCHAR(255) NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tenant_subdomain ON tenants (subdomain);
-- ---------------------------------------------------------------------
-- 1. Table: admins
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admins (
  id SERIAL PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(128) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'content_admin',
  full_name VARCHAR(128) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_admin_username ON admins (username);
CREATE INDEX IF NOT EXISTS idx_admin_email ON admins (email);
CREATE INDEX IF NOT EXISTS idx_admin_role ON admins (role);
-- ---------------------------------------------------------------------
-- 2. Table: users (Child Learners)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(64) PRIMARY KEY,
  child_name VARCHAR(128) NOT NULL DEFAULT 'குழந்தை',
  email VARCHAR(128) UNIQUE NULL,
  password_hash VARCHAR(255) NULL,
  age INT NOT NULL DEFAULT 5,
  avatar_asset VARCHAR(255) NOT NULL DEFAULT 'assets/images/welcome.png',
  total_stars INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_user_active ON users (is_active);
-- ---------------------------------------------------------------------
-- 3. Table: lessons (Educational Modules / Categories)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lessons (
  id VARCHAR(64) PRIMARY KEY,
  category_key VARCHAR(64) NOT NULL UNIQUE,
  title VARCHAR(128) NOT NULL,
  subtitle VARCHAR(255) DEFAULT '',
  count_text VARCHAR(64) DEFAULT '',
  button_text VARCHAR(64) DEFAULT 'கற்கலாம்',
  icon_emoji VARCHAR(32) DEFAULT '⭐',
  gradient_colors JSON,
  route_name VARCHAR(64) DEFAULT '',
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lesson_order ON lessons (display_order);
CREATE INDEX IF NOT EXISTS idx_lesson_active ON lessons (is_active);
-- ---------------------------------------------------------------------
-- 4. Table: letter_groups (Classification for Uyir, Mei, Uyirmei, Aytham)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS letter_groups (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  display_title VARCHAR(128) NOT NULL,
  letter_type VARCHAR(32) NOT NULL,
  description TEXT,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_group_type ON letter_groups (letter_type);
CREATE INDEX IF NOT EXISTS idx_group_order ON letter_groups (display_order);
-- ---------------------------------------------------------------------
-- 5. Table: letters
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS letters (
  id VARCHAR(64) PRIMARY KEY,
  letter VARCHAR(32) NOT NULL,
  type VARCHAR(32) NOT NULL,
  group_id VARCHAR(64) NULL,
  word VARCHAR(128) NOT NULL,
  meaning VARCHAR(128) NOT NULL,
  phonetic VARCHAR(128) NOT NULL,
  icon_emoji VARCHAR(32) DEFAULT '⭐',
  image_path VARCHAR(500) NULL,
  audio_path VARCHAR(500) NULL,
  video_url VARCHAR(500) NULL,
  explanation TEXT NULL,
  mei_base VARCHAR(32) NULL,
  uyir_base VARCHAR(32) NULL,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (group_id) REFERENCES letter_groups(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_letter_type ON letters (type);
CREATE INDEX IF NOT EXISTS idx_letter_order ON letters (display_order);
CREATE INDEX IF NOT EXISTS idx_letter_active ON letters (is_active);
-- ---------------------------------------------------------------------
-- 6. Table: reading_stories
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reading_stories (
  id VARCHAR(64) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  subtitle VARCHAR(255) DEFAULT '',
  cover_emoji VARCHAR(32) DEFAULT '📖',
  cover_image VARCHAR(255) NULL,
  moral VARCHAR(255) DEFAULT '',
  display_order INT NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_story_published ON reading_stories (is_published);
CREATE INDEX IF NOT EXISTS idx_story_order ON reading_stories (display_order);
-- ---------------------------------------------------------------------
-- 7. Table: reading_story_pages
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reading_story_pages (
  id SERIAL PRIMARY KEY,
  story_id VARCHAR(64) NOT NULL,
  page_number INT NOT NULL,
  text TEXT NOT NULL,
  emoji_illustration VARCHAR(32) DEFAULT '🐰',
  character_name VARCHAR(128) DEFAULT '',
  narrator_audio VARCHAR(255) NULL,
  image_path VARCHAR(255) NULL,
  interactive_words JSON NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (story_id) REFERENCES reading_stories(id) ON DELETE CASCADE,
  CONSTRAINT uk_story_page UNIQUE (story_id, page_number)
);

CREATE INDEX IF NOT EXISTS idx_page_story ON reading_story_pages (story_id);
-- ---------------------------------------------------------------------
-- 8. Table: videos
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS videos (
  id VARCHAR(64) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  category VARCHAR(64) NOT NULL DEFAULT 'பாடல்',
  duration VARCHAR(32) DEFAULT '03:00',
  thumbnail_emoji VARCHAR(32) DEFAULT '🎬',
  thumbnail_image VARCHAR(255) NULL,
  video_url VARCHAR(500) NOT NULL,
  local_video_path VARCHAR(255) NULL,
  display_order INT NOT NULL DEFAULT 0,
  is_published BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_video_category ON videos (category);
CREATE INDEX IF NOT EXISTS idx_video_published ON videos (is_published);
-- ---------------------------------------------------------------------
-- 9. Table: quizzes
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quizzes (
  id VARCHAR(64) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  subtitle VARCHAR(255) DEFAULT '',
  icon_emoji VARCHAR(32) DEFAULT '❓',
  category VARCHAR(64) NOT NULL DEFAULT 'uyir',
  question_count INT NOT NULL DEFAULT 5,
  pass_marks INT NOT NULL DEFAULT 3,
  stars_reward INT NOT NULL DEFAULT 5,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_quiz_category ON quizzes (category);
CREATE INDEX IF NOT EXISTS idx_quiz_active ON quizzes (is_active);
-- ---------------------------------------------------------------------
-- 10. Table: quiz_questions
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quiz_questions (
  id VARCHAR(64) PRIMARY KEY,
  quiz_id VARCHAR(64) NOT NULL,
  question_text TEXT NOT NULL,
  visual_hint VARCHAR(64) NULL,
  visual_image VARCHAR(255) NULL,
  explanation TEXT NULL,
  marks INT NOT NULL DEFAULT 1,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_question_quiz ON quiz_questions (quiz_id);
CREATE INDEX IF NOT EXISTS idx_question_order ON quiz_questions (display_order);
-- ---------------------------------------------------------------------
-- 11. Table: quiz_options
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quiz_options (
  id SERIAL PRIMARY KEY,
  question_id VARCHAR(64) NOT NULL,
  option_text VARCHAR(255) NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (question_id) REFERENCES quiz_questions(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_option_question ON quiz_options (question_id);
-- ---------------------------------------------------------------------
-- 12. Table: games
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS games (
  id VARCHAR(64) PRIMARY KEY,
  game_type VARCHAR(64) NOT NULL,
  title VARCHAR(255) NOT NULL,
  prompt TEXT NOT NULL,
  clue TEXT NULL,
  clue_image VARCHAR(255) NULL,
  correct_index INT NOT NULL DEFAULT 0,
  options_json JSON NOT NULL,
  success_praise VARCHAR(255) DEFAULT 'சூப்பர்! ⭐',
  stars_reward INT NOT NULL DEFAULT 3,
  display_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_game_type ON games (game_type);
CREATE INDEX IF NOT EXISTS idx_game_active ON games (is_active);
-- ---------------------------------------------------------------------
-- 13. Table: user_progress
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_progress (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  content_type VARCHAR(32) NOT NULL,
  content_id VARCHAR(64) NOT NULL,
  completion_status VARCHAR(32) NOT NULL DEFAULT 'completed',
  completion_percentage INT NOT NULL DEFAULT 100,
  stars_earned INT NOT NULL DEFAULT 1,
  last_accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT uk_user_content UNIQUE (user_id, content_type, content_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_user ON user_progress (user_id);
CREATE INDEX IF NOT EXISTS idx_progress_content ON user_progress (content_type, content_id);
-- ---------------------------------------------------------------------
-- 14. Table: quiz_results
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quiz_results (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL,
  quiz_id VARCHAR(64) NOT NULL,
  score INT NOT NULL DEFAULT 0,
  total_questions INT NOT NULL DEFAULT 0,
  correct_answers INT NOT NULL DEFAULT 0,
  stars_earned INT NOT NULL DEFAULT 0,
  attempt_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_result_user ON quiz_results (user_id);
CREATE INDEX IF NOT EXISTS idx_result_quiz ON quiz_results (quiz_id);
-- ---------------------------------------------------------------------
-- 15. Table: user_stars (Streak and aggregate star ledger)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_stars (
  user_id VARCHAR(64) PRIMARY KEY,
  total_stars INT NOT NULL DEFAULT 0,
  current_streak INT NOT NULL DEFAULT 1,
  highest_streak INT NOT NULL DEFAULT 1,
  last_earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
-- =====================================================================
-- INITIAL SEED DATA
-- =====================================================================

-- Default Super Admin (username: superadmin, password: Admin@123)
INSERT INTO admins (username, email, password_hash, role, full_name, is_active)
VALUES (
  'superadmin',
  'admin@gmail.com',
  '$2a$10$3Gmn4mOc6xZ1rhY4H60qLOFsdSPDb.9XDlorRu6SWzBDC/7T08pS.',
  'super_admin',
  'AGARAM Super Admin',
  TRUE
) ON CONFLICT (username) DO UPDATE SET email = EXCLUDED.email, password_hash = EXCLUDED.password_hash;

-- Default Child User
INSERT INTO users (id, child_name, age, avatar_asset, total_stars, is_active)
VALUES ('default_child', 'குழந்தை', 5, 'assets/images/welcome.png', 25, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO user_stars (user_id, total_stars, current_streak, highest_streak)
VALUES ('default_child', 25, 3, 5)
ON CONFLICT DO NOTHING;

-- Lesson Categories
INSERT INTO lessons (id, category_key, title, subtitle, count_text, button_text, icon_emoji, gradient_colors, route_name, display_order)
VALUES
('lesson_uyir', 'uyir', 'உயிர் எழுத்துகள்', 'அ முதல் ஔ வரை இனிமையாக கற்போம்', '12 உயிர் எழுத்துகள்', 'கற்கலாம்', '🍎', '["#FF6B8B", "#FF8E53"]', '/uyir', 1),
('lesson_mei', 'mei', 'மெய் எழுத்துகள்', 'க் முதல் ன் வரை புள்ளியிட்ட எழுத்துகள்', '18 மெய் எழுத்துகள்', 'கற்கலாம்', '🎡', '["#4E65FF", "#92EFFD"]', '/mei', 2),
('lesson_aytham', 'aytham', 'ஆய்த எழுத்து', 'முப்புள்ளி கொண்ட தனித்தமிழ் எழுத்து', 'ஆய்தம் – 1', 'கற்கலாம்', '🛡️', '["#A855F7", "#EC4899"]', '/aytham', 3),
('lesson_uyirmei', 'uyirmei', 'உயிர்மெய் எழுத்துகள்', 'உயிரும் மெய்யும் கூடிப் பிறக்கும் எழுத்துகள்', '216 உயிர்மெய் எழுத்துகள்', 'கற்கலாம்', '🌱', '["#11998E", "#38EF7D"]', '/uyirmei', 4),
('lesson_reading', 'reading', 'வாசிப்பு', 'படம் பார்த்து சிறுகதைகள் வாசிப்போம்', 'சிறு கதைகள்', 'வாசிக்கலாம்', '📚', '["#FF8008", "#FFC837"]', '/reading', 5)
ON CONFLICT DO NOTHING;

-- Letter Groups
INSERT INTO letter_groups (id, name, display_title, letter_type, description, display_order)
VALUES
('group_uyir', 'Uyir Letters', 'உயிர் எழுத்துகள் (12)', 'uyir', 'தமிழ் மொழியின் உயிரான 12 எழுத்துகள்', 1),
('group_mei', 'Mei Letters', 'மெய் எழுத்துகள் (18)', 'mei', 'புள்ளியிட்ட 18 மெய் எழுத்துகள்', 2),
('group_aytham', 'Aytham Letter', 'ஆய்த எழுத்து (1)', 'aytham', 'தனித்தன்மை கொண்ட ஆய்த எழுத்து', 3),
('group_uyirmei_ka', 'Ka Varisai', 'க வரிசை (12)', 'uyirmei', 'க் + உயிர் எழுத்துகள்', 4),
('group_uyirmei_nga', 'Nga Varisai', 'ங வரிசை (12)', 'uyirmei', 'ங் + உயிர் எழுத்துகள்', 5),
('group_uyirmei_sa', 'Sa Varisai', 'ச வரிசை (12)', 'uyirmei', 'ச் + உயிர் எழுத்துகள்', 6),
('group_uyirmei_nya', 'Nya Varisai', 'ஞ வரிசை (12)', 'uyirmei', 'ஞ் + உயிர் எழுத்துகள்', 7),
('group_uyirmei_ta', 'Ta Varisai', 'ட வரிசை (12)', 'uyirmei', 'ட் + உயிர் எழுத்துகள்', 8),
('group_uyirmei_nna', 'Nna Varisai', 'ண வரிசை (12)', 'uyirmei', 'ண் + உயிர் எழுத்துகள்', 9),
('group_uyirmei_tha', 'Tha Varisai', 'த வரிசை (12)', 'uyirmei', 'த் + உயிர் எழுத்துகள்', 10),
('group_uyirmei_na', 'Na Varisai', 'ந வரிசை (12)', 'uyirmei', 'ந் + உயிர் எழுத்துகள்', 11),
('group_uyirmei_pa', 'Pa Varisai', 'ப வரிசை (12)', 'uyirmei', 'ப் + உயிர் எழுத்துகள்', 12),
('group_uyirmei_ma', 'Ma Varisai', 'ம வரிசை (12)', 'uyirmei', 'ம் + உயிர் எழுத்துகள்', 13),
('group_uyirmei_ya', 'Ya Varisai', 'ய வரிசை (12)', 'uyirmei', 'ய் + உயிர் எழுத்துகள்', 14),
('group_uyirmei_ra', 'Ra Varisai', 'ர வரிசை (12)', 'uyirmei', 'ர் + உயிர் எழுத்துகள்', 15),
('group_uyirmei_la', 'La Varisai', 'ல வரிசை (12)', 'uyirmei', 'ல் + உயிர் எழுத்துகள்', 16),
('group_uyirmei_va', 'Va Varisai', 'வ வரிசை (12)', 'uyirmei', 'வ் + உயிர் எழுத்துகள்', 17),
('group_uyirmei_zha', 'Zha Varisai', 'ழ வரிசை (12)', 'uyirmei', 'ழ் + உயிர் எழுத்துகள்', 18),
('group_uyirmei_lla', 'Lla Varisai', 'ள வரிசை (12)', 'uyirmei', 'ள் + உயிர் எழுத்துகள்', 19),
('group_uyirmei_rra', 'Rra Varisai', 'ற வரிசை (12)', 'uyirmei', 'ற் + உயிர் எழுத்துகள்', 20),
('group_uyirmei_nna2', 'Nna2 Varisai', 'ன வரிசை (12)', 'uyirmei', 'ன் + உயிர் எழுத்துகள்', 21)
ON CONFLICT DO NOTHING;

-- 12 Uyir Letters
INSERT INTO letters (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, image_path, explanation, display_order)
VALUES
('uyir_a', 'அ', 'uyir', 'group_uyir', 'அம்மா', 'Mother', 'a', '👩‍👧', 'assets/images/amma.jpg', 'அன்பான அம்மா', 1),
('uyir_aa', 'ஆ', 'uyir', 'group_uyir', 'ஆடு', 'Goat', 'aa', '🐐', 'assets/images/aadu.jpg', 'துள்ளி ஓடும் ஆடு', 2),
('uyir_i', 'இ', 'uyir', 'group_uyir', 'இலை', 'Leaf', 'i', '🍃', 'assets/images/leaf.jpg', 'பச்சை இலை', 3),
('uyir_ee', 'ஈ', 'uyir', 'group_uyir', 'ஈ', 'Fly', 'ee', '🪰', 'assets/images/jiv.jpg', 'சுறுசுறுப்பான ஈ', 4),
('uyir_u', 'உ', 'uyir', 'group_uyir', 'உரல்', 'Mortar', 'u', '🥣', 'assets/images/ural.png', 'மர உரல்', 5),
('uyir_oo', 'ஊ', 'uyir', 'group_uyir', 'ஊஞ்சல்', 'Swing', 'oo', '🎪', 'assets/images/swing (2).jpg', 'ஆடும் ஊஞ்சல்', 6),
('uyir_e', 'எ', 'uyir', 'group_uyir', 'எலி', 'Rat', 'e', '🐭', 'assets/images/rat.jpg', 'சுட்டி எலி', 7),
('uyir_ae', 'ஏ', 'uyir', 'group_uyir', 'ஏணி', 'Ladder', 'ae', '🪜', 'assets/images/lader.jpg', 'உயரமான ஏணி', 8),
('uyir_ai', 'ஐ', 'uyir', 'group_uyir', 'ஐந்து', 'Five', 'ai', '🖐️', 'assets/images/number.jpg', 'ஐந்து விரல்கள்', 9),
('uyir_o', 'ஒ', 'uyir', 'group_uyir', 'ஒட்டகம்', 'Camel', 'o', '🐪', 'assets/images/camel.jpg', 'பாலைவன ஒட்டகம்', 10),
('uyir_oa', 'ஓ', 'uyir', 'group_uyir', 'ஓடம்', 'Boat', 'oa', '⛵', 'assets/images/river.jpg', 'மிதக்கும் ஓடம்', 11),
('uyir_au', 'ஔ', 'uyir', 'group_uyir', 'ஔவையார்', 'Avvaiyar', 'au', '👵', 'assets/images/avaiyar.jpg', 'தமிழ் மூதாட்டி', 12)
ON CONFLICT DO NOTHING;

-- Aytham Letter
INSERT INTO letters (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, image_path, explanation, display_order)
VALUES
('aytham_ak', 'ஃ', 'aytham', 'group_aytham', 'எஃகு', 'Steel', 'ak', '⚔️', 'assets/images/sward.jpg', 'உறுதியான எஃகு வாள்', 1)
ON CONFLICT DO NOTHING;

-- 18 Mei Letters (Key samples)
INSERT INTO letters (id, letter, type, group_id, word, meaning, phonetic, icon_emoji, image_path, explanation, display_order)
VALUES
('mei_ik', 'க்', 'mei', 'group_mei', 'சக்கரம்', 'Wheel', 'ik', '🎡', 'assets/images/wheel.jpg', 'சுழலும் சக்கரம்', 1),
('mei_ing', 'ங்', 'mei', 'group_mei', 'சங்கு', 'Conch', 'ing', '🐚', 'assets/images/sangu.png', 'கடல் சங்கு', 2),
('mei_ich', 'ச்', 'mei', 'group_mei', 'எலுமிச்சை', 'புளிப்பான எலுமிச்சை', 'ich', '🍋', NULL, 'மெய் எழுத்து "ச்". (எலுமிச்சை)', 3),
('mei_inj', 'ஞ்', 'mei', 'group_mei', 'ஊஞ்சல்', 'Swing', 'inj', '🎪', 'assets/images/swing (2).jpg', 'ஆடும் ஊஞ்சல்', 4),
('mei_it', 'ட்', 'mei', 'group_mei', 'பட்டம்', 'Kite', 'iT', '🪁', 'assets/images/skite.jpg', 'பறக்கும் பட்டம்', 5),
('mei_inn', 'ண்', 'mei', 'group_mei', 'கண்', 'Eye', 'iN', '👁️', 'assets/images/eye.jpg', 'அழகிய கண்', 6),
('mei_ith', 'த்', 'mei', 'group_mei', 'நத்தை', 'Snail', 'ith', '🐌', 'assets/images/snail.jpg', 'மெல்ல நகரும் நத்தை', 7),
('mei_indh', 'ந்', 'mei', 'group_mei', 'பந்து', 'Ball', 'indh', '⚽', 'assets/images/ball.jpg', 'விளையாடும் பந்து', 8),
('mei_ip', 'ப்', 'mei', 'group_mei', 'கப்பல்', 'Ship', 'ip', '🚢', 'assets/images/ship.jpg', 'பெரிய கப்பல்', 9),
('mei_im', 'ம்', 'mei', 'group_mei', 'மரம்', 'Tree', 'im', '🌳', 'assets/images/tree.jpg', 'நிழல் தரும் மரம்', 10),
('mei_iy', 'ய்', 'mei', 'group_mei', 'பாய்', 'Mat', 'iy', '🧺', 'assets/images/mat.jpg', 'படுக்க உதவும் பாய்', 11),
('mei_ir', 'ர்', 'mei', 'group_mei', 'தேர்', 'கோவில் தேர்', 'ir', '🛕', NULL, 'மெய் எழுத்து "ர்". (தேர்)', 12),
('mei_il', 'ல்', 'mei', 'group_mei', 'சேவல்', 'Rooster', 'il', '🐓', 'assets/images/hen.jpg', 'கூவும் சேவல்', 13),
('mei_iv', 'வ்', 'mei', 'group_mei', 'செவ்வானம்', 'மாலைச் செவ்வானம்', 'iv', '🌅', 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1791177499/agaram_media/images/backend_pic__tura_de_ap___s__n__toas___1789718909825_30607.jpg', 'மெய் எழுத்து "வ்". (செவ்வானம்)', 14),
('mei_izh', 'ழ்', 'mei', 'group_mei', 'யாழ்', 'Harp', 'izh', '🪕', 'assets/images/Harp.jpg', 'இசைக்கும் யாழ்', 15),
('mei_ill', 'ள்', 'mei', 'group_mei', 'வாள்', 'Sword', 'ill', '🗡️', 'assets/images/sward.jpg', 'வீர வாள்', 16),
('mei_irr', 'ற்', 'mei', 'group_mei', 'வெற்றிலை', 'பச்சை வெற்றிலை', 'irr', '🍃', 'https://res.cloudinary.com/dy8bu8suk/image/upload/v1791177419/agaram_media/images/frontend_leaf.jpg', 'மெய் எழுத்து "ற்". (வெற்றிலை)', 17),
('mei_in', 'ன்', 'mei', 'group_mei', 'மீன்', 'Fish', 'in', '🐟', 'assets/images/fish.jpg', 'நீந்தும் மீன்', 18)
ON CONFLICT DO NOTHING;

-- Reading Story: முயலும் ஆமையும்
INSERT INTO reading_stories (id, title, subtitle, cover_emoji, cover_image, moral, display_order, is_published)
VALUES
('story_tortoise_rabbit', 'முயலும் ஆமையும்', 'முயற்சி திருவினையாக்கும்!', '🐰🐢', 'assets/images/story_friends.jpg', 'பொறுமையும் தொடர் முயற்சியும் எப்போதும் வெற்றி தரும்!', 1, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO reading_story_pages (story_id, page_number, text, emoji_illustration, character_name, image_path, interactive_words)
VALUES
('story_tortoise_rabbit', 1, 'ஒரு காட்டில் முயலும் ஆமையும் வாழ்ந்தன.', '🌲🐰 🐢🌿', 'காடு', 'assets/images/story_forest.jpg', '[{"word":"காட்டில்","displayLabel":"காடு","imagePath":"assets/images/story_forest.jpg","emoji":"🌲","meaning":"அழகான காடு (Forest)"},{"word":"முயலும்","displayLabel":"முயல்","imagePath":"assets/images/story_rabbit.jpg","emoji":"🐰","meaning":"சுட்டி முயல் (Rabbit)"},{"word":"ஆமையும்","displayLabel":"ஆமை","imagePath":"assets/images/story_tortoise.jpg","emoji":"🐢","meaning":"அன்பான ஆமை (Tortoise)"}]'),
('story_tortoise_rabbit', 2, 'முயல் வேகமாக ஓடும்.\nஆமை மெதுவாக நடக்கும்.', '🐰💨 🐢🐾', 'முயலும் ஆமையும்', 'assets/images/story_friends.jpg', NULL),
('story_tortoise_rabbit', 3, 'இருவரும் ஓட்டப்பந்தயம் வைத்தனர்.\nமுயல் வேகமாக ஓடியது.', '🏁🐰💨 ... 🐢', 'ஓட்டப்பந்தயம்', 'assets/images/story_race.jpg', NULL),
('story_tortoise_rabbit', 4, 'முயல் மரத்தடியில் தூங்கிவிட்டது.\nஆமை தொடர்ந்து நடந்தது.', '🌳😴🐰💤  🐢🐾', 'தூங்கும் முயல்', 'assets/images/story_sleeping_rabbit.jpg', NULL),
('story_tortoise_rabbit', 5, 'ஆமை முதலில் சென்றது.\nபோட்டியில் வெற்றி பெற்றது!', '🎉🏆🐢✨ 😲🐰', 'வெற்றி!', 'assets/images/story_victory.jpg', NULL),
('story_tortoise_rabbit', 6, 'முயல் தன் தவறை உணர்ந்தது.\nவிடாமுயற்சி வெற்றி தரும்!', '🌟🤝🐰🐢💖', 'நீதி', 'assets/images/story_friends.jpg', NULL)
ON CONFLICT DO NOTHING;

-- Videos (12 Uyir + 18 Mei letters from Cloudinary)
INSERT INTO videos (id, title, description, category, duration, thumbnail_emoji, video_url, display_order, is_published)
VALUES
('vid_uyir_1', 'அ', 'உயிர் எழுத்து அ (அம்மா)', 'உயிர் எழுத்துகள்', '00:15', '🎬அ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790841742/agaram_media/videos/lyai8f00wea5mpvknty5.mp4', 1, TRUE),
('vid_uyir_2', 'ஆ', 'உயிர் எழுத்து ஆ (ஆடு)', 'உயிர் எழுத்துகள்', '00:15', '🎬ஆ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849387/agaram_media/videos/yileko0mif4cuduhy3ty.mp4', 2, TRUE),
('vid_uyir_3', 'இ', 'உயிர் எழுத்து இ (இலை)', 'உயிர் எழுத்துகள்', '00:15', '🎬இ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849484/agaram_media/videos/pskdcrc7xqmdsqbgh9no.mp4', 3, TRUE),
('vid_uyir_4', 'ஈ', 'உயிர் எழுத்து ஈ (ஈ)', 'உயிர் எழுத்துகள்', '00:15', '🎬ஈ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849525/agaram_media/videos/lhylws8eq0iijt9azfhp.mp4', 4, TRUE),
('vid_uyir_5', 'உ', 'உயிர் எழுத்து உ (உரல்)', 'உயிர் எழுத்துகள்', '00:15', '🎬உ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849570/agaram_media/videos/srteaw6jwtppkt0e6esl.mp4', 5, TRUE),
('vid_uyir_6', 'ஊ', 'உயிர் எழுத்து ஊ (ஊஞ்சல்)', 'உயிர் எழுத்துகள்', '00:15', '🎬ஊ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849604/agaram_media/videos/mvtffw845vapnhrhokcu.mp4', 6, TRUE),
('vid_uyir_7', 'எ', 'உயிர் எழுத்து எ (எலி)', 'உயிர் எழுத்துகள்', '00:15', '🎬எ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849714/agaram_media/videos/losz1xmdpogdsyb3kfkb.mp4', 7, TRUE),
('vid_uyir_8', 'ஏ', 'உயிர் எழுத்து ஏ (ஏணி)', 'உயிர் எழுத்துகள்', '00:15', '🎬ஏ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849774/agaram_media/videos/ctcqwju9p8xcdppwxogk.mp4', 8, TRUE),
('vid_uyir_9', 'ஐ', 'உயிர் எழுத்து ஐ (ஐந்து)', 'உயிர் எழுத்துகள்', '00:15', '🎬ஐ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790849825/agaram_media/videos/abyi5xu4ffymff9ioosy.mp4', 9, TRUE),
('vid_uyir_10', 'ஒ', 'உயிர் எழுத்து ஒ (ஒட்டகம்)', 'உயிர் எழுத்துகள்', '00:15', '🎬ஒ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790854598/agaram_media/videos/ranfb0lwkaspm4mffrqp.mp4', 10, TRUE),
('vid_uyir_11', 'ஓ', 'உயிர் எழுத்து ஓ (ஓடம்)', 'உயிர் எழுத்துகள்', '00:15', '🎬ஓ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790854646/agaram_media/videos/gv3wggfnpbus8n2fol4c.mp4', 11, TRUE),
('vid_uyir_12', 'ஔ', 'உயிர் எழுத்து ஔ (ஔவையார்)', 'உயிர் எழுத்துகள்', '00:15', '🎬ஔ', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1790855080/agaram_media/videos/btefhsc3k9n0kgfhmcrn.mp4', 12, TRUE),
('vid_mei_1', 'க்', 'மெய் எழுத்து க் (சக்கரம்)', 'மெய் எழுத்துகள்', '00:15', '✍️க்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791006753/agaram_media/videos/fg18xjxo2q4p9wsyfvpo.mp4', 1, TRUE),
('vid_mei_2', 'ங்', 'மெய் எழுத்து ங் (சங்கு)', 'மெய் எழுத்துகள்', '00:15', '✍️ங்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007508/agaram_media/videos/zjmzubpswzwhlkvl5ojn.mp4', 2, TRUE),
('vid_mei_3', 'ச்', 'மெய் எழுத்துச் (தச்சர்)', 'மெய் எழுத்துகள்', '00:15', '✍️ச்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007812/agaram_media/videos/fsagxkudps6vh6lybuno.mp4', 3, TRUE),
('vid_mei_4', 'ஞ்', 'மெய் எழுத்து ஞ் (ஊஞ்சல்)', 'மெய் எழுத்துகள்', '00:15', '✍️ஞ்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791007916/agaram_media/videos/ykprwmafp4al32alrsa6.mp4', 4, TRUE),
('vid_mei_5', 'ட்', 'மெய் எழுத்து ட் (பட்டம்)', 'மெய் எழுத்துகள்', '00:15', '✍️ட்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791008045/agaram_media/videos/sd0kk4jfqz572vowz63j.mp4', 5, TRUE),
('vid_mei_6', 'ண்', 'மெய் எழுத்து ண் (கண்)', 'மெய் எழுத்துகள்', '00:15', '✍️ண்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791011858/agaram_media/videos/mrj9929eyumtpsvwvk49.mp4', 6, TRUE),
('vid_mei_7', 'த்', 'மெய் எழுத்து த் (நத்தை)', 'மெய் எழுத்துகள்', '00:15', '✍️த்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791012537/agaram_media/videos/xayiuz964o3qwkbtpjkr.mp4', 7, TRUE),
('vid_mei_8', 'ந்', 'மெய் எழுத்து ந் (பந்து)', 'மெய் எழுத்துகள்', '00:15', '✍️ந்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791012754/agaram_media/videos/jb0av76qcjimjylof1oh.mp4', 8, TRUE),
('vid_mei_9', 'ப்', 'மெய் எழுத்து ப் (கப்பல்)', 'மெய் எழுத்துகள்', '00:15', '✍️ப்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791013206/agaram_media/videos/hgdp4p7sjj4zuemigges.mp4', 9, TRUE),
('vid_mei_10', 'ம்', 'மெய் எழுத்து ம் (மரம்)', 'மெய் எழுத்துகள்', '00:15', '✍️ம்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178025/agaram_media/videos/rvu5tcop5a4inyy2myty.mp4', 10, TRUE),
('vid_mei_11', 'ய்', 'மெய் எழுத்து ய் (பாய்)', 'மெய் எழுத்துகள்', '00:15', '✍️ய்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178322/agaram_media/videos/pzjgq9yxjcf3xcyaxbbh.mp4', 11, TRUE),
('vid_mei_12', 'ர்', 'மெய் எழுத்து ர் (ஏர்)', 'மெய் எழுத்துகள்', '00:15', '✍️ர்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791178852/agaram_media/videos/k4tqtli6kuwysaqx7muw.mp4', 12, TRUE),
('vid_mei_13', 'ல்', 'மெய் எழுத்து ல் (சேவல்)', 'மெய் எழுத்துகள்', '00:15', '✍️ல்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179035/agaram_media/videos/p8fcozkulcpzcpvdcsgd.mp4', 13, TRUE),
('vid_mei_14', 'வ்', 'மெய் எழுத்து வ் (செவ்வந்தி)', 'மெய் எழுத்துகள்', '00:15', '✍️வ்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179306/agaram_media/videos/jkhfxzw7ksobhb7hawpv.mp4', 14, TRUE),
('vid_mei_15', 'ழ்', 'மெய் எழுத்து ழ் (யாழ்)', 'மெய் எழுத்துகள்', '00:15', '✍️ழ்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179352/agaram_media/videos/iinovuxh3dnlsajorpsp.mp4', 15, TRUE),
('vid_mei_16', 'ள்', 'மெய் எழுத்து ள் (வாள்)', 'மெய் எழுத்துகள்', '00:15', '✍️ள்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179466/agaram_media/videos/ibjoez182v1nsagtyedb.mp4', 16, TRUE),
('vid_mei_17', 'ற்', 'மெய் எழுத்து ற் (புற்று)', 'மெய் எழுத்துகள்', '00:15', '✍️ற்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179595/agaram_media/videos/umbutwkkjznope99qwnw.mp4', 17, TRUE),
('vid_mei_18', 'ன்', 'மெய் எழுத்து ன் (மீன்)', 'மெய் எழுத்துகள்', '00:15', '✍️ன்', 'https://res.cloudinary.com/dy8bu8suk/video/upload/v1791179910/agaram_media/videos/asrp5x7m9ynstmklzx40.mp4', 18, TRUE)
ON CONFLICT (id) DO UPDATE SET 
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  thumbnail_emoji = EXCLUDED.thumbnail_emoji,
  video_url = EXCLUDED.video_url,
  display_order = EXCLUDED.display_order,
  is_published = EXCLUDED.is_published;

-- Quizzes
INSERT INTO quizzes (id, title, subtitle, icon_emoji, category, question_count, pass_marks, stars_reward, is_active, display_order)
VALUES
('quiz_uyir', 'உயிர் எழுத்துகள் வினாடி வினா', '12 உயிர் எழுத்துகளின் வினாடி வினா', '🍎', 'uyir', 4, 3, 5, TRUE, 1),
('quiz_mei', 'மெய் எழுத்துகள் வினாடி வினா', '18 மெய் எழுத்துகளின் வினாடி வினா', '🎡', 'mei', 4, 3, 5, TRUE, 2),
('quiz_aytham', 'ஆய்த எழுத்து வினாடி வினா', 'ஃ எழுத்து பற்றிய வினாடி வினா', '🛡️', 'aytham', 3, 2, 5, TRUE, 3),
('quiz_uyirmei', 'உயிர்மெய் எழுத்துகள் வினாடி வினா', 'உயிர் + மெய் கூட்டு எழுத்துகள்', '🌱', 'uyirmei', 4, 3, 5, TRUE, 4),
('quiz_reading', 'வாசிப்பு வினாடி வினா', 'கதை மற்றும் சொற்கள் புரிதல்', '📖', 'reading', 3, 2, 5, TRUE, 5)
ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle, icon_emoji = EXCLUDED.icon_emoji, category = EXCLUDED.category, question_count = EXCLUDED.question_count, pass_marks = EXCLUDED.pass_marks, stars_reward = EXCLUDED.stars_reward;

-- Quiz Questions
INSERT INTO quiz_questions (id, quiz_id, question_text, visual_hint, explanation, marks, display_order, is_active)
VALUES
('qu_1', 'quiz_uyir', 'தமிழ் உயிர் எழுத்துகள் மொத்தம் எத்தனை?', '🔢', 'தமிழ் மொழியில் மொத்தம் 12 உயிர் எழுத்துகள் உள்ளன (அ முதல் ஔ வரை).', 1, 1, TRUE),
('qu_2', 'quiz_uyir', '"அ" எழுத்தில் தொடங்கும் சொல் எது?', '👩‍👧', '"அ" - அம்மா.', 1, 2, TRUE),
('qu_3', 'quiz_uyir', 'இவற்றுள் நெடில் எழுத்து எது?', '🎵', '"ஆ" என்பது நீண்ட ஓசையுடைய நெடில் எழுத்து.', 1, 3, TRUE),
('qu_4', 'quiz_uyir', 'கடைசி உயிர் எழுத்து எது?', '👵', '"ஔ" என்பது 12வது மற்றும் கடைசி உயிர் எழுத்து.', 1, 4, TRUE),
('qm_1', 'quiz_mei', 'தமிழ் மெய் எழுத்துகள் மொத்தம் எத்தனை?', '✨', 'மெய் எழுத்துகள் மொத்தம் 18 உள்ளன (க் முதல் ன் வரை).', 1, 1, TRUE),
('qm_2', 'quiz_mei', 'மெய் எழுத்துகளை எவ்வாறு அடையாளம் காணலாம்?', '📍', 'மெய் எழுத்துகளின் தலையில் புள்ளி வைக்கப்பட்டிருக்கும்.', 1, 2, TRUE),
('qm_3', 'quiz_mei', '"கண்" என்ற சொல்லில் உள்ள மெய் எழுத்து எது?', '👁️', '"ண்" என்பது கண் என்ற சொல்லில் உள்ள மெய் எழுத்து.', 1, 3, TRUE),
('qm_4', 'quiz_mei', 'தமிழ் மொழிக்கே உரிய சிறப்பு மெய் எழுத்து எது?', '🎻', '"ழ்" என்பது தமிழுக்கே உரிய சிறப்பு ழகரம்.', 1, 4, TRUE),
('qa_1', 'quiz_aytham', 'ஆய்த எழுத்து எது?', '🛡️', '"ஃ" என்பது ஆய்த எழுத்து ஆகும்.', 1, 1, TRUE),
('qa_2', 'quiz_aytham', 'ஆய்த எழுத்தில் எத்தனை புள்ளிகள் உள்ளன?', '🎯', 'ஆய்த எழுத்து மூன்று புள்ளிகளைக் கொண்டது (முப்புள்ளி).', 1, 2, TRUE),
('qa_3', 'quiz_aytham', 'ஆய்த எழுத்து இடம்பெறும் சொல் எது?', '⚔️', '"எஃகு" என்ற சொல்லில் நடுவில் "ஃ" இடம்பெற்றுள்ளது.', 1, 3, TRUE),
('qum_1', 'quiz_uyirmei', 'க் + அ = என்ன எழுத்து?', '➕', 'க் + அ = க.', 1, 1, TRUE),
('qum_2', 'quiz_uyirmei', 'மொத்த உயிர்மெய் எழுத்துகள் எத்தனை?', '🌈', '18 மெய் x 12 உயிர் = 216 உயிர்மெய் எழுத்துகள்.', 1, 2, TRUE),
('qum_3', 'quiz_uyirmei', 'க் + ஆ = என்ன எழுத்து?', '🦅', 'க் + ஆ = கா.', 1, 3, TRUE),
('qum_4', 'quiz_uyirmei', 'ம் + அ = என்ன எழுத்து?', '🌳', 'ம் + அ = ம.', 1, 4, TRUE),
('qr_1', 'quiz_reading', '"முயலும் ஆமையும்" கதையில் பந்தயத்தில் வென்றது யார்?', '🏆', 'தொடர்ந்து விடாமுயற்சியுடன் சென்ற ஆமை வெற்றி பெற்றது.', 1, 1, TRUE),
('qr_2', 'quiz_reading', 'முயல் ஏன் பந்தயத்தில் தோற்றது?', '😴', 'அலட்சியமாக மரத்தடியில் தூங்கியதால் முயல் தோற்றது.', 1, 2, TRUE),
('qr_3', 'quiz_reading', 'இக்கதை நமக்குக் கற்றுத்தரும் நீதி என்ன?', '💡', 'பொறுமையும் தொடர் முயற்சியும் எப்போதும் வெற்றி தரும்.', 1, 3, TRUE)
ON CONFLICT (id) DO UPDATE SET question_text = EXCLUDED.question_text, visual_hint = EXCLUDED.visual_hint, explanation = EXCLUDED.explanation;

-- Quiz Options
INSERT INTO quiz_options (question_id, option_text, is_correct, display_order)
VALUES
('qu_1', '10', FALSE, 1),
('qu_1', '12', TRUE, 2),
('qu_1', '18', FALSE, 3),
('qu_1', '216', FALSE, 4),
('qu_2', 'ஆடு', FALSE, 1),
('qu_2', 'இலை', FALSE, 2),
('qu_2', 'அம்மா', TRUE, 3),
('qu_2', 'உரல்', FALSE, 4),
('qu_3', 'அ', FALSE, 1),
('qu_3', 'இ', FALSE, 2),
('qu_3', 'ஆ', TRUE, 3),
('qu_3', 'எ', FALSE, 4),
('qu_4', 'ஒ', FALSE, 1),
('qu_4', 'ஓ', FALSE, 2),
('qu_4', 'ஔ', TRUE, 3),
('qu_4', 'ஐ', FALSE, 4),
('qm_1', '12', FALSE, 1),
('qm_1', '18', TRUE, 2),
('qm_1', '24', FALSE, 3),
('qm_1', '30', FALSE, 4),
('qm_2', 'மேலே புள்ளி இருக்கும்', TRUE, 1),
('qm_2', 'கீழே கோடு இருக்கும்', FALSE, 2),
('qm_2', 'சுழி இருக்கும்', FALSE, 3),
('qm_2', 'வட்டமாக இருக்கும்', FALSE, 4),
('qm_3', 'க', FALSE, 1),
('qm_3', 'ண்', TRUE, 2),
('qm_3', 'ஆ', FALSE, 3),
('qm_3', 'த்', FALSE, 4),
('qm_4', 'ல்', FALSE, 1),
('qm_4', 'ள்', FALSE, 2),
('qm_4', 'ழ்', TRUE, 3),
('qm_4', 'ர்', FALSE, 4),
('qa_1', 'அ', FALSE, 1),
('qa_1', 'க்', FALSE, 2),
('qa_1', 'ஃ', TRUE, 3),
('qa_1', 'க', FALSE, 4),
('qa_2', '1', FALSE, 1),
('qa_2', '2', FALSE, 2),
('qa_2', '3', TRUE, 3),
('qa_2', '4', FALSE, 4),
('qa_3', 'அம்மா', FALSE, 1),
('qa_3', 'எஃகு', TRUE, 2),
('qa_3', 'பட்டம்', FALSE, 3),
('qa_3', 'மீன்', FALSE, 4),
('qum_1', 'கா', FALSE, 1),
('qum_1', 'க', TRUE, 2),
('qum_1', 'கி', FALSE, 3),
('qum_1', 'கு', FALSE, 4),
('qum_2', '12', FALSE, 1),
('qum_2', '18', FALSE, 2),
('qum_2', '100', FALSE, 3),
('qum_2', '216', TRUE, 4),
('qum_3', 'கா', TRUE, 1),
('qum_3', 'கி', FALSE, 2),
('qum_3', 'கீ', FALSE, 3),
('qum_3', 'க', FALSE, 4),
('qum_4', 'மி', FALSE, 1),
('qum_4', 'மா', FALSE, 2),
('qum_4', 'ம', TRUE, 3),
('qum_4', 'மு', FALSE, 4),
('qr_1', 'முயல்', FALSE, 1),
('qr_1', 'ஆமை', TRUE, 2),
('qr_1', 'நரி', FALSE, 3),
('qr_1', 'மான்', FALSE, 4),
('qr_2', 'பயந்துவிட்டது', FALSE, 1),
('qr_2', 'தூங்கிவிட்டது', TRUE, 2),
('qr_2', 'வழி தவறியது', FALSE, 3),
('qr_2', 'கால் வலித்தது', FALSE, 4),
('qr_3', 'வேகமே சிறந்தது', FALSE, 1),
('qr_3', 'விடாமுயற்சி வெற்றி தரும்', TRUE, 2),
('qr_3', 'தூங்குவது நல்லது', FALSE, 3),
('qr_3', 'பந்தயம் கூடாது', FALSE, 4);

-- Educational Games
INSERT INTO games (id, game_type, title, prompt, clue, clue_image, correct_index, options_json, success_praise, stars_reward, is_active, display_order)
VALUES
('game_runner_1', 'runner', 'அகரம் ஓட்டம் (2D Runner)', 'ஓடி விளையாடி தமிழ் எழுத்துகளை சேகரிக்கவும்!', '2D ஓட்டப் பந்தயம் - அ, ஆ, இ, ஈ', 'assets/images/welcome.png', 0, '["அ", "ஆ", "இ", "ஈ"]', 'அருமை! இலக்கை அடைந்துவிட்டீர்கள்! 🏃⭐', 3, TRUE, 1),
('game_candy_1', 'candy', 'தமிழ் எழுத்து மிட்டாய் (Match-3)', 'ஒரே மாதிரி உள்ள தமிழ் எழுத்து மிட்டாய்களை இணைத்து மகிழுங்கள்!', 'Match-3 மிட்டாய் விளையாட்டு', 'assets/images/welcome.png', 0, '["அ", "ஆ", "இ", "ஈ"]', 'மிட்டாய் வெடித்தது! சூப்பர்! 🍬✨', 3, TRUE, 2),
('game_racing_1', 'racing', 'உயிர் எழுத்து கார் பந்தயம் (Car Racing)', 'ஒலியைக் கேட்டு காரை ஓட்டி சரியான உயிர் எழுத்துகளை சேகரியுங்கள்!', 'கார் பந்தயம் - உயிர் எழுத்துகள்', 'assets/images/welcome.png', 0, '["அ", "ஆ", "இ", "ஈ"]', 'வெற்றிப் பாதை! வேகம் சூப்பர்! 🚗🏁', 3, TRUE, 3),
('game_fishing_1', 'fishing', 'எழுத்து மீன்பிடி (Letter Fishing)', 'நீந்தும் வண்ண மீன்களில் சரியான உயிர் எழுத்துகளைப் பிடித்து மகிழுங்கள்!', 'மீன்பிடி விளையாட்டு', 'assets/images/welcome.png', 1, '["அ", "ஆ", "இ", "ஈ"]', 'மீன் சிக்கியது! அருமை! 🎣🐟', 3, TRUE, 4),
('game_basket_1', 'basket', 'எழுத்துக் கூடை (Basket - உயிர் எழுத்துகள்)', 'வானிலிருந்து விழும் சரியான உயிர் எழுத்துகளைக் கூடையில் பிடியுங்கள்!', 'கூடை விளையாட்டு - உயிர் எழுத்துகள்', 'assets/images/welcome.png', 0, '["அ", "ஆ", "இ", "ஈ"]', 'கூடையில் விழுந்தது! அற்புதம்! 🧺🍎', 3, TRUE, 5),
('game_basket_2', 'basket', 'எழுத்துக் கூடை (Basket - மெய் எழுத்துகள்)', 'வானிலிருந்து விழும் புள்ளியிட்ட மெய் எழுத்துகளைக் கூடையில் பிடியுங்கள்!', 'கூடை விளையாட்டு - மெய் எழுத்துகள்', 'assets/images/welcome.png', 0, '["க்", "ங்", "ச்", "ஞ்"]', 'மெய் எழுத்து பிடித்தாச்சு! 🧺⭐', 3, TRUE, 6),
('game_puzzle_1', 'puzzle', 'சொல் புதிர் (Word Puzzle)', 'அம்மா சொல்லின் முதல் எழுத்தைத் தொடுக!', 'அ - ம்மா', 'assets/images/welcome.png', 0, '["அ", "ஆ", "இ", "ஈ"]', 'அற்புதம்! அ என்பது சரி! ⭐', 3, TRUE, 7),
('game_balloon_1', 'balloon', 'பலூன் வெடிப்பு (Balloon Pop)', 'ஆ எழுத்துள்ள பலூனைத் தொடு!', 'ஆடு', 'assets/images/welcome.png', 1, '["அ", "ஆ", "இ", "ஈ"]', 'அருமை! பலூன் வெடித்தது! 🎈', 3, TRUE, 8)
ON CONFLICT DO NOTHING;
