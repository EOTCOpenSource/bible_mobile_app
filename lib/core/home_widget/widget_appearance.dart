import 'package:flutter/foundation.dart';

/// The three Android home screen widgets, as the settings page enumerates them.
///
/// The order here is the order of the chooser strip — daily verse first because
/// it is the one most people add, streak last because it is the smallest.
enum HomeWidgetKind {
  dailyVerse('verse'),
  continueReading('continue'),
  streak('streak');

  const HomeWidgetKind(this.prefix);

  /// The shared-preference key prefix this widget's style is written under,
  /// matching `WidgetStyleKeys` in `WidgetStyle.kt`.
  final String prefix;
}

/// Which palette a widget draws itself in.
///
/// [auto] follows the launcher's own light/dark setting, which is what most
/// widgets do; the other three are fixed so a widget can be made legible
/// against a wallpaper the system mode disagrees with. [brand] is the maroon
/// card the app's home screen uses.
enum WidgetTheme {
  auto('auto'),
  light('light'),
  dark('dark'),
  brand('brand');

  const WidgetTheme(this.wireName);

  final String wireName;

  static WidgetTheme parse(String? name) => WidgetTheme.values.firstWhere(
        (t) => t.wireName == name,
        orElse: () => WidgetTheme.auto,
      );
}

/// A multiplier on every text size in a widget.
///
/// Coarse rather than a free slider: the launcher gives a widget a fixed
/// number of cells, and a size between these steps changes how many lines fit
/// without changing how the card reads.
enum WidgetTextScale {
  small('small', 0.85),
  medium('medium', 1.0),
  large('large', 1.18);

  const WidgetTextScale(this.wireName, this.factor);

  final String wireName;
  final double factor;

  static WidgetTextScale parse(String? name) =>
      WidgetTextScale.values.firstWhere(
        (s) => s.wireName == name,
        orElse: () => WidgetTextScale.medium,
      );
}

/// How one widget is drawn, independent of what it says.
///
/// Kept apart from [HomeWidgetData] on purpose: the content changes every day
/// and is pushed on every resume, while this changes only when the user asks
/// for it and has to survive the app never being opened again.
@immutable
class WidgetStyle {
  const WidgetStyle({
    this.theme = WidgetTheme.auto,
    this.textScale = WidgetTextScale.medium,
    this.opacity = 100,
    this.showLabel = true,
    this.showDetail = true,
  });

  final WidgetTheme theme;
  final WidgetTextScale textScale;

  /// Background opacity in percent, 0–100, clamped on the way in.
  ///
  /// Only the card behind the text fades — the text itself never does. Zero is
  /// therefore a real setting rather than an invisible widget: it leaves the
  /// verse standing directly on the wallpaper, which is what a transparent
  /// widget is usually asked for.
  final int opacity;

  /// The small caption line: the "የዕለቱ ቃል" tag, the "ንባብ ቀጥል" label, or the
  /// "ቀናት" suffix under the streak count.
  final bool showLabel;

  /// The widget's second element: the reference line under the verse, the
  /// progress bar under the book name, or the emoji above the streak count.
  final bool showDetail;

  WidgetStyle copyWith({
    WidgetTheme? theme,
    WidgetTextScale? textScale,
    int? opacity,
    bool? showLabel,
    bool? showDetail,
  }) =>
      WidgetStyle(
        theme: theme ?? this.theme,
        textScale: textScale ?? this.textScale,
        opacity: (opacity ?? this.opacity).clamp(0, 100),
        showLabel: showLabel ?? this.showLabel,
        showDetail: showDetail ?? this.showDetail,
      );

  /// The entries this style contributes to the widget preferences, under
  /// [prefix].
  ///
  /// Booleans go over as 0/1 ints rather than as `bool`: the Kotlin side reads
  /// every style value with `getInt`/`getString`, and a `getBoolean` on a key
  /// that was never written throws nothing but silently returns false, which
  /// would hide the label on a fresh install.
  Map<String, Object> toWidgetEntries(String prefix) => {
        '${prefix}_style_theme': theme.wireName,
        '${prefix}_style_scale': textScale.wireName,
        '${prefix}_style_opacity': opacity,
        '${prefix}_style_label': showLabel ? 1 : 0,
        '${prefix}_style_detail': showDetail ? 1 : 0,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetStyle &&
          other.theme == theme &&
          other.textScale == textScale &&
          other.opacity == opacity &&
          other.showLabel == showLabel &&
          other.showDetail == showDetail;

  @override
  int get hashCode =>
      Object.hash(theme, textScale, opacity, showLabel, showDetail);
}

/// The style of all three widgets at once.
@immutable
class HomeWidgetAppearance {
  const HomeWidgetAppearance({
    this.dailyVerse = _kDefaultDailyVerse,
    this.continueReading = const WidgetStyle(),
    this.streak = const WidgetStyle(),
  });

  /// The daily verse widget defaults to the brand card because that is what
  /// the home screen's own daily verse looks like — a widget cut from the same
  /// cloth as the screen it mirrors reads as part of the app rather than as a
  /// generic text box.
  static const _kDefaultDailyVerse = WidgetStyle(theme: WidgetTheme.brand);

  final WidgetStyle dailyVerse;
  final WidgetStyle continueReading;
  final WidgetStyle streak;

  WidgetStyle styleFor(HomeWidgetKind kind) => switch (kind) {
        HomeWidgetKind.dailyVerse => dailyVerse,
        HomeWidgetKind.continueReading => continueReading,
        HomeWidgetKind.streak => streak,
      };

  HomeWidgetAppearance withStyle(HomeWidgetKind kind, WidgetStyle style) =>
      switch (kind) {
        HomeWidgetKind.dailyVerse => HomeWidgetAppearance(
            dailyVerse: style,
            continueReading: continueReading,
            streak: streak,
          ),
        HomeWidgetKind.continueReading => HomeWidgetAppearance(
            dailyVerse: dailyVerse,
            continueReading: style,
            streak: streak,
          ),
        HomeWidgetKind.streak => HomeWidgetAppearance(
            dailyVerse: dailyVerse,
            continueReading: continueReading,
            streak: style,
          ),
      };

  /// Every style key, flattened the way the preferences store them.
  Map<String, Object> toWidgetEntries() => {
        for (final kind in HomeWidgetKind.values)
          ...styleFor(kind).toWidgetEntries(kind.prefix),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeWidgetAppearance &&
          other.dailyVerse == dailyVerse &&
          other.continueReading == continueReading &&
          other.streak == streak;

  @override
  int get hashCode => Object.hash(dailyVerse, continueReading, streak);
}
