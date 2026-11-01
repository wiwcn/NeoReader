import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/dom.dart' as hdom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

class EpubChapter {
  EpubChapter({required this.title, required this.href, required this.content});
  final String title;
  final String href;
  final String content;
}

/// Flattened TOC item aligned to a spine chapter index when possible.
class EpubTocEntry {
  EpubTocEntry({
    required this.title,
    required this.href,
    required this.spineIndex,
    this.level = 0,
  });

  final String title;
  final String href;

  /// Index into [EpubBookData.chapters], or -1 if unmatched.
  final int spineIndex;
  final int level;
}

class EpubBookData {
  EpubBookData({
    required this.title,
    required this.author,
    required this.chapters,
    this.coverBytes,
    this.toc = const [],
  });

  final String title;
  final String author;
  final List<EpubChapter> chapters;
  final Uint8List? coverBytes;

  /// Prefer nav/NCX-derived TOC when non-empty; else derive from [chapters].
  final List<EpubTocEntry> toc;

  List<EpubTocEntry> get effectiveToc {
    if (toc.isNotEmpty) return toc;
    return [
      for (var i = 0; i < chapters.length; i++)
        EpubTocEntry(
          title: chapters[i].title,
          href: chapters[i].href,
          spineIndex: i,
        ),
    ];
  }
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
    final containerXml = XmlDocument.parse(
      utf8.decode(containerFile.content as List<int>),
    );
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
    final author =
        _firstText(opf, const ['dc:creator', 'creator']) ?? 'Unknown';

    final manifest = <String, String>{};
    String? coverId;
    String? coverHref;
    String? ncxHref;
    String? navHref;

    for (final item in opf.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id == null || href == null) continue;
      manifest[id] = href;
      final media = item.getAttribute('media-type') ?? '';
      final props = item.getAttribute('properties') ?? '';
      if (props.contains('cover-image')) {
        coverHref = href;
      }
      if (props.split(RegExp(r'\s+')).contains('nav')) {
        navHref = href;
      }
      if (media == 'application/x-dtbncx+xml') {
        ncxHref = href;
      }
      if (media.startsWith('image/') && id.toLowerCase().contains('cover')) {
        coverId ??= id;
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

    // Parse TOC (EPUB3 nav preferred, then NCX).
    final rawToc = <({String title, String href, int level})>[];
    if (navHref != null) {
      rawToc.addAll(_parseNavXhtml(map, opfDir, navHref));
    }
    if (rawToc.isEmpty && ncxHref != null) {
      rawToc.addAll(_parseNcx(map, opfDir, ncxHref));
    }

    // Map path (no fragment) → first TOC title.
    final tocTitleByPath = <String, String>{};
    for (final t in rawToc) {
      final key = _pathKey(t.href);
      tocTitleByPath.putIfAbsent(key, () => t.title);
    }

    final chapters = <EpubChapter>[];
    final spinePathKeys = <String>[];
    for (final href in spineHrefs) {
      final full = p.posix.normalize(p.posix.join(opfDir, href));
      final file = _tryGet(map, full);
      if (file == null) continue;
      final raw = utf8.decode(file.content as List<int>, allowMalformed: true);
      final doc = html_parser.parse(raw);
      final text =
          doc.body?.text.replaceAll(RegExp(r'[ \t]+\n'), '\n').trim() ?? '';
      if (text.isEmpty) continue;

      final pathKey = _pathKey(href);
      spinePathKeys.add(pathKey);

      final tocTitle = tocTitleByPath[pathKey];
      final heading = doc.querySelector('h1,h2,h3,title')?.text.trim();
      String chapterTitle;
      if (tocTitle != null && tocTitle.isNotEmpty) {
        chapterTitle = tocTitle;
      } else if (heading != null && heading.isNotEmpty) {
        chapterTitle = heading;
      } else {
        chapterTitle = '第${chapters.length + 1}章';
      }

      chapters.add(
        EpubChapter(title: chapterTitle, href: href, content: text),
      );
    }

    if (chapters.isEmpty) {
      chapters.add(EpubChapter(title: title, href: '', content: title));
      spinePathKeys.add('');
    }

    // Align TOC entries to spine indices (path without fragment).
    final pathToSpine = <String, int>{};
    for (var i = 0; i < spinePathKeys.length; i++) {
      pathToSpine.putIfAbsent(spinePathKeys[i], () => i);
    }

    final toc = <EpubTocEntry>[];
    for (final t in rawToc) {
      final key = _pathKey(t.href);
      final idx = pathToSpine[key] ?? -1;
      if (t.title.trim().isEmpty) continue;
      toc.add(
        EpubTocEntry(
          title: t.title.trim(),
          href: t.href,
          spineIndex: idx,
          level: t.level,
        ),
      );
    }

    return EpubBookData(
      title: title.isEmpty ? 'Untitled' : title,
      author: author.isEmpty ? 'Unknown' : author,
      chapters: chapters,
      coverBytes: coverBytes,
      toc: toc,
    );
  }

