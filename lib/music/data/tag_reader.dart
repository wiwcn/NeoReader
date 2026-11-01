import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/track.dart';

/// Lightweight offline tag reader.
///
/// Best-effort ID3v2 for MP3; folder `cover.jpg` / `cover.png` / `folder.jpg`;
/// filename fallback for other containers. Duration may be filled later by
/// the player / scanner.
class TagReader {
  static const _uuid = Uuid();

  static const coverNames = [
    'cover.jpg',
    'cover.jpeg',
    'cover.png',
    'folder.jpg',
    'folder.jpeg',
    'folder.png',
    'AlbumArt.jpg',
    'AlbumArt.png',
  ];

  Future<Track> read(File file, {String? coversDir}) async {
    final stat = await file.stat();
    final path = file.path;
    final base = p.basenameWithoutExtension(path);
    final parent = p.dirname(path);
    final folderName = p.basename(parent);

    var title = base;
    var artist = '';
    var album = folderName;
    var albumArtist = '';
    var trackNumber = 0;
    var year = 0;
    var genre = '';
    Uint8List? embeddedArt;

    final lower = path.toLowerCase();
    if (lower.endsWith('.mp3')) {
      final id3 = await _readId3v2(file);
      if (id3 != null) {
        title = id3.title?.isNotEmpty == true ? id3.title! : title;
        artist = id3.artist ?? artist;
        album = id3.album?.isNotEmpty == true ? id3.album! : album;
        albumArtist = id3.albumArtist ?? albumArtist;
        trackNumber = id3.trackNumber ?? 0;
        year = id3.year ?? 0;
        genre = id3.genre ?? '';
        embeddedArt = id3.picture;
      }
    }

    // "Artist - Title" filename convention
    if (artist.isEmpty && base.contains(' - ')) {
      final parts = base.split(' - ');
      if (parts.length >= 2) {
        artist = parts.first.trim();
        title = parts.sublist(1).join(' - ').trim();
      }
    }

    String? coverPath = await _folderCover(parent);
    if (coverPath == null && embeddedArt != null && coversDir != null) {
      try {
        final dir = Directory(coversDir);
        if (!await dir.exists()) await dir.create(recursive: true);
        final out = File(p.join(coversDir, '${_uuid.v4()}.jpg'));
        await out.writeAsBytes(embeddedArt, flush: true);
        coverPath = out.path;
      } catch (_) {}
    }

    return Track(
      id: _uuid.v4(),
      path: path,
      title: title,
      artist: artist.isEmpty ? 'Unknown artist' : artist,
      album: album.isEmpty ? 'Unknown album' : album,
      albumArtist: albumArtist,
      trackNumber: trackNumber,
      durationMs: 0,
      year: year,
      genre: genre,
      coverPath: coverPath,
      fileSize: stat.size,
      mtimeMs: stat.modified.millisecondsSinceEpoch,
      addedAt: DateTime.now(),
    );
  }

  Future<String?> _folderCover(String dir) async {
    for (final name in coverNames) {
      final f = File(p.join(dir, name));
      if (await f.exists()) return f.path;
    }
    return null;
  }

