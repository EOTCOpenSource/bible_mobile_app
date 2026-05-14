---
title: "Feature: Notes tab in the Saved screen"
labels: ["feature", "good first issue", "help wanted"]
---

## Summary

The Saved screen (`lib/features/saved/`) has a **Highlights** tab and a **Bookmarks** tab, both of which are wired to real data. However there is no **Notes** tab, even though the reader already lets users write per-verse notes (stored in SQLite). Notes are invisible outside the reader — they can only be found by navigating back to the exact verse where they were written.

This issue adds a Notes tab so users can browse and manage all their saved notes in one place.

## Current state

- Notes are written via the Note Sheet in `ReaderScreen` and persisted through `chapterAnnotationsProvider` → `AppDatabase`
- `AnnotationItem` in `lib/features/saved/presentation/pages/saved_common.dart` already carries `noteContent`
- The Saved screen (`saved_screen.dart`) has a `TabBar` — adding a third tab is straightforward
- The Bookmarks tab (`bookmarks_tab.dart`) can be used as a close reference for the same list + filter pattern

## What needs to be built

### 1 — Query all notes from the database

Add a method to the annotation repository (or extend the existing Riverpod provider) that returns all verses with a non-empty note, across all books and chapters, sorted by book number then chapter then verse.

### 2 — `NotesTab` widget

Create `lib/features/saved/presentation/pages/notes_tab.dart` mirroring the structure of `bookmarks_tab.dart`:

- Filter chips: All / Old Testament / New Testament / by book / by chapter
- List of `AnnotationCard`-style rows showing:
  - Book name + chapter:verse reference
  - First line(s) of the note content (truncated)
- Tapping a row opens `ReaderScreen` at that verse (same pattern as Bookmarks)
- Pull-to-refresh

### 3 — Wire into `SavedScreen`

Add **Notes** as a third tab in `lib/features/saved/presentation/pages/saved_screen.dart`.

### 4 — Edit/delete from the list

Stretch goal: long-press a note card to get a menu with **Edit** (opens the Note Sheet) and **Delete** options. 

## Relevant files

| File | Role |
|---|---|
| `lib/features/saved/presentation/pages/saved_screen.dart` | Add Notes tab |
| `lib/features/saved/presentation/pages/bookmarks_tab.dart` | Reference for list + filter pattern |
| `lib/features/saved/presentation/pages/saved_common.dart` | Shared `AnnotationItem`, `AnnotationCard`, filter chips |
| `lib/features/annotations/providers/annotation_providers.dart` | Add `allNotesProvider` |
| `lib/core/storage/app_database.dart` | Add `getAllNotes()` query |

## Notes

- The project uses `AnnotationItem` as the shared display model — add a `noteContent` field if not already present, or filter existing items to those where `noteContent != null`
- Follow the existing `InheritedWidget` + Riverpod pattern: repository access via `BibleRepositoryProvider.of(context)`, feature state via Riverpod
- Keep filters consistent with the Bookmarks tab so the UX is predictable
