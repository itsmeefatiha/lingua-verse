import 'package:flutter/foundation.dart';

import '../../../../core/storage/database_helper.dart';
import '../../data/models/catalog_models.dart';
import '../../data/models/learning_engine_models.dart';
import '../../data/models/quiz_models.dart';
import '../../data/repositories/learning_repository.dart';

class LearningProvider extends ChangeNotifier {
  LearningProvider(this._repository);

  final LearningRepository _repository;
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
      // OFFLINE-FIRST: Load cached levels immediately
      await _loadLevelsFromCache(code, language);

      // BACKGROUND FETCH: Try to fetch fresh data from API
      _fetchLevelsFromApiInBackground(code, language);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  /// Load levels from local SQLite cache and update state
  Future<void> _loadLevelsFromCache(String languageCode, LearningLanguage language) async {
    if (language.id == 0) {
      return; // Language not in the system yet
    }

    try {
      final cachedLevels = await _dbHelper.getCachedLevels(language.id);
      if (cachedLevels.isEmpty) {
        return; // No cache available
      }

      // Convert cached data to LearningLevel objects
      final levels = cachedLevels.map((levelData) {
        return LearningLevel(
          id: (levelData['id'] as int?) ?? 0,
          languageId: language.id,
          name: (levelData['name'] as String?) ?? (levelData['code'] as String?) ?? '',
          orderIndex: (levelData['display_order'] as int?) ?? 0,
          isCompleted: ((levelData['is_completed'] as int?) ?? 0) == 1,
          isLocked: ((levelData['is_locked'] as int?) ?? 1) == 1,
        );
      }).toList();

      // Load lessons for each level from cache
      final lessonsByLevel = <int, List<LearningLesson>>{};
      for (final level in levels) {
        final cachedLessons = await _dbHelper.getCachedLessons(level.id);
        lessonsByLevel[level.id] = cachedLessons.map((lessonData) {
          return LearningLesson(
            id: (lessonData['id'] as int?) ?? 0,
            levelId: level.id,
            name: (lessonData['title'] as String?) ?? '',
            orderIndex: (lessonData['display_order'] as int?) ?? 0,
            isCompleted: ((lessonData['is_completed'] as int?) ?? 0) == 1,
          );
        }).toList();
      }

      // Update state with cached data
      _activeLanguageCode = languageCode;
      _levelsByLanguage[languageCode] = levels;
      _lessonsByLevel.addAll(lessonsByLevel);

      final completedLessonIds = <int>{};
      for (final lessons in lessonsByLevel.values) {
        for (final lesson in lessons) {
          if (lesson.isCompleted) {
            completedLessonIds.add(lesson.id);
          }
        }
      }
      _completedLessonIdsByLanguage[languageCode] = completedLessonIds;

      final passedLevelIds = <int>{};
      for (final level in levels) {
        if (level.isCompleted) {
          passedLevelIds.add(level.id);
        }
      }
      _passedLevelIdsByLanguage[languageCode] = passedLevelIds;

      notifyListeners();
    } catch (e) {
      // Silently ignore cache loading errors
      debugPrint('Error loading levels from cache: $e');
    }
  }

