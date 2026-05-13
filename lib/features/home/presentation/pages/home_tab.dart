import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/settings/app_settings.dart';
import '../widgets/home_header.dart';
import '../widgets/reading_streak_card.dart';
import '../widgets/daily_verse_card.dart';
import '../widgets/continue_reading_section.dart';
import '../widgets/reading_plans_section.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onSwitchToBooks});

  final VoidCallback onSwitchToBooks;

  @override
  Widget build(BuildContext context) {
    final today = Kenat.now();
    final useGeez = Settings.of(context).useGeezNumbers;
    final dateLabel = useGeez
        ? '${today.getWeekdayName()} · ${today.formatInGeez()}'
        : '${today.getWeekdayName()} · ${today.formatStandard()}';
    final todayWeekday = today.getWeekday();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: HomeHeader(dateLabel: dateLabel)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: ReadingStreakCard(
              todayWeekday: todayWeekday,
              onReadToday: onSwitchToBooks,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          const SliverToBoxAdapter(child: DailyVerseCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: ContinueReadingSection(onOpenBooksTab: onSwitchToBooks),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: ReadingPlansSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
