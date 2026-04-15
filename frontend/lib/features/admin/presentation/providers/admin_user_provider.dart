import 'package:flutter/foundation.dart';

import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_repository.dart';

class AdminUserProvider extends ChangeNotifier {
  AdminUserProvider(this._repository);

  final AdminRepository _repository;

  List<AdminUserModel> _users = const [];
  bool _isLoading = false;
  String _search = '';
  String? _error;

  List<AdminUserModel> get users => _users;
  bool get isLoading => _isLoading;
  String get search => _search;
  String? get error => _error;

  Future<void> loadUsers({String? search}) async {
    _isLoading = true;
    _error = null;
    _search = search ?? _search;
    notifyListeners();

    try {
      _users = await _repository.listUsers(search: _search.isEmpty ? null : _search);
    } catch (e) {
      _error = e.toString();
      _users = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(int userId) async {
    await _repository.deleteUser(userId);
    await loadUsers();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }
}