  /// Fetch fresh data from API in background and update cache
  Future<void> _fetchLevelsFromApiInBackground(
    String languageCode,
    LearningLanguage language,
  ) async {
    try {
      // Fetch fresh levels from API
      final apiLevels = await _repository.fetchLevelsForLanguage(
        languageCode,
        languageId: language.id,
      );

      // Cache the levels
      final levelsForDb = apiLevels
          .map((level) => {
                'id': level.id,
                'name': level.name,
                'code': level.name.toUpperCase(),
                'language_id': level.languageId,
                'display_order': level.orderIndex,
                'is_completed': level.isCompleted,
                'is_locked': level.isLocked,
              })
          .toList();
      await _dbHelper.upsertLevels(levelsForDb);

      // Fetch lessons for each level
      final completionMap = await _repository.fetchLessonCompletionMap();
      final passedLevelCodes = await _repository.fetchPassedLevelCodes();

      final lessonsByLevel = <int, List<LearningLesson>>{};
      for (final level in apiLevels) {
        final apiLessons = await _repository.fetchLessonsForLevel(
          levelId: level.id,
          levelName: level.name,
          languageCode: languageCode,
        );

        // Cache the lessons
        final lessonsForDb = apiLessons
            .map((lesson) => {
                  'id': lesson.id,
                  'title': lesson.name,
                  'level_id': level.id,
                  'display_order': lesson.orderIndex,
                  'is_completed': lesson.isCompleted,
                })
            .toList();
        await _dbHelper.upsertLessons(lessonsForDb);

        final hydrated = apiLessons
            .map(
              (lesson) => lesson.copyWith(
                isCompleted: completionMap[lesson.id] ?? lesson.isCompleted,
              ),
            )
            .toList();
        lessonsByLevel[level.id] = hydrated;
      }

      // Build gated levels (same logic as before)
      final sorted = [...apiLevels]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
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

      // Update cache with lock/completion status
      for (final level in gated) {
        await _dbHelper.updateLevelCompletion(level.id, level.isCompleted);
        await _dbHelper.updateLevelLockStatus(level.id, level.isLocked);
      }

      // Update state with fresh API data
      _activeLanguageCode = languageCode;
      _levelsByLanguage[languageCode] = gated;
      _lessonsByLevel.addAll(lessonsByLevel);

      _completedLessonIdsByLanguage[languageCode] = completionMap.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toSet();

      final passedIds = <int>{};
      for (final level in gated) {
        if (passedLevelCodes.contains(_normalizeLevelCode(level.name))) {
          passedIds.add(level.id);
        }
      }
      _passedLevelIdsByLanguage[languageCode] = passedIds;

      notifyListeners();
    } catch (e) {
      // Silently catch API errors - user already has cached data on screen
      debugPrint('Error fetching levels from API in background: $e');
      _error = null; // Don't show error since we have cached data
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

    try {
      // OFFLINE-FIRST: Load cached lessons immediately
      await _loadLessonsFromCache(levelId);

      // BACKGROUND FETCH: Try to fetch fresh data from API
      _fetchLessonsFromApiInBackground(levelId, level, code);
    } catch (e) {
      debugPrint('Error fetching lessons for level: $e');
    }
  }

  /// Load lessons from local SQLite cache for a level
  Future<void> _loadLessonsFromCache(int levelId) async {
    try {
      final cachedLessons = await _dbHelper.getCachedLessons(levelId);
      if (cachedLessons.isEmpty) {
        return; // No cache available
      }

      final lessons = cachedLessons.map((lessonData) {
        return LearningLesson(
          id: (lessonData['id'] as int?) ?? 0,
          levelId: levelId,
          name: (lessonData['title'] as String?) ?? '',
          orderIndex: (lessonData['display_order'] as int?) ?? 0,
          isCompleted: ((lessonData['is_completed'] as int?) ?? 0) == 1,
        );
      }).toList();

      _lessonsByLevel[levelId] = lessons;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading lessons from cache: $e');
    }
  }

  /// Fetch fresh lessons from API in background and update cache
  Future<void> _fetchLessonsFromApiInBackground(
    int levelId,
    LearningLevel level,
    String languageCode,
  ) async {
    try {
      final completionMap = await _repository.fetchLessonCompletionMap();
      final apiLessons = await _repository.fetchLessonsForLevel(
        levelId: levelId,
        levelName: level.name,
        languageCode: languageCode,
      );

      // Cache the lessons
      final lessonsForDb = apiLessons
          .map((lesson) => {
                'id': lesson.id,
                'title': lesson.name,
                'level_id': levelId,
                'display_order': lesson.orderIndex,
                'is_completed': lesson.isCompleted,
              })
          .toList();
      await _dbHelper.upsertLessons(lessonsForDb);

      // Update state with fresh data
      final hydrated = apiLessons
          .map(
            (lesson) => lesson.copyWith(
              isCompleted: completionMap[lesson.id] ?? lesson.isCompleted,
            ),
          )
          .toList();
      _lessonsByLevel[levelId] = hydrated;
      notifyListeners();
    } catch (e) {
      // Silently catch API errors - user already has cached data on screen
      debugPrint('Error fetching lessons from API in background: $e');
    }
  }

  Future<void> fetchWordsForLesson(int lessonId) async {
    try {
      // OFFLINE-FIRST: Load cached words immediately
      await _loadWordsFromCache(lessonId);

      // BACKGROUND FETCH: Try to fetch fresh data from API
      _fetchWordsFromApiInBackground(lessonId);
    } catch (e) {
      debugPrint('Error fetching words for lesson: $e');
    }
  }

  /// Load words from local SQLite cache for a lesson
  Future<void> _loadWordsFromCache(int lessonId) async {
    try {
      final cachedWords = await _dbHelper.getCachedWords(lessonId);
      if (cachedWords.isEmpty) {
        return; // No cache available
      }

      final words = cachedWords.map((wordData) {
        return LearningWord(
          id: (wordData['id'] as int?) ?? 0,
          lessonId: lessonId,
          nativeText: (wordData['native_text'] as String?) ?? '',
          targetText: (wordData['target_text'] as String?) ?? '',
          imageUrl: (wordData['image_url'] as String?)?.isEmpty == true ? null : wordData['image_url'],
        );
      }).toList();

      _wordsByLesson[lessonId] = words;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading words from cache: $e');
    }
  }

  /// Fetch fresh words from API in background and update cache
  Future<void> _fetchWordsFromApiInBackground(int lessonId) async {
    try {
      final apiWords = await _repository.fetchWordsForLesson(lessonId);

      // Cache the words
      final wordsForDb = apiWords
          .map((word) => {
                'id': word.id,
                'lesson_id': lessonId,
                'native_text': word.nativeText,
                'target_text': word.targetText,
                'image_url': word.imageUrl ?? '',
                'audio_url': '',
                'category': 'general',
                'example': '',
              })
          .toList();
      await _dbHelper.upsertWords(wordsForDb);

      // Update state with fresh data
      _wordsByLesson[lessonId] = apiWords;
      notifyListeners();
    } catch (e) {
      // Silently catch API errors - user already has cached data on screen
      debugPrint('Error fetching words from API in background: $e');
    }
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
