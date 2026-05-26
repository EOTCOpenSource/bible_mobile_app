class DailyReading {
  const DailyReading({
    required this.dayNumber,
    required this.isCompleted,
  });

  final int dayNumber;
  final bool isCompleted;

  factory DailyReading.fromJson(Map<String, dynamic> m) => DailyReading(
        dayNumber: (m['dayNumber'] as num).toInt(),
        isCompleted: (m['isCompleted'] as bool?) ?? false,
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
