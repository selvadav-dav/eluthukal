/**
 * TypeScript Interfaces for AGARAM Admin Panel
 */

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data: T;
  error?: string;
}

export interface AdminUser {
  id: number | string;
  username: string;
  email: string;
  fullName?: string;
  full_name?: string;
  role: 'super_admin' | 'content_admin';
  is_active?: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface DashboardStats {
  summary: {
    totalUsers: number;
    totalLessons: number;
    totalLetters: number;
    totalStories: number;
    totalVideos: number;
    totalQuizzes: number;
    totalQuizAttempts: number;
    totalStarsAwarded: number;
  };
  recentQuizAttempts: {
    id: number;
    score: number;
    total_questions: number;
    stars_earned: number;
    attempt_date: string;
    child_name: string;
    quiz_title: string;
  }[];
}

export interface Lesson {
  id: string;
  category_key: string;
  title: string;
  subtitle: string;
  count_text: string;
  button_text: string;
  icon_emoji: string;
  gradientColors: string[];
  route_name: string;
  display_order: number;
  is_active: boolean | number;
  created_at?: string;
  updated_at?: string;
}

export interface LetterGroup {
  id: string;
  name: string;
  display_title: string;
  letter_type: 'uyir' | 'mei' | 'aytham' | 'uyirmei';
  description?: string;
  display_order: number;
}

export interface Letter {
  id: string;
  letter: string;
  type: 'uyir' | 'mei' | 'aytham' | 'uyirmei';
  group_id: string | null;
  group_title?: string;
  word: string;
  meaning: string;
  phonetic: string;
  icon_emoji: string;
  image_path?: string | null;
  audio_path?: string | null;
  video_url?: string | null;
  explanation?: string | null;
  mei_base?: string | null;
  uyir_base?: string | null;
  display_order: number;
  is_active: boolean | number;
  created_at?: string;
  updated_at?: string;
}

export interface InteractiveWordItem {
  word: string;
  displayLabel?: string;
  imagePath?: string;
  emoji?: string;
  meaning?: string;
  audioPath?: string;
}

export interface StoryPage {
  id?: number;
  storyId?: string;
  pageNumber: number;
  text: string;
  emojiIllustration: string;
  characterName: string;
  narratorAudio?: string | null;
  imagePath?: string | null;
  interactiveWords?: InteractiveWordItem[];
}

export interface ReadingStory {
  id: string;
  title: string;
  subtitle: string;
  cover_emoji: string;
  cover_image?: string | null;
  content?: string | null;
  moral: string;
  display_order: number;
  is_published: boolean | number;
  page_count?: number;
  pages?: StoryPage[];
  created_at?: string;
  updated_at?: string;
}

export interface VideoItem {
  id: string;
  title: string;
  description: string;
  category: string;
  duration: string;
  thumbnail_emoji: string;
  thumbnail_image?: string | null;
  video_url: string;
  stream_url?: string;
  local_video_path?: string | null;
  display_order: number;
  is_published: boolean | number;
  created_at?: string;
  updated_at?: string;
}

export interface QuizOption {
  id?: number;
  questionId?: string;
  optionText: string;
  isCorrect: boolean;
  displayOrder?: number;
}

export interface QuizQuestion {
  id: string;
  quizId?: string;
  question: string;
  visualHint?: string;
  visualImage?: string | null;
  explanation?: string;
  marks: number;
  displayOrder: number;
  options: QuizOption[];
}

export interface Quiz {
  id: string;
  title: string;
  subtitle: string;
  icon_emoji: string;
  category: string;
  question_count: number;
  actual_question_count?: number;
  pass_marks: number;
  stars_reward: number;
  is_active: boolean | number;
  display_order: number;
  questions?: QuizQuestion[];
  created_at?: string;
  updated_at?: string;
}

export interface GameItem {
  id: string;
  game_type: string;
  title: string;
  prompt: string;
  clue?: string;
  clue_image?: string | null;
  correct_index: number;
  options: string[];
  success_praise: string;
  stars_reward: number;
  display_order: number;
  is_active: boolean | number;
  created_at?: string;
  updated_at?: string;
}

export interface ChildUser {
  id: string;
  child_name: string;
  email?: string | null;
  age: number;
  avatar_asset: string;
  total_stars: number;
  is_active: boolean | number;
  total_quizzes_taken?: number;
  total_completed_items?: number;
  current_streak?: number;
  highest_streak?: number;
  created_at: string;
  updated_at: string;
}

export interface QuizResultRecord {
  id: number;
  user_id: string;
  child_name?: string;
  quiz_id: string;
  quiz_title?: string;
  score: number;
  total_questions: number;
  correct_answers: number;
  stars_earned: number;
  attempt_date: string;
}
