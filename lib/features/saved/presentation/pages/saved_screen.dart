import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/annotations/annotation_models.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../annotations/providers/annotation_providers.dart';
import '../../../books/data/models/book_index_entry.dart';
import '../../../books/presentation/pages/reader_screen.dart';

// ── Loaded annotation item ────────────────────────────────────────────────────

class _Item {
  const _Item({
    required this.bookEntry,
    required this.chapter,
    required this.verseStart,
    required this.verseText,
    required this.createdAt,
    this.highlightColor,
    this.noteContent,
  });

  final BookIndexEntry bookEntry;
  final int chapter;
  final int verseStart;
  final String verseText;
  final DateTime createdAt;
  final Color? highlightColor;
  final String? noteContent;

  bool get isOT => bookEntry.isOldTestament;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  int _tab = 0;
  bool _loading = true;
  bool _initialized = false;

  List<_Item> _highlights = [];
  List<_Item> _bookmarks = [];
  List<_Item> _notes = [];

  Color? _colorFilter;
  String? _testamentFilter;
  String? _bookFilter;
  int? _chapterFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final db = ref.read(annotationDbProvider);
    final repo = BibleRepositoryProvider.of(context);

    final results = await Future.wait([
      db.getAllBookmarks(),
      db.getAllHighlights(),
      db.getAllNotes(),
    ]);

    final rawBookmarks = results[0] as List<Bookmark>;
    final rawHighlights = results[1] as List<Highlight>;
    final rawNotes = results[2] as List<Note>;

    final bookIds = {
      ...rawBookmarks.map((b) => b.bookId),
      ...rawHighlights.map((h) => h.bookId),
      ...rawNotes.map((n) => n.bookId),
    };

