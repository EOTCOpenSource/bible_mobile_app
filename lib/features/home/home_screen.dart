import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_nav.dart';
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
        children: const [
          HomeTab(),
          _StubTab('መጽሐፍ'),
          _StubTab('ፈልግ'),
          _StubTab('ተቀምጠ'),
          _StubTab('እኔ'),
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
