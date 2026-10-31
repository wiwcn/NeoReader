import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/book.dart';

enum AnnotationExportFormat { markdown, txt }

class AnnotationExportResult {
  const AnnotationExportResult({
    required this.primaryPath,
    this.secondaryPath,
    this.pickedUri,
  });

  final String primaryPath;
  final String? secondaryPath;
  final Uri? pickedUri;
}

class AnnotationExportService {
  Future<AnnotationExportResult> export({
    required List<Annotation> annotations,
    required List<Book> books,
    required AnnotationExportFormat format,
    bool alsoWriteCompanion = true,
    bool offerSavePicker = true,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, AppConstants.exportsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final mdBody = _buildMarkdown(annotations, books);
    final txtBody = _buildTxt(annotations, books);

    final mdPath = p.join(dir.path, 'annotations_$stamp.md');
    final txtPath = p.join(dir.path, 'annotations_$stamp.txt');
    await File(mdPath).writeAsString(mdBody, flush: true);
    await File(txtPath).writeAsString(txtBody, flush: true);

    final primaryPath = format == AnnotationExportFormat.markdown
        ? mdPath
        : txtPath;
    final primaryBytes = utf8.encode(
      format == AnnotationExportFormat.markdown ? mdBody : txtBody,
    );
    final fileName = p.basename(primaryPath);
    final mime = format == AnnotationExportFormat.markdown
        ? 'text/markdown'
        : 'text/plain';

    Uri? picked;
    if (offerSavePicker) {
      try {
        picked = await FilePicker.saveFile(
          fileName: fileName,
          bytes: primaryBytes,
          mimeType: mime,
          dialogTitle: 'NeoReader',
        );
      } catch (_) {
        picked = null;
      }
    }

    return AnnotationExportResult(
      primaryPath: primaryPath,
      secondaryPath: alsoWriteCompanion
          ? (format == AnnotationExportFormat.markdown ? txtPath : mdPath)
          : null,
      pickedUri: picked,
    );
  }

  String _bookTitle(List<Book> books, String id) {
    for (final b in books) {
      if (b.id == id) return b.title;
    }
    return id;
  }

  String _typeLabel(AnnotationType t) => switch (t) {
    AnnotationType.bookmark => 'bookmark',
    AnnotationType.highlight => 'highlight',
    AnnotationType.note => 'note',
  };

  Map<String, List<Annotation>> _group(
    List<Annotation> annotations,
    List<Book> books,
  ) {
    final map = <String, List<Annotation>>{};
    for (final a in annotations) {
      final title = _bookTitle(books, a.bookId);
      map.putIfAbsent(title, () => []).add(a);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return map;
  }

  String _buildMarkdown(List<Annotation> annotations, List<Book> books) {
    final buf = StringBuffer();
    buf.writeln('# NeoReader Annotations');
    buf.writeln();
    buf.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buf.writeln();
    final grouped = _group(annotations, books);
    if (grouped.isEmpty) {
      buf.writeln('_No annotations._');
      return buf.toString();
    }
    for (final entry in grouped.entries) {
      buf.writeln('## ${entry.key}');
      buf.writeln();
      for (final a in entry.value) {
        buf.writeln('### ${_typeLabel(a.type)}');
        if (a.chapter != null && a.chapter!.isNotEmpty) {
          buf.writeln('- Chapter: ${a.chapter}');
        }
        if (a.progress != null) {
          buf.writeln('- Progress: ${(a.progress! * 100).toStringAsFixed(0)}%');
        }
        buf.writeln('- Time: ${a.createdAt.toIso8601String()}');
        if (a.selectedText != null && a.selectedText!.isNotEmpty) {
          buf.writeln();
          buf.writeln('> ${a.selectedText}');
        }
        if (a.note != null && a.note!.isNotEmpty) {
          buf.writeln();
          buf.writeln(a.note);
        }
        buf.writeln();
      }
    }
    return buf.toString();
  }

  String _buildTxt(List<Annotation> annotations, List<Book> books) {
    final buf = StringBuffer();
    buf.writeln('NeoReader Annotations');
    buf.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buf.writeln('=' * 40);
    final grouped = _group(annotations, books);
    if (grouped.isEmpty) {
      buf.writeln('No annotations.');
      return buf.toString();
    }
    for (final entry in grouped.entries) {
      buf.writeln();
      buf.writeln('[${entry.key}]');
      buf.writeln('-' * 40);
      for (final a in entry.value) {
        buf.writeln('Type: ${_typeLabel(a.type)}');
        if (a.chapter != null && a.chapter!.isNotEmpty) {
          buf.writeln('Chapter: ${a.chapter}');
        }
        if (a.progress != null) {
          buf.writeln('Progress: ${(a.progress! * 100).toStringAsFixed(0)}%');
        }
        buf.writeln('Time: ${a.createdAt.toIso8601String()}');
        if (a.selectedText != null && a.selectedText!.isNotEmpty) {
          buf.writeln('Text: ${a.selectedText}');
        }
        if (a.note != null && a.note!.isNotEmpty) {
          buf.writeln('Note: ${a.note}');
        }
        buf.writeln();
      }
    }
    return buf.toString();
  }
}
