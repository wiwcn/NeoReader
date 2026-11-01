import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/glass_scaffold_bg.dart';
import '../models/album.dart';
import '../models/track.dart';
import '../providers/music_providers.dart';
import 'album_detail_page.dart';
import 'cover_image.dart';
import 'artist_detail_page.dart';
import 'playlist_detail_page.dart';
import 'track_actions.dart';
import 'track_tile.dart';

class MusicHomeScreen extends ConsumerStatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  ConsumerState<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends ConsumerState<MusicHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _scanning = false;
  String _scanLabel = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        ref.read(musicTabIndexProvider.notifier).state = _tabs.index;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(musicHandlerProvider.future);
      await _restoreQueue();
    });
  }

  Future<void> _restoreQueue() async {
    final repo = ref.read(musicRepositoryProvider);
    final (ids, index) = await repo.loadQueue();
    if (ids.isEmpty) return;
    final all = await repo.allTracks();
    final byId = {for (final t in all) t.id: t};
    final tracks = [for (final id in ids) if (byId[id] != null) byId[id]!];
    if (tracks.isEmpty) return;
    final mode = await repo.loadPlayMode();
    final h = await ref.read(musicHandlerProvider.future);
    await h.setPlayMode(mode);
    await h.loadQueue(tracks, startIndex: index.clamp(0, tracks.length - 1), autoplay: false);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    // Android 13+ audio; older storage. Best-effort.
    var status = await Permission.audio.request();
    if (status.isGranted) return true;
    status = await Permission.storage.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> _scanFolder() async {
    final ms = ref.read(musicStringsProvider);
    final ok = await _ensurePermission();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ms.permissionNeeded)),
      );
    }
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return;
    setState(() {
      _scanning = true;
      _scanLabel = ms.scanning;
    });
    try {
      final n = await ref.read(musicLibraryProvider.notifier).scan(
            path,
            onProgress: (found, current) {
              if (!mounted) return;
              setState(() => _scanLabel = '$found · ${current.split('/').last}');
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ms.scanDone}: $n')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _playTracks(List<Track> tracks, {int start = 0}) async {
    if (tracks.isEmpty) return;
    final h = await ref.read(musicHandlerProvider.future);
    await h.loadQueue(tracks, startIndex: start, autoplay: true);
    await ref.read(musicRepositoryProvider).saveQueue(
          tracks.map((t) => t.id).toList(),
          start,
        );
  }

  @override
  Widget build(BuildContext context) {
    final ms = ref.watch(musicStringsProvider);
    final cs = Theme.of(context).colorScheme;

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _scanning ? null : _scanFolder,
          icon: _scanning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.folder_open_rounded),
          label: Text(_scanning ? ms.scanning : ms.scanFolder),
        ),
        appBar: GlassAppBar(
          title: Text(ms.music),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: ms.searchMusic,
                      isDense: true,
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                          : cs.surface.withValues(alpha: 0.55),
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) =>
                        ref.read(musicQueryProvider.notifier).state = v,
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  tabs: [
                    Tab(text: ms.tracks),
                    Tab(text: ms.albums),
                    Tab(text: ms.artists),
                    Tab(text: ms.playlists),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            PopupMenuButton<MusicSort>(
              tooltip: ms.sortTitle,
              icon: const Icon(Icons.sort_rounded),
              onSelected: (v) =>
                  ref.read(musicSortProvider.notifier).state = v,
              itemBuilder: (_) => [
                PopupMenuItem(value: MusicSort.title, child: Text(ms.sortTitle)),
                PopupMenuItem(value: MusicSort.artist, child: Text(ms.sortArtist)),
                PopupMenuItem(value: MusicSort.album, child: Text(ms.sortAlbum)),
                PopupMenuItem(value: MusicSort.added, child: Text(ms.sortAdded)),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabs,
              children: [
                _TracksTab(onPlay: _playTracks),
                _AlbumsTab(onPlay: _playTracks),
                _ArtistsTab(onPlay: _playTracks),
                _PlaylistsTab(onPlay: _playTracks),
              ],
            ),
            if (_scanning)
              Positioned(
                left: 16,
                right: 16,
                bottom: 88,
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(12),
                  color: cs.surfaceContainerHigh.withValues(alpha: 0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _scanLabel,
                      maxLines: 2,
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TracksTab extends ConsumerWidget {
  const _TracksTab({required this.onPlay});
  final Future<void> Function(List<Track> tracks, {int start}) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(musicStringsProvider);
    final async = ref.watch(filteredTracksProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tracks) {
        if (tracks.isEmpty) {
          return Center(child: Text(ms.emptyLibrary));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: tracks.length,
          itemBuilder: (context, i) {
            final t = tracks[i];
            return TrackTile(
              track: t,
              onTap: () => onPlay(tracks, start: i),
              onLongPress: () => showTrackActions(
                context,
                ref: ref,
                track: t,
                queueContext: tracks,
                index: i,
              ),
            );
          },
        );
      },
    );
  }
}

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab({required this.onPlay});
  final Future<void> Function(List<Track> tracks, {int start}) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(musicStringsProvider);
    final async = ref.watch(musicAlbumsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (albums) {
        if (albums.isEmpty) return Center(child: Text(ms.emptyLibrary));
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: albums.length,
          itemBuilder: (context, i) {
            final a = albums[i];
            return _AlbumCard(
              album: a,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AlbumDetailPage(album: a),
                  ),
                );
              },
              onPlay: () => onPlay(a.tracks),
            );
          },
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.album,
    required this.onTap,
    required this.onPlay,
  });
  final Album album;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassSurface(
      borderRadius: 18,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: CoverImage(
                  path: album.coverPath,
                  placeholder: ColoredBox(
                    color: cs.primaryContainer,
                    child: Icon(Icons.album_rounded, size: 48, color: cs.onPrimaryContainer),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_circle_fill_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistsTab extends ConsumerWidget {
  const _ArtistsTab({required this.onPlay});
  final Future<void> Function(List<Track> tracks, {int start}) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(musicStringsProvider);
    final async = ref.watch(musicArtistsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (artists) {
        if (artists.isEmpty) return Center(child: Text(ms.emptyLibrary));
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final a = artists[i];
            return ListTile(
              leading: CircleAvatar(
                child: Text(a.name.isNotEmpty ? a.name.characters.first : '?'),
              ),
              title: Text(a.name),
              subtitle: Text('${a.trackCount} ${ms.tracksCount}'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ArtistDetailPage(artist: a),
                  ),
                );
              },
              trailing: IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => onPlay(a.tracks),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab({required this.onPlay});
  final Future<void> Function(List<Track> tracks, {int start}) onPlay;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final ms = ref.read(musicStringsProvider);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        // Opaque dialog surface
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHigh,
        title: Text(ms.newPlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: ms.playlistName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ref.read(musicStringsProvider).isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(ref.read(musicStringsProvider).isZh ? '确定' : 'OK'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(playlistsProvider.notifier).create(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ms = ref.watch(musicStringsProvider);
    final async = ref.watch(playlistsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (playlists) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(ms.newPlaylist),
              onTap: () => _create(context, ref),
            ),
            ...playlists.map((pl) {
              return ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: Text(pl.name),
                subtitle: Text('${pl.count} ${ms.tracksCount}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlaylistDetailPage(playlistId: pl.id),
                    ),
                  );
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'rename') {
                      final c = TextEditingController(text: pl.name);
                      final name = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor:
                              Theme.of(ctx).colorScheme.surfaceContainerHigh,
                          title: Text(ms.renamePlaylist),
                          content: TextField(controller: c),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(ms.isZh ? '取消' : 'Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, c.text.trim()),
                              child: Text(ms.isZh ? '确定' : 'OK'),
                            ),
                          ],
                        ),
                      );
                      if (name != null && name.isNotEmpty) {
                        await ref.read(playlistsProvider.notifier).rename(pl.id, name);
                      }
                    } else if (v == 'delete') {
                      await ref.read(playlistsProvider.notifier).delete(pl.id);
                    } else if (v == 'export') {
                      final repo = ref.read(musicRepositoryProvider);
                      final all = await repo.allTracks();
                      final byId = {for (final t in all) t.id: t};
                      final tracks = [
                        for (final id in pl.trackIds)
                          if (byId[id] != null) byId[id]!,
                      ];
                      final docs = await getApplicationDocumentsDirectory();
                      final out = Directory('${docs.path}/exports');
                      final file = await ref.read(m3uServiceProvider).exportPlaylistM3u(
                            playlist: pl,
                            tracks: tracks,
                            outDir: out,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${ms.exported}: ${file.path}')),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'rename', child: Text(ms.renamePlaylist)),
                    PopupMenuItem(value: 'export', child: Text(ms.exportM3u)),
                    PopupMenuItem(value: 'delete', child: Text(ms.deletePlaylist)),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
