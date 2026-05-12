import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_color_scheme.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        colors: AppColorScheme.light,
        brightness: Brightness.light,
      );

  static ThemeData get dark => _build(
        colors: AppColorScheme.dark,
        brightness: Brightness.dark,
      );

  /// Parchment variant used by the reader screen.
  static ThemeData get parchment => _build(
        colors: AppColorScheme.light.copyWith(
          surface: AppColorScheme.light.parchment,
          surfaceDim: AppColorScheme.light.parchmentDark,
        ),
        brightness: Brightness.light,
      );

  static ThemeData get parchmentDark => _build(
        colors: AppColorScheme.dark.copyWith(
          surface: AppColorScheme.dark.parchment,
          surfaceDim: AppColorScheme.dark.parchmentDark,
        ),
        brightness: Brightness.dark,
      );

  static ThemeData _build({
    required AppColorScheme colors,
    required Brightness brightness,
  }) {
    final base = ThemeData(brightness: brightness);

    return base.copyWith(
      extensions: [colors],

      scaffoldBackgroundColor: colors.surface,

      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: colors.primary,
        primary: colors.primary,
        onPrimary: colors.textOnDark,
        secondary: colors.accent,
        onSecondary: colors.textOnParchment,
        surface: colors.surface,
        onSurface: colors.textBody,
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: colors.textOnDark,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colors.primaryDark,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: brightness,
        ),
        titleTextStyle: AppTypography.amharicSubheading.copyWith(
          color: colors.textOnDark,
        ),
        iconTheme: IconThemeData(color: colors.accent),
        actionsIconTheme: IconThemeData(color: colors.accent),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.borderSubtle),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Dividers ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: colors.primary,
        textColor: colors.textBody,
        titleTextStyle: AppTypography.amharicBody,
        subtitleTextStyle:
            AppTypography.englishCaption.copyWith(color: colors.textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Bottom navigation ─────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.primary,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.textOnDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),

      // ── NavigationBar (Material 3) ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.primary,
        indicatorColor: colors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.accent, size: 24);
          }
          return IconThemeData(color: colors.textOnDark, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = AppTypography.englishCaption;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: colors.accent);
          }
          return base.copyWith(color: colors.textOnDark);
        }),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.accent,
        elevation: 4,
      ),

      // ── Buttons ───────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.accent,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.englishLabel,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.5),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.englishLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: AppTypography.englishLabel,
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: colors.parchment,
        selectedColor: colors.primary,
        secondarySelectedColor: colors.primaryLight,
        labelStyle: AppTypography.englishLabel,
        secondaryLabelStyle:
            AppTypography.englishLabel.copyWith(color: colors.textOnDark),
        side: BorderSide(color: colors.borderSubtle),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Input ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.parchment,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        hintStyle:
            AppTypography.englishBody.copyWith(color: colors.textCaption),
        prefixIconColor: colors.textMuted,
        suffixIconColor: colors.textMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Text theme ────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge:  AppTypography.amharicDisplay,
        displayMedium: AppTypography.amharicHeading,
        displaySmall:  AppTypography.amharicSubheading,
        bodyLarge:     AppTypography.amharicVerse,
        bodyMedium:    AppTypography.amharicBody,
        bodySmall:     AppTypography.amharicCaption,
        labelLarge:    AppTypography.englishLabel,
        labelMedium:   AppTypography.englishLabel,
        labelSmall:    AppTypography.englishCaption,
      ),
    );
  }
}
