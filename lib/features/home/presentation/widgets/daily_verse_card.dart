import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/play_verses.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/repository_provider.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../annotations/providers/annotation_providers.dart';
import '../../../books/data/models/book.dart';
import '../../../books/data/repositories/bible_repository.dart';
import '../../../books/presentation/pages/reader_screen.dart';
import '../../../share/verse_card_sheet.dart';

class DailyVerseCard extends ConsumerStatefulWidget {
  const DailyVerseCard({super.key});

  @override
  ConsumerState<DailyVerseCard> createState() => _DailyVerseCardState();
}

class _DailyVerseCardState extends ConsumerState<DailyVerseCard> {
  Future<DailyVerseResult?>? _future;

  /// Guards the share button while the chapter loads behind it.
  bool _sharing = false;

  // The card is a fixed size whatever the verse costs. Psalm 119 and a one-line
  // proverb both land on the same footprint, so Home's layout below it never
  // moves. Overflow is truncated on screen only — [playVersesAloud] is handed
  // the untouched text and reads the verse to the end.
  static const double _verseFontSize = 17;
  static const double _verseLineHeight = 1.7;
  static const int _verseMaxLines = 3;
  static const double _verseBoxHeight =
      _verseFontSize * _verseLineHeight * _verseMaxLines;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<DailyVerseResult?> _load() {
    final et    = Kenat.now().getEthiopian();
    final month = et['month'] as int;
    final day   = et['day']   as int;
    return BibleRepositoryProvider.of(context).loadDailyVerse(month, day);
  }

  void _retry() => setState(() => _future = _load());

  String _formatRef(DailyVerseResult r, bool useGeez) {
    final ch = useGeez ? toGeez(r.chapter) : '${r.chapter}';
    final v  = useGeez ? toGeez(r.verse)   : '${r.verse}';
    return '${r.bookNameAm} $ch:$v';
  }

  /// The small uppercase reference in the card's top-right, e.g. `JER 31:33`.
  ///
  /// Always Latin digits: it is the compact counterpart to the Amharic
  /// reference along the bottom, and Geez numerals there would collide with
  /// the abbreviated book name in the space available.
  String _shortRef(DailyVerseResult r) {
    final book = r.bookNameEn.trim();
    // "1 Corinthians" → "1 COR", "Jeremiah" → "JER".
    final parts = book.split(RegExp(r'\s+'));
    final word = parts.last;
    final abbr = word.length <= 3 ? word : word.substring(0, 3);
    final prefix = parts.length > 1 ? '${parts.first} ' : '';
    return '$prefix${abbr.toUpperCase()} ${r.chapter}:${r.verse}';
  }

