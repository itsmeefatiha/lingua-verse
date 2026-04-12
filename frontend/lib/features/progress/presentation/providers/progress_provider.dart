import 'package:flutter/foundation.dart';

import '../../data/models/analytics_models.dart';
import '../../data/repositories/progress_repository.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._repository);

  final ProgressRepository _repository;

  ProgressOverviewModel? _overview;
  AnalyticsDashboardModel? _analytics;
  bool _isLoading = false;
  String? _error;

  ProgressOverviewModel? get overview => _overview;
  AnalyticsDashboardModel? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _overview = await _repository.getProgressOverview();
      _analytics = await _repository.getAnalyticsDashboard();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> downloadPdfReport() async {
    try {
      final bytes = await _repository.downloadProgressReportPdf();
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _overview = null;
    _analytics = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
