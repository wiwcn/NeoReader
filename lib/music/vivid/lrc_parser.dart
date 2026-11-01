import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// One timed lyric line (millisecond precision).
@immutable
class LyricLine {
  const LyricLine({required this.startMs, required this.text});

  final int startMs;
  final String text;

  Duration get start => Duration(milliseconds: startMs);
}

/// Minimal LRC parser for same-directory sidecar files.
class LrcParser {
  LrcParser._();

  static final _ts = RegExp(r'\[(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?\]');

  /// Resolve sibling `.lrc` next to an audio file path.
  static String? siblingPath(String audioPath) {
    final dir = p.dirname(audioPath);
    final base = p.basenameWithoutExtension(audioPath);
    for (final name in ['$base.lrc', '$base.LRC']) {
      final candidate = p.join(dir, name);
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  static Future<List<LyricLine>> loadForTrack(String audioPath) async {
    final path = siblingPath(audioPath);
    if (path == null) return const [];
    try {
      final raw = await File(path).readAsString();
      return parse(raw);
    } catch (_) {
      return const [];
    }
  }

  /// Parse LRC body into sorted unique lines (empty text dropped).
  static List<LyricLine> parse(String raw) {
    final out = <LyricLine>[];
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final matches = _ts.allMatches(line).toList();
      if (matches.isEmpty) continue;
      final text = line.substring(matches.last.end).trim();
      if (text.isEmpty) continue;
      for (final m in matches) {
        final min = int.parse(m.group(1)!);
        final sec = int.parse(m.group(2)!);
        final frac = m.group(3);
        var ms = 0;
        if (frac != null) {
          // .xx → centiseconds, .xxx → milliseconds
          if (frac.length <= 2) {
            ms = int.parse(frac.padRight(2, '0')) * 10;
          } else {
            ms = int.parse(frac.padRight(3, '0').substring(0, 3));
          }
        }
        out.add(LyricLine(startMs: min * 60000 + sec * 1000 + ms, text: text));
      }
    }
    out.sort((a, b) => a.startMs.compareTo(b.startMs));
    return out;
  }

  /// Active line index for [position], or -1 if before first / empty.
  static int activeIndex(List<LyricLine> lines, Duration position) {
    if (lines.isEmpty) return -1;
    final ms = position.inMilliseconds;
    if (ms < lines.first.startMs) return -1;
    var lo = 0;
    var hi = lines.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (lines[mid].startMs <= ms) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
