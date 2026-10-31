import '../../core/constants.dart';
import '../../domain/models/book.dart';

/// Registry for format handlers.
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

  /// Remaining Koodo offline modules still scaffolded (formats above are shipping).
  static const plannedModules = <String, String>{
    'format.comic_rar_7z':
        'Comic RAR/7z (cbr full / cbt / cb7) — use CBZ for now',
    'reader.two_column': 'Two-column layout',
    'reader.tts': 'Text-to-speech (local)',
    'reader.dictionary': 'Local MDX dictionary',
    'reader.ocr': 'Local OCR',
    'reader.translation': 'Local translation plugins',
    'library.export_books': 'One-click export all books',
    'library.export_notes_extra': 'Notes export CSV / HTML / PDF',
    'library.lock': 'PIN / biometric library lock',
    'library.snapshot': 'Library snapshots / version control',
  };
}
