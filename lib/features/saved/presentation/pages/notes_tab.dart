import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../annotations/providers/annotation_providers.dart';
import '../../../books/presentation/pages/reader_screen.dart';
import 'saved_common.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<AnnotationItem> items;
  final void Function(AnnotationItem) onOpen;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  String? _testamentFilter;
  String? _bookFilter;
  int? _chapterFilter;

  List<AnnotationItem> get _filtered => widget.items.where((item) {
    if (_testamentFilter == 'OT' && !item.isOT) return false;
    if (_testamentFilter == 'NT' && item.isOT) return false;
    if (_bookFilter != null && item.bookEntry.bookNameEn != _bookFilter) {
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
      .map((item) => item.bookEntry.bookNameEn)
      .toSet();

  Set<int> get _availableChapters {
    if (_bookFilter == null) return {};
    return widget.items
        .where((item) => item.bookEntry.bookNameEn == _bookFilter)
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
              id: e.bookNameEn,
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

  void _showNoteOptions(AnnotationItem item) {
    final s = L10n.of(context);
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: c.textOnParchment),
                title: Text(
                  s.savedEdit,
                  style: AppTypography.amharicLabel.copyWith(
                    color: c.textOnParchment,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _editNote(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: Text(
                  s.savedDelete,
                  style: AppTypography.amharicLabel.copyWith(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteNote(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editNote(AnnotationItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          entry: item.bookEntry,
          initialChapter: (item.chapter - 1).clamp(0, 999),
          initialVerse: item.verseStart,
          openNoteSheet: true,
        ),
      ),
    ).then((_) => widget.onRefresh());
  }

  void _deleteNote(AnnotationItem item) async {
    final s = L10n.of(context);
    final c = context.colors;
    final reference = '${item.bookName(s)} ${item.chapter}:${item.verseStart}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.savedDeleteNoteTitle,
          style: AppTypography.amharicLabel.copyWith(
            color: c.textOnParchment,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          s.savedDeleteNoteMessage(reference),
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
      await db.deleteNote(item.id);
      await widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.savedNoteDeleted)));
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
              .where((i) => i.bookEntry.bookNameEn == _bookFilter)
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
                ? const AnnotationEmptyState(tab: 2)
                : RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    color: context.colors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: items.length,
                      itemBuilder: (_, i) => AnnotationCard(
                        item: items[i],
                        tab: 2,
                        onTap: () => widget.onOpen(items[i]),
                        onLongPress: () => _showNoteOptions(items[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
