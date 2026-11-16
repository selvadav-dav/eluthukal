import React, { useEffect, useState } from 'react';
import { storiesApi } from '../api/stories';
import { ReadingStory, StoryPage } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Plus, Edit2, Trash2, Layers, CheckCircle2, XCircle, Loader2 } from 'lucide-react';
import { resolveMediaUrl } from '../api/client';
import { StoryPageEditor } from '../components/stories/StoryPageEditor';

const blankPage = (pageNumber: number): Partial<StoryPage> => ({
  pageNumber,
  text: '',
  emojiIllustration: '🐰',
  characterName: '',
  imagePath: '',
  interactiveWords: [],
});

export const StoriesPage: React.FC = () => {
  const { t } = useLanguage();
  const [stories, setStories] = useState<ReadingStory[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentStory, setCurrentStory] = useState<Partial<ReadingStory> | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Pages Manager Modal
  const [selectedStoryForPages, setSelectedStoryForPages] = useState<ReadingStory | null>(null);
  const [isPageModalOpen, setIsPageModalOpen] = useState(false);
  const [newPage, setNewPage] = useState<Partial<StoryPage>>(blankPage(1));
  const [editingPage, setEditingPage] = useState<StoryPage | null>(null);

  useEffect(() => {
    fetchStories();
  }, []);

  const fetchStories = async () => {
    setLoading(true);
    try {
      const res = await storiesApi.getAll(true);
      if (res.success && res.data) {
        setStories(res.data);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = () => {
    setCurrentStory({
      title: '',
      subtitle: '',
      cover_emoji: '📖',
      cover_image: '',
      content: '',
      moral: '',
      display_order: stories.length + 1,
      is_published: true,
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (story: ReadingStory) => {
    setCurrentStory({
      ...story,
      content: story.content || '',
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await storiesApi.delete(id);
      fetchStories();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Delete failed');
    }
  };

  const handleSaveStory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentStory?.title) {
      alert('Title is required');
      return;
    }

    setIsSubmitting(true);
    try {
      if (currentStory.id) {
        await storiesApi.update(currentStory.id, currentStory);
      } else {
        await storiesApi.create(currentStory);
      }
      setIsModalOpen(false);
      fetchStories();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Save failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Manage Pages
  const handleOpenPages = async (story: ReadingStory) => {
    try {
      const res = await storiesApi.getById(story.id);
      if (res.success && res.data) {
        setSelectedStoryForPages(res.data);
        setNewPage(blankPage((res.data.pages?.length || 0) + 1));
        setEditingPage(null);
        setIsPageModalOpen(true);
      }
    } catch (err: any) {
      alert(err.message || 'Failed to load story pages');
    }
  };

  const reloadPages = async (storyId: string) => {
    const res = await storiesApi.getById(storyId);
    if (res.success && res.data) {
      setSelectedStoryForPages(res.data);
      setNewPage(blankPage((res.data.pages?.length || 0) + 1));
    }
    fetchStories();
  };

  const handleAddPage = async (page: Partial<StoryPage>) => {
    if (!selectedStoryForPages) return;
    try {
      await storiesApi.addPage(selectedStoryForPages.id, page);
      await reloadPages(selectedStoryForPages.id);
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to add page');
    }
  };

  const handleUpdatePage = async (page: Partial<StoryPage>) => {
    if (!selectedStoryForPages || !page.id) return;
    try {
      await storiesApi.updatePage(selectedStoryForPages.id, page.id, {
        pageNumber: page.pageNumber,
        text: page.text,
        characterName: page.characterName,
        emojiIllustration: page.emojiIllustration,
        imagePath: page.imagePath,
        interactiveWords: page.interactiveWords,
      });
      setEditingPage(null);
      await reloadPages(selectedStoryForPages.id);
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to update page');
    }
  };

  const handleDeletePage = async (pageId?: number) => {
    if (!pageId || !selectedStoryForPages) return;
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await storiesApi.deletePage(selectedStoryForPages.id, pageId);
      await reloadPages(selectedStoryForPages.id);
    } catch (err: any) {
      alert(err.message || 'Failed to delete page');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('stories.pageTitle')}</h2>
          <p>{t('stories.pageSubtitle')}</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={16} />
          <span>{t('stories.addStory')}</span>
        </button>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>{t('stories.order')}</th>
              <th>{t('stories.coverEmoji')}</th>
              <th>{t('stories.title')}</th>
              <th>{t('stories.subtitle')}</th>
              <th>{t('stories.pages')}</th>
              <th>{t('stories.moral')}</th>
              <th>{t('stories.status')}</th>
              <th style={{ textAlign: 'right' }}>{t('stories.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : stories.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              stories.map((story) => (
                <tr key={story.id}>
                  <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>{story.display_order}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontSize: '24px' }}>{story.cover_emoji}</span>
                      {story.cover_image && (
                        <img
                          src={resolveMediaUrl(story.cover_image)}
                          alt=""
                          style={{ width: '36px', height: '36px', borderRadius: '4px', objectFit: 'cover' }}
                        />
                      )}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700 }}>{story.title}</div>
                    {story.content && (
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)', maxWidth: '250px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {story.content}
                      </div>
                    )}
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '14px' }}>{story.subtitle}</td>
                  <td>
                    <button
                      onClick={() => handleOpenPages(story)}
                      className="btn btn-secondary btn-sm"
                      style={{ gap: '6px' }}
                    >
                      <Layers size={14} />
                      <span>{story.page_count || 0} {t('stories.pages')} ({t('stories.managePages')})</span>
                    </button>
                  </td>
                  <td>
                    <span style={{ fontSize: '13px', fontStyle: 'italic', color: 'var(--primary)' }}>
                      "{story.moral}"
                    </span>
                  </td>
                  <td>
                    {story.is_published ? (
                      <span className="badge badge-success">
                        <span className="badge-dot" />
                        {t('stories.published')}
                      </span>
                    ) : (
                      <span className="badge badge-danger">
                        <span className="badge-dot" />
                        {t('stories.draft')}
                      </span>
                    )}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div className="action-btn-group">
                      <button onClick={() => handleOpenEdit(story)} className="btn btn-secondary btn-icon" title={t('common.edit')}>
                        <Edit2 size={14} />
                      </button>
                      <button onClick={() => handleDelete(story.id)} className="btn btn-danger btn-icon" title={t('common.delete')}>
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Story Add / Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentStory?.id ? t('stories.editStory') : t('stories.addStory')}
        maxWidth="700px"
      >
        <form onSubmit={handleSaveStory}>
          <div className="form-group">
            <label className="form-label">{t('stories.title')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. முயலும் ஆமையும்"
              value={currentStory?.title || ''}
              onChange={(e) => setCurrentStory({ ...currentStory, title: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('stories.subtitle')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. விடாமுயற்சி வெற்றி தரும்"
              value={currentStory?.subtitle || ''}
              onChange={(e) => setCurrentStory({ ...currentStory, subtitle: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('stories.coverEmoji')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="🐢"
                value={currentStory?.cover_emoji || '📖'}
                onChange={(e) => setCurrentStory({ ...currentStory, cover_emoji: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('stories.order')}</label>
              <input
                type="number"
                className="form-control"
                value={currentStory?.display_order || 1}
                onChange={(e) => setCurrentStory({ ...currentStory, display_order: parseInt(e.target.value, 10) })}
              />
            </div>
          </div>

          {/* Cover Image Upload */}
          <div className="form-group">
            <FileUpload
              type="image"
              label={t('stories.coverImage')}
              currentValue={currentStory?.cover_image}
              onUploaded={(path) => setCurrentStory({ ...currentStory, cover_image: path })}
            />
          </div>

          {/* Story Content (Multi-paragraph) */}
          <div className="form-group">
            <label className="form-label">{t('stories.content')}</label>
            <textarea
              className="form-control"
              rows={6}
              placeholder={t('stories.contentPlaceholder')}
              value={currentStory?.content || ''}
              onChange={(e) => setCurrentStory({ ...currentStory, content: e.target.value })}
              style={{ lineHeight: 1.6, fontSize: '15px' }}
            />
            <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
              முழுக் கதையையும் பத்திகளாக இங்கே தட்டச்சு செய்யவும் (Enter the full story text in multiple paragraphs).
            </span>
          </div>

          <div className="form-group">
            <label className="form-label">{t('stories.moral')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. விடாமுயற்சியே வெற்றி தரும்!"
              value={currentStory?.moral || ''}
              onChange={(e) => setCurrentStory({ ...currentStory, moral: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('stories.status')}</label>
            <select
              className="form-control"
              value={currentStory?.is_published ? '1' : '0'}
              onChange={(e) => setCurrentStory({ ...currentStory, is_published: e.target.value === '1' })}
            >
              <option value="1">{t('stories.published')}</option>
              <option value="0">{t('stories.draft')}</option>
            </select>
          </div>

          <div className="modal-footer" style={{ margin: '20px -24px -24px', padding: '16px 24px' }}>
            <button type="button" onClick={() => setIsModalOpen(false)} className="btn btn-secondary">
              {t('common.cancel')}
            </button>
            <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
              {isSubmitting ? t('common.saving') : t('common.save')}
            </button>
          </div>
        </form>
      </Modal>

      {/* Pages Manager Modal */}
      <Modal
        isOpen={isPageModalOpen}
        onClose={() => setIsPageModalOpen(false)}
        title={`${t('stories.pages')}: ${selectedStoryForPages?.title || ''}`}
        maxWidth="750px"
      >
        <div>
          {/* Current Pages List */}
          <h4 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '12px' }}>
            {t('stories.pages')} ({selectedStoryForPages?.pages?.length || 0})
          </h4>

          {selectedStoryForPages?.pages && selectedStoryForPages.pages.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginBottom: '24px' }}>
              {selectedStoryForPages.pages.map((p) =>
                editingPage?.id === p.id ? (
                  <div
                    key={p.id}
                    style={{ padding: '14px', borderRadius: 'var(--radius-md)', border: '2px solid var(--primary)', background: 'var(--bg-card, #fff)' }}
                  >
                    <h5 style={{ fontSize: '14px', fontWeight: 700, marginBottom: '10px' }}>
                      {t('common.edit')} #{p.pageNumber}
                    </h5>
                    <StoryPageEditor
                      initialPage={editingPage}
                      submitLabel={t('common.save')}
                      onSubmit={handleUpdatePage}
                      onCancel={() => setEditingPage(null)}
                    />
                  </div>
                ) : (
                <div
                  key={p.id}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '12px',
                    borderRadius: 'var(--radius-md)',
                    background: 'var(--bg-muted)',
                    border: '1px solid var(--border-color)',
                  }}
                >
                  <span style={{ fontWeight: 800, color: 'var(--primary)', minWidth: '24px' }}>#{p.pageNumber}</span>
                  {p.imagePath ? (
                    <img
                      src={resolveMediaUrl(p.imagePath)}
                      alt=""
                      style={{ width: '64px', height: '48px', borderRadius: '6px', objectFit: 'cover', flexShrink: 0 }}
                    />
                  ) : (
                    <span style={{ fontSize: '20px' }}>{p.emojiIllustration}</span>
                  )}
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 600, fontSize: '14px' }}>{p.characterName || 'பாத்திரம்'}</div>
                    <div style={{ fontSize: '14px', color: 'var(--text-main)', marginTop: '2px', lineHeight: 1.6 }}>{p.text}</div>
                    {p.interactiveWords && p.interactiveWords.length > 0 && (
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginTop: '6px' }}>
                        {p.interactiveWords.map((w, i) => (
                          <span
                            key={i}
                            className="badge"
                            title={w.imagePath ? 'Has image' : 'No image yet'}
                            style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                          >
                            {w.imagePath ? (
                              <img
                                src={resolveMediaUrl(w.imagePath)}
                                alt=""
                                style={{ width: '18px', height: '18px', borderRadius: '3px', objectFit: 'cover' }}
                              />
                            ) : (
                              <span>{w.emoji || '•'}</span>
                            )}
                            {w.word}
                            {!w.imagePath && (
                              <span style={{ color: 'var(--text-muted)', fontSize: '11px' }}>(no image)</span>
                            )}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                  <div className="action-btn-group">
                    <button
                      onClick={() => setEditingPage(p)}
                      className="btn btn-secondary btn-sm"
                      style={{ padding: '4px 8px' }}
                      title={t('common.edit')}
                    >
                      <Edit2 size={12} />
                    </button>
                    <button
                      onClick={() => handleDeletePage(p.id)}
                      className="btn btn-danger btn-sm"
                      style={{ padding: '4px 8px' }}
                      title={t('common.delete')}
                    >
                      <Trash2 size={12} />
                    </button>
                  </div>
                </div>
                )
              )}
            </div>
          ) : (
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '20px' }}>
              {t('common.noData')}
            </p>
          )}

          {/* Add Page Form */}
          <div style={{ borderTop: '2px dashed var(--border-color)', paddingTop: '16px' }}>
            <h4 style={{ fontSize: '15px', fontWeight: 700, marginBottom: '12px' }}>+ {t('stories.addPage')}</h4>
            <StoryPageEditor
              initialPage={newPage}
              submitLabel={t('stories.addPage')}
              onSubmit={handleAddPage}
            />
          </div>
        </div>
      </Modal>
    </div>
  );
};
