import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/settings/app_settings.dart';
import '../widgets/home_header.dart';
import '../widgets/daily_verse_card.dart';
import '../widgets/continue_reading_section.dart';
import '../../../topics/presentation/widgets/topics_section.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onSwitchToBooks});

  final VoidCallback onSwitchToBooks;

  /// The shortest viewport the one-screen layout can honestly occupy.
  ///
  /// Below this the strips are squeezed past the point where their own titles
  /// fit and the column overflows, so the page scrolls at this height instead
  /// of clipping. Measured against the tightest phone plus real chrome — a
  /// status bar, a gesture inset and the 64dp bottom nav all come off the
  /// screen before Home sees it.
  static const double minLayoutHeight = 580;

  @override
  Widget build(BuildContext context) {
    final today = Kenat.now();
    final useGeez = Settings.of(context).useGeezNumbers;
    final dateLabel = useGeez
        ? '${today.getWeekdayName()} · ${today.formatInGeez()}'
        : '${today.getWeekdayName()} · ${today.formatStandard()}';

    // Home is one screen, not a scroll. The header and the verse card are
    // fixed, and the two strips below split whatever is left — which is what
    // keeps this honest from a 640dp phone to a 915dp one without a scrollbar
    // and without tuning heights per device. Reading plans is its own tab now,
    // so it no longer competes for the space.
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHeader(
          dateLabel: dateLabel,
          onReadToday: onSwitchToBooks,
        ),
        const SizedBox(height: 12),
        const DailyVerseCard(),
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
