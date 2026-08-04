import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/topic_models.dart';
import '../pages/topic_detail_screen.dart';
import '../../providers/topic_providers.dart';

/// The topic strip on Home.
///
/// Sized by its parent rather than by a hardcoded height: Home is a single
/// non-scrolling screen, so this has to give way when the screen is short
/// instead of pushing something off the bottom.
class TopicsSection extends ConsumerWidget {
  const TopicsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isAm = L10n.of(context) is AmStrings;
    final topicsAsync = ref.watch(topicsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isAm ? 'አርእስቶች' : 'Topics',
            style: AppTypography.amharicSubheading.copyWith(
              color: c.textOnParchment,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: topicsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (topics) => LayoutBuilder(
              builder: (context, constraints) {
                // Cards are a portrait rectangle keyed off the height on
                // offer, so the strip stays proportional whatever it is given.
                final height = constraints.maxHeight;
                final width = (height * 0.82).clamp(88.0, 140.0);

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: topics.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _TopicCard(
                    topic: topics[i],
                    label: isAm ? topics[i].labelAm : topics[i].labelEn,
                    width: width,
                    colors: c,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A topic as its own picture, with the name burned into the bottom edge.
///
/// The image is the card rather than a 36px thumbnail above two lines of text —
/// these are hand-picked icons, and shrinking them to a corner wasted them and
/// left the card looking like a form row.
class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.label,
    required this.width,
    required this.colors,
  });

  final TopicEntry topic;
  final String label;
  final double width;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return SizedBox(
      width: width,
      child: Material(
        color: c.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TopicDetailScreen(topic: topic),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (topic.image != null)
                Image.asset(
                  topic.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _IconFallback(topic: topic, colors: c),
                )
              else
                _IconFallback(topic: topic, colors: c),
              // Scrim only under the text: enough to keep the label readable on
              // a bright image without dulling the artwork above it.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.amharicLabel.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.topic, required this.colors});

  final TopicEntry topic;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.primary.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Text(topic.icon, style: const TextStyle(fontSize: 30)),
    );
  }
}
