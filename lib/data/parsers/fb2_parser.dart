import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';

import 'text_content.dart';

class Fb2Parser {
  Future<TextContent> parseFile(String path, {String? fallbackTitle}) async {
    final bytes = await File(path).readAsBytes();
    String xml;
    try {
      xml = utf8.decode(bytes);
    } catch (_) {
      xml = latin1.decode(bytes, allowInvalid: true);
    }
    if (xml.startsWith('\uFEFF')) xml = xml.substring(1);
    final doc = XmlDocument.parse(xml);

    String title = fallbackTitle ?? 'Untitled';
    String author = 'Unknown';

    for (final t in doc.findAllElements('book-title')) {
      final v = t.innerText.trim();
      if (v.isNotEmpty) {
        title = v;
        break;
      }
    }
    final firstNames = doc.findAllElements('first-name').map((e) => e.innerText.trim());
    final lastNames = doc.findAllElements('last-name').map((e) => e.innerText.trim());
    final parts = <String>[
      ...firstNames.where((e) => e.isNotEmpty),
      ...lastNames.where((e) => e.isNotEmpty),
    ];
    if (parts.isNotEmpty) author = parts.join(' ');

    final buf = StringBuffer();
    for (final body in doc.findAllElements('body')) {
      final name = body.getAttribute('name');
      if (name == 'notes' || name == 'comments') continue;
      for (final el in body.descendants.whereType<XmlElement>()) {
        final local = el.name.local;
        if (local == 'title' || local == 'subtitle') {
          final t = el.innerText.trim();
          if (t.isNotEmpty) {
            buf.writeln();
            buf.writeln(t);
            buf.writeln();
          }
        } else if (local == 'p' || local == 'v' || local == 'text-author') {
          final t = el.innerText.trim();
          if (t.isNotEmpty) buf.writeln(t);
        } else if (local == 'empty-line') {
          buf.writeln();
        }
      }
    }

    var text = buf.toString().trim();
    if (text.isEmpty) {
      // Fallback: strip tags from whole document text
      text = html_parser.parse(xml).body?.text.trim() ?? title;
    }

    return TextContent(title: title, author: author, body: text);
  }
}
