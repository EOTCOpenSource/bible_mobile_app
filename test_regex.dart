import 'package:kenat/kenat.dart';

void main() {
  final inputs = [
    'ዮሐ 3:16',
    'ዮሐንስ 3፥16',
    'john 3:16',
    'jn3:16',
    '1ሳሙ 17',
    '1 sam 17 4',
    '፹፩ 3',
    '1 john 3:16',
    '1Jn3:16',
    'Enoch 1 1',
  ];

  for (final input in inputs) {
    print('Testing: $input');
    final cleanInput = input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    
    String bookPart = cleanInput;
    String? cStr;
    String? vStr;
    
    final regex1 = RegExp(r'^(.+?)\s+(\d+|[፩-፼]+)\s+(\d+|[፩-፼]+)$'); // "1 sam 17 4"
    final regex2 = RegExp(r'^(.+?)\s*(\d+|[፩-፼]+)\s*[:፥፦]\s*(\d+|[፩-፼]+)$'); // "john 3:16", "jn3:16"
    final regex3 = RegExp(r'^(.+?)\s+(\d+|[፩-፼]+)$'); // "1ሳሙ 17"
    final regex4 = RegExp(r'^([a-z]+|[\u1200-\u137F]+)(\d+|[፩-፼]+)$'); // "jn3"

    if (regex2.hasMatch(cleanInput)) {
      final m = regex2.firstMatch(cleanInput)!;
      bookPart = m.group(1)!;
      cStr = m.group(2)!;
      vStr = m.group(3)!;
    } else if (regex1.hasMatch(cleanInput)) {
      final m = regex1.firstMatch(cleanInput)!;
      bookPart = m.group(1)!;
      cStr = m.group(2)!;
      vStr = m.group(3)!;
    } else if (regex3.hasMatch(cleanInput)) {
      final m = regex3.firstMatch(cleanInput)!;
      bookPart = m.group(1)!;
      cStr = m.group(2)!;
    } else if (regex4.hasMatch(cleanInput)) {
      final m = regex4.firstMatch(cleanInput)!;
      bookPart = m.group(1)!;
      cStr = m.group(2)!;
    }
    
    print('  Book: $bookPart');
    print('  Chapter: $cStr');
    print('  Verse: $vStr');
  }
}
