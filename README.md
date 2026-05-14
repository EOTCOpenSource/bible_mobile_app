# EOTC Bible — መጽሐፍ ቅዱስ

A Flutter Bible reader built for the Ethiopian Orthodox Tewahedo Church canon. The app ships the full 81-book EOTC canon in Amharic, with a reader-first design, verse sharing, and deep-link navigation.

---

## Features

- **81-book EOTC canon** — includes deuterocanonical books (Jubilees, Enoch, 1–3 Maccabees, Tobit, Judith, Baruch, Sirach, and more)
- **Reader** — chapter-by-chapter page swipe, section headings, Geez numeral support
- **Nine Ethiopic/Latin fonts** — switchable from the reader's font sheet
- **Dark mode** — full dark reader theme
- **Verse actions** — tap any verse to copy, highlight, bookmark, or add a note
- **Deep links** — `eotcbible://` custom scheme and HTTPS App Links open a specific verse directly
- **Daily verse** — Ethiopian-calendar-aware verse of the day
- **Continue reading** — persists your position per book
- **Search** — full-text search across the whole canon or within a single book
- **Reading streaks** — tracks consecutive days of reading

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.11
- Android SDK or Xcode (for device/emulator targets)

### Run

```bash
flutter pub get
flutter run
```

### Build

```bash
# Android
flutter build apk

# iOS
flutter build ios
```

### Analyze & test

```bash
flutter analyze
flutter test
```

---

## Deep Links

Verses can be shared and opened directly via URL.

| Format | Example |
|---|---|
| Custom scheme | `eotcbible://openinapp/jer29_11` |
| HTTPS App Link | `https://80-weahadu.vercel.app/openinapp/jer29_11` |

**Slug format:** `{abbrev}{chapter}_{verse}` where `abbrev` is the book's short English name lowercased with spaces removed (`1 Sam` → `1sam`, `Jer` → `jer`).

**Test on Android:**
```bash
adb shell am start -a android.intent.action.VIEW \
  -d "eotcbible://openinapp/jer29_11" \
  org.nehemiah_osc.bibleflutter/.MainActivity
```

---

## Project Structure

```
lib/
  core/           # theme, typography, l10n, settings, deep links, services
  features/
    books/        # Bible data layer, reader screen, verse actions
    home/         # Home tab: daily verse, continue reading, streaks
    me/           # Settings tab and reading preferences
assets/
  bibledata/      # 81 JSON book files + index.json
  fonts/          # Nine Ethiopic/Latin font families
```

See [`CLAUDE.md`](CLAUDE.md) for a full architecture reference.

---

## License

Source available under the [PolyForm Noncommercial License 1.0.0](LICENSE).
Free to use, study, and modify for any noncommercial purpose.
Commercial use is not permitted without explicit written permission from the project maintainers.
