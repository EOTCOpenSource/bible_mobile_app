import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../fasting/presentation/widgets/fasting_home_card.dart';
import '../widgets/home_header.dart';
import '../widgets/daily_verse_card.dart';
import '../widgets/continue_reading_section.dart';
import '../../../topics/presentation/widgets/topics_section.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onSwitchToBooks});

  final VoidCallback onSwitchToBooks;

  /// The shortest viewport the one-screen layout can honestly occupy.
  static const double minLayoutHeight = 660;

  @override
  Widget build(BuildContext context) {
    final today = Kenat.now();
    final useGeez = Settings.of(context).useGeezNumbers;
    final dateLabel = useGeez
        ? '${today.getWeekdayName()} · ${today.formatInGeez()}'
        : '${today.getWeekdayName()} · ${today.formatStandard()}';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHeader(
          dateLabel: dateLabel,
          onReadToday: onSwitchToBooks,
        ),
        const SizedBox(height: 12),
        const DailyVerseCard(),
        const SizedBox(height: 10),
        const FastingHomeCard(),
        const SizedBox(height: 14),


        // Continue reading gets the larger share: its card carries progress
        // and a call to action, where a topic is just a picture and a word.
        Expanded(
          flex: 5,
          child: ContinueReadingSection(onOpenBooksTab: onSwitchToBooks),
        ),
        const SizedBox(height: 10),
        const Expanded(flex: 4, child: TopicsSection()),
        const SizedBox(height: 8),
      ],
    );

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight >= minLayoutHeight) return content;

          // Small screen, split-screen, or a transient short viewport during
          // startup: lay the same page out at its floor and let it scroll.
          // Clipping content is the one outcome worse than a scrollbar.
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(height: minLayoutHeight, child: content),
          );
        },
      ),
    );
  }
}
