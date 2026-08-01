import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../pages/topic_detail_screen.dart';
import '../../providers/topic_providers.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            isAm ? 'አርእስቶች' : 'Topics',
            style: TextStyle(
              color: c.textBody,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: topicsAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: c.accent),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (topics) {
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: topics.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (ctx, idx) {
                  final topic = topics[idx];
                  final label = isAm ? topic.labelAm : topic.labelEn;

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TopicDetailScreen(topic: topic),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.surfaceDim,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.borderSubtle,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          topic.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    topic.image!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  topic.icon,
                                  style: const TextStyle(fontSize: 28),
                                ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              color: c.textBody,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${topic.keywords.length} ${isAm ? "ቁልፍ ቃላት" : "keywords"}',
                            style: TextStyle(
                              color: c.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
