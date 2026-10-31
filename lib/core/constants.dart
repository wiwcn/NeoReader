/// NeoReader app-wide constants. Offline-only: no sync endpoints, no Pro gates.
class AppConstants {
  static const String appName = 'NeoReader';
  static const String appNameZh = 'NeoReader';
  static const String booksDirName = 'books';
  static const String coversDirName = 'covers';
  static const String dbName = 'neoreader.db';
  static const int dbVersion = 3;

  /// Formats with working local readers / parsers.
  static const Set<String> supportedExtensions = {
    'epub',
    'pdf',
    'txt',
    'mobi',
    'azw3',
    'azw',
    'fb2',
    'cbz',
    'cbr',
    'md',
    'markdown',
    'docx',
    'html',
    'htm',
    'xhtml',
    'mhtml',
    'mht',
  };

  /// Still planned (no working viewer path yet).
  static const Set<String> plannedExtensions = {
    'cbt',
    'cb7',
    'xml', // generic XML (non-fb2) remains planned
  };

  static const List<String> importPickerExtensions = [
    'epub',
    'pdf',
    'txt',
    'mobi',
    'azw3',
    'azw',
    'fb2',
    'cbz',
    'cbr',
    'md',
    'docx',
    'html',
    'htm',
    'xhtml',
    'mhtml',
  ];

  static const double defaultFontSize = 19;
  static const double defaultLineHeight = 1.75;
  static const String fontsDirName = 'fonts';
  static const String exportsDirName = 'exports';
}
