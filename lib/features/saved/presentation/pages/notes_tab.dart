import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../annotations/providers/annotation_providers.dart';
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

  List<AnnotationItem> get _filtered {
    return widget.items.where((item) {
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
  }

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





  void _deleteNote(AnnotationItem item) async {
    final s = L10n.of(context);
    final reference = '${item.bookName(s)} ${item.chapter}:${item.verseStart}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: Icons.delete_outline_rounded,
        title: s.savedDeleteNoteTitle,
        caption: 'DELETE',
        actions: AppDialogActions(
          cancelLabel: s.savedCancel,
          onCancel: () => Navigator.pop(ctx, false),
          confirmLabel: s.savedDelete,
          destructive: true,
          onConfirm: () => Navigator.pop(ctx, true),
        ),
        children: [
          Text(
            s.savedDeleteNoteMessage(reference),
            style: AppTypography.amharicBody.copyWith(
              color: context.colors.textMuted,
              fontSize: 14,
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

  bool _isMultiSelect = false;
  final Set<int> _selectedIds = {};

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isMultiSelect = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterMultiSelect(int id) {
    setState(() {
      _isMultiSelect = true;
      _selectedIds.add(id);
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _isMultiSelect = false;
      _selectedIds.clear();
    });
  }

  Future<void> _batchDeleteNotes() async {
    final s = L10n.of(context);
    final count = _selectedIds.length;
    if (count == 0) return;

    await showDialog<void>(
      context: context,
      builder: (dlgCtx) => AppDialog(
        icon: Icons.delete_outline_rounded,
        title: s.deleteSelectedTitle,
        caption: 'NOTES',
        actions: AppDialogActions(
          cancelLabel: s.savedCancel,
          onCancel: () => Navigator.pop(dlgCtx),
          confirmLabel: s.savedDelete,
          destructive: true,
          onConfirm: () async {
            final db = ref.read(annotationDbProvider);
            for (final id in _selectedIds.toList()) {
              await db.deleteNote(id);
            }
            _exitMultiSelect();
            await widget.onRefresh();
            if (dlgCtx.mounted) Navigator.pop(dlgCtx);
          },
        ),
        children: [
          Text(
            s.deleteSelectedMessage(count),
            style: AppTypography.amharicBody.copyWith(
              color: context.colors.textOnParchment,
            ),
          ),
        ],
      ),
    );
  }

  void _batchAddToCollection() {
    if (_selectedIds.isEmpty) return;
    final firstId = _selectedIds.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CollectionPickerSheet(
        itemType: 'note',
        itemId: firstId,
        onItemChanged: () async {
          await widget.onRefresh();
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
    final currentBookEntry =
        _bookFilter == null
            ? null
            : widget.items
                .where((item) => item.bookEntry.id == _bookFilter)
                .firstOrNull
                ?.bookEntry;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ColoredBox(
        color: context.colors.surfaceDim,
        child: Column(
          children: [
            if (_isMultiSelect)
              MultiSelectHeaderBar(
                selectedCount: _selectedIds.length,
                onClose: _exitMultiSelect,
              )
            else
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
                        _testamentFilter =
                            _testamentFilter == 'OT' ? null : 'OT';
                        _bookFilter = null;
                        _chapterFilter = null;
                      }),
                    ),
                    const SizedBox(width: 6),
                    SavedFilterChip(
                      label: s.savedFilterNew,
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
                    if (_bookFilter != null &&
                        availableChapters.length > 1) ...[
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
                          isMultiSelect: _isMultiSelect,
                          isSelected: _selectedIds.contains(items[i].id),
                          onSelectToggle: (_) => _toggleSelect(items[i].id),
                          onTap: () {
                            if (_isMultiSelect) {
                              _toggleSelect(items[i].id);
                            } else {
                              widget.onOpen(items[i]);
                            }
                          },
                          onAddToCollection: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => CollectionPickerSheet(
                              itemType: 'note',
                              itemId: items[i].id,
                              onItemChanged: widget.onRefresh,
                            ),
                          ),
                          onLongPress: () => _enterMultiSelect(items[i].id),
                          onDelete: () => _deleteNote(items[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isMultiSelect
          ? MultiSelectBottomActionBar(
              selectedCount: _selectedIds.length,
              onAddToCollection: _batchAddToCollection,
              onDelete: _batchDeleteNotes,
            )
          : null,
    );
  }
}
