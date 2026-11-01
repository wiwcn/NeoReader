import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../presentation/providers/providers.dart';
import '../data/music_repository.dart';
import '../data/music_scanner.dart';
import '../data/m3u_service.dart';
import '../data/waveform_cache.dart';
import '../l10n/music_strings.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/play_mode.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../player/music_audio_handler.dart';
import '../player/music_player_service.dart';

final musicRepositoryProvider = Provider((ref) => MusicRepository());
final musicScannerProvider = Provider(
  (ref) => MusicScanner(ref.watch(musicRepositoryProvider)),
);
final m3uServiceProvider = Provider((ref) => M3uService());
final waveformCacheProvider = Provider((ref) => WaveformCache.instance);

final musicStringsProvider = Provider<MusicStrings>((ref) {
  final settings = ref.watch(settingsProvider).value;
  return MusicStrings(settings?.isZh ?? true);
});

enum MusicSort { title, artist, album, added }

final musicQueryProvider = StateProvider<String>((ref) => '');
final musicSortProvider = StateProvider<MusicSort>((ref) => MusicSort.title);
final musicTabIndexProvider = StateProvider<int>((ref) => 0);

class MusicLibraryNotifier extends AsyncNotifier<List<Track>> {
  @override
  Future<List<Track>> build() => ref.read(musicRepositoryProvider).allTracks();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(musicRepositoryProvider).allTracks());
  }

  Future<int> scan(String folder, {void Function(int, String)? onProgress}) async {
    final n = await ref.read(musicScannerProvider).scanRoot(
          folder,
          onProgress: onProgress,
        );
    await refresh();
    return n;
  }

  Future<void> toggleFavorite(Track track) async {
    final next = !track.isFavorite;
    await ref.read(musicRepositoryProvider).setFavorite(track.id, next);
    await refresh();
  }
}

final musicLibraryProvider =
    AsyncNotifierProvider<MusicLibraryNotifier, List<Track>>(
  MusicLibraryNotifier.new,
);

final filteredTracksProvider = Provider<AsyncValue<List<Track>>>((ref) {
  final async = ref.watch(musicLibraryProvider);
  final q = ref.watch(musicQueryProvider).trim().toLowerCase();
  final sort = ref.watch(musicSortProvider);
  return async.whenData((tracks) {
    var list = tracks;
    if (q.isNotEmpty) {
      list = list
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q) ||
                t.album.toLowerCase().contains(q),
          )
          .toList();
    }
    list = [...list];
    switch (sort) {
      case MusicSort.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case MusicSort.artist:
        list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      case MusicSort.album:
        list.sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
      case MusicSort.added:
        list.sort((a, b) {
          final aa = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bb = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bb.compareTo(aa);
        });
    }
    return list;
  });
});

final musicAlbumsProvider = Provider<AsyncValue<List<Album>>>((ref) {
  final repo = ref.watch(musicRepositoryProvider);
  final q = ref.watch(musicQueryProvider).trim().toLowerCase();
  return ref.watch(musicLibraryProvider).whenData((tracks) {
    var albums = repo.albumsFrom(tracks);
    if (q.isNotEmpty) {
      albums = albums
          .where(
            (a) =>
                a.name.toLowerCase().contains(q) ||
                a.artist.toLowerCase().contains(q),
          )
          .toList();
    }
    return albums;
  });
});

final musicArtistsProvider = Provider<AsyncValue<List<Artist>>>((ref) {
  final repo = ref.watch(musicRepositoryProvider);
  final q = ref.watch(musicQueryProvider).trim().toLowerCase();
  return ref.watch(musicLibraryProvider).whenData((tracks) {
    var artists = repo.artistsFrom(tracks);
    if (q.isNotEmpty) {
      artists = artists.where((a) => a.name.toLowerCase().contains(q)).toList();
    }
    return artists;
  });
});

class PlaylistsNotifier extends AsyncNotifier<List<Playlist>> {
  @override
  Future<List<Playlist>> build() =>
      ref.read(musicRepositoryProvider).allPlaylists();

  Future<void> refresh() async {
    state = AsyncData(await ref.read(musicRepositoryProvider).allPlaylists());
  }

  Future<Playlist> create(String name) async {
    final pl = await ref.read(musicRepositoryProvider).createPlaylist(name);
    await refresh();
    return pl;
  }

  Future<void> rename(String id, String name) async {
    await ref.read(musicRepositoryProvider).renamePlaylist(id, name);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(musicRepositoryProvider).deletePlaylist(id);
    await refresh();
  }

  Future<void> addTracks(String playlistId, List<String> trackIds) async {
    await ref
        .read(musicRepositoryProvider)
        .addTracksToPlaylist(playlistId, trackIds);
    await refresh();
  }

  Future<void> removeTrack(String playlistId, String trackId) async {
    await ref
        .read(musicRepositoryProvider)
        .removeTrackFromPlaylist(playlistId, trackId);
    await refresh();
  }
}

final playlistsProvider =
    AsyncNotifierProvider<PlaylistsNotifier, List<Playlist>>(
  PlaylistsNotifier.new,
);

final musicHandlerProvider = FutureProvider<MusicAudioHandler>((ref) async {
  final h = await MusicPlayerService.instance.tryInit();
  return h!;
});

/// Live queue / index / mode from handler once ready.
final playerQueueProvider = StreamProvider<List<Track>>((ref) async* {
  final handler = await ref.watch(musicHandlerProvider.future);
  yield handler.tracks;
  yield* handler.queueStream;
});

final playerIndexProvider = StreamProvider<int>((ref) async* {
  final handler = await ref.watch(musicHandlerProvider.future);
  yield handler.currentIndex;
  yield* handler.indexStream;
});

final playerModeProvider = StreamProvider<PlayMode>((ref) async* {
  final handler = await ref.watch(musicHandlerProvider.future);
  yield handler.playMode;
  yield* handler.modeStream;
});

final playerPositionProvider = StreamProvider<Duration>((ref) async* {
  final handler = await ref.watch(musicHandlerProvider.future);
  yield* handler.player.positionStream;
});

final playerDurationProvider = StreamProvider<Duration?>((ref) async* {
  final handler = await ref.watch(musicHandlerProvider.future);
  yield* handler.player.durationStream;
});

final playerPlayingProvider = StreamProvider<bool>((ref) async* {
  final handler = await ref.watch(musicHandlerProvider.future);
  yield* handler.player.playingStream;
});

final currentTrackProvider = Provider<Track?>((ref) {
  final queue = ref.watch(playerQueueProvider).value ?? const [];
  final index = ref.watch(playerIndexProvider).value ?? 0;
  if (queue.isEmpty || index < 0 || index >= queue.length) return null;
  return queue[index];
});

class VividModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(musicRepositoryProvider).loadVividMode();

  Future<void> setEnabled(bool enabled) async {
    await ref.read(musicRepositoryProvider).saveVividMode(enabled);
    state = AsyncData(enabled);
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    await setEnabled(!current);
  }
}

final vividModeProvider =
    AsyncNotifierProvider<VividModeNotifier, bool>(VividModeNotifier.new);
