import 'package:flutter/foundation.dart';

import '../../data/models/admin_dashboard_stats_model.dart';
import '../../data/repositories/admin_repository.dart';

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider(this._repository);

  final AdminRepository _repository;

  AdminDashboardStatsModel? _stats;
  bool _isLoading = false;
  String? _error;

  AdminDashboardStatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repository.getDashboardStats();
    } catch (e) {
      _error = e.toString();
      _stats = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _stats = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
