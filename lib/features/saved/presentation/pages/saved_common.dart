import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/data/models/book_index_entry.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class AnnotationItem {
  const AnnotationItem({
    required this.bookEntry,
    required this.chapter,
    required this.verseStart,
    required this.verseText,
    required this.createdAt,
    this.highlightColor,
    this.noteContent,
  });

  final BookIndexEntry bookEntry;
  final int chapter;
  final int verseStart;
  final String verseText;
  final DateTime createdAt;
  final Color? highlightColor;
  final String? noteContent;

  bool get isOT => bookEntry.isOldTestament;
}

// ── Annotation card ──────────────────────────────────────────────────────────

class AnnotationCard extends StatelessWidget {
  const AnnotationCard({
    super.key,
    required this.item,
    required this.tab,
    required this.onTap,
  });

  final AnnotationItem item;
  final int tab;
  final VoidCallback onTap;

  String _daysAgo(AppStrings s) {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inDays == 0) return s.savedToday;
    if (diff.inDays == 1) return s.savedYesterday;
    return s.savedDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final accent = tab == 0 && item.highlightColor != null
        ? item.highlightColor!
        : tab == 1
            ? c.primary
            : c.accentDeep;
    final chRef =
        '${item.bookEntry.bookShortNameAm} ${item.chapter}:${item.verseStart}';

    return GestureDetector(
      onTap: onTap,
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
                              _daysAgo(s),
                              style: AppTypography.amharicCaption.copyWith(
                                fontSize: 11,
                                color: c.textCaption,
                              ),
                            ),
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
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: accent.withValues(alpha: 0.18)),
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
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: item.highlightColor!
                                  .withValues(alpha: 0.20),
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
                        const SizedBox(height: 10),
                        // Footer
                        Row(
                          children: [
                            Icon(Icons.menu_book_outlined,
                                size: 12, color: c.textCaption),
                            const SizedBox(width: 4),
                            Text(
                              item.bookEntry.bookNameAm,
                              style: AppTypography.amharicCaption.copyWith(
                                fontSize: 11,
                                color: c.textCaption,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 11, color: c.textCaption),
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
            : Icons.sticky_note_2_rounded;

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
          s.savedHighlightsEmpty,
          s.savedHighlightsEmptyHint,
        ),
      1 => (
          Icons.bookmark_border_rounded,
          s.savedBookmarksEmpty,
          s.savedBookmarksEmptyHint,
        ),
      _ => (
          Icons.sticky_note_2_outlined,
          s.savedNotesEmpty,
          s.savedNotesEmptyHint,
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
          border: Border.all(
            color: active ? c.primary : c.borderSubtle,
          ),
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
              Icon(trailing, size: 16,
                  color: active ? Colors.white : c.textMuted),
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
              separatorBuilder: (_, idx) => Divider(
                  color: c.borderSubtle, height: 1, indent: 20),
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
                              color: isSelected
                                  ? c.primary
                                  : c.textOnParchment,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded,
                              size: 18, color: c.primary),
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
