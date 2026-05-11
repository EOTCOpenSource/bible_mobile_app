import 'package:flutter/material.dart';
import 'package:kenat/kenat.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Root screen — owns bottom nav state
// ═══════════════════════════════════════════════════════════════════════════

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
          _HomeTab(),
          _StubTab('መጽሐፍ'),
          _StubTab('ፈልግ'),
          _StubTab('ተቀምጠ'),
          _StubTab('እኔ'),
        ],
      ),
      bottomNavigationBar: _AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bottom navigation
// ═══════════════════════════════════════════════════════════════════════════

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded,         Icons.home_outlined,         'መነሻ'),
    (Icons.menu_book_rounded,    Icons.menu_book_outlined,    'መጽሐፍ'),
    (Icons.search_rounded,       Icons.search_rounded,        'ፈልግ'),
    (Icons.bookmark_rounded,     Icons.bookmark_border_rounded, 'ተቀምጠ'),
    (Icons.person_rounded,       Icons.person_outline_rounded, 'እኔ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final (activeIcon, inactiveIcon, label) = _items[i];
              final isActive = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  highlightColor: Colors.transparent,
                  splashColor: AppColors.primary.withValues(alpha: 0.06),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          isActive ? activeIcon : inactiveIcon,
                          key: ValueKey(isActive),
                          size: 24,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textCaption,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppTypography.amharicCaption.copyWith(
                          fontSize: 10,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textCaption,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Home tab — scrollable content
// ═══════════════════════════════════════════════════════════════════════════

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final today = Kenat.now();
    // "ሐሙስ · ግንቦት 15 2016"
    final dateLabel = '${today.getWeekdayName()} · ${today.formatStandard()}';
    // 0 = Sunday … 6 = Saturday
    final todayWeekday = today.getWeekday();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Header(dateLabel: dateLabel)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _ReadingStreakCard(todayWeekday: todayWeekday)),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          const SliverToBoxAdapter(child: _DailyVerseCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: _ContinueReadingSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: _ReadingPlansSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'እንኳን ደህና\nመጡ',
                  style: AppTypography.amharicDisplay.copyWith(
                    color: AppColors.textOnParchment,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Avatar(letter: 'ን'),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTypography.amharicSubheading.copyWith(
          color: AppColors.textOnDark,
          fontSize: 20,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reading Streak Card
// ═══════════════════════════════════════════════════════════════════════════

class _ReadingStreakCard extends StatelessWidget {
  const _ReadingStreakCard({required this.todayWeekday});

  /// 0 = Sunday … 6 = Saturday, as returned by Kenat.getWeekday()
  final int todayWeekday;

  // First-character abbreviations for Sun → Sat, matching Kenat's 0-based weekday
  static const _dayLabels = ['እ', 'ሰ', 'ሠ', 'ረ', 'ሐ', 'ዓ', 'ቅ'];

  // true = done (past day this week), null = today, false = future
  List<bool?> get _status => List.generate(
        7,
        (i) => i < todayWeekday
            ? true
            : i == todayWeekday
                ? null
                : false,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: flame + streak count ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  '፲፪ ቀናት',
                  style: AppTypography.amharicSubheading.copyWith(
                    color: AppColors.textOnParchment,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'ተከታታይ ንባብ',
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // ── Row 2: day circles (own row, full width, no overflow) ────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final done = _status[i];
                final isToday = done == null;
                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? AppColors.primary
                            : done == true
                                ? AppColors.primaryLight
                                : AppColors.borderSubtle,
                        border: isToday
                            ? Border.all(color: AppColors.accent, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: done == true
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : isToday
                              ? const Icon(Icons.star_rounded,
                                  size: 12, color: AppColors.accent)
                              : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dayLabels[i],
                      style: AppTypography.amharicCaption.copyWith(
                        fontSize: 9,
                        color: AppColors.textCaption,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 14),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 10),
            // ── Row 3: subtitle + CTA ─────────────────────────────────────
            Row(
              children: [
                Text(
                  'ዛሬ ምዕራፍ ፲ ያንብቡ',
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                _PillButton(
                  label: 'ዛሬ ያንብቡ',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Daily Verse Card
// ═══════════════════════════════════════════════════════════════════════════

class _DailyVerseCard extends StatelessWidget {
  const _DailyVerseCard();

  static const _verse =
      'ቃልህ ለእግሬ መብራት ነው፤\nለመንገዴም ብርሃን ነው።';
  static const _reference = 'መዝሙረ ዳዊት ፻፲፱፥፻፭';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Label row ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'የዕለቱ ቃል',
                    style: AppTypography.amharicCaption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  AppIcons.ethiopianCross,
                  style: TextStyle(
                    color: AppColors.accent.withValues(alpha: 0.55),
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Verse text ─────────────────────────────────────────────────
            Text(
              _verse,
              style: AppTypography.amharicVerse.copyWith(
                color: AppColors.textOnDark,
                height: 1.9,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 18),
            // ── Reference + actions ─────────────────────────────────────────
            Row(
              children: [
                Text(
                  _reference,
                  style: AppTypography.amharicLabel.copyWith(
                    color: AppColors.accent.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _CardIconButton(icon: Icons.share_outlined),
                const SizedBox(width: 2),
                _CardIconButton(icon: Icons.bookmark_border_rounded),
                const SizedBox(width: 2),
                _CardIconButton(icon: Icons.volume_up_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: AppColors.textOnDark),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Continue Reading
// ═══════════════════════════════════════════════════════════════════════════

class _ContinueReadingSection extends StatelessWidget {
  const _ContinueReadingSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'ንባብ ቀጥል',
                style: AppTypography.amharicSubheading.copyWith(
                  color: AppColors.textOnParchment,
                ),
              ),
              const Spacer(),
              Text(
                '፵% ተጠናቅቋ',
                style: AppTypography.englishCaption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ContinueReadingCard(),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Book cover ─────────────────────────────────────────────────
          Container(
            width: 54,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              AppIcons.ethiopianCross,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ── Book info ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'መጽሐፈ ነገሥት ቀዳማዊ',
                  style: AppTypography.amharicLabel.copyWith(
                    color: AppColors.textOnParchment,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '1 Kings · Chapter 8',
                  style: AppTypography.englishCaption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.40,
                    minHeight: 6,
                    backgroundColor: AppColors.parchmentDark,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Arrow ─────────────────────────────────────────────────────
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reading Plans
// ═══════════════════════════════════════════════════════════════════════════

class _PlanData {
  final String titleAm;
  final String daysLabel;
  final int totalDays;
  final int completedDays;
  final Color color;
  const _PlanData({
    required this.titleAm,
    required this.daysLabel,
    required this.totalDays,
    required this.completedDays,
    required this.color,
  });
}

class _ReadingPlansSection extends StatelessWidget {
  const _ReadingPlansSection();

  static const _plans = [
    _PlanData(
      titleAm: 'መጽሐፈ ዘፍጥረት',
      daysLabel: '30 ቀናት',
      totalDays: 30,
      completedDays: 12,
      color: AppColors.primary,
    ),
    _PlanData(
      titleAm: 'ወንጌለ ዮሐንስ',
      daysLabel: '21 ቀናት',
      totalDays: 21,
      completedDays: 5,
      color: AppColors.newTestament,
    ),
    _PlanData(
      titleAm: 'መዝሙረ ዳዊት',
      daysLabel: '45 ቀናት',
      totalDays: 45,
      completedDays: 0,
      color: Color(0xFF3E5C3A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'የንባብ ዕቅዶ',
                style: AppTypography.amharicSubheading.copyWith(
                  color: AppColors.textOnParchment,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'ሁሉንም ይመልከቱ',
                  style: AppTypography.amharicCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _plans.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ReadingPlanCard(plan: _plans[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadingPlanCard extends StatelessWidget {
  const _ReadingPlanCard({required this.plan});
  final _PlanData plan;

  @override
  Widget build(BuildContext context) {
    final progress = plan.completedDays / plan.totalDays;

    return Container(
      width: 158,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: plan.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: plan.color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // cross icon box
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              AppIcons.ethiopianCross,
              style: TextStyle(color: AppColors.accent, fontSize: 16),
            ),
          ),
          const Spacer(),
          Text(
            plan.titleAm,
            style: AppTypography.amharicLabel.copyWith(
              color: Colors.white,
              fontSize: 13,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            plan.daysLabel,
            style: AppTypography.amharicCaption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Stub tabs (placeholder until screens are built)
// ═══════════════════════════════════════════════════════════════════════════

class _StubTab extends StatelessWidget {
  const _StubTab(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: AppTypography.amharicHeading.copyWith(
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
