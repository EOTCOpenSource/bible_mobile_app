import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_state.dart';
import '../data/reading_plan.dart';
import '../data/reading_plan_repository.dart';

final readingPlansProvider =
    AsyncNotifierProvider<ReadingPlansNotifier, List<ReadingPlan>>(
  ReadingPlansNotifier.new,
);

class ReadingPlansNotifier extends AsyncNotifier<List<ReadingPlan>> {
  @override
  Future<List<ReadingPlan>> build() async {
    final authState = ref.watch(authStateProvider);
    if (!authState.isAuthenticated) return [];
    final repo = ReadingPlanRepository(
      ref.read(apiClientProvider),
      authState.token!,
    );
    return repo.fetchPlans();
  }

  Future<void> markDayComplete(String planId, int dayNumber) async {
    final token = ref.read(authStateProvider).token;
    if (token == null) return;
    final repo = ReadingPlanRepository(ref.read(apiClientProvider), token);
    await repo.markDayComplete(planId, dayNumber);
    ref.invalidateSelf();
  }
}
