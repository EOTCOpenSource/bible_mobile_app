---
title: "Feature: Verse Share — system share sheet"
labels: ["feature", "good first issue", "help wanted"]
---

## Summary

The **Share** button in the reader's verse action bar (`lib/features/books/presentation/widgets/reader/verse_action_bar.dart`) currently shows a "coming soon" snackbar. It should open the native system share sheet so users can send a verse to any app (WhatsApp, Telegram, Messages, etc.).

## Current state

```dart
// lib/features/books/presentation/pages/reader_screen.dart
onShare: () {
  _deselect();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s.comingSoon)),
  );
},
```

## What needs to be built

### 1 — Add `share_plus` dependency

```yaml
# pubspec.yaml
dependencies:
  share_plus: ^10.0.0
```

### 2 — Share the same text that copy uses

The copy action already builds a well-formatted string including the verse text, reference, and deep link. Share should reuse that exact string so the two are always consistent.

```dart
// Current copy text shape (from _selectedVerseText):
// ርኵሱም መንፈስ አንፈራገጠውና በታላቅ ድምፅ ጮኾ ከእርሱ ወጣ።
// የማርቆስ ወንጌል 1:26 (https://80-weahadu.vercel.app/openinapp/mark1_26)

onShare: () async {
  final text = _selectedVerseText(settings);
  if (text != null) {
    await SharePlus.instance.share(ShareParams(text: text));
  }
  _deselect();
},
```

### 3 — No "coming soon" snackbar

Remove the placeholder snackbar entirely once the share sheet is wired up.

## Relevant files

| File | Role |
|---|---|
| `lib/features/books/presentation/pages/reader_screen.dart` | Replace `onShare` implementation |
| `lib/features/books/presentation/widgets/reader/verse_action_bar.dart` | Share button UI (no change needed) |
| `pubspec.yaml` | Add `share_plus` |

## Notes

- `_selectedVerseText` is a private method on `_ReaderScreenState` — reuse it directly, do not duplicate the formatting logic
- Test that the deep link URL at the end of the share text is tappable in the receiving app
- `SharePlus.instance.share(ShareParams(...))` is the current API for `share_plus` v10+
