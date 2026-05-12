# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Build
flutter build apk
flutter build ios

# Analyze (lint)
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart
```

## Architecture

### State management — InheritedWidget only

The app uses no third-party state management. Three `InheritedWidget`/`InheritedNotifier` wrappers sit at the root of the widget tree (see `lib/main.dart`):

| Widget | Access pattern | Purpose |
|---|---|---|
| `BibleRepositoryProvider` | `BibleRepositoryProvider.of(context)` | Provides the singleton `BibleRepository` |
| `Settings` | `Settings.of(context)` / `Settings.update(context, ...)` | Global `AppSettings` (font, size, dark mode) |
| `L10n` | `L10n.of(context)` / `L10n.switchLanguage(...)` | AM/EN string switching |

`AppSettings` is an immutable value object — always mutate via `copyWith` and call `Settings.update`.

### Feature-first folder structure

```
lib/
  core/           # shared: theme, typography, widgets, l10n, settings, services
  features/
    books/        # Bible reading: data models, repository, reader screen
    home/         # Home tab: daily verse, continue reading, streaks (mostly stubs)
    me/           # Settings tab and reading settings page
```

### Bible data layer

- **Assets:** `assets/bibledata/` — 81 book JSON files named `{NN}-{bookname}.json` plus `index.json`
- **Load flow:** `BibleRepository.loadIndex()` → `List<BookIndexEntry>` → `BibleRepository.loadBook(entry)` → `Book`
- **Hierarchy:** `Book` → `Chapter` → `Section` (has a title) → `Verse`
- **Flattening:** `Chapter.allVerses` expands all sections into a flat verse list
- Both index and individual books are cached in memory after first load; the index is always available for book lookups by name or number

### Reader screen

`ReaderScreen` takes a `BookIndexEntry` and an optional `initialChapter` index. It manages:
- `PageView` for chapter-by-chapter swiping
- Verse selection via a string key `"chapterNum:sectionIdx:verseNum"`
- Font/size settings bottom sheet (`ReaderFontSheet`)
- `ChapterNavBar`, `ReaderToolbar`, `ReaderBreadcrumb` as separate widget files under `lib/features/books/presentation/widgets/reader/`

### Typography & fonts

`AppTypography` (`lib/core/theme/app_typography.dart`) defines all named text styles. Nine custom Ethiopic/Latin fonts are registered in `pubspec.yaml`; the reader exposes all nine through `readerFonts[]` / `readerFontNames[]` in `lib/features/books/presentation/widgets/reader/constants.dart`. Font indices in `AppSettings` always index into `readerFonts[]`.

### Stub / placeholder features

These widgets in `lib/features/home/presentation/widgets/` are hardcoded placeholders not yet wired to real data:
- `daily_verse_card.dart` — hardcoded Psalm 119:105
- `continue_reading_section.dart` — hardcoded "1 Kings Chapter 8"
- `reading_streak_card.dart` — hardcoded "12 days"

The Search and Bookmarks tabs in `HomeScreen` are `_StubTab` placeholders.

### Ethiopian calendar

The `kenat` package is used for Ethiopian date handling and Geez numeral display. `AppSettings.useGeezNumbers` controls whether chapter/verse numbers render in Geez script throughout the reader.
