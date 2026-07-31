import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bible_repository_provider.dart';
import '../data/edition_manager.dart';
import '../data/models/edition.dart';

final editionManagerProvider = Provider<EditionManager>((ref) {
  final repo = ref.watch(bibleRepositoryProvider);
  final manager = EditionManager(
    storage: repo.storage,
    catalog: repo.catalog,
  );
  ref.onDispose(manager.dispose);
  return manager;
});

/// Every catalogued edition plus its install state.
///
/// Invalidate after installing, updating or removing an edition to refresh the
/// list.
final editionListProvider = FutureProvider<List<EditionInstall>>((ref) async {
  return ref.watch(editionManagerProvider).list();
});

/// The edition currently being read. Kept in Riverpod so switching rebuilds
/// book lists and the reader without threading a callback through every screen.
final activeEditionIdProvider = StateProvider<String>(
  (ref) => ref.watch(bibleRepositoryProvider).activeEditionId,
);

/// Short name of the active edition — language and year — for the chip and the
/// settings row. See [Edition.shortLabel] for why this is not `abbrev`.
final activeEditionTitleProvider = FutureProvider<String>((ref) async {
  // Depend on the id so switching editions refreshes the label.
  ref.watch(activeEditionIdProvider);
  final edition = await ref.watch(bibleRepositoryProvider).activeEdition();
  return edition?.shortLabel ?? '';
});

/// The edition in the reader's parallel column, or null when parallel reading
/// is off. Mirrors [activeEditionIdProvider] so the chip, the picker and the
/// settings row all rebuild off one piece of state.
final secondaryEditionIdProvider = StateProvider<String?>(
  (ref) => ref.watch(bibleRepositoryProvider).secondaryEditionId,
);

/// Short name of the parallel edition, null when parallel reading is off.
final secondaryEditionTitleProvider = FutureProvider<String?>((ref) async {
  ref.watch(secondaryEditionIdProvider);
  final edition = await ref.watch(bibleRepositoryProvider).secondaryEdition();
  return edition?.shortLabel;
});
