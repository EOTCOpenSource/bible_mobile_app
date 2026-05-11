import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({this.useGeezNumbers = false});

  final bool useGeezNumbers;

  AppSettings copyWith({bool? useGeezNumbers}) =>
      AppSettings(useGeezNumbers: useGeezNumbers ?? this.useGeezNumbers);

  @override
  bool operator ==(Object other) =>
      other is AppSettings && other.useGeezNumbers == useGeezNumbers;

  @override
  int get hashCode => useGeezNumbers.hashCode;
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
