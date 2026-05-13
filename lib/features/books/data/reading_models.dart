import 'package:flutter/foundation.dart';

@immutable
class ReadingPosition {
  const ReadingPosition({
    required this.bookId,
    required this.chapter,
    this.verse,
    required this.updatedAtMs,
  });

  final String bookId;
  final int chapter;
  final int? verse;
  final int updatedAtMs;

  factory ReadingPosition.fromRow(Map<String, Object?> row) {
    final v = row['verse'];
    return ReadingPosition(
      bookId: row['book_id']! as String,
      chapter: (row['chapter'] as num).toInt(),
      verse: v == null ? null : (v as num).toInt(),
      updatedAtMs: (row['updated_at'] as num).toInt(),
    );
  }
}

@immutable
class ReadingStreakState {
  const ReadingStreakState({
    this.lastQualifiedDate,
    this.currentStreak = 0,
    this.currentStreakStart,
    this.longestStreak = 0,
    this.longestStreakStart,
    this.longestStreakEnd,
  });

  final String? lastQualifiedDate;
  final int currentStreak;
  final String? currentStreakStart;
  final int longestStreak;
  final String? longestStreakStart;
  final String? longestStreakEnd;

  factory ReadingStreakState.fromRow(Map<String, Object?> row) {
    int n(Object? k, [int d = 0]) {
      final v = row[k];
      if (v == null) return d;
      return (v as num).toInt();
    }

    String? s(Object? k) => row[k] as String?;

    return ReadingStreakState(
      lastQualifiedDate: s('last_qualified_date'),
      currentStreak: n('current_streak'),
      currentStreakStart: s('current_streak_start'),
      longestStreak: n('longest_streak'),
      longestStreakStart: s('longest_streak_start'),
      longestStreakEnd: s('longest_streak_end'),
    );
  }

  ReadingStreakState copyWith({
    String? lastQualifiedDate,
    int? currentStreak,
    String? currentStreakStart,
    int? longestStreak,
    String? longestStreakStart,
    String? longestStreakEnd,
  }) =>
      ReadingStreakState(
        lastQualifiedDate: lastQualifiedDate ?? this.lastQualifiedDate,
        currentStreak: currentStreak ?? this.currentStreak,
        currentStreakStart: currentStreakStart ?? this.currentStreakStart,
        longestStreak: longestStreak ?? this.longestStreak,
        longestStreakStart: longestStreakStart ?? this.longestStreakStart,
        longestStreakEnd: longestStreakEnd ?? this.longestStreakEnd,
      );
}
