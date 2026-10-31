/// NeoReader app-wide constants. Offline-only: no sync endpoints, no Pro gates.
class AppConstants {
  static const String appName = 'NeoReader';
  static const String appNameZh = 'NeoReader';
  static const String booksDirName = 'books';
  static const String coversDirName = 'covers';
  static const String dbName = 'neoreader.db';
  static const int dbVersion = 2;

  /// Supported import extensions for v1 core.
  static const Set<String> supportedExtensions = {
    'epub',
    'pdf',
    'txt',
  };

  /// Scaffolded formats (parsers planned / stubbed).
  static const Set<String> plannedExtensions = {
    'mobi',
    'azw3',
    'azw',
    'fb2',
    'cbr',
    'cbz',
    'cbt',
    'cb7',
    'md',
    'docx',
    'html',
    'htm',
    'xhtml',
    'xml',
    'mhtml',
  };

  static const double defaultFontSize = 18;
  static const double defaultLineHeight = 1.6;
}
