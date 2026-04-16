import 'package:flutter/foundation.dart';

import '../../data/models/catalog_models.dart';
import '../../data/models/learning_engine_models.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/learning_repository.dart';

class LearningProvider extends ChangeNotifier {
  LearningProvider(this._repository);

  final LearningRepository _repository;

  List<LearningLanguage> _languages = const [];
  String? _activeLanguageCode;
  final Map<String, List<LearningLevel>> _levelsByLanguage = {};
  final Map<int, List<LearningLesson>> _lessonsByLevel = {};
  final Map<int, List<LearningWord>> _wordsByLesson = {};
  final Map<String, Set<int>> _completedLessonIdsByLanguage = {};
  final Map<String, Set<int>> _passedLevelIdsByLanguage = {};
  final Map<String, Set<int>> _wrongQuestionIdsByLevel = {};

  List<LevelModel> _levels = const [];
  List<QuizQuestionModel> _quizQuestions = const [];
  bool _isLoadingCatalog = false;
  bool _isLoadingQuiz = false;
  String? _error;

  List<LearningLanguage> get languages => _languages;
  String? get activeLanguageCode => _activeLanguageCode;
  List<LearningLevel> get engineLevels =>
      _activeLanguageCode == null ? const [] : (_levelsByLanguage[_activeLanguageCode!] ?? const []);

  List<LevelModel> get levels => _levels;
  List<QuizQuestionModel> get quizQuestions => _quizQuestions;
  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isLoadingQuiz => _isLoadingQuiz;
  String? get error => _error;

  List<LearningLesson> lessonsForLevel(int levelId) => _lessonsByLevel[levelId] ?? const [];
  List<LearningWord> wordsForLesson(int lessonId) => _wordsByLesson[lessonId] ?? const [];
  bool isLevelLocked(LearningLevel level) => level.isLocked;
  bool isLevelCompleted(LearningLevel level) => level.isCompleted;
  Set<int> wrongQuestionIdsForLevel(String levelCode) => _wrongQuestionIdsByLevel[_normalizeLevelCode(levelCode)] ?? const <int>{};

