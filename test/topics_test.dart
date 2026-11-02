import 'package:flutter_test/flutter_test.dart';
import 'package:bibleflutter/features/topics/data/topic_models.dart';

void main() {
  group('Topic Models & Deserialization', () {
    test('TopicEntry fromJson parses search keywords', () {
      final json = {
        'id': 'prayer',
        'labelAm': 'ጸሎት',
        'labelEn': 'Prayer',
        'icon': '🙏',
        'image': 'assets/topics/images/prayer.png',
        'keywords': ['ጸሎት', 'ጸልዩ', 'ጸለየ']
      };

      final topic = TopicEntry.fromJson(json);
      expect(topic.id, 'prayer');
      expect(topic.labelAm, 'ጸሎት');
      expect(topic.labelEn, 'Prayer');
      expect(topic.icon, '🙏');
      expect(topic.image, 'assets/topics/images/prayer.png');
      expect(topic.keywords.length, 3);
      expect(topic.keywords[0], 'ጸሎት');
      expect(topic.keywords[1], 'ጸልዩ');
    });
  });
}
