import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'text_content.dart';

class DocxParser {
  Future<TextContent> parseFile(String path, {String? fallbackTitle}) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? docFile;
    for (final f in archive.files) {
      if (f.name.replaceAll('\\', '/') == 'word/document.xml') {
        docFile = f;
        break;
      }
    }
    if (docFile == null) {
      throw StateError('Invalid DOCX: missing word/document.xml');
    }
    final xml = utf8.decode(docFile.content as List<int>, allowMalformed: true);
    final doc = XmlDocument.parse(xml);
    final buf = StringBuffer();
    for (final p in doc.findAllElements('w:p')) {
      final texts = p.findAllElements('w:t').map((e) => e.innerText).join();
      if (texts.trim().isEmpty) {
        buf.writeln();
      } else {
        buf.writeln(texts);
      }
    }
    // Also try without namespace prefix
    if (buf.isEmpty) {
      for (final el in doc.descendants.whereType<XmlElement>()) {
        if (el.name.local == 't') {
          buf.write(el.innerText);
        } else if (el.name.local == 'p') {
          buf.writeln();
        }
      }
    }

    String author = 'DOCX';
    for (final f in archive.files) {
      if (f.name.replaceAll('\\', '/') == 'docProps/core.xml') {
        try {
          final core = XmlDocument.parse(
            utf8.decode(f.content as List<int>, allowMalformed: true),
          );
          for (final e in core.findAllElements('dc:creator')) {
            final t = e.innerText.trim();
            if (t.isNotEmpty) author = t;
          }
          for (final e in core.findAllElements('dc:title')) {
            final t = e.innerText.trim();
            if (t.isNotEmpty) {
              return TextContent(
                title: t,
                author: author,
                body: buf.toString().trim(),
              );
            }
          }
        } catch (_) {}
      }
    }

    return TextContent(
      title: fallbackTitle ?? 'Document',
      author: author,
      body: buf.toString().trim().isEmpty
          ? '(empty document)'
          : buf.toString().trim(),
    );
  }
}
