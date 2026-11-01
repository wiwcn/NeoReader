import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/glass_scaffold_bg.dart';
import '../models/album.dart';
import '../providers/music_providers.dart';
import 'cover_image.dart';
import 'track_actions.dart';
import 'track_tile.dart';

class AlbumDetailPage extends ConsumerWidget {
  const AlbumDetailPage({super.key, required this.album});
  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(musicStringsProvider);
    final cs = Theme.of(context).colorScheme;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(album.name)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final h = await ref.read(musicHandlerProvider.future);
            await h.loadQueue(album.tracks, autoplay: true);
            await ref.read(musicRepositoryProvider).saveQueue(
                  album.tracks.map((t) => t.id).toList(),
                  0,
                );
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(ms.play),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: album.tracks.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: CoverImage(
                          path: album.coverPath,
                          placeholder: ColoredBox(
                            color: cs.primaryContainer,
                            child: Icon(
                              Icons.album_rounded,
                              size: 48,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(album.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            album.artist,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            '${album.trackCount} ${ms.tracksCount}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            final t = album.tracks[i - 1];
            return TrackTile(
              track: t,
              onTap: () async {
                final h = await ref.read(musicHandlerProvider.future);
                await h.loadQueue(album.tracks, startIndex: i - 1, autoplay: true);
                await ref.read(musicRepositoryProvider).saveQueue(
                      album.tracks.map((e) => e.id).toList(),
                      i - 1,
                    );
              },
              onLongPress: () => showTrackActions(
                context,
                ref: ref,
                track: t,
                queueContext: album.tracks,
                index: i - 1,
              ),
            );
          },
        ),
      ),
    );
  }
}
