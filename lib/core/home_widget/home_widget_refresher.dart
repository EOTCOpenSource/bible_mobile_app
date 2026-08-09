import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';

import '../../features/books/providers/reading_progress_providers.dart';
import '../l10n/app_strings.dart';
import '../services/bible_repository_provider.dart';
import '../settings/app_settings.dart';
import 'home_widget_data.dart';
import 'home_widget_service.dart';

/// Gathers the state the home screen widgets show and pushes it to Android.
///
/// Called on launch and on every resume. Both, not just launch: the widgets
/// must not go stale if the app is left running in the background for days,
/// and resume is the only signal that reliably fires when the Ethiopian date
/// has rolled over.
///
/// Every read is defensive. This runs on a startup path, and a widget that
/// cannot be refreshed is never a reason to fail the app launch behind it —
/// so a thrown repository call leaves the previous widget content in place.
Future<void> refreshHomeWidgets(
  WidgetRef ref, {
  required AppStrings s,
  required bool isAmharic,
  required AppSettings settings,
}) async {
  if (!HomeWidgetService.isSupported) return;

  try {
    final repo = ref.read(bibleRepositoryProvider);

    final et = Kenat.now().getEthiopian();
    final dailyVerse = await repo.loadDailyVerse(
      et['month'] as int,
      et['day'] as int,
    );

    final snapshots = await ref.read(continueReadingSnapshotsProvider.future);
    final latest = snapshots.isEmpty ? null : snapshots.first;

    final streak = await ref.read(readingStreakStateProvider.future);

    await HomeWidgetService.push(
      buildHomeWidgetData(
        s: s,
        useGeezNumbers: settings.useGeezNumbers,
        isAmharic: isAmharic,
        streakEmoji: settings.streakEmoji,
        dailyVerse: dailyVerse,
        continueReading: latest == null
            ? null
            : (
                entry: latest.entry,
                position: latest.position,
                progress: latest.progressPercent,
              ),
        streakCount: streak.currentStreak,
      ),
    );
  } catch (e) {
    debugPrint('[HomeWidget] refresh failed: $e');
  }
}

/// A [HomeWidgetData] built from the same sources as [refreshHomeWidgets] but
/// not pushed anywhere — the preview the settings page draws so the user can
/// see their emoji choice on the real streak count.
Future<HomeWidgetData?> previewHomeWidgetData(
  WidgetRef ref, {
  required AppStrings s,
  required bool isAmharic,
  required AppSettings settings,
}) async {
  try {
    final streak = await ref.read(readingStreakStateProvider.future);
    return buildHomeWidgetData(
      s: s,
      useGeezNumbers: settings.useGeezNumbers,
      isAmharic: isAmharic,
      streakEmoji: settings.streakEmoji,
      dailyVerse: null,
      continueReading: null,
      streakCount: streak.currentStreak,
    );
  } catch (e) {
    debugPrint('[HomeWidget] preview failed: $e');
    return null;
  }
}
