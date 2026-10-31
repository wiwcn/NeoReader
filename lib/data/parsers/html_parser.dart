import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;

import 'text_content.dart';

class HtmlBookParser {
  Future<TextContent> parseFile(String path, {String? fallbackTitle}) async {
    final bytes = await File(path).readAsBytes();
    String raw;
    try {
      raw = utf8.decode(bytes);
    } catch (_) {
      raw = latin1.decode(bytes, allowInvalid: true);
    }
    if (raw.startsWith('\uFEFF')) raw = raw.substring(1);

    // MHTML: extract first text/html part
    if (path.toLowerCase().endsWith('.mhtml') ||
        path.toLowerCase().endsWith('.mht') ||
        raw.contains('Content-Type: multipart/related')) {
      raw = _extractMhtmlHtml(raw) ?? raw;
    }

    final doc = html_parser.parse(raw);
    final title = doc.querySelector('title')?.text.trim();
    final author = doc
        .querySelector('meta[name="author"]')
        ?.attributes['content']
        ?.trim();

    // Prefer article/main body
    final root =
        doc.querySelector('article') ??
        doc.querySelector('main') ??
        doc.querySelector('body') ??
        doc.documentElement;

    final buf = StringBuffer();
    if (root != null) {
      for (final node in root.querySelectorAll(
        'h1,h2,h3,h4,p,li,pre,blockquote',
      )) {
        final t = node.text.trim();
        if (t.isEmpty) continue;
        final tag = node.localName;
        if (tag != null && tag.startsWith('h')) {
          buf.writeln();
          buf.writeln(t);
          buf.writeln();
        } else {
          buf.writeln(t);
          buf.writeln();
        }
      }
    }
    var body = buf.toString().trim();
    if (body.isEmpty) {
      body = root?.text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim() ?? '';
    }

    return TextContent(
      title: (title == null || title.isEmpty)
          ? (fallbackTitle ?? 'HTML')
          : title,
      author: (author == null || author.isEmpty) ? 'HTML' : author,
      body: body.isEmpty ? (fallbackTitle ?? 'Empty document') : body,
    );
  }

  String? _extractMhtmlHtml(String raw) {
    final parts = raw.split(RegExp(r'(?=Content-Type:)', caseSensitive: false));
    for (final part in parts) {
      if (!part.toLowerCase().contains('text/html')) continue;
      final idx = part.indexOf(RegExp(r'\r?\n\r?\n'));
      if (idx < 0) continue;
      var body = part.substring(idx).trim();
      // Quoted-printable light decode
      body = body.replaceAll(RegExp(r'=\r?\n'), '');
      body = body.replaceAllMapped(RegExp(r'=([0-9A-Fa-f]{2})'), (m) {
        return String.fromCharCode(int.parse(m[1]!, radix: 16));
      });
      return body;
    }
    return null;
  }
}
