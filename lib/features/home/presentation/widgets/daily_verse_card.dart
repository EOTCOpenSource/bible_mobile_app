import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/data/repositories/bible_repository.dart';
import '../../../books/presentation/pages/reader_screen.dart';

class DailyVerseCard extends StatefulWidget {
  const DailyVerseCard({super.key});

  @override
  State<DailyVerseCard> createState() => _DailyVerseCardState();
}

class _DailyVerseCardState extends State<DailyVerseCard> {
  Future<DailyVerseResult?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<DailyVerseResult?> _load() {
    final et    = Kenat.now().getEthiopian();
    final month = et['month'] as int;
    final day   = et['day']   as int;
    return BibleRepositoryProvider.of(context).loadDailyVerse(month, day);
  }

  void _retry() => setState(() => _future = _load());

  String _formatRef(DailyVerseResult r, bool useGeez) {
    final ch = useGeez ? toGeez(r.chapter) : '${r.chapter}';
    final v  = useGeez ? toGeez(r.verse)   : '${r.verse}';
    return '${r.bookNameAm} $ch:$v';
  }

  void _openInReader(BuildContext context, DailyVerseResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          entry:          result.bookEntry,
          initialChapter: result.chapter - 1,
          initialVerse:   result.verse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s       = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;

    return FutureBuilder<DailyVerseResult?>(
      future: _future,
      builder: (context, snapshot) {
        final result    = snapshot.data;
        final verseText = result?.text ?? '';
        final reference = result != null ? _formatRef(result, useGeez) : '';

        final c = context.colors;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tag row ────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.dailyVerseTag,
                        style: AppTypography.amharicCaption.copyWith(
                          color: c.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppIcons.ethiopianCross,
                      style: TextStyle(
                        color: c.accent.withValues(alpha: 0.55),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Verse text ─────────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: switch (snapshot.connectionState) {
                    ConnectionState.waiting =>
                      _LoadingLines(key: const ValueKey('loading')),
                    _ when verseText.isEmpty => GestureDetector(
                        key: const ValueKey('empty'),
                        onTap: _retry,
                        child: Row(
                          children: [
                            Icon(Icons.refresh_rounded,
                                size: 18,
                                color: c.textOnDark.withValues(alpha: 0.8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.dailyVerseUnavailable,
                                style: AppTypography.amharicBody.copyWith(
                                  color: c.textOnDark.withValues(alpha: 0.85),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _ => Text(
                        key: const ValueKey('verse'),
                        verseText,
                        style: AppTypography.amharicVerse.copyWith(
                          color: c.textOnDark,
                          height: 1.9,
                          fontSize: 18,
                        ),
                      ),
                  },
                ),
                const SizedBox(height: 18),
                // ── Reference link + actions ───────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: result != null
                          ? () => _openInReader(context, result)
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reference,
                            style: AppTypography.amharicLabel.copyWith(
                              color: c.accent.withValues(alpha: 0.9),
                              fontSize: 13,
                              decoration: result != null
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor:
                                  c.accent.withValues(alpha: 0.6),
                            ),
                          ),
                          if (result != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 11,
                              color: c.accent.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    _IconAction(icon: Icons.share_outlined),
                    const SizedBox(width: 2),
                    _IconAction(icon: Icons.bookmark_border_rounded),
                    const SizedBox(width: 2),
                    _IconAction(icon: Icons.volume_up_outlined),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingLines extends StatelessWidget {
  const _LoadingLines({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(0.9),
        const SizedBox(height: 8),
        _line(0.75),
        const SizedBox(height: 8),
        _line(0.6),
      ],
    );
  }

  Widget _line(double widthFraction) => FractionallySizedBox(
        widthFactor: widthFraction,
        child: Container(
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: context.colors.textOnDark),
        ),
      ),
    );
  }
}
