import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../storage/app_database_provider.dart';
import '../sync/sync_repository.dart';
import '../sync/sync_service.dart';
import 'auth_repository.dart';
import 'auth_storage.dart';
import 'user_profile.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((_) => const ApiClient());

final authStorageProvider = Provider<AuthStorage>(
  (_) => const AuthStorage(FlutterSecureStorage()),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(authStorageProvider),
    ref,
  ),
);

// ── State ─────────────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState._({required this.status, this.user, this.token});

  const AuthState.unknown() : this._(status: AuthStatus.unknown);
  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);
  const AuthState.authenticated(UserProfile user, String token)
      : this._(status: AuthStatus.authenticated, user: user, token: token);

  final AuthStatus status;
  final UserProfile? user;
  final String? token;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnknown => status == AuthStatus.unknown;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._storage, this._ref)
      : super(const AuthState.unknown()) {
    _init();
  }

  final AuthRepository _repo;
  final AuthStorage _storage;
  final Ref _ref;

  Future<void> _init() async {
    final token = await _storage.readToken();
    if (token == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final profile = await _repo.fetchProfile(token);
      state = AuthState.authenticated(profile, token);
      _syncAfterAuth(token);
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _storage.clearToken();
      state = const AuthState.unauthenticated();
    } catch (_) {
      // Network error — keep token, go unauthenticated until next launch
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    final token = await _repo.login(email, password);
    await _storage.saveToken(token);
    final profile = await _repo.fetchProfile(token);
    state = AuthState.authenticated(profile, token);
    _syncAfterAuth(token);
  }

  Future<void> register(String name, String email, String password) async {
    await _repo.register(name, email, password);
  }

  Future<void> verifyOtp(String email, String otp) async {
    final token = await _repo.verifyOtp(email, otp);
    await _storage.saveToken(token);
    final profile = await _repo.fetchProfile(token);
    state = AuthState.authenticated(profile, token);
    _syncAfterAuth(token);
  }

  Future<void> signInWithGoogle() async {
    final token = await _repo.signInWithGoogle();
    await _storage.saveToken(token);
    final profile = await _repo.fetchProfile(token);
    state = AuthState.authenticated(profile, token);
    _syncAfterAuth(token);
  }

  void _syncAfterAuth(String token) {
    SyncService(
      db: _ref.read(appDatabaseProvider),
      repo: SyncRepository(_ref.read(apiClientProvider), token),
    ).syncAll();
  }

  Future<void> logout() async {
    final token = state.token;
    if (token != null) {
      try {
        await _repo.logout(token);
      } catch (_) {
        // Best-effort server logout — always clear locally
      }
    }
    await _storage.clearToken();
    state = const AuthState.unauthenticated();
  }

  Future<void> deleteAccount() async {
    final token = state.token;
    if (token != null) await _repo.deleteAccount(token);
    await _storage.clearToken();
    state = const AuthState.unauthenticated();
  }
}
