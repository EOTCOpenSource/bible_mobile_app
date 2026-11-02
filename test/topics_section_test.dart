import 'package:bibleflutter/core/l10n/l10n.dart';
import 'package:bibleflutter/core/theme/app_theme.dart';
import 'package:bibleflutter/features/topics/data/topic_models.dart';
import 'package:bibleflutter/features/topics/presentation/widgets/topics_section.dart';
import 'package:bibleflutter/features/topics/providers/topic_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('topic cards fit at the supported larger text scale', (tester) async {
    const topic = TopicEntry(
      id: 'communion',
      labelAm: 'Holy Communion',
      labelEn: 'Holy Communion',
      icon: '🍷',
      keywords: ['ቁርባን'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [topicsProvider.overrideWith((ref) async => [topic])],
        child: L10n(
          initialLanguage: AppLanguage.english,
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: const Scaffold(body: SizedBox(width: 360, child: TopicsSection())),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
