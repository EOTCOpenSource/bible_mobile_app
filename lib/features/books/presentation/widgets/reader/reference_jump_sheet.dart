import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/settings/app_settings.dart';
import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../providers/reading_progress_providers.dart';
import '../../pages/reader_screen.dart';

class ReferenceJumpSheet extends ConsumerStatefulWidget {
  const ReferenceJumpSheet({super.key});

  @override
  ConsumerState<ReferenceJumpSheet> createState() => _ReferenceJumpSheetState();
}

class _ReferenceJumpSheetState extends ConsumerState<ReferenceJumpSheet> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime time, AppStrings s) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes.clamp(1, 59);
      return '${mins}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      final dayDiff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(time.year, time.month, time.day))
          .inDays;
      if (dayDiff == 0) return s.savedToday;
      if (dayDiff == 1) return s.savedYesterday;
      return s.savedDaysAgo(dayDiff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final isAmharic = s is AmStrings;
    final useGeez = Settings.of(context).useGeezNumbers;

    final snapshotsAsync = ref.watch(continueReadingSnapshotsProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search input field
          TextField(
            controller: _textController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: s.searchHint,
              prefixIcon: Icon(Icons.search_rounded, color: c.textMuted),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _textController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: c.surfaceDim,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content section
          if (_textController.text.trim().isEmpty) ...[
            Text(
              s.savedHistory,
              style: AppTypography.amharicLabel.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            snapshotsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, st) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  s.historyEmptyHint,
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                ),
              ),
              data: (snapshots) {
                final historySnaps = snapshots.take(5).toList();
                if (historySnaps.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        s.historyEmptyHint,
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: historySnaps.map((snap) {
                    final bookName = isAmharic
                        ? snap.entry.bookNameAm
                        : snap.entry.bookNameEn;
                    final chNum = snap.position.chapter;
                    final chStr = useGeez ? toGeez(chNum) : '$chNum';
                    final verseNum = snap.position.verse;
                    final verseStr = verseNum != null
                        ? (useGeez ? ':${toGeez(verseNum)}' : ':$verseNum')
                        : '';
                    final titleText = '$bookName $chStr$verseStr';

                    final timeText = _formatRelativeTime(
                      DateTime.fromMillisecondsSinceEpoch(snap.position.updatedAtMs),
                      s,
                    );

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.history_rounded, size: 20, color: c.primary),
                      title: Text(
                        titleText,
                        style: AppTypography.amharicBody.copyWith(
                          color: c.textOnParchment,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      trailing: Text(
                        timeText,
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReaderScreen(
                              entry: snap.entry,
                              initialChapterNumber: chNum,
                              initialVerse: verseNum,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '${s.searchRunBtn}: "${_textController.text.trim()}"',
                style: TextStyle(color: c.textMuted, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
