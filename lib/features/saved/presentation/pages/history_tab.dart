import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import 'saved_common.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onRefresh,
    required this.onClearHistory,
  });

  final List<AnnotationItem> items;
  final void Function(AnnotationItem) onOpen;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearHistory;

  String _formatDate(DateTime date, AppStrings s) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(date.year, date.month, date.day)).inDays;

    if (diff == 0) return s.savedToday;
    if (diff == 1) return s.savedYesterday;

    return s.savedDaysAgo(diff);
  }

  String _formatTime(DateTime time, AppStrings s) {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    if (s is AmStrings) {
      final p = time.hour < 12 ? 'ጠዋት' : 'ከሰዓት';
      return '$h:$m $p';
    } else {
      final p = time.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $p';
    }
  }

  void _confirmClear(BuildContext context, AppStrings s) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.savedClearHistoryTitle,
          style: AppTypography.amharicLabel.copyWith(
            color: c.textOnParchment,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          s.savedClearHistoryMessage,
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
              s.savedClearHistory,
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
      onClearHistory();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: c.borderSubtle),
            const SizedBox(height: 16),
            Text(
              s.savedHistory,
              style: AppTypography.amharicBody.copyWith(
                fontSize: 15,
                color: c.textCaption,
              ),
            ),
          ],
        ),
      );
    }

    final groups = <String, List<AnnotationItem>>{};
    for (final item in items) {
      final key = _formatDate(item.createdAt, s);
      groups.putIfAbsent(key, () => []).add(item);
    }

    return ColoredBox(
      color: c.surfaceDim,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: c.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextButton.icon(
                    onPressed: () => _confirmClear(context, s),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: Text(s.savedClearHistory),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      textStyle: AppTypography.amharicLabel,
                    ),
                  ),
                ),
              ),
            ),
            for (final entry in groups.entries) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    entry.key,
                    style: AppTypography.amharicLabel.copyWith(
                      color: c.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: entry.value.length,
                  itemBuilder: (_, i) {
                    final item = entry.value[i];
                    return AnnotationCard(
                      item: item,
                      tab: 3,
                      trailingText: _formatTime(item.createdAt, s),
                      onTap: () => onOpen(item),
                    );
                  },
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}
