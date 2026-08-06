import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/auth/user_profile.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../auth/presentation/pages/profile_screen.dart';
import '../../../../core/audio/tts_providers.dart';
import '../../../onboarding/presentation/pages/onboarding_screen.dart';
import '../../../books/presentation/pages/editions_page.dart';
import '../../../books/providers/edition_providers.dart';
import '../../../backup/data/backup_models.dart';
import '../../../backup/providers/backup_providers.dart';
import '../widgets/web_reader_card.dart';
import 'reading_settings_page.dart';
import 'voice_settings_page.dart';

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final settings = Settings.of(context);
    final isAmharic = s is AmStrings;
    final authState = ref.watch(authStateProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _MeAppBar(s: s)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _ProfileCard(s: s, user: authState.user),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Reading ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionReading,
              enLabel: 'READING',
              rows: [
                _ArrowRow(
                  label: s.settingTranslation,
                  value: ref
                      .watch(activeEditionTitleProvider)
                      .maybeWhen(
                        data: (t) => t,
                        orElse: () => s.settingTranslationValue,
                      ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditionsPage()),
                  ),
                ),
                _ArrowRow(
                  label: s.meShowIntroduction,
                  onTap: () {
                    // The flag stays true — replaying the intro must not make a
                    // back-out reopen it on the next launch.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                ),
                _ArrowRow(
                  label: s.settingReadingPrefs,
                  hint: s.settingReadingPrefsHint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReadingSettingsPage(),
                    ),
                  ),
                ),
                _ToggleRow(
                  label: s.settingNightMode,
                  hint: s.settingNightModeHint,
                  value: settings.isDarkReader,
                  onChanged: (v) => Settings.update(
                    context,
                    settings.copyWith(isDarkReader: v),
                  ),
                ),
                // Audio reading is set up before it is used: the user's own
                // Addis AI key, then the voice that reads to them. The row
                // shows the voice actually in effect, so "which voice is this
                // going to use?" is answerable without opening the page.
                _ArrowRow(
                  label: s.settingAudio,
                  value: ref.watch(effectiveVoiceProvider('am')).maybeWhen(
                        data: (v) => v?.name ?? '',
                        orElse: () => '',
                      ),
                  hint: s.voiceSectionVoices,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VoiceSettingsPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Language ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionLanguage,
              enLabel: 'LANGUAGE',
              rows: [_LanguageRow(s: s, isAmharic: isAmharic)],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Numbers ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionNumbers,
              enLabel: 'NUMBERS',
              rows: [
                _ToggleRow(
                  label: s.settingGeezNums,
                  hint: s.settingGeezNumsHint,
                  value: settings.useGeezNumbers,
                  onChanged: (v) => Settings.update(
                    context,
                    settings.copyWith(useGeezNumbers: v),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Reminders ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionReminders,
              enLabel: 'REMINDERS',
              rows: [
                // Daily Verse
                _TimePickerRow(
                  label: s.settingDailyVerse,
                  hint: s.settingDailyVerseHint,
                  enabled: settings.dailyVerseNotificationEnabled,
                  time: settings.dailyVerseNotificationTime,
                  defaultTime: const TimeOfDay(hour: 6, minute: 0),
                  onToggle: (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (v) {
                      final granted = await NotificationService.instance
                          .requestPermissions();
                      if (!granted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(s.notificationPermissionDenied),
                          ),
                        );
                        return;
                      }
                    }
                    if (!context.mounted) return;
                    Settings.update(
                      context,
                      settings.copyWith(dailyVerseNotificationEnabled: v),
                    );
                    if (v) {
                      final time =
                          settings.dailyVerseNotificationTime ??
                          const TimeOfDay(hour: 6, minute: 0);
                      await NotificationService.instance.scheduleDailyVerse(
                        time,
                        s.settingDailyVerse,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(s.dailyVerseSet(time.formatted)),
                        ),
                      );
                    } else {
                      await NotificationService.instance.cancel(
                        NotificationConfig.dailyVerseId,
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text(s.dailyVerseOff)),
                      );
                    }
                  },
                  onTimePicked: (picked) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!mounted) return;
                    Settings.update(
                      context,
                      settings.copyWith(dailyVerseNotificationTime: picked),
                    );
                    await NotificationService.instance.scheduleDailyVerse(
                      picked,
                      s.settingDailyVerse,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(s.dailyVerseUpdated(picked.formatted)),
                      ),
                    );
                  },
                ),
                // Reading Reminder
                _TimePickerRow(
                  label: s.settingReadingTime,
                  hint: s.settingReadingTimeHint,
                  enabled: settings.readingTimeNotificationEnabled,
                  time: settings.readingTimeNotificationTime,
                  defaultTime: const TimeOfDay(hour: 20, minute: 0),
                  onToggle: (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (v) {
                      final granted = await NotificationService.instance
                          .requestPermissions();
                      if (!granted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(s.notificationPermissionDenied),
                          ),
                        );
                        return;
                      }
                    }
                    if (!context.mounted) return;
                    Settings.update(
                      context,
                      settings.copyWith(readingTimeNotificationEnabled: v),
                    );
                    if (v) {
                      final time =
                          settings.readingTimeNotificationTime ??
                          const TimeOfDay(hour: 20, minute: 0);
                      await NotificationService.instance
                          .scheduleReadingReminder(time, s.settingReadingTime);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(s.readingReminderSet(time.formatted)),
                        ),
                      );
                    } else {
                      await NotificationService.instance.cancel(
                        NotificationConfig.readingReminderId,
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text(s.readingReminderOff)),
                      );
                    }
                  },
                  onTimePicked: (picked) async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!mounted) return;
                    Settings.update(
                      context,
                      settings.copyWith(readingTimeNotificationTime: picked),
                    );
                    await NotificationService.instance.scheduleReadingReminder(
                      picked,
                      s.settingReadingTime,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          s.readingReminderUpdated(picked.formatted),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Backup & Restore ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionBackup,
              enLabel: 'BACKUP',
              rows: [
                _ArrowRow(
                  label: s.backupExportJson,
                  hint: s.backupExportJsonHint,
                  onTap: _isBackupBusy ? null : () => _handleExportJson(context),
                ),
                _ArrowRow(
                  label: s.backupExportMarkdown,
                  hint: s.backupExportMarkdownHint,
                  onTap: _isBackupBusy ? null : () => _handleExportMarkdown(context),
                ),
                _ArrowRow(
                  label: s.backupImport,
                  hint: s.backupImportHint,
                  onTap: _isBackupBusy ? null : () => _handleImportJson(context),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Device ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SettingsSection(
              amLabel: s.sectionDevice,
              enLabel: 'DEVICE',
              rows: const [WebReaderCard()],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _LogoutSection(s: s)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  bool _isBackupBusy = false;

  Future<void> _handleExportJson(BuildContext context) async {
    final s = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final exportService = ref.read(exportServiceProvider);

    setState(() => _isBackupBusy = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final file = File('${tempDir.path}/eotcbible-backup-$dateStr.json');
      await exportService.exportToJson(file);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'EOTC Bible Annotations Backup',
        ),
      );
      messenger.showSnackBar(
        SnackBar(content: Text(s.backupExportSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${s.backupImportFailed}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBackupBusy = false);
    }
  }

  Future<void> _handleExportMarkdown(BuildContext context) async {
    final s = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final exportService = ref.read(exportServiceProvider);

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _MarkdownExportDialog(),
    );

    if (proceed != true || !mounted) return;

    setState(() => _isBackupBusy = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final file = File('${tempDir.path}/eotcbible-annotations-$dateStr.md');
      await exportService.exportToMarkdown(file);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'EOTC Bible Annotations (Markdown)',
        ),
      );
      messenger.showSnackBar(
        SnackBar(content: Text(s.backupExportSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${s.backupImportFailed}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBackupBusy = false);
    }
  }

  Future<void> _handleImportJson(BuildContext context) async {
    final s = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final importService = ref.read(importServiceProvider);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;
      if (path == null) return;

      setState(() => _isBackupBusy = true);
      final jsonFile = File(path);
      final content = await jsonFile.readAsString();

      final preview = await importService.parseAndPreview(content);

      if (!mounted) return;
      setState(() => _isBackupBusy = false);

      var selectedPolicy = BackupConflictPolicy.skip;

      if (!context.mounted) return;
      final confirmedPolicy = await showDialog<BackupConflictPolicy>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(s.backupImport),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.backupPreviewText(
                        preview.bookmarkCount,
                        preview.highlightCount,
                        preview.noteCount,
                        preview.existingCount,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.backupConflictTitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<BackupConflictPolicy>(
                      groupValue: selectedPolicy,
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedPolicy = val);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<BackupConflictPolicy>(
                            title: Text(s.backupConflictSkip),
                            value: BackupConflictPolicy.skip,
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<BackupConflictPolicy>(
                            title: Text(s.backupConflictMerge),
                            value: BackupConflictPolicy.merge,
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<BackupConflictPolicy>(
                            title: Text(s.backupConflictReplace),
                            value: BackupConflictPolicy.replace,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: Text(s.backupCancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, selectedPolicy),
                    child: Text(s.backupConfirmImport),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmedPolicy == null || !mounted) return;

      setState(() => _isBackupBusy = true);
      await importService.executeImport(
        payload: preview.payload,
        conflictPolicy: confirmedPolicy,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.backupImportSuccess),
          backgroundColor: AppColors.accentDeep,
        ),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.backupImportFailed),
          content: Text(e is FormatException ? e.message : e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isBackupBusy = false);
    }
  }
}

// ── App bar ────────────────────────────────────────────────────────────────────

class _MeAppBar extends StatelessWidget {
  const _MeAppBar({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            s.meTitle,
            style: AppTypography.amharicHeading.copyWith(
              color: c.textOnParchment,
            ),
          ),
          const Spacer(),
          Text(
            'Settings',
            style: AppTypography.englishLabel.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Profile card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.s, required this.user});
  final AppStrings s;
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (user == null) return _GuestCard(s: s, colors: c);
    final initial = user!.name.isNotEmpty ? user!.name.characters.first : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (user!.avatar != null)
                ClipOval(
                  child: Image.network(
                    user!.avatar!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => _InitialsCircle(
                      initial: initial,
                      accent: c.accent,
                      primary: c.primary,
                    ),
                  ),
                )
              else
                _InitialsCircle(
                  initial: initial,
                  accent: c.accent,
                  primary: c.primary,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user!.name,
                      style: const TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user!.email,
                      style: AppTypography.amharicCaption.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.meProfileEditBadge,
                        style: AppTypography.amharicCaption.copyWith(
                          color: c.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({
    required this.initial,
    required this.accent,
    required this.primary,
  });

  final String initial;
  final Color accent;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: AppTypography.shiromeda,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.s, required this.colors});
  final AppStrings s;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: c.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ግባ ወይም ተመዝገብ',
                      style: const TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ማስታወሻዎትን ወደ ደመና ያስቀምጡ',
                      style: AppTypography.amharicCaption.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Markdown export confirmation ───────────────────────────────────────────────

/// Confirms the one-way Markdown export.
///
/// The whole reason this dialog exists is the caveat: a Markdown file is for
/// reading, and `import_service` cannot parse it back. So the caveat gets its
/// own callout rather than sitting in the body text where it reads as an aside,
/// and the confirm button says the verb rather than repeating the title.
class _MarkdownExportDialog extends StatelessWidget {
  const _MarkdownExportDialog();

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;

    return AlertDialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.borderSubtle),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description_outlined, size: 20, color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.backupExportMarkdown,
                  style: AppTypography.amharicLabel.copyWith(
                    color: c.textOnParchment,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MARKDOWN',
                  style: AppTypography.englishLabel.copyWith(
                    color: c.textCaption,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.backupMarkdownBody,
            style: AppTypography.amharicBody.copyWith(
              color: c.textMuted,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          // The caveat, given its own weight — this is what the user is
          // actually being asked to accept.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 17, color: c.accentDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.backupMarkdownDisclaimer,
                    style: AppTypography.amharicBody.copyWith(
                      color: c.accentDeep,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            s.backupCancel,
            style: AppTypography.amharicLabel.copyWith(
              color: c.textMuted,
              fontSize: 14,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.textOnDark,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            s.backupConfirmExport,
            style: AppTypography.amharicLabel.copyWith(
              color: c.textOnDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Settings section ───────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.amLabel,
    required this.enLabel,
    required this.rows,
  });

  final String amLabel;
  final String enLabel;
  final List<Widget> rows;

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
              Text(
                amLabel,
                style: AppTypography.amharicLabel.copyWith(color: c.textMuted),
              ),
              Text(
                ' · ',
                style: AppTypography.englishLabel.copyWith(color: c.textMuted),
              ),
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
          child: Column(children: _separated(rows, c.borderSubtle)),
        ),
      ],
    );
  }

  static List<Widget> _separated(List<Widget> rows, Color dividerColor) {
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i < rows.length - 1) {
        result.add(Divider(color: dividerColor, height: 1, indent: 16));
      }
    }
    return result;
  }
}

