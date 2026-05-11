import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kenat/kenat.dart';
import '../../core/l10n/l10n.dart';
import '../../core/providers/repository_provider.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/book.dart';
import '../../data/models/book_index_entry.dart';

// ── Available reader fonts ────────────────────────────────────────────────────

const _readerFonts = [
  AppTypography.shiromeda,
  AppTypography.abbaGarima,
  AppTypography.selam,
  AppTypography.kiros,
];
const _fontNames = ['Shiromeda', 'Abba Garima', 'Selam', 'Kiros'];

// ── Dark mode palette ─────────────────────────────────────────────────────────

const _darkBg      = Color(0xFF151210);
const _darkSurface = Color(0xFF231E1B);
const _darkText    = Color(0xFFF5EBE0);
const _darkMuted   = Color(0xFF9E8878);
const _darkAccent  = Color(0xFFD4A853);

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

  bool _isDark = false;
  double _fontSize = 17.0;
  int _fontIndex = 0;

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

  String? get _selectedVerseText {
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

  Color get _bgColor      => _isDark ? _darkBg      : AppColors.parchment;
  Color get _surfaceColor => _isDark ? _darkSurface  : Colors.white;
  Color get _textColor    => _isDark ? _darkText     : AppColors.textOnParchment;
  Color get _mutedColor   => _isDark ? _darkMuted    : AppColors.textMuted;
  Color get _captionColor => _isDark ? const Color(0xFF6B5A50) : AppColors.textCaption;
  Color get _accentColor  => _isDark ? _darkAccent   : AppColors.accentDeep;

  void _showFontSheet(BuildContext ctx) {
    double localSize   = _fontSize;
    int    localFont   = _fontIndex;
    bool   localDark   = _isDark;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setSheet) => _FontSheet(
          isDark:   localDark,
          fontSize: localSize,
          fontIdx:  localFont,
          textColor:   _textColor,
          mutedColor:  _mutedColor,
          accentColor: _accentColor,
          surfaceColor: _surfaceColor,
          onSizeChange: (v) {
            setSheet(() => localSize = v);
            setState(() => _fontSize = v);
          },
          onFontChange: (i) {
            setSheet(() => localFont = i);
            setState(() => _fontIndex = i);
          },
          onDarkToggle: () {
            setSheet(() => localDark = !localDark);
            setState(() => _isDark = !_isDark);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s       = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;
    final isAm    = s is AmStrings;

    final chapterReady = !_loading &&
        _book != null &&
        _currentChapter < _book!.chapters.length;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Toolbar ──────────────────────────────────────────────────────
            _ReaderToolbar(
              entry:          widget.entry,
              currentChapter: _currentChapter,
              isDark:         _isDark,
              useGeez:        useGeez,
              isAmharic:      isAm,
              bgColor:        _bgColor,
              textColor:      _textColor,
              mutedColor:     _mutedColor,
              s:              s,
              onBack:         () => Navigator.pop(context),
              onFontSettings: () => _showFontSheet(context),
            ),
            // ── Breadcrumb ───────────────────────────────────────────────────
            if (chapterReady)
              _BreadcrumbBar(
                entry:          widget.entry,
                chapter:        _book!.chapters[_currentChapter],
                useGeez:        useGeez,
                isAmharic:      isAm,
                s:              s,
                bgColor:        _bgColor,
                accentColor:    _accentColor,
                mutedColor:     _mutedColor,
              ),
            // ── Pages ────────────────────────────────────────────────────────
            Expanded(
              child: _loading || _book == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: _isDark ? AppColors.accent : AppColors.primary,
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
                            itemBuilder: (ctx, i) => _ChapterPage(
                              entry:         widget.entry,
                              chapter:       _book!.chapters[i],
                              isDark:        _isDark,
                              fontSize:      _fontSize,
                              fontFamily:    _readerFonts[_fontIndex],
                              textColor:     _textColor,
                              mutedColor:    _mutedColor,
                              captionColor:  _captionColor,
                              bgColor:       _bgColor,
                              accentColor:   _accentColor,
                              surfaceColor:  _surfaceColor,
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
                              child: _VerseActionBar(
                                s:            s,
                                isDark:       _isDark,
                                surfaceColor: _surfaceColor,
                                textColor:    _textColor,
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
                                  final text = _selectedVerseText;
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
              _ChapterNavBar(
                currentChapter: _currentChapter,
                totalChapters:  _book!.chapters.length,
                isDark:         _isDark,
                useGeez:        useGeez,
                s:              s,
                bgColor:        _bgColor,
                surfaceColor:   _surfaceColor,
                textColor:      _textColor,
                mutedColor:     _mutedColor,
                onPrev: () => _goToChapter(_currentChapter - 1),
                onNext: () => _goToChapter(_currentChapter + 1),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Toolbar ───────────────────────────────────────────────────────────────────

class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.entry,
    required this.currentChapter,
    required this.isDark,
    required this.useGeez,
    required this.isAmharic,
    required this.bgColor,
    required this.textColor,
    required this.mutedColor,
    required this.s,
    required this.onBack,
    required this.onFontSettings,
  });

  final BookIndexEntry entry;
  final int currentChapter;
  final bool isDark;
  final bool useGeez;
  final bool isAmharic;
  final Color bgColor;
  final Color textColor;
  final Color mutedColor;
  final AppStrings s;
  final VoidCallback onBack;
  final VoidCallback onFontSettings;

  String get _label {
    final n = currentChapter + 1;
    final ch = useGeez ? toGeez(n) : '$n';
    final book = isAmharic ? entry.bookShortNameAm : entry.bookShortNameEn;
    return '$book · ${s.chapterAbbr} $ch';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Menu / back
          IconButton(
            icon: Icon(Icons.menu_rounded, size: 22, color: mutedColor),
            onPressed: onBack,
          ),
          // Chapter dropdown (center)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _label,
                      style: TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: mutedColor),
                ],
              ),
            ),
          ),
          // Aa
          GestureDetector(
            onTap: onFontSettings,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Text(
                'Aa',
                style: TextStyle(
                  fontFamily: AppTypography.nokiaPureheadline,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: mutedColor,
                ),
              ),
            ),
          ),
          // Search
          IconButton(
            icon: Icon(Icons.search_rounded, size: 20, color: mutedColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ── Breadcrumb ────────────────────────────────────────────────────────────────

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({
    required this.entry,
    required this.chapter,
    required this.useGeez,
    required this.isAmharic,
    required this.s,
    required this.bgColor,
    required this.accentColor,
    required this.mutedColor,
  });

  final BookIndexEntry entry;
  final Chapter chapter;
  final bool useGeez;
  final bool isAmharic;
  final AppStrings s;
  final Color bgColor;
  final Color accentColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final chNum    = useGeez ? toGeez(chapter.chapterNumber) : '${chapter.chapterNumber}';
    final bookTag  = isAmharic ? entry.bookShortNameAm : entry.bookShortNameEn;
    final testTag  = entry.isOldTestament ? s.booksOldTestament : s.booksNewTestament;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _LocationChip(text: bookTag, accentColor: accentColor),
          const SizedBox(width: 8),
          _LocationChip(
              text: '${s.chapterAbbr} $chNum', accentColor: accentColor),
          const Spacer(),
          Text(
            testTag,
            style: TextStyle(
              fontFamily: AppTypography.amharicCaption.fontFamily,
              fontSize: 10,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.text, required this.accentColor});

  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTypography.shiromeda,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }
}

