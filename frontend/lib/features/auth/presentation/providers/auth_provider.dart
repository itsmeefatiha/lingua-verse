import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/session_store.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_profile_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, this._sessionStore);

  final AuthRepository _repository;
  final SessionStore _sessionStore;

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;
  String? _error;

  UserProfileModel? _user;

  bool get isAuthenticated => _sessionStore.isAuthenticated;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserProfileModel? get user => _user;
  bool get needsLanguageSelection {
    final current = _user;
    if (current == null) {
      return false;
    }
    return current.targetLanguage.trim().isEmpty;
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _repository.login(email: email, password: password);
      _sessionStore.setToken(token);
      _user = await _repository.getMe();
    } catch (e) {
      _error = e.toString();
      _sessionStore.clear();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyAccount({
    required String email,
    required String otpCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _repository.verifyAccount(
        email: email,
        otpCode: otpCode,
      );
      _sessionStore.setToken(token);
      _user = await _repository.getMe();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> socialLogin(String provider) async {
    if (provider.toLowerCase() != 'google') {
      _error = 'Provider non supporte: $provider';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final webClientId = AppConfig.googleWebClientId.trim();
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: webClientId.isEmpty ? null : webClientId,
      );

      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('Connexion Google annulee');
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('idToken Google indisponible');
      }

      final token = await _repository.loginWithGoogle(idToken: idToken);
      _sessionStore.setToken(token);
      _user = await _repository.getMe();
    } catch (e) {
      _error = e.toString();
      _sessionStore.clear();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _sessionStore.clear();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> refreshMe() async {
    if (!_sessionStore.isAuthenticated) {
      return;
    }
    try {
      _user = await _repository.getMe();
      notifyListeners();
    } catch (_) {
      // Ignore refresh failures to keep session usable.
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String avatarUrl,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _repository.updateMe(
        fullName: fullName,
        avatarUrl: avatarUrl,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserLanguages(String nativeLang, String targetLang) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_sessionStore.isAuthenticated && _user != null) {
        _user = await _repository.updateMe(
          fullName: _user!.fullName,
          avatarUrl: _user!.avatarUrl,
          sourceLanguage: nativeLang,
          targetLanguage: targetLang,
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _user =
            (_user ??
                    const UserProfileModel(
                      id: 0,
                      email: '',
                      fullName: '',
                      avatarUrl: '',
                      sourceLanguage: 'fr',
                      targetLanguage: 'en',
                      totalXp: 0,
                      level: 1,
                      streak: 0,
                      weeklyXp: 0,
                      currentLeague: 'bronze',
                      role: 'user',
                    ))
                .copyWith(
                  sourceLanguage: nativeLang,
                  targetLanguage: targetLang,
                );
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.forgotPassword(email: email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyForgotPasswordOtp({
    required String email,
    required String otpCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return otpCode.trim().length == 6;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.resetPassword(
        email: email,
        otpCode: otpCode,
        newPassword: newPassword,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
