import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import 'saved_common.dart';

class NotesTab extends StatefulWidget {
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
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
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
    final books = widget.items
        .where((item) {
          if (_testamentFilter == 'OT' && !item.isOT) return false;
          if (_testamentFilter == 'NT' && item.isOT) return false;
          return true;
        })
        .map((item) => item.bookEntry)
        .toSet()
        .toList()
      ..sort((a, b) => a.bookNumber.compareTo(b.bookNumber));

    final s = L10n.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AnnotationPickerSheet(
        title: s.savedPickBook,
        items: [
          AnnotationPickerItem(id: null, label: s.savedPickAllBooks),
          ...books.map(
              (e) => AnnotationPickerItem(id: e.bookNameEn, label: e.bookNameAm)),
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
    final chapters = _availableChapters.toList()..sort();
    final s = L10n.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AnnotationPickerSheet(
        title: s.savedPickChapter,
        items: [
          AnnotationPickerItem(id: null, label: s.savedPickAllChapters),
          ...chapters.map(
              (ch) => AnnotationPickerItem(id: ch, label: s.savedFilterChapter(ch))),
        ],
        selectedId: _chapterFilter,
        onSelect: (id) {
          setState(() => _chapterFilter = id as int?);
          Navigator.pop(context);
        },
      ),
    );
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
                  label: s.savedFilterOT,
                  active: _testamentFilter == 'OT',
                  onTap: () => setState(() {
                    _testamentFilter =
                        _testamentFilter == 'OT' ? null : 'OT';
                    _bookFilter = null;
                    _chapterFilter = null;
                  }),
                ),
                const SizedBox(width: 6),
                SavedFilterChip(
                  label: s.savedFilterNT,
                  active: _testamentFilter == 'NT',
                  onTap: () => setState(() {
                    _testamentFilter =
                        _testamentFilter == 'NT' ? null : 'NT';
                    _bookFilter = null;
                    _chapterFilter = null;
                  }),
                ),
                if (availableBookIds.length > 1) ...[
                  const SizedBox(width: 6),
                  SavedFilterChip(
                    label: currentBookEntry?.bookNameAm ?? s.savedFilterAll,
                    active: _bookFilter != null,
                    trailing: Icons.expand_more_rounded,
                    onTap: _showBookPicker,
                  ),
                ],
                if (_bookFilter != null && availableChapters.length > 1) ...[
                  const SizedBox(width: 6),
                  SavedFilterChip(
                    label: _chapterFilter != null
                        ? s.savedFilterChapter(_chapterFilter!)
                        : s.savedFilterAllChapters,
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
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
