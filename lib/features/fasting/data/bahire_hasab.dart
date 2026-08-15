import 'package:kenat/kenat.dart';
import 'fasts.dart';

/// Pure computation of Bahire Hasab (ባሕረ ሐሳብ) for calculating Ethiopian Orthodox
/// movable feasts and fasts for any given Ethiopian year.
class BahireHasab {
  final int year;

  const BahireHasab(this.year);

  /// Years since creation (ዓመተ ዓለም).
  int get ameteAlem => year + 5500;

  /// Golden number / position in 19-year Metonic cycle (ወንበር).
  int get wenber {
    final r = ameteAlem % 19;
    return r == 0 ? 18 : r - 1;
  }

  /// Abekte (አበቅቴ).
  int get abekte => (wenber * 11) % 30;

  /// Metkih (መጥቅዕ).
  int get metkih {
    final m = (wenber * 19) % 30;
    return m == 0 ? 30 : m;
  }

  /// Month of Metkih (1 = Meskerem, 2 = Tikimt).
  int get metkihMonth => metkih > 14 ? 1 : 2;

  /// Weekday of Metkih (0 = Sunday, 1 = Monday ... 6 = Saturday).
  int get metkihWeekday {
    return Kenat.fromEthiopian(year, metkihMonth, metkih).getWeekday();
  }

  /// Tewsak factor for Nineveh based on Metkih weekday.
  int get ninevehTewsak {
    return switch (metkihWeekday) {
      0 => 7, // Sunday
      1 => 6, // Monday
      2 => 5, // Tuesday
      3 => 4, // Wednesday
      4 => 3, // Thursday
      5 => 2, // Friday
      6 => 8, // Saturday
      _ => 7,
    };
  }

  /// Mebaja Hamer (መባጃ ሐመር).
  int get mebajaHamer => metkih + ninevehTewsak;

  /// EthiopianDate of Fast of Nineveh (ጾመ ነነዌ - Monday start).
  EthiopianDate get nenewe {
    int month;
    int day;

    if (metkihMonth == 1) {
      if (mebajaHamer > 30) {
        month = 6; // Yekatit
        day = mebajaHamer - 30;
      } else {
        month = 5; // Tir
        day = mebajaHamer;
      }
    } else {
      if (mebajaHamer > 30) {
        month = 7; // Megabit
        day = mebajaHamer - 30;
      } else {
        month = 6; // Yekatit
        day = mebajaHamer;
      }
    }

    return EthiopianDate(year, month, day);
  }

  /// Fasika (Easter Sunday) date, which is 69 days after Nineveh.
  EthiopianDate get fasika => nenewe.addDays(69);
}
