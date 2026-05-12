import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/annotations/annotation_models.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/models/book_index_entry.dart';
import '../widgets/reader/constants.dart';
import '../widgets/reader/toolbar.dart';
import '../widgets/reader/breadcrumb.dart';
import '../widgets/reader/chapter_page.dart';
import '../widgets/reader/font_sheet.dart';
import '../widgets/reader/highlight_sheet.dart';
import '../widgets/reader/note_sheet.dart';
import '../widgets/reader/verse_action_bar.dart';
import '../widgets/reader/chapter_nav_bar.dart';
import '../../../annotations/providers/annotation_providers.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.entry,
    this.initialChapter = 0,
    this.initialVerse,
  });

  final BookIndexEntry entry;
  final int initialChapter;
  final int? initialVerse;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  Book? _book;
  bool _loading = true;
  late final PageController _pageCtrl;
  int _currentChapter = 0;

  String? _selectedKey;
  final GlobalKey _spotlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.initialChapter;
    _pageCtrl = PageController(initialPage: widget.initialChapter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_book == null && _loading) _loadBook();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    final book =
        await BibleRepositoryProvider.of(context).loadBook(widget.entry);
    if (!mounted) return;
    setState(() {
      _book = book;
      _loading = false;
    });
    _autoSelectInitialVerse();
  }

  void _autoSelectInitialVerse() {
    final targetVerse = widget.initialVerse;
    if (targetVerse == null || _book == null) return;
    final chIdx = widget.initialChapter.clamp(0, _book!.chapters.length - 1);
    final chapter = _book!.chapters[chIdx];
    for (var sIdx = 0; sIdx < chapter.sections.length; sIdx++) {
      if (chapter.sections[sIdx].verses.any((v) => v.verseNumber == targetVerse)) {
        setState(() {
          _selectedKey = _verseKey(chapter.chapterNumber, sIdx, targetVerse);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _spotlightKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.3,
            );
          }
        });
        break;
      }
    }
  }

  void _goToChapter(int idx) {
    if (_book == null) return;
    _pageCtrl.animateToPage(
      idx.clamp(0, _book!.chapters.length - 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _selectVerse(String key) =>
      setState(() => _selectedKey = _selectedKey == key ? null : key);

  void _deselect() => setState(() => _selectedKey = null);

  String _verseKey(int chNum, int secIdx, int verseNum) =>
      '$chNum:$secIdx:$verseNum';

  bool _isSelected(int chNum, int secIdx, int verseNum) =>
      _selectedKey == _verseKey(chNum, secIdx, verseNum);

  int? get _selectedVerseNum {
    if (_selectedKey == null) return null;
    final parts = _selectedKey!.split(':');
    return parts.length == 3 ? int.tryParse(parts[2]) : null;
  }

  int get _currentChapterNumber =>
      _book?.chapters[_currentChapter].chapterNumber ?? 1;

  ChapterKey get _chapterKey =>
      (bookId: widget.entry.bookNameEn, chapter: _currentChapterNumber);

  String? _selectedVerseText(AppSettings settings) {
    if (_book == null || _selectedKey == null) return null;
    final parts = _selectedKey!.split(':');
    if (parts.length != 3) return null;
    final chNum = int.tryParse(parts[0]);
    final secIdx = int.tryParse(parts[1]);
    final vNum = int.tryParse(parts[2]);
    if (chNum == null || secIdx == null || vNum == null) return null;
    try {
      final chapter =
          _book!.chapters.firstWhere((c) => c.chapterNumber == chNum);
      final section = chapter.sections[secIdx];
      final verse = section.verses.firstWhere((v) => v.verseNumber == vNum);
      return '${widget.entry.bookNameAm} $chNum:${verse.verseNumber}\n${verse.text}';
    } catch (_) {
      return null;
    }
  }

  // ── Font settings sheet ───────────────────────────────────────────────────

  void _showFontSheet(BuildContext ctx, AppSettings settings) {
    final isDark = settings.isDarkReader;
    final surfaceColor = isDark ? readerDarkSurface : Colors.white;
    final textColor = isDark ? readerDarkText : AppColors.textOnParchment;
    final mutedColor = isDark ? readerDarkMuted : AppColors.textMuted;
    final accentColor = isDark ? readerDarkAccent : AppColors.accentDeep;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReaderFontSheet(
        settings: settings,
        textColor: textColor,
        mutedColor: mutedColor,
        accentColor: accentColor,
        onSizeChange: (v) =>
            Settings.update(ctx, settings.copyWith(fontSize: v)),
        onFontChange: (i) =>
            Settings.update(ctx, settings.copyWith(bodyFontIndex: i)),
      ),
    );
  }

  // ── Highlight sheet ───────────────────────────────────────────────────────

  void _showHighlightSheet(
    BuildContext ctx,
    AppSettings settings,
    ChapterAnnotations annotations,
  ) {
    final verseNum = _selectedVerseNum;
    if (verseNum == null) return;

    final isDark = settings.isDarkReader;
    final surfaceColor = isDark ? readerDarkSurface : Colors.white;
    final textColor = isDark ? readerDarkText : AppColors.textOnParchment;
    final currentColor = annotations.highlightColor(verseNum);

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => HighlightSheet(
        currentColor: currentColor,
        surfaceColor: surfaceColor,
        textColor: textColor,
        onColorSelected: (color) {
          Navigator.pop(ctx);
          ref.read(chapterAnnotationsProvider(_chapterKey).notifier).setHighlight(
                verseStart: verseNum,
                bookNumber: widget.entry.bookNumber,
                color: color,
              );
          _deselect();
        },
        onRemove: () {
          Navigator.pop(ctx);
          ref
              .read(chapterAnnotationsProvider(_chapterKey).notifier)
              .removeHighlight(verseNum);
          _deselect();
        },
      ),
    );
  }

  // ── Note sheet ────────────────────────────────────────────────────────────

  void _showNoteSheet(
    BuildContext ctx,
    AppSettings settings,
    ChapterAnnotations annotations,
  ) {
    final verseNum = _selectedVerseNum;
    if (verseNum == null) return;

    final isDark = settings.isDarkReader;
    final surfaceColor = isDark ? readerDarkSurface : Colors.white;
    final textColor = isDark ? readerDarkText : AppColors.textOnParchment;
    final mutedColor = isDark ? readerDarkMuted : AppColors.textMuted;
    final existingNote = annotations.noteFor(verseNum);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteSheet(
        initialContent: existingNote?.content ?? '',
        surfaceColor: surfaceColor,
        textColor: textColor,
        mutedColor: mutedColor,
        onSave: (content) {
          ref.read(chapterAnnotationsProvider(_chapterKey).notifier).saveNote(
                verseStart: verseNum,
                bookNumber: widget.entry.bookNumber,
                content: content,
              );
          _deselect();
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final settings = Settings.of(context);
    final useGeez = settings.useGeezNumbers;
    final isAm = s is AmStrings;
    final isDark = settings.isDarkReader;

    final bgColor = isDark ? readerDarkBg : AppColors.parchment;
    final surfaceColor = isDark ? readerDarkSurface : Colors.white;
    final textColor = isDark ? readerDarkText : AppColors.textOnParchment;
    final mutedColor = isDark ? readerDarkMuted : AppColors.textMuted;
    final accentColor = isDark ? readerDarkAccent : AppColors.accentDeep;

    final bodyFont = readerFonts[settings.bodyFontIndex];
    final titleFont = readerFonts[settings.titleFontIndex];

    final chapterReady = !_loading &&
        _book != null &&
        _currentChapter < _book!.chapters.length;

    // Watch annotations for the current chapter
    final annotationsAsync =
        ref.watch(chapterAnnotationsProvider(_chapterKey));
    final annotations = annotationsAsync.value ?? ChapterAnnotations.empty;

    // Derive action bar state for the selected verse
    final verseNum = _selectedVerseNum;
    final isBookmarked = verseNum != null && annotations.isBookmarked(verseNum);
    final highlightColor =
        verseNum != null ? annotations.highlightColor(verseNum) : null;
    final hasNote =
        verseNum != null && annotations.noteFor(verseNum) != null;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Toolbar ──────────────────────────────────────────────────────
            ReaderToolbar(
              entry: widget.entry,
              currentChapter: _currentChapter,
              useGeez: useGeez,
              isAmharic: isAm,
              bgColor: bgColor,
              textColor: textColor,
              mutedColor: mutedColor,
              s: s,
              onBack: () => Navigator.pop(context),
              onFontSettings: () => _showFontSheet(context, settings),
            ),
            // ── Breadcrumb ───────────────────────────────────────────────────
            if (chapterReady)
              ReaderBreadcrumb(
                entry: widget.entry,
                chapter: _book!.chapters[_currentChapter],
                useGeez: useGeez,
                isAmharic: isAm,
                s: s,
                bgColor: bgColor,
                accentColor: accentColor,
                mutedColor: mutedColor,
              ),
            // ── Pages ────────────────────────────────────────────────────────
            Expanded(
              child: _loading || _book == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark ? context.colors.accent : context.colors.primary,
                      ),
                    )
                  : GestureDetector(
                      onTap: _deselect,
                      behavior: HitTestBehavior.translucent,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageCtrl,
                            itemCount: _book!.chapters.length,
                            onPageChanged: (i) =>
                                setState(() => _currentChapter = i),
                            itemBuilder: (ctx, i) {
                              // Each page watches its own chapter's annotations
                              final pageChapterNum =
                                  _book!.chapters[i].chapterNumber;
                              final pageKey = (
                                bookId: widget.entry.bookNameEn,
                                chapter: pageChapterNum
                              );
                              final pageAnnotations = ref
                                      .watch(chapterAnnotationsProvider(pageKey))
                                      .value ??
                                  ChapterAnnotations.empty;

                              return ReaderChapterPage(
                                entry: widget.entry,
                                chapter: _book!.chapters[i],
                                isDark: isDark,
                                fontSize: settings.fontSize,
                                fontFamily: bodyFont,
                                titleFontFamily: titleFont,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                accentColor: accentColor,
                                useGeez: useGeez,
                                isAmharic: isAm,
                                isSelectedFn: _isSelected,
                                onVerseTap: _selectVerse,
                                verseKeyFn: _verseKey,
                                annotations: pageAnnotations,
                                spotlightVerseNum: (widget.initialVerse !=
                                            null &&
                                        i == widget.initialChapter)
                                    ? widget.initialVerse
                                    : null,
                                spotlightKey: (widget.initialVerse != null &&
                                        i == widget.initialChapter)
                                    ? _spotlightKey
                                    : null,
                              );
                            },
                          ),
                          // Verse action bar
                          AnimatedSlide(
                            offset: _selectedKey != null
                                ? Offset.zero
                                : const Offset(0, 1),
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: VerseActionBar(
                                s: s,
                                isDark: isDark,
                                surfaceColor: surfaceColor,
                                textColor: textColor,
                                isBookmarked: isBookmarked,
                                highlightColor: highlightColor,
                                hasNote: hasNote,
                                onBookmark: () {
                                  if (verseNum == null) return;
                                  ref
                                      .read(chapterAnnotationsProvider(
                                              _chapterKey)
                                          .notifier)
                                      .toggleBookmark(
                                        verseStart: verseNum,
                                        bookNumber: widget.entry.bookNumber,
                                      );
                                  _deselect();
                                },
                                onHighlight: () =>
                                    _showHighlightSheet(context, settings, annotations),
                                onNote: () =>
                                    _showNoteSheet(context, settings, annotations),
                                onCopy: () async {
                                  final text = _selectedVerseText(settings);
                                  if (text != null) {
                                    await Clipboard.setData(
                                        ClipboardData(text: text));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(s.verseCopy)));
                                    }
                                  }
                                  _deselect();
                                },
                                onShare: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(s.comingSoon)));
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // ── Chapter nav ──────────────────────────────────────────────────
            if (!_loading && _book != null)
              ChapterNavBar(
                currentChapter: _currentChapter,
                totalChapters: _book!.chapters.length,
                isDark: isDark,
                useGeez: useGeez,
                s: s,
                bgColor: bgColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                mutedColor: mutedColor,
                onPrev: () => _goToChapter(_currentChapter - 1),
                onNext: () => _goToChapter(_currentChapter + 1),
              ),
          ],
        ),
      ),
    );
  }
}
