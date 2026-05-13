import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, [HomeScreen] hides the bottom tab bar so the reader can use the
/// full screen. [ReaderScreen] toggles this while the user scrolls the chapter.
final readerImmersiveModeProvider = StateProvider<bool>((ref) => false);

/// When true, [AppBottomNav] uses reader parchment / reader-night shell colors.
/// [ReaderScreen] sets this only while that route is on screen.
final readerBottomNavMatchReaderProvider = StateProvider<bool>((ref) => false);
