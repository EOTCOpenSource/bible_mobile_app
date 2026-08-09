import 'package:flutter/foundation.dart';

/// Immutable model representing an Ethiopian Orthodox Tewahedo Bible book introduction.
@immutable
class BookIntroduction {
  final int bookNumber;
  final String author;
  final String period;
  final String summary;
  final List<String> themes;
  final List<OutlineEntry> outline;

  // Raw un-resolved fields stored for dynamic re-localization
  final String authorAm;
  final String authorEn;
  final String periodAm;
  final String periodEn;
  final String summaryAm;
  final String summaryEn;
  final List<String> themesAm;
  final List<String> themesEn;
  final List<Map<String, dynamic>> rawOutline;

  const BookIntroduction({
    required this.bookNumber,
    required this.author,
    required this.period,
    required this.summary,
    required this.themes,
    required this.outline,
    this.authorAm = '',
    this.authorEn = '',
    this.periodAm = '',
    this.periodEn = '',
    this.summaryAm = '',
    this.summaryEn = '',
    this.themesAm = const [],
    this.themesEn = const [],
    this.rawOutline = const [],
  });

  /// Explicit, null-safe factory constructor to create [BookIntroduction] from JSON.
  factory BookIntroduction.fromJson(
    Map<String, dynamic> json,
    int bookNumber, {
    String locale = 'am',
  }) {
    final authorAm = json['authorAm'] as String? ?? '';
    final authorEn = json['authorEn'] as String? ?? '';
    final periodAm = json['periodAm'] as String? ?? '';
    final periodEn = json['periodEn'] as String? ?? '';
    final summaryAm = json['summaryAm'] as String? ?? '';
    final summaryEn = json['summaryEn'] as String? ?? '';

    final themesAmRaw = (json['themesAm'] as List?)?.cast<String>() ?? const <String>[];
    final themesEnRaw = (json['themesEn'] as List?)?.cast<String>() ?? const <String>[];

    final rawOutlineList = (json['outline'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];

    final isEn = locale.toLowerCase().startsWith('en');

    final resolvedAuthor = _resolveString(isEn ? authorEn : authorAm, isEn ? authorAm : authorEn);
    final resolvedPeriod = _resolveString(isEn ? periodEn : periodAm, isEn ? periodAm : periodEn);
    final resolvedSummary = _resolveString(isEn ? summaryEn : summaryAm, isEn ? summaryAm : summaryEn);

    final primaryThemes = isEn ? themesEnRaw : themesAmRaw;
    final fallbackThemes = isEn ? themesAmRaw : themesEnRaw;
    final resolvedThemes = primaryThemes.isNotEmpty ? primaryThemes : fallbackThemes;

    final resolvedOutline = rawOutlineList
        .map((entryJson) => OutlineEntry.fromJson(entryJson, locale: locale))
        .toList();

    return BookIntroduction(
      bookNumber: bookNumber,
      author: resolvedAuthor,
      period: resolvedPeriod,
      summary: resolvedSummary,
      themes: List.unmodifiable(resolvedThemes),
      outline: List.unmodifiable(resolvedOutline),
      authorAm: authorAm,
      authorEn: authorEn,
      periodAm: periodAm,
      periodEn: periodEn,
      summaryAm: summaryAm,
      summaryEn: summaryEn,
      themesAm: List.unmodifiable(themesAmRaw),
      themesEn: List.unmodifiable(themesEnRaw),
      rawOutline: List.unmodifiable(rawOutlineList),
    );
  }

  /// Returns a new instance resolved for the given [locale].
  BookIntroduction forLocale(String locale) {
    final isEn = locale.toLowerCase().startsWith('en');

    final resolvedAuthor = _resolveString(isEn ? authorEn : authorAm, isEn ? authorAm : authorEn);
    final resolvedPeriod = _resolveString(isEn ? periodEn : periodAm, isEn ? periodAm : periodEn);
    final resolvedSummary = _resolveString(isEn ? summaryEn : summaryAm, isEn ? summaryAm : summaryEn);

    final primaryThemes = isEn ? themesEn : themesAm;
    final fallbackThemes = isEn ? themesAm : themesEn;
    final resolvedThemes = primaryThemes.isNotEmpty ? primaryThemes : fallbackThemes;

    final resolvedOutline = rawOutline
        .map((entryJson) => OutlineEntry.fromJson(entryJson, locale: locale))
        .toList();

    return BookIntroduction(
      bookNumber: bookNumber,
      author: resolvedAuthor,
      period: resolvedPeriod,
      summary: resolvedSummary,
      themes: List.unmodifiable(resolvedThemes),
      outline: List.unmodifiable(resolvedOutline),
      authorAm: authorAm,
      authorEn: authorEn,
      periodAm: periodAm,
      periodEn: periodEn,
      summaryAm: summaryAm,
      summaryEn: summaryEn,
      themesAm: themesAm,
      themesEn: themesEn,
      rawOutline: rawOutline,
    );
  }

  static String _resolveString(String primary, String fallback) {
    if (primary.trim().isNotEmpty) return primary;
    if (fallback.trim().isNotEmpty) return fallback;
    return '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookIntroduction &&
          runtimeType == other.runtimeType &&
          bookNumber == other.bookNumber &&
          author == other.author &&
          period == other.period &&
          summary == other.summary &&
          listEquals(themes, other.themes) &&
          listEquals(outline, other.outline);

  @override
  int get hashCode =>
      bookNumber.hashCode ^
      author.hashCode ^
      period.hashCode ^
      summary.hashCode ^
      Object.hashAll(themes) ^
      Object.hashAll(outline);
}

/// Represents an entry in a book's thematic or structural outline.
@immutable
class OutlineEntry {
  final String title;
  final int fromChapter;
  final int toChapter;

  final String titleAm;
  final String titleEn;

  const OutlineEntry({
    required this.title,
    required this.fromChapter,
    required this.toChapter,
    this.titleAm = '',
    this.titleEn = '',
  });

  factory OutlineEntry.fromJson(
    Map<String, dynamic> json, {
    String locale = 'am',
  }) {
    final titleAm = json['titleAm'] as String? ?? '';
    final titleEn = json['titleEn'] as String? ?? '';

    final isEn = locale.toLowerCase().startsWith('en');
    final primary = isEn ? titleEn : titleAm;
    final fallback = isEn ? titleAm : titleEn;

    String resolved = '';
    if (primary.trim().isNotEmpty) {
      resolved = primary;
    } else if (fallback.trim().isNotEmpty) {
      resolved = fallback;
    }

    final from = (json['fromChapter'] as num?)?.toInt() ?? 1;
    final rawTo = (json['toChapter'] as num?)?.toInt() ?? from;
    final to = rawTo >= from ? rawTo : from;

    return OutlineEntry(
      title: resolved,
      fromChapter: from,
      toChapter: to,
      titleAm: titleAm,
      titleEn: titleEn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutlineEntry &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          fromChapter == other.fromChapter &&
          toChapter == other.toChapter;

  @override
  int get hashCode => Object.hash(title, fromChapter, toChapter);
}
