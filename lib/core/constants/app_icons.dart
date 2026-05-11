/// Liturgical symbol constants used across the app.
///
/// The Ethiopian Orthodox Cross (✠) is the primary brand mark.
/// All symbols are Unicode characters rendered via Noto Sans Ethiopic
/// or a system fallback — no icon font required.
abstract final class AppIcons {
  // ── Brand mark ────────────────────────────────────────────────────────────
  static const String ethiopianCross = '✠'; // U+2720  – primary brand mark

  // ── Supplementary crosses ─────────────────────────────────────────────────
  static const String crossOutline = '✞'; // U+271E  – decorative outline cross
  static const String malteseCross = '✤'; // U+2724  – section ornament

  // ── Structural markers ────────────────────────────────────────────────────
  static const String sectionFleuron = '❧'; // U+2767  – end-of-section mark
  static const String chapterPilcrow = '§'; // U+00A7  – chapter label prefix

  // ── Typographic ornaments ─────────────────────────────────────────────────
  static const String ornamentOpen  = '❮'; // U+276E
  static const String ornamentClose = '❯'; // U+276F
  static const String bulletFloral  = '❁'; // U+2741  – list bullets
}
