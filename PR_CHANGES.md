# PR #6 — User Authentication & Reading Plans

## Overview

Full authentication flow connected to the EOTCbibleBE backend, plus reading plans wired to real data with book-style UI, testament-based colours, and cross-device sync of settings and streaks.

---

## What was built

### 1. Auth foundation
- **`ApiClient`** (`lib/core/api/`) — HTTP wrapper with Bearer token support, `GET/POST/PUT/PATCH/DELETE`, file upload, and typed `ApiException` (including `isAccountLocked` for HTTP 423/429)
- **`AuthStorage`** (`lib/core/auth/`) — secure token persistence via `flutter_secure_storage`
- **`AuthRepository`** — all backend endpoints: register, verify-OTP, login, forgot/reset password, fetch/update profile, change password, upload avatar, logout, delete account, Google OAuth
- **`AuthState` / `AuthNotifier`** — Riverpod `StateNotifierProvider`; validates stored token on startup via `GET /profile`, clears on 401

### 2. Auth screens
| Screen | Notes |
|---|---|
| Login | Email/password, Google sign-in, forgot-password link, register link. Shows human-readable "Too many failed attempts" for locked accounts |
| Register | Name / email / password |
| OTP verification | 6-digit input + Resend button |
| Forgot password | Sends reset email, shows confirmation |
| Reset password | Token + new password |
| Profile | Avatar (upload/initials fallback), name/email edit, change password, logout, delete account |

All screens match the Figma design with full AM/EN localisation.

### 3. Me tab & home header
- Me tab shows login prompt when unauthenticated, switches to profile summary when logged in
- Home header avatar and greeting wired to `authStateProvider`

### 4. Backend sync (bookmarks, highlights, notes, progress)
- `SyncRepository` + `SyncService` handle push/pull for all annotation types
- Sync runs automatically after every login (`pullAll` then `syncAll`)
- Annotation models carry `remoteId` and `syncStatus` for conflict-free upserts

### 5. Reading plans
- **API**: `GET /reading-plans`, `PATCH /reading-plans/:id/days/:dayNumber/complete`
- **`ReadingPlanRepository`** + `readingPlansProvider` (auto-fetches when authenticated, returns `[]` otherwise)
- **Auth guard**: unauthenticated users see an inline "Log in to sync" prompt with dismiss option instead of the plan cards
- **Book-style cards**: each plan renders as an upright book cover (`BookCover` widget) with testament colour — burgundy (OT), navy (NT), olive (deuterocanonical)
- **View All screen** (`ReadingPlansScreen`): full scrollable list, same book cover + horizontal card layout matching Continue Reading
- **Tap to read**: tapping a card opens the reader at the first incomplete day; position is saved to a local `plan_position` SQLite table so subsequent taps resume from the same spot

### 6. Shared `BookCover` widget
`lib/core/widgets/book_cover.dart` — parameterised cover colour, size, and testament colour helper (`testamentColor(bookName)`). Replaces the inline implementation previously duplicated in `continue_reading_section.dart`.

### 7. Settings sync (stretch goal #8)
- `settingsNotifierProvider` (`lib/core/settings/settings_provider.dart`) — lifts `ValueNotifier<AppSettings>` into Riverpod so `AuthNotifier` can read/write it without a `BuildContext`
- On login: remote `theme`/`fontSize` are applied only for fields still at their default value (local always wins over remote for fields the user has explicitly changed)
- On every settings change: `PUT /auth/profile` is fired (fire-and-forget) to keep the backend in sync
- Listener is removed on logout / account deletion

### 8. Streak sync (stretch goal #9)
- `RemoteStreak` parsed from `GET /profile` response (`streak.current`, `streak.longest`)
- After login: each field is set to `max(local, remote)` — the streak never goes backwards
- `readingStreakStateProvider` is invalidated immediately so the home screen reflects the merged count

---

## New dependencies
```yaml
flutter_secure_storage: ^9.0.0
google_sign_in: ^6.0.0
http: ^1.2.0
sqflite_common_ffi: (already present — version bump)
```

---

## Database migrations
| Version | Change |
|---|---|
| v2 | Added `reading_position`, `chapter_read`, `reading_streak` tables |
| v3 | Migrated `reading_position` to per-book rows |
| v4 | Marked legacy kebab-case `book_id` annotations for re-sync |
| **v5** | Added `plan_position` table (`plan_id`, `day_number`, `book_id`, `chapter`) |

---

## What is intentionally deferred
- **Facebook OAuth** — button shows "Coming soon" snackbar. Requires registering Android/iOS platforms in the Facebook Developer Console and adding key hashes. The backend endpoint (`POST /auth/social/facebook`) is already implemented; only the Flutter-side native integration is pending.

---

## File map
```
lib/
  core/
    api/api_client.dart              — HTTP client + ApiException
    auth/
      auth_repository.dart           — all backend auth calls
      auth_state.dart                — AuthNotifier + settings/streak sync
      auth_storage.dart              — secure token storage
      user_profile.dart              — UserProfile + RemoteSettings + RemoteStreak
    settings/
      app_settings.dart              — Settings accepts external ValueNotifier
      settings_provider.dart         — settingsNotifierProvider (Riverpod)
    storage/app_database.dart        — v5 migration + plan_position methods
    sync/
      sync_repository.dart           — fetch/push bookmarks, highlights, notes
      sync_service.dart              — orchestrates pull + push
    widgets/book_cover.dart          — shared BookCover widget
  features/
    auth/presentation/pages/         — login, register, otp, forgot, reset, profile
    home/
      data/
        reading_plan.dart            — ReadingPlan + DailyReading + DailyReadingItem
        reading_plan_repository.dart — GET /reading-plans, PATCH day complete
      presentation/
        pages/reading_plans_screen.dart
        widgets/reading_plans_section.dart
      providers/reading_plan_providers.dart
    me/presentation/pages/me_screen.dart
```
