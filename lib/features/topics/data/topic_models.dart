import 'package:flutter/foundation.dart' show immutable;

@immutable
class TopicEntry {
  const TopicEntry({
    required this.id,
    required this.labelAm,
    required this.labelEn,
    required this.icon,
    this.image,
    required this.keywords,
  });

  final String id;
  final String labelAm;
  final String labelEn;
  final String icon;
  final String? image;
  final List<String> keywords;

  factory TopicEntry.fromJson(Map<String, dynamic> json) {
    return TopicEntry(
      id: json['id'] as String,
      labelAm: json['labelAm'] as String,
      labelEn: json['labelEn'] as String,
      icon: json['icon'] as String,
      image: json['image'] as String?,
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// A search hit resolved back to a topic for display.
@immutable
class TopicVerse {
  const TopicVerse({
    required this.bookNameAm,
    required this.bookNameEn,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.bookIndexEntry,
  });

  final String bookNameAm;
  final String bookNameEn;
  final int chapter;
  final int verse;
  final String text;
  final dynamic bookIndexEntry; // BookIndexEntry
}
