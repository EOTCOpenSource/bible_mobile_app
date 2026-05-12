import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/data/models/book_index_entry.dart';
import '../../../books/data/repositories/bible_repository.dart';
import '../../../books/presentation/pages/reader_screen.dart';

// ── Highlight helper ──────────────────────────────────────────────────────────

List<TextSpan> _highlightSpans(
  String text,
  List<String> terms,
  TextStyle base,
  TextStyle hl,
) {
  final matches = <(int, int)>[];
  for (final t in terms) {
    if (t.isEmpty) continue;
    var pos = 0;
    while (pos < text.length) {
      final idx = text.indexOf(t, pos);
      if (idx < 0) break;
      matches.add((idx, idx + t.length));
      pos = idx + t.length;
    }
  }
  if (matches.isEmpty) return [TextSpan(text: text, style: base)];

  matches.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(int, int)>[];
  for (final m in matches) {
    if (merged.isEmpty || m.$1 >= merged.last.$2) {
      merged.add(m);
    } else {
      final prev = merged.removeLast();
      merged.add((prev.$1, m.$2 > prev.$2 ? m.$2 : prev.$2));
    }
  }

  final spans = <TextSpan>[];
  var pos = 0;
  for (final (start, end) in merged) {
    if (start > pos) spans.add(TextSpan(text: text.substring(pos, start), style: base));
    spans.add(TextSpan(text: text.substring(start, end), style: hl));
    pos = end;
  }
  if (pos < text.length) spans.add(TextSpan(text: text.substring(pos), style: base));
  return spans;
}

// ── Main tab ──────────────────────────────────────────────────────────────────

enum _SearchState { idle, loading, results, empty }

class SearchTab extends StatefulWidget {
  const SearchTab({super.key, this.initialBook, this.initialScope});
  final BookIndexEntry? initialBook;
  final SearchScope? initialScope;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();
  Timer? _debounce;
  int _version = 0;

  _SearchState _state   = _SearchState.idle;
  List<SearchHit> _hits = [];
  String _activeQuery   = '';

  SearchMode  _mode  = SearchMode.smart;
  SearchScope _scope = SearchScope.all;
  late BookIndexEntry? _book;

