import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Local cover art. Uses [Image.memory] so widget tests / screenshots can
/// paint covers (FileImage codecs often never complete under flutter_test).
///
/// Always paints with [BoxFit.cover]. Parents must constrain to a **square**
/// (`AspectRatio(aspectRatio: 1)`, equal width/height [SizedBox], etc.) so the
/// cover is never stretched into a tall/wide card slot.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
  });

  final String? path;
  final BoxFit fit;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  static final Map<String, Uint8List> _bytesCache = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallback = placeholder ??
        ColoredBox(
          color: cs.primaryContainer,
          child: Center(
            child: Icon(
              Icons.album_rounded,
              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        );

    Widget child;
    final p = path;
    if (p == null || p.isEmpty) {
      child = fallback;
    } else {
      final file = File(p);
      if (!file.existsSync()) {
        child = fallback;
      } else {
        try {
          final bytes = _bytesCache.putIfAbsent(p, file.readAsBytesSync);
          child = Image.memory(
            bytes,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => fallback,
          );
        } catch (_) {
          child = fallback;
        }
      }
    }

    final framed = SizedBox.expand(child: child);
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: framed);
    }
    return framed;
  }
}
