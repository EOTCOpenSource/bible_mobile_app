import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/book_cover.dart';
import '../../../books/presentation/pages/reader_screen.dart';
import '../../../books/providers/reading_progress_providers.dart';

/// The books you have open, most recently read first.
///
/// A strip of book covers rather than one wide card per page: the old layout
/// showed a single book at a time behind a page indicator, so the second book
/// you were reading was invisible until you swiped for it.
class ContinueReadingSection extends ConsumerWidget {
  const ContinueReadingSection({super.key, required this.onOpenBooksTab});

  final VoidCallback onOpenBooksTab;

  /// Past this the strip stops being "where was I" and turns into a history —
  /// which is what the books tab is for.
  static const int maxBooks = 10;

  /// Covers visible at rest. Enough that the strip reads as a shelf and its
  /// scrollability is obvious from the tile clipped at the edge.
  static const double _tilesInView = 3;

  /// Matches the page gutter the section title sits on.
  static const double _leadInset = 16;

  /// Wider than the gutter so the rightmost cover's drop shadow finishes
  /// inside the viewport instead of being cut against it.
  static const double _trailInset = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final c = context.colors;
    final asyncSnaps = ref.watch(continueReadingSnapshotsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            s.continueReadingTitle,
            style: AppTypography.amharicSubheading.copyWith(
              color: c.textOnParchment,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Takes the height its parent allots rather than a fixed one: Home is
        // one non-scrolling screen, so this has to give way on a short phone
        // instead of pushing the topics strip off the bottom.
        Expanded(
          child: asyncSnaps.when(
            loading: () => const _ContinueCardSkeleton(),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EmptyContinueCard(
                  colors: c, s: s, onOpenBooks: onOpenBooksTab),
            ),
            data: (snaps) {
              if (snaps.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _EmptyContinueCard(
                      colors: c, s: s, onOpenBooks: onOpenBooksTab),
                );
              }

              final recent = snaps.take(maxBooks).toList();

              // The list runs edge to edge and insets itself, rather than
              // sitting inside the section's padding. A cover throws its
              // shadow down and to the right past its own box, and with the
              // viewport stopping at the padding that shadow was sliced off
              // the last cover on screen. Now it has somewhere to land.
              return LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;
                  final shelf = constraints.maxWidth -
                      _leadInset -
                      _trailInset -
                      gap * (_tilesInView - 1);

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                        left: _leadInset, right: _trailInset),
                    itemCount: recent.length,
                    separatorBuilder: (_, _) => const SizedBox(width: gap),
                    itemBuilder: (_, i) => _BookTile(
                      snap: recent[i],
                      width: shelf / _tilesInView,
                      colors: c,
                      s: s,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One book: its cover with the name set on the face, and how far through it
/// you are underneath.
class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.snap,
    required this.width,
    required this.colors,
    required this.s,
  });

  final ContinueReadingSnapshot snap;
  final double width;
  final AppColorScheme colors;
  final AppStrings s;

  /// Height of the progress bar, its percentage, and the gap above them.
  static const double _progressBlock = 26;

  /// A closed book is taller than it is wide; covers keep that ratio until the
  /// strip is too short for it, then they shrink rather than crop.
  static const double _coverAspect = 1.42;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final useGeez = Settings.of(context).useGeezNumbers;
    final chapter = snap.position.chapter;
    final chapterLabel =
        '${s.chapterAbbr} ${useGeez ? toGeez(chapter) : chapter}';

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ReaderScreen(
                entry: snap.entry,
                initialChapterNumber: snap.position.chapter,
                initialVerse: snap.position.verse,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // BookCover reserves 10dp past the face for its page edges, so
              // the face is sized inside that rather than over it.
              final maxFaceHeight =
                  constraints.maxHeight - _progressBlock - 10;
              final faceWidth = width - 10;
              final faceHeight =
                  math.min(faceWidth * _coverAspect, maxFaceHeight);

              if (faceHeight <= 0) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Cover(
                    snap: snap,
                    faceWidth: faceWidth,
                    faceHeight: faceHeight,
                    chapterLabel: chapterLabel,
                  ),
                  const Spacer(),
                  _Progress(percent: snap.progressPercent, colors: c),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.snap,
    required this.faceWidth,
    required this.faceHeight,
    required this.chapterLabel,
  });

  final ContinueReadingSnapshot snap;
  final double faceWidth;
  final double faceHeight;
  final String chapterLabel;

  @override
  Widget build(BuildContext context) {
    // Short name, not the full one: "መዝ" fits the face at this size where
    // "መዝሙረ ዳዊት" wrapped to two lines and crowded out the chapter.
    final isAm = L10n.of(context) is AmStrings;
    final name = isAm
        ? snap.entry.bookShortNameAm
        : snap.entry.bookShortNameEn;

    return BookCover(
      coverColor: testamentColor(snap.entry.bookNameEn),
      width: faceWidth,
      height: faceHeight,
      title: name.isNotEmpty
          ? name
          : (isAm ? snap.entry.bookNameAm : snap.entry.bookNameEn),
      subtitle: chapterLabel,
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.percent, required this.colors});

  final int percent;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: c.parchmentDark,
            valueColor: AlwaysStoppedAnimation(c.primary),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$percent%',
          style: AppTypography.englishCaption.copyWith(
            color: c.primary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0,
          ),
        ),
      ],
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
          ),
          child: Row(
            children: [
              const BookCover(width: 40, height: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.streakReadTodayHint,
                      style: AppTypography.amharicLabel.copyWith(
                        color: c.textOnParchment,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.booksTitle,
                      style: AppTypography.englishCaption.copyWith(
                        color: c.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
      ),
    );
  }
}
