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
import '../../../books/data/models/book_index_entry.dart';
import '../../../books/providers/reading_progress_providers.dart';
import '../../providers/starter_books_provider.dart';

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
  ///
  /// The same constant the provider queries with, so the strip can never ask
  /// for more books than were fetched.
  static const int maxBooks = continueReadingBookLimit;

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

    // Nothing read yet means the shelf is offering books rather than resuming
    // them, and the heading has to say so.
    final hasHistory = asyncSnaps.value?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            hasHistory ? s.continueReadingTitle : s.startReadingTitle,
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
              // A fresh install used to get one card that only said "go to the
              // books tab". It now gets books it can actually open.
              if (snaps.isEmpty) {
                return _StarterShelf(
                  colors: c,
                  s: s,
                  onOpenBooks: onOpenBooksTab,
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
                      entry: recent[i].entry,
                      width: shelf / _tilesInView,
                      subtitle: _chapterLabel(context, s, recent[i].position.chapter),
                      footer: _Progress(
                          percent: recent[i].progressPercent, colors: c),
                      onTap: () => _openReader(
                        context,
                        recent[i].entry,
                        chapter: recent[i].position.chapter,
                        verse: recent[i].position.verse,
                      ),
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

/// Shared geometry for the shelf: how wide a tile is, how the cover is sized
/// inside it, and where the footer sits. Both shelves — books you are reading
/// and books you could start — are the same object with a different footer.
class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.entry,
    required this.width,
    required this.subtitle,
    required this.footer,
    required this.onTap,
  });

  final BookIndexEntry entry;
  final double width;

  /// The line under the name on the cover face.
  final String subtitle;

  /// Drawn under the cover — progress, or a call to action.
  final Widget footer;
  final VoidCallback onTap;

  /// Height of the footer and the gap above it.
  static const double _footerBlock = 26;

  /// A closed book is taller than it is wide; covers keep that ratio until the
  /// strip is too short for it, then they shrink rather than crop.
  static const double _coverAspect = 1.42;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // BookCover reserves 10dp past the face for its page edges, so
              // the face is sized inside that rather than over it.
              final maxFaceHeight = constraints.maxHeight - _footerBlock - 10;
              final faceWidth = width - 10;
              final faceHeight =
                  math.min(faceWidth * _coverAspect, maxFaceHeight);

              if (faceHeight <= 0) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Cover(
                    entry: entry,
                    faceWidth: faceWidth,
                    faceHeight: faceHeight,
                    subtitle: subtitle,
                  ),
                  const Spacer(),
                  footer,
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
    required this.entry,
    required this.faceWidth,
    required this.faceHeight,
    required this.subtitle,
  });

  final BookIndexEntry entry;
  final double faceWidth;
  final double faceHeight;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // Short name, not the full one: "መዝ" fits the face at this size where
    // "መዝሙረ ዳዊት" wrapped to two lines and crowded out the chapter.
    final isAm = L10n.of(context) is AmStrings;
    final name = isAm ? entry.bookShortNameAm : entry.bookShortNameEn;

    return BookCover(
      coverColor: testamentColor(entry.bookNameEn),
      width: faceWidth,
      height: faceHeight,
      title: name.isNotEmpty
          ? name
          : (isAm ? entry.bookNameAm : entry.bookNameEn),
      subtitle: subtitle,
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

// ── Starter shelf ────────────────────────────────────────────────────────────

/// What the shelf shows before anything has been read.
///
/// Suggested books rather than a card pointing at the books tab: the first
/// thing a new reader sees should be openable, not a signpost.
class _StarterShelf extends ConsumerWidget {
  const _StarterShelf({
    required this.colors,
    required this.s,
    required this.onOpenBooks,
  });

  final AppColorScheme colors;
  final AppStrings s;
  final VoidCallback onOpenBooks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    final books = ref.watch(starterBooksProvider).value ?? const [];

    // No edition installed yet, so there is nothing to suggest — the signpost
    // is still the only honest thing to show.
    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _EmptyContinueCard(colors: c, s: s, onOpenBooks: onOpenBooks),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final shelf = constraints.maxWidth -
            ContinueReadingSection._leadInset -
            ContinueReadingSection._trailInset -
            gap * (ContinueReadingSection._tilesInView - 1);

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: ContinueReadingSection._leadInset,
            right: ContinueReadingSection._trailInset,
          ),
          itemCount: books.length,
          separatorBuilder: (_, _) => const SizedBox(width: gap),
          itemBuilder: (_, i) => _BookTile(
            entry: books[i],
            width: shelf / ContinueReadingSection._tilesInView,
            subtitle: _chapterCountLabel(context, s, books[i]),
            footer: _StartAction(label: s.startReadingAction, colors: c),
            onTap: () => _openReader(context, books[i], chapter: 1),
          ),
        );
      },
    );
  }
}

/// Stands where the progress bar sits on a book already being read, so the two
/// shelves line up rather than one riding higher than the other.
class _StartAction extends StatelessWidget {
  const _StartAction({required this.label, required this.colors});

  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      children: [
        Icon(Icons.play_arrow_rounded, size: 14, color: c.primary),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amharicCaption.copyWith(
              color: c.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

String _chapterLabel(BuildContext context, AppStrings s, int chapter) {
  final useGeez = Settings.of(context).useGeezNumbers;
  return '${s.chapterAbbr} ${useGeez ? toGeez(chapter) : chapter}';
}

/// How long the book is, for a reader deciding where to start.
String _chapterCountLabel(
    BuildContext context, AppStrings s, BookIndexEntry entry) {
  final count = entry.chapterCount;
  if (count == null || count <= 0) return '';
  final useGeez = Settings.of(context).useGeezNumbers;
  return '${useGeez ? toGeez(count) : count} ${s.booksChapterSuffix}';
}

void _openReader(
  BuildContext context,
  BookIndexEntry entry, {
  required int chapter,
  int? verse,
}) {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ReaderScreen(
        entry: entry,
        initialChapterNumber: chapter,
        initialVerse: verse,
      ),
    ),
  );
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
