import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/core/deep_links/deep_link_uri.dart';
import 'package:bibleflutter/core/home_widget/home_widget_service.dart';
import 'package:bibleflutter/core/home_widget/widget_appearance.dart';
import 'package:bibleflutter/core/l10n/am_strings.dart';
import 'package:bibleflutter/core/l10n/en_strings.dart';
import 'package:bibleflutter/core/l10n/verse_ref.dart';
import 'package:bibleflutter/core/settings/app_settings.dart';
import 'package:bibleflutter/features/books/data/models/book_index_entry.dart';
import 'package:bibleflutter/features/books/data/reading_models.dart';
import 'package:bibleflutter/features/books/data/repositories/bible_repository.dart';

const _jer = BookIndexEntry(
  id: 'JER',
  bookNumber: 24,
  bookNameAm: 'ትንቢተ ኤርምያስ',
  bookNameEn: 'Jeremiah',
  bookShortNameAm: 'ኤር',
  bookShortNameEn: 'Jer',
  testament: 'old',
  chapterCount: 52,
);

const _kings = BookIndexEntry(
  id: '1KI',
  bookNumber: 11,
  bookNameAm: 'መጽሐፈ ነገሥት ቀዳማዊ',
  bookNameEn: '1 Kings',
  bookShortNameAm: '1 ነገ',
  bookShortNameEn: '1 Kgs',
  testament: 'old',
  chapterCount: 22,
);

final _dailyVerse = DailyVerseResult(
  text: 'እኔ ስለ እናንተ የማስበውን አሳብ አውቃለሁና',
  bookNameAm: 'ትንቢተ ኤርምያስ',
  bookNameEn: 'Jeremiah',
  chapter: 29,
  verse: 11,
  bookEntry: _jer,
);

({BookIndexEntry entry, ReadingPosition position, int progress}) _continue({
  int chapter = 8,
  int? verse = 22,
  int progress = 36,
}) =>
    (
      entry: _kings,
      position: ReadingPosition(
        bookId: '1KI',
        chapter: chapter,
        verse: verse,
        updatedAtMs: 0,
      ),
      progress: progress,
    );

