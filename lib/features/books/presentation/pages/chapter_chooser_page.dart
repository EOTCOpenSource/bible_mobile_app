import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/book.dart';
import '../../data/models/book_index_entry.dart';
import '../../data/reading_models.dart';
import '../../data/repositories/bible_repository.dart' show BibleRepository;
import '../../providers/reading_progress_providers.dart';
import '../widgets/edition_switcher.dart';
import '../widgets/reader/constants.dart';
import 'book_reader_page.dart';
import '../../../search/presentation/pages/search_tab.dart';

class ChapterChooserPage extends ConsumerStatefulWidget {
  const ChapterChooserPage({super.key, required this.entry});
  final BookIndexEntry entry;

  @override
  ConsumerState<ChapterChooserPage> createState() =>
      _ChapterChooserPageState();
}

class _ChapterChooserPageState extends ConsumerState<ChapterChooserPage> {
  Book? _book;
  bool _loading = true;
  bool _initialized = false;

  int _lastChapterIdx = 0;
  int _lastChapterNum = 1;
  int _lastVerseNum = 1;
  int _nextChapterIdx = -1;
  Set<int> _readChapters = {};
  double _bookProgress = 0;

  BibleRepository? _repo;

  /// The book as the active edition names it — re-resolved on every switch.
  late BookIndexEntry _entry;

