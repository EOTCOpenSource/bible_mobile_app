import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_client.dart';
import '../settings/app_settings.dart';
import 'user_profile.dart';

const _webClientId =
    '633243120991-2fj8v1g9ree4dkgklqe7613sdm6e6idc.apps.googleusercontent.com';

class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  // ── Auth endpoints ────────────────────────────────────────────────────────

  Future<void> register(String name, String email, String password) async {
    await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<String> verifyOtp(String email, String otp) async {
    final res = await _api.post('/auth/verify-otp', body: {
      'email': email,
      'otp': otp,
    });
    return res['data']['token'] as String;
  }

  Future<void> resendOtp(String email) async {
    await _api.post('/auth/resend-otp', body: {'email': email});
  }

  Future<String> login(String email, String password) async {
    final res = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return res['data']['token'] as String;
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _api.post('/auth/reset-password', body: {
      'token': token,
      'newPassword': newPassword,
      'confirmPassword': newPassword,
    });
  }

  Future<UserProfile> fetchProfile(String token) async {
    final res = await _api.get('/auth/profile', token: token);
    return UserProfile.fromJson(res['data']['user'] as Map<String, dynamic>);
  }

  Future<void> logout(String token) async {
    await _api.post('/auth/logout', token: token);
  }

  Future<void> deleteAccount(String token) async {
    await _api.delete('/auth/account', token: token);
  }

  Future<void> updateProfileSettings(
    String token, {
    required AppSettings settings,
  }) =>
      _api.put('/auth/profile', body: {
        'settings': {
          'theme': settings.isDarkReader ? 'dark' : 'light',
          'fontSize': settings.fontSize.round(),
          'notificationsEnabled': true,
        },
      }, token: token);

  Future<UserProfile> updateProfile(
    String token, {
    required String name,
    required String email,
  }) async {
    final res = await _api.put(
      '/auth/profile',
      body: {'name': name, 'email': email},
      token: token,
    );
    return UserProfile.fromJson(res['data']['user'] as Map<String, dynamic>);
  }

  Future<void> changePassword(
    String token, {
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      token: token,
    );
  }

  Future<UserProfile> uploadAvatar(String token, File file) async {
    final res = await _api.uploadFile('/auth/avatar', file: file, token: token);
    return UserProfile.fromJson(res['data']['user'] as Map<String, dynamic>);
  }

  // ── Social auth ───────────────────────────────────────────────────────────

  Future<(String token, String? photoUrl)> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(serverClientId: _webClientId);
    await googleSignIn.signOut();
    final account = await googleSignIn.signIn();
    if (account == null) throw const ApiException('Google sign-in cancelled');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const ApiException('Failed to get Google ID token');
    }

    final res = await _api.post('/auth/social/google', body: {'idToken': idToken});
    return (res['data']['token'] as String, account.photoUrl);
  }
}
