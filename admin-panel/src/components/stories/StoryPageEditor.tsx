import React, { useEffect, useState } from 'react';
import { Plus, Trash2, Save, X } from 'lucide-react';
import { FileUpload } from '../common/FileUpload';
import { InteractiveWordItem, StoryPage } from '../../types';
import { useLanguage } from '../../context/LanguageContext';

interface StoryPageEditorProps {
  /** Page being edited; pass a page without `id` to create a new one. */
  initialPage: Partial<StoryPage>;
  submitLabel: string;
  onSubmit: (page: Partial<StoryPage>) => Promise<void>;
  onCancel?: () => void;
}

const emptyWord = (): InteractiveWordItem => ({
  word: '',
  displayLabel: '',
  emoji: '',
  meaning: '',
  imagePath: '',
});

/**
 * Form for one story page: page image, story lines text, and the tappable (underlined)
 * words, each of which can carry its own image shown in the app's word popup.
 */
export const StoryPageEditor: React.FC<StoryPageEditorProps> = ({
  initialPage,
  submitLabel,
  onSubmit,
  onCancel,
}) => {
  const { t } = useLanguage();
  const [page, setPage] = useState<Partial<StoryPage>>(initialPage);
  const [words, setWords] = useState<InteractiveWordItem[]>(initialPage.interactiveWords || []);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setPage(initialPage);
    setWords(initialPage.interactiveWords || []);
  }, [initialPage]);

  const updateWord = (index: number, patch: Partial<InteractiveWordItem>) => {
    setWords((prev) => prev.map((w, i) => (i === index ? { ...w, ...patch } : w)));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!page.text?.trim()) {
      alert('Page story text is required / கதை வரிகள் தேவை');
      return;
    }
    const cleanedWords = words
      .filter((w) => w.word.trim())
      .map((w) => ({
        word: w.word.trim(),
        displayLabel: (w.displayLabel || w.word).trim(),
        ...(w.emoji ? { emoji: w.emoji } : {}),
        ...(w.meaning ? { meaning: w.meaning } : {}),
        ...(w.imagePath ? { imagePath: w.imagePath } : {}),
        ...(w.audioPath ? { audioPath: w.audioPath } : {}),
      }));

    setSaving(true);
    try {
      await onSubmit({
        ...page,
        imagePath: page.imagePath || null,
        interactiveWords: cleanedWords,
      });
    } finally {
      setSaving(false);
    }
  };

  const keyBase = page.id ?? 'new';

  return (
    <form onSubmit={handleSubmit}>
      <div style={{ display: 'grid', gridTemplateColumns: '100px 1fr 120px', gap: '10px' }}>
        <div className="form-group">
          <label className="form-label">{t('stories.pageNumber')}</label>
          <input
            type="number"
            className="form-control"
            value={page.pageNumber || 1}
            onChange={(e) => setPage({ ...page, pageNumber: parseInt(e.target.value, 10) })}
            required
          />
        </div>
        <div className="form-group">
          <label className="form-label">{t('stories.character')}</label>
          <input
            type="text"
            className="form-control"
            placeholder="எ.கா. முயல் / Rabbit"
            value={page.characterName || ''}
            onChange={(e) => setPage({ ...page, characterName: e.target.value })}
          />
        </div>
        <div className="form-group">
          <label className="form-label">{t('stories.emoji')}</label>
          <input
            type="text"
            className="form-control"
            placeholder="🐇"
            value={page.emojiIllustration ?? ''}
            onChange={(e) => setPage({ ...page, emojiIllustration: e.target.value })}
          />
        </div>
      </div>

      {/* Page Illustration Image Upload */}
      <div className="form-group">
        <FileUpload
          key={`page-img-${keyBase}`}
          type="image"
          label="பக்கப் படம் (Page Image)"
          currentValue={page.imagePath}
          onUploaded={(path) => setPage((prev) => ({ ...prev, imagePath: path }))}
          onClear={() => setPage((prev) => ({ ...prev, imagePath: '' }))}
        />
      </div>

      {/* Story Lines (Text) */}
      <div className="form-group">
        <label className="form-label">{t('stories.pageText')}</label>
        <textarea
          className="form-control"
          rows={3}
          placeholder="இந்தப் பக்கத்திற்கான தமிழ் கதை வரிகளை உள்ளிடுக (Enter the story lines for this page)..."
          value={page.text || ''}
          onChange={(e) => setPage({ ...page, text: e.target.value })}
          required
        />
      </div>

      {/* Tappable Words with Image & Meaning */}
      <div className="form-group">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
          <label className="form-label" style={{ margin: 0 }}>
            தொட்டுப் பார்க்கும் சொற்கள் / Tappable Words ({words.length})
          </label>
          <button
            type="button"
            className="btn btn-secondary btn-sm"
            onClick={() => setWords((prev) => [...prev, emptyWord()])}
          >
            <Plus size={14} />
            <span>+ சொல் சேர்க்க (Add Word)</span>
          </button>
        </div>
        <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '10px' }}>
          இந்தச் சொற்கள் செயலியில் அடிக்கோடிட்டுக் காட்டப்படும். குழந்தை தொடும்போது அதன் படம் மற்றும் பொருள் தோன்றும்.
          இச்சொல் கதை வரியில் இடம்பெற்றிருக்க வேண்டும் (These words are underlined in the app; child can tap to view image & meaning).
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {words.map((w, i) => {
            const inText = !w.word.trim() || (page.text || '').toLowerCase().includes(w.word.trim().toLowerCase());
            return (
              <div
                key={i}
                style={{
                  padding: '12px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-color)',
                  background: 'var(--bg-card, #fff)',
                }}
              >
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 80px auto', gap: '8px', alignItems: 'end' }}>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">கதையில் உள்ள சொல் (Word in text)</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="எ.கா. முயல்"
                      value={w.word}
                      onChange={(e) => updateWord(i, { word: e.target.value })}
                    />
                  </div>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">காட்டும் பெயர் (Display label)</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="எ.கா. முயல்"
                      value={w.displayLabel || ''}
                      onChange={(e) => updateWord(i, { displayLabel: e.target.value })}
                    />
                  </div>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">சின்னம் (Emoji)</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="🐰"
                      value={w.emoji || ''}
                      onChange={(e) => updateWord(i, { emoji: e.target.value })}
                    />
                  </div>
                  <button
                    type="button"
                    className="btn btn-danger btn-sm"
                    style={{ padding: '8px' }}
                    title={t('common.delete')}
                    onClick={() => setWords((prev) => prev.filter((_, idx) => idx !== i))}
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
                {!inText && (
                  <div style={{ fontSize: '12px', color: 'var(--danger, #dc2626)', marginTop: '4px' }}>
                    "{w.word}" கதை வரியில் இல்லை. அதனால் அடிக்கோடு வராது ("{w.word}" is not in the page text, so it won't be underlined).
                  </div>
                )}
                <div className="form-group" style={{ marginTop: '8px', marginBottom: '8px' }}>
                  <label className="form-label">பொருள் (Meaning)</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="எ.கா. வேகமாக ஓடும் முயல் (Rabbit)"
                    value={w.meaning || ''}
                    onChange={(e) => updateWord(i, { meaning: e.target.value })}
                  />
                </div>
                <FileUpload
                  key={`word-img-${keyBase}-${i}`}
                  type="image"
                  label="சொல் படம் (Word Image)"
                  currentValue={w.imagePath}
                  onUploaded={(path) => updateWord(i, { imagePath: path })}
                  onClear={() => updateWord(i, { imagePath: '' })}
                />
              </div>
            );
          })}
        </div>
      </div>

      <div style={{ display: 'flex', gap: '8px' }}>
        <button type="submit" className="btn btn-primary btn-sm" disabled={saving}>
          {page.id ? <Save size={14} /> : <Plus size={14} />}
          <span>{saving ? t('common.saving') : submitLabel}</span>
        </button>
        {onCancel && (
          <button type="button" className="btn btn-secondary btn-sm" onClick={onCancel}>
            <X size={14} />
            <span>{t('common.cancel')}</span>
          </button>
        )}
      </div>
    </form>
  );
};
