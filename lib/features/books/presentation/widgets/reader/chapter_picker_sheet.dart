import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/book.dart';
import '../../../data/models/book_index_entry.dart';

/// Chapter grid for the reader's toolbar label.
///
/// The label has always looked tappable — it carries a dropdown chevron — but
/// was wired to nothing, so the only way to reach a distant chapter was to swipe
/// through every page between.
///
/// Numbers come from [Chapter.chapterNumber] rather than from the index: a few
/// books do not start at 1 in every edition, and the grid has to send the reader
/// to the chapter it printed.
class ReaderChapterPicker extends StatefulWidget {
  const ReaderChapterPicker({
    super.key,
    required this.entry,
    required this.chapters,
    required this.currentIndex,
    required this.useGeez,
    required this.isAmharic,
    required this.s,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.titleFontFamily,
    required this.onSelect,
  });

  final BookIndexEntry entry;
  final List<Chapter> chapters;

  /// Index into [chapters] of the page the reader is on.
  final int currentIndex;

  final bool useGeez;
  final bool isAmharic;
  final AppStrings s;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final String titleFontFamily;
  final ValueChanged<int> onSelect;

  @override
  State<ReaderChapterPicker> createState() => _ReaderChapterPickerState();
}

class _ReaderChapterPickerState extends State<ReaderChapterPicker> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    // Opens showing the current chapter: in Psalms, chapter 119 is fourteen
    // screens down, and a picker that always starts at 1 is no better than
    // swiping there.
    final rows = (widget.currentIndex / 5).floor();
    _controller = ScrollController(
      initialScrollOffset: rows > 2 ? (rows - 2) * 60.0 : 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final chapters = widget.chapters;
    final useGeez = widget.useGeez;
    final textColor = widget.textColor;
    final mutedColor = widget.mutedColor;
    final accentColor = widget.accentColor;

    final bookName = widget.isAmharic ? entry.bookNameAm : entry.bookNameEn;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.surfaceColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bookName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: widget.titleFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    '${chapters.length} ${widget.s.chapterAbbr}',
                    style: TextStyle(fontSize: 11.5, color: mutedColor),
                  ),
                ],
              ),
            ),
            Flexible(
              child: GridView.builder(
                controller: _controller,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                physics: const BouncingScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.05,
                ),
                itemCount: chapters.length,
                itemBuilder: (ctx, i) {
                  final number = chapters[i].chapterNumber;
                  final isCurrent = i == widget.currentIndex;
                  return _ChapterButton(
                    label: useGeez
                        ? (chapters[i].alt?.isNotEmpty == true
                            ? chapters[i].alt!
                            : toGeez(number))
                        : '$number',
                    isCurrent: isCurrent,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    useGeez: useGeez,
                    onTap: () => widget.onSelect(i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterButton extends StatelessWidget {
  const _ChapterButton({
    required this.label,
    required this.isCurrent,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.useGeez,
    required this.onTap,
  });

  final String label;
  final bool isCurrent;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool useGeez;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent
              ? accentColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? accentColor.withValues(alpha: 0.55)
                : mutedColor.withValues(alpha: 0.22),
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontFamily: useGeez
                  ? AppTypography.shiromeda
                  : AppTypography.nokiaPureheadline,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isCurrent ? accentColor : textColor,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
