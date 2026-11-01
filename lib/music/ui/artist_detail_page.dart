import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/glass_scaffold_bg.dart';
import '../models/artist.dart';
import '../providers/music_providers.dart';
import 'track_actions.dart';
import 'track_tile.dart';

class ArtistDetailPage extends ConsumerWidget {
  const ArtistDetailPage({super.key, required this.artist});
  final Artist artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(musicStringsProvider);

    return GlassScaffoldBackground(
      oledTrueBlack: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(artist.name)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final h = await ref.read(musicHandlerProvider.future);
            await h.loadQueue(artist.tracks, autoplay: true);
            await ref.read(musicRepositoryProvider).saveQueue(
                  artist.tracks.map((t) => t.id).toList(),
                  0,
                );
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(ms.play),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: artist.tracks.length,
          itemBuilder: (context, i) {
            final t = artist.tracks[i];
            return TrackTile(
              track: t,
              onTap: () async {
                final h = await ref.read(musicHandlerProvider.future);
                await h.loadQueue(artist.tracks, startIndex: i, autoplay: true);
                await ref.read(musicRepositoryProvider).saveQueue(
                      artist.tracks.map((e) => e.id).toList(),
                      i,
                    );
              },
              onLongPress: () => showTrackActions(
                context,
                ref: ref,
                track: t,
                queueContext: artist.tracks,
                index: i,
              ),
            );
          },
        ),
      ),
    );
  }
}
