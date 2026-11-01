import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/glass_scaffold_bg.dart';
import '../data/waveform_cache.dart';
import '../models/play_mode.dart';
import '../models/track.dart';
import '../providers/music_providers.dart';
import 'queue_sheet.dart';
import 'cover_image.dart';
import 'waveform_seekbar.dart';

/// Harmonoid-like fullscreen Now Playing: large cover carousel + waveform seek.
class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage> {
  final Map<String, Float32List?> _peakCache = {};
  PageController? _pageController;
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _ensurePeaks(Track track) async {
    final key = WaveformCache.instance.cacheKey(
      track.path,
      track.mtimeMs,
      track.fileSize,
    );
    if (_peakCache.containsKey(key)) return;
    final peaks = await ref.read(waveformCacheProvider).getOrCompute(
          path: track.path,
          mtimeMs: track.mtimeMs,
          fileSize: track.fileSize,
        );
    if (mounted) setState(() => _peakCache[key] = peaks);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '${d.inMinutes}:$s';
  }

  IconData _modeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequential:
        return Icons.arrow_right_alt_rounded;
      case PlayMode.listLoop:
        return Icons.repeat_rounded;
      case PlayMode.single:
        return Icons.repeat_one_rounded;
      case PlayMode.shuffle:
        return Icons.shuffle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ms = ref.watch(musicStringsProvider);
    final queue = ref.watch(playerQueueProvider).value ?? const <Track>[];
    final index = ref.watch(playerIndexProvider).value ?? 0;
    final track = queue.isEmpty ? null : queue[index.clamp(0, queue.length - 1)];
    final playing = ref.watch(playerPlayingProvider).value ?? false;
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).value ??
        (track != null ? track.duration : Duration.zero);
    final mode = ref.watch(playerModeProvider).value ?? PlayMode.listLoop;
    final isZh = ms.isZh;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (track != null) {
      _ensurePeaks(track);
      if (_pageController == null || _pageIndex != index) {
        _pageController?.dispose();
        _pageController = PageController(
          initialPage: index,
          viewportFraction: 0.82,
        );
        _pageIndex = index;
      }
    }

    final peakKey = track == null
        ? null
        : WaveformCache.instance.cacheKey(track.path, track.mtimeMs, track.fileSize);
    final peaks = peakKey == null ? null : _peakCache[peakKey];

    return GlassScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(ms.nowPlaying),
          actions: [
            IconButton(
              tooltip: ms.queue,
              onPressed: () => showQueueSheet(context),
              icon: const Icon(Icons.queue_music_rounded),
            ),
          ],
        ),
        body: track == null
            ? Center(child: Text(ms.noQueue))
            : SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Large cover carousel (Harmonoid) — swipe = prev/next.
                    Expanded(
                      flex: 5,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: queue.length,
                        onPageChanged: (i) async {
                          if (i == index) return;
                          final h = await ref.read(musicHandlerProvider.future);
                          await h.playTrackAt(i);
                        },
                        itemBuilder: (context, i) {
                          final t = queue[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            child: GestureDetector(
                              onDoubleTap: () async {
                                await ref
                                    .read(musicLibraryProvider.notifier)
                                    .toggleFavorite(t);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        t.isFavorite ? ms.unfavorite : ms.favorite,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: _HeroCover(path: t.coverPath),
                            ),
                          );
                        },
                      ),
                    ),
                    // Lower chrome — one-handed on tall 19.5:9 (G8).
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + bottomInset * 0.25),
                        child: Column(
                          children: [
                            Text(
                              track.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${track.displayArtist} · ${track.displayAlbum}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            WaveformSeekBar(
                              peaks: peaks,
                              position: position,
                              duration: duration.inMilliseconds > 0
                                  ? duration
                                  : track.duration,
                              playing: playing,
                              onSeek: (d) async {
                                final h =
                                    await ref.read(musicHandlerProvider.future);
                                await h.seek(d);
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmt(position),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  Text(
                                    _fmt(
                                      duration.inMilliseconds > 0
                                          ? duration
                                          : track.duration,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  tooltip: isZh ? mode.labelZh() : mode.labelEn(),
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  onPressed: () async {
                                    final h = await ref
                                        .read(musicHandlerProvider.future);
                                    final next = mode.next;
                                    await h.setPlayMode(next);
                                    await ref
                                        .read(musicRepositoryProvider)
                                        .savePlayMode(next);
                                  },
                                  icon: Icon(_modeIcon(mode)),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(
                                    minWidth: 56,
                                    minHeight: 56,
                                  ),
                                  iconSize: 36,
                                  onPressed: () async {
                                    final h = await ref
                                        .read(musicHandlerProvider.future);
                                    await h.skipToPrevious();
                                  },
                                  icon: const Icon(Icons.skip_previous_rounded),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    shape: const CircleBorder(),
                                    minimumSize: const Size(72, 72),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () async {
                                    final h = await ref
                                        .read(musicHandlerProvider.future);
                                    if (playing) {
                                      await h.pause();
                                    } else {
                                      await h.play();
                                    }
                                  },
                                  child: Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 40,
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(
                                    minWidth: 56,
                                    minHeight: 56,
                                  ),
                                  iconSize: 36,
                                  onPressed: () async {
                                    final h = await ref
                                        .read(musicHandlerProvider.future);
                                    await h.skipToNext();
                                  },
                                  icon: const Icon(Icons.skip_next_rounded),
                                ),
                                IconButton(
                                  tooltip: ms.favorite,
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(musicLibraryProvider.notifier)
                                        .toggleFavorite(track);
                                  },
                                  icon: Icon(
                                    track.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: track.isFavorite
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.45
                    : 0.18,
              ),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CoverImage(
            path: path,
            placeholder: ColoredBox(
              color: cs.primaryContainer,
              child: Icon(
                Icons.album_rounded,
                size: 96,
                color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
