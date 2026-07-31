import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/bible_repository_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/edition_manager.dart';
import '../../data/models/edition.dart';
import '../../providers/edition_providers.dart';
import '../widgets/edition_switcher.dart';

/// Picks the active Bible edition and manages which ones are on the device.
///
/// `am-2000` ships inside the app, so this screen always has something to
/// offer offline; the other eight are ~8–14 MB downloads.
///
/// Nine editions in one flat list read as noise, so the screen leads with the
/// edition being read, then filters the rest by language — the axis along which
/// a reader actually chooses.
class EditionsPage extends ConsumerStatefulWidget {
  const EditionsPage({super.key});

  @override
  ConsumerState<EditionsPage> createState() => _EditionsPageState();
}

class _EditionsPageState extends ConsumerState<EditionsPage> {
  /// Download progress by edition id, present only while in flight.
  final Map<String, double> _progress = {};

  /// Cancellation handles for the in-flight downloads above.
  final Map<String, CancellationToken> _cancels = {};

  /// Language subtag the list is filtered to; null means every language.
  String? _language;

  Future<void> _download(EditionInstall item, AppStrings s) async {
    final id = item.edition.id;
    final manager = ref.read(editionManagerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final cancel = CancellationToken();

    setState(() {
      _progress[id] = 0;
      _cancels[id] = cancel;
    });
    try {
      await manager.install(
        id,
        cancel: cancel,
        onProgress: (p) {
          if (mounted) setState(() => _progress[id] = p);
        },
      );
      ref.invalidate(editionListProvider);
    } on Object catch (e) {
      // A cancel the user asked for is not an error worth a snackbar.
      if (!cancel.isCancelled) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _progress.remove(id);
          _cancels.remove(id);
        });
      }
    }
  }

  void _cancelDownload(EditionInstall item) =>
      _cancels[item.edition.id]?.cancel();

  Future<void> _update(EditionInstall item, AppStrings s) async {
    final id = item.edition.id;
    final manager = ref.read(editionManagerProvider);
    final repo = ref.read(bibleRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final title = editionTitleFor(item.edition, s);

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
    final title = editionTitleFor(item.edition, s);
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
      // Deleting the parallel edition turns parallel reading off; the chip and
      // the settings row read that from this provider, not from the repository.
      ref.read(secondaryEditionIdProvider.notifier).state =
          repo.secondaryEditionId;
      ref.invalidate(editionListProvider);
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _use(EditionInstall item, AppStrings s) async {
    final repo = ref.read(bibleRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (!await repo.switchEdition(item.edition.id)) return;
    if (!mounted) return;
    ref.read(activeEditionIdProvider.notifier).state = repo.activeEditionId;
    ref.read(secondaryEditionIdProvider.notifier).state =
        repo.secondaryEditionId;
    ref.invalidate(editionListProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(s.editionSwitched(editionTitleFor(item.edition, s))),
        ),
      );
  }

  Future<void> _refresh() async {
    await ref.read(editionManagerProvider).fetchManifest(force: true);
    ref.invalidate(editionListProvider);
  }

  /// Languages present in the catalog, in catalog order, for the filter row.
  List<({String code, String name})> _languages(List<EditionInstall> items) {
    final seen = <String>{};
    final out = <({String code, String name})>[];
    for (final i in items) {
      if (seen.add(i.edition.language)) {
        out.add((code: i.edition.language, name: i.edition.languageName));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final s = L10n.of(context);
    final c = context.colors;
    final activeId = ref.watch(activeEditionIdProvider);
    final listAsync = ref.watch(editionListProvider);

    return Scaffold(
      backgroundColor: c.surfaceDim,
      appBar: AppBar(
        backgroundColor: c.surfaceDim,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          s.editionsTitle,
          style: AppTypography.amharicSubheading
              .copyWith(fontSize: 17, color: c.textOnParchment),
        ),
        actions: [
          IconButton(
            tooltip: s.editionsCheckUpdates,
            icon: Icon(Icons.refresh_rounded, size: 20, color: c.textMuted),
            onPressed: _refresh,
          ),
        ],
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
          final active = items
              .where((i) => i.edition.id == activeId)
              .firstOrNull;
          final languages = _languages(items);
          final visible = _language == null
              ? items
              : items.where((i) => i.edition.language == _language).toList();
          final installed = visible.where((i) => i.isInstalled).toList();
          final available = visible.where((i) => !i.isInstalled).toList();
          final installedTotal = items.where((i) => i.isInstalled).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
              children: [
                if (active != null) ...[
                  _ActiveEditionHero(item: active, s: s),
                  const SizedBox(height: 18),
                ],
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    s.editionsOnDeviceCount(installedTotal, items.length),
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                ),
                if (languages.length > 1)
                  _LanguageFilterRow(
                    languages: languages,
                    selected: _language,
                    allLabel: s.editionsFilterAll,
                    onChanged: (code) => setState(() => _language = code),
                  ),
                const SizedBox(height: 14),
                if (installed.isEmpty && available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      s.editionsNoneForFilter,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: c.textMuted),
                    ),
                  ),
                if (installed.isNotEmpty) ...[
                  _GroupLabel(
                    text: s.editionsInstalled,
                    count: installed.length,
                    color: c.textMuted,
                  ),
                  for (final item in installed)
                    _EditionCard(
                      item: item,
                      s: s,
                      isActive: item.edition.id == activeId,
                      progress: _progress[item.edition.id],
                      canCancel: _cancels.containsKey(item.edition.id),
                      onUse: () => _use(item, s),
                      onUpdate: () => _update(item, s),
                      onRemove: () => _remove(item, s),
                      onDownload: () => _download(item, s),
                      onCancel: () => _cancelDownload(item),
                    ),
                ],
                if (available.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _GroupLabel(
                    text: s.editionsAvailable,
                    count: available.length,
                    color: c.textMuted,
                  ),
                  for (final item in available)
                    _EditionCard(
                      item: item,
                      s: s,
                      isActive: false,
                      progress: _progress[item.edition.id],
                      canCancel: _cancels.containsKey(item.edition.id),
                      onUse: () => _use(item, s),
                      onUpdate: () => _update(item, s),
                      onRemove: () => _remove(item, s),
                      onDownload: () => _download(item, s),
                      onCancel: () => _cancelDownload(item),
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

// ── Hero ──────────────────────────────────────────────────────────────────────

/// The edition being read, given the weight of the decision it represents.
class _ActiveEditionHero extends StatelessWidget {
  const _ActiveEditionHero({required this.item, required this.s});

  final EditionInstall item;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = item.edition;
    final base = editionLanguageColor(context, e.language);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base, Color.lerp(base, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded,
                  size: 13, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Text(
                s.editionsActiveLabel.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTypography.nokiaPureheadline,
                  fontSize: 9,
                  letterSpacing: 1.4,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    e.abbrev.isNotEmpty ? e.abbrev : e.id,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTypography.shiromeda,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editionTitleFor(e, s),
                      style: TextStyle(
                        fontFamily: AppTypography.shiromeda,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      editionSubtitleFor(e, s),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _HeroPill(text: e.languageName),
              if (e.yearLabel.isNotEmpty) _HeroPill(text: e.yearLabel),
              _HeroPill(text: s.editionMetaBooks(_grouped(e.books))),
              _HeroPill(text: s.editionMetaVerses(_grouped(e.verses))),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTypography.shiromeda,
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: 0.92),
            height: 1.2,
          ),
        ),
      );
}

// ── Language filter ───────────────────────────────────────────────────────────

class _LanguageFilterRow extends StatelessWidget {
  const _LanguageFilterRow({
    required this.languages,
    required this.selected,
    required this.allLabel,
    required this.onChanged,
  });

  final List<({String code, String name})> languages;
  final String? selected;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          _FilterChip(
            label: allLabel,
            color: context.colors.primary,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final lang in languages)
            _FilterChip(
              label: lang.name,
              color: editionLanguageColor(context, lang.code),
              selected: selected == lang.code,
              onTap: () => onChanged(lang.code),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : c.borderSubtle),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.shiromeda,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : c.textMuted,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Group label ───────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({
    required this.text,
    required this.count,
    required this.color,
  });

  final String text;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
        child: Row(
          children: [
            Text(
              text.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTypography.nokiaPureheadline,
                fontSize: 9,
                letterSpacing: 1.2,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTypography.nokiaPureheadline,
                  fontSize: 9,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Divider(color: context.colors.borderSubtle, height: 1),
            ),
          ],
        ),
      );
}

// ── Edition card ──────────────────────────────────────────────────────────────

class _EditionCard extends StatelessWidget {
  const _EditionCard({
    required this.item,
    required this.s,
    required this.isActive,
    required this.progress,
    required this.canCancel,
    required this.onUse,
    required this.onUpdate,
    required this.onRemove,
    required this.onDownload,
    required this.onCancel,
  });

  final EditionInstall item;
  final AppStrings s;
  final bool isActive;
  final double? progress;
  final bool canCancel;
  final VoidCallback onUse;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  static String _size(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = item.edition;
    final lang = editionLanguageColor(context, e.language);
    final busy = progress != null;
    final needsUpdate = item.status == EditionStatus.updateAvailable;
    final size = _size(item.downloadBytes);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? lang.withValues(alpha: 0.5) : c.borderSubtle,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditionAbbrevBadge(
                  abbrev: e.abbrev.isNotEmpty ? e.abbrev : e.id,
                  color: lang,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editionTitleFor(e, s),
                        style: TextStyle(
                          fontFamily: AppTypography.shiromeda,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textOnParchment,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        editionSubtitleFor(e, s),
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 2),
                    child: _Badge(text: s.editionActive, color: lang),
                  )
                else if (item.isBundled)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 2),
                    child: _Badge(text: s.editionBuiltIn, color: c.textMuted),
                  ),
                if (item.isInstalled && !item.isBundled && !busy)
                  _OverflowMenu(
                    s: s,
                    canUpdate: needsUpdate,
                    onUpdate: onUpdate,
                    onRemove: onRemove,
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MetaPill(text: e.languageName, color: lang),
                if (e.yearLabel.isNotEmpty) _MetaPill(text: e.yearLabel),
                _MetaPill(text: s.editionMetaBooks(_grouped(e.books))),
                _MetaPill(text: s.editionMetaChapters(_grouped(e.chapters))),
                if (!item.isInstalled && size.isNotEmpty)
                  _MetaPill(text: size, icon: Icons.sd_storage_outlined),
                if (needsUpdate)
                  _MetaPill(
                    text: s.editionUpdateAvailable,
                    color: c.accentDeep,
                    icon: Icons.arrow_circle_up_rounded,
                  ),
              ],
            ),
          ),
          // Only en-kjv is public domain; every other edition belongs to a
          // Bible Society and the reader should be able to see whose it is.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              e.isPublicDomain
                  ? s.editionPublicDomain
                  : s.editionPublishedBy(e.publisher ?? '—'),
              style: TextStyle(
                fontSize: 10,
                color: c.textMuted.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
          if (busy)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress == 0 ? null : progress,
                            minHeight: 5,
                            backgroundColor: c.borderSubtle,
                            color: lang,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          progress == null || progress == 0
                              ? s.editionDownloading
                              : '${s.editionDownloading}  '
                                  '${(progress! * 100).round()}%',
                          style: TextStyle(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (canCancel)
                    IconButton(
                      tooltip: s.editionCancel,
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: c.textMuted),
                      onPressed: onCancel,
                    ),
                ],
              ),
            )
          else if (!item.isInstalled || !isActive || needsUpdate)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  if (!item.isInstalled)
                    _PrimaryAction(
                      label: s.editionDownload,
                      icon: Icons.download_rounded,
                      color: lang,
                      onTap: onDownload,
                    )
                  else if (!isActive)
                    _PrimaryAction(
                      label: s.editionUse,
                      icon: Icons.check_rounded,
                      color: lang,
                      onTap: onUse,
                    ),
                  if (needsUpdate) ...[
                    if (!isActive) const SizedBox(width: 8),
                    _SecondaryAction(
                      label: s.editionUpdate,
                      icon: Icons.arrow_circle_up_rounded,
                      onTap: onUpdate,
                    ),
                  ],
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── Card parts ────────────────────────────────────────────────────────────────

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    required this.s,
    required this.canUpdate,
    required this.onUpdate,
    required this.onRemove,
  });

  final AppStrings s;
  final bool canUpdate;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: c.textMuted),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      onSelected: (v) => v == 'update' ? onUpdate() : onRemove(),
      itemBuilder: (_) => [
        if (canUpdate)
          PopupMenuItem(
            value: 'update',
            child: Row(
              children: [
                const Icon(Icons.arrow_circle_up_rounded, size: 18),
                const SizedBox(width: 10),
                Text(s.editionUpdate),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: Color(0xFFB61F21)),
              const SizedBox(width: 10),
              Text(
                s.editionRemove,
                style: const TextStyle(color: Color(0xFFB61F21)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text, this.color, this.icon});

  final String text;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = color ?? c.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTypography.shiromeda,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: tint,
              height: 1.2,
            ),
          ),
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

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTypography.shiromeda,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.accentDeep.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c.accentDeep),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.shiromeda,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.accentDeep,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 31102 → 31,102. Verse counts are five digits and unreadable otherwise.
String _grouped(int n) {
  final digits = '$n';
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}
