import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cross_ref.dart';
import '../data/repositories/crossref_repository.dart';

/// Singleton instance of CrossRefRepository.
final crossRefRepositoryProvider = Provider<CrossRefRepository>((ref) {
  final repository = CrossRefRepository();
  ref.onDispose(repository.clearCache);
  return repository;
});

/// Verse parameter record for looking up cross references.
typedef CrossRefVerseQuery = ({int book, int chapter, int verse});

/// Family provider to retrieve cross references for a verse.
final crossRefsForVerseProvider =
    FutureProvider.family<List<CrossRef>, CrossRefVerseQuery>((ref, query) async {
  final repo = ref.read(crossRefRepositoryProvider);
  return repo.getCrossRefs(query.book, query.chapter, query.verse);
});