  @override
  void initState() {
    super.initState();
    _book  = widget.initialBook;
    _scope = widget.initialScope ?? SearchScope.all;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  SearchFilter get _filter => SearchFilter(mode: _mode, scope: _scope, book: _book);

  // ── Input handling ────────────────────────────────────────────────────────

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _state = _SearchState.idle; _hits = []; });
      return;
    }
    setState(() => _state = _SearchState.loading);
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(value.trim()));
  }

  void _submit() {
    _debounce?.cancel();
    final q = _controller.text.trim();
    if (q.length < 2) return;
    setState(() => _state = _SearchState.loading);
    _run(q);
  }

  Future<void> _run(String q) async {
    final v    = ++_version;
    final repo = BibleRepositoryProvider.of(context);
    final hits = await repo.searchVerses(q, filter: _filter);
    if (!mounted || _version != v) return;
    setState(() {
      _activeQuery = q;
      _hits  = hits;
      _state = hits.isEmpty ? _SearchState.empty : _SearchState.results;
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() { _state = _SearchState.idle; _hits = []; });
  }

  // ── Filter helpers ────────────────────────────────────────────────────────

  void _applyMode(SearchMode m) {
    setState(() => _mode = m);
    if (_controller.text.trim().length >= 2) _submit();
  }

  void _applyScope(SearchScope s, {BookIndexEntry? book}) {
    setState(() { _scope = s; _book = book; });
    if (_controller.text.trim().length >= 2) _submit();
  }

  String _scopeLabel(AppStrings s) {
    if (_book != null) {
      return _book!.bookShortNameAm.isNotEmpty
          ? _book!.bookShortNameAm
          : _book!.bookNameAm;
    }
    return switch (_scope) {
      SearchScope.all          => s.searchInAll,
      SearchScope.oldTestament => s.booksOldTestament,
      SearchScope.newTestament => s.booksNewTestament,
    };
  }

  bool get _scopeActive => _scope != SearchScope.all || _book != null;

  Future<void> _showScopeSheet(BuildContext ctx, AppStrings s) async {
    await showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _ScopeSheet(
        currentScope: _scope,
        currentBook:  _book,
        s:            s,
        repo:         BibleRepositoryProvider.of(ctx),
        onAll:  () { Navigator.pop(sheetCtx); _applyScope(SearchScope.all); },
        onOT:   () { Navigator.pop(sheetCtx); _applyScope(SearchScope.oldTestament); },
        onNT:   () { Navigator.pop(sheetCtx); _applyScope(SearchScope.newTestament); },
        onBook: (b) { Navigator.pop(sheetCtx); _applyScope(SearchScope.all, book: b); },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s       = L10n.of(context);
    final isAm    = s is AmStrings;
    final useGeez = Settings.of(context).useGeezNumbers;

    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchInputRow(
              controller: _controller,
              focusNode:  _focusNode,
              hint:       s.searchHint,
              runLabel:   s.searchRunBtn,
              onChanged:  _onChanged,
              onSubmit:   _submit,
              onClear:    _clear,
            ),
            _FilterRow(
              mode:        _mode,
              scopeLabel:  _scopeLabel(s),
              scopeActive: _scopeActive,
              s:           s,
              onMode:      _applyMode,
              onScopeTap:  () => _showScopeSheet(context, s),
            ),
            Divider(color: c.borderSubtle, height: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (_state) {
                  _SearchState.idle    => _IdleView(key: const ValueKey('i'), s: s),
                  _SearchState.loading => const _LoadingView(key: ValueKey('l')),
                  _SearchState.empty   => _EmptyView(key: const ValueKey('e'), s: s),
                  _SearchState.results => _ResultsList(
                      key:     const ValueKey('r'),
                      hits:    _hits,
                      query:   _activeQuery,
                      mode:    _mode,
                      s:       s,
                      isAm:    isAm,
                      useGeez: useGeez,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search input row ──────────────────────────────────────────────────────────

class _SearchInputRow extends StatelessWidget {
  const _SearchInputRow({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.runLabel,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String runLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: c.surfaceDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.borderSubtle),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search_rounded, size: 18, color: c.textCaption),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller:      controller,
                      focusNode:       focusNode,
                      onChanged:       onChanged,
                      onSubmitted:     (_) => onSubmit(),
                      textInputAction: TextInputAction.search,
                      style: AppTypography.amharicBody.copyWith(
                        fontSize: 15,
                        color: c.textOnParchment,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: AppTypography.amharicBody.copyWith(
                          fontSize: 15,
                          color: c.textCaption,
                          height: 1.2,
                        ),
                        border:        InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense:        true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (_, v, _) => v.text.isNotEmpty
                        ? GestureDetector(
                            onTap: onClear,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: c.textMuted),
                            ),
                          )
                        : const SizedBox(width: 8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                runLabel,
                style: AppTypography.amharicLabel.copyWith(
                  color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip row ───────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.mode,
    required this.scopeLabel,
    required this.scopeActive,
    required this.s,
    required this.onMode,
    required this.onScopeTap,
  });

  final SearchMode mode;
  final String scopeLabel;
  final bool scopeActive;
  final AppStrings s;
  final ValueChanged<SearchMode> onMode;
  final VoidCallback onScopeTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _Chip(
            label:  s.searchSmartMode,
            active: mode == SearchMode.smart,
            onTap:  () => onMode(SearchMode.smart),
          ),
          const SizedBox(width: 6),
          _Chip(
            label:  s.searchAllWords,
            active: mode == SearchMode.allWords,
            onTap:  () => onMode(SearchMode.allWords),
          ),
          const SizedBox(width: 6),
          _Chip(
            label:      scopeLabel,
            active:     scopeActive,
            trailingIcon: Icons.arrow_drop_down_rounded,
            onTap:      onScopeTap,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    this.trailingIcon,
    this.onTap,
  });

  final String label;
  final bool active;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg     = active ? c.primary : c.surface;
    final fg     = active ? Colors.white : c.textBody;
    final border = active ? c.primary : c.borderSubtle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active && trailingIcon == null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.circle, size: 6, color: Colors.white),
              ),
            Text(
              label,
              style: AppTypography.amharicCaption.copyWith(
                fontSize: 12,
                color: fg,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 2),
              Icon(trailingIcon, size: 16, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Scope bottom sheet ────────────────────────────────────────────────────────

class _ScopeSheet extends StatefulWidget {
  const _ScopeSheet({
    required this.currentScope,
    required this.currentBook,
    required this.s,
    required this.repo,
    required this.onAll,
    required this.onOT,
    required this.onNT,
    required this.onBook,
  });

  final SearchScope currentScope;
  final BookIndexEntry? currentBook;
  final AppStrings s;
  final BibleRepository repo;
  final VoidCallback onAll;
  final VoidCallback onOT;
  final VoidCallback onNT;
  final ValueChanged<BookIndexEntry> onBook;

  @override
  State<_ScopeSheet> createState() => _ScopeSheetState();
}

class _ScopeSheetState extends State<_ScopeSheet> {
  late Future<List<BookIndexEntry>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = widget.repo.loadIndex();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isAm = s is AmStrings;
    final c = context.colors;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.68,
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: c.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              s.searchScopeTitle,
              style: AppTypography.amharicSubheading.copyWith(
                fontSize: 16, color: c.textOnParchment),
            ),
          ),
          const SizedBox(height: 12),
          // Scope options
          _ScopeOption(
            label:    s.searchInAll,
            selected: widget.currentBook == null && widget.currentScope == SearchScope.all,
            onTap:    widget.onAll,
          ),
          _ScopeOption(
            label:    s.booksOldTestament,
            selected: widget.currentBook == null && widget.currentScope == SearchScope.oldTestament,
            onTap:    widget.onOT,
          ),
          _ScopeOption(
            label:    s.booksNewTestament,
            selected: widget.currentBook == null && widget.currentScope == SearchScope.newTestament,
            onTap:    widget.onNT,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: Divider(color: c.borderSubtle)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    s.searchOrPickBook,
                    style: AppTypography.amharicCaption.copyWith(
                      fontSize: 11, color: c.textCaption),
                  ),
                ),
                Expanded(child: Divider(color: c.borderSubtle)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Book list
          Expanded(
            child: FutureBuilder<List<BookIndexEntry>>(
              future: _booksFuture,
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                        color: context.colors.primary, strokeWidth: 2));
                }
                final books = snap.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: books.length,
                  itemBuilder: (_, i) {
                    final b = books[i];
                    final name = isAm ? b.bookNameAm : b.bookNameEn;
                    final selected = widget.currentBook?.bookNumber == b.bookNumber;
                    return _ScopeOption(
                      label:      name,
                      sublabel:   isAm ? b.bookNameEn : b.bookNameAm,
                      selected:   selected,
                      onTap:      () => widget.onBook(b),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.amharicBody.copyWith(
                      fontSize: 14,
                      color: selected ? c.primary : c.textBody,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (sublabel != null && sublabel!.isNotEmpty)
                    Text(
                      sublabel!,
                      style: AppTypography.amharicCaption.copyWith(
                        fontSize: 11, color: c.textCaption),
                    ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 18, color: c.primary),
          ],
        ),
      ),
    );
  }
}

