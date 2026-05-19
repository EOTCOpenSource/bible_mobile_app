import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/presentation/pages/reader_screen.dart';
import '../../../books/providers/reading_progress_providers.dart';

class ContinueReadingSection extends ConsumerStatefulWidget {
  const ContinueReadingSection({super.key, required this.onOpenBooksTab});

  final VoidCallback onOpenBooksTab;

  @override
  ConsumerState<ContinueReadingSection> createState() =>
      _ContinueReadingSectionState();
}

class _ContinueReadingSectionState
    extends ConsumerState<ContinueReadingSection> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final asyncSnaps = ref.watch(continueReadingSnapshotsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.continueReadingTitle,
            style: AppTypography.amharicSubheading.copyWith(
              color: c.textOnParchment,
            ),
          ),
          const SizedBox(height: 12),
          asyncSnaps.when(
            data: (snaps) {
              if (snaps.isEmpty) {
                return _EmptyContinueCard(
                  colors: c,
                  s: s,
                  onOpenBooks: widget.onOpenBooksTab,
                );
              }
              if (snaps.length == 1) {
                return _ContinueReadingCard(snap: snaps.first, colors: c, s: s);
              }
              return Column(
                children: [
                  SizedBox(
                    height: 122,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: snaps.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (_, i) =>
                          _ContinueReadingCard(snap: snaps[i], colors: c, s: s),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DotIndicator(
                    count: snaps.length,
                    current: _currentPage,
                    color: c.primary,
                  ),
                ],
              );
            },
            loading: () => const _ContinueCardSkeleton(),
            error: (_, _) => _EmptyContinueCard(
              colors: c,
              s: s,
              onOpenBooks: widget.onOpenBooksTab,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.count,
    required this.current,
    required this.color,
  });

  final int count;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.snap,
    required this.colors,
    required this.s,
  });

  final ContinueReadingSnapshot snap;
  final AppColorScheme colors;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final pct = (snap.progressPercent / 100).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ReaderScreen(
                entry: snap.entry,
                initialChapterNumber: snap.position.chapter,
                initialVerse: snap.position.verse,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const _ClosedBookCover(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snap.entry.bookNameAm,
                      style: AppTypography.amharicLabel.copyWith(
                        color: c.textOnParchment,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${snap.entry.bookNameEn} · ${s.chapterAbbr} ${snap.position.chapter}',
                      style: AppTypography.englishCaption.copyWith(
                        color: c.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: c.parchmentDark,
                              valueColor: AlwaysStoppedAnimation(c.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${snap.progressPercent}%',
                          style: AppTypography.englishCaption.copyWith(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: c.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContinueCard extends StatelessWidget {
  const _EmptyContinueCard({
    required this.colors,
    required this.s,
    required this.onOpenBooks,
  });

  final AppColorScheme colors;
  final AppStrings s;
  final VoidCallback onOpenBooks;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenBooks,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const _ClosedBookCover(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.streakReadTodayHint,
                      style: AppTypography.amharicLabel.copyWith(
                        color: c.textOnParchment,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.booksTitle,
                      style: AppTypography.englishCaption.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCardSkeleton extends StatelessWidget {
  const _ContinueCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderSubtle),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
      ),
    );
  }
}

/// Closed Bible cover: spine gradient, stacked “page” shadows, gold inlay, simple cross (swap later).
class _ClosedBookCover extends StatelessWidget {
  const _ClosedBookCover();

  static const double _w = 56;
  static const double _h = 84;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pageEdge1 = c.surface;
    const pageEdge2 = Color(0xFFE6DFD3);

    return SizedBox(
      width: _w + 10,
      height: _h + 10,
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: _w,
          height: _h,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
              bottomLeft: Radius.circular(4),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [c.primaryDark, c.primary, c.primary],
              stops: const [0, 0.12, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(7, 10),
                blurRadius: 12,
                spreadRadius: 0,
              ),
              BoxShadow(color: c.primary, offset: const Offset(4, 4), blurRadius: 0),
              BoxShadow(color: pageEdge2, offset: const Offset(3, 3), blurRadius: 0),
              BoxShadow(color: pageEdge1, offset: const Offset(2, 2), blurRadius: 0),
              BoxShadow(color: pageEdge2, offset: const Offset(1.5, 1.5), blurRadius: 0),
              BoxShadow(color: pageEdge1, offset: const Offset(1, 1), blurRadius: 0),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 5,
                top: 0,
                bottom: 0,
                width: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0DFFFFFF),
                        offset: Offset(1, 0),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 9,
                top: 4,
                right: 4,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                      bottomLeft: Radius.circular(2),
                    ),
                    border: Border.all(
                      color: c.accent.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: CustomPaint(
                    size: const Size(16, 22),
                    painter: _SimpleGoldCrossPainter(color: c.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches the HTML SVG: vertical + horizontal bar, round caps (viewBox 24×32, stroke 3).
class _SimpleGoldCrossPainter extends CustomPainter {
  _SimpleGoldCrossPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w / 24;
    final sy = h / 32;
    final stroke = 3 * ((sx + sy) / 2).clamp(1.8, 3.2);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = 12 * sx;
    final top = 2 * sy;
    final bottom = 30 * sy;
    final left = 2 * sx;
    final right = 22 * sx;
    final midY = 10 * sy;

    canvas.drawLine(Offset(cx, top), Offset(cx, bottom), paint);
    canvas.drawLine(Offset(left, midY), Offset(right, midY), paint);
  }

  @override
  bool shouldRepaint(covariant _SimpleGoldCrossPainter oldDelegate) =>
      oldDelegate.color != color;
}
