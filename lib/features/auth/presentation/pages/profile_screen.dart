import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/user_profile.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/storage/app_database_provider.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/providers/reading_progress_providers.dart';

// ── Stats provider ─────────────────────────────────────────────────────────

final _bookmarkCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = await ref.watch(appDatabaseProvider).database;
  final rows = await db.rawQuery(
    "SELECT COUNT(*) as c FROM bookmarks WHERE sync_status != 'pendingDelete'",
  );
  return (rows.first['c'] as int?) ?? 0;
});

// ── Profile screen ─────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: c.parchment,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _TopBar(user: user, colors: c)),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverToBoxAdapter(child: _AvatarSection(user: user, colors: c)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _StatsRow(colors: c)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _ActionButtons(colors: c)),
            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(child: _AchievementsSection(colors: c)),
            SliverToBoxAdapter(child: const SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.user, required this.colors});
  final UserProfile user;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.borderSubtle),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.chevron_left_rounded,
                  color: c.textOnParchment, size: 22),
            ),
          ),
          const Spacer(),
          Text(
            'ፕሮፋይል',
            style: AppTypography.amharicLabel.copyWith(
              color: c.textOnParchment,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          _MenuButton(user: user, colors: c),
        ],
      ),
    );
  }
}

class _MenuButton extends ConsumerWidget {
  const _MenuButton({required this.user, required this.colors});
  final UserProfile user;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    return GestureDetector(
      onTap: () => _showMenu(context, ref, c),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.borderSubtle),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.more_horiz_rounded, color: c.textMuted, size: 20),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, AppColorScheme c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProfileMenuSheet(colors: c, ref: ref, context: context),
    );
  }
}

