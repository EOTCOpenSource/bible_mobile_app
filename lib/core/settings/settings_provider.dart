import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_settings.dart';

/// Singleton ValueNotifier shared by [Settings] InheritedWidget and Riverpod.
/// Must be overridden in [ProviderScope] before the widget tree builds.
final settingsNotifierProvider = Provider<ValueNotifier<AppSettings>>(
  (ref) => throw StateError('settingsNotifierProvider not initialised'),
);
