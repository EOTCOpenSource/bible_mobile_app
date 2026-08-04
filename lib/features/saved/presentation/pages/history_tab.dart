import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import 'saved_common.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onRefresh,
    required this.onDeleteItem,
    this.onClearHistory,
    this.onLoadMore,
    this.hasMore = false,
  });

  final List<AnnotationItem> items;
  final void Function(AnnotationItem) onOpen;
  final Future<void> Function() onRefresh;
  final void Function(int id) onDeleteItem;
  final VoidCallback? onClearHistory;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  static const _ethiopianMonthsAm = [
    'መስከረም',
    'ጥቅምት',
    'ህዳር',
    'ታኅሣሥ',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዝያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'ጳጉሜ',
  ];

  static const _ethiopianMonthsEn = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miazia',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  String _formatDate(DateTime date, AppStrings s, bool isAmharic, bool useGeez) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(date.year, date.month, date.day)).inDays;

    if (diff == 0) return s.savedToday;
    if (diff == 1) return s.savedYesterday;

    final et = Kenat(date).getEthiopian();
    final month = (et['month'] as int).clamp(1, 13);
    final day = et['day'] as int;
    final dayStr = useGeez ? toGeez(day) : '$day';
    final monthStr = isAmharic
        ? _ethiopianMonthsAm[month - 1]
        : _ethiopianMonthsEn[month - 1];
    return '$monthStr $dayStr';
  }

  String _formatTime(DateTime time, AppStrings s) {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final p = time.hour < 12 ? s.timeMorning : s.timeAfternoon;
    return '$h:$m $p';
  }

  void _confirmDeleteSingleItem(
      BuildContext context, AppStrings s, int itemId) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.savedDeleteHistoryTitle,
          style: AppTypography.amharicLabel.copyWith(
            color: c.textOnParchment,
            fontSize: 17,
            fontWeight: FontWeight.bold,
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
      onDeleteItem(itemId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;
    final isAmharic = s is AmStrings;
    final useGeez = Settings.of(context).useGeezNumbers;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: c.borderSubtle),
            const SizedBox(height: 16),
            Text(
              s.historyEmptyHint,
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
      final key = _formatDate(item.createdAt, s, isAmharic, useGeez);
      groups.putIfAbsent(key, () => []).add(item);
    }

    return ColoredBox(
      color: c.surfaceDim,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: c.primary,
        child: CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 8)),
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
                      onDelete: () =>
                          _confirmDeleteSingleItem(context, s, item.id),
                    );
                  },
                ),
              ),
            ],
            if (hasMore && onLoadMore != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: OutlinedButton(
                      onPressed: onLoadMore,
                      child: Text(s.loadMore),
                    ),
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}
