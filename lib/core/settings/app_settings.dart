import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.useGeezNumbers = false,
    this.bodyFontIndex = 0,
    this.titleFontIndex = 0,
    this.fontSize = 17.0,
    this.isDarkReader = false,
    this.continuousReading = false,
    this.dailyVerseNotificationEnabled = false,
    this.readingTimeNotificationEnabled = false,
    this.dailyVerseNotificationTime,
    this.readingTimeNotificationTime,
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

  /// Whether daily verse notifications are enabled.
  final bool dailyVerseNotificationEnabled;

  /// Whether reading time reminder notifications are enabled.
  final bool readingTimeNotificationEnabled;

  /// Preferred time for the daily verse notification (nullable, defaults to 6:00 AM if null).
  final TimeOfDay? dailyVerseNotificationTime;

  /// Preferred time for the reading time reminder (nullable, defaults to 8:00 PM if null).
  final TimeOfDay? readingTimeNotificationTime;

  AppSettings copyWith({
    bool? useGeezNumbers,
    int? bodyFontIndex,
    int? titleFontIndex,
    double? fontSize,
    bool? isDarkReader,
    bool? continuousReading,
    bool? dailyVerseNotificationEnabled,
    bool? readingTimeNotificationEnabled,
    TimeOfDay? dailyVerseNotificationTime,
    TimeOfDay? readingTimeNotificationTime,
  }) => AppSettings(
    useGeezNumbers: useGeezNumbers ?? this.useGeezNumbers,
    bodyFontIndex: bodyFontIndex ?? this.bodyFontIndex,
    titleFontIndex: titleFontIndex ?? this.titleFontIndex,
    fontSize: fontSize ?? this.fontSize,
    isDarkReader: isDarkReader ?? this.isDarkReader,
    continuousReading: continuousReading ?? this.continuousReading,
    dailyVerseNotificationEnabled:
        dailyVerseNotificationEnabled ?? this.dailyVerseNotificationEnabled,
    readingTimeNotificationEnabled:
        readingTimeNotificationEnabled ?? this.readingTimeNotificationEnabled,
    dailyVerseNotificationTime:
        dailyVerseNotificationTime ?? this.dailyVerseNotificationTime,
    readingTimeNotificationTime:
        readingTimeNotificationTime ?? this.readingTimeNotificationTime,
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
      other.dailyVerseNotificationEnabled == dailyVerseNotificationEnabled &&
      other.readingTimeNotificationEnabled == readingTimeNotificationEnabled &&
      other.dailyVerseNotificationTime == dailyVerseNotificationTime &&
      other.readingTimeNotificationTime == readingTimeNotificationTime;

  @override
  int get hashCode => Object.hash(
    useGeezNumbers,
    bodyFontIndex,
    titleFontIndex,
    fontSize,
    isDarkReader,
    continuousReading,
    dailyVerseNotificationEnabled,
    readingTimeNotificationEnabled,
    dailyVerseNotificationTime,
    readingTimeNotificationTime,
  );
}

class Settings extends InheritedNotifier<ValueNotifier<AppSettings>> {
  Settings({super.key, AppSettings? initial, required super.child})
    : super(notifier: ValueNotifier(initial ?? const AppSettings()));

  static AppSettings of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<Settings>();
    assert(
      s != null,
      'No Settings found in widget tree. Wrap your app with Settings().',
    );
    return s!.notifier!.value;
  }

  static void update(BuildContext context, AppSettings updated) {
    final s = context.getInheritedWidgetOfExactType<Settings>();
    assert(s != null, 'No Settings found in widget tree.');
    s!.notifier!.value = updated;
  }

  /// Returns the underlying [ValueNotifier] without an [InheritedWidget]
  /// lookup on every rebuild. Capture this **before** any `await` to safely
  /// mutate settings across async gaps without using [BuildContext] after
  /// the gap.
  static ValueNotifier<AppSettings> notifierOf(BuildContext context) {
    final s = context.getInheritedWidgetOfExactType<Settings>();
    assert(s != null, 'No Settings found in widget tree.');
    return s!.notifier!;
  }

  @override
  bool updateShouldNotify(Settings oldWidget) =>
      notifier!.value != oldWidget.notifier!.value;
}

/// Convenience extension for displaying a [TimeOfDay] as a readable string.
/// Example: TimeOfDay(hour: 6, minute: 0).formatted → "6:00 AM"
extension TimeOfDayX on TimeOfDay {
  String get formatted {
    final h = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final m = minute.toString().padLeft(2, '0');
    final p = period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
