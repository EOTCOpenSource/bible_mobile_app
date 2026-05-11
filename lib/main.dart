import 'package:flutter/material.dart';
import 'core/l10n/l10n.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Settings(
      child: L10n(
        initialLanguage: AppLanguage.amharic,
        child: MaterialApp(
          title: 'መጽሐፍ ቅዱስ',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
