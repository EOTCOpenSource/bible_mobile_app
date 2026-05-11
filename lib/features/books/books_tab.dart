import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../core/l10n/l10n.dart';
import '../../core/providers/repository_provider.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/book_index_entry.dart';
import 'reader_screen.dart';

// ── Category filters ──────────────────────────────────────────────────────────

enum _OTFilter { all, law, history, wisdom, prophets, other }

enum _NTFilter { all, gospels, acts, pauline, general, revelation, other }

// ── Tab ───────────────────────────────────────────────────────────────────────

class BooksTab extends StatefulWidget {
  const BooksTab({super.key});

  @override
  State<BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<BooksTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<BookIndexEntry> _books = [];
  bool _loading = true;
  bool _initialized = false;
  _OTFilter _otFilter = _OTFilter.all;
  _NTFilter _ntFilter = _NTFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadBooks();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final books = await BibleRepositoryProvider.of(context).loadIndex();
    if (mounted) setState(() { _books = books; _loading = false; });
  }

  List<BookIndexEntry> get _otBooks =>
      _books.where((b) => b.isOldTestament).toList();

  List<BookIndexEntry> get _ntBooks =>
      _books.where((b) => !b.isOldTestament).toList();

  // OT: 1–54  (Law 1–5, History 6–26, Wisdom 27–34, Prophets 35–54)
  List<BookIndexEntry> get _filteredOT {
    final ot = _otBooks;
    return switch (_otFilter) {
      _OTFilter.all      => ot,
      _OTFilter.law      => ot.where((b) => b.bookNumber <= 5).toList(),
      _OTFilter.history  => ot.where((b) => b.bookNumber >= 6  && b.bookNumber <= 26).toList(),
      _OTFilter.wisdom   => ot.where((b) => b.bookNumber >= 27 && b.bookNumber <= 34).toList(),
      _OTFilter.prophets => ot.where((b) => b.bookNumber >= 35 && b.bookNumber <= 54).toList(),
      _OTFilter.other    => ot.where((b) => b.bookNumber > 54).toList(),
    };
  }

  // NT: 55–81  (Gospels 55–58, Acts 59, Pauline 60–73, General 74–80, Revelation 81)
  List<BookIndexEntry> get _filteredNT {
    final nt = _ntBooks;
    return switch (_ntFilter) {
      _NTFilter.all        => nt,
      _NTFilter.gospels    => nt.where((b) => b.bookNumber >= 55 && b.bookNumber <= 58).toList(),
      _NTFilter.acts       => nt.where((b) => b.bookNumber == 59).toList(),
      _NTFilter.pauline    => nt.where((b) => b.bookNumber >= 60 && b.bookNumber <= 73).toList(),
      _NTFilter.general    => nt.where((b) => b.bookNumber >= 74 && b.bookNumber <= 80).toList(),
      _NTFilter.revelation => nt.where((b) => b.bookNumber == 81).toList(),
      _NTFilter.other      => nt.where((b) =>
          b.bookNumber < 55 || b.bookNumber > 81).toList(),
    };
  }

  void _openBook(BookIndexEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReaderScreen(entry: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BooksHeader(s: s, total: _books.isEmpty ? 81 : _books.length, useGeez: useGeez),
          const SizedBox(height: 10),
          _BooksTabBar(controller: _tabController, s: s),
          const SizedBox(height: 4),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BookListTab(
                    filterLabels: [
                      s.booksFilterAll,
                      s.booksFilterLaw,
                      s.booksFilterHistory,
                      s.booksFilterWisdom,
                      s.booksFilterProphets,
                      s.booksFilterOther,
                    ],
                    selectedFilter: _otFilter.index,
                    onFilterChanged: (i) =>
                        setState(() => _otFilter = _OTFilter.values[i]),
                    books: _filteredOT,
                    s: s,
                    useGeez: useGeez,
                    onBookTap: _openBook,
                  ),
                  _BookListTab(
                    filterLabels: [
                      s.booksFilterAll,
                      s.booksFilterGospels,
                      s.booksFilterActs,
                      s.booksFilterPauline,
                      s.booksFilterGeneral,
                      s.booksFilterRevelation,
                      s.booksFilterOther,
                    ],
                    selectedFilter: _ntFilter.index,
                    onFilterChanged: (i) =>
                        setState(() => _ntFilter = _NTFilter.values[i]),
                    books: _filteredNT,
                    s: s,
                    useGeez: useGeez,
                    onBookTap: _openBook,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _BooksHeader extends StatelessWidget {
  const _BooksHeader({required this.s, required this.total, required this.useGeez});

  final AppStrings s;
  final int total;
  final bool useGeez;

  @override
  Widget build(BuildContext context) {
    final numStr = useGeez ? toGeez(total) : '$total';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.booksTitle,
                  style: AppTypography.amharicHeading.copyWith(
                    color: AppColors.textOnParchment,
                  ),
                ),
                Text(
                  s.booksSubtitle(numStr),
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _BooksTabBar extends StatelessWidget {
  const _BooksTabBar({required this.controller, required this.s});

  final TabController controller;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTypography.amharicLabel.copyWith(fontSize: 13),
          unselectedLabelStyle: AppTypography.amharicLabel.copyWith(fontSize: 13),
          tabs: [
            Tab(text: s.booksOldTestament),
            Tab(text: s.booksNewTestament),
          ],
        ),
      ),
    );
  }
}

// ── Book list tab ─────────────────────────────────────────────────────────────

class _BookListTab extends StatelessWidget {
  const _BookListTab({
    required this.filterLabels,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.books,
    required this.s,
    required this.useGeez,
    required this.onBookTap,
  });

  final List<String> filterLabels;
  final int selectedFilter;
  final ValueChanged<int> onFilterChanged;
  final List<BookIndexEntry> books;
  final AppStrings s;
  final bool useGeez;
  final ValueChanged<BookIndexEntry> onBookTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              for (int i = 0; i < filterLabels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: filterLabels[i],
                    selected: i == selectedFilter,
                    onTap: () => onFilterChanged(i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: books.isEmpty
              ? Center(
                  child: Text(
                    s.booksFilterAll,
                    style: AppTypography.amharicCaption.copyWith(
                      color: AppColors.textCaption,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: books.length,
                  separatorBuilder: (context, i) => const Divider(
                    color: AppColors.borderSubtle,
                    height: 1,
                    indent: 58,
                  ),
                  itemBuilder: (ctx, i) => _BookRow(
                    book: books[i],
                    s: s,
                    useGeez: useGeez,
                    onTap: () => onBookTap(books[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.amharicLabel.copyWith(
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Book row ──────────────────────────────────────────────────────────────────

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.s,
    required this.useGeez,
    required this.onTap,
  });

  final BookIndexEntry book;
  final AppStrings s;
  final bool useGeez;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAmharic = s is AmStrings;
    final badgeColor =
        book.isOldTestament ? AppColors.primary : AppColors.newTestament;
    final chCount = book.chapterCount;
    final chStr =
        chCount == null ? null : (useGeez ? toGeez(chCount) : '$chCount');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                isAmharic ? book.bookShortNameAm : book.bookShortNameEn,
                style: TextStyle(
                  fontFamily: AppTypography.shiromeda,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 14),
            // Names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAmharic ? book.bookNameAm : book.bookNameEn,
                    style: AppTypography.amharicLabel.copyWith(
                      color: AppColors.textOnParchment,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAmharic ? book.bookNameEn : book.bookNameAm,
                    style: AppTypography.englishLabel.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Chapter count
            if (chStr != null)
              Text(
                '$chStr ${s.booksChapterSuffix}',
                style: AppTypography.amharicCaption.copyWith(
                  color: AppColors.textCaption,
                  fontSize: 11,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textCaption,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
