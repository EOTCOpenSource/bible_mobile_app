import 'package:flutter/material.dart';

export 'app_color_scheme.dart';

abstract final class AppColors {
  // ── Primary – Deep Burgundy ──────────────────────────────────────────────
  static const Color primary      = Color(0xFF6B1F2A);
  static const Color primaryLight = Color(0xFF8B3A47);
  static const Color primaryDark  = Color(0xFF4A1219);

  // ── Accent – Gold / Sand ─────────────────────────────────────────────────
  static const Color accent      = Color(0xFFF4D38A);
  static const Color accentDark  = Color(0xFFD4A853); // readable on light bg
  static const Color accentDeep  = Color(0xFFAA8230); // icons / hairlines

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color parchment     = Color(0xFFEFE9DF); // reading mode
  static const Color parchmentDark = Color(0xFFE0D8CC); // cards on parchment
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceDim    = Color(0xFFF8F5F0);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textOnDark      = Color(0xFFFFF8F0); // on primary bg
  static const Color textOnParchment = Color(0xFF2C1810); // on parchment bg
  static const Color textBody        = Color(0xFF3D2314);
  static const Color textMuted       = Color(0xFF7A6458);
  static const Color textCaption     = Color(0xFF9E8878);

  // ── Borders & Dividers ───────────────────────────────────────────────────
  static const Color divider      = Color(0xFFD4B896);
  static const Color borderSubtle = Color(0xFFE8D9C4);

  // ── Testament identifiers ─────────────────────────────────────────────────
  static const Color oldTestament = Color(0xFF6B1F2A); // burgundy
  static const Color newTestament = Color(0xFF1F3D6B); // deep navy

  // ── Reader shell (bottom nav, etc. — matches reader scaffold) ────────────
  static const Color readerShellDarkBg      = Color(0xFF151210);
  static const Color readerShellDarkSurface = Color(0xFF231E1B);
  static const Color readerShellDarkText    = Color(0xFFF5EBE0);
  static const Color readerShellDarkMuted   = Color(0xFF9E8878);
  static const Color readerShellDarkAccent  = Color(0xFFD4A853);

  // ── Scrim / overlay ──────────────────────────────────────────────────────
  static const Color scrim = Color(0xCC2C1810);
}
