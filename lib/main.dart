import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/l10n.dart';
import 'core/services/bible_repository_provider.dart';
import 'core/services/repository_provider.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/books/data/repositories/bible_repository.dart';
import 'features/home/presentation/pages/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bibleRepository = BibleRepository();
  runApp(
    ProviderScope(
      overrides: [
        bibleRepositoryProvider.overrideWithValue(bibleRepository),
      ],
      child: BibleRepositoryProvider(
        repository: bibleRepository,
        child: const BibleApp(),
      ),
    ),
  );
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // BibleRepositoryProvider is already provided by main() with the same
    // instance that's registered in ProviderScope — don't create a second one.
    return Settings(
      child: L10n(
        initialLanguage: AppLanguage.amharic,
        child: const _BibleMaterialApp(),
      ),
    );
  }
}

/// [MaterialApp] must read [Settings] so night mode updates the whole UI (not only the reader).
class _BibleMaterialApp extends StatelessWidget {
  const _BibleMaterialApp();

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    return MaterialApp(
      title: 'መጽሐፍ ቅዱስ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.isDarkReader ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
