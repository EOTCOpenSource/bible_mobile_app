import 'package:flutter/material.dart';

/// Semantic color tokens for the app, available as a [ThemeExtension].
///
/// Access in any widget via [BuildContext.colors]:
///   `final c = context.colors;`
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentDark,
    required this.accentDeep,
    required this.parchment,
    required this.parchmentDark,
    required this.surface,
    required this.surfaceDim,
    required this.textOnDark,
    required this.textOnParchment,
    required this.textBody,
    required this.textMuted,
    required this.textCaption,
    required this.divider,
    required this.borderSubtle,
    required this.oldTestament,
    required this.newTestament,
    required this.scrim,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color accentDark;
  final Color accentDeep;
  final Color parchment;
  final Color parchmentDark;
  final Color surface;
  final Color surfaceDim;
  final Color textOnDark;
  final Color textOnParchment;
  final Color textBody;
  final Color textMuted;
  final Color textCaption;
  final Color divider;
  final Color borderSubtle;
  final Color oldTestament;
  final Color newTestament;
  final Color scrim;

  // ── Light palette ─────────────────────────────────────────────────────────

  static const light = AppColorScheme(
    primary:        Color(0xFF6B1F2A),
    primaryLight:   Color(0xFF8B3A47),
    primaryDark:    Color(0xFF4A1219),
    accent:         Color(0xFFF4D38A),
    accentDark:     Color(0xFF855B0B),
    accentDeep:     Color(0xFF7A520B),
    parchment:      Color(0xFFEFE9DF),
    parchmentDark:  Color(0xFFE0D8CC),
    surface:        Color(0xFFFFFFFF),
    surfaceDim:     Color(0xFFF8F5F0),
    textOnDark:     Color(0xFFFFF8F0),
    textOnParchment:Color(0xFF2C1810),
    textBody:       Color(0xFF3D2314),
    textMuted:      Color(0xFF544438),
    textCaption:    Color(0xFF5C4A3E),
    divider:        Color(0xFFD4B896),
    borderSubtle:   Color(0xFFE8D9C4),
    oldTestament:   Color(0xFF6B1F2A),
    newTestament:   Color(0xFF1F3D6B),
    scrim:          Color(0xCC2C1810),
  );

  // ── Dark palette ──────────────────────────────────────────────────────────

  static const dark = AppColorScheme(
    primary:        Color(0xFFA03848),
    primaryLight:   Color(0xFFC05868),
    primaryDark:    Color(0xFF6B1F2A),
    accent:         Color(0xFFF4D38A),
    accentDark:     Color(0xFFD4A853),
    accentDeep:     Color(0xFFD4A853),
    parchment:      Color(0xFF1E1A16),
    parchmentDark:  Color(0xFF161210),
    surface:        Color(0xFF0F0D0B),
    surfaceDim:     Color(0xFF1A1614),
    textOnDark:     Color(0xFFFFF8F0),
    textOnParchment:Color(0xFFEEE4D4),
    textBody:       Color(0xFFDDD0BE),
    textMuted:      Color(0xFFC4B4A4),
    textCaption:    Color(0xFFBBAA9A),
    divider:        Color(0xFF3A2E24),
    borderSubtle:   Color(0xFF2E2420),
    oldTestament:   Color(0xFFA03848),
    newTestament:   Color(0xFF4A6B9B),
    scrim:          Color(0xCC0A0806),
  );

  // ── ThemeExtension API ────────────────────────────────────────────────────

  @override
  AppColorScheme copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? accent,
    Color? accentDark,
    Color? accentDeep,
    Color? parchment,
    Color? parchmentDark,
    Color? surface,
    Color? surfaceDim,
    Color? textOnDark,
    Color? textOnParchment,
    Color? textBody,
    Color? textMuted,
    Color? textCaption,
    Color? divider,
    Color? borderSubtle,
    Color? oldTestament,
    Color? newTestament,
    Color? scrim,
  }) =>
      AppColorScheme(
        primary:         primary         ?? this.primary,
        primaryLight:    primaryLight    ?? this.primaryLight,
        primaryDark:     primaryDark     ?? this.primaryDark,
        accent:          accent          ?? this.accent,
        accentDark:      accentDark      ?? this.accentDark,
        accentDeep:      accentDeep      ?? this.accentDeep,
        parchment:       parchment       ?? this.parchment,
        parchmentDark:   parchmentDark   ?? this.parchmentDark,
        surface:         surface         ?? this.surface,
        surfaceDim:      surfaceDim      ?? this.surfaceDim,
        textOnDark:      textOnDark      ?? this.textOnDark,
        textOnParchment: textOnParchment ?? this.textOnParchment,
        textBody:        textBody        ?? this.textBody,
        textMuted:       textMuted       ?? this.textMuted,
        textCaption:     textCaption     ?? this.textCaption,
        divider:         divider         ?? this.divider,
        borderSubtle:    borderSubtle    ?? this.borderSubtle,
        oldTestament:    oldTestament    ?? this.oldTestament,
        newTestament:    newTestament    ?? this.newTestament,
        scrim:           scrim           ?? this.scrim,
      );

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      primary:         Color.lerp(primary,         other.primary,         t)!,
      primaryLight:    Color.lerp(primaryLight,    other.primaryLight,    t)!,
      primaryDark:     Color.lerp(primaryDark,     other.primaryDark,     t)!,
      accent:          Color.lerp(accent,          other.accent,          t)!,
      accentDark:      Color.lerp(accentDark,      other.accentDark,      t)!,
      accentDeep:      Color.lerp(accentDeep,      other.accentDeep,      t)!,
      parchment:       Color.lerp(parchment,       other.parchment,       t)!,
      parchmentDark:   Color.lerp(parchmentDark,   other.parchmentDark,   t)!,
      surface:         Color.lerp(surface,         other.surface,         t)!,
      surfaceDim:      Color.lerp(surfaceDim,      other.surfaceDim,      t)!,
      textOnDark:      Color.lerp(textOnDark,      other.textOnDark,      t)!,
      textOnParchment: Color.lerp(textOnParchment, other.textOnParchment, t)!,
      textBody:        Color.lerp(textBody,        other.textBody,        t)!,
      textMuted:       Color.lerp(textMuted,       other.textMuted,       t)!,
      textCaption:     Color.lerp(textCaption,     other.textCaption,     t)!,
      divider:         Color.lerp(divider,         other.divider,         t)!,
      borderSubtle:    Color.lerp(borderSubtle,    other.borderSubtle,    t)!,
      oldTestament:    Color.lerp(oldTestament,    other.oldTestament,    t)!,
      newTestament:    Color.lerp(newTestament,    other.newTestament,    t)!,
      scrim:           Color.lerp(scrim,           other.scrim,           t)!,
    );
  }
}

/// Convenience accessor: `context.colors.primary`
extension AppColorSchemeContext on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>()!;
}