// ── Chapter page ──────────────────────────────────────────────────────────────

class _ChapterPage extends StatelessWidget {
  const _ChapterPage({
    required this.entry,
    required this.chapter,
    required this.isDark,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.mutedColor,
    required this.captionColor,
    required this.bgColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.useGeez,
    required this.isAmharic,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
  });

  final BookIndexEntry entry;
  final Chapter chapter;
  final bool isDark;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
  final Color mutedColor;
  final Color captionColor;
  final Color bgColor;
  final Color accentColor;
  final Color surfaceColor;
  final bool useGeez;
  final bool isAmharic;
  final bool Function(int chNum, int secIdx, int verseNum) isSelectedFn;
  final ValueChanged<String> onVerseTap;
  final String Function(int chNum, int secIdx, int verseNum) verseKeyFn;

  @override
  Widget build(BuildContext context) {
    // +1 so index 0 = chapter header, index i+1 = section[i]
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: chapter.sections.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return _ChapterHeader(
            entry:       entry,
            chapter:     chapter,
            isAmharic:   isAmharic,
            isDark:      isDark,
            accentColor: accentColor,
            textColor:   textColor,
            mutedColor:  mutedColor,
          );
        }
        final secIdx = i - 1;
        return _SectionView(
          section:     chapter.sections[secIdx],
          secIdx:      secIdx,
          chapter:     chapter,
          fontSize:    fontSize,
          fontFamily:  fontFamily,
          textColor:   textColor,
          accentColor: accentColor,
          isDark:      isDark,
          useGeez:     useGeez,
          isSelectedFn: isSelectedFn,
          onVerseTap:  onVerseTap,
          verseKeyFn:  verseKeyFn,
        );
      },
    );
  }
}

