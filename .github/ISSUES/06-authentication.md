---
title: "Feature: User authentication — login, register, and session management linked to backend"
labels: ["feature", "help wanted", "backend integration", "advanced"]
---

## Summary

Add a full authentication flow — email/password registration, OTP verification, login, Google/Facebook OAuth, and persistent session management — connected to the EOTCbibleBE backend. Once authenticated, the app can sync reading plans, notes, highlights, streaks, and user settings across devices.

## Backend API

Base URL: `https://github.com/EOTCOpenSource/EOTCbibleBE` (see `/api-docs` for Swagger spec)

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/v1/auth/register` | Create account (triggers OTP email) |
| `POST` | `/api/v1/auth/verify-otp` | Verify 6-digit OTP → returns JWT |
| `POST` | `/api/v1/auth/login` | Email + password login → returns JWT |
| `POST` | `/api/v1/auth/social/google` | Google OAuth → returns JWT |
| `POST` | `/api/v1/auth/social/facebook` | Facebook OAuth → returns JWT |
| `POST` | `/api/v1/auth/forgot-password` | Send password reset email |
| `POST` | `/api/v1/auth/reset-password` | Reset via token |
| `GET` | `/api/v1/auth/profile` | Fetch profile (protected) |
| `PUT` | `/api/v1/auth/profile` | Update name/avatar (protected) |
| `POST` | `/api/v1/auth/logout` | Invalidate JWT on server (protected) |

### Security notes from the backend
- Account is locked for 2 hours after 5 failed login attempts
- OTP expires — handle the "OTP expired, resend?" case in the UI
- JWT must be sent as `Authorization: Bearer <token>`

## What needs to be built

### 1 — Secure token storage

Add `flutter_secure_storage`:

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

Create `lib/core/auth/auth_storage.dart`:

```dart
class AuthStorage {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> clearToken();
}
```

### 2 — Auth repository

Create `lib/core/auth/auth_repository.dart`:

```dart
class AuthRepository {
  Future<String> login(String email, String password);     // returns JWT
  Future<void> register(String name, String email, String password);
  Future<String> verifyOtp(String email, String otp);     // returns JWT
  Future<void> logout();
  Future<UserProfile> fetchProfile();
  Future<String> signInWithGoogle();                      // returns JWT
}
```

### 3 — Auth state provider

```dart
// Riverpod — single source of truth for auth state across the app
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
}
```

On app startup, `AuthNotifier` reads the stored token. If one exists, it calls `GET /profile` to validate it — if the server returns 401 the token is stale and the user is signed out.

### 4 — Login screen

Create `lib/features/auth/presentation/pages/login_screen.dart`:

- Email + password fields
- **Login** button → `POST /login`
- **Forgot password** link → `POST /forgot-password` then show a confirmation
- **Register** link → navigate to register screen
- **Continue with Google** button → Google Sign-In → `POST /social/google`
- Show a clear error for locked accounts: "Too many failed attempts. Try again in 2 hours."

### 5 — Register + OTP screens

`register_screen.dart` — name, email, password → `POST /register`

`otp_screen.dart` — six-digit input → `POST /verify-otp`. Include a **Resend OTP** button (re-calls `/register` with the same email).

### 6 — Profile screen

Create `lib/features/auth/presentation/pages/profile_screen.dart` accessible from the Me tab:
- Display avatar, name, email
- Edit name / upload avatar (`PUT /profile`, `POST /avatar`)
- **Log out** → `POST /logout` → clear stored token → navigate to login

### 7 — Auth guard

Any feature that requires auth (reading plans, cross-device sync) checks `authStateProvider.status`. If `unauthenticated`, show an inline prompt:

```
"Log in to sync your reading plans across devices"
[Log in]  [Continue without account]
```

Do not force login — the app must remain fully usable offline and without an account.

### 8 — Settings sync (stretch goal)

The backend `User.settings` object stores `theme`, `fontSize`, and `notificationsEnabled`. After login, pull these and merge them with the local `AppSettings` (local takes precedence for conflicts). On settings change, `PUT /profile` to persist.

### 9 — Streak sync (stretch goal)

The backend tracks `streak.current` and `streak.longest` per user. After login, compare with the local streak from `readingStreakStateProvider` and use whichever is higher (never regress the count).

## Screen flow

```
App start
  ├─ Token exists → GET /profile
  │     ├─ 200 → authenticated, show home
  │     └─ 401 → clear token, show home (unauthenticated)
  └─ No token → show home (unauthenticated)

Me tab → "Log in" button
  └─ Login screen
       ├─ Email/password → POST /login → home
       ├─ Google → OAuth flow → POST /social/google → home
       └─ Register → Register screen → OTP screen → home
```

## Folder structure

```
lib/
  core/
    auth/
      auth_repository.dart
      auth_storage.dart
      auth_state.dart         # AuthNotifier + AuthState
  features/
    auth/
      presentation/
        pages/
          login_screen.dart
          register_screen.dart
          otp_screen.dart
          profile_screen.dart
```

## Dependencies to add

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  google_sign_in: ^6.0.0       # for Google OAuth
  http: ^1.2.0                  # or dio if preferred
```

## Relevant files

| File | Role |
|---|---|
| `lib/features/me/` | Me tab — add Login / Profile entry point |
| `lib/main.dart` | Bootstrap auth state check on startup |
| `lib/features/home/presentation/widgets/reading_plans_section.dart` | Show auth prompt when unauthenticated |
| `lib/core/api/api_client.dart` | (from issue #01) Attach JWT to all API requests |

## Notes

- **Do not gate core features behind login** — reading, search, bookmarks, highlights, notes must all work without an account
- Facebook OAuth requires a Facebook Developer app approval; implement Google first and treat Facebook as a follow-up
- Store only the JWT — never store the raw password
- The backend locks accounts after 5 failed attempts; surface this as a human-readable error, not a generic "invalid credentials"
