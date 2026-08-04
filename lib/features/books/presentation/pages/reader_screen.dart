import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';

import '../../../../core/annotations/annotation_models.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/sync/sync_repository.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../data/models/book_index_entry.dart';
import '../../data/models/edition.dart';
import '../../data/reading_constants.dart';
import '../../data/repositories/bible_repository.dart' show BibleRepository;
import '../widgets/edition_switcher.dart';
import '../../providers/reading_progress_providers.dart';
import '../../providers/reader_immersive_provider.dart';
import '../../../../core/deep_links/deep_link_uri.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/play_verses.dart';
import '../widgets/reader/constants.dart';
import '../widgets/reader/toolbar.dart';
import '../widgets/reader/breadcrumb.dart';
import '../widgets/reader/chapter_page.dart';
import '../widgets/reader/chapter_picker_sheet.dart';
import '../widgets/reader/reference_jump_sheet.dart';
import '../widgets/reader/parallel_chapter_page.dart';
import '../widgets/reader/font_sheet.dart';
import '../widgets/reader/highlight_sheet.dart';
import '../widgets/reader/note_sheet.dart';
import '../widgets/reader/note_view_sheet.dart';
import '../widgets/reader/verse_action_bar.dart';
import '../widgets/reader/verse_apparatus_sheet.dart';
import '../widgets/reader/chapter_nav_bar.dart';
import '../../../annotations/providers/annotation_providers.dart';
import '../../../search/presentation/pages/search_tab.dart';
import '../../../share/verse_card_sheet.dart';
// ── Screen ────────────────────────────────────────────────────────────────────

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.entry,
    this.initialChapter = 0,
    this.initialChapterNumber,
    this.initialVerse,
    this.autoStartAudio = false,
  });

  final BookIndexEntry entry;

  /// Page index in [Book.chapters] (0-based).
  final int initialChapter;

  /// If set, overrides [initialChapter] after the book loads (canonical chapter number).
  final int? initialChapterNumber;
  final int? initialVerse;
  final bool autoStartAudio;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  Book? _book;
  bool _loading = true;
  late PageController _pageCtrl;
  int _currentChapter = 0;

  /// The open book *in the active edition*. Re-resolved on every edition
  /// switch: the USFM id is stable, everything else about the entry is not.
  late BookIndexEntry _entry;

  BibleRepository? _repo;
  bool _initialized = false;

  /// Parallel column state. [_secondaryBook] is null while parallel reading is
  /// off *and* when the parallel edition's canon has no such book — the two are
  /// told apart by [_parallelOn], because the second case has to say so rather
  /// than quietly drop back to one column.
  Book? _secondaryBook;
  bool _parallelOn = false;
  String _primaryLabel = '';
  String _secondaryLabel = '';

  /// The primary edition as of the last load, so a notification that only
  /// changed the parallel column does not re-read the whole book.
  String? _primaryEditionId;

  String? _selectedKey;
  String? _selectionEndKey;
  final GlobalKey _spotlightKey = GlobalKey();
  final GlobalKey _audioScrollKey = GlobalKey();
  bool _isAudioPlaying = false;

  Timer? _dwellTimer;
  int? _dwellChapterNumber;

  /// Page index used only to spotlight [initialVerse] on first open.
  int? _spotlightChapterPageIndex;
  int _lastHistoryUpdateTime = DateTime.now().millisecondsSinceEpoch;

  /// Toolbar, breadcrumb, chapter footer, and home bottom nav follow this.
  bool _readerChromeVisible = true;

  /// Root container for updates that must not use [ref] after dispose (immersive flag).
  ProviderContainer? _riverpodContainer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entry = widget.entry;
    _currentChapter = widget.initialChapter;
    _pageCtrl = PageController(initialPage: widget.initialChapter);
    AudioService.instance.currentVerseIndexNotifier.addListener(_onAudioVerseIndexChanged);
    AudioService.instance.stateNotifier.addListener(_onAudioStateChanged);
  }

  void _onAudioStateChanged() {
    final state = AudioService.instance.stateNotifier.value;
    final wasPlaying = _isAudioPlaying;
    _isAudioPlaying = (state == AudioState.playing || state == AudioState.buffering);
    if (wasPlaying && !_isAudioPlaying && mounted) {
      setState(() {
        _selectedKey = null;
        _selectionEndKey = null;
      });
    }
  }

  void _onAudioVerseIndexChanged() {
    final verseIdx = AudioService.instance.currentVerseIndexNotifier.value;
    if (verseIdx == null || _book == null || !mounted) return;
    if (_currentChapter >= _book!.chapters.length) return;
    final chapter = _book!.chapters[_currentChapter];
    if (verseIdx < 0 || verseIdx >= chapter.allVerses.length) return;

    final verse = chapter.allVerses[verseIdx];
    for (var sIdx = 0; sIdx < chapter.sections.length; sIdx++) {
      if (chapter.sections[sIdx].verses.any((v) => v.verseNumber == verse.verseNumber)) {
        final targetKey = _verseKey(chapter.chapterNumber, sIdx, verse.verseNumber);
        if (_selectedKey != targetKey) {
          setState(() {
            _isAudioPlaying = true;
            _selectedKey = targetKey;
            _selectionEndKey = null;
          });
          // Auto-scroll to the active verse
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final ctx = _audioScrollKey.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(
                ctx,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                alignment: 0.3,
              );
            }
          });
        }
        break;
      }
    }
  }

  /// Returns the verse number currently being read by audio on page [pageIdx],
  /// or null if audio is not active on that page.
  int? _audioVerseNum(int pageIdx) {
    if (!_isAudioPlaying || _book == null) return null;
    if (pageIdx != _currentChapter) return null;
    final verseIdx = AudioService.instance.currentVerseIndexNotifier.value;
    if (verseIdx == null) return null;
    final chapter = _book!.chapters[_currentChapter];
    if (verseIdx < 0 || verseIdx >= chapter.allVerses.length) return null;
    return chapter.allVerses[verseIdx].verseNumber;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _riverpodContainer = ProviderScope.containerOf(context);
    if (!_initialized) {
      _initialized = true;
      // The toolbar can switch editions mid-chapter; follow the repository so
      // the text under the reader is always the edition they just chose.
      _repo = BibleRepositoryProvider.of(context);
      _repo!.addListener(_onEditionChanged);
    }
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
      _recordHistory();
      _persistReadingPosition();
    } else if (state == AppLifecycleState.resumed) {
      _lastHistoryUpdateTime = DateTime.now().millisecondsSinceEpoch;
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
    AudioService.instance.currentVerseIndexNotifier.removeListener(_onAudioVerseIndexChanged);
    AudioService.instance.stateNotifier.removeListener(_onAudioStateChanged);
    _dwellTimer?.cancel();
    _repo?.removeListener(_onEditionChanged);
    WidgetsBinding.instance.removeObserver(this);
    _recordHistory();
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

  void _recordHistory() {
    if (_book == null) return;
    final container = _riverpodContainer;
    if (container == null) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMs = now - _lastHistoryUpdateTime;
    _lastHistoryUpdateTime = now;
    if (durationMs < 1000) return;

    final verse = _selectionVerseStart;
    unawaited(
      () async {
        try {
          await container.read(appDatabaseProvider).insertReadingHistory(
            bookId: _entry.id,
            chapter: _currentChapterNumber,
            verse: verse,
            durationMs: durationMs,
          );
        } catch (e, st) {
          debugPrint('Failed to insert reading history: $e\n$st');
        }
      }(),
    );
  }

  void _persistReadingPosition() {
    if (_book == null) return;
    final ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context);
    } on Object catch (_) {
      return;
    }
    final verse = _selectionVerseStart;
    unawaited(
      container
          .read(readingProgressRepositoryProvider)
          .saveReadingPosition(
            bookId: _entry.id,
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
        final bookId = _entry.id;
        await container
            .read(readingProgressRepositoryProvider)
            .recordQualifiedChapterRead(bookId: bookId, chapter: chNum);
        final token = container.read(authStateProvider).token;
        if (token != null) {
          SyncService(
            db: container.read(appDatabaseProvider),
            repo: SyncRepository(container.read(apiClientProvider), token),
          ).logReadingProgress(bookId: bookId, chapter: chNum);
        }
        container.invalidate(continueReadingSnapshotsProvider);
        container.invalidate(readingStreakStateProvider);
      },
    );
  }

  Future<void> _loadBook() async {
    final book = await BibleRepositoryProvider.of(
      context,
    ).loadBook(_entry);
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

    if (widget.autoStartAudio) {
      _playCurrentChapterAudio();
    }
    unawaited(_refreshParallel());
  }

  /// Reads the open chapter aloud with the user's own key and chosen voice.
  ///
  /// Anything that stops it from starting routes to the voice settings page
  /// rather than failing silently — a missing key is the common case on a
  /// fresh install, and it is fixable right there.
  Future<void> _playCurrentChapterAudio() async {
    final book = _book;
    if (book == null || _currentChapter >= book.chapters.length) return;
    final ch = book.chapters[_currentChapter];

    await playVersesAloud(
      context: context,
      ref: ref,
      title: '${_entry.bookNameAm} ${ch.chapterNumber}',
      verses: ch.allVerses.map((v) => v.text).toList(),
    );
  }

  /// Re-reads the parallel column for the open book.
  ///
  /// Cheap enough to call on every edition notification: the secondary book is
  /// cached in the repository, and a book the parallel canon does not carry
  /// resolves to null without touching the database twice.
  Future<void> _refreshParallel() async {
    final repo = _repo;
    if (repo == null) return;

    _primaryEditionId = repo.activeEditionId;
    final parallelId = repo.secondaryEditionId;

    if (parallelId == null) {
      if (!mounted) return;
      setState(() {
        _parallelOn = false;
        _secondaryBook = null;
        _secondaryLabel = '';
      });
      return;
    }

    final book = await repo.loadSecondaryBook(_entry.id);
    final secondary = await repo.secondaryEdition();
    final primary = await repo.activeEdition();
    if (!mounted) return;

    setState(() {
      _parallelOn = true;
      _secondaryBook = book;
      _primaryLabel = primary == null ? '' : _editionLabel(primary);
      _secondaryLabel = secondary == null ? '' : _editionLabel(secondary);
    });
  }

  static String _editionLabel(Edition e) => e.shortLabel;

  /// The open chapter in the parallel edition, null when its versification
  /// does not reach this far.
  Chapter? _secondaryChapterFor(int chapterNumber) {
    final book = _secondaryBook;
    if (book == null) return null;
    for (final c in book.chapters) {
      if (c.chapterNumber == chapterNumber) return c;
    }
    return null;
  }

  /// Re-reads the open book from the edition just switched to, holding the
  /// reader on the same chapter number.
  ///
  /// Two things can go wrong and both are ordinary: the new canon may not carry
  /// this book at all (the protestant editions have no deuterocanon), and its
  /// versification may not carry this chapter. The first leaves the reader, the
  /// second lands on the nearest chapter the edition does have.
  Future<void> _onEditionChanged() async {
    final repo = _repo;
    if (repo == null || !mounted) return;

    // Turning the parallel column on or off leaves the primary text alone;
    // reloading the book would throw away the reader's scroll position for a
    // change that does not affect it.
    if (_primaryEditionId != null &&
        repo.activeEditionId == _primaryEditionId) {
      await _refreshParallel();
      return;
    }

    final entry = await repo.bookById(_entry.id);
    if (!mounted) return;

    if (entry == null) {
      final s = L10n.of(context);
      final edition = await repo.activeEdition();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              s.editionBookMissing(
                edition == null ? '' : editionTitleFor(edition, s),
              ),
            ),
          ),
        );
      if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.pop(context);
      return;
    }

    final keepChapter = _currentChapterNumber;
    final book = await repo.loadBook(entry);
    if (!mounted) return;

    var idx = book.chapters.indexWhere((c) => c.chapterNumber == keepChapter);
    if (idx < 0) idx = (keepChapter - 1).clamp(0, book.chapters.length - 1);

    // A fresh controller rather than a jump: the new edition can have fewer
    // chapters, and a PageController restoring an out-of-range offset lands on
    // the wrong page.
    final previous = _pageCtrl;
    setState(() {
      _entry = entry;
      _book = book;
      _loading = false;
      _currentChapter = idx;
      _selectedKey = null;
      _selectionEndKey = null;
      _spotlightChapterPageIndex = null;
      _pageCtrl = PageController(initialPage: idx);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());

    _persistReadingPosition();
    _scheduleDwellTimer();
    await _refreshParallel();
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
    final target = idx.clamp(0, _book!.chapters.length - 1);
    // Animating across a long jump would flick through every chapter between
    // Psalm 1 and Psalm 119, so only neighbours slide.
    if ((target - _currentChapter).abs() > 2) {
      _pageCtrl.jumpToPage(target);
      return;
    }
    _pageCtrl.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  // ── Chapter picker ────────────────────────────────────────────────────────

  void _showChapterPicker(BuildContext ctx, AppSettings settings) {
    final book = _book;
    if (book == null || book.chapters.isEmpty) return;

    final isDark = settings.isDarkReader;
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => ReaderChapterPicker(
        entry: _entry,
        chapters: book.chapters,
        currentIndex: _currentChapter,
        useGeez: settings.useGeezNumbers,
        isAmharic: L10n.of(ctx) is AmStrings,
        s: L10n.of(ctx),
        surfaceColor: isDark ? readerDarkSurface : Colors.white,
        textColor: isDark ? readerDarkText : AppColors.textOnParchment,
        mutedColor: isDark ? readerDarkMuted : AppColors.textMuted,
        accentColor: isDark ? readerDarkAccent : AppColors.accentDeep,
        titleFontFamily: readerFonts[settings.titleFontIndex],
        onSelect: (i) {
          Navigator.pop(sheetCtx);
          _deselect();
          _goToChapter(i);
        },
      ),
    );
  }

  void _selectVerse(String key) {
    setState(() {
      if (_selectedKey == null) {
        _selectedKey = key;
        _selectionEndKey = null;
      } else if (key == _selectedKey && _selectionEndKey == null) {
        _selectedKey = null;
      } else {
        _selectionEndKey = key == _selectedKey ? null : key;
      }
    });
    _persistReadingPosition();
  }

  void _deselect() => setState(() {
    _selectedKey = null;
    _selectionEndKey = null;
  });

  String _verseKey(int chNum, int secIdx, int verseNum) =>
      '$chNum:$secIdx:$verseNum';

  bool _isSelected(int chNum, int secIdx, int verseNum) {
    if (_selectedKey == null) return false;
    final ap = _selectedKey!.split(':');
    if (ap.length != 3 || int.tryParse(ap[0]) != chNum) return false;
    final anchor = int.tryParse(ap[2]);
    if (anchor == null) return false;
    final end = _selectionEndVerseNum;
    if (end == null) return verseNum == anchor;
    final lo = anchor < end ? anchor : end;
    final hi = anchor < end ? end : anchor;
    return verseNum >= lo && verseNum <= hi;
  }

  int? get _selectedVerseNum {
    if (_selectedKey == null) return null;
    final parts = _selectedKey!.split(':');
    return parts.length == 3 ? int.tryParse(parts[2]) : null;
  }

  int? get _selectionEndVerseNum {
    if (_selectionEndKey == null) return null;
    final parts = _selectionEndKey!.split(':');
    return parts.length == 3 ? int.tryParse(parts[2]) : null;
  }

  /// The smaller verse number of the selected range (anchor when single verse).
  int? get _selectionVerseStart {
    final anchor = _selectedVerseNum;
    if (anchor == null) return null;
    final end = _selectionEndVerseNum;
    if (end == null) return anchor;
    return anchor < end ? anchor : end;
  }

  /// Number of verses in the selection (1 for single verse).
  int get _selectionVerseCount {
    final anchor = _selectedVerseNum;
    if (anchor == null) return 0;
    final end = _selectionEndVerseNum;
    if (end == null) return 1;
    return (end - anchor).abs() + 1;
  }

  int get _currentChapterNumber {
    final book = _book;
    if (book == null || _currentChapter >= book.chapters.length) return 1;
    return book.chapters[_currentChapter].chapterNumber;
  }

  ChapterKey get _chapterKey =>
      (bookId: _entry.id, chapter: _currentChapterNumber);

  String? _selectedVerseText(AppSettings settings) {
    if (_book == null || _selectedKey == null) return null;
    final parts = _selectedKey!.split(':');
    if (parts.length != 3) return null;
    final chNum = int.tryParse(parts[0]);
    if (chNum == null) return null;
    final start = _selectionVerseStart;
    if (start == null) return null;
    final count = _selectionVerseCount;
    try {
      final chapter = _book!.chapters.firstWhere(
        (c) => c.chapterNumber == chNum,
      );
      final verseMap = {
        for (final sec in chapter.sections)
          for (final v in sec.verses) v.verseNumber: v.text,
      };
      final texts = [
        for (var v = start; v < start + count; v++)
          if (verseMap[v] != null) verseMap[v]!,
      ];
      if (texts.isEmpty) return null;
      final useGeez = settings.useGeezNumbers;
      final startStr = useGeez ? toGeez(start) : '$start';
      final refEnd = count > 1
          ? '-${useGeez ? toGeez(start + count - 1) : '${start + count - 1}'}'
          : '';
      final ref = '${_entry.bookNameAm} $chNum:$startStr$refEnd';
      final deepLink = verseDeepLinkUri(_entry, chNum, start);
      return '${texts.join('\n')}\n$ref\n$deepLink';
    } catch (_) {
      return null;
    }
  }

  List<Verse> _getSelectedVerses() {
    if (_book == null || _selectedKey == null) return [];
    final parts = _selectedKey!.split(':');
    if (parts.length != 3) return [];
    final chNum = int.tryParse(parts[0]);
    if (chNum == null) return [];
    final start = _selectionVerseStart;
    if (start == null) return [];
    final count = _selectionVerseCount;
    try {
      final chapter = _book!.chapters.firstWhere(
        (c) => c.chapterNumber == chNum,
      );
      final allVerses = chapter.allVerses;
      return allVerses
          .where((v) => v.verseNumber >= start && v.verseNumber < start + count)
          .toList();
    } catch (_) {
      return [];
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

  // ── Reference Jump sheet ──────────────────────────────────────────────────

  void _showReferenceJumpSheet(BuildContext ctx, AppSettings settings) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReferenceJumpSheet(
        useGeez: settings.useGeezNumbers,
        isAmharic: L10n.of(ctx) is AmStrings,
        s: L10n.of(ctx),
      ),
    );
  }

  // ── Highlight sheet ───────────────────────────────────────────────────────

  void _showHighlightSheet(
    BuildContext ctx,
    AppSettings settings,
    ChapterAnnotations annotations,
  ) {
    final verseNum = _selectionVerseStart;
    if (verseNum == null) return;
    final count = _selectionVerseCount;

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
                bookNumber: _entry.bookNumber,
                color: color,
                verseCount: count,
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
    final verseNum = _selectionVerseStart;
    if (verseNum == null) return;
    final count = _selectionVerseCount;

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
                bookNumber: _entry.bookNumber,
                content: content,
                verseCount: count,
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
    final reference = '${_entry.bookNameAm} $chNumDisplay:$vNumDisplay';

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
          setState(() {
            _selectedKey = verseKey;
            _selectionEndKey = null;
          });
          final chKey = (bookId: _entry.id, chapter: chNum);
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

  // ── Footnotes and cross references ────────────────────────────────────────

  void _showApparatus(Verse verse, int chapterNumber) {
    if (verse.refs.isEmpty && verse.notes.isEmpty) return;

    final s = L10n.of(context);
    final settings = Settings.of(context);
    final isDark = settings.isDarkReader;
    final useGeez = settings.useGeezNumbers;

    final chNum = useGeez ? toGeez(chapterNumber) : '$chapterNumber';
    final vNum = verse.displayNumber(useGeez: useGeez);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerseApparatusSheet(
        reference: '${_entry.bookNameAm} $chNum:$vNum',
        refs: verse.refs,
        notes: verse.notes,
        s: s,
        surfaceColor: isDark ? readerDarkSurface : Colors.white,
        textColor: isDark ? readerDarkText : AppColors.textOnParchment,
        mutedColor: isDark ? readerDarkMuted : AppColors.textMuted,
        accentColor: isDark ? readerDarkAccent : AppColors.accentDeep,
        bodyFont: readerFonts[settings.bodyFontIndex],
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

          final verseNum = _selectionVerseStart;
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
                                entry: _entry,
                                currentChapter: _currentChapter,
                                chapterNumber:
                                    chapterReady ? _currentChapterNumber : null,
                                onChapterTap: chapterReady
                                    ? () => _showChapterPicker(context, settings)
                                    : null,
                                onGoToReference: () =>
                                    _showReferenceJumpSheet(context, settings),
                                useGeez: useGeez,
                                isAmharic: isAm,
                                bgColor: bgColor,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                accentColor: accentColor,
                                sheetTheme: EditionSheetTheme(
                                  surface: surfaceColor,
                                  text: textColor,
                                  muted: mutedColor,
                                  accent: accentColor,
                                  border: mutedColor.withValues(alpha: 0.25),
                                ),
                                s: s,
                                onSearch: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SearchTab(initialBook: _entry),
                                  ),
                                ),
                                onBack: () => Navigator.pop(context),
                                onFontSettings: () =>
                                    _showFontSheet(context, settings),
                                onAudio: _playCurrentChapterAudio,
                              ),
                              if (chapterReady)
                                ReaderBreadcrumb(
                                  entry: _entry,
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
                              onTap: () {
                                if (!settings.hasSeenReaderHint) {
                                  Settings.update(
                                    context,
                                    settings.copyWith(hasSeenReaderHint: true),
                                  );
                                }
                                _deselect();
                              },
                              behavior: HitTestBehavior.translucent,
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    controller: _pageCtrl,
                                    itemCount: _book!.chapters.length,
                                    onPageChanged: (i) {
                                      _recordHistory();
                                      setState(() => _currentChapter = i);
                                      _setReaderChromeVisible(true);
                                      _persistReadingPosition();
                                      _scheduleDwellTimer();
                                    },
                                    itemBuilder: (ctx, i) {
                                      final pageChapterNum =
                                          _book!.chapters[i].chapterNumber;
                                      final pageKey = (
                                        bookId: _entry.id,
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
                                          final spotlightVerse =
                                              (widget.initialVerse != null &&
                                                      i ==
                                                          _spotlightChapterPageIndex)
                                                  ? widget.initialVerse
                                                  : null;
                                          final spotlightKey =
                                              spotlightVerse == null
                                                  ? null
                                                  : _spotlightKey;

                                          // Parallel wins over continuous
                                          // reading: a paragraph of run-on
                                          // verses has nothing to align a
                                          // second translation against.
                                          if (_parallelOn) {
                                            return ParallelChapterPage(
                                              entry: _entry,
                                              chapter: _book!.chapters[i],
                                              secondaryChapter:
                                                  _secondaryChapterFor(
                                                pageChapterNum,
                                              ),
                                              secondaryBookMissing:
                                                  _secondaryBook == null,
                                              primaryLabel: _primaryLabel,
                                              secondaryLabel: _secondaryLabel,
                                              isDark: isDark,
                                              fontSize: settings.fontSize,
                                              fontFamily: bodyFont,
                                              titleFontFamily: titleFont,
                                              textColor: textColor,
                                              mutedColor: mutedColor,
                                              accentColor: accentColor,
                                              useGeez: useGeez,
                                              isAmharic: isAm,
                                              s: s,
                                              isSelectedFn: _isSelected,
                                              onVerseTap: _selectVerse,
                                              verseKeyFn: _verseKey,
                                              annotations: pageAnnotations,
                                              onNoteTap: (key, ann) =>
                                                  _showNoteView(key, ann),
                                              onApparatusTap: (verse) =>
                                                  _showApparatus(
                                                verse,
                                                pageChapterNum,
                                              ),
                                              spotlightVerseNum:
                                                  spotlightVerse,
                                              spotlightKey: spotlightKey,
                                            );
                                          }

                                          return ReaderChapterPage(
                                            entry: _entry,
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
                                            onApparatusTap: (verse) =>
                                                _showApparatus(
                                              verse,
                                              pageChapterNum,
                                            ),
                                            spotlightVerseNum: _audioVerseNum(i) ?? spotlightVerse,
                                            spotlightKey: _audioVerseNum(i) != null
                                                ? _audioScrollKey
                                                : spotlightKey,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  // Verse action bar
                                  AnimatedSlide(
                                    offset: (_selectedKey != null && !_isAudioPlaying)
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
                                                    _entry.bookNumber,
                                                verseCount:
                                                    _selectionVerseCount,
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
                                        onShare: () {
                                          final selectedVerses = _getSelectedVerses();
                                          if (selectedVerses.isNotEmpty && _book != null) {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.transparent,
                                              builder: (context) => VerseCardSheet(
                                                verses: selectedVerses,
                                                book: _book!,
                                                chapterNumber: _currentChapterNumber,
                                              ),
                                            );
                                          }
                                          _deselect();
                                        },
                                      ),
                                    ),
                                  ),
                                  // Contextual Reader Hint (One-off Coach Mark)
                                  if (!settings.hasSeenReaderHint)
                                    Positioned(
                                      top: 16,
                                      left: 20,
                                      right: 20,
                                      child: GestureDetector(
                                        onTap: () {
                                          Settings.update(
                                            context,
                                            settings.copyWith(
                                              hasSeenReaderHint: true,
                                            ),
                                          );
                                        },
                                        child: Material(
                                          elevation: 6,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          color: isDark
                                              ? readerDarkSurface
                                              : Colors.white,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: accentColor.withValues(
                                                    alpha: 0.5),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.touch_app_rounded,
                                                  color: accentColor,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    s.readerVerseActionHint,
                                                    style: TextStyle(
                                                      fontFamily: bodyFont,
                                                      fontSize: 13,
                                                      color: textColor,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.close_rounded,
                                                  color: mutedColor,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  _buildAudioMiniPlayer(settings),
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

  Widget _buildAudioMiniPlayer(AppSettings settings) {
    return ValueListenableBuilder<AudioState>(
      valueListenable: AudioService.instance.stateNotifier,
      builder: (context, audioState, _) {
        if (audioState == AudioState.stopped) return const SizedBox.shrink();
        final isDark = settings.isDarkReader;
        final surfaceColor = isDark ? readerDarkSurface : Colors.white;
        final textColor = isDark ? readerDarkText : AppColors.textOnParchment;
        final accentColor = isDark ? readerDarkAccent : AppColors.accentDeep;

        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: audioState == AudioState.buffering
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accentColor,
                        ),
                      )
                    : Icon(
                        audioState == AudioState.playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        size: 32,
                        color: accentColor,
                      ),
                onPressed: audioState == AudioState.buffering
                    ? null
                    : () {
                        if (audioState == AudioState.playing) {
                          AudioService.instance.pause();
                        } else {
                          AudioService.instance.resume();
                        }
                      },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: AudioService.instance.currentTitleNotifier,
                  builder: (context, title, _) {
                    return Text(
                      title ?? 'ድምፅ ንባብ',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop_rounded, color: Colors.redAccent),
                onPressed: () => AudioService.instance.stop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
