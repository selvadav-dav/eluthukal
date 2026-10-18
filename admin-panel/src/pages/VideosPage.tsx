import React, { useEffect, useState } from 'react';
import { videosApi } from '../api/videos';
import { VideoItem } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Plus, Edit2, Trash2, Play, Eye, Loader2, Sparkles, Video as VideoIcon } from 'lucide-react';

import { resolveMediaUrl } from '../api/client';


const UYIR_LETTERS = ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஊ', 'எ', 'ஏ', 'ஐ', 'ஒ', 'ஓ', 'ஔ'];
const MEI_LETTERS = ['க்', 'ங்', 'ச்', 'ஞ்', 'ட்', 'ண்', 'த்', 'ந்', 'ப்', 'ம்', 'ய்', 'ர்', 'ல்', 'வ்', 'ழ்', 'ள்', 'ற்', 'ன்'];

export const VideosPage: React.FC = () => {
  const { t } = useLanguage();
  const [videos, setVideos] = useState<VideoItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentVideo, setCurrentVideo] = useState<Partial<VideoItem> | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [previewingVideo, setPreviewingVideo] = useState<VideoItem | null>(null);

  useEffect(() => {
    fetchVideos();
  }, []);

  const fetchVideos = async () => {
    setLoading(true);
    try {
      const res = await videosApi.getAll({ all: true });
      if (res.success && res.data) {
        setVideos(res.data);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = (defaultCat: string = 'உயிர் எழுத்துகள்') => {
    setCurrentVideo({
      title: '',
      description: '',
      category: defaultCat,
      duration: '00:10',
      thumbnail_emoji: '🎬',
      video_url: '',
      display_order: videos.length + 1,
      is_published: true,
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (video: VideoItem) => {
    setCurrentVideo(video);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await videosApi.delete(id);
      fetchVideos();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Delete failed');
    }
  };

  const handleQuickLetterPick = (letter: string, index: number) => {
    if (!currentVideo) return;
    setCurrentVideo({
      ...currentVideo,
      title: letter,
      thumbnail_emoji: `🎬${letter}`,
      display_order: index + 1,
    });
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentVideo?.title) {
      alert('காணொளி தலைப்பு அவசியம் (Title is required)');
      return;
    }
    if (!currentVideo?.video_url) {
      alert('தயவுசெய்து காணொளிக் கோப்பைத் தேர்ந்தெடுத்து பதிவேற்றவும் (Please upload a video file)');
      return;
    }

    setIsSubmitting(true);
    try {
      if (currentVideo.id) {
        await videosApi.update(currentVideo.id, currentVideo);
      } else {
        await videosApi.create(currentVideo);
      }
      setIsModalOpen(false);
      fetchVideos();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Save failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  const uyirCount = videos.filter((v) => v.category === 'உயிர் எழுத்துகள்' || UYIR_LETTERS.includes(v.title)).length;
  const meiCount = videos.filter((v) => v.category === 'மெய் எழுத்துகள்' || MEI_LETTERS.includes(v.title)).length;
  const aythamCount = videos.filter((v) => v.category === 'ஆய்த எழுத்து' || v.title === 'ஃ').length;
  const songsCount = videos.filter((v) => v.category === 'பாடல்').length;
  const storiesCount = videos.filter((v) => v.category === 'கதை').length;
  const lessonsCount = videos.filter((v) => v.category === 'பாடம்').length;

  const filteredVideos = videos.filter((vid) => {
    if (selectedFilter === 'all') return true;
    if (selectedFilter === 'uyir') return vid.category === 'உயிர் எழுத்துகள்' || UYIR_LETTERS.includes(vid.title);
    if (selectedFilter === 'mei') return vid.category === 'மெய் எழுத்துகள்' || MEI_LETTERS.includes(vid.title);
    if (selectedFilter === 'aytham') return vid.category === 'ஆய்த எழுத்து' || vid.title === 'ஃ';
    if (selectedFilter === 'song') return vid.category === 'பாடல்';
    if (selectedFilter === 'story') return vid.category === 'கதை';
    if (selectedFilter === 'lesson') return vid.category === 'பாடம்';
    return true;
  });

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('videos.pageTitle')}</h2>
          <p>தமிழ் உயிர் எழுத்துகள் (12), மெய் எழுத்துகள் (18), ஆய்த எழுத்து (1) மற்றும் கல்வி காணொளிகள் மேலாண்மை</p>
        </div>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <button
            onClick={() => handleOpenAdd('ஆய்த எழுத்து')}
            className="btn btn-secondary"
            style={{ display: 'flex', alignItems: 'center', gap: '6px', borderColor: '#8B5CF6', color: '#6D28D9', background: '#F5F3FF' }}
          >
            <Plus size={16} />
            <span>+ ஆய்த எழுத்து காணொளி</span>
          </button>
          <button
            onClick={() => handleOpenAdd('மெய் எழுத்துகள்')}
            className="btn btn-secondary"
            style={{ display: 'flex', alignItems: 'center', gap: '6px', borderColor: '#3B82F6', color: '#1D4ED8', background: '#EFF6FF' }}
          >
            <Plus size={16} />
            <span>+ மெய் எழுத்து காணொளி</span>
          </button>
          <button
            onClick={() => handleOpenAdd('உயிர் எழுத்துகள்')}
            className="btn btn-primary"
            style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <Plus size={16} />
            <span>{t('videos.addVideo')}</span>
          </button>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="tabs-header" style={{ marginBottom: '16px', display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
        <button
          className={`tab-btn ${selectedFilter === 'all' ? 'active' : ''}`}
          onClick={() => setSelectedFilter('all')}
        >
          அனைத்தும் ({videos.length})
        </button>
        <button
          className={`tab-btn ${selectedFilter === 'uyir' ? 'active' : ''}`}
          onClick={() => setSelectedFilter('uyir')}
          style={selectedFilter === 'uyir' ? { background: '#FDF2F8', borderColor: '#EC4899', color: '#BE185D' } : {}}
        >
          🅰️ உயிர் எழுத்துகள் ({uyirCount}/12)
        </button>
        <button
          className={`tab-btn ${selectedFilter === 'mei' ? 'active' : ''}`}
          onClick={() => setSelectedFilter('mei')}
          style={selectedFilter === 'mei' ? { background: '#EFF6FF', borderColor: '#3B82F6', color: '#1D4ED8' } : {}}
        >
          ✍️ மெய் எழுத்துகள் ({meiCount}/18)
        </button>
        <button
          className={`tab-btn ${selectedFilter === 'aytham' ? 'active' : ''}`}
          onClick={() => setSelectedFilter('aytham')}
          style={selectedFilter === 'aytham' ? { background: '#FAF5FF', borderColor: '#A855F7', color: '#7E22CE' } : {}}
        >
          ⭐ ஆய்த எழுத்து ({aythamCount}/1)
        </button>
        {songsCount > 0 && (
          <button
            className={`tab-btn ${selectedFilter === 'song' ? 'active' : ''}`}
            onClick={() => setSelectedFilter('song')}
          >
            🎵 பாடல்கள் ({songsCount})
          </button>
        )}
        {storiesCount > 0 && (
          <button
            className={`tab-btn ${selectedFilter === 'story' ? 'active' : ''}`}
            onClick={() => setSelectedFilter('story')}
          >
            📖 கதைகள் ({storiesCount})
          </button>
        )}
        {lessonsCount > 0 && (
          <button
            className={`tab-btn ${selectedFilter === 'lesson' ? 'active' : ''}`}
            onClick={() => setSelectedFilter('lesson')}
          >
            🎓 பாடங்கள் ({lessonsCount})
          </button>
        )}
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>{t('videos.order')}</th>
              <th>{t('videos.thumbnail')}</th>
              <th>{t('videos.title')}</th>
              <th>{t('videos.category')}</th>
              <th>{t('videos.duration')}</th>
              <th>காணொளி (Video)</th>
              <th>{t('videos.status')}</th>
              <th style={{ textAlign: 'right' }}>{t('videos.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : filteredVideos.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '40px 16px', color: 'var(--text-muted)' }}>
                  <div style={{ fontSize: '32px', marginBottom: '8px' }}>🎬</div>
                  <div style={{ fontWeight: 600, fontSize: '15px' }}>காணொளிகள் எதுவும் இல்லை</div>
                  {selectedFilter === 'mei' && (
                    <div style={{ marginTop: '8px' }}>
                      <button
                        onClick={() => handleOpenAdd('மெய் எழுத்துகள்')}
                        className="btn btn-primary btn-sm"
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                      >
                        <Plus size={14} />
                        <span>மெய் எழுத்து காணொளியை சேர்க்கவும்</span>
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ) : (
              filteredVideos.map((vid) => {
                const isUyir = vid.category === 'உயிர் எழுத்துகள்';
                const isMei = vid.category === 'மெய் எழுத்துகள்';
                const isSong = vid.category === 'பாடல்';
                const isStory = vid.category === 'கதை';

                const badgeBg = isUyir
                  ? '#FDF2F8'
                  : isMei
                  ? '#EFF6FF'
                  : isSong
                  ? '#EDE9FE'
                  : isStory
                  ? '#FEF3C7'
                  : '#E0F2FE';

                const badgeColor = isUyir
                  ? '#DB2777'
                  : isMei
                  ? '#2563EB'
                  : isSong
                  ? '#6D28D9'
                  : isStory
                  ? '#B45309'
                  : '#0369A1';

                return (
                  <tr key={vid.id}>
                    <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>{vid.display_order}</td>
                    <td>
                      <div
                        style={{
                          width: '38px',
                          height: '38px',
                          borderRadius: '10px',
                          background: isUyir ? '#FFE4E6' : isMei ? '#DBEAFE' : '#F1F5F9',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: (isUyir || isMei) ? '18px' : '20px',
                          fontWeight: 'bold',
                          color: isUyir ? '#E11D48' : isMei ? '#2563EB' : 'inherit',
                        }}
                      >
                        {vid.thumbnail_emoji || (isUyir || isMei ? vid.title : '🎬')}
                      </div>
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, color: 'var(--text-dark, #1E293B)', fontSize: '15px' }}>
                        {vid.title}
                      </div>
                      {vid.description && (
                        <div style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{vid.description}</div>
                      )}
                    </td>
                    <td>
                      <span
                        className="badge"
                        style={{
                          background: badgeBg,
                          color: badgeColor,
                          fontWeight: 700,
                          border: `1px solid ${badgeColor}33`,
                        }}
                      >
                        {vid.category}
                      </span>
                    </td>
                    <td style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-muted)' }}>
                      {vid.duration || '00:10'}
                    </td>
                    <td>
                      {vid.video_url ? (
                        <button
                          type="button"
                          onClick={() => setPreviewingVideo(vid)}
                          className="btn btn-secondary btn-sm"
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '6px',
                            fontSize: '12px',
                            fontWeight: 700,
                            padding: '4px 10px',
                            background: '#FAF5FF',
                            borderColor: '#E9D5FF',
                            color: '#7E22CE',
                          }}
                          title="காணொளி முன்னோட்டம் (Play Preview)"
                        >
                          <Play size={12} fill="#7E22CE" />
                          <span>▶ Preview</span>
                        </button>
                      ) : (
                        <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>இல்லை</span>
                      )}
                    </td>
                    <td>
                      {vid.is_published ? (
                        <span className="badge badge-success">
                          <span className="badge-dot" />
                          {t('common.active')}
                        </span>
                      ) : (
                        <span className="badge badge-danger">
                          <span className="badge-dot" />
                          {t('common.inactive')}
                        </span>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div className="action-btn-group">
                        <button
                          onClick={() => setPreviewingVideo(vid)}
                          className="btn btn-secondary btn-icon"
                          title="முன்னோட்டம் (Preview)"
                        >
                          <Eye size={14} />
                        </button>
                        <button
                          onClick={() => handleOpenEdit(vid)}
                          className="btn btn-secondary btn-icon"
                          title={t('common.edit')}
                        >
                          <Edit2 size={14} />
                        </button>
                        <button
                          onClick={() => handleDelete(vid.id)}
                          className="btn btn-danger btn-icon"
                          title={t('common.delete')}
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Video Modal Form */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentVideo?.id ? t('videos.editVideo') : t('videos.addVideo')}
        maxWidth="640px"
      >
        <form onSubmit={handleSave}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label" style={{ fontWeight: 700 }}>
                {t('videos.category')} <span style={{ color: 'var(--danger)' }}>*</span>
              </label>
              <select
                className="form-control"
                value={currentVideo?.category || 'உயிர் எழுத்துகள்'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, category: e.target.value })}
              >
                <option value="உயிர் எழுத்துகள்">🅰️ உயிர் எழுத்துகள் (Uyir Letters - அ, ஆ...)</option>
                <option value="மெய் எழுத்துகள்">✍️ மெய் எழுத்துகள் (Mei Letters - க், ங்...)</option>
                <option value="ஆய்த எழுத்து">⭐ ஆய்த எழுத்து (Aytham Letter - ஃ)</option>
                <option value="பாடல்">🎵 பாடல் (Song / Rhyme)</option>
                <option value="கதை">📖 கதை (Story / Tale)</option>
                <option value="பாடம்">🎓 பாடம் (Lesson / Educational)</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">{t('videos.duration')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="00:10"
                value={currentVideo?.duration || '00:10'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, duration: e.target.value })}
              />
            </div>
          </div>

          {/* Quick Letter Pickers */}
          {currentVideo?.category === 'உயிர் எழுத்துகள்' && (
            <div className="form-group" style={{ background: '#FDF2F8', padding: '12px', borderRadius: '12px', border: '1px solid #FBCFE8' }}>
              <label className="form-label" style={{ color: '#BE185D', fontWeight: 700, fontSize: '12px', marginBottom: '8px', display: 'block' }}>
                ⚡ விரைவு உயிர் எழுத்து தேர்வு (Click to auto-fill Uyir Letter):
              </label>
              <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                {UYIR_LETTERS.map((letter, idx) => (
                  <button
                    key={letter}
                    type="button"
                    onClick={() => handleQuickLetterPick(letter, idx)}
                    className="btn btn-sm"
                    style={{
                      background: currentVideo?.title === letter ? '#DB2777' : 'white',
                      color: currentVideo?.title === letter ? 'white' : '#BE185D',
                      borderColor: '#F472B6',
                      fontWeight: 700,
                      minWidth: '34px',
                      padding: '4px 8px',
                    }}
                  >
                    {letter}
                  </button>
                ))}
              </div>
            </div>
          )}

          {currentVideo?.category === 'மெய் எழுத்துகள்' && (
            <div className="form-group" style={{ background: '#EFF6FF', padding: '12px', borderRadius: '12px', border: '1px solid #BFDBFE' }}>
              <label className="form-label" style={{ color: '#1D4ED8', fontWeight: 700, fontSize: '12px', marginBottom: '8px', display: 'block' }}>
                ⚡ விரைவு மெய் எழுத்து தேர்வு (Click to auto-fill Mei Letter):
              </label>
              <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                {MEI_LETTERS.map((letter, idx) => (
                  <button
                    key={letter}
                    type="button"
                    onClick={() => handleQuickLetterPick(letter, idx)}
                    className="btn btn-sm"
                    style={{
                      background: currentVideo?.title === letter ? '#2563EB' : 'white',
                      color: currentVideo?.title === letter ? 'white' : '#1D4ED8',
                      borderColor: '#60A5FA',
                      fontWeight: 700,
                      minWidth: '34px',
                      padding: '4px 8px',
                    }}
                  >
                    {letter}
                  </button>
                ))}
              </div>
            </div>
          )}

          {currentVideo?.category === 'ஆய்த எழுத்து' && (
            <div className="form-group" style={{ background: '#FAF5FF', padding: '12px', borderRadius: '12px', border: '1px solid #E9D5FF' }}>
              <label className="form-label" style={{ color: '#7E22CE', fontWeight: 700, fontSize: '12px', marginBottom: '8px', display: 'block' }}>
                ⚡ விரைவு ஆய்த எழுத்து தேர்வு (Click to auto-fill Aytham Letter):
              </label>
              <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                <button
                  type="button"
                  onClick={() => handleQuickLetterPick('ஃ', 0)}
                  className="btn btn-sm"
                  style={{
                    background: currentVideo?.title === 'ஃ' ? '#7E22CE' : 'white',
                    color: currentVideo?.title === 'ஃ' ? 'white' : '#7E22CE',
                    borderColor: '#C084FC',
                    fontWeight: 700,
                    minWidth: '40px',
                    padding: '4px 12px',
                    fontSize: '16px',
                  }}
                >
                  ஃ
                </button>
              </div>
            </div>
          )}

          <div className="form-group">
            <label className="form-label" style={{ fontWeight: 700 }}>
              {t('videos.title')} <span style={{ color: 'var(--danger)' }}>*</span>
            </label>
            <input
              type="text"
              className="form-control"
              placeholder="எ.கா. அ அல்லது க் அல்லது உயிர் எழுத்துகள் பாடல்"
              value={currentVideo?.title || ''}
              onChange={(e) => setCurrentVideo({ ...currentVideo, title: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('videos.description')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="எ.கா. க் எழுத்து கற்பிக்கும் சிறப்பு காணொளி"
              value={currentVideo?.description || ''}
              onChange={(e) => setCurrentVideo({ ...currentVideo, description: e.target.value })}
            />
          </div>

          {/* Video File Upload */}
          <FileUpload
            type="video"
            label="🎥 காணொளி கோப்பு பதிவேற்றுக (Video File - MP4, WebM, MOV)"
            currentValue={currentVideo?.video_url}
            onUploaded={(path) => setCurrentVideo((prev) => (prev ? { ...prev, video_url: path } : prev))}
            onClear={() => setCurrentVideo((prev) => (prev ? { ...prev, video_url: '' } : prev))}
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('videos.thumbnail')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="🎬"
                value={currentVideo?.thumbnail_emoji || '🎬'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, thumbnail_emoji: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">வரிசை (Order)</label>
              <input
                type="number"
                className="form-control"
                value={currentVideo?.display_order || 1}
                onChange={(e) => setCurrentVideo({ ...currentVideo, display_order: parseInt(e.target.value) || 1 })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('videos.status')}</label>
              <select
                className="form-control"
                value={currentVideo?.is_published ? '1' : '0'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, is_published: e.target.value === '1' })}
              >
                <option value="1">{t('common.active')} (Published)</option>
                <option value="0">{t('common.inactive')} (Draft)</option>
              </select>
            </div>
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

      {/* Video Player Preview Modal */}
      {previewingVideo && (
        <Modal
          isOpen={true}
          onClose={() => setPreviewingVideo(null)}
          title={`▶ ${previewingVideo.title}`}
          maxWidth="640px"
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div style={{ borderRadius: '12px', overflow: 'hidden', background: '#000', boxShadow: '0 4px 16px rgba(0,0,0,0.2)' }}>
              <video
                controls
                autoPlay
                src={resolveMediaUrl(previewingVideo.video_url)}
                style={{ width: '100%', maxHeight: '360px', display: 'block' }}
              >
                உங்கள் உலாவி காணொளியை ஆதரிக்கவில்லை (Your browser does not support HTML5 video).
              </video>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '6px' }}>
              <div>
                <span className="badge badge-secondary" style={{ marginRight: '8px' }}>
                  {previewingVideo.category}
                </span>
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>
                  கால அளவு: {previewingVideo.duration || '00:10'}
                </span>
              </div>
              <span className="badge badge-success">Status: Published</span>
            </div>
            {previewingVideo.description && (
              <p style={{ fontSize: '14px', color: 'var(--text-dark, #334155)', margin: 0 }}>
                {previewingVideo.description}
              </p>
            )}
            <div style={{ textAlign: 'right', marginTop: '12px' }}>
              <button
                type="button"
                onClick={() => setPreviewingVideo(null)}
                className="btn btn-secondary"
              >
                மூடுக (Close)
              </button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};
