import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

class EpubChapter {
  EpubChapter({required this.title, required this.href, required this.content});
  final String title;
  final String href;
  final String content;
}

class EpubBookData {
  EpubBookData({
    required this.title,
    required this.author,
    required this.chapters,
    this.coverBytes,
  });

  final String title;
  final String author;
  final List<EpubChapter> chapters;
  final Uint8List? coverBytes;
}

/// Lightweight EPUB parser (ZIP + OPF + XHTML) — no epubx dependency.
class EpubParser {
  Future<EpubBookData> parseFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return parseBytes(bytes);
  }

  EpubBookData parseBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final map = <String, ArchiveFile>{};
    for (final f in archive.files) {
      if (f.isFile) {
        map[f.name.replaceAll('\\', '/')] = f;
      }
    }

    final containerFile = map['META-INF/container.xml'];
    if (containerFile == null) {
      throw StateError('Invalid EPUB: missing META-INF/container.xml');
    }
    final containerXml =
        XmlDocument.parse(utf8.decode(containerFile.content as List<int>));
    final rootfile = containerXml
        .findAllElements('rootfile')
        .map((e) => e.getAttribute('full-path'))
        .whereType<String>()
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (rootfile.isEmpty) {
      throw StateError('Invalid EPUB: missing rootfile');
    }

    final opfPath = rootfile;
    final opfDir = p.posix.dirname(opfPath);
    final opfFile = _get(map, opfPath);
    final opf = XmlDocument.parse(utf8.decode(opfFile.content as List<int>));

    final title = _firstText(opf, const ['dc:title', 'title']) ?? 'Untitled';
    final author = _firstText(opf, const ['dc:creator', 'creator']) ?? 'Unknown';

    final manifest = <String, String>{};
    String? coverId;
    String? coverHref;
    for (final item in opf.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id != null && href != null) {
        manifest[id] = href;
        final props = item.getAttribute('properties') ?? '';
        if (props.contains('cover-image')) {
          coverHref = href;
        }
        final media = item.getAttribute('media-type') ?? '';
        if (media.startsWith('image/') && id.toLowerCase().contains('cover')) {
          coverId ??= id;
        }
      }
    }
    for (final meta in opf.findAllElements('meta')) {
      if (meta.getAttribute('name') == 'cover') {
        coverId = meta.getAttribute('content') ?? coverId;
      }
    }
    coverHref ??= coverId != null ? manifest[coverId] : null;

    Uint8List? coverBytes;
    if (coverHref != null) {
      final coverPath = p.posix.normalize(p.posix.join(opfDir, coverHref));
      final cf = _tryGet(map, coverPath);
      if (cf != null) {
        coverBytes = Uint8List.fromList(cf.content as List<int>);
      }
    }

    final spineHrefs = <String>[];
    for (final itemref in opf.findAllElements('itemref')) {
      final idref = itemref.getAttribute('idref');
      if (idref != null && manifest.containsKey(idref)) {
        spineHrefs.add(manifest[idref]!);
      }
    }

    final chapters = <EpubChapter>[];
    for (final href in spineHrefs) {
      final full = p.posix.normalize(p.posix.join(opfDir, href));
      final file = _tryGet(map, full);
      if (file == null) continue;
      final raw = utf8.decode(file.content as List<int>, allowMalformed: true);
      final doc = html_parser.parse(raw);
      final text =
          doc.body?.text.replaceAll(RegExp(r'[ \t]+\n'), '\n').trim() ?? '';
      if (text.isEmpty) continue;
      final heading = doc.querySelector('h1,h2,h3,title')?.text.trim();
      chapters.add(
        EpubChapter(
          title: (heading == null || heading.isEmpty)
              ? 'Chapter ${chapters.length + 1}'
              : heading,
          href: href,
          content: text,
        ),
      );
    }

    if (chapters.isEmpty) {
      chapters.add(EpubChapter(title: title, href: '', content: title));
    }

    return EpubBookData(
      title: title.isEmpty ? 'Untitled' : title,
      author: author.isEmpty ? 'Unknown' : author,
      chapters: chapters,
      coverBytes: coverBytes,
    );
  }

  String? _firstText(XmlDocument doc, List<String> names) {
    for (final name in names) {
      for (final el in doc.findAllElements(name)) {
        final t = el.innerText.trim();
        if (t.isNotEmpty) return t;
      }
      final local = name.contains(':') ? name.split(':').last : name;
      for (final el in doc.descendants.whereType<XmlElement>()) {
        if (el.name.local == local) {
          final t = el.innerText.trim();
          if (t.isNotEmpty) return t;
        }
      }
    }
    return null;
  }

  ArchiveFile _get(Map<String, ArchiveFile> map, String path) {
    final f = _tryGet(map, path);
    if (f == null) throw StateError('Missing EPUB entry: $path');
    return f;
  }

  ArchiveFile? _tryGet(Map<String, ArchiveFile> map, String path) {
    final normalized = path.replaceAll('\\', '/');
    if (map.containsKey(normalized)) return map[normalized];
    final lower = normalized.toLowerCase();
    for (final e in map.entries) {
      if (e.key.toLowerCase() == lower) return e.value;
    }
    return null;
  }
}