// ── State views ───────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({super.key, required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 64, color: c.borderSubtle),
          const SizedBox(height: 16),
          Text(
            s.searchPrompt,
            style: AppTypography.amharicBody.copyWith(
              fontSize: 15, color: c.textCaption),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
          color: context.colors.primary, strokeWidth: 2.5),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key, required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: c.borderSubtle),
          const SizedBox(height: 12),
          Text(
            s.searchNoResults,
            style: AppTypography.amharicBody.copyWith(
              fontSize: 15, color: c.textCaption),
          ),
        ],
      ),
    );
  }
}

// ── Results list ──────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    super.key,
    required this.hits,
    required this.query,
    required this.mode,
    required this.s,
    required this.isAm,
    required this.useGeez,
  });

  final List<SearchHit> hits;
  final String query;
  final SearchMode mode;
  final AppStrings s;
  final bool isAm;
  final bool useGeez;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Text(
            s.searchResultCount(hits.length),
            style: AppTypography.amharicCaption.copyWith(
              fontSize: 12, color: context.colors.textMuted),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: hits.length,
            separatorBuilder: (context, _) =>
                Divider(height: 1, color: context.colors.borderSubtle,
                    indent: 16, endIndent: 16),
            itemBuilder: (ctx, i) => _ResultTile(
              hit:     hits[i],
              query:   query,
              mode:    mode,
              s:       s,
              isAm:    isAm,
              useGeez: useGeez,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Result tile ───────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.hit,
    required this.query,
    required this.mode,
    required this.s,
    required this.isAm,
    required this.useGeez,
  });

  final SearchHit hit;
  final String query;
  final SearchMode mode;
  final AppStrings s;
  final bool isAm;
  final bool useGeez;

  String _ref() {
    final ch = useGeez ? toGeez(hit.chapter) : '${hit.chapter}';
    final v  = useGeez ? toGeez(hit.verse)   : '${hit.verse}';
    final book = isAm ? hit.bookEntry.bookNameAm : hit.bookEntry.bookNameEn;
    return '$book ${s.chapterAbbr} $ch:$v';
  }

  List<String> get _terms => mode == SearchMode.allWords
      ? query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList()
      : [query];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final baseStyle = AppTypography.amharicBody.copyWith(
      fontSize: 14,
      color: c.textBody,
      height: 1.75,
    );
    final hlStyle = baseStyle.copyWith(
      backgroundColor: c.accent.withValues(alpha: 0.5),
      color: c.textOnParchment,
      fontWeight: FontWeight.w700,
    );

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReaderScreen(
            entry:          hit.bookEntry,
            initialChapter: hit.chapter - 1,
            initialVerse:   hit.verse,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ref(),
                    style: AppTypography.amharicLabel.copyWith(
                      fontSize: 12,
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: _highlightSpans(hit.text, _terms, baseStyle, hlStyle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.bookmark_border_rounded,
                size: 18, color: c.textCaption),
          ],
        ),
      ),
    );
  }
}
