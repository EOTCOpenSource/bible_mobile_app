import '../../features/books/data/models/book_identity.dart';
import '../../features/books/data/models/book_index_entry.dart';

// Custom scheme — used for adb testing and as the fallback inside openinapp.html
const _kCustomScheme = 'eotcbible';
const _kCustomHost = 'openinapp';

// HTTPS App Links — what gets written to the clipboard and linkified in every app
const _kHttpsHost = '80-weahadu.vercel.app';
const _kHttpsPathPrefix = '/openinapp/';

// Slug format: {abbrev}{chapter}_{verse}
// abbrev = bookShortNameEn lowercased with spaces removed (e.g. "1 Sam" → "1sam", "Jer" → "jer")
// examples: jer29_11  ps23_14  1sam3_4
final _slugRegex = RegExp(r'^([1-9]?[a-z]+)(\d+)_(\d+)$', caseSensitive: false);

class DeepLinkTarget {
  const DeepLinkTarget({
    required this.entry,
    required this.chapter,
    required this.verse,
  });
  final BookIndexEntry entry;
  final int chapter;
  final int verse;
}

/// Encodes a verse reference as a slug, e.g. `jer29_11`, `1sam3_4`.
///
/// Built from the frozen abbreviation table rather than the entry's own
/// [BookIndexEntry.bookShortNameEn], so the slug for a verse is the same
/// whichever edition the reader happens to have active — a link shared from the
/// Ge'ez edition has to open for someone reading Amharic.
String verseDeepLinkSlug(BookIndexEntry entry, int chapter, int verse) =>
    '${deepLinkSlugFromUsfm(entry.id)}${chapter}_$verse';

/// HTTPS URI for the clipboard — linkified by Telegram, WhatsApp, Chrome, etc.
/// e.g. `https://80-weahadu.vercel.app/openinapp/jer29_11`
Uri verseDeepLinkUri(BookIndexEntry entry, int chapter, int verse) => Uri(
      scheme: 'https',
      host: _kHttpsHost,
      path: '$_kHttpsPathPrefix${verseDeepLinkSlug(entry, chapter, verse)}',
    );

/// Parses both the HTTPS App Link and the custom `eotcbible://` scheme into a
/// [DeepLinkTarget], returning null when the URI doesn't match or the book is unknown.
DeepLinkTarget? parseDeepLink(Uri uri, List<BookIndexEntry> index) {
  String? slug;

  if (uri.scheme == _kCustomScheme && uri.host == _kCustomHost) {
    // eotcbible://openinapp/jer29_11
    slug = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == _kHttpsHost &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments[0] == 'openinapp') {
    // https://80-weahadu.vercel.app/openinapp/jer29_11
    slug = uri.pathSegments[1];
  }

  if (slug == null || slug.isEmpty) return null;
  final match = _slugRegex.firstMatch(slug);
  if (match == null) return null;

  final abbrev = match.group(1)!.toLowerCase();
  final chapter = int.parse(match.group(2)!);
  final verse = int.parse(match.group(3)!);

  final usfm = usfmFromDeepLinkSlug(abbrev);
  if (usfm == null) return null;

  // The link may name a book this edition does not contain — a deuterocanonical
  // reference opened while reading the protestant 66, say. That is a miss, not
  // a malformed link, and the caller shows "verse not found" either way.
  final entry = index.cast<BookIndexEntry?>().firstWhere(
    (e) => e!.id == usfm,
    orElse: () => null,
  );
  if (entry == null) return null;
  return DeepLinkTarget(entry: entry, chapter: chapter, verse: verse);
}
