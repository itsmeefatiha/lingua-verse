import 'package:flutter/foundation.dart';

import '../../data/models/catalog_models.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/learning_repository.dart';

class LearningProvider extends ChangeNotifier {
  LearningProvider(this._repository);

  final LearningRepository _repository;

  List<LevelModel> _levels = const [];
  List<QuizQuestionModel> _quizQuestions = const [];
  bool _isLoadingCatalog = false;
  bool _isLoadingQuiz = false;
  String? _error;

  List<LevelModel> get levels => _levels;
  List<QuizQuestionModel> get quizQuestions => _quizQuestions;
  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isLoadingQuiz => _isLoadingQuiz;
  String? get error => _error;

  Future<void> loadCatalog() async {
    _isLoadingCatalog = true;
    _error = null;
    notifyListeners();

    try {
      _levels = await _repository.getRoadmap();
    } catch (e) {
      _error = e.toString();
      _levels = const [];
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  Future<void> loadQuiz({String? levelCode, int count = 10}) async {
    _isLoadingQuiz = true;
    _error = null;
    notifyListeners();

    try {
      _quizQuestions = await _repository.generateQuiz(levelCode: levelCode, count: count);
    } catch (e) {
      _error = e.toString();
      _quizQuestions = const [];
    } finally {
      _isLoadingQuiz = false;
      notifyListeners();
    }
  }

  Future<QuizSubmitResponseModel?> submitQuiz({
    String? levelCode,
    required int durationSeconds,
    required Map<int, String> answers,
  }) async {
    try {
      return await _repository.submitQuiz(
        levelCode: levelCode,
        durationSeconds: durationSeconds,
        answers: answers,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clear() {
    _levels = const [];
    _quizQuestions = const [];
    _isLoadingCatalog = false;
    _isLoadingQuiz = false;
    _error = null;
    notifyListeners();
  }
}
