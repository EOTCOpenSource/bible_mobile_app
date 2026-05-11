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

// ── Dark mode palette ─────────────────────────────────────────────────────────

const _darkBg      = Color(0xFF151210);
const _darkSurface = Color(0xFF231E1B);
const _darkText    = Color(0xFFF5EBE0);
const _darkMuted   = Color(0xFF9E8878);

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

  // null = no selection;  key = "chapterNum:sectionIdx:verseNum"
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
    final book =
        await BibleRepositoryProvider.of(context).loadBook(widget.entry);
    if (mounted) setState(() { _book = book; _loading = false; });
  }

  void _goToChapter(int idx) {
    if (_book == null) return;
    final clamped = idx.clamp(0, _book!.chapters.length - 1);
    _pageCtrl.animateToPage(
      clamped,
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

  // Return the text of the currently selected verse, for clipboard
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

  // ── Colors based on mode ────────────────────────────────────────────────────

  Color get _bgColor      => _isDark ? _darkBg      : Colors.white;
  Color get _surfaceColor => _isDark ? _darkSurface  : AppColors.surfaceDim;
  Color get _textColor    => _isDark ? _darkText     : AppColors.textOnParchment;
  Color get _mutedColor   => _isDark ? _darkMuted    : AppColors.textMuted;
  Color get _captionColor => _isDark ? const Color(0xFF6B5A50) : AppColors.textCaption;

  @override
  Widget build(BuildContext context) {
    final s       = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;
    final isAm    = s is AmStrings;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Toolbar ──────────────────────────────────────────────────────
            _ReaderToolbar(
              entry: widget.entry,
              currentChapter: _currentChapter,
              isDark: _isDark,
              fontSize: _fontSize,
              useGeez: useGeez,
              isAmharic: isAm,
              bgColor: _bgColor,
              textColor: _textColor,
              mutedColor: _mutedColor,
              onBack: () => Navigator.pop(context),
              onToggleDark: () => setState(() => _isDark = !_isDark),
              onFontSizeIncrease: () =>
                  setState(() => _fontSize = (_fontSize + 2).clamp(13, 26)),
              onFontSizeDecrease: () =>
                  setState(() => _fontSize = (_fontSize - 2).clamp(13, 26)),
              onFontCycle: () =>
                  setState(() => _fontIndex = (_fontIndex + 1) % _readerFonts.length),
            ),
            // ── Chapter pages ────────────────────────────────────────────────
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
                              chapter: _book!.chapters[i],
                              isDark: _isDark,
                              fontSize: _fontSize,
                              fontFamily: _readerFonts[_fontIndex],
                              textColor: _textColor,
                              mutedColor: _mutedColor,
                              captionColor: _captionColor,
                              bgColor: _bgColor,
                              useGeez: useGeez,
                              isSelectedFn: _isSelected,
                              onVerseTap: _selectVerse,
                              verseKeyFn: _verseKey,
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
                                s: s,
                                isDark: _isDark,
                                surfaceColor: _surfaceColor,
                                textColor: _textColor,
                                onBookmark: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.comingSoon)),
                                  );
                                },
                                onHighlight: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.comingSoon)),
                                  );
                                },
                                onCopy: () async {
                                  final text = _selectedVerseText;
                                  if (text != null) {
                                    await Clipboard.setData(
                                        ClipboardData(text: text));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(s.verseCopy)),
                                      );
                                    }
                                  }
                                  _deselect();
                                },
                                onShare: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.comingSoon)),
                                  );
                                },
                                onMore: () {
                                  _deselect();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.comingSoon)),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // ── Chapter navigation bar ───────────────────────────────────────
            if (!_loading && _book != null)
              _ChapterNavBar(
                currentChapter: _currentChapter,
                totalChapters: _book!.chapters.length,
                isDark: _isDark,
                useGeez: useGeez,
                s: s,
                surfaceColor: _surfaceColor,
                textColor: _textColor,
                mutedColor: _mutedColor,
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
    required this.fontSize,
    required this.useGeez,
    required this.isAmharic,
    required this.bgColor,
    required this.textColor,
    required this.mutedColor,
    required this.onBack,
    required this.onToggleDark,
    required this.onFontSizeIncrease,
    required this.onFontSizeDecrease,
    required this.onFontCycle,
  });

  final BookIndexEntry entry;
  final int currentChapter;
  final bool isDark;
  final double fontSize;
  final bool useGeez;
  final bool isAmharic;
  final Color bgColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onBack;
  final VoidCallback onToggleDark;
  final VoidCallback onFontSizeIncrease;
  final VoidCallback onFontSizeDecrease;
  final VoidCallback onFontCycle;

  String get _chapterNum {
    final n = currentChapter + 1;
    return useGeez ? toGeez(n) : '$n';
  }

  @override
  Widget build(BuildContext context) {
    final bookName = isAmharic ? entry.bookShortNameAm : entry.bookShortNameEn;
    final iconColor = mutedColor;

    return Container(
      height: 52,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Back
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: iconColor),
            onPressed: onBack,
          ),
          // Book + chapter title
          Expanded(
            child: Text(
              '$bookName $_chapterNum',
              style: TextStyle(
                fontFamily: AppTypography.shiromeda,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Font size decrease
          IconButton(
            icon: Icon(Icons.text_decrease_rounded, size: 18, color: iconColor),
            onPressed: onFontSizeDecrease,
            tooltip: 'Smaller',
          ),
          // Font size increase
          IconButton(
            icon: Icon(Icons.text_increase_rounded, size: 18, color: iconColor),
            onPressed: onFontSizeIncrease,
            tooltip: 'Larger',
          ),
          // Font family cycle
          IconButton(
            icon: Icon(Icons.font_download_outlined, size: 18, color: iconColor),
            onPressed: onFontCycle,
            tooltip: 'Font',
          ),
          // Dark/light toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 18,
              color: iconColor,
            ),
            onPressed: onToggleDark,
          ),
        ],
      ),
    );
  }
}

