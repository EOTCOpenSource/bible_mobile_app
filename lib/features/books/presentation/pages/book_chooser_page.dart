import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/book_index_entry.dart';
import '../../data/repositories/bible_repository.dart'
    show BibleRepository, SearchScope;
import '../widgets/edition_switcher.dart';
import '../widgets/reader/reference_jump_sheet.dart';

// ── Category filters ──────────────────────────────────────────────────────────

enum _OTFilter { all, law, history, wisdom, prophets, other }

enum _NTFilter { all, gospels, acts, pauline, general, revelation, other }

// ── Page ──────────────────────────────────────────────────────────────────────

class BookChooserPage extends StatefulWidget {
  const BookChooserPage({
    super.key,
    required this.onBookTap,
    this.onSearchTap,
  });

  final void Function(BookIndexEntry entry) onBookTap;
  final void Function(SearchScope scope)? onSearchTap;

  @override
  State<BookChooserPage> createState() => _BookChooserPageState();
}

class _BookChooserPageState extends State<BookChooserPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  BibleRepository? _repo;
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
      _repo = BibleRepositoryProvider.of(context);
      // The book list is edition-specific. Switching editions happens on
      // another tab, so without this the chooser keeps showing the previous
      // edition's books until the app restarts.
      _repo!.addListener(_loadBooks);
      _loadBooks();
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_loadBooks);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final repo = _repo;
    if (repo == null) return;
    await repo.loadIntroductions();
    final books = await repo.loadIndex();
    if (mounted) setState(() { _books = books; _loading = false; });
  }

  List<BookIndexEntry> get _otBooks =>
      _books.where((b) => b.isOldTestament).toList();

  List<BookIndexEntry> get _ntBooks =>
      _books.where((b) => !b.isOldTestament).toList();

  /// Filters key on the canon section, not on a book-number range.
  ///
  /// Display order is edition-specific — `am-2000` runs to 94 positions with
  /// the deuterocanon at 40–58, while the protestant editions stop at 66 — so
  /// the numeric ranges these filters used to carry were correct for exactly
  /// one edition and silently mis-bucketed every other.
  List<BookIndexEntry> _bySection(
    List<BookIndexEntry> books,
    Set<String> sections,
  ) =>
      books.where((b) => b.section != null && sections.contains(b.section!))
          .toList();

  /// Books the named sections do not claim: the Ethiopic appendix and the
  /// unsectioned deuterocanon.
  List<BookIndexEntry> _unsectioned(List<BookIndexEntry> books) =>
      books.where((b) => b.section == null).toList();

  List<BookIndexEntry> get _filteredOT {
    final ot = _otBooks;
    return switch (_otFilter) {
      _OTFilter.all      => ot,
      _OTFilter.law      => _bySection(ot, const {'Pentateuch'}),
      _OTFilter.history  => _bySection(ot, const {'Historical'}),
      _OTFilter.wisdom   => _bySection(ot, const {'PoetryWisdom'}),
      _OTFilter.prophets => _bySection(ot, const {'MajorProphet', 'MinorProphet'}),
      _OTFilter.other    => [
          ..._bySection(ot, const {'Deuterocanonical'}),
          ..._unsectioned(ot),
        ],
    };
  }

  List<BookIndexEntry> get _filteredNT {
    final nt = _ntBooks;
    return switch (_ntFilter) {
      _NTFilter.all        => nt,
      _NTFilter.gospels    => _bySection(nt, const {'Gospel'}),
      _NTFilter.acts       => _bySection(nt, const {'Acts'}),
      _NTFilter.pauline    => _bySection(nt, const {'PaulineEpistle'}),
      _NTFilter.general    => _bySection(nt, const {'GeneralEpistle'}),
      _NTFilter.revelation => _bySection(nt, const {'Revelation'}),
      _NTFilter.other      => _unsectioned(nt),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BooksHeader(
            s: s,
            total: _books.isEmpty ? 81 : _books.length,
            useGeez: useGeez,
            onSearchTap: widget.onSearchTap == null
                ? null
                : () {
                    final scope = _tabController.index == 0
                        ? SearchScope.oldTestament
                        : SearchScope.newTestament;
                    widget.onSearchTap!(scope);
                  },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                 showModalBottomSheet(
                   context: context,
                   isScrollControlled: true,
                   backgroundColor: Colors.transparent,
                   builder: (_) => ReferenceJumpSheet(
                     useGeez: useGeez,
                     isAmharic: L10n.of(context) is AmStrings,
                     s: s,
                   ),
                 );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: context.colors.textCaption),
                    const SizedBox(width: 8),
                    Text(
                      L10n.of(context) is AmStrings ? 'ወደ ጥቅስ ሂድ...' : 'Go to verse...',
                      style: AppTypography.amharicBody.copyWith(color: context.colors.textCaption),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _BooksTabBar(controller: _tabController, s: s),
          const SizedBox(height: 4),
          if (_loading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: context.colors.primary,
                ),
              ),
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
                    onBookTap: widget.onBookTap,
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
                    onBookTap: widget.onBookTap,
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
  const _BooksHeader({
    required this.s,
    required this.total,
    required this.useGeez,
    this.onSearchTap,
  });

  final AppStrings s;
  final int total;
  final bool useGeez;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
                    color: c.textOnParchment,
                  ),
                ),
                Text(
                  s.booksSubtitle(numStr),
                  style: AppTypography.amharicCaption.copyWith(
                    color: c.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // The book list is edition-specific — offer the switch here rather
          // than making the reader walk out to settings to change translation.
          const EditionChip(),
          IconButton(
            icon: Icon(Icons.search_rounded, color: c.textMuted),
            onPressed: onSearchTap,
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: c.surfaceDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: c.textMuted,
          labelStyle: AppTypography.amharicLabel.copyWith(fontSize: 13),
          unselectedLabelStyle:
              AppTypography.amharicLabel.copyWith(fontSize: 13),
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
                      color: context.colors.textCaption,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: books.length,
                  separatorBuilder: (context, i) => Divider(
                    color: context.colors.borderSubtle,
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
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surfaceDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.primary : c.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.amharicLabel.copyWith(
            fontSize: 13,
            color: selected ? Colors.white : c.textMuted,
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
    final c = context.colors;
    final isAmharic = s is AmStrings;
    final badgeColor =
        book.isOldTestament ? c.primary : c.newTestament;
    final chCount = book.chapterCount;
    final chStr =
        chCount == null ? null : (useGeez ? toGeez(chCount) : '$chCount');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAmharic ? book.bookNameAm : book.bookNameEn,
                    style: AppTypography.amharicLabel.copyWith(
                      color: c.textOnParchment,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Builder(
                    builder: (context) {
                      final repo = BibleRepositoryProvider.of(context);
                      final intro = repo.getIntroduction(
                        book.id,
                        locale: isAmharic ? 'am' : 'en',
                      );
                      final otherName = isAmharic ? book.bookNameEn : book.bookNameAm;
                      final subParts = <String>[];
                      if (otherName.isNotEmpty) subParts.add(otherName);
                      if (intro != null) {
                        if (intro.author.isNotEmpty) subParts.add(intro.author);
                        if (intro.period.isNotEmpty) subParts.add(intro.period);
                      }
                      return Text(
                        subParts.join('  •  '),
                        style: AppTypography.englishLabel.copyWith(
                          color: c.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
              ),
            ),
            if (chStr != null)
              Text(
                '$chStr ${s.booksChapterSuffix}',
                style: AppTypography.amharicCaption.copyWith(
                  color: c.textCaption,
                  fontSize: 11,
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: c.textCaption,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
