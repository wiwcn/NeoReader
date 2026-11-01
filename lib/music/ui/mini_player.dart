import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/music_providers.dart';
import 'now_playing_page.dart';

/// Global mini player above the bottom navigation bar.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();

    final playing = ref.watch(playerPlayingProvider).value ?? false;
    final ms = ref.watch(musicStringsProvider);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: GlassSurface(
            borderRadius: 16,
            blur: 18,
            opacity: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.16,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NowPlayingPage(),
                  ),
                );
              },
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    _Cover(path: track.coverPath, size: 48),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            track.displayArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: ms.play,
                      iconSize: 28,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      onPressed: () async {
                        final h = await ref.read(musicHandlerProvider.future);
                        if (playing) {
                          await h.pause();
                        } else {
                          await h.play();
                        }
                      },
                      icon: Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      onPressed: () async {
                        final h = await ref.read(musicHandlerProvider.future);
                        await h.skipToNext();
                      },
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.path, required this.size});
  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget child;
    if (path != null && File(path!).existsSync()) {
      child = Image.file(File(path!), fit: BoxFit.cover);
    } else {
      child = ColoredBox(
        color: cs.primaryContainer,
        child: Icon(Icons.music_note_rounded, color: cs.onPrimaryContainer),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}