class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet({
    required this.colors,
    required this.ref,
    required this.context,
  });
  final AppColorScheme colors;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    final c = colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: c.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SheetTile(
              icon: Icons.logout_rounded,
              label: 'ውጣ',
              color: c.textBody,
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            Divider(color: c.borderSubtle, height: 1, indent: 16),
            _SheetTile(
              icon: Icons.delete_outline_rounded,
              label: 'መለያ ሰርዝ',
              color: c.primary,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref, c);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, WidgetRef ref, AppColorScheme c) {
    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'መለያ ይሰረዝ?',
          style: AppTypography.amharicSubheading.copyWith(
            color: c.textOnParchment,
          ),
        ),
        content: Text(
          'ሁሉም ውሂብዎ ይጠፋል። ይህ ድርጊት ሊቀለበስ አይችልም።',
          style: AppTypography.amharicBody.copyWith(
            color: c.textMuted,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text('ይቅር',
                style: AppTypography.amharicLabel
                    .copyWith(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await ref.read(authStateProvider.notifier).deleteAccount();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text('ሰርዝ',
                style: AppTypography.amharicLabel
                    .copyWith(color: c.primary)),
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTypography.amharicLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar section ─────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.user, required this.colors});
  final UserProfile user;
  final AppColorScheme colors;

  String get _initial =>
      user.name.isNotEmpty ? user.name.characters.first : '?';

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _initial,
                style: TextStyle(
                  fontFamily: AppTypography.shiromeda,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.parchment, width: 2),
                ),
                alignment: Alignment.center,
                child:
                    Icon(Icons.camera_alt_rounded, size: 13, color: c.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          user.name,
          style: AppTypography.amharicSubheading.copyWith(
            color: c.textOnParchment,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: AppTypography.englishCaption.copyWith(
            color: c.textMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppIcons.malteseCross,
                  style: TextStyle(color: c.accentDeep, fontSize: 11)),
              const SizedBox(width: 6),
              Text(
                'አባል · የቅዱስ ቤተ-ሰብ',
                style: AppTypography.amharicCaption.copyWith(
                  color: c.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    final useGeez = Settings.of(context).useGeezNumbers;
    final streakAsync = ref.watch(readingStreakStateProvider);
    final bookmarkAsync = ref.watch(_bookmarkCountProvider);
    final snapshotsAsync = ref.watch(continueReadingSnapshotsProvider);

    final streak = streakAsync.value?.currentStreak ?? 0;
    final bookmarks = bookmarkAsync.value ?? 0;

    int overallPct = 0;
    if (snapshotsAsync.value != null && snapshotsAsync.value!.isNotEmpty) {
      final snapshots = snapshotsAsync.value!;
      overallPct = snapshots
              .map((s) => s.progressPercent)
              .reduce((a, b) => a + b) ~/
          snapshots.length;
    }

    String fmt(int n) => useGeez ? toGeez(n) : '$n';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          children: [
            _StatCell(
                value: fmt(streak),
                label: 'ቀን ቅ/ነዴ',
                colors: c),
            _StatDivider(colors: c),
            _StatCell(
                value: fmt(bookmarks),
                label: 'ምልክት',
                colors: c),
            _StatDivider(colors: c),
            _StatCell(
                value: '${fmt(overallPct)}%',
                label: 'ዕቅድ',
                colors: c),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.colors,
  });
  final String value;
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.amharicSubheading.copyWith(
              color: c.textOnParchment,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.amharicCaption.copyWith(
              color: c.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: VerticalDivider(color: colors.borderSubtle, width: 1),
    );
  }
}

// ── Action buttons ─────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.primary, width: 1.2),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, color: c.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'ፕሮፋይል አስተካክል',
                      style: AppTypography.amharicCaption.copyWith(
                        color: c.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderSubtle),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.ios_share_rounded, color: c.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Achievements section ───────────────────────────────────────────────────

class _AchievementsSection extends ConsumerWidget {
  const _AchievementsSection({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    final streakAsync = ref.watch(readingStreakStateProvider);
    final streak = streakAsync.value?.currentStreak ?? 0;
    final longest = streakAsync.value?.longestStreak ?? 0;
    final snapshotsAsync = ref.watch(continueReadingSnapshotsProvider);
    final hasReadAnything =
        (snapshotsAsync.value?.isNotEmpty ?? false);

    final achievements = [
      _Achievement(
        icon: AppIcons.ethiopianCross,
        title: 'መጀመሪያ ቀን',
        subtitle: 'First Day',
        unlocked: hasReadAnything || streak > 0,
      ),
      _Achievement(
        icon: '🔗',
        title: '፯ ቀን ሰንሰለት',
        subtitle: '7-Day Streak',
        unlocked: streak >= 7 || longest >= 7,
      ),
      _Achievement(
        icon: '✦',
        title: 'የምዝሙሩ',
        subtitle: 'Psalm Reader',
        unlocked: snapshotsAsync.value
                ?.any((s) => s.entry.bookNameEn.contains('Psalm')) ??
            false,
      ),
    ];

    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'ስኬቶች',
                style: AppTypography.amharicLabel.copyWith(
                  color: c.textOnParchment,
                ),
              ),
              const Spacer(),
              Text(
                '$unlockedCount/${achievements.length}',
                style: AppTypography.amharicCaption.copyWith(
                  color: c.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: achievements.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                _AchievementCard(achievement: achievements[i], colors: c),
          ),
        ),
      ],
    );
  }
}

class _Achievement {
  const _Achievement({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.unlocked,
  });
  final String icon;
  final String title;
  final String subtitle;
  final bool unlocked;
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.colors,
  });
  final _Achievement achievement;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final unlocked = achievement.unlocked;
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? c.primary.withValues(alpha: 0.25) : c.borderSubtle,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked
                  ? c.primary.withValues(alpha: 0.1)
                  : c.borderSubtle.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: unlocked
                ? Text(achievement.icon,
                    style: TextStyle(
                        fontSize: 20,
                        color: c.primary,
                        height: 1))
                : Icon(Icons.lock_outline_rounded,
                    color: c.textCaption, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: AppTypography.amharicCaption.copyWith(
              color: unlocked ? c.textOnParchment : c.textCaption,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            achievement.subtitle,
            style: AppTypography.englishCaption.copyWith(
              color: c.textCaption,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
