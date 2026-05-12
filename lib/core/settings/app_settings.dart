import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.useGeezNumbers = false,
    this.bodyFontIndex = 0,
    this.titleFontIndex = 0,
    this.fontSize = 17.0,
    this.isDarkReader = false,
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

  AppSettings copyWith({
    bool? useGeezNumbers,
    int? bodyFontIndex,
    int? titleFontIndex,
    double? fontSize,
    bool? isDarkReader,
  }) =>
      AppSettings(
        useGeezNumbers: useGeezNumbers ?? this.useGeezNumbers,
        bodyFontIndex: bodyFontIndex ?? this.bodyFontIndex,
        titleFontIndex: titleFontIndex ?? this.titleFontIndex,
        fontSize: fontSize ?? this.fontSize,
        isDarkReader: isDarkReader ?? this.isDarkReader,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.useGeezNumbers == useGeezNumbers &&
      other.bodyFontIndex == bodyFontIndex &&
      other.titleFontIndex == titleFontIndex &&
      other.fontSize == fontSize &&
      other.isDarkReader == isDarkReader;

  @override
  int get hashCode => Object.hash(
        useGeezNumbers,
        bodyFontIndex,
        titleFontIndex,
        fontSize,
        isDarkReader,
      );
}

class Settings extends InheritedNotifier<ValueNotifier<AppSettings>> {
  Settings({super.key, AppSettings? initial, required super.child})
      : super(notifier: ValueNotifier(initial ?? const AppSettings()));

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
