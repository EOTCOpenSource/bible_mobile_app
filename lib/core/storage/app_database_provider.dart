import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single [AppDatabase] per [ProviderScope]. Use this for annotations, reading
/// progress, and streaks so the app never opens two handles to the same file.
final appDatabaseProvider = Provider<AppDatabase>((_) => AppDatabase());

/// Legacy name; identical to [appDatabaseProvider].
final Provider<AppDatabase> annotationDbProvider = appDatabaseProvider;