  Future<_Id3?> _readId3v2(File file) async {
    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final header = await raf.read(10);
      if (header.length < 10) return null;
      if (header[0] != 0x49 || header[1] != 0x44 || header[2] != 0x33) {
        return null; // not "ID3"
      }
      final ver = header[3];
      if (ver < 2 || ver > 4) return null;
      final size = _synchsafe(header, 6);
      if (size <= 0 || size > 5 * 1024 * 1024) return null;
      final body = await raf.read(size);
      return _parseFrames(body, ver);
    } catch (_) {
      return null;
    } finally {
      await raf?.close();
    }
  }

  int _synchsafe(List<int> b, int o) {
    return ((b[o] & 0x7f) << 21) |
        ((b[o + 1] & 0x7f) << 14) |
        ((b[o + 2] & 0x7f) << 7) |
        (b[o + 3] & 0x7f);
  }

  _Id3 _parseFrames(Uint8List body, int ver) {
    String? title, artist, album, albumArtist, genre;
    int? trackNumber, year;
    Uint8List? picture;
    var i = 0;
    while (i + 10 <= body.length) {
      String id;
      int frameSize;
      int headerLen;
      if (ver == 2) {
        if (i + 6 > body.length) break;
        id = String.fromCharCodes(body.sublist(i, i + 3));
        if (id.trim().isEmpty || id[0] == '\x00') break;
        frameSize = (body[i + 3] << 16) | (body[i + 4] << 8) | body[i + 5];
        headerLen = 6;
      } else {
        id = String.fromCharCodes(body.sublist(i, i + 4));
        if (id.trim().isEmpty || id[0] == '\x00') break;
        if (ver == 4) {
          frameSize = _synchsafe(body, i + 4);
        } else {
          frameSize =
              (body[i + 4] << 24) | (body[i + 5] << 16) | (body[i + 6] << 8) | body[i + 7];
        }
        headerLen = 10;
      }
      if (frameSize <= 0 || i + headerLen + frameSize > body.length) break;
      final data = body.sublist(i + headerLen, i + headerLen + frameSize);
      i += headerLen + frameSize;

      switch (id) {
        case 'TIT2':
        case 'TT2':
          title = _text(data);
        case 'TPE1':
        case 'TP1':
          artist = _text(data);
        case 'TALB':
        case 'TAL':
          album = _text(data);
        case 'TPE2':
        case 'TP2':
          albumArtist = _text(data);
        case 'TRCK':
        case 'TRK':
          final t = _text(data);
          if (t != null) {
            trackNumber = int.tryParse(t.split('/').first.trim());
          }
        case 'TYER':
        case 'TDRC':
        case 'TYE':
          final t = _text(data);
          if (t != null) year = int.tryParse(t.substring(0, t.length.clamp(0, 4)));
        case 'TCON':
        case 'TCO':
          genre = _text(data);
        case 'APIC':
        case 'PIC':
          picture ??= _apic(data, ver == 2);
      }
    }
    return _Id3(
      title: title,
      artist: artist,
      album: album,
      albumArtist: albumArtist,
      trackNumber: trackNumber,
      year: year,
      genre: genre,
      picture: picture,
    );
  }

  String? _text(Uint8List data) {
    if (data.isEmpty) return null;
    final encoding = data[0];
    final bytes = data.sublist(1);
    try {
      switch (encoding) {
        case 0:
          return latin1.decode(bytes).replaceAll('\x00', '').trim();
        case 1:
        case 2:
          // UTF-16 with BOM or UTF-16BE
          return _utf16(bytes);
        case 3:
          return utf8.decode(bytes, allowMalformed: true).replaceAll('\x00', '').trim();
        default:
          return utf8.decode(bytes, allowMalformed: true).replaceAll('\x00', '').trim();
      }
    } catch (_) {
      return null;
    }
  }

  String _utf16(Uint8List bytes) {
    if (bytes.length < 2) return '';
    Endian endian = Endian.little;
    var start = 0;
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      endian = Endian.little;
      start = 2;
    } else if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      endian = Endian.big;
      start = 2;
    }
    final bd = ByteData.sublistView(bytes);
    final codeUnits = <int>[];
    for (var i = start; i + 1 < bytes.length; i += 2) {
      final u = bd.getUint16(i, endian);
      if (u == 0) break;
      codeUnits.add(u);
    }
    return String.fromCharCodes(codeUnits).trim();
  }

  Uint8List? _apic(Uint8List data, bool v2) {
    if (data.length < 4) return null;
    var o = 1; // skip encoding
    if (v2) {
      o += 3; // image format
    } else {
      while (o < data.length && data[o] != 0) {
        o++;
      }
      o++; // null
    }
    if (o >= data.length) return null;
    o++; // picture type
    // description
    while (o < data.length && data[o] != 0) {
      o++;
    }
    o++;
    if (o >= data.length) return null;
    return Uint8List.fromList(data.sublist(o));
  }
}

class _Id3 {
  _Id3({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.year,
    this.genre,
    this.picture,
  });
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? year;
  final String? genre;
  final Uint8List? picture;
}
