import 'package:kenat/kenat.dart';
import 'models/book_index_entry.dart';

class ParsedReference {
  const ParsedReference({
    required this.book,
    required this.chapter,
    this.verse,
    required this.confidence,
  });

  final BookIndexEntry book;
  final int chapter;
  final int? verse;
  final double confidence;
}

List<ParsedReference> parseReference(
  String input,
  List<BookIndexEntry> index, {
  bool useGeezNumbers = false,
}) {
  final cleanInput = input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleanInput.isEmpty) return [];

  String bookPart = cleanInput;
  String? cStr;
  String? vStr;

  final regex1 = RegExp(r'^(.+?)\s+(\d+|[፩-፼]+)\s+(\d+|[፩-፼]+)$');
  final regex2 = RegExp(r'^(.+?)\s*(\d+|[፩-፼]+)\s*[:፥፦]\s*(\d+|[፩-፼]+)$');
  final regex3 = RegExp(r'^(.+?)\s+(\d+|[፩-፼]+)$');
  final regex4 = RegExp(r'^([a-z]+|[\u1200-\u137F]+)(\d+|[፩-፼]+)(?:\s*[:፥፦]\s*(\d+|[፩-፼]+))?$');

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
    vStr = m.group(3);
  }

  int? parseNumber(String? str) {
    if (str == null || str.isEmpty) return null;
    final val = int.tryParse(str);
    if (val != null) return val;
    try {
      return toArabic(str);
    } catch (_) {
      return null;
    }
  }

  final chapter = parseNumber(cStr);
  final verse = parseNumber(vStr);

  if (chapter == null || chapter <= 0) return [];

  final queryBook = bookPart.trim();
  final candidates = <ParsedReference>[];

  final aliases = {
    'ሄኖክ': ['ENO'],
    'enoch': ['ENO'],
    'ኩፋሌ': ['JUB'],
    'jubilees': ['JUB'],
    'መቃ': ['1MA', '2MA', '3MA'],
    'maccabees': ['1MA', '2MA', '3MA'],
    'jn': ['JHN'],
  };

  for (final book in index) {
    if (book.chapterCount != null && chapter > book.chapterCount!) {
      continue;
    }

    double conf = 0.0;
    final aliasList = aliases[queryBook];
    if (aliasList != null && aliasList.contains(book.id)) {
      conf = 1.0;
    } else {
      final names = [
        book.bookNameAm.toLowerCase(),
        book.bookNameEn.toLowerCase(),
        book.bookShortNameAm.toLowerCase(),
        book.bookShortNameEn.toLowerCase(),
      ];
      
      final cleanQuery = queryBook.replaceAll(' ', '');
      for (final name in names) {
        final cleanName = name.replaceAll(' ', '');
        if (cleanName == cleanQuery) {
          conf = 1.0;
          break;
        } else if (cleanName.startsWith(cleanQuery)) {
          final c = cleanQuery.length / cleanName.length;
          if (c > conf) conf = c;
        }
      }
    }

    if (conf > 0.0) {
      candidates.add(ParsedReference(
        book: book,
        chapter: chapter,
        verse: verse,
        confidence: conf,
      ));
    }
  }

  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  return candidates;
}
