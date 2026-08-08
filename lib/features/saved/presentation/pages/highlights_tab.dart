import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/annotations/annotation_models.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../annotations/providers/annotation_providers.dart';
import 'saved_common.dart';

class HighlightsTab extends ConsumerStatefulWidget {
  const HighlightsTab({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<AnnotationItem> items;
  final void Function(AnnotationItem) onOpen;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<HighlightsTab> createState() => _HighlightsTabState();
}

class _HighlightsTabState extends ConsumerState<HighlightsTab> {
  Color? _colorFilter;
  String? _testamentFilter;
  String? _bookFilter;
  int? _chapterFilter;

  List<AnnotationItem> get _filtered {
    final selectedTags = ref.watch(selectedTagsProvider);
    return widget.items.where((item) {
      if (_colorFilter != null &&
          item.highlightColor?.toARGB32() != _colorFilter!.toARGB32()) {
        return false;
      }
      if (_testamentFilter == 'OT' && !item.isOT) return false;
      if (_testamentFilter == 'NT' && item.isOT) return false;
      if (_bookFilter != null && item.bookEntry.id != _bookFilter) {
        return false;
      }
      if (_chapterFilter != null && item.chapter != _chapterFilter) {
        return false;
      }
      if (selectedTags.isNotEmpty) {
        if (item.tags == null || item.tags!.isEmpty) return false;
        final itemTagSet = item.tags!.split(',').toSet();
        if (!selectedTags.every((t) => itemTagSet.contains(t))) return false;
      }
      return true;
    }).toList();
  }

  Set<String> get _availableBookIds => widget.items
      .where((item) {
        if (_testamentFilter == 'OT' && !item.isOT) return false;
        if (_testamentFilter == 'NT' && item.isOT) return false;
        if (_colorFilter != null &&
            item.highlightColor?.toARGB32() != _colorFilter!.toARGB32()) {
          return false;
        }
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

  void _deleteHighlight(AnnotationItem item) async {
    final s = L10n.of(context);
    final c = context.colors;
    final reference = '${item.bookName(s)} ${item.chapter}:${item.verseStart}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.savedDeleteHighlightTitle,
          style: AppTypography.amharicLabel.copyWith(
            color: c.textOnParchment,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          s.savedDeleteHighlightMessage(reference),
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
      await db.deleteHighlight(item.id);
      await widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.savedHighlightDeleted)));
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

    final distinctTagsAsync = ref.watch(distinctTagsProvider);
    final selectedTags = ref.watch(selectedTagsProvider);

    return ColoredBox(
      color: context.colors.surfaceDim,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                _ColorDot(
                  color: null,
                  selected: _colorFilter == null,
                  onTap: () => setState(() => _colorFilter = null),
                ),
                for (final c in highlightPalette)
                  _ColorDot(
                    color: c,
                    selected: _colorFilter?.toARGB32() == c.toARGB32(),
                    onTap: () => setState(
                      () => _colorFilter =
                          _colorFilter?.toARGB32() == c.toARGB32() ? null : c,
                    ),
                  ),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: context.colors.borderSubtle,
                ),
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
          distinctTagsAsync.when(
            data: (tags) => TagFilterRow(
              availableTags: tags,
              selectedTags: selectedTags,
              onTagToggled: (tag) {
                final current = ref.read(selectedTagsProvider);
                if (current.contains(tag)) {
                  ref.read(selectedTagsProvider.notifier).state =
                      Set.from(current)..remove(tag);
                } else {
                  ref.read(selectedTagsProvider.notifier).state =
                      Set.from(current)..add(tag);
                }
              },
              onClearAll: () {
                ref.read(selectedTagsProvider.notifier).state = {};
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
          Expanded(
            child: items.isEmpty
                ? const AnnotationEmptyState(tab: 0)
                : RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    color: context.colors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: items.length,
                      itemBuilder: (_, i) => AnnotationCard(
                        item: items[i],
                        tab: 0,
                        onTap: () => widget.onOpen(items[i]),
                        onAddToCollection: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => CollectionPickerSheet(
                            itemType: 'highlight',
                            itemId: items[i].id,
                            initialTags: items[i].tags,
                            onItemChanged: widget.onRefresh,
                          ),
                        ),
                        onLongPress: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => CollectionPickerSheet(
                            itemType: 'highlight',
                            itemId: items[i].id,
                            initialTags: items[i].tags,
                            onItemChanged: widget.onRefresh,
                          ),
                        ),
                        onDelete: () => _deleteHighlight(items[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Color dot filter ──────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? c.surfaceDim,
          border: Border.all(
            color: selected ? c.primary : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: color == null
            ? Icon(Icons.done_all_rounded, size: 16, color: c.textMuted)
            : selected
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.black54)
            : null,
      ),
    );
  }
}
