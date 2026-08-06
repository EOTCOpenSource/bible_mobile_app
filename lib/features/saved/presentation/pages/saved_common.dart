import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/annotations/annotation_models.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../annotations/providers/annotation_providers.dart';
import '../../../books/data/models/book_index_entry.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class AnnotationItem {
  const AnnotationItem({
    required this.id,
    required this.bookEntry,
    required this.chapter,
    required this.verseStart,
    this.verseCount = 1,
    required this.verseText,
    required this.createdAt,
    this.highlightColor,
    this.noteContent,
    this.tags,
    this.itemType = 'bookmark',
  });

  final int id;
  final BookIndexEntry bookEntry;
  final int chapter;
  final int verseStart;
  final int verseCount;
  final String verseText;
  final DateTime createdAt;
  final Color? highlightColor;
  final String? noteContent;
  final String? tags;
  final String itemType;

  bool get isOT => bookEntry.isOldTestament;

  String bookName(AppStrings strings) =>
      strings is EnStrings ? bookEntry.bookNameEn : bookEntry.bookNameAm;

  String bookShortName(AppStrings strings) => strings is EnStrings
      ? bookEntry.bookShortNameEn
      : bookEntry.bookShortNameAm;
}

// ── Annotation card ──────────────────────────────────────────────────────────

class AnnotationCard extends StatelessWidget {
  const AnnotationCard({
    super.key,
    required this.item,
    required this.tab,
    required this.onTap,
    this.onLongPress,
    this.trailingText,
    this.onDelete,
  });

  final AnnotationItem item;
  final int tab;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? trailingText;
  final VoidCallback? onDelete;

  String _daysAgo(AppStrings strings) {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inDays == 0) return strings.savedToday;
    if (diff.inDays == 1) return strings.savedYesterday;
    return strings.savedDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final settings = Settings.of(context);
    final accent = tab == 0 && item.highlightColor != null
        ? item.highlightColor!
        : tab == 1
        ? c.primary
        : tab == 2
        ? c.accentDeep
        : c.textMuted;

    final chNum = settings.useGeezNumbers
        ? toGeez(item.chapter)
        : '${item.chapter}';
    final vStart = settings.useGeezNumbers
        ? toGeez(item.verseStart)
        : '${item.verseStart}';
    final vEnd = settings.useGeezNumbers
        ? toGeez(item.verseStart + item.verseCount - 1)
        : '${item.verseStart + item.verseCount - 1}';

