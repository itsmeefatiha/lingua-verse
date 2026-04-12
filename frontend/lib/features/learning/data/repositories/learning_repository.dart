import '../../../../core/network/api_client.dart';
import '../models/catalog_models.dart';
import '../models/quiz_models.dart';

class LearningRepository {
  LearningRepository(this._apiClient);

  final ApiClient _apiClient;

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

  Future<List<QuizQuestionModel>> generateQuiz({String? levelCode, int count = 10}) async {
    final response = await _apiClient.postList(
      '/quiz/generate',
      body: {
        if (levelCode != null && levelCode.isNotEmpty) 'level_code': levelCode,
        'question_count': count,
      },
    );

    return response
        .map((entry) => QuizQuestionModel.fromApi(entry as Map<String, dynamic>))
        .toList();
  }

  Future<QuizSubmitResponseModel> submitQuiz({
    String? levelCode,
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
        'duration_seconds': durationSeconds,
        'answers': apiAnswers,
      },
    );

    return QuizSubmitResponseModel.fromApi(data);
  }
}
