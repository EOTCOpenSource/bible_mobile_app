import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../settings/app_settings.dart';
import '../settings/settings_provider.dart';
import '../storage/app_database_provider.dart';
import '../sync/sync_repository.dart';
import '../sync/sync_service.dart';
import '../../features/books/data/reading_models.dart';
import '../../features/books/providers/reading_progress_providers.dart';
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

  VoidCallback? _settingsListener;
  AppSettings? _lastPushedSettings;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stopSettingsPush();
    super.dispose();
  }

  // ── Auth flow ─────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final token = await _storage.readToken();
    if (token == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final profile = await _repo.fetchProfile(token);
      state = AuthState.authenticated(profile, token);
      _syncAfterAuth(token, profile);
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
    _syncAfterAuth(token, profile);
  }

  Future<void> register(String name, String email, String password) async {
    await _repo.register(name, email, password);
  }

  Future<void> verifyOtp(String email, String otp) async {
    final token = await _repo.verifyOtp(email, otp);
    await _storage.saveToken(token);
    final profile = await _repo.fetchProfile(token);
    state = AuthState.authenticated(profile, token);
    _syncAfterAuth(token, profile);
  }

  Future<void> signInWithGoogle() async {
    final (token, photoUrl) = await _repo.signInWithGoogle();
    await _storage.saveToken(token);
    var profile = await _repo.fetchProfile(token);
    if (profile.avatar == null && photoUrl != null) {
      profile = profile.copyWith(avatar: photoUrl);
    }
    state = AuthState.authenticated(profile, token);
    _syncAfterAuth(token, profile);
  }

  void _syncAfterAuth(String token, UserProfile profile) {
    _applyRemoteSettings(profile);
    _applyRemoteStreak(profile);
    _startSettingsPush(token);
    final svc = SyncService(
      db: _ref.read(appDatabaseProvider),
      repo: SyncRepository(_ref.read(apiClientProvider), token),
    );
    svc.pullAll().then((_) => svc.syncAll());
  }

  Future<void> logout() async {
    final token = state.token;
    _stopSettingsPush();
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
    _stopSettingsPush();
    if (token != null) await _repo.deleteAccount(token);
    await _storage.clearToken();
    state = const AuthState.unauthenticated();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final token = state.token;
    if (token == null) return;
    final updated = await _repo.updateProfile(token, name: name, email: email);
    state = AuthState.authenticated(updated, token);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = state.token;
    if (token == null) return;
    await _repo.changePassword(token,
        currentPassword: currentPassword, newPassword: newPassword);
  }

  Future<void> uploadAvatar(File file) async {
    final token = state.token;
    if (token == null) return;
    final updated = await _repo.uploadAvatar(token, file);
    final withAvatar = updated.avatar != null
        ? updated
        : state.user!.copyWith(avatar: null);
    state = AuthState.authenticated(withAvatar, token);
  }

  // ── Settings sync (#8) ────────────────────────────────────────────────────────

  /// On login, apply remote settings for any field still at its default value.
  /// Local changes take precedence — we never overwrite a user's explicit choice.
  void _applyRemoteSettings(UserProfile profile) {
    final remote = profile.remoteSettings;
    if (remote == null) return;
    final notifier = _ref.read(settingsNotifierProvider);
    final local = notifier.value;
    const defaults = AppSettings();

    final merged = local.copyWith(
      isDarkReader: local.isDarkReader == defaults.isDarkReader
          ? remote.isDark
          : local.isDarkReader,
      fontSize: local.fontSize == defaults.fontSize
          ? remote.fontSize
          : local.fontSize,
    );

    if (merged == local) return;
    _lastPushedSettings = merged; // prevent immediate push-back
    notifier.value = merged;
  }

  /// Listen for settings changes and push them to the backend (fire-and-forget).
  void _startSettingsPush(String token) {
    _stopSettingsPush();
    final notifier = _ref.read(settingsNotifierProvider);
    _settingsListener = () {
      final current = notifier.value;
      if (current == _lastPushedSettings) return;
      _lastPushedSettings = current;
      _repo
          .updateProfileSettings(token, settings: current)
          .catchError((_) {});
    };
    notifier.addListener(_settingsListener!);
  }

  void _stopSettingsPush() {
    if (_settingsListener == null) return;
    try {
      _ref.read(settingsNotifierProvider).removeListener(_settingsListener!);
    } catch (_) {}
    _settingsListener = null;
  }

  // ── Streak sync (#9) ─────────────────────────────────────────────────────────

  /// After login, keep whichever streak value is higher — local or backend.
  void _applyRemoteStreak(UserProfile profile) {
    final remote = profile.remoteStreak;
    if (remote == null || (remote.current == 0 && remote.longest == 0)) return;
    _mergeStreak(remote);
  }

  Future<void> _mergeStreak(RemoteStreak remote) async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final row = await db.getReadingStreakRow();
      final local = ReadingStreakState.fromRow(row);

      final mergedCurrent =
          remote.current > local.currentStreak ? remote.current : local.currentStreak;
      final mergedLongest =
          remote.longest > local.longestStreak ? remote.longest : local.longestStreak;

      if (mergedCurrent == local.currentStreak &&
          mergedLongest == local.longestStreak) {
        return;
      }

      await db.updateReadingStreakRow(
        lastQualifiedDate: local.lastQualifiedDate,
        currentStreak: mergedCurrent,
        currentStreakStart: local.currentStreakStart,
        longestStreak: mergedLongest,
        longestStreakStart: local.longestStreakStart,
        longestStreakEnd: local.longestStreakEnd,
        // Freezes are earned on this device and the server does not track
        // them, so a merge must carry the local balance rather than zero it.
        freezeCredits: local.freezeCredits,
      );

      _ref.invalidate(readingStreakStateProvider);
    } catch (_) {}
  }
}
