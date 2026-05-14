# Contributing to EOTC Bible

Thank you for your interest in contributing. This document covers everything you need to get started.

---

## Before You Start

By submitting a contribution you agree that your work will be released under the project's [PolyForm Noncommercial License 1.0.0](LICENSE). If you are contributing on behalf of an organization, make sure you have the authority to do so.

---

## Ways to Contribute

- **Bug reports** — open an issue with steps to reproduce, device/OS version, and a screenshot if relevant
- **Bible data corrections** — if a verse is missing or mistranslated, open an issue citing the source text
- **UI improvements** — new features or polish that serve the EOTC community
- **Translations** — additional language support beyond Amharic/English
- **Font additions** — Ethiopic fonts with open licenses

---

## Development Setup

```bash
# 1. Clone the repo
git clone <repo-url>
cd bibleflutter

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

# 4. Verify everything passes before opening a PR
flutter analyze
flutter test
```

The project uses a feature-first folder layout under `lib/features/` with shared code in `lib/core/`.

---

## Branching & Pull Requests

- Branch off `main`: `git checkout -b feat/my-feature`
- One logical change per PR — keep diffs reviewable
- Prefix commits with a type: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Run `flutter analyze` before pushing — PRs must pass with zero issues
- Write a short PR description explaining *why*, not just *what*

---

## Code Style

- Follow the conventions in the existing codebase
- State management uses `InheritedWidget`/`InheritedNotifier` for global app state (`Settings`, `L10n`, `BibleRepositoryProvider`) and Riverpod for feature-level state (reading progress, annotations, immersive mode) — follow whichever pattern fits the scope of your change
- No comments that describe *what* the code does — only add a comment when the *why* is non-obvious
- No new `*.md` documentation files inside `lib/` — keep docs at the repo root

---

## Reporting a Security Issue

Do not open a public issue for security vulnerabilities. Email the maintainers directly and allow reasonable time to respond before any public disclosure.

---

## Code of Conduct

Be respectful. This project serves a religious community — discussions about scripture, theology, or community practices should remain courteous and constructive. Harassment or discrimination of any kind will result in removal from the project.
