import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Local cover art. Uses [Image.memory] so widget tests / screenshots can
/// paint covers (FileImage codecs often never complete under flutter_test).
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final String? path;
  final BoxFit fit;
  final Widget? placeholder;

  static final Map<String, Uint8List> _bytesCache = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallback = placeholder ??
        ColoredBox(
          color: cs.primaryContainer,
          child: Icon(
            Icons.album_rounded,
            color: cs.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        );

    final p = path;
    if (p == null || p.isEmpty) return fallback;
    final file = File(p);
    if (!file.existsSync()) return fallback;

    try {
      final bytes = _bytesCache.putIfAbsent(p, file.readAsBytesSync);
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }
}
