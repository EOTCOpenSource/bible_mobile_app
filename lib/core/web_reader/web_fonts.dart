/// The nine reader fonts, described for the browser.
///
/// The Flutter reader gets its fonts from the `fonts:` block in `pubspec.yaml`
/// by family name; a browser needs the actual file, so this table names the
/// files as well. The order and display names deliberately match
/// `readerFonts[]` / `readerFontNames[]` in the reader's `constants.dart`, so
/// the web reader's font picker offers exactly what the app's does.
class WebFont {
  const WebFont({
    required this.family,
    required this.label,
    required this.regular,
    this.bold,
  });

  /// CSS/Flutter family name.
  final String family;

  /// What the picker shows, in Amharic like the app's picker.
  final String label;

  /// Asset filename of the regular weight, relative to `assets/fonts/`.
  final String regular;

  /// Asset filename of the 700 weight, when the family ships one.
  final String? bold;

  Map<String, dynamic> toJson() => {
        'family': family,
        'label': label,
        'regular': regular,
        if (bold != null) 'bold': bold,
      };
}

/// Directory the font files live in, inside the asset bundle.
///
/// Files declared under `fonts:` are bundled at their declared path, so
/// `rootBundle.load('assets/fonts/<file>')` reads them without also listing
/// them under `assets:`.
const kFontAssetDir = 'assets/fonts';

const kWebFonts = <WebFont>[
  WebFont(
    family: 'Shiromeda',
    label: 'ሽሮሜዳ',
    regular: 'Shiromeda_Regular_3cc9866348.ttf',
    bold: 'Shiromeda_Bold_0ad34492db.ttf',
  ),
  WebFont(
    family: 'BelaHidaseQedmo',
    label: 'በላ ሕዳሴ',
    regular: 'Bela_Hidase_Qedmo_Extra_Bold_fa986f6c22.ttf',
  ),
  WebFont(
    family: 'AbbaGarima',
    label: 'አባ ገሪማ',
    regular: 'Abba_Garima_Regular_d8040ce97a.ttf',
  ),
  WebFont(
    family: 'Selam',
    label: 'ሰላም',
    regular: 'Selam_Regular_a59259475e.otf',
  ),
  WebFont(
    family: 'EthiopicSadiss',
    label: 'ሳዲስ',
    regular: 'Ethiopic_Sadiss_Light_9f053f0273.ttf',
  ),
  WebFont(
    family: 'GeezHandwriting',
    label: 'ጊዜ',
    regular: 'Geez_Handwriting_ea6b90e5a8.ttf',
    bold: 'Geez_Handwriting_Bold_797edd48ee.ttf',
  ),
  WebFont(
    family: 'Kiros',
    label: 'ኪሮስ',
    regular: 'kiros_61f90ce99a.ttf',
  ),
  WebFont(
    family: 'AddisAbebaUnicode',
    label: 'አዲስ አበባ',
    regular: 'A0_Addis_Abeba_Unicode_20030827_e3a95c0418.ttf',
  ),
  WebFont(
    family: 'NokiaPureheadline',
    label: 'Nokia Pure',
    regular: 'Nokia_Pureheadline_Light_55fdcc36e6.ttf',
  ),
];

/// Every filename `/fonts/<name>` may serve.
///
/// An allowlist rather than a path join: `/fonts/` takes its filename from the
/// URL, and joining that onto an asset directory would let `../` walk the
/// bundle.
final Set<String> kServableFontFiles = {
  for (final f in kWebFonts) ...[f.regular, if (f.bold != null) f.bold!],
};

/// MIME type for a font file, by extension.
String fontMimeType(String filename) =>
    filename.endsWith('.otf') ? 'font/otf' : 'font/ttf';
