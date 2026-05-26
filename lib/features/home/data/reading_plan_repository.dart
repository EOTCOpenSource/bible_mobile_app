import '../../../core/api/api_client.dart';
import 'reading_plan.dart';

class ReadingPlanRepository {
  const ReadingPlanRepository(this._api, this._token);

  final ApiClient _api;
  final String _token;

  Future<List<ReadingPlan>> fetchPlans() async {
    final res = await _api.get('/reading-plans', token: _token);
    final data = res['data'];
    final list = (data is Map
            ? (data['readingPlans'] ?? data['data'] ?? data)
            : data) as List? ??
        [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ReadingPlan.fromJson)
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  Future<void> markDayComplete(String planId, int dayNumber) =>
      _api.patch('/reading-plans/$planId/days/$dayNumber/complete',
          token: _token);
}
