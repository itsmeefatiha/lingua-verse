import '../../../../core/network/api_client.dart';
import '../models/catalog_models.dart';
import '../models/learning_engine_models.dart';
import '../models/quiz_models.dart';

class LearningRepository {
  LearningRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LearningLanguage>> fetchLanguages() async {
    try {
      final raw = await _apiClient.getList('/content/languages');
      return raw
          .map((entry) => LearningLanguage.fromApi(entry as Map<String, dynamic>))
          .where((language) => language.code.isNotEmpty)
          .toList();
    } catch (_) {
      final me = await _apiClient.getJson('/users/me');
      final codes = <String>{};
      final source = (me['source_language'] as String? ?? '').trim().toLowerCase();
      final target = (me['target_language'] as String? ?? '').trim().toLowerCase();
      if (source.isNotEmpty) {
        codes.add(source);
      }
      if (target.isNotEmpty) {
        codes.add(target);
      }
      if (codes.isEmpty) {
        codes.addAll(const ['en', 'fr', 'es']);
      }
      final list = codes.toList()..sort();
      return List<LearningLanguage>.generate(
        list.length,
        (index) => LearningLanguage.fromApi(
          {
            'id': index + 1,
            'code': list[index],
            'name': '',
          },
        ),
      );
    }
  }

  Future<List<LearningLevel>> fetchLevelsForLanguage(
    String languageCode, {
    required int languageId,
  }) async {
    final normalizedCode = languageCode.trim().toLowerCase();
    List<dynamic> raw;

    try {
      raw = await _apiClient.getList('/content/languages/$normalizedCode/levels');
    } catch (_) {
      raw = await _apiClient.getList('/content/levels');
    }

    final levels = raw
        .map(
          (entry) => LearningLevel.fromApi(
            entry as Map<String, dynamic>,
            fallbackLanguageId: languageId,
          ),
        )
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return levels;
  }

  Future<List<LearningLesson>> fetchLessonsForLevel({
    required int levelId,
    required String levelName,
    String? languageCode,
  }) async {
    final encodedLanguage = languageCode?.trim().toLowerCase();
    final path = encodedLanguage == null || encodedLanguage.isEmpty
        ? '/content/levels/id/$levelId/lessons'
        : '/content/levels/${levelName.toUpperCase()}/lessons?language_code=$encodedLanguage';
    final raw = await _apiClient.getList(path);
    final lessons = raw
        .map((entry) => LearningLesson.fromApi(entry as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return lessons.map((lesson) => lesson.copyWith()).toList();
  }

  Future<List<LearningWord>> fetchWordsForLesson(int lessonId) async {
    final raw = await _apiClient.getList('/content/lessons/$lessonId/vocabulary');
    return raw
        .map((entry) => LearningWord.fromApi(entry as Map<String, dynamic>))
        .toList();
  }

  Future<Map<int, bool>> fetchLessonCompletionMap() async {
    try {
      final data = await _apiClient.getJson('/progress/me');
      final lessons = (data['lessons'] as List<dynamic>? ?? const []);
      final result = <int, bool>{};

      for (final item in lessons) {
        final map = item as Map<String, dynamic>;
        final lessonId = (map['lesson_id'] as num?)?.toInt();
        if (lessonId == null) {
          continue;
        }
        final status = (map['status'] as String? ?? '').toLowerCase();
        final quizCompleted = map['quiz_completed'] as bool? ?? false;
        final vocabCompleted = map['vocab_completed'] as bool? ?? false;
        final progressPercent = (map['progress_percent'] as num?)?.toDouble() ?? 0;
        result[lessonId] =
            status == 'completed' || quizCompleted || vocabCompleted || progressPercent >= 100;
      }

      return result;
    } catch (_) {
      return <int, bool>{};
    }
  }

  Future<Set<String>> fetchPassedLevelCodes() async {
    try {
      final attempts = await _apiClient.getList('/quiz/attempts/me');
      final passed = <String>{};

      for (final item in attempts) {
        final map = item as Map<String, dynamic>;
        final score = (map['score'] as num?)?.toInt() ?? 0;
        final levelCode = (map['level_code'] as String? ?? '').trim().toUpperCase();
        if (score >= 80 && levelCode.isNotEmpty) {
          passed.add(levelCode);
        }
      }

      return passed;
    } catch (_) {
      return <String>{};
    }
  }

  Future<List<QuizAttemptModel>> fetchMyQuizAttempts() async {
    try {
      final attempts = await _apiClient.getList('/quiz/attempts/me');
      return attempts
          .map((entry) => QuizAttemptModel.fromApi(entry as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    } catch (_) {
      return <QuizAttemptModel>[];
    }
  }

  Future<void> markLessonComplete({required int lessonId}) async {
    final words = await fetchWordsForLesson(lessonId);
    for (final word in words) {
      await _apiClient.postJson('/progress/vocabularies/${word.id}/view');
    }
  }

  Future<QuizSubmitResponseModel> submitLevelQuiz({
    required String levelCode,
    required String languageCode,
    required int durationSeconds,
    required Map<int, String> answers,
  }) {
    return submitQuiz(
      levelCode: levelCode.toUpperCase(),
      languageCode: languageCode,
      durationSeconds: durationSeconds,
      answers: answers,
    );
  }

  Future<List<LevelModel>> getRoadmap() async {
    final levelsRaw = await _apiClient.getList('/content/levels');
    final levels = levelsRaw
        .map((entry) => LevelModel.fromApi(entry as Map<String, dynamic>))
        .toList();

    final withLessons = <LevelModel>[];
    for (final level in levels) {
      final lessonsRaw = await _apiClient.getList('/content/levels/${level.code}/lessons');
      final lessons = <LessonModel>[];
      for (final lessonData in lessonsRaw) {
        final lesson = LessonModel.fromApi(lessonData as Map<String, dynamic>, level.code);
        final vocabRaw = await _apiClient.getList('/content/lessons/${lesson.id}/vocabulary');
        final vocab = vocabRaw
            .map((item) => VocabularyModel.fromApi(item as Map<String, dynamic>))
            .toList();
        lessons.add(lesson.copyWith(vocabularies: vocab));
      }
      withLessons.add(level.copyWith(lessons: lessons));
    }

    return withLessons;
  }

  Future<List<QuizQuestionModel>> generateQuiz({String? levelCode, String? languageCode, int count = 10}) async {
    final response = await _apiClient.postList(
      '/quiz/generate',
      body: {
        if (levelCode != null && levelCode.isNotEmpty) 'level_code': levelCode,
        if (languageCode != null && languageCode.isNotEmpty) 'language_code': languageCode,
        'question_count': count,
      },
    );

    return response
        .map((entry) => QuizQuestionModel.fromApi(entry as Map<String, dynamic>))
        .toList();
  }

  Future<QuizSubmitResponseModel> submitQuiz({
    String? levelCode,
    String? languageCode,
    required int durationSeconds,
    required Map<int, String> answers,
  }) async {
    final apiAnswers = answers.entries
        .map(
          (entry) => {
            'question_id': entry.key,
            'answer': entry.value,
          },
        )
        .toList();

    final data = await _apiClient.postJson(
      '/quiz/attempts/submit',
      body: {
        if (levelCode != null && levelCode.isNotEmpty) 'level_code': levelCode,
        if (languageCode != null && languageCode.isNotEmpty) 'language_code': languageCode,
        'duration_seconds': durationSeconds,
        'answers': apiAnswers,
      },
    );

    return QuizSubmitResponseModel.fromApi(data);
  }
}
