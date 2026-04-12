import '../../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<String> login({required String email, required String password}) async {
    final data = await _apiClient.postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return data['access_token'] as String;
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _apiClient.postJson(
      '/auth/register',
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
      },
    );
  }

  Future<void> verifyAccount({
    required String email,
    required String otpCode,
  }) async {
    await _apiClient.postJson(
      '/auth/verify-account',
      body: {
        'email': email,
        'otp_code': otpCode,
      },
    );
  }

  Future<UserProfileModel> getMe() async {
    final data = await _apiClient.getJson('/users/me');
    return UserProfileModel.fromJson(data);
  }

  Future<UserProfileModel> updateMe({
    required String fullName,
    required String avatarUrl,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final data = await _apiClient.patchJson(
      '/users/me',
      body: {
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      },
    );
    return UserProfileModel.fromJson(data);
  }

  Future<void> forgotPassword({required String email}) async {
    await _apiClient.postJson(
      '/auth/forgot-password',
      body: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await _apiClient.postJson(
      '/auth/reset-password',
      body: {
        'email': email,
        'otp_code': otpCode,
        'new_password': newPassword,
      },
    );
  }
}