    final chRef = item.verseCount > 1
        ? '${item.bookShortName(s)} $chNum:$vStart–$vEnd'
        : '${item.bookShortName(s)} $chNum:$vStart';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reference row
                        Row(
                          children: [
                            _TypeBadge(tab: tab, accent: accent),
                            const SizedBox(width: 8),
                            Text(
                              chRef,
                              style: TextStyle(
                                fontFamily: AppTypography.shiromeda,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              trailingText ?? _daysAgo(s),
                              style: AppTypography.amharicCaption.copyWith(
                                fontSize: 11,
                                color: c.textCaption,
                              ),
                            ),
                            if (onDelete != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onDelete,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.red.withValues(alpha: 0.70),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Body
                        if (tab == 2 && item.noteContent != null) ...[
                          Text(
                            item.noteContent!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.amharicBody.copyWith(
                              fontSize: 14,
                              color: c.textOnParchment,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              item.verseText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.amharicCaption.copyWith(
                                fontSize: 12,
                                color: c.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ] else if (tab == 0 && item.highlightColor != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: item.highlightColor!.withValues(
                                alpha: 0.20,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.verseText,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.amharicBody.copyWith(
                                fontSize: 14,
                                color: c.textOnParchment,
                                height: 1.65,
                              ),
                            ),
                          )
                        else
                          Text(
                            item.verseText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.amharicBody.copyWith(
                              fontSize: 14,
                              color: c.textOnParchment,
                              height: 1.65,
                            ),
                          ),
                        if (item.tags != null && item.tags!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final t in item.tags!.split(','))
                                if (t.trim().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${t.trim()}',
                                      style: AppTypography.amharicCaption
                                          .copyWith(
                                        fontSize: 10,
                                        color: c.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Footer
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 12,
                              color: c.textCaption,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.bookName(s),
                              style: AppTypography.amharicCaption.copyWith(
                                fontSize: 11,
                                color: c.textCaption,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: c.textCaption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.tab, required this.accent});
  final int tab;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = tab == 0
        ? Icons.format_color_fill_rounded
        : tab == 1
        ? Icons.bookmark_rounded
        : tab == 2
        ? Icons.sticky_note_2_rounded
        : Icons.history_rounded;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, size: 13, color: accent),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class AnnotationEmptyState extends StatelessWidget {
  const AnnotationEmptyState({super.key, required this.tab});
  final int tab;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final (icon, label, hint) = switch (tab) {
      0 => (
        Icons.format_color_fill_rounded,
        s.savedEmptyHighlightsTitle,
        s.savedEmptyHighlightsHint,
      ),
      1 => (
        Icons.bookmark_border_rounded,
        s.savedEmptyBookmarksTitle,
        s.savedEmptyBookmarksHint,
      ),
      _ => (
        Icons.sticky_note_2_outlined,
        s.savedEmptyNotesTitle,
        s.savedEmptyNotesHint,
      ),
    };

    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: c.borderSubtle),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTypography.amharicLabel.copyWith(
              color: c.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: AppTypography.amharicCaption.copyWith(
                color: c.textCaption,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class SavedFilterChip extends StatelessWidget {
  const SavedFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.fromLTRB(12, 6, trailing != null ? 6 : 12, 6),
        decoration: BoxDecoration(
          color: active ? c.primary : c.surfaceDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? c.primary : c.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.amharicLabel.copyWith(
                fontSize: 12,
                color: active ? Colors.white : c.textMuted,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 2),
              Icon(
                trailing,
                size: 16,
                color: active ? Colors.white : c.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Picker sheet ─────────────────────────────────────────────────────────────

class AnnotationPickerItem {
  const AnnotationPickerItem({required this.id, required this.label});
  final dynamic id;
  final String label;
}

class AnnotationPickerSheet extends StatelessWidget {
  const AnnotationPickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final String title;
  final List<AnnotationPickerItem> items;
  final dynamic selectedId;
  final ValueChanged<dynamic> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: c.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              title,
              style: AppTypography.amharicLabel.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.textOnParchment,
              ),
            ),
          ),
          Divider(color: c.borderSubtle, height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: items.length,
              separatorBuilder: (_, idx) =>
                  Divider(color: c.borderSubtle, height: 1, indent: 20),
              itemBuilder: (_, i) {
                final it = items[i];
                final isSelected = it.id == selectedId;
                return InkWell(
                  onTap: () => onSelect(it.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.label,
                            style: AppTypography.amharicLabel.copyWith(
                              fontSize: 14,
                              color: isSelected ? c.primary : c.textOnParchment,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded, size: 18, color: c.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tag Filter Row ─────────────────────────────────────────────────────────────

class TagFilterRow extends StatelessWidget {
  const TagFilterRow({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onClearAll,
  });

  final List<String> availableTags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (availableTags.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final s = L10n.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          FilterChip(
            label: Text(s.all),
            selected: selectedTags.isEmpty,
            onSelected: (_) => onClearAll(),
            selectedColor: c.primary.withValues(alpha: 0.2),
            checkmarkColor: c.primary,
            labelStyle: AppTypography.amharicCaption.copyWith(
              color: selectedTags.isEmpty ? c.primary : c.textMuted,
              fontWeight: selectedTags.isEmpty ? FontWeight.bold : FontWeight.normal,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          const SizedBox(width: 8),
          for (final tag in availableTags) ...[
            FilterChip(
              label: Text('#$tag'),
              selected: selectedTags.contains(tag),
              onSelected: (_) => onTagToggled(tag),
              selectedColor: c.primary.withValues(alpha: 0.2),
              checkmarkColor: c.primary,
              labelStyle: AppTypography.amharicCaption.copyWith(
                color: selectedTags.contains(tag) ? c.primary : c.textMuted,
                fontWeight: selectedTags.contains(tag) ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

// ── Tag Input Field ────────────────────────────────────────────────────────────

class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    this.initialTags,
    this.allDistinctTags = const [],
    required this.onTagsChanged,
  });

  final String? initialTags;
  final List<String> allDistinctTags;
  final ValueChanged<String?> onTagsChanged;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _ctrl = TextEditingController();
  final Set<String> _tags = {};
  String _typedText = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTags != null && widget.initialTags!.isNotEmpty) {
      for (final t in widget.initialTags!.split(',')) {
        if (t.trim().isNotEmpty) _tags.add(t.trim().toLowerCase());
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final norm = tag.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (norm.isNotEmpty) {
      setState(() {
        _tags.add(norm);
        _ctrl.clear();
        _typedText = '';
      });
      _notify();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _notify();
  }

  void _notify() {
    final normalized = normalizeTags(_tags.join(','));
    widget.onTagsChanged(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);
    final suggestions = widget.allDistinctTags
        .where((t) =>
            !_tags.contains(t) &&
            (_typedText.isEmpty || t.contains(_typedText.toLowerCase())))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in _tags)
              Chip(
                label: Text('#$tag',
                    style: AppTypography.amharicCaption.copyWith(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => _removeTag(tag),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        if (_tags.isNotEmpty) const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          onChanged: (val) {
            if (val.endsWith(',')) {
              _addTag(val.substring(0, val.length - 1));
            } else {
              setState(() => _typedText = val);
            }
          },
          onSubmitted: (val) => _addTag(val),
          decoration: InputDecoration(
            hintText: s.addTagHint,
            hintStyle:
                AppTypography.amharicCaption.copyWith(color: c.textMuted),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.check, size: 18),
                    onPressed: () => _addTag(_ctrl.text),
                  )
                : null,
          ),
        ),
        if (suggestions.isNotEmpty && _typedText.isNotEmpty) ...[
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final sug in suggestions) ...[
                  ActionChip(
                    label: Text('#$sug',
                        style: AppTypography.amharicCaption
                            .copyWith(fontSize: 11)),
                    onPressed: () => _addTag(sug),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Collection Picker Sheet ────────────────────────────────────────────────────

class CollectionPickerSheet extends ConsumerStatefulWidget {
  const CollectionPickerSheet({
    super.key,
    required this.itemType,
    required this.itemId,
    this.initialTags,
    required this.onItemChanged,
  });

  final String itemType;
  final int itemId;
  final String? initialTags;
  final VoidCallback onItemChanged;

  @override
  ConsumerState<CollectionPickerSheet> createState() =>
      _CollectionPickerSheetState();
}

class _CollectionPickerSheetState extends ConsumerState<CollectionPickerSheet> {
  Set<int> _linkedCollectionIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLinkedCollections();
  }

  Future<void> _loadLinkedCollections() async {
    final db = ref.read(annotationDbProvider);
    final collections = await db.listCollections();
    final linked = <int>{};
    for (final c in collections) {
      if (c.id == null) continue;
      final items = await db.listItemsInCollection(c.id!);
      if (items.any((m) =>
          m['item_type'] == widget.itemType && m['item_id'] == widget.itemId)) {
        linked.add(c.id!);
      }
    }
    if (mounted) {
      setState(() {
        _linkedCollectionIds = linked;
        _loading = false;
      });
    }
  }

  Future<void> _toggleCollection(int collectionId, bool isLinked) async {
    final db = ref.read(annotationDbProvider);
    if (isLinked) {
      await db.removeItemFromCollection(
          collectionId, widget.itemType, widget.itemId);
      setState(() => _linkedCollectionIds.remove(collectionId));
    } else {
      await db.addItemToCollection(
          collectionId, widget.itemType, widget.itemId);
      setState(() => _linkedCollectionIds.add(collectionId));
    }
    ref.invalidate(collectionsProvider);
    widget.onItemChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final collectionsAsync = ref.watch(collectionsNotifierProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.folder_special_rounded, color: c.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  s.addToCollection,
                  style: AppTypography.amharicLabel.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: c.textOnParchment,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator()))
            else
              collectionsAsync.when(
                data: (collections) {
                  return Column(
                    children: [
                      if (collections.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(s.noCollections,
                              style: AppTypography.amharicCaption
                                  .copyWith(color: c.textMuted)),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: collections.length,
                            itemBuilder: (ctx, idx) {
                              final col = collections[idx];
                              final isLinked =
                                  _linkedCollectionIds.contains(col.id);
                              return CheckboxListTile(
                                value: isLinked,
                                onChanged: col.id == null
                                    ? null
                                    : (_) => _toggleCollection(
                                        col.id!, isLinked),
                                title: Text(col.name,
                                    style: AppTypography.amharicBody
                                        .copyWith(fontSize: 14)),
                                secondary: Icon(
                                  getCollectionIconData(col.icon),
                                  color: col.color ?? c.primary,
                                ),
                                activeColor: c.primary,
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              showCreateCollectionDialog(context, ref),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(s.newCollection),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Error: $err'),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(s.savedOk),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

// ── Create Collection Dialog ───────────────────────────────────────────────────

Future<void> showCreateCollectionDialog(
    BuildContext context, WidgetRef ref) async {
  final s = L10n.of(context);
  final c = context.colors;
  final ctrl = TextEditingController();
  Color? selectedColor = c.primary;

  await showDialog<void>(
    context: context,
    builder: (dlgCtx) {
      return StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: Text(s.newCollection),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: s.collectionNameHint,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(s.collectionColorLabel, style: AppTypography.amharicCaption),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final color in highlightPalette)
                      GestureDetector(
                        onTap: () => setDlgState(() => selectedColor = color),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: selectedColor == color
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: Text(s.savedCancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = ctrl.text.trim();
                  if (name.isNotEmpty) {
                    await ref
                        .read(collectionsNotifierProvider.notifier)
                        .createCollection(
                          name,
                          color: selectedColor,
                        );
                    if (context.mounted) Navigator.pop(dlgCtx);
                  }
                },
                child: Text(s.collectionCreateAction),
              ),
            ],
          );
        },
      );
    },
  );
}

IconData getCollectionIconData(String? iconStr) {
  if (iconStr == null) return Icons.folder_outlined;
  final codePoint = int.tryParse(iconStr);
  if (codePoint == null) return Icons.folder_outlined;
  // ignore: non_const_argument_for_const_parameter
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}

