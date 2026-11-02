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

/// A non-verse destination inside the app, reached by the same `openinapp`
/// links the home screen widgets carry.
///
/// Deliberately a separate vocabulary from the verse slug rather than an
/// extension of it. Every route name here is barred from matching
/// [_slugRegex] — a route has no trailing `{chapter}_{verse}` — so adding one
/// can never shadow a book abbreviation, and links shared before these
/// existed keep resolving exactly as they did.
enum AppRoute {
  /// The reading streak page.
  streak('streak');

  const AppRoute(this.slug);

  /// The path segment that names this route, e.g. `eotcbible://openinapp/streak`.
  final String slug;
}

/// Extracts the `openinapp` slug from either supported URI form, or null when
/// the URI is not one of ours.
///
/// Shared by [parseDeepLink] and [parseAppRoute] so the two vocabularies can
/// never disagree about which URIs belong to this app.
String? _openInAppSlug(Uri uri) {
  if (uri.scheme == _kCustomScheme && uri.host == _kCustomHost) {
    // eotcbible://openinapp/jer29_11
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == _kHttpsHost &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments[0] == 'openinapp') {
    // https://80-weahadu.vercel.app/openinapp/jer29_11
    return uri.pathSegments[1];
  }
  return null;
}

/// URI for a non-verse destination, e.g. `eotcbible://openinapp/streak`.
///
/// Custom scheme rather than HTTPS: these are only ever produced by this app's
/// own home screen widgets, never shared, so there is nothing for a browser to
/// fall back to.
Uri appRouteUri(AppRoute route) => Uri(
      scheme: _kCustomScheme,
      host: _kCustomHost,
      path: '/${route.slug}',
    );

/// Parses [uri] as an [AppRoute], or null when it names a verse or nothing
/// this app knows.
///
/// Callers try this **before** [parseDeepLink]: a route slug carries no
/// chapter or verse, so the verse parser would reject it and report the link
/// as broken.
AppRoute? parseAppRoute(Uri uri) {
  final slug = _openInAppSlug(uri)?.toLowerCase();
  if (slug == null || slug.isEmpty) return null;
  for (final route in AppRoute.values) {
    if (route.slug == slug) return route;
  }
  return null;
}

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
  final slug = _openInAppSlug(uri);
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
