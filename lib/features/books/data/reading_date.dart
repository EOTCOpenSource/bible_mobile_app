/// Local calendar date helpers for streaks (no time-of-day).
abstract final class ReadingDate {
  ReadingDate._();

  /// Today in the device local timezone, normalized to midnight.
  static DateTime todayLocal() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String toIsoDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String todayIso() => toIsoDate(todayLocal());

  /// Parses `YYYY-MM-DD` or returns null.
  static DateTime? tryParseIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parts = iso.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Whole calendar days from [a] to [b] (both date-only); `b` is typically today.
  static int calendarDaysBetween(DateTime a, DateTime b) {
    final aa = DateTime(a.year, a.month, a.day);
    final bb = DateTime(b.year, b.month, b.day);
    return bb.difference(aa).inDays;
  }
}
