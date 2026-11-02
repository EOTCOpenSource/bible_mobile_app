import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('default constructor sets expected default values', () {
      const settings = AppSettings();
      expect(settings.useGeezNumbers, false);
      expect(settings.bodyFontIndex, 0);
      expect(settings.titleFontIndex, 0);
      expect(settings.fontSize, 17.0);
      expect(settings.isDarkReader, false);
      expect(settings.continuousReading, false);
      expect(settings.dailyVerseNotificationEnabled, false);
      expect(settings.readingTimeNotificationEnabled, false);
    });

    test('copyWith with no arguments returns an equal object', () {
      const s1 = AppSettings(
        useGeezNumbers: true,
        fontSize: 19.5,
        isDarkReader: true,
        dailyVerseNotificationTime: TimeOfDay(hour: 7, minute: 30),
      );
      final s2 = s1.copyWith();
      expect(s2, equals(s1));
      expect(s2.hashCode, equals(s1.hashCode));
    });

    test('copyWith updates individual fields while preserving others', () {
      const initial = AppSettings(
        useGeezNumbers: false,
        fontSize: 16.0,
        isDarkReader: false,
        bodyFontIndex: 1,
      );

      final updatedGeez = initial.copyWith(useGeezNumbers: true);
      expect(updatedGeez.useGeezNumbers, true);
      expect(updatedGeez.fontSize, 16.0);
      expect(updatedGeez.isDarkReader, false);
      expect(updatedGeez.bodyFontIndex, 1);

      final updatedSize = initial.copyWith(fontSize: 22.0);
      expect(updatedSize.useGeezNumbers, false);
      expect(updatedSize.fontSize, 22.0);

      final updatedDark = initial.copyWith(isDarkReader: true);
      expect(updatedDark.isDarkReader, true);
      expect(updatedDark.fontSize, 16.0);
    });

    test('TimeOfDayX extension formats time correctly', () {
      const morning = TimeOfDay(hour: 6, minute: 0);
      const evening = TimeOfDay(hour: 20, minute: 15);
      expect(morning.formatted, '6:00 AM');
      expect(evening.formatted, '8:15 PM');
    });
  });
}