// ── Row types ──────────────────────────────────────────────────────────────────

class _ArrowRow extends StatelessWidget {
  const _ArrowRow({required this.label, this.hint, this.value, this.onTap});

  final String label;
  final String? hint;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.amharicLabel.copyWith(
                      color: c.textOnParchment,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hint!,
                      style: AppTypography.amharicCaption.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: AppTypography.amharicCaption.copyWith(
                  color: c.textMuted,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded, color: c.textCaption, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.amharicLabel.copyWith(
                    color: c.textOnParchment,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: AppTypography.amharicCaption.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.primary,
            activeTrackColor: c.primaryLight.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

// ── Notification time-picker row ─────────────────────────────────────────────

/// A settings row combining an enable/disable [Switch] with a tappable time
/// chip. When enabled the chip opens the system time picker; when disabled it
/// is greyed-out and non-interactive. An internal [_busy] flag prevents double
/// taps and shows a small [CircularProgressIndicator] while async work runs.
class _TimePickerRow extends StatefulWidget {
  const _TimePickerRow({
    required this.label,
    this.hint,
    required this.enabled,
    this.time,
    required this.defaultTime,
    required this.onToggle,
    required this.onTimePicked,
  });

  final String label;
  final String? hint;

  /// Whether the notification is currently enabled.
  final bool enabled;

  /// Currently stored time; [defaultTime] is displayed when null.
  final TimeOfDay? time;

  /// Fallback displayed when [time] is null.
  final TimeOfDay defaultTime;

  /// Called when the switch is flipped. Owns permission requests, scheduling,
  /// and snackbars. Return normally to confirm; the [_busy] guard is released
  /// automatically.
  final Future<void> Function(bool enabled) onToggle;

  /// Called with the newly-chosen time after the system picker confirms.
  final Future<void> Function(TimeOfDay time) onTimePicked;

  @override
  State<_TimePickerRow> createState() => _TimePickerRowState();
}

class _TimePickerRowState extends State<_TimePickerRow> {
  bool _busy = false;

  Future<void> _handleToggle(bool v) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onToggle(v);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    if (_busy || !widget.enabled) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.time ?? widget.defaultTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onTimePicked(picked);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final displayTime = (widget.time ?? widget.defaultTime).formatted;
    final isOn = widget.enabled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          // Label + hint
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: AppTypography.amharicLabel.copyWith(
                    color: c.textOnParchment,
                  ),
                ),
                if (widget.hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.hint!,
                    style: AppTypography.amharicCaption.copyWith(
                      color: c.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tappable time chip
          GestureDetector(
            onTap: isOn && !_busy ? _pickTime : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOn
                    ? c.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isOn ? c.primary : c.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: isOn ? c.primary : c.textCaption,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayTime,
                    style: AppTypography.amharicCaption.copyWith(
                      color: isOn ? c.primary : c.textCaption,
                      fontWeight: isOn ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Switch or loading indicator
          if (_busy)
            const SizedBox(
              width: 40,
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Switch(
              value: isOn,
              onChanged: _handleToggle,
              activeThumbColor: c.primary,
              activeTrackColor: c.primaryLight.withValues(alpha: 0.4),
            ),
        ],
      ),
    );
  }
}

// ── Language picker row ────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.s, required this.isAmharic});

  final AppStrings s;
  final bool isAmharic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            s.settingLanguage,
            style: AppTypography.amharicLabel.copyWith(
              color: c.textOnParchment,
            ),
          ),
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
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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

// ── Logout section ─────────────────────────────────────────────────────────────

class _LogoutSection extends ConsumerWidget {
  const _LogoutSection({required this.s});
  final AppStrings s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    if (!authState.isAuthenticated) return const SizedBox.shrink();

    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          await ref.read(authStateProvider.notifier).logout();
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
              Text(
                s.profileLogout,
                style: AppTypography.amharicLabel.copyWith(
                  color: c.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
