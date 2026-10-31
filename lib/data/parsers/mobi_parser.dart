import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:html/parser.dart' as html_parser;

import 'text_content.dart';

/// Best-effort DRM-free MOBI / AZW / AZW3 text extractor (PalmDOC + raw HTML sweep).
class MobiParser {
  Future<TextContent> parseFile(String path, {String? fallbackTitle}) async {
    final bytes = await File(path).readAsBytes();
    if (bytes.length < 78) {
      throw StateError('File too small to be MOBI/AZW');
    }
    final data = Uint8List.fromList(bytes);
    final bd = ByteData.sublistView(data);

    final titleFromHeader = _readCString(data, 0, 32).trim();
    final numRecords = bd.getUint16(76, Endian.big);
    if (numRecords == 0 || 78 + numRecords * 8 > data.length) {
      throw StateError('Invalid PalmDB record table');
    }

    final offsets = <int>[];
    for (var i = 0; i < numRecords; i++) {
      final off = bd.getUint32(78 + i * 8, Endian.big);
      offsets.add(off);
    }

    final rec0 = _record(data, offsets, 0);
    if (rec0.length < 16) {
      throw StateError('Empty MOBI record 0');
    }
    final rec0bd = ByteData.sublistView(rec0);
    final compression = rec0bd.getUint16(0, Endian.big);
    final textLength = rec0bd.getUint32(4, Endian.big);
    final textRecordCount = rec0bd.getUint16(8, Endian.big);
    // Skip encryption check lightly — encrypted books won't decode usefully.

    var fullName = titleFromHeader;
    var author = 'Kindle';
    if (rec0.length >= 0x20 &&
        ascii.decode(rec0.sublist(0x10, 0x14), allowInvalid: true) == 'MOBI') {
      final headerLen = rec0bd.getUint32(0x14, Endian.big);
      final fullNameOffset = rec0.length > 0x54
          ? rec0bd.getUint32(0x54, Endian.big)
          : 0;
      final fullNameLength = rec0.length > 0x58
          ? rec0bd.getUint32(0x58, Endian.big)
          : 0;
      if (fullNameOffset > 0 &&
          fullNameLength > 0 &&
          fullNameOffset + fullNameLength <= rec0.length) {
        fullName = utf8
            .decode(
              rec0.sublist(fullNameOffset, fullNameOffset + fullNameLength),
              allowMalformed: true,
            )
            .trim();
      }
      // EXTH
      final exthFlag = rec0.length > 0x80
          ? rec0bd.getUint32(0x80, Endian.big)
          : 0;
      if ((exthFlag & 0x40) != 0 && headerLen + 16 < rec0.length) {
        final exthStart = 16 + headerLen;
        if (exthStart + 12 <= rec0.length &&
            ascii.decode(
                  rec0.sublist(exthStart, exthStart + 4),
                  allowInvalid: true,
                ) ==
                'EXTH') {
          final exthLen = ByteData.sublistView(rec0)
              .getUint32(exthStart + 4, Endian.big);
          final exthCount = ByteData.sublistView(rec0)
              .getUint32(exthStart + 8, Endian.big);
          var p = exthStart + 12;
          final end = (exthStart + exthLen).clamp(0, rec0.length);
          for (var i = 0; i < exthCount && p + 8 <= end; i++) {
            final type = ByteData.sublistView(rec0).getUint32(p, Endian.big);
            final len = ByteData.sublistView(rec0).getUint32(p + 4, Endian.big);
            if (len < 8 || p + len > end) break;
            final payload = rec0.sublist(p + 8, p + len);
            if (type == 100) {
              // author
              author = utf8.decode(payload, allowMalformed: true).trim();
            } else if (type == 503 || type == 504) {
              final t = utf8.decode(payload, allowMalformed: true).trim();
              if (t.isNotEmpty) fullName = t;
            }
            p += len;
          }
        }
      }
    }

    final textParts = <String>[];
    final count = textRecordCount.clamp(0, offsets.length - 1);
    for (var i = 1; i <= count; i++) {
      final rec = _record(data, offsets, i);
      List<int> decoded;
      if (compression == 2) {
        decoded = _palmdocInflate(rec);
      } else if (compression == 1) {
        decoded = rec;
      } else {
        // Unknown / Huff/cdic — keep raw and HTML-sweep later
        decoded = rec;
      }
      textParts.add(utf8.decode(decoded, allowMalformed: true));
      if (textParts.join().length > textLength + 4096 && textLength > 0) break;
    }

    var combined = textParts.join();
    if (textLength > 0 && combined.length > textLength) {
      combined = combined.substring(0, textLength);
    }

    // Strip HTML if present (KF8 / mobi HTML)
    String body;
    if (combined.contains('<html') ||
        combined.contains('<HTML') ||
        combined.contains('<p') ||
        combined.contains('<mbp:')) {
      final doc = html_parser.parse(combined);
      body = doc.body?.text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim() ?? '';
    } else {
      body = combined.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
      body = body.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    }

    // Fallback: scan whole file for readable UTF-8 prose if PalmDOC failed
    if (body.length < 40) {
      final loose = utf8.decode(data, allowMalformed: true);
      final doc = html_parser.parse(loose);
      final t =
          doc.body?.text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim() ?? '';
      if (t.length > body.length) body = t;
    }

    if (body.isEmpty) {
      body =
          'Unable to extract text from this MOBI/AZW3 file. '
          'DRM-protected or Huff/cdic-compressed books are not supported yet. '
          'Try converting to EPUB/TXT with Calibre.';
    }

    final title =
        (fullName.isEmpty ? null : fullName) ?? fallbackTitle ?? 'Kindle book';

    return TextContent(
      title: title,
      author: author.isEmpty ? 'Kindle' : author,
      body: body,
    );
  }

  Uint8List _record(Uint8List data, List<int> offsets, int index) {
    final start = offsets[index];
    final end = index + 1 < offsets.length ? offsets[index + 1] : data.length;
    if (start >= data.length || end <= start) return Uint8List(0);
    return data.sublist(start, end.clamp(0, data.length));
  }

  String _readCString(Uint8List data, int offset, int maxLen) {
    final end = (offset + maxLen).clamp(0, data.length);
    var i = offset;
    while (i < end && data[i] != 0) {
      i++;
    }
    return ascii.decode(data.sublist(offset, i), allowInvalid: true);
  }

  /// PalmDOC LZ77-ish inflate used by classic MOBI.
  List<int> _palmdocInflate(List<int> src) {
    final out = <int>[];
    var i = 0;
    while (i < src.length) {
      final b = src[i++];
      if (b == 0x00) {
        out.add(0);
      } else if (b >= 0x01 && b <= 0x08) {
        for (var j = 0; j < b && i < src.length; j++) {
          out.add(src[i++]);
        }
      } else if (b >= 0x09 && b <= 0x7F) {
        out.add(b);
      } else if (b >= 0x80 && b <= 0xBF) {
        if (i >= src.length) break;
        final b2 = src[i++];
        final distance = (((b << 8) | b2) & 0x3FFF) >> 3;
        final length = (b2 & 0x7) + 3;
        if (distance == 0 || distance > out.length) continue;
        for (var j = 0; j < length; j++) {
          out.add(out[out.length - distance]);
        }
      } else {
        // 0xC0..0xFF: space + char
        out.add(0x20);
        out.add(b ^ 0x80);
      }
    }
    return out;
  }
}
