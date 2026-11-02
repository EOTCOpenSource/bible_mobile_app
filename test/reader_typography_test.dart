import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/features/books/presentation/widgets/reader/reader_style_resolver.dart';

void main() {
  group('AppSettings typography fields', () {
    test('default values match deliverable specs', () {
      final settings = AppSettings();
      expect(settings.lineHeight, equals(1.6));
      expect(settings.marginScale, equals(1.0));
      expect(settings.textAlign, equals(0));
      expect(settings.keepScreenOn, equals(false));
    });

    test('copyWith updates typography settings', () {
      final settings = AppSettings();
      final updated = settings.copyWith(
        lineHeight: 1.8,
        marginScale: 1.2,
        textAlign: 1,
        keepScreenOn: true,
      );

      expect(updated.lineHeight, equals(1.8));
      expect(updated.marginScale, equals(1.2));
      expect(updated.textAlign, equals(1));
      expect(updated.keepScreenOn, equals(true));
      expect(settings.lineHeight, equals(1.6)); // immutable
    });

    test('equality and hashCode include typography fields', () {
      final settingsA = AppSettings(
        lineHeight: 1.8,
        marginScale: 1.2,
        textAlign: 1,
        keepScreenOn: true,
      );
      final settingsB = AppSettings(
        lineHeight: 1.8,
        marginScale: 1.2,
        textAlign: 1,
        keepScreenOn: true,
      );
      final settingsC = AppSettings(
        lineHeight: 1.6,
        marginScale: 1.2,
        textAlign: 1,
        keepScreenOn: true,
      );

      expect(settingsA, equals(settingsB));
      expect(settingsA.hashCode, equals(settingsB.hashCode));
      expect(settingsA, isNot(equals(settingsC)));
    });

    test('serializes to map with all four new fields present', () {
      final settings = AppSettings(
        lineHeight: 1.8,
        marginScale: 1.4,
        textAlign: 1,
        keepScreenOn: true,
      );
      final map = settings.toMap();

      expect(map['lineHeight'], equals(1.8));
      expect(map['marginScale'], equals(1.4));
      expect(map['textAlign'], equals(1));
      expect(map['keepScreenOn'], equals(true));
    });

    test('deserializes from map with missing fields using defaults (migration safety)', () {
      final map = <String, dynamic>{
        'fontSize': 19.0,
        'isDarkReader': true,
      };
      final deserialized = AppSettings.fromMap(map);

      expect(deserialized.fontSize, equals(19.0));
      expect(deserialized.isDarkReader, equals(true));
      expect(deserialized.lineHeight, equals(1.6));
      expect(deserialized.marginScale, equals(1.0));
      expect(deserialized.textAlign, equals(0));
      expect(deserialized.keepScreenOn, equals(false));
    });

    test('clamps lineHeight and marginScale to allowed ranges', () {
      final low = const AppSettings().copyWith(lineHeight: 0.5, marginScale: 0.2);
      expect(low.lineHeight, equals(1.2));
      expect(low.marginScale, equals(0.6));

      final high = const AppSettings().copyWith(lineHeight: 3.5, marginScale: 2.5);
      expect(high.lineHeight, equals(2.2));
      expect(high.marginScale, equals(1.6));
    });
  });

  group('ReaderStyleResolver typography computations', () {
    test('computeBodyStyle sets font, size, and line height', () {
      final style = ReaderStyleResolver.computeBodyStyle(
        fontFamily: 'NotoSerifEthiopic',
        fontSize: 18.0,
        lineHeight: 1.8,
        textColor: Colors.black,
      );

      expect(style.fontFamily, equals('NotoSerifEthiopic'));
      expect(style.fontSize, equals(18.0));
      expect(style.height, equals(1.8));
      expect(style.color, equals(Colors.black));
    });

    test('computeBodyPadding scales padding based on marginScale', () {
      final paddingNormal = ReaderStyleResolver.computeBodyPadding(
        marginScale: 1.0,
        top: 16.0,
        bottom: 80.0,
      );
      final paddingWide = ReaderStyleResolver.computeBodyPadding(
        marginScale: 1.5,
        top: 16.0,
        bottom: 80.0,
      );

      expect(paddingWide.left, greaterThan(paddingNormal.left));
      expect(paddingWide.right, greaterThan(paddingNormal.right));
      expect(paddingNormal.left, equals(20.0));
      expect(paddingNormal.right, equals(20.0));
      expect(paddingNormal.top, equals(16.0));
      expect(paddingNormal.bottom, equals(80.0));
    });

    test('computeTextAlign returns start for index 0 and justify for index 1 on normal screens', () {
      final startAlign = ReaderStyleResolver.computeTextAlign(
        textAlign: 0,
        screenWidth: 400,
      );
      final justifyAlign = ReaderStyleResolver.computeTextAlign(
        textAlign: 1,
        screenWidth: 400,
      );

      expect(startAlign, equals(TextAlign.start));
      expect(justifyAlign, equals(TextAlign.justify));
    });

    test('computeTextAlign forces TextAlign.start on narrow screens (<340px)', () {
      final justifyAlignOnNarrow = ReaderStyleResolver.computeTextAlign(
        textAlign: 1,
        screenWidth: 320,
      );

      expect(justifyAlignOnNarrow, equals(TextAlign.start));
    });
  });
}
