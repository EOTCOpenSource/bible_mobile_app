class DailyReadingItem {
  const DailyReadingItem({
    required this.book,
    required this.startChapter,
    required this.endChapter,
  });

  final String book;         // kebab-case from API, e.g. "wisdom-of-solomon"
  final int startChapter;
  final int endChapter;

  factory DailyReadingItem.fromJson(Map<String, dynamic> m) => DailyReadingItem(
        book: (m['book'] as String?) ?? '',
        startChapter: (m['startChapter'] as num?)?.toInt() ?? 1,
        endChapter: (m['endChapter'] as num?)?.toInt() ?? 1,
      );
}

class DailyReading {
  const DailyReading({
    required this.dayNumber,
    required this.isCompleted,
    this.readings = const [],
  });

  final int dayNumber;
  final bool isCompleted;
  final List<DailyReadingItem> readings;

  factory DailyReading.fromJson(Map<String, dynamic> m) => DailyReading(
        dayNumber: (m['dayNumber'] as num).toInt(),
        isCompleted: (m['isCompleted'] as bool?) ?? false,
        readings: ((m['readings'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DailyReadingItem.fromJson)
            .where((r) => r.book.isNotEmpty)
            .toList(),
      );
}

class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.name,
    required this.durationInDays,
    required this.dailyReadings,
    this.startBook = '',
    this.status,
  });

  final String id;
  final String name;
  final int durationInDays;
  final List<DailyReading> dailyReadings;
  final String startBook;
  final String? status;

  int get completedDays => dailyReadings.where((d) => d.isCompleted).length;

  factory ReadingPlan.fromJson(Map<String, dynamic> m) => ReadingPlan(
        id: (m['_id'] ?? m['id'] ?? '') as String,
        name: (m['name'] as String?) ?? '',
        durationInDays: (m['durationInDays'] as num?)?.toInt() ?? 0,
        dailyReadings: ((m['dailyReadings'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DailyReading.fromJson)
            .toList(),
        startBook: (m['startBook'] as String?) ?? '',
        status: m['status'] as String?,
      );
}
