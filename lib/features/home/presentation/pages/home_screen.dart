import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../books/presentation/pages/books_tab.dart';
import '../../../books/providers/reader_immersive_provider.dart';
import '../../../me/presentation/pages/me_screen.dart';
import '../../../saved/presentation/pages/saved_screen.dart';
import '../../../search/presentation/pages/search_tab.dart';
import '../../providers/home_tab_provider.dart';
import 'home_tab.dart';
import 'reading_plans_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Incremented each time the saved tab is tapped so IndexedStack recreates
  // SavedScreen fresh (picks up any annotations made since last visit).
  int _savedKey = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selectedIndex = ref.watch(homeTabIndexProvider);
    // Gate reader-specific states on the books tab being active. The nested
    // Navigator inside BooksTab keeps ReaderScreen alive even when another tab
    // is selected, so the providers stay true — clamp them here so other tabs
    // always get a normal white bottom nav.
    final onBooksTab = selectedIndex == kBooksTabIndex;
    final immersive = ref.watch(readerImmersiveModeProvider) && onBooksTab;
    final bottomNavMatchReader =
        ref.watch(readerBottomNavMatchReaderProvider) && onBooksTab;
    return Scaffold(
      backgroundColor: c.surface,
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomeTab(
            onSwitchToBooks: () =>
                ref.read(homeTabIndexProvider.notifier).state = kBooksTabIndex,
          ),
          BooksTab(
            onSearchTap: (scope) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchTab(initialScope: scope),
              ),
            ),
          ),
          const ReadingPlansScreen(),
          SavedScreen(key: ValueKey(_savedKey)),
          const MeScreen(),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: immersive
            ? const SizedBox.shrink()
            : AppBottomNav(
                selectedIndex: selectedIndex,
                matchReaderShellColors: bottomNavMatchReader,
                onTap: (i) {
                  if (i == 3) setState(() => _savedKey++);
                  ref.read(homeTabIndexProvider.notifier).state = i;
                },
              ),
      ),
    );
  }
}
