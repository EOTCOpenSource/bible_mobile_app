import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/bible_repository_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/cross_ref.dart';
import '../../providers/crossref_providers.dart';

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white54 : Colors.black54;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final maxSheetHeight = mediaQuery.size.height * 0.8;

    final sheetContent = Container(
      constraints: BoxConstraints(
        maxHeight: maxSheetHeight,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.crossRefTitle,
                        style: AppTypography.amharicSubheading.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sourceReferenceLabel,
                        style: AppTypography.amharicSubheading.copyWith(
                          fontSize: 18,
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: textColor,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Body
          Expanded(
            child: asyncRefs.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    s.crossRefNoResults,
                    style: AppTypography.amharicBody.copyWith(color: mutedColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (refs) {
                if (refs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alt_route_rounded,
                            size: 48,
                            color: mutedColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.crossRefNoResults,
                            style: AppTypography.amharicBody.copyWith(
                              color: mutedColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: refs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = refs[index];
                    return _CrossRefItemTile(
                      crossRef: item,
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

    if (screenWidth > 640) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: Colors.transparent,
            child: sheetContent,
          ),
        ),
      );
    }

    return sheetContent;
  }
}

class _CrossRefItemTile extends ConsumerWidget {
  const _CrossRefItemTile({
    required this.crossRef,
    required this.onTap,
  });

  final CrossRef crossRef;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bibleRepositoryProvider);
    final isAmharic = Localizations.localeOf(context).languageCode == 'am';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    return FutureBuilder(
      future: _loadTargetVerseData(repo, isAmharic),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final refLabel = data?.referenceLabel ?? 'Book ${crossRef.book} ${crossRef.chapter}:${crossRef.verse}';
        final textPreview = data?.verseText;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Relevance Weight Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${crossRef.weight}',
                        style: AppTypography.amharicCaption.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Reference & Verse Text Preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              refLabel,
                              style: AppTypography.amharicSubheading.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: mutedColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        Container(
                          width: 140,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: mutedColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      else if (textPreview != null && textPreview.isNotEmpty)
                        Text(
                          textPreview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.amharicBody.copyWith(
                            color: mutedColor,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_TargetVerseData> _loadTargetVerseData(dynamic repo, bool isAmharic) async {
    try {
      final entry = await repo.findBook(crossRef.book);
      String bookName;
      if (entry != null) {
        bookName = isAmharic ? entry.bookNameAm : entry.bookNameEn;
      } else {
        bookName = 'Book ${crossRef.book}';
      }

      final range = crossRef.toVerse != null && crossRef.toVerse != crossRef.verse
          ? '-${crossRef.toVerse}'
          : '';
      final refLabel = '$bookName ${crossRef.chapter}:${crossRef.verse}$range';

      String? verseText;
      if (entry != null) {
        final book = await repo.loadBook(entry);
        for (final chap in book.chapters) {
          if (chap.chapterNumber == crossRef.chapter) {
            for (final verse in chap.verses) {
              if (verse.verseNumber == crossRef.verse) {
                verseText = verse.text;
                break;
              }
            }
            break;
          }
        }
      }

      return _TargetVerseData(referenceLabel: refLabel, verseText: verseText);
    } catch (_) {
      final range = crossRef.toVerse != null && crossRef.toVerse != crossRef.verse
          ? '-${crossRef.toVerse}'
          : '';
      return _TargetVerseData(
        referenceLabel: 'Book ${crossRef.book} ${crossRef.chapter}:${crossRef.verse}$range',
        verseText: null,
      );
    }
  }
}

class _TargetVerseData {
  const _TargetVerseData({
    required this.referenceLabel,
    this.verseText,
  });

  final String referenceLabel;
  final String? verseText;
}
