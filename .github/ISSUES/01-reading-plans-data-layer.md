---
title: "Feature: Reading Plans — data layer, enrollment, and progress tracking"
labels: ["feature", "good first issue", "help wanted"]
---

## Summary

The Reading Plans section on the home screen (`lib/features/home/presentation/widgets/reading_plans_section.dart`) currently renders three hardcoded cards with fake progress. Nothing is stored, nothing is interactive, and the **View All** button does nothing.

This issue covers building the full reading plans feature end-to-end.

## Current state

```dart
// reading_plans_section.dart — hardcoded today, needs to be data-driven
static const _plans = [
  _PlanData(titleAm: 'መጽሐፈ ዘፍጥረት', totalDays: 30, completedDays: 12, ...),
  _PlanData(titleAm: 'ወንጌለ ዮሐንስ',  totalDays: 21, completedDays: 5,  ...),
  _PlanData(titleAm: 'መዝሙረ ዳዊት',   totalDays: 45, completedDays: 0,  ...),
];
```

The **View All** `onTap` is an empty closure. No plan data is persisted anywhere.

## What needs to be built

### 1 — Data model

Define a `ReadingPlan` and `UserPlanProgress` model. A plan is a named sequence of daily readings, each pointing to a book + chapter range. Example structure:

```dart
class ReadingPlan {
  final String id;           // e.g. "genesis-30"
  final String titleAm;
  final String titleEn;
  final List<PlanDay> days;  // ordered list of chapters to read per day
}

class PlanDay {
  final int dayNumber;
  final String bookNameEn;   // matches BookIndexEntry.bookNameEn
  final int chapterStart;
  final int chapterEnd;
}
```

### 2 — Built-in plan definitions

Provide at least three starter plans as static data (JSON under `assets/` or Dart constants):

- **Genesis** — 30 days covering the full book
- **Gospel of John** — 21 days covering the full book  
- **Psalms** — 45 days covering the full book

### 3 — Storage

Persist user enrollment and daily progress in SQLite (the project already uses `sqflite` via `lib/core/storage/app_database.dart`). Track:
- Which plans the user has enrolled in
- Which days they have completed
- The start date

### 4 — Riverpod providers

Add providers following the existing pattern in `lib/features/books/providers/reading_progress_providers.dart`:
- `enrolledPlansProvider` — list of plans the user has started
- `planProgressProvider(planId)` — completed days + percentage

### 5 — Home screen wire-up

Replace the hardcoded `_PlanData` list in `ReadingPlansSection` with the live providers. The progress bar should reflect real `completedDays / totalDays`.

### 6 — View All screen

Create `lib/features/home/presentation/pages/reading_plans_screen.dart` listing all available plans with enroll/continue actions. Wire the **View All** `onTap` to navigate to it.

### 7 — Daily plan card

When the user opens the app and has an active plan, show today's reading as a tappable card that opens `ReaderScreen` at the correct chapter.

## Relevant files

| File | Role |
|---|---|
| `lib/features/home/presentation/widgets/reading_plans_section.dart` | UI — replace hardcoded data |
| `lib/core/storage/app_database.dart` | Add plan enrollment + progress tables |
| `lib/features/books/providers/reading_progress_providers.dart` | Reference for provider pattern |
| `lib/features/books/presentation/pages/reader_screen.dart` | Navigation target for plan readings |
| `assets/` | Add plan definition JSON files here |

## Notes

- Follow the existing `InheritedWidget` + Riverpod split: global app state via `InheritedWidget`, feature state via Riverpod providers
- The `BibleRepository.loadIndex()` gives you `BookIndexEntry` objects to resolve book names
- Keep plan definitions in assets so the community can add new plans without touching Dart code
