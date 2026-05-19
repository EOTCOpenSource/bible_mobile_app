import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/annotations/annotation_models.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/models/book_index_entry.dart';
import '../../data/reading_constants.dart';
import '../../providers/reading_progress_providers.dart';
import '../../providers/reader_immersive_provider.dart';
import '../../../../core/deep_links/deep_link_uri.dart';
import '../widgets/reader/constants.dart';
import '../widgets/reader/toolbar.dart';
import '../widgets/reader/breadcrumb.dart';
import '../widgets/reader/chapter_page.dart';
import '../widgets/reader/font_sheet.dart';
import '../widgets/reader/highlight_sheet.dart';
import '../widgets/reader/note_sheet.dart';
import '../widgets/reader/note_view_sheet.dart';
import '../widgets/reader/verse_action_bar.dart';
import '../widgets/reader/chapter_nav_bar.dart';
import '../../../annotations/providers/annotation_providers.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.entry,
    this.initialChapter = 0,
    this.initialChapterNumber,
    this.initialVerse,
     this.openNoteSheet = false,
  });

  final BookIndexEntry entry;

  /// Page index in [Book.chapters] (0-based).
  final int initialChapter;

  /// If set, overrides [initialChapter] after the book loads (canonical chapter number).
  final int? initialChapterNumber;
  final int? initialVerse;
   final bool openNoteSheet;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  Book? _book;
  bool _loading = true;
  late final PageController _pageCtrl;
  int _currentChapter = 0;

  String? _selectedKey;
  final GlobalKey _spotlightKey = GlobalKey();

  Timer? _dwellTimer;
  int? _dwellChapterNumber;

  /// Page index used only to spotlight [initialVerse] on first open.
  int? _spotlightChapterPageIndex;

  /// Toolbar, breadcrumb, chapter footer, and home bottom nav follow this.
  bool _readerChromeVisible = true;

  /// Root container for updates that must not use [ref] after dispose (immersive flag).
  ProviderContainer? _riverpodContainer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentChapter = widget.initialChapter;
    _pageCtrl = PageController(initialPage: widget.initialChapter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _riverpodContainer = ProviderScope.containerOf(context);
    // Defer: updating [readerBottomNavMatchReaderProvider] rebuilds [HomeScreen]
    // while this route is mounting; doing it synchronously here can throw.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setReaderBottomNavMatchReader(true);
    });
    if (_book == null && _loading) _loadBook();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _dwellTimer?.cancel();
      _persistReadingPosition();
    } else if (state == AppLifecycleState.resumed) {
      _persistReadingPosition();
      _scheduleDwellTimer();
    }
  }

  void _setReaderImmersiveProvider(bool immersive) {
    final c = _riverpodContainer;
    if (c == null) return;
    try {
      c.read(readerImmersiveModeProvider.notifier).state = immersive;
    } on Object catch (_) {}
  }

  void _setReaderBottomNavMatchReader(bool match) {
    final c = _riverpodContainer;
    if (c == null) return;
    try {
      c.read(readerBottomNavMatchReaderProvider.notifier).state = match;
    } on Object catch (_) {}
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _persistReadingPosition();
    // Reset immersive/color providers while ref is still valid (before super.dispose).
    // _riverpodContainer is only for timer callbacks that may fire after dispose.
    try {
      ref.read(readerImmersiveModeProvider.notifier).state = false;
      ref.read(readerBottomNavMatchReaderProvider.notifier).state = false;
    } catch (_) {}
    _pageCtrl.dispose();
    super.dispose();
  }

  void _setReaderChromeVisible(bool visible) {
    if (!mounted) return;
    if (_readerChromeVisible == visible) return;
    setState(() => _readerChromeVisible = visible);
    _setReaderImmersiveProvider(!visible);
  }

  /// Vertical chapter scroll: hide chrome while reading down; show at top or
  /// on a strong upward fling.
  bool _onChapterScroll(ScrollNotification n) {
    if (_loading || _book == null) return false;
    if (n.metrics.axis != Axis.vertical) return false;

    if (n is ScrollUpdateNotification) {
      final pixels = n.metrics.pixels;
      final delta = n.scrollDelta ?? 0.0;

      if (pixels <= 16) {
        _setReaderChromeVisible(true);
      } else if (delta > 3 && pixels > 28) {
        _setReaderChromeVisible(false);
      } else if (delta < -22) {
        _setReaderChromeVisible(true);
      }
    }
    return false;
  }

  void _persistReadingPosition() {
    if (_book == null) return;
    final ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context);
    } on Object catch (_) {
      return;
    }
    final verse = _selectedVerseNum;
    unawaited(
      container
          .read(readingProgressRepositoryProvider)
          .saveReadingPosition(
            bookId: widget.entry.bookNameEn,
            chapter: _currentChapterNumber,
            verse: verse,
          ),
    );
  }

  void _scheduleDwellTimer() {
    _dwellTimer?.cancel();
    if (_book == null || _loading) return;
    final chNum = _currentChapterNumber;
    _dwellChapterNumber = chNum;
    _dwellTimer = Timer(
      const Duration(seconds: kReadingDwellQualifySeconds),
      () async {
        if (!mounted || _book == null) return;
        if (_currentChapterNumber != _dwellChapterNumber) return;
        // Capture the root container here; do not use [ref] after awaits — the
        // reader may be popped while [recordQualifiedChapterRead] runs, which
        // invalidates this Consumer's [ref] before [invalidate] is called.
        final ProviderContainer container;
        try {
          container = ProviderScope.containerOf(context);
        } on Object catch (_) {
          return;
        }
        final bookId = widget.entry.bookNameEn;
        await container
            .read(readingProgressRepositoryProvider)
            .recordQualifiedChapterRead(bookId: bookId, chapter: chNum);
        container.invalidate(continueReadingSnapshotsProvider);
        container.invalidate(readingStreakStateProvider);
      },
    );
  }

  Future<void> _loadBook() async {
    final book = await BibleRepositoryProvider.of(
      context,
    ).loadBook(widget.entry);
    if (!mounted) return;

    var pageIdx = widget.initialChapter.clamp(0, book.chapters.length - 1);
    if (widget.initialChapterNumber != null) {
      final i = book.chapters.indexWhere(
        (c) => c.chapterNumber == widget.initialChapterNumber,
      );
      if (i >= 0) pageIdx = i;
    }

    setState(() {
      _book = book;
      _currentChapter = pageIdx;
      _loading = false;
      _spotlightChapterPageIndex = widget.initialVerse != null ? pageIdx : null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      if (_pageCtrl.page?.round() != pageIdx) {
        _pageCtrl.jumpToPage(pageIdx);
      }
    });

    _persistReadingPosition();
    _scheduleDwellTimer();
    _autoSelectInitialVerse(pageIdx);
  }

  void _autoSelectInitialVerse(int chapterPageIndex) {
    final targetVerse = widget.initialVerse;
    if (targetVerse == null || _book == null) return;
    final chIdx = chapterPageIndex.clamp(0, _book!.chapters.length - 1);
    final chapter = _book!.chapters[chIdx];
    for (var sIdx = 0; sIdx < chapter.sections.length; sIdx++) {
      if (chapter.sections[sIdx].verses.any(
        (v) => v.verseNumber == targetVerse,
      )) {
        setState(() {
          _selectedKey = _verseKey(chapter.chapterNumber, sIdx, targetVerse);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Wait one extra frame so any page jump has time to render the
          // target chapter before we try to scroll within it.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
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

  void _selectVerse(String key) {
    setState(() => _selectedKey = _selectedKey == key ? null : key);
    _persistReadingPosition();
  }

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

  int get _currentChapterNumber {
    final book = _book;
    if (book == null || _currentChapter >= book.chapters.length) return 1;
    return book.chapters[_currentChapter].chapterNumber;
  }

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
      final chapter = _book!.chapters.firstWhere(
        (c) => c.chapterNumber == chNum,
      );
      final section = chapter.sections[secIdx];
      final verse = section.verses.firstWhere((v) => v.verseNumber == vNum);
      final deepLink = verseDeepLinkUri(widget.entry, chNum, verse.verseNumber);
      return '${verse.text}\n${widget.entry.bookNameAm} $chNum:${verse.verseNumber}\n$deepLink';
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
        textColor: textColor,
        mutedColor: mutedColor,
        accentColor: accentColor,
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
          final c = _riverpodContainer;
          if (c == null) return;
          c
              .read(chapterAnnotationsProvider(_chapterKey).notifier)
              .setHighlight(
                verseStart: verseNum,
                bookNumber: widget.entry.bookNumber,
                color: color,
              );
          if (mounted) _deselect();
        },
        onRemove: () {
          Navigator.pop(ctx);
          final c = _riverpodContainer;
          if (c == null) return;
          c
              .read(chapterAnnotationsProvider(_chapterKey).notifier)
              .removeHighlight(verseNum);
          if (mounted) _deselect();
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
          final c = _riverpodContainer;
          if (c == null) return;
          c
              .read(chapterAnnotationsProvider(_chapterKey).notifier)
              .saveNote(
                verseStart: verseNum,
                bookNumber: widget.entry.bookNumber,
                content: content,
              );
          if (mounted) _deselect();
        },
      ),
    );
  }

  // ── Note view sheet ───────────────────────────────────────────────────────

  void _showNoteView(String verseKey, ChapterAnnotations annotations) {
    if (_book == null) return;
    final parts = verseKey.split(':');
    if (parts.length != 3) return;
    final chNum = int.tryParse(parts[0]);
    final vNum = int.tryParse(parts[2]);
    if (chNum == null || vNum == null) return;

    final note = annotations.noteFor(vNum);
    if (note == null) return;

    String? verseText;
    try {
      final chapter = _book!.chapters.firstWhere(
        (ch) => ch.chapterNumber == chNum,
      );
      outer:
      for (final sec in chapter.sections) {
        for (final v in sec.verses) {
          if (v.verseNumber == vNum) {
            verseText = v.text;
            break outer;
          }
        }
      }
    } catch (_) {}
    if (verseText == null) return;

    final settings = Settings.of(context);
    final isDark = settings.isDarkReader;
    final surfaceColor = isDark ? readerDarkSurface : Colors.white;
    final textColor = isDark ? readerDarkText : AppColors.textOnParchment;
    final mutedColor = isDark ? readerDarkMuted : AppColors.textMuted;
    final accentColor = isDark ? readerDarkAccent : AppColors.accentDeep;
    final bodyFont = readerFonts[settings.bodyFontIndex];

    final chNumDisplay = settings.useGeezNumbers ? toGeez(chNum) : '$chNum';
    final vNumDisplay = settings.useGeezNumbers ? toGeez(vNum) : '$vNum';
    final reference = '${widget.entry.bookNameAm} $chNumDisplay:$vNumDisplay';

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NoteViewSheet(
        reference: reference,
        verseText: verseText!,
        noteContent: note.content,
        bodyFont: bodyFont,
        textColor: textColor,
        mutedColor: mutedColor,
        accentColor: accentColor,
        onEdit: () {
          Navigator.pop(context);
          if (!mounted) return;
          setState(() => _selectedKey = verseKey);
          final chKey = (bookId: widget.entry.bookNameEn, chapter: chNum);
          final liveAnnotations =
              _riverpodContainer
                  ?.read(chapterAnnotationsProvider(chKey))
                  .value ??
              ChapterAnnotations.empty;
          _showNoteSheet(context, Settings.of(context), liveAnnotations);
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

    final chapterReady =
        !_loading && _book != null && _currentChapter < _book!.chapters.length;

    return PopScope(
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) _setReaderChromeVisible(true);
      },
      child: Consumer(
        builder: (context, ref, _) {
          final annotationsAsync = ref.watch(
            chapterAnnotationsProvider(_chapterKey),
          );
          final annotations =
              annotationsAsync.value ?? ChapterAnnotations.empty;

          final verseNum = _selectedVerseNum;
          final isBookmarked =
              verseNum != null && annotations.isBookmarked(verseNum);
          final highlightColor = verseNum != null
              ? annotations.highlightColor(verseNum)
              : null;
          final hasNote =
              verseNum != null && annotations.noteFor(verseNum) != null;

          return Scaffold(
            backgroundColor: bgColor,
            body: SafeArea(
              child: Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _readerChromeVisible
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                onFontSettings: () =>
                                    _showFontSheet(context, settings),
                              ),
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
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  // ── Pages ────────────────────────────────────────────────────────
                  Expanded(
                    child: _loading || _book == null
                        ? Center(
                            child: CircularProgressIndicator(
                              color: isDark
                                  ? context.colors.accent
                                  : context.colors.primary,
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: _onChapterScroll,
                            child: GestureDetector(
                              onTap: _deselect,
                              behavior: HitTestBehavior.translucent,
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    controller: _pageCtrl,
                                    itemCount: _book!.chapters.length,
                                    onPageChanged: (i) {
                                      setState(() => _currentChapter = i);
                                      _setReaderChromeVisible(true);
                                      _persistReadingPosition();
                                      _scheduleDwellTimer();
                                    },
                                    itemBuilder: (ctx, i) {
                                      final pageChapterNum =
                                          _book!.chapters[i].chapterNumber;
                                      final pageKey = (
                                        bookId: widget.entry.bookNameEn,
                                        chapter: pageChapterNum,
                                      );
                                      return Consumer(
                                        builder: (ctx2, pageRef, _) {
                                          final pageAnnotations =
                                              pageRef
                                                  .watch(
                                                    chapterAnnotationsProvider(
                                                      pageKey,
                                                    ),
                                                  )
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
                                            continuousReading:
                                                settings.continuousReading,
                                            onNoteTap: (key, ann) =>
                                                _showNoteView(key, ann),
                                            spotlightVerseNum:
                                                (widget.initialVerse != null &&
                                                    i ==
                                                        _spotlightChapterPageIndex)
                                                ? widget.initialVerse
                                                : null,
                                            spotlightKey:
                                                (widget.initialVerse != null &&
                                                    i ==
                                                        _spotlightChapterPageIndex)
                                                ? _spotlightKey
                                                : null,
                                          );
                                        },
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
                                          final c = _riverpodContainer;
                                          if (c == null) return;
                                          c
                                              .read(
                                                chapterAnnotationsProvider(
                                                  _chapterKey,
                                                ).notifier,
                                              )
                                              .toggleBookmark(
                                                verseStart: verseNum,
                                                bookNumber:
                                                    widget.entry.bookNumber,
                                              );
                                          _deselect();
                                        },
                                        onHighlight: () => _showHighlightSheet(
                                          context,
                                          settings,
                                          annotations,
                                        ),
                                        onNote: () => _showNoteSheet(
                                          context,
                                          settings,
                                          annotations,
                                        ),
                                        onCopy: () async {
                                          final text = _selectedVerseText(
                                            settings,
                                          );
                                          if (text != null) {
                                            await Clipboard.setData(
                                              ClipboardData(text: text),
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(s.verseCopy),
                                                ),
                                              );
                                            }
                                          }
                                          _deselect();
                                        },
                                        onShare: () async {
                                          final text = _selectedVerseText(
                                            settings,
                                          );
                                          if (text != null) {
                                            await SharePlus.instance.share(
                                              ShareParams(text: text),
                                            );
                                          }
                                          _deselect();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  if (!_loading && _book != null)
                    ChapterNavBar(
                      currentChapter: _currentChapter,
                      totalChapters: _book!.chapters.length,
                      useGeez: useGeez,
                      s: s,
                      bgColor: bgColor,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      onPrev: () => _goToChapter(_currentChapter - 1),
                      onNext: () => _goToChapter(_currentChapter + 1),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