  void _openInReader(BuildContext context, DailyVerseResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          entry:          result.bookEntry,
          initialChapter: result.chapter - 1,
          initialVerse:   result.verse,
        ),
      ),
    );
  }

  /// What the audio service is asked to call this verse.
  ///
  /// Deliberately not the displayed reference: that switches to Geez numerals
  /// with the setting, and the title is compared against the playing title to
  /// decide whether this card owns the audio.
  String _audioTitle(DailyVerseResult r) =>
      '${r.bookNameAm} ${r.chapter}:${r.verse}';

  bool _isThisPlaying(String title) {
    final audio = AudioService.instance;
    return audio.currentTitleNotifier.value == title &&
        audio.stateNotifier.value != AudioState.stopped;
  }

  /// The annotation bucket this verse belongs to — the same one the reader
  /// writes to, so a bookmark made here is already there when the chapter opens.
  ChapterKey _chapterKey(DailyVerseResult r) =>
      (bookId: r.bookEntry.id, chapter: r.chapter);

  Future<void> _toggleBookmark(DailyVerseResult result) async {
    await ref
        .read(chapterAnnotationsProvider(_chapterKey(result)).notifier)
        .toggleBookmark(
          verseStart: result.verse,
          bookNumber: result.bookEntry.bookNumber,
        );
  }

  /// Opens the same share sheet the reader uses.
  ///
  /// The sheet renders a real [Verse], not a string, so the chapter has to be
  /// loaded first — the daily verse arrives as plain text and does not carry
  /// the line breaks and cross references the card lays out.
  Future<void> _share(DailyVerseResult result) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final book = await BibleRepositoryProvider.of(context)
          .loadBook(result.bookEntry);
      if (!mounted) return;

      final chapter = _findChapter(book, result.chapter);
      final verse = chapter == null ? null : _findVerse(chapter, result.verse);
      if (verse == null || chapter == null) {
        // The edition moved or renumbered the verse under us; the reader is
        // still a way to get to it, so say nothing and do nothing rather than
        // sharing the wrong words.
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VerseCardSheet(
          verses: [verse],
          book: book,
          chapterNumber: chapter.chapterNumber,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  static Chapter? _findChapter(Book book, int number) {
    for (final c in book.chapters) {
      if (c.chapterNumber == number) return c;
    }
    return null;
  }

  static Verse? _findVerse(Chapter chapter, int number) {
    for (final v in chapter.allVerses) {
      if (v.verseNumber == number) return v;
    }
    return null;
  }

  /// Reads the daily verse with the same AI voice as the reader.
  ///
  /// One verse rather than a chapter, so it is a single generation on the
  /// user's key — a second tap stops it instead of paying for it twice.
  Future<void> _toggleAudio(DailyVerseResult result) async {
    final title = _audioTitle(result);
    if (_isThisPlaying(title)) {
      await AudioService.instance.stop();
      return;
    }
    await playVersesAloud(
      context: context,
      ref: ref,
      title: title,
      verses: [result.text],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s       = L10n.of(context);
    final useGeez = Settings.of(context).useGeezNumbers;

    return FutureBuilder<DailyVerseResult?>(
      future: _future,
      builder: (context, snapshot) {
        final result    = snapshot.data;
        final verseText = result?.text ?? '';
        final reference = result != null ? _formatRef(result, useGeez) : '';

        final c = context.colors;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Soft disc bleeding off the top-right corner.
                Positioned(
                  top: -70,
                  right: -55,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tag row ────────────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      s.dailyVerseTag,
                      style: AppTypography.amharicCaption.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    if (result != null)
                      Text(
                        _shortRef(result),
                        style: AppTypography.englishCaption.copyWith(
                          color: c.accent.withValues(alpha: 0.45),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Verse text ─────────────────────────────────────────────
                SizedBox(
                  height: _verseBoxHeight,
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: switch (snapshot.connectionState) {
                      ConnectionState.waiting =>
                        _LoadingLines(key: const ValueKey('loading')),
                      _ when verseText.isEmpty => GestureDetector(
                          key: const ValueKey('empty'),
                          onTap: _retry,
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded,
                                  size: 18,
                                  color: c.textOnDark.withValues(alpha: 0.8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.dailyVerseUnavailable,
                                  style: AppTypography.amharicBody.copyWith(
                                    color: c.textOnDark.withValues(alpha: 0.85),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Tapping the text opens the reader, which is where the
                      // rest of a truncated verse lives.
                      _ => GestureDetector(
                          key: const ValueKey('verse'),
                          onTap: result != null
                              ? () => _openInReader(context, result)
                              : null,
                          child: Text(
                            verseText,
                            maxLines: _verseMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.amharicVerse.copyWith(
                              color: c.textOnDark,
                              height: _verseLineHeight,
                              fontSize: _verseFontSize,
                            ),
                          ),
                        ),
                    },
                  ),
                ),
                const SizedBox(height: 14),
                // ── Reference link + actions ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: result != null
                            ? () => _openInReader(context, result)
                            : null,
                        child: Text(
                          reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.amharicLabel.copyWith(
                            color: c.accent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconAction(
                      icon: Icons.share_outlined,
                      label: s.semanticsDailyVerseShare,
                      onTap: result != null ? () => _share(result) : null,
                      child: _sharing
                          ? CircularProgressIndicator(
                              strokeWidth: 2, color: c.textOnDark)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _BookmarkAction(
                      chapterKey: result != null ? _chapterKey(result) : null,
                      verse: result?.verse,
                      onTap: result != null
                          ? () => _toggleBookmark(result)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _VoiceAction(
                      onTap: result != null ? () => _toggleAudio(result) : null,
                      title: result != null ? _audioTitle(result) : null,
                    ),
                  ],
                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingLines extends StatelessWidget {
  const _LoadingLines({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _line(0.95),
        _line(0.85),
        _line(0.55),
      ],
    );
  }

  Widget _line(double widthFraction) => FractionallySizedBox(
        widthFactor: widthFraction,
        child: Container(
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    this.selected,
    this.onTap,
    this.child,
  });

  final IconData icon;
  final String label;
  final bool? selected;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: Material(
        color: Colors.white.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap ?? () {},
          customBorder: const CircleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            child: Center(
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: child ??
                      Icon(icon, size: 18, color: context.colors.textOnDark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarkAction extends ConsumerWidget {
  const _BookmarkAction({
    required this.chapterKey,
    required this.verse,
    required this.onTap,
  });

  final ChapterKey? chapterKey;
  final int? verse;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = L10n.of(context);
    var saved = false;
    if (chapterKey != null && verse != null) {
      final annotations = ref.watch(chapterAnnotationsProvider(chapterKey!));
      saved = annotations.value?.isBookmarked(verse!) ?? false;
    }

    return _IconAction(
      icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      label: saved ? s.semanticsBookmarkRemove : s.semanticsBookmarkAdd,
      selected: saved,
      onTap: onTap,
    );
  }
}

class _VoiceAction extends StatelessWidget {
  const _VoiceAction({required this.onTap, required this.title});

  final VoidCallback? onTap;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final audio = AudioService.instance;

    return ValueListenableBuilder<String?>(
      valueListenable: audio.currentTitleNotifier,
      builder: (context, playingTitle, _) {
        final isThis = title != null && playingTitle == title;

        return ValueListenableBuilder<AudioState>(
          valueListenable: audio.stateNotifier,
          builder: (context, state, _) {
            final busy = isThis && state == AudioState.buffering;
            final playing = isThis &&
                (state == AudioState.playing || state == AudioState.paused);

            return _IconAction(
              icon: playing ? Icons.stop_rounded : Icons.volume_up_outlined,
              label: s.semanticsAudioBtn,
              selected: playing,
              onTap: onTap,
              child: busy
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.textOnDark,
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
