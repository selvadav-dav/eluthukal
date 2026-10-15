import React, { useEffect, useState } from 'react';
import { quizzesApi } from '../api/quizzes';
import { Quiz } from '../types';
import { Modal } from '../components/common/Modal';
import { useLanguage } from '../context/LanguageContext';
import { Plus, Edit2, Trash2, Layers, CheckCircle2, XCircle, Loader2 } from 'lucide-react';

export const QuizzesPage: React.FC = () => {
  const { t } = useLanguage();
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentQuiz, setCurrentQuiz] = useState<Partial<Quiz> | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Questions Manager
  const [selectedQuiz, setSelectedQuiz] = useState<Quiz | null>(null);
  const [isQuestionsModalOpen, setIsQuestionsModalOpen] = useState(false);
  const [newQuestionText, setNewQuestionText] = useState('');
  const [newVisualHint, setNewVisualHint] = useState('⭐');
  const [newExplanation, setNewExplanation] = useState('');
  const [options, setOptions] = useState([
    { text: '', isCorrect: true },
    { text: '', isCorrect: false },
    { text: '', isCorrect: false },
    { text: '', isCorrect: false },
  ]);

  useEffect(() => {
    fetchQuizzes();
  }, []);

  const fetchQuizzes = async () => {
    setLoading(true);
    try {
      const res = await quizzesApi.getAll({ all: true });
      if (res.success && res.data) {
        setQuizzes(res.data);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = () => {
    setCurrentQuiz({
      title: '',
      subtitle: '',
      category: 'uyir',
      icon_emoji: '🍎',
      question_count: 5,
      pass_marks: 3,
      stars_reward: 5,
      display_order: quizzes.length + 1,
      is_active: true,
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (quiz: Quiz) => {
    setCurrentQuiz(quiz);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await quizzesApi.delete(id);
      fetchQuizzes();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Delete failed');
    }
  };

  const handleSaveQuiz = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentQuiz?.title || !currentQuiz?.category) {
      alert('Title and category are required');
      return;
    }

    setIsSubmitting(true);
    try {
      if (currentQuiz.id) {
        await quizzesApi.update(currentQuiz.id, currentQuiz);
      } else {
        await quizzesApi.create(currentQuiz);
      }
      setIsModalOpen(false);
      fetchQuizzes();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Save failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Manage Questions
  const handleOpenQuestions = async (quiz: Quiz) => {
    try {
      const res = await quizzesApi.getById(quiz.id, true);
      if (res.success && res.data) {
        setSelectedQuiz(res.data);
        setIsQuestionsModalOpen(true);
      }
    } catch (err: any) {
      alert(err.message || 'Failed to load questions');
    }
  };

  const handleAddQuestion = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedQuiz || !newQuestionText) {
      alert('Question text is required');
      return;
    }

    // Check options
    const validOptions = options.filter((o) => o.text.trim().length > 0);
    if (validOptions.length < 2) {
      alert('Please enter at least 2 options');
      return;
    }

    try {
      await quizzesApi.addQuestion(selectedQuiz.id, {
        questionText: newQuestionText,
        visualHint: newVisualHint,
        explanation: newExplanation,
        marks: 1,
        displayOrder: (selectedQuiz.questions?.length || 0) + 1,
        options: validOptions.map((o, idx) => ({
          optionText: o.text,
          isCorrect: o.isCorrect,
          displayOrder: idx + 1,
        })),
      } as any);

      // Reload questions
      const res = await quizzesApi.getById(selectedQuiz.id, true);
      if (res.success && res.data) {
        setSelectedQuiz(res.data);
        setNewQuestionText('');
        setNewExplanation('');
        setOptions([
          { text: '', isCorrect: true },
          { text: '', isCorrect: false },
          { text: '', isCorrect: false },
          { text: '', isCorrect: false },
        ]);
      }
      fetchQuizzes();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to add question');
    }
  };

  const handleDeleteQuestion = async (questionId: string) => {
    if (!selectedQuiz) return;
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await quizzesApi.deleteQuestion(selectedQuiz.id, questionId);
      const res = await quizzesApi.getById(selectedQuiz.id, true);
      if (res.success && res.data) {
        setSelectedQuiz(res.data);
      }
      fetchQuizzes();
    } catch (err: any) {
      alert(err.message || 'Failed to delete question');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('quizzes.pageTitle')}</h2>
          <p>{t('quizzes.pageSubtitle')}</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={16} />
          <span>{t('quizzes.addQuiz')}</span>
        </button>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>{t('quizzes.order')}</th>
              <th>{t('quizzes.icon')}</th>
              <th>{t('quizzes.title')}</th>
              <th>{t('quizzes.category')}</th>
              <th>{t('quizzes.questions')}</th>
              <th>{t('quizzes.passMarks')}</th>
              <th>{t('quizzes.starsReward')}</th>
              <th>{t('quizzes.status')}</th>
              <th style={{ textAlign: 'right' }}>{t('quizzes.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : quizzes.length === 0 ? (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              quizzes.map((quiz) => (
                <tr key={quiz.id}>
                  <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>{quiz.display_order}</td>
                  <td style={{ fontSize: '24px' }}>{quiz.icon_emoji}</td>
                  <td>
                    <div style={{ fontWeight: 700 }}>{quiz.title}</div>
                    <div style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{quiz.subtitle}</div>
                  </td>
                  <td>
                    <span className="badge badge-secondary">{quiz.category.toUpperCase()}</span>
                  </td>
                  <td>
                    <button
                      onClick={() => handleOpenQuestions(quiz)}
                      className="btn btn-secondary btn-sm"
                      style={{ gap: '6px' }}
                    >
                      <Layers size={14} />
                      <span>{quiz.actual_question_count || 0} {t('quizzes.questions')} ({t('quizzes.manageQuestions')})</span>
                    </button>
                  </td>
                  <td style={{ fontWeight: 600 }}>{quiz.pass_marks}</td>
                  <td style={{ color: '#EAB308', fontWeight: 700 }}>⭐ +{quiz.stars_reward}</td>
                  <td>
                    {quiz.is_active ? (
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
                      <button onClick={() => handleOpenEdit(quiz)} className="btn btn-secondary btn-icon" title={t('common.edit')}>
                        <Edit2 size={14} />
                      </button>
                      <button onClick={() => handleDelete(quiz.id)} className="btn btn-danger btn-icon" title={t('common.delete')}>
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

      {/* Quiz Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentQuiz?.id ? t('quizzes.editQuiz') : t('quizzes.addQuiz')}
      >
        <form onSubmit={handleSaveQuiz}>
          <div className="form-group">
            <label className="form-label">{t('quizzes.title')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. உயிர் எழுத்துகள் வினாடி வினா"
              value={currentQuiz?.title || ''}
              onChange={(e) => setCurrentQuiz({ ...currentQuiz, title: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('quizzes.subtitle')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. அ முதல் ஔ வரையிலான எழுத்துகளை சோதிப்போம்"
              value={currentQuiz?.subtitle || ''}
              onChange={(e) => setCurrentQuiz({ ...currentQuiz, subtitle: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('quizzes.category')}</label>
              <select
                className="form-control"
                value={currentQuiz?.category || 'uyir'}
                onChange={(e) => setCurrentQuiz({ ...currentQuiz, category: e.target.value })}
              >
                <option value="uyir">உயிர் எழுத்துகள் (Uyir)</option>
                <option value="mei">மெய் எழுத்துகள் (Mei)</option>
                <option value="aytham">ஆய்த எழுத்து (Aytham)</option>
                <option value="uyirmei">உயிர்மெய் (Uyirmei)</option>
                <option value="reading">வாசிப்பு (Reading)</option>
                <option value="general">பொது அறிவு (General)</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">{t('quizzes.icon')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="🍎"
                value={currentQuiz?.icon_emoji || '❓'}
                onChange={(e) => setCurrentQuiz({ ...currentQuiz, icon_emoji: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('quizzes.passMarks')}</label>
              <input
                type="number"
                className="form-control"
                value={currentQuiz?.pass_marks || 3}
                onChange={(e) => setCurrentQuiz({ ...currentQuiz, pass_marks: parseInt(e.target.value, 10) })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('quizzes.starsReward')}</label>
              <input
                type="number"
                className="form-control"
                value={currentQuiz?.stars_reward || 5}
                onChange={(e) => setCurrentQuiz({ ...currentQuiz, stars_reward: parseInt(e.target.value, 10) })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">{t('quizzes.status')}</label>
            <select
              className="form-control"
              value={currentQuiz?.is_active ? '1' : '0'}
              onChange={(e) => setCurrentQuiz({ ...currentQuiz, is_active: e.target.value === '1' })}
            >
              <option value="1">{t('common.active')}</option>
              <option value="0">{t('common.inactive')}</option>
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

      {/* Questions Manager Modal */}
      <Modal
        isOpen={isQuestionsModalOpen}
        onClose={() => setIsQuestionsModalOpen(false)}
        title={`${t('quizzes.manageQuestions')}: ${selectedQuiz?.title || ''}`}
        maxWidth="800px"
      >
        <div>
          {/* Current Questions */}
          <h4 style={{ fontSize: '15px', fontWeight: 700, marginBottom: '12px' }}>
            {t('quizzes.questions')} ({selectedQuiz?.questions?.length || 0})
          </h4>

          {selectedQuiz?.questions && selectedQuiz.questions.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '24px' }}>
              {selectedQuiz.questions.map((q, qIndex) => (
                <div
                  key={q.id}
                  style={{
                    padding: '14px',
                    borderRadius: 'var(--radius-md)',
                    background: 'var(--bg-muted)',
                    border: '1px solid var(--border-color)',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <div style={{ fontWeight: 700, fontSize: '15px' }}>
                      #{qIndex + 1}: {q.question} {q.visualHint && <span>({q.visualHint})</span>}
                    </div>
                    <button
                      onClick={() => handleDeleteQuestion(q.id)}
                      className="btn btn-danger btn-sm"
                      style={{ padding: '3px 8px' }}
                      title={t('common.delete')}
                    >
                      <Trash2 size={12} />
                    </button>
                  </div>

                  {/* Options display */}
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: '8px' }}>
                    {q.options?.map((opt) => (
                      <div
                        key={opt.id}
                        style={{
                          padding: '6px 10px',
                          borderRadius: '6px',
                          fontSize: '14px',
                          background: opt.isCorrect ? '#DCFCE7' : 'white',
                          border: `1px solid ${opt.isCorrect ? '#86EFAC' : 'var(--border-color)'}`,
                          fontWeight: opt.isCorrect ? 700 : 400,
                          color: opt.isCorrect ? '#166534' : 'var(--text-main)',
                        }}
                      >
                        {opt.isCorrect ? '✅ ' : '⚪ '} {opt.optionText}
                      </div>
                    ))}
                  </div>

                  {q.explanation && (
                    <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '8px', fontStyle: 'italic' }}>
                      {t('quizzes.explanation')}: {q.explanation}
                    </div>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '20px' }}>
              {t('common.noData')}
            </p>
          )}

          {/* Add Question Form */}
          <div style={{ borderTop: '2px dashed var(--border-color)', paddingTop: '16px' }}>
            <h4 style={{ fontSize: '15px', fontWeight: 700, marginBottom: '12px' }}>+ {t('quizzes.addQuestion')}</h4>
            <form onSubmit={handleAddQuestion}>
              <div className="form-group">
                <label className="form-label">{t('quizzes.questionText')}</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. அம்மா என்ற சொல்லின் முதல் எழுத்து எது?"
                  value={newQuestionText}
                  onChange={(e) => setNewQuestionText(e.target.value)}
                  required
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '12px' }}>
                <div className="form-group">
                  <label className="form-label">{t('quizzes.visualHint')}</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="👩"
                    value={newVisualHint}
                    onChange={(e) => setNewVisualHint(e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">{t('quizzes.explanation')}</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. அம்மா என்பதன் முதல் எழுத்து அ."
                    value={newExplanation}
                    onChange={(e) => setNewExplanation(e.target.value)}
                  />
                </div>
              </div>

              {/* 4 Choices Form with Radio selector for correct answer */}
              <label className="form-label" style={{ marginTop: '10px' }}>
                {t('quizzes.options')} ({t('quizzes.correctAnswer')})
              </label>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '16px' }}>
                {options.map((opt, i) => (
                  <div
                    key={i}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      background: 'white',
                      border: '1px solid var(--border-color)',
                      padding: '8px 12px',
                      borderRadius: 'var(--radius-md)',
                    }}
                  >
                    <input
                      type="radio"
                      name="correctChoice"
                      checked={opt.isCorrect}
                      onChange={() => {
                        setOptions(options.map((o, idx) => ({ ...o, isCorrect: idx === i })));
                      }}
                      title="Mark as correct answer"
                    />
                    <input
                      type="text"
                      className="form-control"
                      style={{ border: 'none', padding: '4px', fontSize: '14px' }}
                      placeholder={`Option ${i + 1}`}
                      value={opt.text}
                      onChange={(e) => {
                        const val = e.target.value;
                        setOptions(options.map((o, idx) => (idx === i ? { ...o, text: val } : o)));
                      }}
                      required={i < 2}
                    />
                  </div>
                ))}
              </div>

              <button type="submit" className="btn btn-primary btn-sm">
                <Plus size={14} />
                <span>{t('quizzes.addQuestion')}</span>
              </button>
            </form>
          </div>
        </div>
      </Modal>
    </div>
  );
};
