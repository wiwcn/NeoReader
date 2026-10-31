import '../../core/constants.dart';
import '../../domain/models/book.dart';

/// Registry for format handlers. v1 implements epub/pdf/txt;
/// other Koodo formats are scaffolded as planned modules.
enum FormatSupport { implemented, planned, unsupported }

class FormatRegistry {
  static FormatSupport supportFor(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (AppConstants.supportedExtensions.contains(ext)) {
      return FormatSupport.implemented;
    }
    if (AppConstants.plannedExtensions.contains(ext)) {
      return FormatSupport.planned;
    }
    return FormatSupport.unsupported;
  }

  static BookFormat toBookFormat(String extension) =>
      bookFormatFromExtension(extension);

  /// Scaffolded module ids matching Koodo offline feature surface.
  static const plannedModules = <String, String>{
    'format.mobi_azw': 'Mobipocket / Kindle (mobi, azw3, azw)',
    'format.fb2': 'FictionBook (fb2)',
    'format.comic': 'Comic archives (cbr/cbz/cbt/cb7)',
    'format.richtext': 'Markdown / DOCX',
    'format.html': 'HTML / XHTML / MHTML',
    'reader.vertical': 'Vertical layout',
    'reader.two_column': 'Two-column layout',
    'reader.tts': 'Text-to-speech (local)',
    'reader.dictionary': 'Local MDX dictionary',
    'reader.ocr': 'Local OCR',
    'reader.translation': 'Local translation plugins',
    'library.export': 'One-click export books / notes (CSV/MD/HTML/TXT/PDF)',
    'library.lock': 'PIN / biometric library lock',
    'library.snapshot': 'Library snapshots / version control',
    'stats.charts': 'Rich reading statistics charts',
  };
}
