---
title: "Feature: Daily verse & reading time reminders — local push notifications"
labels: ["feature", "help wanted"]
---

## Summary

The Settings screen (`lib/features/me/`) has two reminder toggles — **Daily verse notification** and **Reading time reminder** — but they are purely visual. Toggling them does nothing. This issue wires them to real local notifications so users receive their chosen reminder at a scheduled time each day.

## Current state

Both settings are defined in `AppSettings` and rendered as toggle rows in the Me screen, but no scheduling code exists anywhere in the codebase:

```dart
// lib/core/settings/app_settings.dart (approximate)
final bool dailyVerseNotification;
final bool readingTimeNotification;
```

The toggles save the boolean to `Settings` (via `InheritedNotifier`) but nothing subscribes to the change to schedule or cancel a notification.

## What needs to be built

### 1 — Add `flutter_local_notifications`

```yaml
dependencies:
  flutter_local_notifications: ^18.0.0
```

### 2 — Notification service

Create `lib/core/notifications/notification_service.dart` with:

```dart
class NotificationService {
  Future<void> init();

  /// Schedule a daily notification at [time]. Cancels any previous one with the same [id].
  Future<void> scheduleDailyAt(int id, TimeOfDay time, String title, String body);

  Future<void> cancel(int id);
}
```

### 3 — Daily verse notification

- **ID:** `1`
- **Default time:** 6:00 AM (Ethiopian morning prayer time)
- **Title:** "የቀኑ ጥቅስ" / "Daily Verse"
- **Body:** today's verse reference from `BibleRepository.loadDailyVerse()` — at least book + chapter:verse; full text is optional (may be too long for a notification)
- Tapping the notification should open the app to the correct verse via the existing deep link: `eotcbible://openinapp/<slug>`

### 4 — Reading time reminder

- **ID:** `2`
- **Default time:** 8:00 PM
- **Title:** "ዛሬ ቃሉን ያንብቡ" / "Read today"
- **Body:** encouragement text; optionally show current streak count
- Tapping opens the app home screen

### 5 — Settings integration

When the user toggles either setting in the Me screen, call `NotificationService` to schedule or cancel the corresponding notification. If the user has not yet granted notification permission, request it at that point (not at app startup).

### 6 — Time picker (stretch goal)

Add a time picker row below each toggle so users can choose their preferred notification time instead of using the default. Persist the chosen time in `AppSettings`.

## Platform setup required

**Android** — add the `SCHEDULE_EXACT_ALARM` and `RECEIVE_BOOT_COMPLETED` permissions to `AndroidManifest.xml` as specified in the `flutter_local_notifications` docs.

**iOS** — request `UNUserNotificationCenter` authorization; handled by the plugin automatically on first schedule call.

## Relevant files

| File | Role |
|---|---|
| `lib/core/settings/app_settings.dart` | Add time fields for notification schedule |
| `lib/features/me/` | Settings UI — wire toggles to service |
| `lib/core/notifications/` | New — notification service |
| `android/app/src/main/AndroidManifest.xml` | Add alarm permissions |
| `lib/features/books/data/repositories/bible_repository.dart` | `loadDailyVerse()` for notification body |

## Notes

- Use exact alarms (`AndroidScheduleMode.exactAllowWhileIdle`) so the notification fires on time even in doze mode
- The app already uses `kenat` for Ethiopian calendar — use it to get today's month/day for `loadDailyVerse`
- Do not schedule notifications at startup if the toggles are off; only schedule when the user explicitly enables them
