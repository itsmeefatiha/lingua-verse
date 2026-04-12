import '../../../../core/network/api_client.dart';
import '../models/admin_dashboard_stats_model.dart';

class AdminRepository {
  AdminRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminDashboardStatsModel> getDashboardStats() async {
    final data = await _apiClient.getJson('/users/admin/dashboard/stats');
    return AdminDashboardStatsModel.fromJson(data);
  }
}
