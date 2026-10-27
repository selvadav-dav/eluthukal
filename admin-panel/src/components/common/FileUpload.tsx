import React, { useState, useRef, useEffect } from 'react';
import { UploadCloud, CheckCircle2, AlertCircle, Loader2, Video, Volume2, Image as ImageIcon, Trash2, RefreshCw, PlayCircle } from 'lucide-react';
import { uploadApi } from '../../api/upload';
import { useLanguage } from '../../context/LanguageContext';
import { resolveMediaUrl, resolveVideoProxyUrl } from '../../api/client';

interface FileUploadProps {
  type: 'image' | 'audio' | 'video';
  currentValue?: string | null;
  onUploaded: (url: string) => void;
  onClear?: () => void;
  label?: string;
  autoUpload?: boolean;
}

const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
};

export const FileUpload: React.FC<FileUploadProps> = ({
  type,
  currentValue,
  onUploaded,
  onClear,
  label,
  autoUpload = true,
}) => {
  const { t } = useLanguage();
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [uploadedPath, setUploadedPath] = useState<string | null>(currentValue || null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [localPreview, setLocalPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    setUploadedPath(currentValue || null);
    if (!currentValue) {
      setSelectedFile(null);
      setLocalPreview(null);
    }
  }, [currentValue]);

  const displayLabel =
    label ||
    (type === 'image'
      ? t('upload_label_image') || 'படம் (Image)'
      : type === 'audio'
      ? t('upload_label_audio') || 'ஒலி (Audio)'
      : 'காணொளி கோப்பு (Video File)');

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate size (100MB max for video, 20MB for audio/image)
    const maxMb = type === 'video' ? 100 : 20;
    if (file.size > maxMb * 1024 * 1024) {
      setError(`கோப்பு அளவு ${maxMb}MB க்குள் இருக்க வேண்டும் (File size exceeds ${maxMb}MB).`);
      return;
    }

    setError(null);
    setSelectedFile(file);

    try {
      const previewUrl = URL.createObjectURL(file);
      setLocalPreview(previewUrl);
    } catch {
      // ignore preview error
    }

    if (autoUpload) {
      performUpload(file);
    }
  };

  const performUpload = async (fileToUpload?: File) => {
    const file = fileToUpload || selectedFile;
    if (!file) return;

    setIsUploading(true);
    setUploadProgress(0);
    setError(null);

    try {
      let res;
      const onProgress = (p: number) => setUploadProgress(p);

      if (type === 'image') res = await uploadApi.uploadImage(file, onProgress);
      else if (type === 'audio') res = await uploadApi.uploadAudio(file, onProgress);
      else res = await uploadApi.uploadVideo(file, onProgress);

      if (res.success && res.data) {
        setUploadedPath(res.data.path);
        onUploaded(res.data.path);
      } else {
        throw new Error(res.message || 'Upload failed');
      }
    } catch (err: any) {
      console.error('File upload error:', err);
      const msg =
        err.response?.data?.message ||
        err.response?.data?.error ||
        err.message ||
        'Upload failed. Please check network/backend.';
      setError(msg);
    } finally {
      setIsUploading(false);
    }
  };

  const handleDelete = (e: React.MouseEvent) => {
    e.stopPropagation();
    setUploadedPath(null);
    setSelectedFile(null);
    setLocalPreview(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
    onUploaded('');
    if (onClear) onClear();
  };

  const handleTriggerUpload = () => {
    if (fileInputRef.current && !isUploading) {
      fileInputRef.current.click();
    }
  };

  const acceptMap = {
    image: 'image/jpeg,image/png,image/webp,image/svg+xml,image/jpg',
    audio: 'audio/mpeg,audio/mp3,audio/wav,audio/aac,audio/m4a,audio/ogg',
    video: 'video/mp4,video/webm,video/quicktime,video/mov,.mp4,.webm,.mov',
  };

  const getMediaUrl = (path: string) => {
    return type === 'video' ? resolveVideoProxyUrl(path) : resolveMediaUrl(path);
  };

  const previewSrc = localPreview || (uploadedPath ? getMediaUrl(uploadedPath) : null);

  return (
    <div className="form-group" style={{ marginBottom: '14px' }}>
      <label className="form-label" style={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: '6px' }}>
        {type === 'video' && <Video size={16} color="#8E24AA" />}
        {type === 'audio' && <Volume2 size={16} color="#00897B" />}
        {type === 'image' && <ImageIcon size={16} color="#E65100" />}
        <span>{displayLabel}</span>
      </label>

      <input
        ref={fileInputRef}
        type="file"
        accept={acceptMap[type]}
        onChange={handleFileSelect}
        disabled={isUploading}
        style={{ display: 'none' }}
      />

      <div
        style={{
          border: error
            ? '2px dashed var(--danger)'
            : isUploading
            ? '2px dashed #8E24AA'
            : uploadedPath || selectedFile
            ? '2px solid var(--border-color)'
            : '2px dashed var(--border-color)',
          borderRadius: 'var(--radius-lg, 12px)',
          padding: '14px',
          background: uploadedPath || selectedFile ? '#FAF5FF' : 'var(--bg-muted, #F8FAFC)',
          position: 'relative',
          transition: 'all 0.2s',
        }}
      >
        {isUploading ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '10px', padding: '10px 0' }}>
            <Loader2 size={32} className="spin" color="#8E24AA" />
            <div style={{ fontWeight: 700, color: '#6A1B9A', fontSize: '14px' }}>
              {type === 'video' ? 'காணொளி பதிவேற்றப்படுகிறது... (Uploading Video...)' : 'பதிவேற்றப்படுகிறது... (Uploading...)'}
            </div>
            {selectedFile && (
              <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                {selectedFile.name} ({formatFileSize(selectedFile.size)})
              </div>
            )}
            {/* Progress Bar */}
            <div style={{ width: '100%', maxWidth: '280px', background: '#E2E8F0', borderRadius: '8px', height: '8px', overflow: 'hidden' }}>
              <div
                style={{
                  width: `${uploadProgress}%`,
                  height: '100%',
                  background: 'linear-gradient(90deg, #8E24AA, #AB47BC)',
                  transition: 'width 0.2s ease',
                }}
              />
            </div>
            <span style={{ fontSize: '12px', fontWeight: 600, color: '#8E24AA' }}>{uploadProgress}%</span>
          </div>
        ) : uploadedPath || selectedFile ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {/* Top header with Status and Delete */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: uploadedPath ? '#16A34A' : '#E65100' }}>
                <CheckCircle2 size={18} />
                <span style={{ fontSize: '13px', fontWeight: 700 }}>
                  {uploadedPath
                    ? type === 'video'
                      ? 'காணொளி வெற்றிகரமாக பதிவேற்றப்பட்டது (Uploaded)'
                      : 'வெற்றிகரமாக பதிவேற்றப்பட்டது (Uploaded)'
                    : 'கோப்பு தேர்ந்தெடுக்கப்பட்டது (Selected)'}
                </span>
              </div>
              <button
                type="button"
                onClick={handleDelete}
                className="btn btn-danger btn-sm"
                style={{ padding: '4px 8px', fontSize: '11px', display: 'flex', alignItems: 'center', gap: '4px' }}
                title="நீக்குக (Delete)"
              >
                <Trash2 size={13} />
                <span>நீக்குக (Delete)</span>
              </button>
            </div>

            {/* Selected File Details */}
            {selectedFile && (
              <div style={{ background: 'white', padding: '8px 12px', borderRadius: '8px', border: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', fontSize: '12px' }}>
                <span style={{ fontWeight: 600, color: 'var(--text-dark, #1E293B)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: '70%' }}>
                  📄 {selectedFile.name}
                </span>
                <span style={{ color: 'var(--text-muted)', fontWeight: 600 }}>
                  {formatFileSize(selectedFile.size)}
                </span>
              </div>
            )}

            {/* Video Player Preview */}
            {type === 'video' && previewSrc && (
              <div style={{ width: '100%', borderRadius: '8px', overflow: 'hidden', border: '1px solid #CBD5E1', background: '#0F172A', boxShadow: '0 2px 8px rgba(0,0,0,0.15)' }}>
                <video
                  controls
                  controlsList="nodownload"
                  onContextMenu={(e) => e.preventDefault()}
                  src={previewSrc}
                  style={{ width: '100%', maxHeight: '200px', display: 'block', margin: '0 auto' }}
                  preload="metadata"
                  onError={(e) => {
                    const target = e.currentTarget;
                    const direct = uploadedPath ? resolveMediaUrl(uploadedPath) : '';
                    if (direct && target.src !== direct) {
                      target.src = direct;
                    }
                  }}
                >
                  உங்கள் உலாவி காணொளியை ஆதரிக்கவில்லை (Your browser does not support HTML5 video).
                </video>
              </div>
            )}

            {/* Image Preview */}
            {type === 'image' && previewSrc && (
              <div style={{ textAlign: 'center' }}>
                <img
                  src={previewSrc}
                  alt="Preview"
                  style={{
                    maxHeight: '120px',
                    maxWidth: '100%',
                    borderRadius: '8px',
                    objectFit: 'contain',
                    border: '1px solid var(--border-color)',
                    background: 'white',
                    padding: '4px',
                  }}
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
              </div>
            )}

            {/* Manual Upload Button if not yet uploaded */}
            {!uploadedPath && selectedFile && (
              <button
                type="button"
                onClick={() => performUpload()}
                className="btn btn-primary btn-sm"
                style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', fontWeight: 700 }}
              >
                <UploadCloud size={16} />
                <span>காணொளியை பதிவேற்றுக (Upload Video)</span>
              </button>
            )}

            {/* Path and Replace Footer */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%', flexWrap: 'wrap', gap: '8px', marginTop: '2px' }}>
              {uploadedPath && (
                <span style={{ fontSize: '11px', color: 'var(--text-muted)', wordBreak: 'break-all', textAlign: 'left', flex: 1 }}>
                  📁 {uploadedPath}
                </span>
              )}
              <button
                type="button"
                onClick={handleTriggerUpload}
                className="btn btn-secondary btn-sm"
                style={{ padding: '4px 10px', fontSize: '12px', display: 'flex', alignItems: 'center', gap: '5px', fontWeight: 600, marginLeft: 'auto' }}
              >
                <RefreshCw size={13} />
                <span>மாற்றுக (Choose Another)</span>
              </button>
            </div>
          </div>
        ) : (
          <div
            onClick={handleTriggerUpload}
            style={{ cursor: 'pointer', padding: '14px 8px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}
          >
            <UploadCloud size={34} style={{ margin: '0 auto 6px', display: 'block', color: type === 'video' ? '#8E24AA' : 'var(--primary)' }} />
            <div style={{ fontSize: '14px', fontWeight: 700, color: 'var(--text-dark, #1E293B)' }}>
              {type === 'video' ? '📁 காணொளியைத் தேர்ந்தெடுக்கவும் (Choose Video)' : t('upload_click')}
            </div>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>
              {type === 'video' ? 'ஆதரிக்கப்படும் வடிவங்கள்: MP4, MOV, WebM (அதிகபட்சம் 100MB)' : t('upload_limits', { type: type.toUpperCase() })}
            </div>
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              style={{ marginTop: '10px', pointerEvents: 'none', fontWeight: 700, background: '#F3E5F5', color: '#6A1B9A', border: '1px solid #CE93D8' }}
            >
              {type === 'video' ? '📁 Choose Video File' : 'கோப்பு தேர்ந்தெடுக்கவும்'}
            </button>
          </div>
        )}
      </div>

      {error && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: 'var(--danger)', fontSize: '12px', marginTop: '6px', background: '#FEE2E2', padding: '6px 10px', borderRadius: '6px' }}>
          <AlertCircle size={15} />
          <span style={{ fontWeight: 600 }}>{error}</span>
        </div>
      )}
    </div>
  );
};

