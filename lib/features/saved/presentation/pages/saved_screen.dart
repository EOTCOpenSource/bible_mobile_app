import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/annotations/annotation_models.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/sync/sync_repository.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../annotations/providers/annotation_providers.dart';
import '../../../books/presentation/pages/reader_screen.dart';
import 'bookmarks_tab.dart';
import 'highlights_tab.dart';
import 'history_tab.dart';
import 'notes_tab.dart';
import 'saved_common.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  int _tab = 0;
  bool _loading = true;
  bool _initialized = false;
  int _historyLimit = 50;
  bool _hasMoreHistory = true;

  List<AnnotationItem> _history = [];
  List<AnnotationItem> _highlights = [];
  List<AnnotationItem> _bookmarks = [];
  List<AnnotationItem> _notes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await _doLoad();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doLoad() async {
    final db = ref.read(annotationDbProvider);
    final repo = BibleRepositoryProvider.of(context);

    final token = ref.read(authStateProvider).token;
    if (token != null) {
      await SyncService(
        db: db,
        repo: SyncRepository(ref.read(apiClientProvider), token),
      ).pullAll();
    }

    final rawHistory = await ref
        .read(appDatabaseProvider)
        .getReadingHistory(limit: _historyLimit);

    final results = await Future.wait([
      db.getAllBookmarks(),
      db.getAllHighlights(),
      db.getAllNotes(),
    ]);

    final rawBookmarks = results[0] as List<Bookmark>;
    final rawHighlights = results[1] as List<Highlight>;
    final rawNotes = results[2] as List<Note>;

    final bookIds = {
      ...rawHistory.map((h) => h['book_id'] as String),
      ...rawBookmarks.map((b) => b.bookId),
      ...rawHighlights.map((h) => h.bookId),
      ...rawNotes.map((n) => n.bookId),
    };

    if (bookIds.isEmpty) {
      if (mounted) {
        setState(() {
          _history = [];
          _highlights = [];
          _bookmarks = [];
          _notes = [];
          _loading = false;
        });
      }
      return;
    }

    final index = await repo.loadIndex();
    final entries = {
      for (final e in index.where((e) => bookIds.contains(e.id))) e.id: e,
    };

    final entryList = entries.values.toList();
    final books = await Future.wait(entryList.map(repo.loadBook));

    final textMap = <String, Map<int, Map<int, String>>>{};
    for (var i = 0; i < entryList.length; i++) {
      final bookId = entryList[i].id;
      textMap[bookId] = {};
      for (final ch in books[i].chapters) {
        textMap[bookId]![ch.chapterNumber] = {
          for (final sec in ch.sections)
            for (final v in sec.verses) v.verseNumber: v.text,
        };
      }
    }

    String getText(String bookId, int ch, int verseStart, [int count = 1]) {
      final chMap = textMap[bookId]?[ch];
      if (chMap == null) return '';
      if (count <= 1) return chMap[verseStart] ?? '';
      return [
        for (var v = verseStart; v < verseStart + count; v++)
          if (chMap[v] != null) chMap[v]!,
      ].join('\n');
    }

      var filteredHighlights = rawHighlights
          .map((h) {
            final e = entries[h.bookId];
            return e == null
                ? null
                : AnnotationItem(
                    id: h.id!,
                    bookEntry: e,
                    chapter: h.chapter,
                    verseStart: h.verseStart,
                    verseCount: h.verseCount,
                    verseText: getText(
                      h.bookId,
                      h.chapter,
                      h.verseStart,
                      h.verseCount,
                    ),
                    createdAt: h.createdAt,
                    highlightColor: h.color,
                    tags: h.tags,
                    itemType: 'highlight',
                  );
          })
          .whereType<AnnotationItem>()
          .toList();

      var filteredBookmarks = rawBookmarks
          .map((b) {
            final e = entries[b.bookId];
            return e == null
                ? null
                : AnnotationItem(
                    id: b.id!,
                    bookEntry: e,
                    chapter: b.chapter,
                    verseStart: b.verseStart,
                    verseCount: b.verseCount,
                    verseText: getText(
                      b.bookId,
                      b.chapter,
                      b.verseStart,
                      b.verseCount,
                    ),
                    createdAt: b.createdAt,
                    tags: b.tags,
                    itemType: 'bookmark',
                  );
          })
          .whereType<AnnotationItem>()
          .toList();

      var filteredNotes = rawNotes
          .map((n) {
            final e = entries[n.bookId];
            return e == null
                ? null
                : AnnotationItem(
                    id: n.id!,
                    bookEntry: e,
                    chapter: n.chapter,
                    verseStart: n.verseStart,
                    verseCount: n.verseCount,
                    verseText: getText(
                      n.bookId,
                      n.chapter,
                      n.verseStart,
                      n.verseCount,
                    ),
                    createdAt: n.createdAt,
                    noteContent: n.content,
                    tags: n.tags,
                    itemType: 'note',
                  );
          })
          .whereType<AnnotationItem>()
          .toList();

      final selectedCollectionId = ref.read(selectedCollectionIdProvider);
      if (selectedCollectionId != null) {
        final linkedItems =
            await db.listItemsInCollection(selectedCollectionId);
        final linkedHighlights = linkedItems
            .where((r) => r['item_type'] == 'highlight')
            .map((r) => r['item_id'] as int)
            .toSet();
        final linkedBookmarks = linkedItems
            .where((r) => r['item_type'] == 'bookmark')
            .map((r) => r['item_id'] as int)
            .toSet();
        final linkedNotes = linkedItems
            .where((r) => r['item_type'] == 'note')
            .map((r) => r['item_id'] as int)
            .toSet();

        filteredHighlights = filteredHighlights
            .where((h) => linkedHighlights.contains(h.id))
            .toList();
        filteredBookmarks = filteredBookmarks
            .where((b) => linkedBookmarks.contains(b.id))
            .toList();
        filteredNotes =
            filteredNotes.where((n) => linkedNotes.contains(n.id)).toList();
      }

      if (!mounted) return;
      setState(() {
        _hasMoreHistory = rawHistory.length >= _historyLimit;
        _history = rawHistory
            .map((row) {
              final bookId = row['book_id'] as String;
              final e = entries[bookId];
              if (e == null) return null;

              final chNum = row['chapter'] as int;
              final verseNum = row['verse'] as int?;

              return AnnotationItem(
                id: row['id'] as int,
                bookEntry: e,
                chapter: chNum,
                verseStart: verseNum ?? 1,
                verseCount: 1,
                verseText: getText(bookId, chNum, verseNum ?? 1, 1),
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  row['opened_at'] as int,
                ),
              );
            })
            .whereType<AnnotationItem>()
            .toList();

        _highlights = filteredHighlights;
        _bookmarks = filteredBookmarks;
        _notes = filteredNotes;
        _loading = false;
      });
  }

  void _openVerse(AnnotationItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          entry: item.bookEntry,
          initialChapter: (item.chapter - 1).clamp(0, 999),
          initialVerse: item.verseStart,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.savedEyebrow,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.savedTitle,
                  style: AppTypography.amharicHeading.copyWith(
                    color: c.textOnParchment,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Collections Header Row ──────────────────────────────────────────
          _CollectionsHeaderSection(onCollectionChanged: _load),

          // ── Tab bar ───────────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _TabLabel(
                  label: s.savedHighlights,
                  count: _highlights.length,
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 24),
                _TabLabel(
                  label: s.savedBookmarks,
                  count: _bookmarks.length,
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                const SizedBox(width: 24),
                _TabLabel(
                  label: s.savedNotes,
                  count: _notes.length,
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
                const SizedBox(width: 24),
                _TabLabel(
                  label: s.savedHistory,
                  count: _history.length,
                  active: _tab == 3,
                  onTap: () => setState(() => _tab = 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: c.borderSubtle, height: 1),

          // ── Tab content ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: c.primary))
                : IndexedStack(
                    index: _tab,
                    children: [
                      HighlightsTab(
                        items: _highlights,
                        onOpen: _openVerse,
                        onRefresh: _load,
                      ),
                      BookmarksTab(
                        items: _bookmarks,
                        onOpen: _openVerse,
                        onRefresh: _load,
                      ),
                      NotesTab(
                        items: _notes,
                        onOpen: _openVerse,
                        onRefresh: _load,
                      ),
                      HistoryTab(
                        items: _history,
                        onOpen: _openVerse,
                        onRefresh: _load,
                        onLoadMore: () {
                          setState(() => _historyLimit += 50);
                          _load();
                        },
                        hasMore: _hasMoreHistory,
                        onDeleteItem: (id) async {
                          await ref
                              .read(appDatabaseProvider)
                              .deleteReadingHistoryItem(id);
                          _load();
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Tab label ─────────────────────────────────────────────────────────────────

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.amharicLabel.copyWith(
                  fontSize: 14,
                  color: active ? c.textOnParchment : c.textMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 5),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: active ? c.primary : c.surfaceDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : c.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.5,
            width: active ? 40 : 0,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Collections Header Section ──────────────────────────────────────────────────

class _CollectionsHeaderSection extends ConsumerWidget {
  const _CollectionsHeaderSection({required this.onCollectionChanged});

  final VoidCallback onCollectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;
    final collectionsAsync = ref.watch(collectionsNotifierProvider);
    final selectedCollectionId = ref.watch(selectedCollectionIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              Text(
                s.collections,
                style: AppTypography.amharicLabel.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: c.textMuted,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => showCreateCollectionDialog(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: c.primary),
                      const SizedBox(width: 2),
                      Text(
                        s.newCollection,
                        style: AppTypography.amharicCaption.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        collectionsAsync.when(
          data: (collections) {
            if (collections.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  s.noCollections,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textMuted,
                    fontSize: 12,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  for (final col in collections) ...[
                    _CollectionChip(
                      collection: col,
                      isSelected: selectedCollectionId == col.id,
                      onTap: () {
                        if (selectedCollectionId == col.id) {
                          ref.read(selectedCollectionIdProvider.notifier).state =
                              null;
                        } else {
                          ref.read(selectedCollectionIdProvider.notifier).state =
                              col.id;
                        }
                        onCollectionChanged();
                      },
                      onLongPress: () => _showCollectionOptions(
                          context, ref, col, onCollectionChanged),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CollectionChip extends StatelessWidget {
  const _CollectionChip({
    required this.collection,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final Collection collection;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = collection.color ?? c.primary;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : c.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              collection.name,
              style: AppTypography.amharicCaption.copyWith(
                color: isSelected ? c.textOnParchment : c.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCollectionOptions(
  BuildContext context,
  WidgetRef ref,
  Collection col,
  VoidCallback onChanged,
) async {
  final s = L10n.of(context);
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(
                '${s.savedDelete} ${col.name}',
                style: AppTypography.amharicLabel.copyWith(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: Text(col.name),
                    content: const Text(
                        'Delete this collection? Annotations will not be deleted.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && col.id != null) {
                  if (ref.read(selectedCollectionIdProvider) == col.id) {
                    ref.read(selectedCollectionIdProvider.notifier).state = null;
                  }
                  await ref
                      .read(collectionsNotifierProvider.notifier)
                      .deleteCollection(col.id!);
                  onChanged();
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
