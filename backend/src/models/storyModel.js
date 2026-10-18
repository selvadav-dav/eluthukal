/**
 * Reading Stories Data Access Model
 */
const { pool } = require('../config/db');

class StoryModel {
  static async getAll({ onlyPublished = true } = {}) {
    const condition = onlyPublished ? 'WHERE is_published = TRUE' : '';
    const [rows] = await pool.query(
      `SELECT s.*, COUNT(p.id) as page_count 
       FROM reading_stories s
       LEFT JOIN reading_story_pages p ON s.id = p.story_id
       ${condition}
       GROUP BY s.id
       ORDER BY s.display_order ASC`
    );
    return rows;
  }

  static async getById(id) {
    const [stories] = await pool.query(
      'SELECT * FROM reading_stories WHERE id = ? LIMIT 1',
      [id]
    );
    if (!stories[0]) return null;

    const [pages] = await pool.query(
      'SELECT * FROM reading_story_pages WHERE story_id = ? ORDER BY page_number ASC',
      [id]
    );

    return {
      ...stories[0],
      pages: pages.map((p) => {
        let interactiveWords = [];
        if (p.interactive_words) {
          if (typeof p.interactive_words === 'string') {
            try {
              interactiveWords = JSON.parse(p.interactive_words);
            } catch (_) {
              interactiveWords = [];
            }
          } else if (Array.isArray(p.interactive_words)) {
            interactiveWords = p.interactive_words;
          }
        }

        return {
          id: p.id,
          pageNumber: p.page_number,
          text: p.text ? p.text.replace(/\\n/g, '\n') : '',
          emojiIllustration: p.emoji_illustration,
          characterName: p.character_name,
          narratorAudio: p.narrator_audio,
          imagePath: p.image_path,
          interactiveWords,
        };
      }),
    };
  }

  static async create({
    id,
    title,
    subtitle = '',
    coverEmoji = '📖',
    coverImage = null,
    content = '',
    moral = '',
    displayOrder = 0,
    isPublished = true,
  }) {
    const storyId = id || `story_${Date.now()}`;
    await pool.query(
      `INSERT INTO reading_stories (id, title, subtitle, cover_emoji, cover_image, content, moral, display_order, is_published)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [storyId, title, subtitle, coverEmoji, coverImage, content, moral, displayOrder, isPublished]
    );
    return this.getById(storyId);
  }

  static async update(id, data) {
    const fields = [];
    const values = [];

    const fieldMap = {
      title: 'title',
      subtitle: 'subtitle',
      coverEmoji: 'cover_emoji',
      coverImage: 'cover_image',
      content: 'content',
      moral: 'moral',
      displayOrder: 'display_order',
      isPublished: 'is_published',
    };

    for (const [key, dbCol] of Object.entries(fieldMap)) {
      if (data[key] !== undefined) {
        fields.push(`${dbCol} = ?`);
        values.push(data[key]);
      }
    }

    if (fields.length === 0) return this.getById(id);

    values.push(id);
    await pool.query(`UPDATE reading_stories SET ${fields.join(', ')} WHERE id = ?`, values);
    return this.getById(id);
  }

  static async delete(id) {
    const [result] = await pool.query('DELETE FROM reading_stories WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  // --- Story Pages CRUD ---
  static async addPage(storyId, { pageNumber, text, emojiIllustration = '🐰', characterName = '', narratorAudio = null, imagePath = null, interactiveWords = [] }) {
    const wordsJson = typeof interactiveWords === 'string' ? interactiveWords : JSON.stringify(interactiveWords || []);
    const [result] = await pool.query(
      `INSERT INTO reading_story_pages (story_id, page_number, text, emoji_illustration, character_name, narrator_audio, image_path, interactive_words)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [storyId, pageNumber, text, emojiIllustration, characterName, narratorAudio, imagePath, wordsJson]
    );
    return result.insertId;
  }

  static async updatePage(pageId, { text, emojiIllustration, characterName, narratorAudio, imagePath, pageNumber, interactiveWords }) {
    const fields = [];
    const values = [];

    if (text !== undefined) { fields.push('text = ?'); values.push(text); }
    if (emojiIllustration !== undefined) { fields.push('emoji_illustration = ?'); values.push(emojiIllustration); }
    if (characterName !== undefined) { fields.push('character_name = ?'); values.push(characterName); }
    if (narratorAudio !== undefined) { fields.push('narrator_audio = ?'); values.push(narratorAudio); }
    if (imagePath !== undefined) { fields.push('image_path = ?'); values.push(imagePath); }
    if (pageNumber !== undefined) { fields.push('page_number = ?'); values.push(pageNumber); }
    if (interactiveWords !== undefined) {
      const wordsJson = typeof interactiveWords === 'string' ? interactiveWords : JSON.stringify(interactiveWords || []);
      fields.push('interactive_words = ?');
      values.push(wordsJson);
    }

    if (fields.length === 0) return true;

    values.push(pageId);
    await pool.query(`UPDATE reading_story_pages SET ${fields.join(', ')} WHERE id = ?`, values);
    return true;
  }

  static async deletePage(pageId) {
    const [result] = await pool.query('DELETE FROM reading_story_pages WHERE id = ?', [pageId]);
    return result.affectedRows > 0;
  }
}

module.exports = StoryModel;
