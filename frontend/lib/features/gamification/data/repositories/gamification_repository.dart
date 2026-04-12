import '../../../../core/network/api_client.dart';
import '../models/leaderboard_models.dart';

class GamificationRepository {
  GamificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LeaderboardEntryModel>> getLeaderboard() async {
    final data = await _apiClient.getList('/leaderboard');
    return data
        .map((entry) => LeaderboardEntryModel.fromApi(entry as Map<String, dynamic>))
        .toList();
  }
}