  Future<void> fetchLanguages({String? preferredLanguageCode}) async {
    _isLoadingCatalog = true;
    _error = null;
    notifyListeners();

    try {
      _languages = await _repository.fetchLanguages();
      if (_languages.isNotEmpty) {
        final preferred = preferredLanguageCode?.trim().toLowerCase();
        if (preferred != null && preferred.isNotEmpty) {
          final exists = _languages.any((entry) => entry.code == preferred);
          _activeLanguageCode = exists ? preferred : _activeLanguageCode;
        }
        _activeLanguageCode ??= _languages.first.code;
        await fetchLevelsForLanguage(languageCode: _activeLanguageCode!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  Future<void> switchLanguage(String languageCode) async {
    if (_activeLanguageCode == languageCode && _levelsByLanguage.containsKey(languageCode)) {
      return;
    }
    _activeLanguageCode = languageCode;
    notifyListeners();
    await fetchLevelsForLanguage(languageCode: languageCode);
  }

  Future<void> fetchLevelsForLanguage({String? languageCode}) async {
    final code = (languageCode ?? _activeLanguageCode ?? '').trim().toLowerCase();
    if (code.isEmpty) {
      return;
    }

    final language = _languages.firstWhere(
      (entry) => entry.code == code,
      orElse: () => LearningLanguage(id: 0, name: code.toUpperCase(), code: code),
    );

    _isLoadingCatalog = true;
    _error = null;
    notifyListeners();

    try {
      final levels = await _repository.fetchLevelsForLanguage(code, languageId: language.id);
      final completionMap = await _repository.fetchLessonCompletionMap();
      final passedLevelCodes = await _repository.fetchPassedLevelCodes();

      final lessonsByLevel = <int, List<LearningLesson>>{};
      for (final level in levels) {
        final lessons = await _repository.fetchLessonsForLevel(
          levelId: level.id,
          levelName: level.name,
          languageCode: code,
        );
        final hydrated = lessons
            .map((lesson) => lesson.copyWith(isCompleted: completionMap[lesson.id] ?? lesson.isCompleted))
            .toList();
        lessonsByLevel[level.id] = hydrated;
      }

      final sorted = [...levels]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final gated = <LearningLevel>[];

      for (var index = 0; index < sorted.length; index++) {
        final level = sorted[index];
        final lessonList = lessonsByLevel[level.id] ?? const <LearningLesson>[];
        final allLessonsDone = lessonList.isNotEmpty && lessonList.every((lesson) => lesson.isCompleted);
        final levelQuizPassed = passedLevelCodes.contains(_normalizeLevelCode(level.name));

        bool isLocked = false;
        if (index > 0) {
          final previous = gated[index - 1];
          final previousLessons = lessonsByLevel[previous.id] ?? const <LearningLesson>[];
          final previousAllLessonsDone =
              previousLessons.isNotEmpty && previousLessons.every((lesson) => lesson.isCompleted);
          final previousQuizPassed = passedLevelCodes.contains(_normalizeLevelCode(previous.name));
          isLocked = !(previousAllLessonsDone && previousQuizPassed);
        }

        gated.add(
          level.copyWith(
            isCompleted: allLessonsDone && levelQuizPassed,
            isLocked: isLocked,
          ),
        );
      }

      _activeLanguageCode = code;
      _levelsByLanguage[code] = gated;
      _lessonsByLevel.addAll(lessonsByLevel);

      _completedLessonIdsByLanguage[code] = completionMap.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toSet();

      final passedIds = <int>{};
      for (final level in gated) {
        if (passedLevelCodes.contains(_normalizeLevelCode(level.name))) {
          passedIds.add(level.id);
        }
      }
      _passedLevelIdsByLanguage[code] = passedIds;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  Future<void> fetchLessonsForLevel(int levelId) async {
    final code = _activeLanguageCode;
    if (code == null) {
      return;
    }
    final level = (_levelsByLanguage[code] ?? const <LearningLevel>[]).firstWhere(
      (entry) => entry.id == levelId,
      orElse: () => const LearningLevel(
        id: 0,
        languageId: 0,
        name: '',
        orderIndex: 0,
        isCompleted: false,
        isLocked: true,
      ),
    );
    if (level.id == 0) {
      return;
    }

    final completionMap = await _repository.fetchLessonCompletionMap();
    final lessons = await _repository.fetchLessonsForLevel(
      levelId: levelId,
      levelName: level.name,
      languageCode: code,
    );
    _lessonsByLevel[levelId] = lessons
        .map((lesson) => lesson.copyWith(isCompleted: completionMap[lesson.id] ?? lesson.isCompleted))
        .toList();
    notifyListeners();
  }

  Future<void> fetchWordsForLesson(int lessonId) async {
    _wordsByLesson[lessonId] = await _repository.fetchWordsForLesson(lessonId);
    notifyListeners();
  }

  Future<void> loadPreviousWrongAnswers({required String levelCode}) async {
    final normalizedLevelCode = _normalizeLevelCode(levelCode);
    final attempts = await _repository.fetchMyQuizAttempts();
    QuizAttemptModel? latestAttempt;
    for (final attempt in attempts) {
      if (_normalizeLevelCode(attempt.levelCode ?? '') == normalizedLevelCode) {
        latestAttempt = attempt;
        break;
      }
    }

    _wrongQuestionIdsByLevel[normalizedLevelCode] = (latestAttempt?.submittedAnswers ?? const [])
        .where((entry) => entry['is_correct'] == false)
        .map((entry) => (entry['question_id'] as num?)?.toInt())
        .whereType<int>()
        .toSet();
    notifyListeners();
  }

  Future<void> markLessonComplete(LearningLesson lesson) async {
    final code = _activeLanguageCode;
    if (code == null) {
      return;
    }

    await _repository.markLessonComplete(lessonId: lesson.id);
    final completed = _completedLessonIdsByLanguage.putIfAbsent(code, () => <int>{});
    completed.add(lesson.id);

    final levelLessons = _lessonsByLevel[lesson.levelId] ?? const <LearningLesson>[];
    _lessonsByLevel[lesson.levelId] = levelLessons
        .map((entry) => entry.id == lesson.id ? entry.copyWith(isCompleted: true) : entry)
        .toList();

    await fetchLevelsForLanguage(languageCode: code);
  }

  Future<QuizSubmitResponseModel?> submitLevelQuiz({
    required int levelId,
    required Map<int, String> answers,
    required int durationSeconds,
  }) async {
    final code = _activeLanguageCode;
    if (code == null) {
      return null;
    }

    final level = (_levelsByLanguage[code] ?? const <LearningLevel>[]).firstWhere(
      (entry) => entry.id == levelId,
      orElse: () => const LearningLevel(
        id: 0,
        languageId: 0,
        name: '',
        orderIndex: 0,
        isCompleted: false,
        isLocked: true,
      ),
    );
    if (level.id == 0) {
      return null;
    }

    final response = await _repository.submitLevelQuiz(
      levelCode: _normalizeLevelCode(level.name),
      languageCode: code,
      durationSeconds: durationSeconds,
      answers: answers,
    );
    final passed = response.score >= 80;

    if (passed) {
      final passedSet = _passedLevelIdsByLanguage.putIfAbsent(code, () => <int>{});
      passedSet.add(levelId);
    }

    await fetchLevelsForLanguage(languageCode: code);
    return response;
  }

  String _normalizeLevelCode(String levelName) {
    return levelName.trim().toUpperCase();
  }

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

  Future<void> loadQuiz({String? levelCode, String? languageCode, int count = 10}) async {
    _isLoadingQuiz = true;
    _error = null;
    notifyListeners();

    try {
      _quizQuestions = await _repository.generateQuiz(
        levelCode: levelCode,
        languageCode: languageCode,
        count: count,
      );
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
    _languages = const [];
    _activeLanguageCode = null;
    _levelsByLanguage.clear();
    _lessonsByLevel.clear();
    _wordsByLesson.clear();
    _completedLessonIdsByLanguage.clear();
    _passedLevelIdsByLanguage.clear();
    _wrongQuestionIdsByLevel.clear();
    _levels = const [];
    _quizQuestions = const [];
    _isLoadingCatalog = false;
    _isLoadingQuiz = false;
    _error = null;
    notifyListeners();
  }
}
