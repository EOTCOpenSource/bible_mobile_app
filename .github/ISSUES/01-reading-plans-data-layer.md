---
title: "Feature: Reading Plans — fetch from backend API and track progress"
labels: ["feature", "help wanted", "backend integration"]
---

## Summary

The Reading Plans section on the home screen (`lib/features/home/presentation/widgets/reading_plans_section.dart`) currently renders three hardcoded cards with fake progress. Plans should be fetched from the backend API and progress tracked there — no local plan definitions needed.

> **Depends on:** Issue #06 (User Authentication) — reading plan endpoints are all protected and require a JWT Bearer token.

## Backend API

Base URL: `https://github.com/EOTCOpenSource/EOTCbibleBE` (see its `/api-docs` for the full Swagger spec)

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/api/v1/reading-plans/` | List the authenticated user's plans |
| `POST` | `/api/v1/reading-plans/` | Create a new plan |
| `GET` | `/api/v1/reading-plans/:id` | Get a specific plan |
| `GET` | `/api/v1/reading-plans/:id/progress` | Get completion percentage |
| `PATCH` | `/api/v1/reading-plans/:id/days/:dayNumber/complete` | Mark a day as read |
| `PUT` | `/api/v1/reading-plans/:id` | Update a plan |
| `DELETE` | `/api/v1/reading-plans/:id` | Delete a plan |

### Plan response shape (abbreviated)

```json
{
  "id": "...",
  "name": "Genesis 30-day plan",
  "startBook": "Genesis",
  "startChapter": 1,
  "endBook": "Genesis",
  "endChapter": 50,
  "durationInDays": 30,
  "startDate": "2024-01-01T00:00:00Z",
  "status": "active",
  "dailyReadings": [
    {
      "dayNumber": 1,
      "date": "2024-01-01T00:00:00Z",
      "readings": [{ "book": "Genesis", "chapter": 1 }],
      "isCompleted": true,
      "completedAt": "2024-01-01T20:00:00Z"
    }
  ]
}
```

## What needs to be built

### 1 — HTTP client / API layer

Create `lib/core/api/api_client.dart` — a thin wrapper around `http` or `dio` that:
- Attaches the JWT `Authorization: Bearer <token>` header to every request
- Reads the token from `flutter_secure_storage` (same store used by the auth feature)
- Handles 401 responses by clearing the token and redirecting to the login screen

```dart
class ApiClient {
  Future<dynamic> get(String path);
  Future<dynamic> post(String path, Map<String, dynamic> body);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]);
  Future<dynamic> delete(String path);
}
```

### 2 — Reading plans repository

Create `lib/features/home/data/reading_plans_repository.dart`:

```dart
class ReadingPlansRepository {
  Future<List<ReadingPlan>> fetchPlans();
  Future<ReadingPlan> fetchPlan(String id);
  Future<PlanProgress> fetchProgress(String id);
  Future<void> completeDay(String planId, int dayNumber);
}
```

### 3 — Data model

```dart
class ReadingPlan {
  final String id;
  final String name;
  final String startBook;
  final String endBook;
  final int durationInDays;
  final String status; // 'active' | 'completed' | 'paused'
  final List<PlanDay> dailyReadings;
}

class PlanDay {
  final int dayNumber;
  final DateTime date;
  final List<PlanReading> readings; // book + chapter
  final bool isCompleted;
}

class PlanReading {
  final String bookNameEn; // matches BookIndexEntry.bookNameEn
  final int chapter;
}
```

### 4 — Riverpod providers

```dart
// Fetch all plans for the current user
final readingPlansProvider = FutureProvider<List<ReadingPlan>>(...);

// Today's reading for a specific plan
final todaysPlanReadingProvider = Provider.family<PlanDay?, String>(...);
```

### 5 — Home screen wire-up

Replace the hardcoded `_PlanData` list in `ReadingPlansSection` with `ref.watch(readingPlansProvider)`. Show a loading skeleton while fetching. Show an empty state with a "Start a plan" CTA if the list is empty.

### 6 — Mark day as complete

When the user finishes reading a chapter that belongs to today's plan reading, call `PATCH /:id/days/:dayNumber/complete`. This can be triggered from a banner shown in the reader when the current chapter matches a plan reading.

### 7 — View All screen

Create `lib/features/home/presentation/pages/reading_plans_screen.dart` listing all plans with their status and progress. Wire the **View All** `onTap` in `ReadingPlansSection`. Allow creating a new plan (opening a form that POSTs to the API).

## Relevant files

| File | Role |
|---|---|
| `lib/features/home/presentation/widgets/reading_plans_section.dart` | Replace hardcoded data with API data |
| `lib/core/api/api_client.dart` | New — shared HTTP client |
| `lib/features/home/data/reading_plans_repository.dart` | New — API calls |
| `lib/features/books/presentation/pages/reader_screen.dart` | Show "mark as complete" banner when chapter matches plan |

## Notes

- All endpoints require auth — do not attempt to fetch plans when the user is logged out; show a "Log in to use Reading Plans" prompt instead
- `bookNameEn` in the API response maps directly to `BookIndexEntry.bookNameEn` in the local index — use `BibleRepository.loadIndex()` to resolve chapter navigation targets
- The API `dailyReadings[].readings` is an array — a single day may cover multiple chapters
