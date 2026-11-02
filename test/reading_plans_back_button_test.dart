import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/home/presentation/pages/reading_plans_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// ReadingPlansScreen is both a bottom-nav tab and a pushed route. As a tab it
/// is the only route on the stack, so a back button there pops the app itself —
/// which is exactly the crash these tests exist to prevent.
Widget _wrap(Widget home) => ProviderScope(
      // The app bar renders in every provider state, so the plan list is left
      // to resolve however it likes here.
      child: L10n(
        initialLanguage: AppLanguage.amharic,
        child: Settings(
          notifier: ValueNotifier(const AppSettings()),
          child: MaterialApp(theme: AppTheme.parchment, home: home),
        ),
      ),
    );

void main() {
  testWidgets('as a tab it shows no back button', (tester) async {
    await tester.pumpWidget(_wrap(const ReadingPlansScreen()));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing,
        reason: 'a back button at the root pops the last route and kills '
            'the app');
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('when pushed it shows a back button that returns', (tester) async {
    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReadingPlansScreen()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(ReadingPlansScreen), findsOneWidget);
    final back = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(back, findsOneWidget);

    await tester.tap(back);
    await tester.pumpAndSettle();

    // Back to the launcher screen, with the app still alive.
    expect(find.byType(ReadingPlansScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