void main() {
  group('AppRoute deep links', () {
    test('parses the streak route from the custom scheme', () {
      expect(
        parseAppRoute(Uri.parse('eotcbible://openinapp/streak')),
        AppRoute.streak,
      );
    });

    test('parses the streak route from the https app link', () {
      expect(
        parseAppRoute(
          Uri.parse('https://80-weahadu.vercel.app/openinapp/streak'),
        ),
        AppRoute.streak,
      );
    });

    test('is case insensitive', () {
      expect(
        parseAppRoute(Uri.parse('eotcbible://openinapp/STREAK')),
        AppRoute.streak,
      );
    });

    test('appRouteUri round-trips', () {
      expect(parseAppRoute(appRouteUri(AppRoute.streak)), AppRoute.streak);
    });

    test('a verse slug is not a route', () {
      expect(parseAppRoute(Uri.parse('eotcbible://openinapp/jer29_11')), isNull);
    });

    test('an unknown slug is not a route', () {
      expect(parseAppRoute(Uri.parse('eotcbible://openinapp/nope')), isNull);
      expect(parseAppRoute(Uri.parse('https://example.com/streak')), isNull);
    });

    // The whole reason routes are a separate vocabulary: adding one must not
    // shadow a book abbreviation. `streak` has no trailing {chapter}_{verse},
    // so the verse regex rejects it and the two can never collide.
    test('route slugs cannot collide with the verse slug format', () {
      for (final route in AppRoute.values) {
        expect(
          parseDeepLink(appRouteUri(route), const [_jer, _kings]),
          isNull,
          reason: '${route.slug} must not parse as a verse',
        );
      }
    });

    test('verse links still resolve unchanged', () {
      final target =
          parseDeepLink(Uri.parse('eotcbible://openinapp/jer29_11'), const [_jer]);
      expect(target, isNotNull);
      expect(target!.entry.id, 'JER');
      expect(target.chapter, 29);
      expect(target.verse, 11);
    });
  });

  group('buildHomeWidgetData', () {
    test('renders Amharic names and Latin numerals by default', () {
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: _continue(),
        streakCount: 12,
      );

      expect(data.verseRef, 'ትንቢተ ኤርምያስ 29:11');
      // The corner reference stays Latin whatever the app language is — it is
      // the compact counterpart to the Amharic one, not a second copy of it.
      expect(data.verseRefShort, 'JER 29:11');
      expect(data.continueBook, 'መጽሐፈ ነገሥት ቀዳማዊ');
      expect(data.continueRef, 'ምዕ. 8');
      expect(data.streakCountLabel, '12');
      expect(data.streakSuffix, 'ቀናት');
    });

    test('renders English names when the app is in English', () {
      final data = buildHomeWidgetData(
        s: const EnStrings(),
        useGeezNumbers: false,
        isAmharic: false,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: _continue(),
        streakCount: 12,
      );

      expect(data.verseRef, 'Jeremiah 29:11');
      expect(data.continueBook, '1 Kings');
      expect(data.continueRef, 'chs. 8');
      expect(data.streakSuffix, 'days');
    });

    test('converts every number to Ge\'ez when that setting is on', () {
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: true,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: _continue(),
        streakCount: 12,
      );

      // The label is what the widget draws, so it must carry the Ge'ez form...
      expect(data.streakCountLabel, '፲፪');
      expect(data.verseRef, contains('፳፱'));
      expect(data.continueRef, contains('፰'));
      // ...while the int stays Latin for the Kotlin side's empty-state check.
      expect(data.streakCount, 12);
      // The corner reference is Latin by design and does not follow the
      // numeral setting; Ge'ez digits there would collide with the
      // abbreviated book name in the space the corner has.
      expect(data.verseRefShort, 'JER 29:11');
    });

    test('the streak count and its suffix are separate fields', () {
      // They are drawn on two different lines at two different sizes. A
      // combined "12 ቀናት" string would print the number twice.
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: _continue(),
        streakCount: 12,
      );
      expect(data.streakSuffix, isNot(contains('12')));
    });

    test('deep links point at the verse and the position they show', () {
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: _continue(chapter: 8, verse: 22),
        streakCount: 3,
      );

      expect(data.verseDeepLink, endsWith('/openinapp/jer29_11'));
      expect(data.continueDeepLink, endsWith('/openinapp/1kgs8_22'));
      expect(data.streakDeepLink, 'eotcbible://openinapp/streak');
    });

    // A book opened but never scrolled has no stored verse. The link still has
    // to be well-formed or the reader reports it as broken.
    test('a position with no verse still links to a valid verse slug', () {
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: null,
        continueReading: _continue(chapter: 8, verse: null),
        streakCount: 0,
      );

      expect(data.continueDeepLink, endsWith('/openinapp/1kgs8_1'));
      expect(
        parseDeepLink(Uri.parse(data.continueDeepLink), const [_kings]),
        isNotNull,
      );
    });

    test('empty state leaves the verse and continue fields blank', () {
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: null,
        continueReading: null,
        streakCount: 0,
      );

      expect(data.verseText, isEmpty);
      expect(data.verseRef, isEmpty);
      expect(data.verseRefShort, isEmpty);
      expect(data.verseDeepLink, isEmpty);
      expect(data.continueBook, isEmpty);
      expect(data.continueDeepLink, isEmpty);
      expect(data.continueProgress, 0);
      // The streak link is static, so it survives having no data at all.
      expect(data.streakDeepLink, isNotEmpty);
    });

    test('long verses are cut on a word boundary, not mid-word', () {
      // Comfortably past the budget rather than just over it, so the test
      // keeps testing the cut if the budget is retuned for a larger widget.
      final long = List.filled(400, 'ቃል').join(' ');
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: DailyVerseResult(
          text: long,
          bookNameAm: 'ትንቢተ ኤርምያስ',
          bookNameEn: 'Jeremiah',
          chapter: 29,
          verse: 11,
          bookEntry: _jer,
        ),
        continueReading: null,
        streakCount: 0,
      );

      expect(data.verseText.length, lessThan(long.length));
      expect(data.verseText, endsWith('…'));
      // The character before the ellipsis is the end of a word, never a space.
      final beforeEllipsis =
          data.verseText.substring(0, data.verseText.length - 1);
      expect(beforeEllipsis, isNot(endsWith(' ')));
    });

    test('a short verse is passed through untouched', () {
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: null,
        streakCount: 0,
      );
      expect(data.verseText, _dailyVerse.text);
    });

    test('the chosen emoji is carried straight through', () {
      final data = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '👑',
        dailyVerse: null,
        continueReading: null,
        streakCount: 100,
      );
      expect(data.streakEmoji, '👑');
    });
  });

  group('HomeWidgetData wire format', () {
    // Every key here is read by name in WidgetKeys.kt. A rename on one side
    // alone is silent — the Kotlin getter falls back to its default and the
    // widget shows placeholder text forever.
    test('writes exactly the keys the Kotlin side reads', () {
      final entries = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: _continue(),
        streakCount: 12,
      ).toWidgetEntries();

      expect(
        entries.keys.toSet(),
        {
          'verse_text',
          'verse_ref',
          'verse_ref_short',
          'verse_deeplink',
          'continue_book',
          'continue_ref',
          'continue_progress',
          'continue_deeplink',
          'streak_count',
          'streak_count_label',
          'streak_emoji',
          'streak_suffix',
          'streak_deeplink',
        },
      );
    });

    // home_widget maps Dart types onto SharedPreferences putters. An int
    // written where Kotlin calls getString throws ClassCastException inside
    // the launcher, which surfaces as a widget that will not load.
    test('progress and streak count are ints, everything else is a string', () {
      final entries = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: _continue(),
        streakCount: 12,
      ).toWidgetEntries();

      expect(entries['continue_progress'], isA<int>());
      expect(entries['streak_count'], isA<int>());
      for (final key in entries.keys
          .where((k) => k != 'continue_progress' && k != 'streak_count')) {
        expect(entries[key], isA<String>(), reason: '$key must be a String');
      }
    });
  });

  group('shortVerseRef', () {
    test('abbreviates a one-word book to three letters', () {
      expect(shortVerseRef('Jeremiah', 29, 11), 'JER 29:11');
    });

    // "1 Corinthians" must keep its ordinal, or 1 and 2 Corinthians become
    // the same reference.
    test('keeps the ordinal on a numbered book', () {
      expect(shortVerseRef('1 Corinthians', 13, 4), '1 COR 13:4');
    });

    test('leaves a book already three letters or shorter alone', () {
      expect(shortVerseRef('Job', 1, 21), 'JOB 1:21');
    });
  });

  group('widget appearance', () {
    test('the daily verse defaults to the brand card, the others to auto', () {
      // The widget is meant to be the home screen's daily verse card, and
      // that card is maroon. The other two have no on-screen counterpart to
      // match, so they follow the launcher.
      const appearance = HomeWidgetAppearance();
      expect(appearance.dailyVerse.theme, WidgetTheme.brand);
      expect(appearance.continueReading.theme, WidgetTheme.auto);
      expect(appearance.streak.theme, WidgetTheme.auto);
    });

    test('withStyle replaces one widget and leaves the others alone', () {
      const appearance = HomeWidgetAppearance();
      final updated = appearance.withStyle(
        HomeWidgetKind.streak,
        const WidgetStyle(theme: WidgetTheme.dark),
      );

      expect(updated.streak.theme, WidgetTheme.dark);
      expect(updated.dailyVerse, appearance.dailyVerse);
      expect(updated.continueReading, appearance.continueReading);
    });

    // Zero is a setting, not a floor to defend against: only the card fades,
    // so a fully transparent background leaves the text on the wallpaper.
    test('opacity spans a fully transparent card to a solid one', () {
      const style = WidgetStyle();
      expect(style.copyWith(opacity: 0).opacity, 0);
      expect(style.copyWith(opacity: 55).opacity, 55);
      expect(style.copyWith(opacity: 100).opacity, 100);
      expect(style.copyWith(opacity: -10).opacity, 0);
      expect(style.copyWith(opacity: 300).opacity, 100);
    });

    // Every key here is read by name in WidgetStyle.kt, which builds it from
    // the prefix plus the field name. A prefix renamed on one side alone is
    // silent: the Kotlin getter falls back to its default and the widget
    // ignores the setting forever.
    test('writes exactly the style keys the Kotlin side reads', () {
      final keys = const HomeWidgetAppearance().toWidgetEntries().keys.toSet();

      expect(keys, {
        for (final prefix in ['verse', 'continue', 'streak'])
          for (final name in ['theme', 'scale', 'opacity', 'label', 'detail'])
            '${prefix}_style_$name',
      });
    });

    // The style keys share a preference file with the content keys. A prefix
    // that collided with a content key would have one overwrite the other.
    test('style keys cannot collide with content keys', () {
      final content = buildHomeWidgetData(
        s: const AmStrings(),
        useGeezNumbers: false,
        isAmharic: true,
        streakEmoji: '🔥',
        dailyVerse: _dailyVerse,
        continueReading: _continue(),
        streakCount: 12,
      ).toWidgetEntries().keys.toSet();

      expect(
        const HomeWidgetAppearance()
            .toWidgetEntries()
            .keys
            .toSet()
            .intersection(content),
        isEmpty,
      );
    });

    // Kotlin reads the enums with `getString` and the toggles with `getInt`.
    // A bool written where getInt is called throws ClassCastException inside
    // the launcher, which surfaces as a widget that will not load.
    test('enums go over as strings and toggles as ints', () {
      final entries = const HomeWidgetAppearance().toWidgetEntries();

      expect(entries['verse_style_theme'], 'brand');
      expect(entries['verse_style_scale'], 'medium');
      expect(entries['verse_style_opacity'], isA<int>());
      expect(entries['verse_style_label'], 1);
      expect(entries['verse_style_detail'], 1);
    });

    test('an unknown or missing wire name reads as the safe default', () {
      expect(WidgetTheme.parse('chartreuse'), WidgetTheme.auto);
      expect(WidgetTheme.parse(null), WidgetTheme.auto);
      expect(WidgetTextScale.parse('enormous'), WidgetTextScale.medium);
      expect(WidgetTextScale.parse(null), WidgetTextScale.medium);
    });

    test('every wire name round-trips', () {
      for (final theme in WidgetTheme.values) {
        expect(WidgetTheme.parse(theme.wireName), theme);
      }
      for (final scale in WidgetTextScale.values) {
        expect(WidgetTextScale.parse(scale.wireName), scale);
      }
    });
  });

  group('streak emoji setting', () {
    test('defaults to the flame', () {
      expect(const AppSettings().streakEmoji, kDefaultStreakEmoji);
      expect(kStreakEmojiChoices, contains(kDefaultStreakEmoji));
    });

    test('copyWith keeps a supported choice', () {
      expect(const AppSettings().copyWith(streakEmoji: '👑').streakEmoji, '👑');
    });

    // The value is drawn by the launcher's system emoji font. Anything outside
    // the vetted set risks a blank box on the home screen, so it is coerced
    // back rather than trusted.
    test('an unsupported emoji falls back to the default', () {
      expect(
        const AppSettings().copyWith(streakEmoji: '🦄').streakEmoji,
        kDefaultStreakEmoji,
      );
      expect(
        const AppSettings().copyWith(streakEmoji: '').streakEmoji,
        kDefaultStreakEmoji,
      );
    });

    test('survives a map round trip', () {
      const settings = AppSettings(streakEmoji: '✨');
      expect(AppSettings.fromMap(settings.toMap()).streakEmoji, '✨');
    });

    test('a map with no emoji key reads as the default', () {
      expect(AppSettings.fromMap(const {}).streakEmoji, kDefaultStreakEmoji);
    });

    test('participates in equality', () {
      expect(
        const AppSettings(streakEmoji: '🔥'),
        isNot(const AppSettings(streakEmoji: '⚡')),
      );
    });
  });
}
