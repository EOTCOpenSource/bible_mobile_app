import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/features/fasting/data/bahire_hasab.dart';
import 'package:bibleflutter/features/fasting/data/fasts.dart';


void main() {
  group('BahireHasab Tests', () {
    test('Calculates Fasika and Nineveh for 2016 EE', () {
      final bh = BahireHasab(2016);
      final nenewe = bh.nenewe;
      final fasika = bh.fasika;

      // 2016 EE Nineveh was Yekatit 18, 2016 (Feb 26, 2024)
      expect(nenewe.year, 2016);
      expect(nenewe.month, 6); // Yekatit
      expect(nenewe.day, 18);

      // Fasika is 69 days after Nineveh -> Miazia 27, 2016 (May 5, 2024)
      expect(fasika.year, 2016);
      expect(fasika.month, 8); // Miazia
      expect(fasika.day, 27);
      expect(fasika.differenceInDays(nenewe), 69);
    });

    test('Calculates Fasika and Nineveh for 2015 EE', () {
      final bh = BahireHasab(2015);
      final nenewe = bh.nenewe;
      final fasika = bh.fasika;

      expect(nenewe.year, 2015);
      expect(fasika.year, 2015);
      expect(fasika.differenceInDays(nenewe), 69);
    });

    test('Calculates Fasika and Nineveh for 2017 EE', () {
      final bh = BahireHasab(2017);
      final nenewe = bh.nenewe;
      final fasika = bh.fasika;

      expect(nenewe.year, 2017);
      expect(fasika.year, 2017);
      expect(fasika.differenceInDays(nenewe), 69);
    });
  });

  group('fastStatusFor Unit Tests (20+ Historical & Edge Case Dates)', () {
    test('1. Wednesday inside Fifty Days after Fasika is NOT a fast day', () {
      final bh = BahireHasab(2016);
      final fasika = bh.fasika;
      // Fasika + 10 days is a Wednesday inside Fifty Days
      final wedInFiftyDays = fasika.addDays(10);
      expect(wedInFiftyDays.isWednesday || wedInFiftyDays.isFriday, isTrue);

      final status = fastStatusFor(wedInFiftyDays);
      expect(status.isFasting, isFalse);
      expect(status.active, isEmpty);
    });

    test('2. Wednesday outside Fifty Days IS a fast day (tsomeDihnet)', () {
      // Meskerem 2, 2016 is a Wednesday
      final date = EthiopianDate(2016, 1, 2);
      expect(date.isWednesday, isTrue);

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeDihnet), isTrue);
    });

    test('3. Friday outside Fifty Days IS a fast day (tsomeDihnet)', () {
      // Meskerem 4, 2016 is a Friday
      final date = EthiopianDate(2016, 1, 4);
      expect(date.isFriday, isTrue);

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeDihnet), isTrue);
    });


    test('4. First day of Great Lent (abiyTsom)', () {
      final bh = BahireHasab(2016);
      final fasika = bh.fasika;
      final firstDayLent = fasika.addDays(-55);

      final status = fastStatusFor(firstDayLent);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.abiyTsom), isTrue);
      expect(status.daysRemaining, 55);
    });

    test('5. Last day of Great Lent (abiyTsom)', () {
      final bh = BahireHasab(2016);
      final fasika = bh.fasika;
      final lastDayLent = fasika.addDays(-1);

      final status = fastStatusFor(lastDayLent);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.abiyTsom), isTrue);
      expect(status.daysRemaining, 1);
    });

    test('6. Day in middle of Great Lent calculating remaining days', () {
      final bh = BahireHasab(2016);
      final fasika = bh.fasika;
      // 23 days before Fasika (Miazia 4, 2016)
      final midLentDate = fasika.addDays(-23);

      final status = fastStatusFor(midLentDate);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.abiyTsom), isTrue);
      expect(status.daysRemaining, 23);
    });

    test('7. Wednesday during Great Lent (Overlapping abiyTsom & tsomeDihnet)', () {
      final bh = BahireHasab(2016);
      final fasika = bh.fasika;
      // Find a Wednesday during Great Lent
      var date = fasika.addDays(-20);
      while (!date.isWednesday) {
        date = date.addDays(-1);
      }

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.abiyTsom), isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeDihnet), isTrue);
      expect(status.active.length, greaterThanOrEqualTo(2));
    });

    test('8. Fast of the Prophets (tsomeNebiyat) first day (Hidar 15)', () {
      final date = EthiopianDate(2016, 3, 15);
      final status = fastStatusFor(date);

      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeNebiyat), isTrue);
    });

    test('9. Fast of the Prophets (tsomeNebiyat) last day (Tahsas 28 in non-leap year)', () {
      final date = EthiopianDate(2016, 4, 28);
      final status = fastStatusFor(date);

      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeNebiyat), isTrue);
    });

    test('10. Fast of the Prophets (tsomeNebiyat) last day (Tahsas 27 in leap year 2015 EE)', () {
      // 2015 EE is a leap year (2015 % 4 == 3)
      final date = EthiopianDate(2015, 4, 27);
      final status = fastStatusFor(date);

      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeNebiyat), isTrue);
    });

    test('11. Fast of Gahad of Lidet', () {
      final date = EthiopianDate(2016, 4, 28);
      final status = fastStatusFor(date);

      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeGahad), isTrue);
    });

    test('12. Fast of Gahad of Timkat (Tir 10)', () {
      final date = EthiopianDate(2016, 5, 10);
      final status = fastStatusFor(date);

      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeGahad), isTrue);
    });

    test('13. Fast of Nineveh (tsomeNenewe) first day', () {
      final bh = BahireHasab(2016);
      final date = bh.nenewe;

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeNenewe), isTrue);
    });

    test('14. Fast of Nineveh (tsomeNenewe) last day (Wednesday)', () {
      final bh = BahireHasab(2016);
      final date = bh.nenewe.addDays(2);

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeNenewe), isTrue);
    });

    test('15. Fast of the Apostles (tsomeHawariyat) start day (Fasika + 50)', () {
      final bh = BahireHasab(2016);
      final date = bh.fasika.addDays(50);

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeHawariyat), isTrue);
    });

    test('16. Fast of the Apostles (tsomeHawariyat) end day (Hamle 5)', () {
      final date = EthiopianDate(2016, 11, 5);

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeHawariyat), isTrue);
    });

    test('17. Fast of the Assumption (tsomeFilseta) start day (Nehase 1)', () {
      final date = EthiopianDate(2016, 12, 1);

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeFilseta), isTrue);
    });

    test('18. Fast of the Assumption (tsomeFilseta) end day (Nehase 16)', () {
      final date = EthiopianDate(2016, 12, 16);

      final status = fastStatusFor(date);
      expect(status.isFasting, isTrue);
      expect(status.active.any((p) => p.type == FastType.tsomeFilseta), isTrue);
    });

    test('19. Pagume 1 (13/1) non-fasting weekday', () {
      // Find Pagume day that is not Wed/Fri
      var date = EthiopianDate(2016, 13, 1);
      if (date.isWednesday || date.isFriday) {
        date = EthiopianDate(2016, 13, 2);
      }

      final status = fastStatusFor(date);
      expect(status.isFasting, isFalse);
    });

    test('20. Pagume 6 (13/6) in leap year (2015 EE)', () {
      final date = EthiopianDate(2015, 13, 6);
      final status = fastStatusFor(date);

      // Unless it happens to be Wed/Fri, Pagume 6 is not a canonical fast
      if (date.isWednesday || date.isFriday) {
        expect(status.isFasting, isTrue);
      } else {
        expect(status.isFasting, isFalse);
      }
    });

    test('21. Non-fasting Tuesday date shows correct next fast countdown', () {
      // Meskerem 1, 2016 is a Tuesday outside any major fast
      final date = EthiopianDate(2016, 1, 1);
      expect(date.isWednesday || date.isFriday, isFalse);

      final status = fastStatusFor(date);
      expect(status.isFasting, isFalse);
      expect(status.next, isNotNull);
      expect(status.daysRemaining, 1); // Next fast is Wednesday (1 day away)
    });

  });
}
