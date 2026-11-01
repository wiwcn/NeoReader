import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'music_database.dart';

/// Cached amplitude peaks keyed by path + mtime + size (G8: isolate + downsample).
class WaveformCache {
  WaveformCache._();
  static final WaveformCache instance = WaveformCache._();

  /// Widget-test / screenshot hook: return synthetic peaks without decoding audio.
  static Float32List? Function({
    required String path,
    required int mtimeMs,
    required int fileSize,
  })? debugPeaksOverride;

  /// Target peak buckets stored (~1–2 per visual second at typical song length).
  static const int targetBuckets = 800;

  /// Max bars painted on G8-width logical viewport.
  static const int maxDrawBars = 200;

  final _inflight = <String, Future<Float32List?>>{};

  String cacheKey(String path, int mtimeMs, int fileSize) =>
      '$path|$mtimeMs|$fileSize';

  Future<Float32List?> getOrCompute({
    required String path,
    required int mtimeMs,
    required int fileSize,
  }) {
    final override = debugPeaksOverride;
    if (override != null) {
      return Future.value(override(path: path, mtimeMs: mtimeMs, fileSize: fileSize));
    }
    final key = cacheKey(path, mtimeMs, fileSize);
    return _inflight.putIfAbsent(key, () async {
      try {
        final cached = await _readDb(key);
        if (cached != null) return cached;
        final peaks = await _extract(path);
        if (peaks != null) {
          await _writeDb(key, path, mtimeMs, fileSize, peaks);
        }
        return peaks;
      } finally {
        _inflight.remove(key);
      }
    });
  }

  /// Downsample for paint (G8: keep ≤ [maxDrawBars]).
  static Float32List downsample(Float32List peaks, int maxBars) {
    if (peaks.isEmpty || peaks.length <= maxBars) return peaks;
    final out = Float32List(maxBars);
    final bucket = peaks.length / maxBars;
    for (var i = 0; i < maxBars; i++) {
      final start = (i * bucket).floor();
      final end = math.min(peaks.length, ((i + 1) * bucket).ceil());
      var maxV = 0.0;
      for (var j = start; j < end; j++) {
        final v = peaks[j].abs();
        if (v > maxV) maxV = v;
      }
      out[i] = maxV;
    }
    return out;
  }

  Future<Float32List?> _readDb(String key) async {
    final db = await MusicDatabase.instance.database;
    final rows = await db.query(
      'waveform_cache',
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final blob = rows.first['peaks_blob'];
    if (blob is Uint8List) {
      return Float32List.view(blob.buffer, blob.offsetInBytes, blob.lengthInBytes ~/ 4);
    }
    return null;
  }

  Future<void> _writeDb(
    String key,
    String path,
    int mtimeMs,
    int fileSize,
    Float32List peaks,
  ) async {
    final db = await MusicDatabase.instance.database;
    final bytes = Uint8List.view(
      peaks.buffer,
      peaks.offsetInBytes,
      peaks.lengthInBytes,
    );
    await db.insert('waveform_cache', {
      'cache_key': key,
      'path': path,
      'mtime_ms': mtimeMs,
      'file_size': fileSize,
      'peaks_blob': bytes,
      'sample_rate_hint': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Float32List?> _extract(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    // just_waveform writes an intermediate wave file; run off UI via compute-friendly async.
    final tmp = await getTemporaryDirectory();
    final waveOut = File(
      p.join(tmp.path, 'wf_${path.hashCode}_${DateTime.now().microsecondsSinceEpoch}.wave'),
    );

    try {
      Waveform? waveform;
      await for (final progress in JustWaveform.extract(
        audioInFile: file,
        waveOutFile: waveOut,
        zoom: const WaveformZoom.pixelsPerSecond(50),
      )) {
        if (progress.waveform != null) {
          waveform = progress.waveform;
        }
      }
      if (waveform == null) return await _fallbackPeaks(file);

      final data = waveform.data;
      if (data.isEmpty) return await _fallbackPeaks(file);

      // Normalize int peaks → 0..1 floats, then bucket to targetBuckets.
      var maxAbs = 1;
      for (final v in data) {
        final a = v.abs();
        if (a > maxAbs) maxAbs = a;
      }
      final floats = Float32List(data.length);
      for (var i = 0; i < data.length; i++) {
        floats[i] = data[i].abs() / maxAbs;
      }
      return downsample(floats, targetBuckets);
    } catch (e, st) {
      debugPrint('Waveform extract failed: $e\n$st');
      return _fallbackPeaks(file);
    } finally {
      try {
        if (await waveOut.exists()) await waveOut.delete();
      } catch (_) {}
    }
  }

  /// Fallback: sample raw file bytes as pseudo-amplitude (still file-derived, not sine art).
  Future<Float32List?> _fallbackPeaks(File file) async {
    try {
      final len = await file.length();
      if (len <= 0) return null;
      final raf = await file.open();
      try {
        const samples = targetBuckets;
        final out = Float32List(samples);
        final step = math.max(1, len ~/ samples);
        final buf = Uint8List(4096);
        for (var i = 0; i < samples; i++) {
          final pos = (i * step).clamp(0, len - 1);
          await raf.setPosition(pos);
          final n = await raf.readInto(buf, 0, math.min(buf.length, len - pos));
          if (n <= 0) {
            out[i] = 0;
            continue;
          }
          var sum = 0;
          for (var j = 0; j < n; j++) {
            sum += (buf[j] - 128).abs();
          }
          out[i] = (sum / n / 128.0).clamp(0.0, 1.0);
        }
        // Soft normalize
        var maxV = 0.0;
        for (final v in out) {
          if (v > maxV) maxV = v;
        }
        if (maxV > 0) {
          for (var i = 0; i < out.length; i++) {
            out[i] = out[i] / maxV;
          }
        }
        return out;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return null;
    }
  }

  /// Encode peaks for debug / transfer.
  static String peaksToBase64(Float32List peaks) =>
      base64Encode(Uint8List.view(peaks.buffer, peaks.offsetInBytes, peaks.lengthInBytes));
}
