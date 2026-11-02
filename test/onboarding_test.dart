import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/onboarding/presentation/pages/onboarding_screen.dart';

void main() {
  // Skipping onboarding calls Settings.update, which writes straight through to
  // AppDatabase — there is no seam. Under a test the global sqflite factory is
  // unset, so the tap throws unless ffi is installed first.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('OnboardingScreen renders page 1 with Skip and Next buttons', (
    tester,
  ) async {
    final settingsNotifier = ValueNotifier<AppSettings>(const AppSettings());

    await tester.pumpWidget(
      Settings(
        notifier: settingsNotifier,
        child: L10n(
          initialLanguage: AppLanguage.amharic,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Skip and Next are rendered
    expect(find.text('እለፍ'), findsOneWidget); // Amharic Skip
    expect(find.text('ቀጣይ'), findsOneWidget); // Amharic Next
  });

  testWidgets('Skipping onboarding updates hasSeenOnboarding flag to true', (
    tester,
  ) async {
    final settingsNotifier = ValueNotifier<AppSettings>(const AppSettings());

    await tester.pumpWidget(
      Settings(
        notifier: settingsNotifier,
        child: L10n(
          initialLanguage: AppLanguage.amharic,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Skip
    await tester.tap(find.text('እለፍ'));
    await tester.pumpAndSettle();

    // Verify flag was updated
    expect(settingsNotifier.value.hasSeenOnboarding, isTrue);
  });
}
