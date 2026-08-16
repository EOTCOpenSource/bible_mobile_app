import 'package:flutter/foundation.dart';
import 'package:kenat/kenat.dart' hide BahireHasab;
import 'bahire_hasab.dart';


/// Represents a specific date in the Ethiopian Calendar.
@immutable
class EthiopianDate implements Comparable<EthiopianDate> {
  final int year;
  final int month;
  final int day;

  const EthiopianDate(this.year, this.month, this.day);

  factory EthiopianDate.fromKenat(Kenat kenat) {
    final et = kenat.getEthiopian();
    return EthiopianDate(
      et['year'] as int,
      et['month'] as int,
      et['day'] as int,
    );
  }

  factory EthiopianDate.fromDateTime(DateTime dt) {
    final kenat = Kenat.fromGregorian(dt.year, dt.month, dt.day);
    return EthiopianDate.fromKenat(kenat);
  }

  factory EthiopianDate.now() {
    return EthiopianDate.fromKenat(Kenat.now());
  }

  Kenat toKenat() {
    return Kenat.fromEthiopian(year, month, day);
  }

  DateTime toDateTime() {
    final greg = toKenat().getGregorian();
    return DateTime(
      greg['year'] as int,
      greg['month'] as int,
      greg['day'] as int,
    );
  }

  /// Adds [days] to this Ethiopian date.
  EthiopianDate addDays(int days) {
    if (days == 0) return this;
    final targetDt = toDateTime().add(Duration(days: days));
    return EthiopianDate.fromDateTime(targetDt);
  }

  /// Returns the difference in days: `this - other`.
  int differenceInDays(EthiopianDate other) {
    return toDateTime().difference(other.toDateTime()).inDays;
  }

  /// Weekday of this date: 0 = Sunday, 1 = Monday, 2 = Tuesday, 3 = Wednesday,
  /// 4 = Thursday, 5 = Friday, 6 = Saturday.
  int get weekday => toKenat().getWeekday();

  bool get isWednesday => weekday == 3;
  bool get isFriday => weekday == 5;

