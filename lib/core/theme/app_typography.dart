import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // ── Amharic – Noto Sans Ethiopic ─────────────────────────────────────────

  static TextStyle get amharicDisplay => GoogleFonts.notoSansEthiopic(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  static TextStyle get amharicHeading => GoogleFonts.notoSansEthiopic(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get amharicSubheading => GoogleFonts.notoSansEthiopic(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.5,
      );

  // Primary style for reading scripture – generous line-height for legibility
  static TextStyle get amharicVerse => GoogleFonts.notoSansEthiopic(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 2.0,
      );

  static TextStyle get amharicBody => GoogleFonts.notoSansEthiopic(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.8,
      );

  static TextStyle get amharicLabel => GoogleFonts.notoSansEthiopic(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get amharicCaption => GoogleFonts.notoSansEthiopic(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ── English – Inter ───────────────────────────────────────────────────────

  static TextStyle get englishDisplay => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.5,
      );

  static TextStyle get englishHeading => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get englishBody => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get englishLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle get englishCaption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.3,
      );

  // Superscript-style verse numbers rendered inline with scripture
  static TextStyle get verseNumber => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0.5,
      );
}
