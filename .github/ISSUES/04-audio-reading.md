---
title: "Feature: Audio verse reading"
labels: ["feature", "help wanted", "needs discussion"]
---

## Summary

The Settings screen lists an **Audio** option (`settingAudio` / `settingAudioAction`) but there is no audio playback anywhere in the app. This issue covers adding the ability to listen to Bible chapters being read aloud.

This is a larger feature that needs community discussion before implementation begins — particularly around audio asset sourcing. **Please comment before starting work.**

## Questions that need answers before coding

1. **Audio source** — Does the project have rights to recorded Amharic scripture audio? If not, is text-to-speech (TTS) an acceptable starting point?
2. **Scope** — Should audio play the full chapter, the selected verse only, or both?
3. **Streaming vs bundled** — Stream from a CDN/server, or bundle MP3s with the app? Bundled audio for 81 books would be very large.

## Proposed initial scope (TTS path)

If no recorded audio is available, implement TTS as a first step using the device's built-in TTS engine:

### 1 — Add `flutter_tts`

```yaml
dependencies:
  flutter_tts: ^4.0.0
```

### 2 — Audio service

Create `lib/core/audio/audio_service.dart`:

```dart
class AudioService {
  Future<void> speak(String text, {String language = 'am-ET'});
  Future<void> stop();
  bool get isPlaying;
}
```

### 3 — Reader integration

When audio is active, show a mini player bar at the bottom of `ReaderScreen` (above `ChapterNavBar`) with play/pause/stop controls. Auto-advance to the next chapter when the current one finishes.

### 4 — Verse-level sync (stretch goal)

Highlight the verse currently being spoken in sync with the TTS position callback.

## If recorded audio becomes available

The architecture should support swapping TTS for streaming MP3s by replacing the `AudioService` implementation. The rest of the UI stays the same. Consider `just_audio` for streaming playback.

## Relevant files

| File | Role |
|---|---|
| `lib/features/me/` | Settings — wire the Audio toggle |
| `lib/features/books/presentation/pages/reader_screen.dart` | Add mini player bar |
| `lib/core/audio/` | New — audio service |
| `lib/features/books/presentation/widgets/reader/chapter_nav_bar.dart` | May need adjustment to accommodate the player bar |

## Notes

- Amharic TTS quality varies by device; test on at least two Android devices before shipping
- `flutter_tts` supports `am-ET` on Android; iOS support for Amharic may be limited — document any gaps
- Do not start audio automatically; require explicit user action (tap play)