  @override
  int compareTo(EthiopianDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EthiopianDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// The seven canonical fasts of the Ethiopian Orthodox Tewahedo Church,
/// plus weekly Wednesday & Friday fasts.
enum FastType {
  tsomeNebiyat,   // Fast of the Prophets (Advent)
  tsomeGahad,     // Fast of Gahad (Eve of Christmas / Epiphany)
  tsomeNenewe,    // Fast of Nineveh
  abiyTsom,       // Great Lent
  tsomeHawariyat, // Fast of the Apostles
  tsomeFilseta,   // Fast of the Assumption
  tsomeDihnet,    // Weekly Wednesday & Friday fast (Fast of Salvation)
}

extension FastTypeX on FastType {
  String get nameAmharic => switch (this) {
        FastType.tsomeNebiyat => 'ጾመ ነቢያት',
        FastType.tsomeGahad => 'ጾመ ገሃድ',
        FastType.tsomeNenewe => 'ጾመ ነነዌ',
        FastType.abiyTsom => 'ዐቢይ ጾም',
        FastType.tsomeHawariyat => 'ጾመ ሐዋርያት',
        FastType.tsomeFilseta => 'ጾመ ፍልሰታ',
        FastType.tsomeDihnet => 'ጾመ ድህነት',
      };

  String get nameEnglish => switch (this) {
        FastType.tsomeNebiyat => 'Fast of the Prophets',
        FastType.tsomeGahad => 'Fast of Gahad',
        FastType.tsomeNenewe => 'Fast of Nineveh',
        FastType.abiyTsom => 'Great Lent',
        FastType.tsomeHawariyat => 'Fast of the Apostles',
        FastType.tsomeFilseta => 'Fast of the Assumption',
        FastType.tsomeDihnet => 'Fast of Salvation',
      };

  String get descriptionAmharic => switch (this) {
        FastType.tsomeNebiyat =>
          'ነቢያት የመሲሑን መወለድ እየተናፈቁ የጾሙት የገና ጾም (ከሕዳር 15 እስከ ታኅሣሥ 28/27)።',
        FastType.tsomeGahad =>
          'የገና እና የጥምቀት ዋዜማ ጾም፤ በበዓላት ዋዜማ የሚደረግ የትዕግሥት እና የጸሎት ጾም::',
        FastType.tsomeNenewe => 'የነነዌ ሰዎች ንስሐ የገቡበት የ3 ቀን ታላቅ የንስሐ ጾም::',
        FastType.abiyTsom =>
          'ጌታችን ኢየሱስ ክርስቶስ በገዳመ ቆሮንቶስ የጾመው የ55 ቀን ታላቅ የጾም እና የጸሎት ጊዜ::',
        FastType.tsomeHawariyat =>
          'ቅዱሳን ሐዋርያት መንፈስ ቅዱስን ከተቀበሉ በኋላ ለወንጌል አገልግሎት የተጉበት ጾም::',
        FastType.tsomeFilseta =>
          'የእመቤታችን ቅድስት ድንግል ማርያም የዕርገቷ እና የዕረፍቷ ጾም (ከነሐሴ 1 እስከ 16)::',
        FastType.tsomeDihnet =>
          'የረቡዕና የዓርብ ሳምንታዊ ጾም፤ የጌታችን ምክር እና ስቅለት የሚታሰብበት::',
      };

  String get descriptionEnglish => switch (this) {
        FastType.tsomeNebiyat =>
          'Advent fast commemorating the Prophets who foretold the Nativity of Christ (43 days).',
        FastType.tsomeGahad =>
          'Eve of Christmas and Epiphany fast observed with prayer and abstinence.',
        FastType.tsomeNenewe =>
          'Three-day fast commemorating the repentance of Nineveh.',
        FastType.abiyTsom =>
          'Great Lent observed for 55 days in preparation for the Holy Resurrection (Fasika).',
        FastType.tsomeHawariyat =>
          'Fast of the Apostles observed following the feast of Pentecost.',
        FastType.tsomeFilseta =>
          'Fast of the Assumption of the Blessed Virgin Mary (Nehase 1-16).',
        FastType.tsomeDihnet =>
          'Weekly Wednesday and Friday fast commemorating the betrayal and crucifixion of Christ.',
      };
}

/// A specific period during which a fast is observed.
@immutable
class FastPeriod {
  final FastType type;
  final String nameAmharic;
  final String nameEnglish;
  final EthiopianDate startDate;
  final EthiopianDate endDate;
  final bool isWeekly;

  const FastPeriod({
    required this.type,
    required this.nameAmharic,
    required this.nameEnglish,
    required this.startDate,
    required this.endDate,
    this.isWeekly = false,
  });

  bool contains(EthiopianDate date) {
    return date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FastPeriod &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          isWeekly == other.isWeekly;

  @override
  int get hashCode => Object.hash(type, startDate, endDate, isWeekly);
}

/// The status of fasting for a given Ethiopian date.
@immutable
class FastStatus {
  final bool isFasting;
  final List<FastPeriod> active; // can overlap, e.g. Wednesday during Lent
  final FastPeriod? next;
  final int? daysRemaining;

  const FastStatus({
    required this.isFasting,
    required this.active,
    this.next,
    this.daysRemaining,
  });
}

/// Returns all major annual fast periods for [year].
List<FastPeriod> fastPeriodsForYear(int year) {
  final periods = <FastPeriod>[];
  final bh = BahireHasab(year);

  // 1. Fast of the Prophets (ጾመ ነቢያት)
  // Hidar 15 to Tahsas 28 (or Tahsas 27 if year is leap year)
  final isLeap = year % 4 == 3;
  final endTahsasDay = isLeap ? 27 : 28;
  periods.add(FastPeriod(
    type: FastType.tsomeNebiyat,
    nameAmharic: FastType.tsomeNebiyat.nameAmharic,
    nameEnglish: FastType.tsomeNebiyat.nameEnglish,
    startDate: EthiopianDate(year, 3, 15),
    endDate: EthiopianDate(year, 4, endTahsasDay),
  ));

  // 2. Fast of Gahad (ጾመ ገሃድ)
  // Eve of Christmas (Tahsas 28 or 27) and Eve of Epiphany (Tir 10)
  periods.add(FastPeriod(
    type: FastType.tsomeGahad,
    nameAmharic: FastType.tsomeGahad.nameAmharic,
    nameEnglish: FastType.tsomeGahad.nameEnglish,
    startDate: EthiopianDate(year, 4, endTahsasDay),
    endDate: EthiopianDate(year, 4, endTahsasDay),
  ));
  periods.add(FastPeriod(
    type: FastType.tsomeGahad,
    nameAmharic: FastType.tsomeGahad.nameAmharic,
    nameEnglish: FastType.tsomeGahad.nameEnglish,
    startDate: EthiopianDate(year, 5, 10),
    endDate: EthiopianDate(year, 5, 10),
  ));

  // 3. Fast of Nineveh (ጾመ ነነዌ - 3 days)
  final neneweStart = bh.nenewe;
  final neneweEnd = neneweStart.addDays(2);
  periods.add(FastPeriod(
    type: FastType.tsomeNenewe,
    nameAmharic: FastType.tsomeNenewe.nameAmharic,
    nameEnglish: FastType.tsomeNenewe.nameEnglish,
    startDate: neneweStart,
    endDate: neneweEnd,
  ));

  // 4. Great Lent (ዐቢይ ጾም - 55 days)
  final fasika = bh.fasika;
  final abiyStart = fasika.addDays(-55);
  final abiyEnd = fasika.addDays(-1);
  periods.add(FastPeriod(
    type: FastType.abiyTsom,
    nameAmharic: FastType.abiyTsom.nameAmharic,
    nameEnglish: FastType.abiyTsom.nameEnglish,
    startDate: abiyStart,
    endDate: abiyEnd,
  ));

  // 5. Fast of the Apostles (ጾመ ሐዋርያት)
  // Starts the day after Pentecost (Fasika + 50 days) and ends Hamle 5 (Month 11, Day 5)
  final hawariyatStart = fasika.addDays(50);
  final hawariyatEnd = EthiopianDate(year, 11, 5);
  if (hawariyatStart.compareTo(hawariyatEnd) <= 0) {
    periods.add(FastPeriod(
      type: FastType.tsomeHawariyat,
      nameAmharic: FastType.tsomeHawariyat.nameAmharic,
      nameEnglish: FastType.tsomeHawariyat.nameEnglish,
      startDate: hawariyatStart,
      endDate: hawariyatEnd,
    ));
  }

  // 6. Fast of the Assumption (ጾመ ፍልሰታ)
  // Nehase 1 to Nehase 16
  periods.add(FastPeriod(
    type: FastType.tsomeFilseta,
    nameAmharic: FastType.tsomeFilseta.nameAmharic,
    nameEnglish: FastType.tsomeFilseta.nameEnglish,
    startDate: EthiopianDate(year, 12, 1),
    endDate: EthiopianDate(year, 12, 16),
  ));

  return periods;
}

/// Pure calculation of FastStatus for a given EthiopianDate.
FastStatus fastStatusFor(EthiopianDate date) {
  final bh = BahireHasab(date.year);
  final fasika = bh.fasika;
  final fiftyDaysStart = fasika;
  final fiftyDaysEnd = fasika.addDays(49);

  // Check if date is inside Fifty Days (፶ ሃምሳ)
  final inFiftyDays =
      date.compareTo(fiftyDaysStart) >= 0 && date.compareTo(fiftyDaysEnd) <= 0;

  // Major fasts for date.year + previous/next year to cover boundaries
  final allFasts = [
    ...fastPeriodsForYear(date.year - 1),
    ...fastPeriodsForYear(date.year),
    ...fastPeriodsForYear(date.year + 1),
  ];

  final active = <FastPeriod>[];

  // 1. Check major fasts active on date
  for (final p in allFasts) {
    if (p.contains(date) && !active.contains(p)) {
      active.add(p);
    }
  }

  // 2. Check weekly Wednesday/Friday fast (ጾመ ድህነት)
  if ((date.isWednesday || date.isFriday) && !inFiftyDays) {
    final dihnet = FastPeriod(
      type: FastType.tsomeDihnet,
      nameAmharic: FastType.tsomeDihnet.nameAmharic,
      nameEnglish: FastType.tsomeDihnet.nameEnglish,
      startDate: date,
      endDate: date,
      isWeekly: true,
    );
    if (!active.contains(dihnet)) {
      active.add(dihnet);
    }
  }

  final isFasting = active.isNotEmpty;

  if (isFasting) {
    // Days remaining in the primary (usually major) active fast
    final primary = active.firstWhere((p) => !p.isWeekly, orElse: () => active.first);
    final remaining = primary.endDate.differenceInDays(date) + 1;
    return FastStatus(
      isFasting: true,
      active: active,
      daysRemaining: remaining > 0 ? remaining : 1,
    );
  }

  // Not fasting — find next upcoming fast
  FastPeriod? nextPeriod;
  int? daysUntil;

  // Search upcoming major fasts or weekly fasts after date
  // Generate candidate upcoming periods
  final upcomingCandidates = <FastPeriod>[];

  for (final p in allFasts) {
    if (p.startDate.compareTo(date) > 0) {
      upcomingCandidates.add(p);
    }
  }

  // Check upcoming weekly fasts within next 7 days
  for (var i = 1; i <= 7; i++) {
    final futureDate = date.addDays(i);
    final fBh = BahireHasab(futureDate.year);
    final fFasika = fBh.fasika;
    final fInFifty = futureDate.compareTo(fFasika) >= 0 &&
        futureDate.compareTo(fFasika.addDays(49)) <= 0;

    if ((futureDate.isWednesday || futureDate.isFriday) && !fInFifty) {
      upcomingCandidates.add(FastPeriod(
        type: FastType.tsomeDihnet,
        nameAmharic: FastType.tsomeDihnet.nameAmharic,
        nameEnglish: FastType.tsomeDihnet.nameEnglish,
        startDate: futureDate,
        endDate: futureDate,
        isWeekly: true,
      ));
    }
  }

  upcomingCandidates.sort((a, b) => a.startDate.compareTo(b.startDate));

  if (upcomingCandidates.isNotEmpty) {
    nextPeriod = upcomingCandidates.first;
    daysUntil = nextPeriod.startDate.differenceInDays(date);
  }

  return FastStatus(
    isFasting: false,
    active: const [],
    next: nextPeriod,
    daysRemaining: daysUntil,
  );
}
