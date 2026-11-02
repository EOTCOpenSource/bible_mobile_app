import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/bible_repository_provider.dart';
import '../../../core/storage/app_database_provider.dart';
import '../data/export_service.dart';
import '../data/import_service.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = ref.watch(bibleRepositoryProvider);
  return ExportService(db: db, bibleRepository: repo);
});

final importServiceProvider = Provider<ImportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = ref.watch(bibleRepositoryProvider);
  return ImportService(db: db, bibleRepository: repo);
});
