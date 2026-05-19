import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_client.dart';
import 'user_profile.dart';

const _webClientId =
    '633243120991-53mhcrmdns9ngi06hj2f1gj5ja7t6n1p.apps.googleusercontent.com';

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

  // ── Social auth ───────────────────────────────────────────────────────────

  Future<String> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(serverClientId: _webClientId);
    final account = await googleSignIn.signIn();
    if (account == null) throw const ApiException('Google sign-in cancelled');

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw const ApiException('Failed to get Google ID token');
    }

    final res = await _api.post('/auth/social/google', body: {'idToken': idToken});
    return res['data']['token'] as String;
  }
}
