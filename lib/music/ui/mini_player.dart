import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/music_providers.dart';
import 'cover_image.dart';
import 'now_playing_page.dart';

/// Global mini player — sits in [HomeShell] bottom chrome above [NavigationBar].
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  static const double height = 64;

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const NowPlayingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();

    final playing = ref.watch(playerPlayingProvider).value ?? false;
    final ms = ref.watch(musicStringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      // No bottom SafeArea — NavigationBar below already owns the home indicator.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        child: GlassSurface(
          borderRadius: 16,
          blur: 18,
          // Slightly denser frost so the bar stays readable over tab content.
          opacity: isDark ? 0.16 : 0.22,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                const SizedBox(width: 8),
                // Cover + titles open Now Playing; control buttons stay separate
                // so play/next taps are never swallowed by the row gesture.
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openNowPlaying(context),
                    child: Row(
                      children: [
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                track.displayArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: playing ? ms.pause : ms.play,
                  iconSize: 28,
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
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
                    color: cs.onSurface,
                  ),
                ),
                IconButton(
                  tooltip: ms.playNext,
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () async {
                    final h = await ref.read(musicHandlerProvider.future);
                    await h.skipToNext();
                  },
                  icon: Icon(Icons.skip_next_rounded, color: cs.onSurface),
                ),
                const SizedBox(width: 4),
              ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: CoverImage(
          path: path,
          placeholder: ColoredBox(
            color: cs.primaryContainer,
            child: Icon(Icons.music_note_rounded, color: cs.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}
