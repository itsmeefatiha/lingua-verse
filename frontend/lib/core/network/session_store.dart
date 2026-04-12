import 'package:flutter/foundation.dart';

class SessionStore extends ChangeNotifier {
  String? _accessToken;

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  void setToken(String? token) {
    _accessToken = token;
    notifyListeners();
  }

  void clear() {
    _accessToken = null;
    notifyListeners();
  }
}
