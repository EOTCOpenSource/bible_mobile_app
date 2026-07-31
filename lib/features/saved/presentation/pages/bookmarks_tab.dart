import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../annotations/providers/annotation_providers.dart';
import 'saved_common.dart';

class BookmarksTab extends ConsumerStatefulWidget {
  const BookmarksTab({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<AnnotationItem> items;
  final void Function(AnnotationItem) onOpen;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<BookmarksTab> createState() => _BookmarksTabState();
}

class _BookmarksTabState extends ConsumerState<BookmarksTab> {
  String? _testamentFilter;
  String? _bookFilter;
  int? _chapterFilter;

  List<AnnotationItem> get _filtered => widget.items.where((item) {
    if (_testamentFilter == 'OT' && !item.isOT) return false;
    if (_testamentFilter == 'NT' && item.isOT) return false;
    if (_bookFilter != null && item.bookEntry.id != _bookFilter) {
      return false;
    }
    if (_chapterFilter != null && item.chapter != _chapterFilter) {
      return false;
    }
    return true;
  }).toList();

  Set<String> get _availableBookIds => widget.items
      .where((item) {
        if (_testamentFilter == 'OT' && !item.isOT) return false;
        if (_testamentFilter == 'NT' && item.isOT) return false;
        return true;
      })
      .map((item) => item.bookEntry.id)
      .toSet();

  Set<int> get _availableChapters {
    if (_bookFilter == null) return {};
    return widget.items
        .where((item) => item.bookEntry.id == _bookFilter)
        .map((item) => item.chapter)
        .toSet();
  }

  void _showBookPicker() {
    final s = L10n.of(context);
    final isEnglish = s is EnStrings;
    final books =
        widget.items
            .where((item) {
              if (_testamentFilter == 'OT' && !item.isOT) return false;
              if (_testamentFilter == 'NT' && item.isOT) return false;
              return true;
            })
            .map((item) => item.bookEntry)
            .toSet()
            .toList()
          ..sort((a, b) => a.bookNumber.compareTo(b.bookNumber));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AnnotationPickerSheet(
        title: s.savedPickBook,
        items: [
          AnnotationPickerItem(id: null, label: s.savedAllBooks),
          ...books.map(
            (e) => AnnotationPickerItem(
              id: e.id,
              label: isEnglish ? e.bookNameEn : e.bookNameAm,
            ),
          ),
        ],
        selectedId: _bookFilter,
        onSelect: (id) {
          setState(() {
            _bookFilter = id as String?;
            _chapterFilter = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showChapterPicker() {
    if (_bookFilter == null) return;
    final s = L10n.of(context);
    final chapters = _availableChapters.toList()..sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AnnotationPickerSheet(
        title: s.savedPickChapter,
        items: [
          AnnotationPickerItem(id: null, label: s.savedAllChapters),
          ...chapters.map(
            (ch) =>
                AnnotationPickerItem(id: ch, label: s.savedChapterLabel(ch)),
          ),
        ],
        selectedId: _chapterFilter,
        onSelect: (id) {
          setState(() => _chapterFilter = id as int?);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteBookmark(AnnotationItem item) async {
    final s = L10n.of(context);
    final c = context.colors;
    final reference = '${item.bookName(s)} ${item.chapter}:${item.verseStart}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.savedDeleteBookmarkTitle,
          style: AppTypography.amharicLabel.copyWith(
            color: c.textOnParchment,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          s.savedDeleteBookmarkMessage(reference),
          style: AppTypography.amharicBody.copyWith(
            color: c.textMuted,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              s.savedCancel,
              style: AppTypography.amharicLabel.copyWith(color: c.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              s.savedDelete,
              style: AppTypography.amharicLabel.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(annotationDbProvider);
      await db.deleteBookmark(item.id);
      await widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.savedBookmarkDeleted)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final items = _filtered;
    final availableBookIds = _availableBookIds;
    final availableChapters = _availableChapters;
    final currentBookEntry = _bookFilter == null
        ? null
        : widget.items
              .where((i) => i.bookEntry.id == _bookFilter)
              .firstOrNull
              ?.bookEntry;

    return ColoredBox(
      color: context.colors.surfaceDim,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                SavedFilterChip(
                  label: s.savedFilterAll,
                  active: _testamentFilter == null,
                  onTap: () => setState(() => _testamentFilter = null),
                ),
                const SizedBox(width: 6),
                SavedFilterChip(
                  label: s.savedFilterOld,
                  active: _testamentFilter == 'OT',
                  onTap: () => setState(() {
                    _testamentFilter = _testamentFilter == 'OT' ? null : 'OT';
                    _bookFilter = null;
                    _chapterFilter = null;
                  }),
                ),
                const SizedBox(width: 6),
                SavedFilterChip(
                  label: s.savedFilterNew,
                  active: _testamentFilter == 'NT',
                  onTap: () => setState(() {
                    _testamentFilter = _testamentFilter == 'NT' ? null : 'NT';
                    _bookFilter = null;
                    _chapterFilter = null;
                  }),
                ),
                if (availableBookIds.length > 1) ...[
                  const SizedBox(width: 6),
                  SavedFilterChip(
                    label: currentBookEntry == null
                        ? s.savedFilterAll
                        : s is EnStrings
                        ? currentBookEntry.bookNameEn
                        : currentBookEntry.bookNameAm,
                    active: _bookFilter != null,
                    trailing: Icons.expand_more_rounded,
                    onTap: _showBookPicker,
                  ),
                ],
                if (_bookFilter != null && availableChapters.length > 1) ...[
                  const SizedBox(width: 6),
                  SavedFilterChip(
                    label: _chapterFilter != null
                        ? s.savedChapterLabel(_chapterFilter!)
                        : s.savedAllChaptersShort,
                    active: _chapterFilter != null,
                    trailing: Icons.expand_more_rounded,
                    onTap: _showChapterPicker,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const AnnotationEmptyState(tab: 1)
                : RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    color: context.colors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: items.length,
                      itemBuilder: (_, i) => AnnotationCard(
                        item: items[i],
                        tab: 1,
                        onTap: () => widget.onOpen(items[i]),
                        onLongPress: () => _deleteBookmark(items[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
