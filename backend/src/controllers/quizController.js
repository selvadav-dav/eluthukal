/**
 * Quizzes & Evaluation Controller
 */
const QuizModel = require('../models/quizModel');
const QuizService = require('../services/quizService');
const { successResponse, errorResponse } = require('../utils/apiResponse');

class QuizController {
  static async getAll(req, res, next) {
    try {
      const { category } = req.query;
      const onlyActive = req.query.all !== 'true';

      const quizzes = await QuizModel.getAll({ category, onlyActive });
      return successResponse(res, 'Quizzes fetched successfully', quizzes);
    } catch (error) {
      next(error);
    }
  }

  static async getById(req, res, next) {
    try {
      // Include answers only if requested by admin (indicated by includeAnswers=true when authenticated)
      const includeAnswers = req.query.includeAnswers === 'true' && req.user;
      const quiz = await QuizModel.getById(req.params.id, { includeAnswers });

      if (!quiz) {
        return errorResponse(res, 'Quiz not found', null, 404);
      }
      return successResponse(res, 'Quiz fetched successfully', quiz);
    } catch (error) {
      next(error);
    }
  }

  static async create(req, res, next) {
    try {
      const quiz = await QuizModel.createQuiz(req.body);
      return successResponse(res, 'Quiz created successfully', quiz, 201);
    } catch (error) {
      next(error);
    }
  }

  static async update(req, res, next) {
    try {
      const quiz = await QuizModel.updateQuiz(req.params.id, req.body);
      if (!quiz) {
        return errorResponse(res, 'Quiz not found', null, 404);
      }
      return successResponse(res, 'Quiz updated successfully', quiz);
    } catch (error) {
      next(error);
    }
  }

  static async delete(req, res, next) {
    try {
      const deleted = await QuizModel.deleteQuiz(req.params.id);
      if (!deleted) {
        return errorResponse(res, 'Quiz not found', null, 404);
      }
      return successResponse(res, 'Quiz deleted successfully');
    } catch (error) {
      next(error);
    }
  }

  // --- Questions ---
  static async addQuestion(req, res, next) {
    try {
      const questionId = await QuizModel.addQuestion(req.params.id, req.body);
      const updatedQuiz = await QuizModel.getById(req.params.id, { includeAnswers: true });
      return successResponse(res, 'Question added successfully', { questionId, quiz: updatedQuiz }, 201);
    } catch (error) {
      next(error);
    }
  }

  static async deleteQuestion(req, res, next) {
    try {
      const deleted = await QuizModel.deleteQuestion(req.params.questionId);
      if (!deleted) {
        return errorResponse(res, 'Question not found', null, 404);
      }
      return successResponse(res, 'Question deleted successfully');
    } catch (error) {
      next(error);
    }
  }

  // --- Child Quiz Submission ---
  static async submitQuiz(req, res, next) {
    try {
      const { userId, answers, score, totalQuestions, correctAnswers, starsEarned } = req.body;
      const quizId = req.params.id;

      if (!userId) {
        return errorResponse(res, 'userId is required to submit quiz', null, 400);
      }

      const result = await QuizService.submitQuiz(userId, quizId, answers || [], {
        score,
        totalQuestions,
        correctAnswers,
        starsEarned,
      });
      return successResponse(res, 'Quiz evaluated successfully', result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = QuizController;
