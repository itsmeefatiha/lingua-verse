import '../../../../core/network/api_client.dart';
import '../../../learning/data/models/learning_engine_models.dart';
import '../models/admin_dashboard_stats_model.dart';
import '../models/admin_user_model.dart';

class AdminRepository {
  AdminRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminDashboardStatsModel> getDashboardStats() async {
    final data = await _apiClient.getJson('/users/admin/dashboard/stats');
    return AdminDashboardStatsModel.fromJson(data);
  }

  Future<List<AdminUserModel>> listUsers({String? search}) async {
    final query = search != null && search.trim().isNotEmpty ? '?search=${Uri.encodeComponent(search.trim())}' : '';
    final data = await _apiClient.getList('/users/admin/users$query');
    return data
        .map((item) => AdminUserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteUser(int userId) async {
    await _apiClient.deleteJson('/users/admin/users/$userId');
  }

  Future<List<LearningLanguage>> fetchLanguages() async {
    final data = await _apiClient.getList('/content/languages');
    return data.map((item) => LearningLanguage.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<List<LearningLevel>> fetchLevelsForLanguage(String languageCode, {required int languageId}) async {
    final data = await _apiClient.getList('/content/languages/${languageCode.toLowerCase()}/levels');
    return data
        .map((item) => LearningLevel.fromApi(item as Map<String, dynamic>, fallbackLanguageId: languageId))
        .toList();
  }

  Future<List<LearningLesson>> fetchLessonsForLevel({
    required int levelId,
    required String levelName,
    String? languageCode,
  }) async {
    final path = languageCode != null && languageCode.trim().isNotEmpty
        ? '/content/levels/${levelName.toUpperCase()}/lessons?language_code=${languageCode.toLowerCase()}'
        : '/content/levels/id/$levelId/lessons';
    final data = await _apiClient.getList(path);
    return data.map((item) => LearningLesson.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<List<LearningWord>> fetchWordsForLesson(int lessonId) async {
    final data = await _apiClient.getList('/content/lessons/$lessonId/vocabulary');
    return data.map((item) => LearningWord.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<void> createLevel({
    required int languageId,
    required String levelCode,
    required int displayOrder,
  }) async {
    await _apiClient.postJson(
      '/content/levels',
      body: {
        'language_id': languageId,
        'code': levelCode.toUpperCase(),
        'display_order': displayOrder,
      },
    );
  }

  Future<void> createLesson({
    required int levelId,
    required String title,
    String? description,
    required int displayOrder,
  }) async {
    await _apiClient.postJson(
      '/content/lessons',
      body: {
        'level_id': levelId,
        'title': title,
        'description': (description ?? '').trim().isEmpty ? null : description,
        'display_order': displayOrder,
      },
    );
  }

  Future<void> createWord({
    required int lessonId,
    required String term,
    required String translation,
    String? category,
    String? example,
  }) async {
    await _apiClient.postJson(
      '/content/lessons/$lessonId/vocabulary',
      body: {
        'term': term,
        'translation': translation,
        'category': (category ?? '').trim().isEmpty ? null : category,
        'example': (example ?? '').trim().isEmpty ? null : example,
      },
    );
  }
}
