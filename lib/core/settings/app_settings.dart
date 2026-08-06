import 'package:flutter/material.dart';
import '../storage/app_database.dart';

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
    this.dailyVerseNotificationEnabled = false,
    this.readingTimeNotificationEnabled = false,
    this.dailyVerseNotificationTime,
    this.readingTimeNotificationTime,
    this.hasSeenOnboarding = false,
    this.hasSeenReaderHint = false,
    this.lineHeight = 1.6,
    this.marginScale = 1.0,
    this.textAlign = 0,
    this.keepScreenOn = false,
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

  /// Whether daily verse notifications are enabled.
  final bool dailyVerseNotificationEnabled;

  /// Whether reading time reminder notifications are enabled.
  final bool readingTimeNotificationEnabled;

  /// Preferred time for the daily verse notification (nullable, defaults to 6:00 AM if null).
  final TimeOfDay? dailyVerseNotificationTime;

  /// Preferred time for the reading time reminder (nullable, defaults to 8:00 PM if null).
  final TimeOfDay? readingTimeNotificationTime;

  /// Whether the user has completed or skipped the first-run onboarding.
  final bool hasSeenOnboarding;

  /// Whether the user has seen the contextual reader action hint.
  final bool hasSeenReaderHint;

  /// Reader typography preferences
  final double lineHeight;
  final double marginScale;
  final int textAlign;
  final bool keepScreenOn;

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
    bool? dailyVerseNotificationEnabled,
    bool? readingTimeNotificationEnabled,
    TimeOfDay? dailyVerseNotificationTime,
    TimeOfDay? readingTimeNotificationTime,
    bool? hasSeenOnboarding,
    bool? hasSeenReaderHint,
    double? lineHeight,
    double? marginScale,
    int? textAlign,
    bool? keepScreenOn,
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
        dailyVerseNotificationEnabled:
            dailyVerseNotificationEnabled ?? this.dailyVerseNotificationEnabled,
        readingTimeNotificationEnabled:
            readingTimeNotificationEnabled ?? this.readingTimeNotificationEnabled,
        dailyVerseNotificationTime:
            dailyVerseNotificationTime ?? this.dailyVerseNotificationTime,
        readingTimeNotificationTime:
            readingTimeNotificationTime ?? this.readingTimeNotificationTime,
        hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
        hasSeenReaderHint: hasSeenReaderHint ?? this.hasSeenReaderHint,
        lineHeight: (lineHeight ?? this.lineHeight).clamp(1.2, 2.2),
        marginScale: (marginScale ?? this.marginScale).clamp(0.6, 1.6),
        textAlign: textAlign ?? this.textAlign,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      );

  Map<String, dynamic> toMap() => {
        'useGeezNumbers': useGeezNumbers,
        'bodyFontIndex': bodyFontIndex,
        'titleFontIndex': titleFontIndex,
        'fontSize': fontSize,
        'isDarkReader': isDarkReader,
        'continuousReading': continuousReading,
        'cardBgType': cardBgType,
        'cardSolidColorIndex': cardSolidColorIndex,
        'cardGradientIndex': cardGradientIndex,
        'cardFrameStyleIndex': cardFrameStyleIndex,
        'cardFontIndex': cardFontIndex,
        'cardAspectRatio': cardAspectRatio,
        'dailyVerseNotificationEnabled': dailyVerseNotificationEnabled,
        'readingTimeNotificationEnabled': readingTimeNotificationEnabled,
        'hasSeenOnboarding': hasSeenOnboarding,
        'hasSeenReaderHint': hasSeenReaderHint,
        'lineHeight': lineHeight,
        'marginScale': marginScale,
        'textAlign': textAlign,
        'keepScreenOn': keepScreenOn,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        useGeezNumbers: map['useGeezNumbers'] as bool? ?? false,
        bodyFontIndex: map['bodyFontIndex'] as int? ?? 0,
        titleFontIndex: map['titleFontIndex'] as int? ?? 0,
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 17.0,
        isDarkReader: map['isDarkReader'] as bool? ?? false,
        continuousReading: map['continuousReading'] as bool? ?? false,
        cardBgType: map['cardBgType'] as int? ?? 0,
        cardSolidColorIndex: map['cardSolidColorIndex'] as int? ?? 0,
        cardGradientIndex: map['cardGradientIndex'] as int? ?? 0,
        cardFrameStyleIndex: map['cardFrameStyleIndex'] as int? ?? 0,
        cardFontIndex: map['cardFontIndex'] as int? ?? 0,
        cardAspectRatio: map['cardAspectRatio'] as int? ?? 0,
        dailyVerseNotificationEnabled:
            map['dailyVerseNotificationEnabled'] as bool? ?? false,
        readingTimeNotificationEnabled:
            map['readingTimeNotificationEnabled'] as bool? ?? false,
        hasSeenOnboarding: map['hasSeenOnboarding'] as bool? ?? false,
        hasSeenReaderHint: map['hasSeenReaderHint'] as bool? ?? false,
        lineHeight: ((map['lineHeight'] as num?)?.toDouble() ?? 1.6).clamp(1.2, 2.2),
        marginScale: ((map['marginScale'] as num?)?.toDouble() ?? 1.0).clamp(0.6, 1.6),
        textAlign: map['textAlign'] as int? ?? 0,
        keepScreenOn: map['keepScreenOn'] as bool? ?? false,
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
      other.cardAspectRatio == cardAspectRatio &&
      other.dailyVerseNotificationEnabled == dailyVerseNotificationEnabled &&
      other.readingTimeNotificationEnabled == readingTimeNotificationEnabled &&
      other.dailyVerseNotificationTime == dailyVerseNotificationTime &&
      other.readingTimeNotificationTime == readingTimeNotificationTime &&
      other.hasSeenOnboarding == hasSeenOnboarding &&
      other.hasSeenReaderHint == hasSeenReaderHint &&
      other.lineHeight == lineHeight &&
      other.marginScale == marginScale &&
      other.textAlign == textAlign &&
      other.keepScreenOn == keepScreenOn;

  @override
  int get hashCode => Object.hashAll([
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
        dailyVerseNotificationEnabled,
        readingTimeNotificationEnabled,
        dailyVerseNotificationTime,
        readingTimeNotificationTime,
        hasSeenOnboarding,
        hasSeenReaderHint,
        lineHeight,
        marginScale,
        textAlign,
        keepScreenOn,
      ]);
}

class Settings extends InheritedNotifier<ValueNotifier<AppSettings>> {
  const Settings({
    super.key,
    required ValueNotifier<AppSettings> notifier,
    required super.child,
  }) : super(notifier: notifier);

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
    
    // Asynchronously persist to database
    AppDatabase().saveNotificationSettings(
      dailyVerseEnabled: updated.dailyVerseNotificationEnabled,
      readingTimeEnabled: updated.readingTimeNotificationEnabled,
      dailyVerseHour: updated.dailyVerseNotificationTime?.hour,
      dailyVerseMinute: updated.dailyVerseNotificationTime?.minute,
      readingTimeHour: updated.readingTimeNotificationTime?.hour,
      readingTimeMinute: updated.readingTimeNotificationTime?.minute,
      hasSeenOnboarding: updated.hasSeenOnboarding,
      hasSeenReaderHint: updated.hasSeenReaderHint,
      lineHeight: updated.lineHeight,
      marginScale: updated.marginScale,
      textAlign: updated.textAlign,
      keepScreenOn: updated.keepScreenOn,
    );
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
