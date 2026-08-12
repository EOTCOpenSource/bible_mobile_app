/// The compact Latin reference the daily verse surfaces print in their corner,
/// e.g. `JER 29:11`, `1 COR 13:4`.
///
/// Always Latin digits and never the Amharic name: it is the counterpart to
/// the full localised reference printed elsewhere on the same card, and a
/// second Amharic reference in the corner would just repeat it in less space.
///
/// Shared by the home screen's [DailyVerseCard] and the Android daily verse
/// widget so the two cannot drift — the widget is meant to be the card, and a
/// reference abbreviated one way on screen and another on the home screen
/// reads as two different features.
String shortVerseRef(String bookNameEn, int chapter, int verse) {
  final parts = bookNameEn.trim().split(RegExp(r'\s+'));
  final word = parts.last;
  // "1 Corinthians" → "1 COR", "Jeremiah" → "JER".
  final abbr = word.length <= 3 ? word : word.substring(0, 3);
  final prefix = parts.length > 1 ? '${parts.first} ' : '';
  return '$prefix${abbr.toUpperCase()} $chapter:$verse';
}