    if (bookIds.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final index = await repo.loadIndex();
    final entries = {
      for (final e in index.where((e) => bookIds.contains(e.bookNameEn)))
        e.bookNameEn: e
    };

    final entryList = entries.values.toList();
    final books = await Future.wait(entryList.map(repo.loadBook));

    // verse text lookup: bookId → chapter → verseNum → text
    final textMap = <String, Map<int, Map<int, String>>>{};
    for (var i = 0; i < entryList.length; i++) {
      final bookId = entryList[i].bookNameEn;
      textMap[bookId] = {};
      for (final ch in books[i].chapters) {
        textMap[bookId]![ch.chapterNumber] = {
          for (final sec in ch.sections)
            for (final v in sec.verses) v.verseNumber: v.text,
        };
      }
    }

    String getText(String bookId, int ch, int v) =>
        textMap[bookId]?[ch]?[v] ?? '';

    if (!mounted) return;
    setState(() {
      _highlights = rawHighlights
          .map((h) {
            final e = entries[h.bookId];
            return e == null
                ? null
                : _Item(
                    bookEntry: e,
                    chapter: h.chapter,
                    verseStart: h.verseStart,
                    verseText: getText(h.bookId, h.chapter, h.verseStart),
                    createdAt: h.createdAt,
                    highlightColor: h.color,
                  );
          })
          .whereType<_Item>()
          .toList();

      _bookmarks = rawBookmarks
          .map((b) {
            final e = entries[b.bookId];
            return e == null
                ? null
                : _Item(
                    bookEntry: e,
                    chapter: b.chapter,
                    verseStart: b.verseStart,
                    verseText: getText(b.bookId, b.chapter, b.verseStart),
                    createdAt: b.createdAt,
                  );
          })
          .whereType<_Item>()
          .toList();

      _notes = rawNotes
          .map((n) {
            final e = entries[n.bookId];
            return e == null
                ? null
                : _Item(
                    bookEntry: e,
                    chapter: n.chapter,
                    verseStart: n.verseStart,
                    verseText: getText(n.bookId, n.chapter, n.verseStart),
                    createdAt: n.createdAt,
                    noteContent: n.content,
                  );
          })
          .whereType<_Item>()
          .toList();

      _loading = false;
    });
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  List<_Item> get _rawForTab =>
      _tab == 0 ? _highlights : _tab == 1 ? _bookmarks : _notes;

  List<_Item> get _filtered {
    return _rawForTab.where((item) {
      if (_tab == 0 && _colorFilter != null) {
        if (item.highlightColor?.toARGB32() != _colorFilter!.toARGB32()) {
          return false;
        }
      }
      if (_testamentFilter == 'OT' && !item.isOT) return false;
      if (_testamentFilter == 'NT' && item.isOT) return false;
      if (_bookFilter != null && item.bookEntry.bookNameEn != _bookFilter) {
        return false;
      }
      if (_chapterFilter != null && item.chapter != _chapterFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Set<String> get _availableBookIds {
    return _rawForTab
        .where((item) {
          if (_testamentFilter == 'OT' && !item.isOT) return false;
          if (_testamentFilter == 'NT' && item.isOT) return false;
          if (_tab == 0 &&
              _colorFilter != null &&
              item.highlightColor?.toARGB32() != _colorFilter!.toARGB32()) {
            return false;
          }
          return true;
        })
        .map((item) => item.bookEntry.bookNameEn)
        .toSet();
  }

  Set<int> get _availableChapters {
    if (_bookFilter == null) return {};
    return _rawForTab
        .where((item) => item.bookEntry.bookNameEn == _bookFilter)
        .map((item) => item.chapter)
        .toSet();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _openVerse(_Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          entry: item.bookEntry,
          initialChapter: (item.chapter - 1).clamp(0, 999),
          initialVerse: item.verseStart,
        ),
      ),
    ).then((_) => _load());
  }

  void _showBookPicker() {
    final books = _rawForTab
        .where((item) {
          if (_testamentFilter == 'OT' && !item.isOT) return false;
          if (_testamentFilter == 'NT' && item.isOT) return false;
          return true;
        })
        .map((item) => item.bookEntry)
        .toSet()
        .toList()
      ..sort((a, b) => a.bookNumber.compareTo(b.bookNumber));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickerSheet(
        title: 'መጽሐፍ ምረጥ',
        items: [
          const _PickerItem(id: null, label: 'ሁሉም መጻሕፍ'),
          ...books.map(
            (e) => _PickerItem(id: e.bookNameEn, label: e.bookNameAm),
          ),
        ],
        selectedId: _bookFilter,
        onSelect: (id) {
          setState(() {
            _bookFilter = id;
            _chapterFilter = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showChapterPicker() {
    if (_bookFilter == null) return;
    final chapters = _availableChapters.toList()..sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickerSheet(
        title: 'ምዕራፍ ምረጥ',
        items: [
          const _PickerItem(id: null, label: 'ሁሉም ምዕራፍ'),
          ...chapters.map(
            (ch) => _PickerItem(id: ch, label: 'ምዕ. $ch'),
          ),
        ],
        selectedId: _chapterFilter,
        onSelect: (id) {
          setState(() => _chapterFilter = id as int?);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final availableBookIds = _availableBookIds;
    final availableChapters = _availableChapters;

    final currentBookEntry = _bookFilter == null
        ? null
        : _rawForTab
            .where((i) => i.bookEntry.bookNameEn == _bookFilter)
            .firstOrNull
            ?.bookEntry;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ያቀቡት',
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ስብስቤ',
                  style: AppTypography.amharicHeading.copyWith(
                    color: AppColors.textOnParchment,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Custom tab bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _TabLabel(
                  label: 'ምልክቶ',
                  count: _highlights.length,
                  active: _tab == 0,
                  onTap: () => setState(() {
                    _tab = 0;
                    _colorFilter = null;
                    _bookFilter = null;
                    _chapterFilter = null;
                    _testamentFilter = null;
                  }),
                ),
                const SizedBox(width: 24),
                _TabLabel(
                  label: 'ክታቦ',
                  count: _bookmarks.length,
                  active: _tab == 1,
                  onTap: () => setState(() {
                    _tab = 1;
                    _colorFilter = null;
                    _bookFilter = null;
                    _chapterFilter = null;
                    _testamentFilter = null;
                  }),
                ),
                const SizedBox(width: 24),
                _TabLabel(
                  label: 'ማስታወሻ',
                  count: _notes.length,
                  active: _tab == 2,
                  onTap: () => setState(() {
                    _tab = 2;
                    _colorFilter = null;
                    _bookFilter = null;
                    _chapterFilter = null;
                    _testamentFilter = null;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.borderSubtle, height: 1),

          // ── Filters ───────────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                // Color circles — highlights tab only
                if (_tab == 0) ...[
                  _ColorDot(
                    color: null,
                    selected: _colorFilter == null,
                    onTap: () => setState(() => _colorFilter = null),
                  ),
                  for (final c in highlightPalette)
                    _ColorDot(
                      color: c,
                      selected: _colorFilter?.toARGB32() == c.toARGB32(),
                      onTap: () => setState(() =>
                          _colorFilter = _colorFilter?.toARGB32() == c.toARGB32()
                              ? null
                              : c),
                    ),
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.borderSubtle,
                  ),
                ],
                // Testament chips
                _Chip(
                  label: 'ሁሉም',
                  active: _testamentFilter == null,
                  onTap: () => setState(
                      () => _testamentFilter = null),
                ),
                const SizedBox(width: 6),
                _Chip(
                  label: 'ብሉይ',
                  active: _testamentFilter == 'OT',
                  onTap: () => setState(() {
                    _testamentFilter =
                        _testamentFilter == 'OT' ? null : 'OT';
                    _bookFilter = null;
                    _chapterFilter = null;
                  }),
                ),
                const SizedBox(width: 6),
                _Chip(
                  label: 'አዲስ',
                  active: _testamentFilter == 'NT',
                  onTap: () => setState(() {
                    _testamentFilter =
                        _testamentFilter == 'NT' ? null : 'NT';
                    _bookFilter = null;
                    _chapterFilter = null;
                  }),
                ),
                // Book chip (only if there are multiple books)
                if (availableBookIds.length > 1) ...[
                  const SizedBox(width: 6),
                  _Chip(
                    label: currentBookEntry?.bookNameAm ?? 'ሁሉም',
                    active: _bookFilter != null,
                    trailing: Icons.expand_more_rounded,
                    onTap: _showBookPicker,
                  ),
                ],
                // Chapter chip (only if a book is selected and has multiple chapters)
                if (_bookFilter != null && availableChapters.length > 1) ...[
                  const SizedBox(width: 6),
                  _Chip(
                    label: _chapterFilter != null
                        ? 'ምዕ. $_chapterFilter'
                        : 'ሁሉም ምዕ.',
                    active: _chapterFilter != null,
                    trailing: Icons.expand_more_rounded,
                    onTap: _showChapterPicker,
                  ),
                ],
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : items.isEmpty
                    ? _EmptyState(tab: _tab)
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _AnnotationCard(
                            item: items[i],
                            tab: _tab,
                            onTap: () => _openVerse(items[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Tab label ─────────────────────────────────────────────────────────────────

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.amharicLabel.copyWith(
                  fontSize: 14,
                  color: active
                      ? AppColors.textOnParchment
                      : AppColors.textMuted,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 5),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.5,
            width: active ? 40 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Color dot filter ──────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? AppColors.surfaceDim,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: color == null
            ? const Icon(Icons.done_all_rounded,
                size: 16, color: AppColors.textMuted)
            : selected
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.black54)
                : null,
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.fromLTRB(12, 6, trailing != null ? 6 : 12, 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.amharicLabel.copyWith(
                fontSize: 12,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 2),
              Icon(
                trailing,
                size: 16,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Picker sheet ──────────────────────────────────────────────────────────────

class _PickerItem {
  const _PickerItem({required this.id, required this.label});
  final dynamic id;
  final String label;
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final String title;
  final List<_PickerItem> items;
  final dynamic selectedId;
  final ValueChanged<dynamic> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              title,
              style: AppTypography.amharicLabel.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnParchment,
              ),
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AppColors.borderSubtle, height: 1, indent: 20),
              itemBuilder: (_, i) {
                final item = items[i];
                final isSelected = item.id == selectedId;
                return InkWell(
                  onTap: () => onSelect(item.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: AppTypography.amharicLabel.copyWith(
                              fontSize: 14,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textOnParchment,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Annotation card ───────────────────────────────────────────────────────────

class _AnnotationCard extends StatelessWidget {
  const _AnnotationCard({
    required this.item,
    required this.tab,
    required this.onTap,
  });

  final _Item item;
  final int tab;
  final VoidCallback onTap;

  Color get _accentColor {
    if (tab == 0 && item.highlightColor != null) return item.highlightColor!;
    if (tab == 1) return AppColors.primary;
    return AppColors.accentDeep;
  }

  String _daysAgo() {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inDays == 0) return 'ዛሬ';
    if (diff.inDays == 1) return 'ትናንት';
    return '${diff.inDays} ቀን';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final chRef = '${item.bookEntry.bookShortNameAm} ${item.chapter}:${item.verseStart}';
    final bodyText = tab == 2
        ? (item.noteContent ?? item.verseText)
        : item.verseText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: accent, width: 4),
            top: BorderSide(color: AppColors.borderSubtle),
            right: BorderSide(color: AppColors.borderSubtle),
            bottom: BorderSide(color: AppColors.borderSubtle),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Reference row ──────────────────────────────────────────
              Row(
                children: [
                  _TypeBadge(tab: tab, accent: accent),
                  const SizedBox(width: 8),
                  Text(
                    chRef,
                    style: TextStyle(
                      fontFamily: AppTypography.shiromeda,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _daysAgo(),
                    style: AppTypography.amharicCaption.copyWith(
                      fontSize: 11,
                      color: AppColors.textCaption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Body text ──────────────────────────────────────────────
              if (tab == 2 && item.noteContent != null) ...[
                Text(
                  item.noteContent!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.amharicBody.copyWith(
                    fontSize: 14,
                    color: AppColors.textOnParchment,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bodyText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicCaption.copyWith(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ] else
                Text(
                  bodyText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.amharicBody.copyWith(
                    fontSize: 14,
                    color: AppColors.textOnParchment,
                    height: 1.65,
                  ),
                ),
              const SizedBox(height: 10),
              // ── Footer row ─────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 12, color: AppColors.textCaption),
                  const SizedBox(width: 4),
                  Text(
                    item.bookEntry.bookNameAm,
                    style: AppTypography.amharicCaption.copyWith(
                      fontSize: 11,
                      color: AppColors.textCaption,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.open_in_new_rounded,
                      size: 14, color: AppColors.textCaption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.tab, required this.accent});

  final int tab;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = tab == 0
        ? Icons.format_color_fill_rounded
        : tab == 1
            ? Icons.bookmark_rounded
            : Icons.sticky_note_2_rounded;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, size: 13, color: accent),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab});
  final int tab;

  @override
  Widget build(BuildContext context) {
    final (icon, label, hint) = switch (tab) {
      0 => (Icons.format_color_fill_rounded, 'ምንም ምልክቶ የለም',
          'ምንባብ ሲያነቡ ቁጥር ጎልቶ ይሰምጡ'),
      1 => (Icons.bookmark_border_rounded, 'ምንም ክታቦ የለም',
          'ምንባብ ሲያነቡ ቁጥር ያቆዩ'),
      _ => (Icons.sticky_note_2_outlined, 'ምንም ማስታወሻ የለም',
          'ምንባብ ሲያነቡ ማስታወሻ ይጻፉ'),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.borderSubtle),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTypography.amharicLabel.copyWith(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: AppTypography.amharicCaption.copyWith(
                color: AppColors.textCaption,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
