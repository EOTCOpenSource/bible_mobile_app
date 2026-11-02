import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the books tab in [HomeScreen]'s bottom nav.
const kBooksTabIndex = 1;

/// Which bottom-nav tab `HomeScreen` is showing.
///
/// A provider rather than plain `State` because deep links are handled at the
/// root navigator, above `HomeScreen` and outside its element tree: the streak
/// page's "read today" call-to-action has to be able to select the books tab
/// even when it was opened from a home screen widget rather than from Home.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
