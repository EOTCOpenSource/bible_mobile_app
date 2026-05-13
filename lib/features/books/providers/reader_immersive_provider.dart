import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, [HomeScreen] hides the bottom tab bar so the reader can use the
/// full screen. [ReaderScreen] toggles this while the user scrolls the chapter.
final readerImmersiveModeProvider = StateProvider<bool>((ref) => false);
