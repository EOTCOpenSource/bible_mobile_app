import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/l10n/l10n.dart';
import 'core/services/repository_provider.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/books/data/repositories/bible_repository.dart';
import 'features/home/presentation/pages/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BibleApp(),
    ),
  );
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BibleRepositoryProvider(
      repository: BibleRepository(),
      child: Settings(
        child: L10n(
          initialLanguage: AppLanguage.amharic,
          child: MaterialApp(
            title: 'መጽሐፍ ቅዱስ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
  }
}
