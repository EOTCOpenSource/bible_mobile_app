import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';

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
  _Ink(this.isDark)
      : page = isDark ? readerDarkBg : AppColors.parchment,
        band = isDark ? readerDarkSurface : AppColors.parchmentDark,
        card = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.55),
        text = isDark ? readerDarkText : AppColors.textOnParchment,
        muted = isDark ? readerDarkMuted : AppColors.textMuted,
        rubric = isDark ? AppColors.primaryLight : AppColors.primary,
        gilt = isDark ? readerDarkAccent : AppColors.accentDeep;

  final bool isDark;
  final Color page;
  final Color band;
  final Color card;
  final Color text;
  final Color muted;
  final Color rubric;
  final Color gilt;
}

/// How references are written: Ge'ez or Arabic numerals, `፥` or `:`.
class _Numbers {
  const _Numbers({required this.geez, required this.amharic});

  final bool geez;
  final bool amharic;

  String n(int value) => geez ? toGeez(value) : '$value';
  String get colon => amharic ? '፥' : ':';

  String reference(String book, CrossRef r) {
    final start = '$book ${n(r.chapter)}$colon${n(r.verse)}';
    if (!r.isRange) return start;
    if (r.toChapter == r.chapter) return '$start-${n(r.toVerse)}';
    return '$start-${n(r.toChapter)}$colon${n(r.toVerse)}';
  }
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

  /// USFM id of the verse's book.
  final String sourceBook;
  final int sourceChapter;
  final int sourceVerse;
  final String sourceReferenceLabel;
  final void Function(String targetBook, int targetChapter, int targetVerse)
      onSelectCrossRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    final settings = Settings.of(context);
    final asyncRefs = ref.watch(crossRefsForVerseProvider((
      book: sourceBook,
      chapter: sourceChapter,
      verse: sourceVerse,
    )));

    final ink = _Ink(settings.isDarkReader);
    final numbers = _Numbers(
      geez: settings.useGeezNumbers,
      amharic: s is AmStrings,
    );
    final bodyFont = readerFonts[settings.bodyFontIndex];
    final mediaQuery = MediaQuery.of(context);

    final sheetContent = Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.8),
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
            Flexible(
              child: asyncRefs.when(
                loading: () => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ink.rubric,
                      ),
                    ),
                  ),
                ),
                // A failed lookup and an empty one read the same to a reader:
                // scripture nobody has linked here. Saying "error" would blame
                // them for it.
                error: (err, stack) => _Empty(s: s, ink: ink),
                data: (refs) {
                  if (refs.isEmpty) return _Empty(s: s, ink: ink);
                  final strongest = refs.first.votes;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: refs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = refs[index];
                      return _CrossRefCard(
                        crossRef: item,
                        strongest: strongest,
                        ink: ink,
                        numbers: numbers,
                        bodyFont: bodyFont,
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
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card ────────────────────────────────────────────────────────────────────

/// One passage that echoes the verse in view.
///
/// A card, so it reads as something to tap and open, with the passage's own
/// words under its reference. Strength is said twice and quietly: a rubric
/// rule down the card's edge, fading as the list descends the way a
/// manuscript marks its margin, and the reader-vote count in the corner for
/// anyone who wants the exact figure.
class _CrossRefCard extends ConsumerWidget {
  const _CrossRefCard({
    required this.crossRef,
    required this.strongest,
    required this.ink,
    required this.numbers,
    required this.bodyFont,
    required this.onTap,
  });

  final CrossRef crossRef;

  /// The top vote count in this list, so the rule is scaled against what this
  /// verse actually offers rather than against a fixed maximum.
  final int strongest;

  final _Ink ink;
  final _Numbers numbers;
  final String bodyFont;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(crossRefTargetProvider((
      ref: crossRef,
      amharic: numbers.amharic,
    )));
    final data = target.valueOrNull;
    final label = numbers.reference(data?.bookName ?? crossRef.book, crossRef);

    // Never fully transparent: the weakest reference is still a reference, and
    // a rule that disappears would read as a rendering fault.
    final strength =
        strongest <= 0 ? 1.0 : (crossRef.votes / strongest).clamp(0.0, 1.0);
    final ruleAlpha = 0.22 + strength * 0.78;

    final verses = data?.verses ?? const [];
    final preview = verses.length == 1
        ? verses.first.text
        : verses
            .map((v) => '${v.displayNumber(useGeez: numbers.geez)} ${v.text}')
            .join(' ');

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: ink.card,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: ink.rubric.withValues(alpha: ruleAlpha),
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
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
                    const SizedBox(width: 8),
                    _Votes(votes: crossRef.votes, ink: ink, alpha: ruleAlpha),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: ink.muted.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                if (target.isLoading)
                  Container(
                    width: 160,
                    height: 11,
                    margin: const EdgeInsets.only(top: 9),
                    decoration: BoxDecoration(
                      color: ink.muted.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                else if (preview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: bodyFont,
                        color: ink.text.withValues(alpha: 0.78),
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reader votes, in the rule's ink so a strong link is dark in both places.
class _Votes extends StatelessWidget {
  const _Votes({required this.votes, required this.ink, required this.alpha});

  final int votes;
  final _Ink ink;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final color = ink.rubric.withValues(alpha: alpha);
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: ink.rubric.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up_alt_outlined, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              '$votes',
              style: AppTypography.englishCaption.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
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
    );
  }
}