  /// Set when an edition switch left this book outside the active canon and
  /// the reader was on top, so the exit is deferred until we are visible again.
  bool _leaveWhenVisible = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Chapter counts and text are edition-specific, and the edition can now
      // be switched from this very screen, so follow the repository.
      _repo = BibleRepositoryProvider.of(context);
      _repo!.addListener(_onEditionChanged);
      _loadBook();
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_onEditionChanged);
    super.dispose();
  }

  /// Reloads the book against the newly active edition, or leaves the screen
  /// when that edition's canon does not carry it — the protestant editions
  /// have no deuterocanon, so this is an ordinary outcome, not an error.
  Future<void> _onEditionChanged() async {
    final repo = _repo;
    if (repo == null || !mounted) return;

    final entry = await repo.bookById(_entry.id);
    if (!mounted) return;

    if (entry == null) {
      final s = L10n.of(context);
      final edition = await repo.activeEdition();
      if (!mounted) return;
      final title = edition == null ? '' : editionTitleFor(edition, s);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(s.editionBookMissing(title))),
        );
      _leaveWhenVisible = true;
      _exitIfVisible();
      return;
    }

    setState(() {
      _entry = entry;
      _loading = true;
    });
    await _loadBook();
  }

  /// Pops back to the book list once this route is the visible one.
  void _exitIfVisible() {
    if (!_leaveWhenVisible || !mounted) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _leaveWhenVisible = false;
    Navigator.pop(context);
  }

  Future<void> _loadBook() async {
    // Resolve repo via [ProviderContainer] before any await. If the user pops
    // this route while awaits are in flight, this [Consumer]'s [ref] is invalid
    // even when [mounted] is still true — same class of bug as Reader dwell.
    final ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context);
    } on Object catch (_) {
      return;
    }
    final repo = container.read(readingProgressRepositoryProvider);

    final book =
        await BibleRepositoryProvider.of(context).loadBook(_entry);
    if (!mounted) return;

    final pos = await repo.getReadingPosition();
    if (!mounted) return;

    final readSet =
        await repo.readChapterNumbersForBook(_entry.id);
    if (!mounted) return;

    final p = _deriveProgress(book, pos, readSet);
    setState(() {
      _book = book;
      _loading = false;
      _lastChapterIdx = p.lastChapterIdx;
      _lastChapterNum = p.lastChapterNum;
      _lastVerseNum = p.lastVerseNum;
      _nextChapterIdx = p.nextChapterIdx;
      _readChapters = p.readChapters;
      _bookProgress = p.bookProgress;
    });
  }

  /// Re-query DB for resume position + chapter read set (e.g. after returning
  /// from [ReaderScreen]) so the grid updates without leaving this screen.
  Future<void> _refreshChapterReadingUi() async {
    final book = _book;
    if (book == null) return;

    final ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context);
    } on Object catch (_) {
      return;
    }
    final repo = container.read(readingProgressRepositoryProvider);

    final pos = await repo.getReadingPosition();
    if (!mounted) return;

    final readSet =
        await repo.readChapterNumbersForBook(_entry.id);
    if (!mounted) return;

    final p = _deriveProgress(book, pos, readSet);
    setState(() {
      _lastChapterIdx = p.lastChapterIdx;
      _lastChapterNum = p.lastChapterNum;
      _lastVerseNum = p.lastVerseNum;
      _nextChapterIdx = p.nextChapterIdx;
      _readChapters = p.readChapters;
      _bookProgress = p.bookProgress;
    });
  }

  /// First chapter index (in [book.chapters] order) not in [readChapters], or
  /// `-1` when every chapter is already marked read (no "next" highlight).
  int _indexOfNextUnreadChapter(Book book, Set<int> readChapters) {
    for (var i = 0; i < book.chapters.length; i++) {
      if (!readChapters.contains(book.chapters[i].chapterNumber)) return i;
    }
    return -1;
  }

  ({
    int lastChapterIdx,
    int lastChapterNum,
    int lastVerseNum,
    int nextChapterIdx,
    Set<int> readChapters,
    double bookProgress,
  }) _deriveProgress(Book book, ReadingPosition? pos, Set<int> readChapters) {
    var lastIdx = 0;
    var lastVerse = 1;
    if (pos != null && pos.bookId == _entry.id) {
      final i =
          book.chapters.indexWhere((c) => c.chapterNumber == pos.chapter);
      if (i >= 0) lastIdx = i;
      lastVerse = pos.verse ?? 1;
    }

    final lastNum = (lastIdx < book.chapters.length)
        ? book.chapters[lastIdx].chapterNumber
        : lastIdx + 1;
    final total = book.chapters.length;
    final readCount = readChapters.length;
    final progress = total <= 0 ? 0.0 : (readCount / total).clamp(0.0, 1.0);
    final nextIdx = _indexOfNextUnreadChapter(book, readChapters);

    return (
      lastChapterIdx: lastIdx,
      lastChapterNum: lastNum,
      lastVerseNum: lastVerse,
      nextChapterIdx: nextIdx,
      readChapters: readChapters,
      bookProgress: progress,
    );
  }

  void _openChapter(int idx) {
    final book = _book;
    if (book == null || idx < 0 || idx >= book.chapters.length) return;
    final chNum = book.chapters[idx].chapterNumber;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          entry: _entry,
          initialChapter: idx,
          initialChapterNumber: chNum,
        ),
      ),
    ).then((_) async {
      if (!mounted) return;
      // The reader can switch editions too; if that dropped this book from the
      // canon, leave now that this route is back on top.
      if (_leaveWhenVisible) {
        _exitIfVisible();
        return;
      }
      await _refreshChapterReadingUi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;
    final isAmharic = s is AmStrings;
    final total = _book?.chapters.length ?? (_entry.chapterCount ?? 0);

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surfaceDim,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              entry: _entry,
              s: s,
              isAmharic: isAmharic,
              onSearch: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchTab(initialBook: _entry),
                ),
              ),
            ),
            if (_loading)
              Expanded(
                child: Center(child: CircularProgressIndicator(color: c.primary)),
              )
            else ...[
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _BookInfoCard(
                      entry: _entry,
                      totalChapters: total,
                      progress: _bookProgress,
                      s: s,
                      useGeez: useGeez,
                      isAmharic: isAmharic,
                    ),
                    const SizedBox(height: 6),
                    BookIntroductionCard(
                      entry: _entry,
                      s: s,
                      isAmharic: isAmharic,
                      onSelectChapter: _openChapter,
                    ),
                    const SizedBox(height: 10),
                    _ContinueCard(
                      s: s,
                      useGeez: useGeez,
                      lastChapterNum: _lastChapterNum,
                      lastVerseNum: _lastVerseNum,
                      onContinue: () => _openChapter(_lastChapterIdx),
                    ),
                    const SizedBox(height: 14),
                    _LegendRow(s: s),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: _book!.chapters.length,
                      itemBuilder: (ctx, i) {
                        final chNum = _book!.chapters[i].chapterNumber;
                        return _ChapterCell(
                          chapterNum: chNum,
                          isNext: _nextChapterIdx >= 0 && i == _nextChapterIdx,
                          isRead: _readChapters.contains(chNum),
                          isBookmarked: false,
                          useGeez: useGeez,
                          onTap: () => _openChapter(i),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Book introduction card ───────────────────────────────────────────────────

class BookIntroductionCard extends StatefulWidget {
  const BookIntroductionCard({
    super.key,
    required this.entry,
    required this.s,
    required this.isAmharic,
    required this.onSelectChapter,
  });

  final BookIndexEntry entry;
  final AppStrings s;
  final bool isAmharic;
  final ValueChanged<int> onSelectChapter;

  @override
  State<BookIntroductionCard> createState() => _BookIntroductionCardState();
}

class _BookIntroductionCardState extends State<BookIntroductionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final repo = BibleRepositoryProvider.of(context);
    final locale = widget.isAmharic ? 'am' : 'en';
    final intro = repo.getIntroduction(widget.entry.bookNumber, locale: locale);

    if (intro == null) return const SizedBox.shrink();

    final c = context.colors;
    final settings = Settings.of(context);
    final fontIndex = settings.bodyFontIndex.clamp(0, readerFonts.length - 1);
    final fontFamily = readerFonts[fontIndex];
    final summaryFontSize = (settings.fontSize * 0.82).clamp(12.0, 24.0);

    final metaList = <String>[];
    if (intro.author.isNotEmpty) metaList.add('${widget.s.author}: ${intro.author}');
    if (intro.period.isNotEmpty) metaList.add('${widget.s.period}: ${intro.period}');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Text(
                widget.s.aboutThisBook,
                style: AppTypography.amharicLabel.copyWith(
                  fontWeight: FontWeight.bold,
                  color: c.textOnParchment,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? widget.s.showLess : widget.s.readMore,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (metaList.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              metaList.join('  •  '),
              style: AppTypography.amharicCaption.copyWith(
                color: c.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            intro.summary,
            style: AppTypography.amharicBody.copyWith(
              fontFamily: fontFamily,
              color: c.textOnParchment,
              fontSize: summaryFontSize,
              height: 1.45,
            ),
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (_expanded) ...[
            if (intro.themes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                widget.s.themes,
                style: AppTypography.amharicCaption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: c.textOnParchment,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: intro.themes.map((theme) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      theme,
                      style: AppTypography.amharicCaption.copyWith(
                        color: c.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (intro.outline.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                widget.s.outline,
                style: AppTypography.amharicCaption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: c.textOnParchment,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              ...intro.outline.map((item) {
                final chLabel = item.fromChapter == item.toChapter
                    ? '${widget.s.chapterAbbr} ${item.fromChapter}'
                    : '${widget.s.chapterAbbr} ${item.fromChapter}–${item.toChapter}';
                return InkWell(
                  onTap: () => widget.onSelectChapter(item.fromChapter - 1),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            chLabel,
                            style: AppTypography.amharicCaption.copyWith(
                              fontSize: 11,
                              color: c.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.amharicCaption.copyWith(
                              color: c.textOnParchment,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.entry,
    required this.s,
    required this.isAmharic,
    this.onSearch,
  });
  final BookIndexEntry entry;
  final AppStrings s;
  final bool isAmharic;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
            color: c.textMuted,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breadcrumb,
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  title,
                  style: AppTypography.amharicHeading.copyWith(
                    color: c.textOnParchment,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const EditionChip(),
          IconButton(
            icon: Icon(Icons.search_rounded, size: 20, color: c.textMuted),
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
}

// ── Book info card ───────────────────────────────────────────────────────────

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
    final c = context.colors;
    final baseColor = entry.isOldTestament ? c.primary : c.newTestament;
    final shortName = isAmharic ? entry.bookShortNameAm : entry.bookShortNameEn;
    final altName = isAmharic ? entry.bookNameEn : entry.bookNameAm;
    final testTag = entry.isOldTestament ? 'OT' : 'NT';
    final chapStr = useGeez ? toGeez(totalChapters) : '$totalChapters';
    final pctVal = (progress * 100).round();
    final pctStr = useGeez ? toGeez(pctVal) : '$pctVal';

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
                    style: TextStyle(
                      fontFamily: AppTypography.shiromeda,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    '$chapStr ${s.chapterAbbr} · $pctStr% ${s.chapSelectorProgressSuffix}',
                    style: AppTypography.amharicCaption.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(c.accent),
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
    required this.lastChapterNum,
    required this.lastVerseNum,
    required this.onContinue,
  });
  final AppStrings s;
  final bool useGeez;
  final int lastChapterNum;
  final int lastVerseNum;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chStr = useGeez ? toGeez(lastChapterNum) : '$lastChapterNum';
    final vStr = useGeez ? toGeez(lastVerseNum) : '$lastVerseNum';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.borderSubtle),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.menu_book_rounded, color: c.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.chapSelectorLastRead,
                    style: AppTypography.amharicCaption.copyWith(
                      color: c.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.chapterAbbr} $chStr  ·  ${s.chapSelectorVerseLabel} $vStr',
                    style: AppTypography.amharicLabel.copyWith(
                      color: c.textOnParchment,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onContinue,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: c.primary,
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

// ── Legend row ───────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _LegendDot(color: c.primary, label: s.legendNextChapter),
            const SizedBox(width: 10),
            _LegendIcon(
              icon: Icons.menu_book_rounded,
              color: c.primary,
              label: s.chapSelectorProgressSuffix,
            ),
            const SizedBox(width: 10),
            _LegendIcon(
              icon: Icons.book_rounded,
              color: c.textMuted,
              label: s.legendUnread,
            ),
            const SizedBox(width: 10),
            _LegendIcon(
              icon: Icons.bookmark_rounded,
              color: c.accentDark,
              label: s.legendBookmark,
            ),
            const SizedBox(width: 14),
            Text(
              s.chapSelectorChapNosLabel,
              style: AppTypography.englishLabel.copyWith(
                color: c.textCaption,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: context.colors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _LegendIcon extends StatelessWidget {
  const _LegendIcon({
    required this.icon,
    required this.color,
    required this.label,
  });
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
            color: context.colors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Chapter cell ─────────────────────────────────────────────────────────────

class _ChapterCell extends StatelessWidget {
  const _ChapterCell({
    required this.chapterNum,
    required this.isNext,
    required this.isRead,
    required this.isBookmarked,
    required this.useGeez,
    required this.onTap,
  });
  final int chapterNum;
  final bool isNext;
  final bool isRead;
  final bool isBookmarked;
  final bool useGeez;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color bgColor;
    final Color numColor;
    final Color borderColor;

    if (isNext) {
      bgColor = c.primary;
      numColor = Colors.white;
      borderColor = c.primary;
    } else if (isRead) {
      bgColor = c.parchment;
      numColor = c.textOnParchment;
      borderColor = c.parchmentDark;
    } else {
      bgColor = c.surface;
      numColor = c.textOnParchment;
      borderColor = c.borderSubtle;
    }

    final bookIconColor = isNext
        ? Colors.white.withValues(alpha: 0.88)
        : isRead
            ? c.primary.withValues(alpha: 0.85)
            : c.textMuted.withValues(alpha: 0.75);

    final chapterLabel = useGeez ? toGeez(chapterNum) : '$chapterNum';
    final TextStyle numberStyle = useGeez
        ? TextStyle(
            fontFamily: AppTypography.shiromeda,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: numColor,
            height: 1.05,
          )
        : TextStyle(
            fontFamily: AppTypography.nokiaPureheadline,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: numColor,
            height: 1.0,
            letterSpacing: 0.2,
          );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 16, 14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    chapterLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: numberStyle,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Icon(
                isRead ? Icons.menu_book_rounded : Icons.book_rounded,
                size: 12,
                color: bookIconColor,
              ),
            ),
            if (isBookmarked)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 10,
                  color: isNext ? c.accent : c.accentDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
