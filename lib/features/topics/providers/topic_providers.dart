import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/bible_repository_provider.dart';
import '../data/topic_models.dart';
import '../data/topics_repository.dart';

final topicsRepositoryProvider = Provider<TopicsRepository>((ref) {
  final bibleRepo = ref.watch(bibleRepositoryProvider);
  return TopicsRepository(bibleRepo: bibleRepo);
});

final topicsProvider = FutureProvider<List<TopicEntry>>((ref) async {
  final repo = ref.watch(topicsRepositoryProvider);
  return repo.loadTopics();
});
