import 'package:flutter/material.dart';
import 'app_strings.dart';
import 'am_strings.dart';
import 'en_strings.dart';

export 'app_strings.dart';
export 'am_strings.dart';
export 'en_strings.dart';

/// Supported app languages.
enum AppLanguage { amharic, english }

/// Wraps the widget tree with a reactive [AppStrings] instance.
/// Switch language at runtime via [L10n.switchLanguage].
///
/// Usage:
///   // read strings
///   final s = L10n.of(context);
///
///   // switch language
///   L10n.switchLanguage(context, AppLanguage.english);
class L10n extends InheritedNotifier<ValueNotifier<AppStrings>> {
  L10n({
    super.key,
    required AppLanguage initialLanguage,
    required super.child,
  }) : super(notifier: ValueNotifier(_resolve(initialLanguage)));

  // ── Public API ────────────────────────────────────────────────────────────

  static AppStrings of(BuildContext context) {
    final l10n = context.dependOnInheritedWidgetOfExactType<L10n>();
    assert(l10n != null, 'No L10n found in widget tree. Wrap your app with L10n().');
    return l10n!.notifier!.value;
  }

  static void switchLanguage(BuildContext context, AppLanguage lang) {
    final l10n = context.getInheritedWidgetOfExactType<L10n>();
    assert(l10n != null, 'No L10n found in widget tree.');
    l10n!.notifier!.value = _resolve(lang);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static AppStrings _resolve(AppLanguage lang) => switch (lang) {
        AppLanguage.amharic => const AmStrings(),
        AppLanguage.english => const EnStrings(),
      };

  @override
  bool updateShouldNotify(L10n oldWidget) => notifier!.value != oldWidget.notifier!.value;
}
