import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenat/kenat.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/user_profile.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/l10n/l10n.dart';
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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _saveError;
  String? _savedName;
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    final parts = (user?.name ?? '').split(' ');
    _savedName = user?.name;
    _savedEmail = user?.email;
    _firstNameCtrl = TextEditingController(text: parts.first);
    _lastNameCtrl = TextEditingController(text: parts.skip(1).join(' '));
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final user = ref.read(authStateProvider).user;
    if (user == null) return false;
    final parts = (_savedName ?? user.name).split(' ');
    final origFirst = parts.first;
    final origLast = parts.skip(1).join(' ');
    final emailChanged =
        !user.isGoogleUser && _emailCtrl.text.trim() != (_savedEmail ?? user.email);
    return _firstNameCtrl.text.trim() != origFirst ||
        _lastNameCtrl.text.trim() != origLast ||
        emailChanged;
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) return;
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final name = '$firstName $lastName'.trim();
    final email =
        user.isGoogleUser ? user.email : _emailCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() { _isSaving = true; _saveError = null; });
    try {
      await ref
          .read(authStateProvider.notifier)
          .updateProfile(name: name, email: email);
      if (mounted) {
        final updated = ref.read(authStateProvider).user!;
        setState(() {
          _savedName = updated.name;
          _savedEmail = updated.email;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar(L10n.of(context).profileSaved, const Color(0xFF2E7D32)),
        );
      }
    } on ApiException catch (e) {
      setState(() => _saveError = e.message);
    } catch (_) {
      setState(() => _saveError = L10n.of(context).authConnectionError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(authStateProvider.notifier).uploadAvatar(File(picked.path));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snackBar(e.message, context.colors.primary));
      }
    } catch (_) {
      // Network error — ignore silently
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  SnackBar _snackBar(String msg, Color bg) => SnackBar(
        content: Text(msg,
            style:
                AppTypography.amharicCaption.copyWith(color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);
    final user = ref.watch(authStateProvider).user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: c.parchment,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _TopBar(user: user, colors: c)),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _EditableAvatarSection(
                user: user,
                colors: c,
                isUploading: _isUploadingAvatar,
                onTap: user.isGoogleUser ? null : _pickAvatar,
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _StatsRow(colors: c)),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),

            // Account Info
            SliverToBoxAdapter(
              child: _FormSection(
                label: s.profileSectionInfo,
                enLabel: 'ACCOUNT',
                children: [
                  _FieldRow(
                    controller: _firstNameCtrl,
                    label: s.profileFirstName,
                    enabled: !_isSaving,
                    onChanged: (_) => setState(() {}),
                  ),
                  _FieldRow(
                    controller: _lastNameCtrl,
                    label: s.profileLastName,
                    enabled: !_isSaving,
                    onChanged: (_) => setState(() {}),
                  ),
                  _FieldRow(
                    controller: _emailCtrl,
                    label: s.authEmail,
                    enabled: !_isSaving && !user.isGoogleUser,
                    locked: user.isGoogleUser,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (user.isGoogleUser) _GoogleNotice(colors: c, s: s),
                ],
              ),
            ),

            // Security — email users only
            if (!user.isGoogleUser) ...[
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _FormSection(
                  label: s.profileSectionSecurity,
                  enLabel: 'SECURITY',
                  children: [
                    _ArrowTile(
                      icon: Icons.lock_outline_rounded,
                      label: s.profileChangePassword,
                      onTap: _showChangePassword,
                    ),
                  ],
                ),
              ),
            ],

            SliverToBoxAdapter(child: const SizedBox(height: 16)),

            // Preferences
            SliverToBoxAdapter(
              child: _FormSection(
                label: s.profileSectionPreferences,
                enLabel: 'PREFERENCES',
                children: [
                  _LanguageRow(s: s),
                  _NightModeRow(),
                ],
              ),
            ),

            if (_saveError != null) ...[
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ErrorBanner(message: _saveError!),
                ),
              ),
            ],

            if (_hasChanges) ...[
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SaveButton(
                    label: s.profileSaveChanges,
                    isLoading: _isSaving,
                    onTap: _isSaving ? null : _save,
                  ),
                ),
              ),
            ],

            SliverToBoxAdapter(child: const SizedBox(height: 28)),
            SliverToBoxAdapter(child: _AchievementsSection(colors: c)),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverToBoxAdapter(child: _LogoutTile(colors: c, s: s)),
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
            L10n.of(context).profileTitle,
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
      builder: (ctx) => SafeArea(
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
                icon: Icons.delete_outline_rounded,
                label: L10n.of(context).profileDeleteAccount,
                color: c.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, ref, c);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AppColorScheme c) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: c.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(L10n.of(context).profileDeleteTitle,
            style: AppTypography.amharicSubheading
                .copyWith(color: c.textOnParchment)),
        content: Text(L10n.of(context).profileDeleteMessage,
            style: AppTypography.amharicBody
                .copyWith(color: c.textMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(L10n.of(context).profileDeleteCancel,
                style: AppTypography.amharicLabel
                    .copyWith(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await ref.read(authStateProvider.notifier).deleteAccount();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(L10n.of(context).profileDeleteConfirm,
                style: AppTypography.amharicLabel
                    .copyWith(color: c.primary)),
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
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
            Text(label,
                style: AppTypography.amharicLabel.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Editable avatar section ─────────────────────────────────────────────────

class _EditableAvatarSection extends StatelessWidget {
  const _EditableAvatarSection({
    required this.user,
    required this.colors,
    required this.isUploading,
    required this.onTap,
  });

  final UserProfile user;
  final AppColorScheme colors;
  final bool isUploading;
  final VoidCallback? onTap;

  String get _initial =>
      user.name.isNotEmpty ? user.name.characters.first : '?';

  Widget _initialsCircle(AppColorScheme c) => Container(
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
      );

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final s = L10n.of(context);

    Widget avatar;
    if (user.avatar != null) {
      avatar = ClipOval(
        child: Image.network(
          user.avatar!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, e, st) => _initialsCircle(c),
        ),
      );
    } else {
      avatar = _initialsCircle(c);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: isUploading ? null : onTap,
              child: avatar,
            ),
            if (isUploading)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                ),
              ),
            if (onTap != null && !isUploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.parchment, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.camera_alt_rounded,
                        color: c.accent, size: 15),
                  ),
                ),
              ),
          ],
        ),
        if (onTap != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: isUploading ? null : onTap,
            child: Text(
              s.profileChangePhoto,
              style: AppTypography.amharicCaption.copyWith(
                color: c.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        SizedBox(height: onTap != null ? 8.0 : 14.0),
        Text(
          user.name,
          style: AppTypography.amharicSubheading
              .copyWith(color: c.textOnParchment),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: AppTypography.englishCaption
              .copyWith(color: c.textMuted, fontSize: 13),
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
                L10n.of(context).profileMemberBadge,
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
                label: L10n.of(context).profileStatStreak,
                colors: c),
            _StatDivider(colors: c),
            _StatCell(
                value: fmt(bookmarks),
                label: L10n.of(context).profileStatBookmarks,
                colors: c),
            _StatDivider(colors: c),
            _StatCell(
                value: '${fmt(overallPct)}%',
                label: L10n.of(context).profileStatPlan,
                colors: c),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
      required this.value, required this.label, required this.colors});
  final String value;
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTypography.amharicSubheading
                  .copyWith(color: c.textOnParchment, fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.amharicCaption
                  .copyWith(color: c.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 36, child: VerticalDivider(color: colors.borderSubtle, width: 1));
}

// ── Form section & fields ──────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.label,
    required this.enLabel,
    required this.children,
  });

  final String label;
  final String enLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(label,
                  style: AppTypography.amharicLabel
                      .copyWith(color: c.textMuted)),
              Text(' · ',
                  style: AppTypography.englishLabel
                      .copyWith(color: c.textMuted)),
              Text(
                enLabel,
                style: AppTypography.englishLabel.copyWith(
                  color: c.textCaption,
                  letterSpacing: 1.4,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderSubtle),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(children: _separated(children, c.borderSubtle)),
        ),
      ],
    );
  }

  static List<Widget> _separated(List<Widget> rows, Color divColor) {
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i < rows.length - 1) {
        result.add(Divider(color: divColor, height: 1, indent: 16));
      }
    }
    return result;
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.controller,
    required this.label,
    required this.enabled,
    this.locked = false,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool locked;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.amharicCaption.copyWith(
              color: c.textCaption,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: AppTypography.amharicBody
                .copyWith(color: c.textOnParchment, fontSize: 15),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 6, bottom: 10),
              border: InputBorder.none,
              suffixIcon: locked
                  ? Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_outline_rounded,
                          color: c.textCaption, size: 16),
                    )
                  : null,
              suffixIconConstraints:
                  const BoxConstraints(maxWidth: 28, maxHeight: 28),
              disabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: c.primary, width: 1.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: c.borderSubtle.withValues(alpha: 0.5), width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleNotice extends StatelessWidget {
  const _GoogleNotice({required this.colors, required this.s});
  final AppColorScheme colors;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 13, color: c.textCaption),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              s.profileGoogleNote,
              style: AppTypography.amharicCaption.copyWith(
                color: c.textCaption,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowTile extends StatelessWidget {
  const _ArrowTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c.textMuted, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppTypography.amharicLabel
                      .copyWith(color: c.textOnParchment)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: c.textCaption, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Preferences rows ───────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isAmharic = s is AmStrings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(s.settingLanguage,
              style: AppTypography.amharicLabel
                  .copyWith(color: c.textOnParchment)),
          const Spacer(),
          _LangChip(
            label: s.langAmharic,
            selected: isAmharic,
            onTap: () => L10n.switchLanguage(context, AppLanguage.amharic),
          ),
          const SizedBox(width: 8),
          _LangChip(
            label: s.langEnglish,
            selected: !isAmharic,
            onTap: () => L10n.switchLanguage(context, AppLanguage.english),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.primary : c.borderSubtle,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.amharicCaption.copyWith(
            color: selected ? Colors.white : c.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _NightModeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);
    final settings = Settings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.settingNightMode,
                    style: AppTypography.amharicLabel
                        .copyWith(color: c.textOnParchment)),
                const SizedBox(height: 2),
                Text(s.settingNightModeHint,
                    style: AppTypography.amharicCaption
                        .copyWith(color: c.textMuted)),
              ],
            ),
          ),
          Switch(
            value: settings.isDarkReader,
            onChanged: (v) =>
                Settings.update(context, settings.copyWith(isDarkReader: v)),
            activeThumbColor: c.primary,
            activeTrackColor: c.primaryLight.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

// ── Save button ────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton(
      {required this.label, required this.isLoading, required this.onTap});
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: onTap == null
              ? c.primary.withValues(alpha: 0.5)
              : c.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: c.accent),
              )
            : Text(label,
                style: AppTypography.amharicLabel
                    .copyWith(color: c.accent, fontSize: 15)),
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: c.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTypography.amharicCaption
                    .copyWith(color: c.primary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Logout tile ────────────────────────────────────────────────────────────

class _LogoutTile extends ConsumerWidget {
  const _LogoutTile({required this.colors, required this.s});
  final AppColorScheme colors;
  final AppStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          await ref.read(authStateProvider.notifier).logout();
          if (context.mounted) Navigator.of(context).pop();
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.primary.withValues(alpha: 0.18)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: c.primary, size: 18),
              const SizedBox(width: 10),
              Text(s.profileLogout,
                  style: AppTypography.amharicLabel
                      .copyWith(color: c.primary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Change password sheet ──────────────────────────────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _currentCtrl.text.isNotEmpty &&
      _newCtrl.text.length >= 8 &&
      _newCtrl.text == _confirmCtrl.text;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final s = L10n.of(context);
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = s.profilePasswordMismatch);
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authStateProvider.notifier).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profilePasswordChanged,
                style: AppTypography.amharicCaption
                    .copyWith(color: Colors.white)),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = L10n.of(context).authConnectionError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = L10n.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: c.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            s.profileChangePassword,
            style: AppTypography.amharicSubheading
                .copyWith(color: c.textOnParchment),
          ),
          const SizedBox(height: 20),
          _PwField(
            controller: _currentCtrl,
            label: s.profileCurrentPassword,
            obscure: _obscureCurrent,
            enabled: !_isLoading,
            onToggle: () =>
                setState(() => _obscureCurrent = !_obscureCurrent),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _PwField(
            controller: _newCtrl,
            label: s.profileNewPassword,
            obscure: _obscureNew,
            enabled: !_isLoading,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _PwField(
            controller: _confirmCtrl,
            label: s.profileConfirmNewPassword,
            obscure: _obscureConfirm,
            enabled: !_isLoading,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 20),
          _SaveButton(
            label: s.profileUpdatePassword,
            isLoading: _isLoading,
            onTap: (!_canSubmit || _isLoading) ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  const _PwField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.enabled,
    required this.onToggle,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      onChanged: onChanged,
      style: AppTypography.amharicBody
          .copyWith(color: c.textOnParchment, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.amharicCaption
            .copyWith(color: c.textCaption, fontSize: 12),
        prefixIcon:
            Icon(Icons.lock_outline_rounded, color: c.textCaption, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: c.textCaption,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: c.parchment,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
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
    final hasReadAnything = (snapshotsAsync.value?.isNotEmpty ?? false);

    final s = L10n.of(context);
    final achievements = [
      _Achievement(
        icon: AppIcons.ethiopianCross,
        title: s.achievementFirstDayTitle,
        subtitle: s.achievementFirstDaySub,
        unlocked: hasReadAnything || streak > 0,
      ),
      _Achievement(
        icon: '🔗',
        title: s.achievement7DayTitle,
        subtitle: s.achievement7DaySub,
        unlocked: streak >= 7 || longest >= 7,
      ),
      _Achievement(
        icon: '✦',
        title: s.achievementPsalmTitle,
        subtitle: s.achievementPsalmSub,
        unlocked: snapshotsAsync.value
                ?.any((snap) => snap.entry.bookNameEn.contains('Psalm')) ??
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
              Text(s.profileAchievements,
                  style: AppTypography.amharicLabel
                      .copyWith(color: c.textOnParchment)),
              const Spacer(),
              Text('$unlockedCount/${achievements.length}',
                  style: AppTypography.amharicCaption
                      .copyWith(color: c.textMuted, fontSize: 12)),
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
  const _Achievement(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.unlocked});
  final String icon;
  final String title;
  final String subtitle;
  final bool unlocked;
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard(
      {required this.achievement, required this.colors});
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
          color: unlocked
              ? c.primary.withValues(alpha: 0.25)
              : c.borderSubtle,
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
                        fontSize: 20, color: c.primary, height: 1))
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
            style: AppTypography.englishCaption
                .copyWith(color: c.textCaption, fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