// ── Chapter header (illuminated initial + book title) ─────────────────────────

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.entry,
    required this.chapter,
    required this.isAmharic,
    required this.isDark,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
  });

  final BookIndexEntry entry;
  final Chapter chapter;
  final bool isAmharic;
  final bool isDark;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;

  String get _firstSectionTitle {
    for (final sec in chapter.sections) {
      if (sec.title.trim().isNotEmpty) return sec.title;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bookName  = isAmharic ? entry.bookNameAm  : entry.bookNameEn;
    final altName   = isAmharic ? entry.bookNameEn  : entry.bookNameAm;
    final shortName = entry.bookShortNameAm.isNotEmpty
        ? entry.bookShortNameAm
        : entry.bookShortNameEn;
    final sectionTitle = _firstSectionTitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illuminated initial / decorative badge
              Container(
                width: 56,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2420)
                      : AppColors.parchmentDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  shortName,
                  style: TextStyle(
                    fontFamily: AppTypography.shiromeda,
                    fontSize: shortName.length <= 2 ? 22 : 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 14),
              // Title area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookName,
                      style: TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.2,
                      ),
                    ),
                    if (altName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        altName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.nokiaPureheadline,
                          fontSize: 9,
                          letterSpacing: 1.0,
                          color: mutedColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (sectionTitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        sectionTitle,
                        style: TextStyle(
                          fontFamily: AppTypography.abbaGarima,
                          fontSize: 13,
                          color: accentColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: accentColor.withValues(alpha: 0.25),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Section view ──────────────────────────────────────────────────────────────

class _SectionView extends StatelessWidget {
  const _SectionView({
    required this.section,
    required this.secIdx,
    required this.chapter,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.accentColor,
    required this.isDark,
    required this.useGeez,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
  });

  final Section section;
  final int secIdx;
  final Chapter chapter;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
  final Color accentColor;
  final bool isDark;
  final bool useGeez;
  final bool Function(int, int, int) isSelectedFn;
  final ValueChanged<String> onVerseTap;
  final String Function(int, int, int) verseKeyFn;

  @override
  Widget build(BuildContext context) {
    // Skip the first section title — it's shown in the chapter header
    final showTitle = secIdx > 0 && section.title.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                section.title,
                style: TextStyle(
                  fontFamily: AppTypography.abbaGarima,
                  fontSize: fontSize - 2,
                  color: accentColor,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ),
          ] else
            const SizedBox(height: 8),
          // Verses — inline format
          ...section.verses.map((verse) {
            final key      = verseKeyFn(chapter.chapterNumber, secIdx, verse.verseNumber);
            final selected = isSelectedFn(chapter.chapterNumber, secIdx, verse.verseNumber);
            final numStr   = useGeez ? toGeez(verse.verseNumber) : '${verse.verseNumber}';

            return GestureDetector(
              onTap: () => onVerseTap(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? accentColor.withValues(alpha: isDark ? 0.18 : 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$numStr ',
                        style: TextStyle(
                          fontFamily: AppTypography.nokiaPureheadline,
                          fontSize: fontSize * 0.62,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      TextSpan(
                        text: verse.text,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: fontSize,
                          height: 1.85,
                          color: textColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Font settings sheet ───────────────────────────────────────────────────────

class _FontSheet extends StatelessWidget {
  const _FontSheet({
    required this.isDark,
    required this.fontSize,
    required this.fontIdx,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.onSizeChange,
    required this.onFontChange,
    required this.onDarkToggle,
  });

  final bool isDark;
  final double fontSize;
  final int fontIdx;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final Color surfaceColor;
  final ValueChanged<double> onSizeChange;
  final ValueChanged<int> onFontChange;
  final VoidCallback onDarkToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Font size slider
          Row(
            children: [
              GestureDetector(
                onTap: () => onSizeChange((fontSize - 2).clamp(13, 26)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('A',
                      style: TextStyle(
                          fontFamily: AppTypography.nokiaPureheadline,
                          fontSize: 13,
                          color: mutedColor)),
                ),
              ),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 13,
                  max: 26,
                  divisions: 6,
                  activeColor: accentColor,
                  inactiveColor: mutedColor.withValues(alpha: 0.3),
                  onChanged: onSizeChange,
                ),
              ),
              GestureDetector(
                onTap: () => onSizeChange((fontSize + 2).clamp(13, 26)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('A',
                      style: TextStyle(
                          fontFamily: AppTypography.nokiaPureheadline,
                          fontSize: 20,
                          color: textColor)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Font family picker
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _fontNames.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onFontChange(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: i == fontIdx
                              ? accentColor.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i == fontIdx
                                ? accentColor
                                : mutedColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _fontNames[i],
                          style: TextStyle(
                            fontFamily: _readerFonts[i],
                            fontSize: 14,
                            color: i == fontIdx ? accentColor : mutedColor,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dark mode toggle
          Row(
            children: [
              Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: mutedColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isDark ? 'Light Mode' : 'Night Mode',
                  style: TextStyle(
                    fontFamily: AppTypography.nokiaPureheadline,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (_) => onDarkToggle(),
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Verse action bar ──────────────────────────────────────────────────────────

class _VerseActionBar extends StatelessWidget {
  const _VerseActionBar({
    required this.s,
    required this.isDark,
    required this.surfaceColor,
    required this.textColor,
    required this.onBookmark,
    required this.onHighlight,
    required this.onCopy,
    required this.onShare,
    required this.onMore,
  });

  final AppStrings s;
  final bool isDark;
  final Color surfaceColor;
  final Color textColor;
  final VoidCallback onBookmark;
  final VoidCallback onHighlight;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionBtn(icon: Icons.bookmark_add_outlined, label: s.verseBookmark, textColor: textColor, onTap: onBookmark),
          _ActionBtn(icon: Icons.edit_outlined,         label: s.verseHighlight, textColor: textColor, onTap: onHighlight),
          _ActionBtn(icon: Icons.copy_rounded,          label: s.verseCopy,      textColor: textColor, onTap: onCopy),
          _ActionBtn(icon: Icons.share_outlined,        label: s.verseShare,     textColor: textColor, onTap: onShare),
          _ActionBtn(icon: Icons.more_horiz_rounded,    label: s.verseMore,      textColor: textColor, onTap: onMore),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.amharicCaption.copyWith(
                fontSize: 10,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chapter nav bar ───────────────────────────────────────────────────────────

class _ChapterNavBar extends StatelessWidget {
  const _ChapterNavBar({
    required this.currentChapter,
    required this.totalChapters,
    required this.isDark,
    required this.useGeez,
    required this.s,
    required this.bgColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.onPrev,
    required this.onNext,
  });

  final int currentChapter;
  final int totalChapters;
  final bool isDark;
  final bool useGeez;
  final AppStrings s;
  final Color bgColor;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  String _ch(int idx) {
    final n = idx + 1;
    return '${s.chapterAbbr} ${useGeez ? toGeez(n) : n}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentChapter > 0;
    final hasNext = currentChapter < totalChapters - 1;
    final total   = useGeez ? toGeez(totalChapters) : '$totalChapters';

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          // Prev
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            label: hasPrev ? _ch(currentChapter - 1) : '',
            enabled: hasPrev,
            textColor: textColor,
            mutedColor: mutedColor,
            onTap: onPrev,
          ),
          // Center pill
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  '${_ch(currentChapter)}  ·  $total',
                  style: TextStyle(
                    fontFamily: AppTypography.shiromeda,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
          // Next
          _NavArrow(
            icon: Icons.chevron_right_rounded,
            label: hasNext ? _ch(currentChapter + 1) : '',
            enabled: hasNext,
            isNext: true,
            textColor: textColor,
            mutedColor: mutedColor,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
    this.isNext = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool isNext;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? textColor : mutedColor.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isNext) Icon(icon, color: color, size: 22),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.shiromeda,
                  fontSize: 11,
                  color: color,
                ),
              ),
            if (isNext) Icon(icon, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
