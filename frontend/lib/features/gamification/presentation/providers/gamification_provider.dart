import 'package:flutter/foundation.dart';

import '../../data/models/leaderboard_models.dart';
import '../../data/repositories/gamification_repository.dart';

class GamificationProvider extends ChangeNotifier {
  GamificationProvider(this._repository);

  final GamificationRepository _repository;

  List<LeaderboardEntryModel> _entries = const [];
  bool _isLoading = false;
  String? _error;

  List<LeaderboardEntryModel> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLeaderboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _repository.getLeaderboard();
    } catch (e) {
      _error = e.toString();
      _entries = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _entries = const [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
