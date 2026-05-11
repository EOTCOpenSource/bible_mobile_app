import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../me/presentation/pages/reading_settings_page.dart';
import '../../data/models/book.dart';
import '../../data/models/book_index_entry.dart';
import '../widgets/reader/constants.dart';
import '../widgets/reader/toolbar.dart';
import '../widgets/reader/breadcrumb.dart';
import '../widgets/reader/chapter_page.dart';
import '../widgets/reader/font_sheet.dart';
import '../widgets/reader/verse_action_bar.dart';
import '../widgets/reader/chapter_nav_bar.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.entry, this.initialChapter = 0});

  final BookIndexEntry entry;
  final int initialChapter;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  Book? _book;
  bool _loading = true;
  late final PageController _pageCtrl;
  int _currentChapter = 0;

  String? _selectedKey;

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
    final book = await BibleRepositoryProvider.of(context).loadBook(widget.entry);
    if (mounted) setState(() { _book = book; _loading = false; });
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

  String? _selectedVerseText(AppSettings settings) {
    if (_book == null || _selectedKey == null) return null;
    final parts = _selectedKey!.split(':');
    if (parts.length != 3) return null;
    final chNum  = int.tryParse(parts[0]);
    final secIdx = int.tryParse(parts[1]);
    final vNum   = int.tryParse(parts[2]);
    if (chNum == null || secIdx == null || vNum == null) return null;
    try {
      final chapter = _book!.chapters.firstWhere((c) => c.chapterNumber == chNum);
      final section = chapter.sections[secIdx];
      final verse   = section.verses.firstWhere((v) => v.verseNumber == vNum);
      return '${widget.entry.bookNameAm} $chNum:${verse.verseNumber}\n${verse.text}';
    } catch (_) {
      return null;
    }
  }

  // ── Font settings bottom sheet ────────────────────────────────────────────

  void _showFontSheet(BuildContext ctx, AppSettings settings) {
    final isDark       = settings.isDarkReader;
    final surfaceColor = isDark ? readerDarkSurface : Colors.white;
    final textColor    = isDark ? readerDarkText    : AppColors.textOnParchment;
    final mutedColor   = isDark ? readerDarkMuted   : AppColors.textMuted;
    final accentColor  = isDark ? readerDarkAccent  : AppColors.accentDeep;

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
        onSizeChange: (v) => Settings.update(
          ctx, settings.copyWith(fontSize: v),
        ),
        onFontChange: (i) => Settings.update(
          ctx, settings.copyWith(bodyFontIndex: i),
        ),
        onDarkToggle: () => Settings.update(
          ctx, settings.copyWith(isDarkReader: !isDark),
        ),
        onOpenFullSettings: () {
          Navigator.pop(ctx); // close sheet
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const ReadingSettingsPage()),
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s        = L10n.of(context);
    final settings = Settings.of(context);
    final useGeez  = settings.useGeezNumbers;
    final isAm     = s is AmStrings;
    final isDark   = settings.isDarkReader;

    final bgColor      = isDark ? readerDarkBg      : AppColors.parchment;
    final surfaceColor = isDark ? readerDarkSurface  : Colors.white;
    final textColor    = isDark ? readerDarkText     : AppColors.textOnParchment;
    final mutedColor   = isDark ? readerDarkMuted    : AppColors.textMuted;
    final accentColor  = isDark ? readerDarkAccent   : AppColors.accentDeep;

    final bodyFont = readerFonts[settings.bodyFontIndex];
    final titleFont = readerFonts[settings.titleFontIndex];

    final chapterReady = !_loading &&
        _book != null &&
        _currentChapter < _book!.chapters.length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Toolbar ──────────────────────────────────────────────────────
            ReaderToolbar(
              entry:          widget.entry,
              currentChapter: _currentChapter,
              useGeez:        useGeez,
              isAmharic:      isAm,
              bgColor:        bgColor,
              textColor:      textColor,
              mutedColor:     mutedColor,
              s:              s,
              onBack:         () => Navigator.pop(context),
              onFontSettings: () => _showFontSheet(context, settings),
            ),
            // ── Breadcrumb ───────────────────────────────────────────────────
            if (chapterReady)
              ReaderBreadcrumb(
                entry:          widget.entry,
                chapter:        _book!.chapters[_currentChapter],
                useGeez:        useGeez,
                isAmharic:      isAm,
                s:              s,
                bgColor:        bgColor,
                accentColor:    accentColor,
                mutedColor:     mutedColor,
              ),
            // ── Pages ────────────────────────────────────────────────────────
            Expanded(
              child: _loading || _book == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark ? AppColors.accent : AppColors.primary,
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
                            itemBuilder: (ctx, i) => ReaderChapterPage(
                              entry:         widget.entry,
                              chapter:       _book!.chapters[i],
                              isDark:        isDark,
                              fontSize:      settings.fontSize,
                              fontFamily:    bodyFont,
                              titleFontFamily: titleFont,
                              textColor:     textColor,
                              mutedColor:    mutedColor,
                              accentColor:   accentColor,
                              useGeez:       useGeez,
                              isAmharic:     isAm,
                              isSelectedFn:  _isSelected,
                              onVerseTap:    _selectVerse,
                              verseKeyFn:    _verseKey,
                            ),
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
                                s:            s,
                                isDark:       isDark,
                                surfaceColor: surfaceColor,
                                textColor:    textColor,
                                onBookmark: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.comingSoon)));
                                },
                                onHighlight: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.comingSoon)));
                                },
                                onCopy: () async {
                                  final text = _selectedVerseText(settings);
                                  if (text != null) {
                                    await Clipboard.setData(
                                        ClipboardData(text: text));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(s.verseCopy)));
                                    }
                                  }
                                  _deselect();
                                },
                                onShare: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.comingSoon)));
                                },
                                onMore: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.comingSoon)));
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
                totalChapters:  _book!.chapters.length,
                isDark:         isDark,
                useGeez:        useGeez,
                s:              s,
                bgColor:        bgColor,
                surfaceColor:   surfaceColor,
                textColor:      textColor,
                mutedColor:     mutedColor,
                onPrev: () => _goToChapter(_currentChapter - 1),
                onNext: () => _goToChapter(_currentChapter + 1),
              ),
          ],
        ),
      ),
    );
  }
}
