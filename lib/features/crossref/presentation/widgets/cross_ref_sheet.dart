import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/presentation/widgets/reader/constants.dart';
import '../../data/models/cross_ref.dart';
import '../../providers/crossref_providers.dart';

/// The palette this sheet is drawn in.
///
/// Parchment and ink, with the burgundy of manuscript rubrication and the gilt
/// of an illuminated initial — the same four roles the reader already uses, so
/// the sheet reads as the page it was opened from rather than as a white card
/// dropped on top of it.
///
/// Night mode is a setting of this app, not the platform's brightness:
/// `Theme.of(context).brightness` answers a different question and says
/// "light" on a dark reader.
class _Ink {
  _Ink(bool isDark)
      : page = isDark ? readerDarkBg : AppColors.parchment,
        band = isDark ? readerDarkSurface : AppColors.parchmentDark,
        text = isDark ? readerDarkText : AppColors.textOnParchment,
        muted = isDark ? readerDarkMuted : AppColors.textMuted,
        rubric = isDark ? AppColors.primaryLight : AppColors.primary,
        gilt = isDark ? readerDarkAccent : AppColors.accentDeep;

  final Color page;
  final Color band;
  final Color text;
  final Color muted;
  final Color rubric;
  final Color gilt;
}

/// The passages that echo the verse in view.
class CrossRefSheet extends ConsumerWidget {
  const CrossRefSheet({
    super.key,
    required this.sourceBook,
    required this.sourceChapter,
    required this.sourceVerse,
    required this.sourceReferenceLabel,
    required this.onSelectCrossRef,
  });

  final int sourceBook;
  final int sourceChapter;
  final int sourceVerse;
  final String sourceReferenceLabel;
  final void Function(int targetBook, int targetChapter, int targetVerse) onSelectCrossRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final asyncRefs = ref.watch(
      crossRefsForVerseProvider((
        book: sourceBook,
        chapter: sourceChapter,
        verse: sourceVerse,
      )),
    );

    final ink = _Ink(Settings.of(context).isDarkReader);
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.8;

    final sheetContent = Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: ink.page,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              s: s,
              ink: ink,
              sourceReferenceLabel: sourceReferenceLabel,
              count: asyncRefs.valueOrNull?.length,
            ),
            Expanded(
              child: asyncRefs.when(
                loading: () => Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ink.rubric,
                    ),
                  ),
                ),
                // A failed lookup and an empty one read the same to a reader:
                // scripture nobody has linked here. Saying "error" would blame
                // them for it.
                error: (err, stack) => _Empty(s: s, ink: ink),
                data: (refs) {
                  if (refs.isEmpty) return _Empty(s: s, ink: ink);

                  final strongest = refs.first.weight;
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    itemCount: refs.length,
                    itemBuilder: (context, index) {
                      final item = refs[index];
                      return _CrossRefRow(
                        crossRef: item,
                        strongest: strongest,
                        ink: ink,
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelectCrossRef(item.book, item.chapter, item.verse);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (mediaQuery.size.width > 640) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(color: Colors.transparent, child: sheetContent),
        ),
      );
    }
    return sheetContent;
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

/// The binding at the top of the page: what this list is, and of what.
class _Header extends StatelessWidget {
  const _Header({
    required this.s,
    required this.ink,
    required this.sourceReferenceLabel,
    required this.count,
  });

  final AppStrings s;
  final _Ink ink;
  final String sourceReferenceLabel;

  /// Null until the lookup lands — the line simply has one fewer thing in it
  /// rather than reserving space for a number that may never come.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ink.band,
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: ink.muted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AbbaGarima is the app's liturgical face, kept for section
                    // labels. A cross-reference list is exactly that kind of
                    // marginal apparatus, so the eyebrow is set in it rather
                    // than in the reading face.
                    Text(
                      s.crossRefTitle,
                      style: AppTypography.liturgicalHeading.copyWith(
                        color: ink.rubric,
                        fontSize: 11,
                        height: 1.2,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            sourceReferenceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.amharicSubheading.copyWith(
                              color: ink.text,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            s.crossRefCount(count!),
                            style: AppTypography.amharicCaption.copyWith(
                              color: ink.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                iconSize: 22,
                color: ink.muted,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Row ─────────────────────────────────────────────────────────────────────

/// One passage that echoes the verse in view.
///
/// The relevance weight used to be a starred badge in the leading position —
/// the loudest thing in the row, and the one thing a reader has no use for as a
/// number. Here it sets the intensity of the rubric rule down the left edge
/// instead, the way a manuscript marks its margin: because the list arrives
/// sorted by weight, the rule fades as you scroll and shows you where the
/// strong references stop without asking you to read a single digit.
class _CrossRefRow extends ConsumerWidget {
  const _CrossRefRow({
    required this.crossRef,
    required this.strongest,
    required this.ink,
    required this.onTap,
  });

  final CrossRef crossRef;

  /// The top weight in this list, so the rule is scaled against what this verse
  /// actually offers rather than against a fixed maximum no data may reach.
  final int strongest;

  final _Ink ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAmharic = L10n.of(context) is AmStrings;

    final target = ref.watch(crossRefTargetProvider((
      book: crossRef.book,
      chapter: crossRef.chapter,
      verse: crossRef.verse,
      toVerse: crossRef.toVerse,
      amharic: isAmharic,
    )));

    final data = target.valueOrNull;
    final refLabel = data?.referenceLabel ??
        'Book ${crossRef.book} ${crossRef.chapter}:${crossRef.verse}';
    final preview = data?.verseText;

    // Never fully transparent: the weakest reference is still a reference, and
    // a rule that disappears would read as a rendering fault.
    final strength = strongest <= 0
        ? 1.0
        : (crossRef.weight / strongest).clamp(0.0, 1.0);
    final ruleAlpha = 0.22 + strength * 0.78;

    return InkWell(
      onTap: onTap,
      // 6 + 3 + 11 puts the text on the same 20dp line as the header while
      // leaving the rule standing in a margin of its own. Flush to the sheet's
      // edge it read as a rendering seam rather than as a mark on the page.
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 13, 20, 13),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: ink.rubric.withValues(alpha: ruleAlpha),
                width: 3,
              ),
            ),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    refLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicLabel.copyWith(
                      color: ink.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // The same alpha as the rule in the margin, on purpose: the
                // number and the stroke are one datum said twice, so a strong
                // reference is dark in both places and a faint one is faint in
                // both. Scale is then legible at a glance and exact on a look.
                Text(
                  '${crossRef.weight}',
                  style: AppTypography.englishCaption.copyWith(
                    color: ink.rubric.withValues(alpha: ruleAlpha),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (target.isLoading)
              Container(
                width: 150,
                height: 11,
                margin: const EdgeInsets.only(top: 9),
                decoration: BoxDecoration(
                  color: ink.muted.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else if (preview != null && preview.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.amharicVerse.copyWith(
                  color: ink.muted,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty ───────────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty({required this.s, required this.ink});

  final AppStrings s;
  final _Ink ink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.horizontal_rule_rounded,
              size: 34,
              color: ink.gilt.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              s.crossRefNoResults,
              textAlign: TextAlign.center,
              style: AppTypography.amharicBody.copyWith(
                color: ink.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
