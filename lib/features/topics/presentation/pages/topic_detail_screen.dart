import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../books/data/models/book_index_entry.dart';
import '../../../books/presentation/pages/reader_screen.dart';
import '../../data/topic_models.dart';
import '../../data/topics_repository.dart';
import '../../providers/topic_providers.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topic});

  final TopicEntry topic;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final _scrollController = ScrollController();
  final _verses = <TopicVerse>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    final repo = ref.read(topicsRepositoryProvider);
    try {
      final results = await repo.searchTopicVerses(
        widget.topic,
        offset: 0,
        limit: TopicsRepository.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _verses.addAll(results);
        _offset = results.length;
        _hasMore = results.length >= TopicsRepository.pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    final repo = ref.read(topicsRepositoryProvider);
    try {
      final results = await repo.searchTopicVerses(
        widget.topic,
        offset: _offset,
        limit: TopicsRepository.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _verses.addAll(results);
        _offset += results.length;
        _hasMore = results.length >= TopicsRepository.pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isAm = L10n.of(context) is AmStrings;
    final useGeez = Settings.of(context).useGeezNumbers;
    final topicName = isAm ? widget.topic.labelAm : widget.topic.labelEn;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.textBody),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.topic.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      widget.topic.image!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(widget.topic.icon,
                    style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              topicName,
              style: TextStyle(
                color: c.textBody,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(c, isAm, useGeez),
    );
  }

  Widget _buildBody(AppColorScheme c, bool isAm, bool useGeez) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: c.accent),
      );
    }

    if (_verses.isEmpty) {
      return Center(
        child: Text(
          isAm
              ? 'ለዚህ አርእስት ጥቅስ አልተገኘም።'
              : 'No verses found for this topic.',
          style: TextStyle(color: c.textMuted),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _verses.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        // Loading indicator at the bottom
        if (idx >= _verses.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.accent,
                ),
              ),
            ),
          );
        }

        final verse = _verses[idx];
        final bookName = isAm ? verse.bookNameAm : verse.bookNameEn;
        final chStr =
            useGeez ? toGeez(verse.chapter) : '${verse.chapter}';
        final vStr = useGeez ? toGeez(verse.verse) : '${verse.verse}';
        final refDisplay = '$bookName $chStr:$vStr';

        return InkWell(
          onTap: () {
            final entry = verse.bookIndexEntry;
            if (entry is BookIndexEntry) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReaderScreen(
                    entry: entry,
                    initialChapter: verse.chapter - 1,
                    initialVerse: verse.verse,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surfaceDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        refDisplay,
                        style: TextStyle(
                          color: c.accentDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: c.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  verse.text,
                  style: TextStyle(
                    color: c.textBody,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