// ── Chapter page ──────────────────────────────────────────────────────────────

class _ChapterPage extends StatelessWidget {
  const _ChapterPage({
    required this.chapter,
    required this.isDark,
    required this.fontSize,
    required this.fontFamily,
    required this.textColor,
    required this.mutedColor,
    required this.captionColor,
    required this.bgColor,
    required this.useGeez,
    required this.isSelectedFn,
    required this.onVerseTap,
    required this.verseKeyFn,
  });

  final Chapter chapter;
  final bool isDark;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
  final Color mutedColor;
  final Color captionColor;
  final Color bgColor;
  final bool useGeez;
  final bool Function(int chNum, int secIdx, int verseNum) isSelectedFn;
  final ValueChanged<String> onVerseTap;
  final String Function(int chNum, int secIdx, int verseNum) verseKeyFn;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: chapter.sections.length,
      itemBuilder: (ctx, secIdx) {
        final section = chapter.sections[secIdx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title (skip if empty)
            if (section.title.trim().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontFamily: AppTypography.abbaGarima,
                    fontSize: fontSize - 2,
                    color: isDark ? AppColors.accent : AppColors.accentDeep,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 8),
            // Verses
            ...section.verses.map((verse) {
              final key = verseKeyFn(
                  chapter.chapterNumber, secIdx, verse.verseNumber);
              final selected = isSelectedFn(
                  chapter.chapterNumber, secIdx, verse.verseNumber);
              final numStr =
                  useGeez ? toGeez(verse.verseNumber) : '${verse.verseNumber}';

              return GestureDetector(
                onTap: () => onVerseTap(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark
                            ? AppColors.accent.withValues(alpha: 0.18)
                            : AppColors.accent.withValues(alpha: 0.28))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verse number
                      SizedBox(
                        width: 28,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            numStr,
                            style: TextStyle(
                              fontFamily: AppTypography.nokiaPureheadline,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColors.accentDeep,
                            ),
                          ),
                        ),
                      ),
                      // Verse text
                      Expanded(
                        child: Text(
                          verse.text,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: fontSize,
                            height: 1.85,
                            color: textColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
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
          _ActionBtn(
            icon: Icons.bookmark_add_outlined,
            label: s.verseBookmark,
            textColor: textColor,
            onTap: onBookmark,
          ),
          _ActionBtn(
            icon: Icons.edit_outlined,
            label: s.verseHighlight,
            textColor: textColor,
            onTap: onHighlight,
          ),
          _ActionBtn(
            icon: Icons.copy_rounded,
            label: s.verseCopy,
            textColor: textColor,
            onTap: onCopy,
          ),
          _ActionBtn(
            icon: Icons.share_outlined,
            label: s.verseShare,
            textColor: textColor,
            onTap: onShare,
          ),
          _ActionBtn(
            icon: Icons.more_horiz_rounded,
            label: s.verseMore,
            textColor: textColor,
            onTap: onMore,
          ),
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
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  String _chLabel(int idx) {
    final n = idx + 1;
    return '${s.chapterAbbr}. ${useGeez ? toGeez(n) : n}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPrev = currentChapter > 0;
    final hasNext = currentChapter < totalChapters - 1;

    return Container(
      height: 52,
      color: surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Previous
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            label: hasPrev ? _chLabel(currentChapter - 1) : '',
            enabled: hasPrev,
            textColor: textColor,
            mutedColor: mutedColor,
            onTap: onPrev,
          ),
          // Current chapter indicator
          Expanded(
            child: Center(
              child: Text(
                _chLabel(currentChapter),
                style: TextStyle(
                  fontFamily: AppTypography.shiromeda,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
          // Next
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            label: hasNext ? _chLabel(currentChapter + 1) : '',
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

class _NavBtn extends StatelessWidget {
  const _NavBtn({
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
    final color = enabled ? textColor : mutedColor.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isNext) Icon(icon, color: color, size: 22),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.shiromeda,
                  fontSize: 12,
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
