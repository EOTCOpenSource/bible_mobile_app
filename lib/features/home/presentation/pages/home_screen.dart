import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../books/presentation/pages/books_tab.dart';
import '../../../me/presentation/pages/me_screen.dart';
import '../../../search/presentation/pages/search_tab.dart';
import 'home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeTab(),
          BooksTab(
            onSearchTap: (scope) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchTab(initialScope: scope),
              ),
            ),
          ),
          const SearchTab(),
          const _StubTab('ተቀምጠ'),
          const MeScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _StubTab extends StatelessWidget {
  const _StubTab(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: AppTypography.amharicHeading.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
