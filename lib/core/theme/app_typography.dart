import 'package:flutter/material.dart';

abstract final class AppTypography {
  // ── Font family constants ─────────────────────────────────────────────────
  static const String shiromeda       = 'Shiromeda';       // primary Amharic reading
  static const String belaHidaseQedmo = 'BelaHidaseQedmo'; // display / hero titles
  static const String abbaGarima      = 'AbbaGarima';      // liturgical / section labels
  static const String selam           = 'Selam';           // alternate body
  static const String ethiopicSadiss  = 'EthiopicSadiss';  // light ambient labels
  static const String geezHandwriting = 'GeezHandwriting'; // decorative / splash
  static const String kiros              = 'Kiros';              // traditional alternate
  static const String addisAbebaUnicode  = 'AddisAbebaUnicode';  // classic unicode Geez
  static const String nokiaPureheadline  = 'NokiaPureheadline';  // Latin / English UI

  // ── Amharic – Shiromeda (primary reading) ─────────────────────────────────

  static const TextStyle amharicDisplay = TextStyle(
    fontFamily: belaHidaseQedmo,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.4,
  );

  static const TextStyle amharicHeading = TextStyle(
    fontFamily: shiromeda,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle amharicSubheading = TextStyle(
    fontFamily: shiromeda,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  /// Primary scripture reading style — generous line-height for legibility.
  static const TextStyle amharicVerse = TextStyle(
    fontFamily: shiromeda,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 2.0,
  );

  static const TextStyle amharicBody = TextStyle(
    fontFamily: shiromeda,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.8,
  );

  static const TextStyle amharicLabel = TextStyle(
    fontFamily: shiromeda,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle amharicCaption = TextStyle(
    fontFamily: shiromeda,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── Amharic – AbbaGarima (liturgical / section titles) ───────────────────

  static const TextStyle liturgicalHeading = TextStyle(
    fontFamily: abbaGarima,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle liturgicalBody = TextStyle(
    fontFamily: abbaGarima,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 2.0,
  );

  // ── Amharic – EthiopicSadiss (light ambient) ──────────────────────────────

  static const TextStyle ambientLabel = TextStyle(
    fontFamily: ethiopicSadiss,
    fontSize: 13,
    fontWeight: FontWeight.w300,
    height: 1.4,
  );

  // ── Amharic – GeezHandwriting (decorative) ────────────────────────────────

  static const TextStyle decorative = TextStyle(
    fontFamily: geezHandwriting,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── English – NokiaPureheadline ───────────────────────────────────────────

  static const TextStyle englishHeading = TextStyle(
    fontFamily: nokiaPureheadline,
    fontSize: 18,
    fontWeight: FontWeight.w300,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle englishBody = TextStyle(
    fontFamily: nokiaPureheadline,
    fontSize: 15,
    fontWeight: FontWeight.w300,
    height: 1.6,
  );

  static const TextStyle englishLabel = TextStyle(
    fontFamily: nokiaPureheadline,
    fontSize: 13,
    fontWeight: FontWeight.w300,
    height: 1.4,
    letterSpacing: 0.2,
  );

  static const TextStyle englishCaption = TextStyle(
    fontFamily: nokiaPureheadline,
    fontSize: 11,
    fontWeight: FontWeight.w300,
    height: 1.4,
    letterSpacing: 0.3,
  );

  /// Inline verse number superscript.
  static const TextStyle verseNumber = TextStyle(
    fontFamily: nokiaPureheadline,
    fontSize: 10,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: 0.5,
  );
}
