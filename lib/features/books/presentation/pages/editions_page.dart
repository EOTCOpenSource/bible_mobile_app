import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/bible_repository_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/edition.dart';
import '../../providers/edition_providers.dart';

/// Picks the active Bible edition and manages which ones are on the device.
///
/// `am-2000` ships inside the app, so this screen always has something to
/// offer offline; the other eight are ~8–14 MB downloads.
class EditionsPage extends ConsumerStatefulWidget {
  const EditionsPage({super.key});

  @override
  ConsumerState<EditionsPage> createState() => _EditionsPageState();
}

class _EditionsPageState extends ConsumerState<EditionsPage> {
  /// Download progress by edition id, present only while in flight.
  final Map<String, double> _progress = {};

  Future<void> _download(EditionInstall item, AppStrings s) async {
    final id = item.edition.id;
    final manager = ref.read(editionManagerProvider);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _progress[id] = 0);
    try {
      await manager.install(
        id,
        onProgress: (p) {
          if (mounted) setState(() => _progress[id] = p);
        },
      );
      ref.invalidate(editionListProvider);
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _progress.remove(id));
    }
  }

  Future<void> _update(EditionInstall item, AppStrings s) async {
    final id = item.edition.id;
    final manager = ref.read(editionManagerProvider);
    final repo = ref.read(bibleRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final title = _title(item.edition, s);

    setState(() => _progress[id] = 0);
    try {
      await manager.update(
        id,
        onProgress: (p) {
          if (mounted) setState(() => _progress[id] = p);
        },
      );
      // The reader holds a read-only connection; reopen it so the corrected
      // text is what the next chapter render sees.
      if (id == repo.activeEditionId) await repo.reloadActiveEdition();
      ref.invalidate(editionListProvider);
      messenger.showSnackBar(SnackBar(content: Text(s.editionUpdated(title))));
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _progress.remove(id));
    }
  }

  Future<void> _remove(EditionInstall item, AppStrings s) async {
    final title = _title(item.edition, s);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.editionRemoveTitle),
        content: Text(s.editionRemoveBody(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.editionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.editionRemoveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final manager = ref.read(editionManagerProvider);
    final repo = ref.read(bibleRepositoryProvider);
    try {
      await manager.remove(item.edition.id);
      // Falls back to the bundled edition if the one just deleted was active.
      await repo.handleEditionRemoved(item.edition.id);
      ref.read(activeEditionIdProvider.notifier).state = repo.activeEditionId;
      ref.invalidate(editionListProvider);
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _use(EditionInstall item) async {
    final repo = ref.read(bibleRepositoryProvider);
    if (!await repo.switchEdition(item.edition.id)) return;
    if (!mounted) return;
    ref.read(activeEditionIdProvider.notifier).state = repo.activeEditionId;
    ref.invalidate(editionListProvider);
  }

  static String _title(Edition e, AppStrings s) =>
      s is EnStrings ? e.titleEn : e.title;

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final activeId = ref.watch(activeEditionIdProvider);
    final listAsync = ref.watch(editionListProvider);

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          s.editionsTitle,
          style: AppTypography.amharicSubheading
              .copyWith(fontSize: 17, color: c.textOnParchment),
        ),
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (items) {
          final installed = items.where((i) => i.isInstalled).toList();
          final available = items.where((i) => !i.isInstalled).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(editionManagerProvider).fetchManifest(force: true);
              ref.invalidate(editionListProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    s.editionsSubtitle,
                    style: TextStyle(fontSize: 13, color: c.textMuted),
                  ),
                ),
                if (installed.isNotEmpty) ...[
                  _GroupLabel(text: s.editionsInstalled, color: c.textMuted),
                  for (final item in installed)
                    _EditionCard(
                      item: item,
                      s: s,
                      isActive: item.edition.id == activeId,
                      progress: _progress[item.edition.id],
                      onUse: () => _use(item),
                      onUpdate: () => _update(item, s),
                      onRemove: () => _remove(item, s),
                      onDownload: () => _download(item, s),
                    ),
                ],
                if (available.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _GroupLabel(text: s.editionsAvailable, color: c.textMuted),
                  for (final item in available)
                    _EditionCard(
                      item: item,
                      s: s,
                      isActive: false,
                      progress: _progress[item.edition.id],
                      onUse: () => _use(item),
                      onUpdate: () => _update(item, s),
                      onRemove: () => _remove(item, s),
                      onDownload: () => _download(item, s),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.nokiaPureheadline,
            fontSize: 9,
            letterSpacing: 1.2,
            color: color,
          ),
        ),
      );
}

class _EditionCard extends StatelessWidget {
  const _EditionCard({
    required this.item,
    required this.s,
    required this.isActive,
    required this.progress,
    required this.onUse,
    required this.onUpdate,
    required this.onRemove,
    required this.onDownload,
  });

  final EditionInstall item;
  final AppStrings s;
  final bool isActive;
  final double? progress;
  final VoidCallback onUse;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;
  final VoidCallback onDownload;

  static String _size(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = item.edition;
    final isEnglish = s is EnStrings;
    final title = isEnglish ? e.titleEn : e.title;
    final subtitle = isEnglish ? e.title : e.titleEn;
    final busy = progress != null;

    final meta = <String>[
      e.languageName,
      if (e.yearLabel.isNotEmpty) e.yearLabel,
      '${e.books} · ${e.verses}',
      if (!item.isInstalled) _size(item.downloadBytes),
    ].where((t) => t.isNotEmpty).join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: c.surfaceDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? c.accentDeep.withValues(alpha: 0.55)
              : c.borderSubtle,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textOnParchment,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              if (isActive)
                _Badge(text: s.editionActive, color: c.accentDeep)
              else if (item.isBundled)
                _Badge(text: s.editionBuiltIn, color: c.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            meta,
            style: TextStyle(
              fontFamily: AppTypography.nokiaPureheadline,
              fontSize: 10,
              letterSpacing: 0.4,
              color: c.textMuted,
            ),
          ),
          // Only en-kjv is public domain; every other edition belongs to a
          // Bible Society and the reader should be able to see whose it is.
          const SizedBox(height: 4),
          Text(
            e.isPublicDomain
                ? s.editionPublicDomain
                : s.editionPublishedBy(e.publisher ?? '—'),
            style: TextStyle(
              fontSize: 10,
              color: c.textMuted.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          if (busy) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress == 0 ? null : progress,
                minHeight: 4,
                backgroundColor: c.borderSubtle,
                color: c.accentDeep,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.editionDownloading,
              style: TextStyle(fontSize: 11, color: c.textMuted),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (!item.isInstalled)
                  _CardAction(
                    label: s.editionDownload,
                    primary: true,
                    onTap: onDownload,
                  )
                else ...[
                  if (!isActive)
                    _CardAction(
                      label: s.editionUse,
                      primary: true,
                      onTap: onUse,
                    ),
                  if (item.status == EditionStatus.updateAvailable)
                    _CardAction(label: s.editionUpdate, onTap: onUpdate),
                  if (!item.isBundled)
                    _CardAction(
                      label: s.editionRemove,
                      destructive: true,
                      onTap: onRemove,
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = destructive
        ? const Color(0xFFB61F21)
        : primary
            ? c.accentDeep
            : c.textMuted;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
