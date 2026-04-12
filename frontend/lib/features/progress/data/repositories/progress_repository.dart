import '../../../../core/network/api_client.dart';
import '../models/analytics_models.dart';

class ProgressRepository {
  ProgressRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ProgressOverviewModel> getProgressOverview() async {
    final data = await _apiClient.getJson('/progress/me');
    return ProgressOverviewModel.fromApi(data);
  }

  Future<AnalyticsDashboardModel> getAnalyticsDashboard() async {
    final data = await _apiClient.getJson('/analytics/dashboard');
    return AnalyticsDashboardModel.fromApi(data);
  }

  Future<List<int>> downloadProgressReportPdf() {
    return _apiClient.getBytes('/analytics/report/progression.pdf');
  }
}
