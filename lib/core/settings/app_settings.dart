import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.useGeezNumbers = false,
    this.bodyFontIndex = 0,
    this.titleFontIndex = 0,
    this.fontSize = 17.0,
    this.isDarkReader = false,
    this.continuousReading = false,
    this.cardBgType = 0,
    this.cardSolidColorIndex = 0,
    this.cardGradientIndex = 0,
    this.cardFrameStyleIndex = 0,
    this.cardFontIndex = 0,
    this.cardAspectRatio = 0,
  });

  final bool useGeezNumbers;

  /// Index into readerFonts[] for verse body text.
  final int bodyFontIndex;

  /// Index into readerFonts[] for section/chapter titles.
  final int titleFontIndex;

  /// Base font size for reading.
  final double fontSize;

  /// App + reader dark theme (Settings “night mode”).
  final bool isDarkReader;

  /// When true, verses flow as a paragraph instead of one verse per line.
  final bool continuousReading;

  /// Card designer preferences
  final int cardBgType;
  final int cardSolidColorIndex;
  final int cardGradientIndex;
  final int cardFrameStyleIndex;
  final int cardFontIndex;
  final int cardAspectRatio;

  AppSettings copyWith({
    bool? useGeezNumbers,
    int? bodyFontIndex,
    int? titleFontIndex,
    double? fontSize,
    bool? isDarkReader,
    bool? continuousReading,
    int? cardBgType,
    int? cardSolidColorIndex,
    int? cardGradientIndex,
    int? cardFrameStyleIndex,
    int? cardFontIndex,
    int? cardAspectRatio,
  }) =>
      AppSettings(
        useGeezNumbers: useGeezNumbers ?? this.useGeezNumbers,
        bodyFontIndex: bodyFontIndex ?? this.bodyFontIndex,
        titleFontIndex: titleFontIndex ?? this.titleFontIndex,
        fontSize: fontSize ?? this.fontSize,
        isDarkReader: isDarkReader ?? this.isDarkReader,
        continuousReading: continuousReading ?? this.continuousReading,
        cardBgType: cardBgType ?? this.cardBgType,
        cardSolidColorIndex: cardSolidColorIndex ?? this.cardSolidColorIndex,
        cardGradientIndex: cardGradientIndex ?? this.cardGradientIndex,
        cardFrameStyleIndex: cardFrameStyleIndex ?? this.cardFrameStyleIndex,
        cardFontIndex: cardFontIndex ?? this.cardFontIndex,
        cardAspectRatio: cardAspectRatio ?? this.cardAspectRatio,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.useGeezNumbers == useGeezNumbers &&
      other.bodyFontIndex == bodyFontIndex &&
      other.titleFontIndex == titleFontIndex &&
      other.fontSize == fontSize &&
      other.isDarkReader == isDarkReader &&
      other.continuousReading == continuousReading &&
      other.cardBgType == cardBgType &&
      other.cardSolidColorIndex == cardSolidColorIndex &&
      other.cardGradientIndex == cardGradientIndex &&
      other.cardFrameStyleIndex == cardFrameStyleIndex &&
      other.cardFontIndex == cardFontIndex &&
      other.cardAspectRatio == cardAspectRatio;

  @override
  int get hashCode => Object.hash(
        useGeezNumbers,
        bodyFontIndex,
        titleFontIndex,
        fontSize,
        isDarkReader,
        continuousReading,
        cardBgType,
        cardSolidColorIndex,
        cardGradientIndex,
        cardFrameStyleIndex,
        cardFontIndex,
        cardAspectRatio,
      );
}

class Settings extends InheritedNotifier<ValueNotifier<AppSettings>> {
  const Settings({
    super.key,
    required ValueNotifier<AppSettings> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppSettings of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<Settings>();
    assert(s != null, 'No Settings found in widget tree. Wrap your app with Settings().');
    return s!.notifier!.value;
  }

  static void update(BuildContext context, AppSettings updated) {
    final s = context.getInheritedWidgetOfExactType<Settings>();
    assert(s != null, 'No Settings found in widget tree.');
    s!.notifier!.value = updated;
  }

  @override
  bool updateShouldNotify(Settings oldWidget) =>
      notifier!.value != oldWidget.notifier!.value;
}
