import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/track.dart';
import '../providers/music_providers.dart';

Future<void> showTrackActions(
  BuildContext context, {
  required WidgetRef ref,
  required Track track,
  required List<Track> queueContext,
  required int index,
}) async {
  final ms = ref.read(musicStringsProvider);
  final cs = Theme.of(context).colorScheme;

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: cs.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: Text(ms.play),
              onTap: () => Navigator.pop(ctx, 'play'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play_rounded),
              title: Text(ms.playNext),
              onTap: () => Navigator.pop(ctx, 'next'),
            ),
            ListTile(
              leading: const Icon(Icons.queue_rounded),
              title: Text(ms.addToQueue),
              onTap: () => Navigator.pop(ctx, 'queue'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: Text(ms.addToPlaylist),
              onTap: () => Navigator.pop(ctx, 'playlist'),
            ),
            ListTile(
              leading: Icon(
                track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
              title: Text(track.isFavorite ? ms.unfavorite : ms.favorite),
              onTap: () => Navigator.pop(ctx, 'fav'),
            ),
          ],
        ),
      );
    },
  );

  if (action == null || !context.mounted) return;
  final h = await ref.read(musicHandlerProvider.future);
  switch (action) {
    case 'play':
      await h.loadQueue(queueContext, startIndex: index, autoplay: true);
      await ref.read(musicRepositoryProvider).saveQueue(
            queueContext.map((t) => t.id).toList(),
            index,
          );
    case 'next':
      await h.addToQueue([track], playNext: true);
      await ref.read(musicRepositoryProvider).saveQueue(
            h.tracks.map((t) => t.id).toList(),
            h.currentIndex,
          );
    case 'queue':
      await h.addToQueue([track]);
      await ref.read(musicRepositoryProvider).saveQueue(
            h.tracks.map((t) => t.id).toList(),
            h.currentIndex,
          );
    case 'fav':
      await ref.read(musicLibraryProvider.notifier).toggleFavorite(track);
    case 'playlist':
      if (context.mounted) {
        await _pickPlaylist(context, ref, track);
      }
  }
}

Future<void> _pickPlaylist(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final ms = ref.read(musicStringsProvider);
  final playlists = ref.read(playlistsProvider).value ?? [];
  if (playlists.isEmpty) {
    final pl = await ref.read(playlistsProvider.notifier).create(
          ms.isZh ? '我的歌单' : 'My playlist',
        );
    await ref.read(playlistsProvider.notifier).addTracks(pl.id, [track.id]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ms.addToPlaylist}: ${pl.name}')),
      );
    }
    return;
  }
  final id = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final pl in playlists)
            ListTile(
              title: Text(pl.name),
              onTap: () => Navigator.pop(ctx, pl.id),
            ),
        ],
      ),
    ),
  );
  if (id == null) return;
  await ref.read(playlistsProvider.notifier).addTracks(id, [track.id]);
}