  List<({String title, String href, int level})> _parseNavXhtml(
    Map<String, ArchiveFile> map,
    String opfDir,
    String navHref,
  ) {
    final full = p.posix.normalize(p.posix.join(opfDir, navHref));
    final file = _tryGet(map, full);
    if (file == null) return const [];
    final raw = utf8.decode(file.content as List<int>, allowMalformed: true);
    final doc = html_parser.parse(raw);

    hdom.Element? tocNav;
    for (final nav in doc.querySelectorAll('nav')) {
      final type =
          nav.attributes['epub:type'] ??
          nav.attributes['type'] ??
          nav.attributes['role'] ??
          '';
      if (type.contains('toc') || type == 'doc-toc') {
        tocNav = nav;
        break;
      }
    }
    tocNav ??= doc.querySelector('nav');
    if (tocNav == null) return const [];

    final out = <({String title, String href, int level})>[];
    void walk(hdom.Element el, int level) {
      for (final child in el.children) {
        if (child.localName == 'a') {
          final href = child.attributes['href'] ?? '';
          final label = child.text.trim();
          if (href.isNotEmpty && label.isNotEmpty) {
            final resolved = p.posix.normalize(
              p.posix.join(p.posix.dirname(navHref), href),
            );
            out.add((title: label, href: resolved, level: level));
          }
        } else if (child.localName == 'ol' ||
            child.localName == 'ul' ||
            child.localName == 'li') {
          walk(child, child.localName == 'li' ? level : level + 0);
          // bump level when entering nested lists under an li
        }
      }
    }

    // Better nesting: walk ol/li structure.
    void walkList(hdom.Element list, int level) {
      for (final li in list.children.where((c) => c.localName == 'li')) {
        hdom.Element? a;
        for (final c in li.children) {
          if (c.localName == 'a') {
            a = c;
            break;
          }
        }
        a ??= li.querySelector('a');
        if (a != null) {
          final href = a.attributes['href'] ?? '';
          final label = a.text.trim();
          if (href.isNotEmpty && label.isNotEmpty) {
            final resolved = _resolveHref(navHref, href);
            out.add((title: label, href: resolved, level: level));
          }
        }
        for (final nested in li.children.where(
          (c) => c.localName == 'ol' || c.localName == 'ul',
        )) {
          walkList(nested, level + 1);
        }
      }
    }

    final rootList = tocNav.querySelector('ol') ?? tocNav.querySelector('ul');
    if (rootList != null) {
      walkList(rootList, 0);
    } else {
      walk(tocNav, 0);
    }
    return out;
  }

  List<({String title, String href, int level})> _parseNcx(
    Map<String, ArchiveFile> map,
    String opfDir,
    String ncxHref,
  ) {
    final full = p.posix.normalize(p.posix.join(opfDir, ncxHref));
    final file = _tryGet(map, full);
    if (file == null) return const [];
    final xml = XmlDocument.parse(
      utf8.decode(file.content as List<int>, allowMalformed: true),
    );
    final out = <({String title, String href, int level})>[];

    void walk(XmlElement el, int level) {
      for (final np in el.childElements.where(
        (e) => e.name.local == 'navPoint',
      )) {
        final label = np
            .findElements('navLabel')
            .expand((e) => e.findElements('text'))
            .map((e) => e.innerText.trim())
            .firstWhere((t) => t.isNotEmpty, orElse: () => '');
        final src = np
            .findElements('content')
            .map((e) => e.getAttribute('src') ?? '')
            .firstWhere((s) => s.isNotEmpty, orElse: () => '');
        if (label.isNotEmpty && src.isNotEmpty) {
          final resolved = _resolveHref(ncxHref, src);
          out.add((title: label, href: resolved, level: level));
        }
        walk(np, level + 1);
      }
    }

    final navMaps = xml.findAllElements('navMap').toList();
    if (navMaps.isNotEmpty) {
      walk(navMaps.first, 0);
    } else {
      walk(xml.rootElement, 0);
    }
    return out;
  }

  String _resolveHref(String baseHref, String href) {
    // Keep fragment for reference but normalize path relative to base file.
    final parts = href.split('#');
    final pathPart = parts.first;
    final frag = parts.length > 1 ? '#${parts.sublist(1).join('#')}' : '';
    final dir = p.posix.dirname(baseHref);
    final joined = pathPart.isEmpty
        ? baseHref.split('#').first
        : p.posix.normalize(p.posix.join(dir, pathPart));
    return '$joined$frag';
  }

  /// Path key without fragment, normalized, for spine alignment.
  String _pathKey(String href) {
    final path = href.split('#').first.replaceAll('\\', '/');
    return p.posix.normalize(path).toLowerCase();
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
