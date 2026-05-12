import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/book.dart';
import '../../data/models/book_index_entry.dart';
import 'reader_screen.dart';
import '../../../search/presentation/pages/search_tab.dart';

class ChapterSelectorScreen extends StatefulWidget {
  const ChapterSelectorScreen({super.key, required this.entry});
  final BookIndexEntry entry;

  @override
  State<ChapterSelectorScreen> createState() => _ChapterSelectorScreenState();
}

class _ChapterSelectorScreenState extends State<ChapterSelectorScreen> {
  Book? _book;
  bool _loading = true;
  bool _initialized = false;

  // Placeholder progress — will come from persistence layer later
  static const _lastChapterIdx = 0;
  static const _lastVerseNum   = 1;
  // In real app: Set<int> _readChapters, Set<int> _bookmarkedChapters

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) { _initialized = true; _loadBook(); }
  }

  Future<void> _loadBook() async {
    final book = await BibleRepositoryProvider.of(context).loadBook(widget.entry);
    if (mounted) setState(() { _book = book; _loading = false; });
  }

  void _openChapter(int idx) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(entry: widget.entry, initialChapter: idx),
      ),
    );
  }

  double get _progress {
    final total = _book?.chapters.length ?? 1;
    return (_lastChapterIdx / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final s        = L10n.of(context);
    final useGeez  = Settings.of(context).useGeezNumbers;
    final isAmharic = s is AmStrings;
    final total    = _book?.chapters.length ?? (widget.entry.chapterCount ?? 0);

    return Scaffold(
      backgroundColor: AppColors.surfaceDim,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed header ─────────────────────────────────────────────
            _TopBar(
              entry:     widget.entry,
              s:         s,
              isAmharic: isAmharic,
              onSearch:  () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchTab(initialBook: widget.entry),
                ),
              ),
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else ...[
              _BookInfoCard(
                entry:         widget.entry,
                totalChapters: total,
                progress:      _progress,
                s:             s,
                useGeez:       useGeez,
                isAmharic:     isAmharic,
              ),
              const SizedBox(height: 10),
              _ContinueCard(
                s:              s,
                useGeez:        useGeez,
                lastChapterIdx: _lastChapterIdx,
                lastVerseNum:   _lastVerseNum,
                onContinue:     () => _openChapter(_lastChapterIdx),
              ),
              const SizedBox(height: 14),
              _LegendRow(s: s),
              const SizedBox(height: 10),
              // ── Scrollable chapter grid ──────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:  5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _book!.chapters.length,
                  itemBuilder: (ctx, i) {
                    final chNum = _book!.chapters[i].chapterNumber;
                    return _ChapterCell(
                      chapterNum:   chNum,
                      isCurrent:    i == _lastChapterIdx,
                      isRead:       i < _lastChapterIdx,
                      isBookmarked: false,
                      useGeez:      useGeez,
                      onTap:        () => _openChapter(i),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.entry, required this.s, required this.isAmharic, this.onSearch});
  final BookIndexEntry entry;
  final AppStrings s;
  final bool isAmharic;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final breadcrumb =
        '${s.booksTitle} · ${entry.isOldTestament ? s.booksOldTestament : s.booksNewTestament}';
    final title = isAmharic ? entry.bookNameAm : entry.bookNameEn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.textMuted,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breadcrumb,
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  title,
                  style: AppTypography.amharicHeading.copyWith(
                    color: AppColors.textOnParchment,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
}

// ── Book info card ────────────────────────────────────────────────────────────

class _BookInfoCard extends StatelessWidget {
  const _BookInfoCard({
    required this.entry,
    required this.totalChapters,
    required this.progress,
    required this.s,
    required this.useGeez,
    required this.isAmharic,
  });
  final BookIndexEntry entry;
  final int totalChapters;
  final double progress;
  final AppStrings s;
  final bool useGeez;
  final bool isAmharic;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        entry.isOldTestament ? AppColors.primary : AppColors.newTestament;
    final shortName = isAmharic ? entry.bookShortNameAm : entry.bookShortNameEn;
    final altName   = isAmharic ? entry.bookNameEn : entry.bookNameAm;
    final testTag   = entry.isOldTestament ? 'OT' : 'NT';
    final chapStr   = useGeez ? toGeez(totalChapters) : '$totalChapters';
    final pctVal    = (progress * 100).round();
    final pctStr    = useGeez ? toGeez(pctVal) : '$pctVal';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [baseColor, Color.lerp(baseColor, Colors.black, 0.25)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left badge
            Container(
              width: 66,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shortName,
                    style: const TextStyle(
                      fontFamily: AppTypography.shiromeda,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${entry.bookNameEn.split(' ').take(2).join(' ')} · $testTag',
                    style: const TextStyle(
                      fontFamily: AppTypography.nokiaPureheadline,
                      fontSize: 7,
                      color: Colors.white60,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Right info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${entry.bookNameEn.toUpperCase()} · $testTag',
                      style: const TextStyle(
                        fontFamily: AppTypography.nokiaPureheadline,
                        fontSize: 8,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Alternate-language name
                  Text(
                    altName,
                    style: AppTypography.amharicLabel.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Chapter count + progress %
                  Text(
                    '$chapStr ${s.chapterAbbr} · $pctStr% ${s.chapSelectorProgressSuffix}',
                    style: AppTypography.amharicCaption.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Continue reading card ─────────────────────────────────────────────────────

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.s,
    required this.useGeez,
    required this.lastChapterIdx,
    required this.lastVerseNum,
    required this.onContinue,
  });
  final AppStrings s;
  final bool useGeez;
  final int lastChapterIdx;
  final int lastVerseNum;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final chStr = useGeez ? toGeez(lastChapterIdx + 1) : '${lastChapterIdx + 1}';
    final vStr  = useGeez ? toGeez(lastVerseNum)       : '$lastVerseNum';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Book icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.menu_book_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            // Position label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.chapSelectorLastRead,
                    style: AppTypography.amharicCaption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.chapterAbbr} $chStr  ·  ${s.chapSelectorVerseLabel} $vStr',
                    style: AppTypography.amharicLabel.copyWith(
                      color: AppColors.textOnParchment,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Continue button
            GestureDetector(
              onTap: onContinue,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.chapSelectorContinueBtn,
                      style: AppTypography.amharicLabel.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legend row ────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _LegendDot(color: AppColors.primary, label: s.legendCurrent),
          const SizedBox(width: 14),
          _LegendDot(color: AppColors.borderSubtle, label: s.legendUnread, border: true),
          const SizedBox(width: 14),
          _LegendIcon(
            icon: Icons.bookmark_rounded,
            color: AppColors.accentDark,
            label: s.legendBookmark,
          ),
          const Spacer(),
          Text(
            s.chapSelectorChapNosLabel,
            style: AppTypography.englishLabel.copyWith(
              color: AppColors.textCaption,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.border = false});
  final Color color;
  final String label;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: border ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: border ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _LegendIcon extends StatelessWidget {
  const _LegendIcon({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Chapter cell ──────────────────────────────────────────────────────────────

class _ChapterCell extends StatelessWidget {
  const _ChapterCell({
    required this.chapterNum,
    required this.isCurrent,
    required this.isRead,
    required this.isBookmarked,
    required this.useGeez,
    required this.onTap,
  });
  final int chapterNum;
  final bool isCurrent;
  final bool isRead;
  final bool isBookmarked;
  final bool useGeez;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color numColor;
    final Color borderColor;

    if (isCurrent) {
      bgColor     = AppColors.primary;
      numColor    = Colors.white;
      borderColor = AppColors.primary;
    } else if (isRead) {
      bgColor     = AppColors.parchment;
      numColor    = AppColors.textOnParchment;
      borderColor = AppColors.parchmentDark;
    } else {
      bgColor     = Colors.white;
      numColor    = AppColors.textOnParchment;
      borderColor = AppColors.borderSubtle;
    }

    final geezLabel   = toGeez(chapterNum);
    final arabicLabel = '$chapterNum';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    geezLabel,
                    style: TextStyle(
                      fontFamily: AppTypography.shiromeda,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: numColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    arabicLabel,
                    style: TextStyle(
                      fontFamily: AppTypography.nokiaPureheadline,
                      fontSize: 9,
                      color: numColor.withValues(alpha: 0.55),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            if (isBookmarked)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 10,
                  color: isCurrent ? AppColors.accent : AppColors.accentDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
