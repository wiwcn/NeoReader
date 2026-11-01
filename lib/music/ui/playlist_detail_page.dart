import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/glass_scaffold_bg.dart';
import '../models/track.dart';
import '../providers/music_providers.dart';
import 'track_actions.dart';
import 'track_tile.dart';

class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({super.key, required this.playlistId});
  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(musicStringsProvider);
    final playlists = ref.watch(playlistsProvider).value ?? [];
    final match = playlists.where((p) => p.id == playlistId).toList();
    if (match.isEmpty) {
      return GlassScaffoldBackground(
        oledTrueBlack: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: GlassAppBar(title: Text(ms.playlists)),
          body: Center(child: Text(ms.noQueue)),
        ),
      );
    }
    final playlist = playlists.firstWhere((p) => p.id == playlistId);
    final all = ref.watch(musicLibraryProvider).value ?? const <Track>[];
    final byId = {for (final t in all) t.id: t};
    final tracks = [
      for (final id in playlist.trackIds)
        if (byId[id] != null) byId[id]!,
    ];

    return GlassScaffoldBackground(
      oledTrueBlack: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: Text(playlist.name)),
        floatingActionButton: tracks.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () async {
                  final h = await ref.read(musicHandlerProvider.future);
                  await h.loadQueue(tracks, autoplay: true);
                  await ref.read(musicRepositoryProvider).saveQueue(
                        tracks.map((t) => t.id).toList(),
                        0,
                      );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(ms.play),
              ),
        body: tracks.isEmpty
            ? Center(child: Text(ms.emptyLibrary))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: tracks.length,
                itemBuilder: (context, i) {
                  final t = tracks[i];
                  return TrackTile(
                    track: t,
                    onTap: () async {
                      final h = await ref.read(musicHandlerProvider.future);
                      await h.loadQueue(tracks, startIndex: i, autoplay: true);
                      await ref.read(musicRepositoryProvider).saveQueue(
                            tracks.map((e) => e.id).toList(),
                            i,
                          );
                    },
                    onLongPress: () => showTrackActions(
                      context,
                      ref: ref,
                      track: t,
                      queueContext: tracks,
                      index: i,
                    ),
                    trailing: IconButton(
                      tooltip: ms.removeFromPlaylist,
                      onPressed: () {
                        ref
                            .read(playlistsProvider.notifier)
                            .removeTrack(playlistId, t.id);
                      },
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
