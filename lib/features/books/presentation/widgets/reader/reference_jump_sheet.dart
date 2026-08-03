import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/services/repository_provider.dart';
import '../../../../../core/settings/app_settings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../data/models/book_index_entry.dart';
import '../../../data/reference_parser.dart';
import '../../../data/reading_models.dart';
import '../../../providers/reading_progress_providers.dart';
import '../../pages/reader_screen.dart';

class ReferenceJumpSheet extends ConsumerStatefulWidget {
  const ReferenceJumpSheet({
    super.key,
    required this.useGeez,
    required this.s,
    required this.isAmharic,
  });

  final bool useGeez;
  final AppStrings s;
  final bool isAmharic;

  @override
  ConsumerState<ReferenceJumpSheet> createState() => _ReferenceJumpSheetState();
}

class _ReferenceJumpSheetState extends ConsumerState<ReferenceJumpSheet> {
  final _controller = TextEditingController();
  List<ParsedReference> _candidates = [];
  List<BookIndexEntry> _index = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = BibleRepositoryProvider.of(context);
      _index = await repo.loadIndex();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final q = _controller.text;
    setState(() {
      _candidates = parseReference(
        q,
        _index,
        useGeezNumbers: widget.useGeez,
      );
    });
  }

  void _navigate(BookIndexEntry book, int chapter, int? verse) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          entry: book,
          initialChapterNumber: chapter,
          initialVerse: verse,
        ),
      ),
    );
  }

  Widget _buildRecentLocations() {
    final snapshotsAsync = ref.watch(continueReadingSnapshotsProvider);
    return snapshotsAsync.when(
      data: (snapshots) {
        if (snapshots.isEmpty) return const SizedBox();
        final recent = snapshots.take(5).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          itemBuilder: (ctx, i) {
            final snap = recent[i];
            final book = snap.entry;
            final pos = snap.position;
            return _ReferenceTile(
              book: book,
              chapter: pos.chapter,
              verse: pos.verse,
              isAmharic: widget.isAmharic,
              useGeez: widget.useGeez,
              s: widget.s,
              onTap: () => _navigate(book, pos.chapter, pos.verse),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Settings.of(context).isDarkReader;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : c.textOnParchment;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: AppTypography.amharicBody.copyWith(color: textColor),
              onSubmitted: (v) {
                if (_candidates.isNotEmpty) {
                  final first = _candidates.first;
                  _navigate(first.book, first.chapter, first.verse);
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter reference (e.g. John 3:16)',
                hintStyle: AppTypography.amharicBody.copyWith(color: c.textCaption),
                filled: true,
                fillColor: c.surfaceDim,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: _controller.text.trim().isEmpty
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildRecentLocations(),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _candidates.length,
                    itemBuilder: (ctx, i) {
                      final cand = _candidates[i];
                      return _ReferenceTile(
                        book: cand.book,
                        chapter: cand.chapter,
                        verse: cand.verse,
                        isAmharic: widget.isAmharic,
                        useGeez: widget.useGeez,
                        s: widget.s,
                        onTap: () => _navigate(cand.book, cand.chapter, cand.verse),
                      );
                    },
                  ),
          ),
        ],
      ),
    )));
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.isAmharic,
    required this.useGeez,
    required this.s,
    required this.onTap,
  });

  final BookIndexEntry book;
  final int chapter;
  final int? verse;
  final bool isAmharic;
  final bool useGeez;
  final AppStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = isAmharic ? book.bookNameAm : book.bookNameEn;
    final ch = useGeez ? toGeez(chapter) : '$chapter';
    final v = verse == null ? '' : ':${useGeez ? toGeez(verse) : '$verse'}';
    final refStr = '$name $ch$v';

    final isDark = Settings.of(context).isDarkReader;
    final textColor = isDark ? Colors.white : context.colors.textOnParchment;

    return ListTile(
      title: Text(
        refStr,
        style: AppTypography.amharicBody.copyWith(color: textColor),
      ),
      onTap: onTap,
    );
  }
}
