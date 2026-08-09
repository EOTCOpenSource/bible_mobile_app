import 'package:flutter/foundation.dart';

/// Everything the three Android home screen widgets draw, in the form they
/// draw it.
///
/// Deliberately nothing but strings and ints. The widgets render in the
/// launcher's process, which has no Flutter engine, no `AppStrings` and no
/// access to the Ge'ez numeral helpers — so every localisation, numeral
/// conversion and truncation decision is made here, on the Dart side, and the
/// Kotlin layer only ever copies text into a `TextView`.
@immutable
class HomeWidgetData {
  const HomeWidgetData({
    required this.verseText,
    required this.verseRef,
    required this.verseDeepLink,
    required this.continueBook,
    required this.continueRef,
    required this.continueProgress,
    required this.continueDeepLink,
    required this.streakCount,
    required this.streakCountLabel,
    required this.streakEmoji,
    required this.streakSuffix,
    required this.streakDeepLink,
  });

  /// The day's verse, already truncated to what the medium widget can show.
  final String verseText;

  /// Localised reference, e.g. `ኤር 29:11`.
  final String verseRef;

  /// `eotcbible://openinapp/jer29_11` — the verse itself, so tapping the
  /// widget lands on the words it was showing.
  final String verseDeepLink;

  /// Book name for the continue-reading widget, empty when nothing was ever
  /// opened. The Kotlin side hides the widget's body on empty.
  final String continueBook;

  /// Localised chapter/verse the reader left off at.
  final String continueRef;

  /// 0–100. Drives the little progress bar.
  final int continueProgress;

  /// Deep link back to the exact position, reusing the ordinary verse slug —
  /// continue-reading needs no vocabulary of its own.
  final String continueDeepLink;

  /// Days in the current run, as a number.
  ///
  /// The widget shows [streakCountLabel] rather than this — the int is here so
  /// the Kotlin side can tell "no streak yet" from "a streak of zero written
  /// in Ge'ez", which it cannot read back out of the label.
  final int streakCount;

  /// [streakCount] rendered in the numeral system the user reads in, so the
  /// widget shows `፲፪` when the app does.
  final String streakCountLabel;

  /// The user's chosen streak emoji, 🔥 by default.
  final String streakEmoji;

  /// The localised word after the number — "ቀናት" / "days" — and nothing else.
  /// The count is a separate, larger line in the layout.
  final String streakSuffix;

  /// `eotcbible://openinapp/streak`.
  final String streakDeepLink;

  /// The shape written to the shared preferences the widgets read.
  ///
  /// Keys are part of the contract with the Kotlin layer — changing one here
  /// without changing `WidgetKeys.kt` leaves the widget showing a stale value
  /// forever, because a missing key reads as "no update".
  Map<String, Object> toWidgetEntries() => {
        'verse_text': verseText,
        'verse_ref': verseRef,
        'verse_deeplink': verseDeepLink,
        'continue_book': continueBook,
        'continue_ref': continueRef,
        'continue_progress': continueProgress,
        'continue_deeplink': continueDeepLink,
        'streak_count': streakCount,
        'streak_count_label': streakCountLabel,
        'streak_emoji': streakEmoji,
        'streak_suffix': streakSuffix,
        'streak_deeplink': streakDeepLink,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeWidgetData &&
          other.verseText == verseText &&
          other.verseRef == verseRef &&
          other.verseDeepLink == verseDeepLink &&
          other.continueBook == continueBook &&
          other.continueRef == continueRef &&
          other.continueProgress == continueProgress &&
          other.continueDeepLink == continueDeepLink &&
          other.streakCount == streakCount &&
          other.streakCountLabel == streakCountLabel &&
          other.streakEmoji == streakEmoji &&
          other.streakSuffix == streakSuffix &&
          other.streakDeepLink == streakDeepLink;

  @override
  int get hashCode => Object.hashAll([
        verseText,
        verseRef,
        verseDeepLink,
        continueBook,
        continueRef,
        continueProgress,
        continueDeepLink,
        streakCount,
        streakCountLabel,
        streakEmoji,
        streakSuffix,
        streakDeepLink,
      ]);
}
