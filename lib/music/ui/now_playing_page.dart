import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/glass_scaffold_bg.dart';
import '../data/waveform_cache.dart';
import '../models/play_mode.dart';
import '../models/track.dart';
import '../l10n/music_strings.dart';
import '../providers/music_providers.dart';
import '../vivid/cover_theme.dart';
import '../vivid/lrc_parser.dart';
import '../vivid/vivid_stage.dart';
import 'queue_sheet.dart';
import 'cover_image.dart';
import 'waveform_seekbar.dart';

/// Harmonoid-like fullscreen Now Playing: large cover carousel + waveform seek.
/// Optional 绚丽模式: cover-themed immersive lyrics stage (Folia-inspired UX).
class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage>
    with TickerProviderStateMixin {
  final Map<String, Float32List?> _peakCache = {};
  PageController? _pageController;
  int _pageIndex = 0;

  CoverTheme _theme = CoverTheme.fallback;
  String? _themePath;
  List<LyricLine> _lyrics = const [];
  String? _lyricsTrackPath;

  late final AnimationController _ambient;
  late final AnimationController _chromeFade;
  Timer? _idleTimer;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _chromeFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    );
    _bumpIdle();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _ambient.dispose();
    _chromeFade.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _bumpIdle() {
    _idleTimer?.cancel();
    if (!_chromeVisible) {
      setState(() => _chromeVisible = true);
      _chromeFade.forward();
    } else if (_chromeFade.value < 1) {
      _chromeFade.forward();
    }
    _idleTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      final vivid = ref.read(vividModeProvider).value ?? false;
      if (!vivid) return;
      setState(() => _chromeVisible = false);
      _chromeFade.reverse();
    });
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

  Future<void> _ensureTheme(Track track) async {
    final path = track.coverPath;
    if (path == _themePath && _themePath != null) return;
    _themePath = path;
    final peeked = CoverThemeCache.instance.peek(path);
    if (peeked != null && mounted) {
      setState(() => _theme = peeked);
    }
    final theme = await CoverThemeCache.instance.resolve(path);
    if (mounted && path == _themePath) {
      setState(() => _theme = theme);
    }
  }

  Future<void> _ensureLyrics(Track track) async {
    if (_lyricsTrackPath == track.path) return;
    _lyricsTrackPath = track.path;
    final lines = await LrcParser.loadForTrack(track.path);
    if (mounted && _lyricsTrackPath == track.path) {
      setState(() => _lyrics = lines);
    }
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
    final vivid = ref.watch(vividModeProvider).value ?? false;
    final isZh = ms.isZh;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (track != null) {
      _ensurePeaks(track);
      if (vivid) {
        _ensureTheme(track);
        _ensureLyrics(track);
      }
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

    final vividToggle = IconButton(
      tooltip: ms.vividMode,
      onPressed: () async {
        _bumpIdle();
        final messenger = ScaffoldMessenger.of(context);
        await ref.read(vividModeProvider.notifier).toggle();
        if (!mounted) return;
        final on = ref.read(vividModeProvider).value ?? false;
        messenger.showSnackBar(
          SnackBar(content: Text(on ? ms.vividModeOn : ms.vividModeOff)),
        );
      },
      icon: Icon(
        vivid ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
        color: vivid ? _theme.accent : null,
      ),
    );

    if (vivid && track != null) {
      return _buildVivid(
        context: context,
        ms: ms,
        track: track,
        queue: queue,
        index: index,
        playing: playing,
        position: position,
        duration: duration,
        mode: mode,
        peaks: peaks,
        isZh: isZh,
        bottomInset: bottomInset,
        vividToggle: vividToggle,
      );
    }

    return GlassScaffoldBackground(
      oledTrueBlack: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: Text(ms.nowPlaying),
          actions: [
            vividToggle,
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
                    Expanded(
                      flex: 5,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return PageView.builder(
                            controller: _pageController,
                            itemCount: queue.length,
                            onPageChanged: (i) async {
                              if (i == index) return;
                              final h =
                                  await ref.read(musicHandlerProvider.future);
                              await h.playTrackAt(i);
                            },
                            itemBuilder: (context, i) {
                              final t = queue[i];
                              final active = i == index;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: GestureDetector(
                                  onDoubleTap: () async {
                                    await ref
                                        .read(musicLibraryProvider.notifier)
                                        .toggleFavorite(t);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            t.isFavorite
                                                ? ms.unfavorite
                                                : ms.favorite,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: _HeroCover(
                                    path: t.coverPath,
                                    active: active,
                                    slotWidth: constraints.maxWidth,
                                    slotHeight: constraints.maxHeight,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          12 + bottomInset * 0.25,
                        ),
                        child: _TransportChrome(
                          track: track,
                          playing: playing,
                          position: position,
                          duration: duration,
                          mode: mode,
                          peaks: peaks,
                          isZh: isZh,
                          ms: ms,
                          fmt: _fmt,
                          modeIcon: _modeIcon,
                          onSeek: (d) async {
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            await h.seek(d);
                          },
                          onMode: () async {
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            final next = mode.next;
                            await h.setPlayMode(next);
                            await ref
                                .read(musicRepositoryProvider)
                                .savePlayMode(next);
                          },
                          onPrev: () async {
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            await h.skipToPrevious();
                          },
                          onPlayPause: () async {
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            if (playing) {
                              await h.pause();
                            } else {
                              await h.play();
                            }
                          },
                          onNext: () async {
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            await h.skipToNext();
                          },
                          onFavorite: () {
                            ref
                                .read(musicLibraryProvider.notifier)
                                .toggleFavorite(track);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildVivid({
    required BuildContext context,
    required MusicStrings ms,
    required Track track,
    required List<Track> queue,
    required int index,
    required bool playing,
    required Duration position,
    required Duration duration,
    required PlayMode mode,
    required Float32List? peaks,
    required bool isZh,
    required double bottomInset,
    required Widget vividToggle,
  }) {
    final theme = _theme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _bumpIdle,
      onPanDown: (_) => _bumpIdle(),
      child: Scaffold(
        backgroundColor: theme.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) {
                return VividStageBackdrop(
                  coverPath: track.coverPath,
                  theme: theme,
                  tick: _ambient.value,
                );
              },
            ),
            SafeArea(
              child: Column(
                children: [
                  // Top bar (dims with chrome).
                  FadeTransition(
                    opacity: _chromeFade,
                    child: IgnorePointer(
                      ignoring: !_chromeVisible,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ms.nowPlaying,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.primary.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            vividToggle,
                            IconButton(
                              tooltip: ms.queue,
                              onPressed: () {
                                _bumpIdle();
                                showQueueSheet(context);
                              },
                              icon: Icon(
                                Icons.queue_music_rounded,
                                color: theme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Lyric / kinetic stage.
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (context, _) {
                        return VividLyricFocus(
                          theme: theme,
                          title: track.title,
                          artist: track.displayArtist,
                          lines: _lyrics,
                          position: position,
                          emptyHint: ms.vividEmptyLyrics,
                          breath: _ambient.value,
                        );
                      },
                    ),
                  ),
                  // Transport chrome.
                  FadeTransition(
                    opacity: _chromeFade,
                    child: IgnorePointer(
                      ignoring: !_chromeVisible,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          12 + bottomInset * 0.25,
                        ),
                        child: _TransportChrome(
                          track: track,
                          playing: playing,
                          position: position,
                          duration: duration,
                          mode: mode,
                          peaks: peaks,
                          isZh: isZh,
                          ms: ms,
                          fmt: _fmt,
                          modeIcon: _modeIcon,
                          accent: theme.accent,
                          labelColor: theme.secondary,
                          titleColor: theme.primary,
                          onSeek: (d) async {
                            _bumpIdle();
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            await h.seek(d);
                          },
                          onMode: () async {
                            _bumpIdle();
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            final next = mode.next;
                            await h.setPlayMode(next);
                            await ref
                                .read(musicRepositoryProvider)
                                .savePlayMode(next);
                          },
                          onPrev: () async {
                            _bumpIdle();
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            await h.skipToPrevious();
                          },
                          onPlayPause: () async {
                            _bumpIdle();
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            if (playing) {
                              await h.pause();
                            } else {
                              await h.play();
                            }
                          },
                          onNext: () async {
                            _bumpIdle();
                            final h =
                                await ref.read(musicHandlerProvider.future);
                            await h.skipToNext();
                          },
                          onFavorite: () {
                            _bumpIdle();
                            ref
                                .read(musicLibraryProvider.notifier)
                                .toggleFavorite(track);
                          },
                        ),
                      ),
                    ),
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

class _TransportChrome extends StatelessWidget {
  const _TransportChrome({
    required this.track,
    required this.playing,
    required this.position,
    required this.duration,
    required this.mode,
    required this.peaks,
    required this.isZh,
    required this.ms,
    required this.fmt,
    required this.modeIcon,
    required this.onSeek,
    required this.onMode,
    required this.onPrev,
    required this.onPlayPause,
    required this.onNext,
    required this.onFavorite,
    this.accent,
    this.labelColor,
    this.titleColor,
  });

  final Track track;
  final bool playing;
  final Duration position;
  final Duration duration;
  final PlayMode mode;
  final Float32List? peaks;
  final bool isZh;
  final MusicStrings ms;
  final String Function(Duration) fmt;
  final IconData Function(PlayMode) modeIcon;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onMode;
  final VoidCallback onPrev;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onFavorite;
  final Color? accent;
  final Color? labelColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor,
        );
    final subStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: labelColor ?? cs.onSurfaceVariant,
        );
    final timeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: labelColor ?? cs.onSurfaceVariant,
        );

    return Column(
      children: [
        if (titleColor != null) ...[
          // Vivid: compact meta above waveform (lyrics already hero).
          Text(
            track.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${track.displayArtist} · ${track.displayAlbum}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subStyle,
          ),
          const SizedBox(height: 10),
        ] else ...[
          Text(
            track.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '${track.displayArtist} · ${track.displayAlbum}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subStyle,
          ),
          const SizedBox(height: 16),
        ],
        WaveformSeekBar(
          peaks: peaks,
          position: position,
          duration: duration.inMilliseconds > 0 ? duration : track.duration,
          playing: playing,
          playedColor: accent,
          unplayedColor: accent?.withValues(alpha: 0.28),
          onSeek: onSeek,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt(position), style: timeStyle),
              Text(
                fmt(duration.inMilliseconds > 0 ? duration : track.duration),
                style: timeStyle,
              ),
            ],
          ),
        ),
        if (titleColor == null) const Spacer() else const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: isZh ? mode.labelZh() : mode.labelEn(),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onMode,
              icon: Icon(modeIcon(mode), color: titleColor),
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              iconSize: 36,
              onPressed: onPrev,
              icon: Icon(Icons.skip_previous_rounded, color: titleColor),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                minimumSize: const Size(72, 72),
                padding: EdgeInsets.zero,
                backgroundColor: accent ?? cs.primary,
                foregroundColor: accent != null
                    ? (ThemeData.estimateBrightnessForColor(accent!) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black)
                    : null,
              ),
              onPressed: onPlayPause,
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 40,
              ),
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              iconSize: 36,
              onPressed: onNext,
              icon: Icon(Icons.skip_next_rounded, color: titleColor),
            ),
            IconButton(
              tooltip: ms.favorite,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onFavorite,
              icon: Icon(
                track.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: track.isFavorite
                    ? (accent ?? cs.error)
                    : titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Strict 1:1 cover floated on the theme canvas — no black tray / heavy shadow.
class _HeroCover extends StatelessWidget {
  const _HeroCover({
    required this.path,
    required this.active,
    required this.slotWidth,
    required this.slotHeight,
  });

  final String? path;
  final bool active;
  final double slotWidth;
  final double slotHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageWidth = slotWidth * 0.82 - 16;
    final side = math.min(pageWidth, slotHeight).clamp(0.0, double.infinity);
    final scale = active ? 1.0 : 0.92;

    Widget cover = SizedBox(
      width: side,
      height: side,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CoverImage(
          path: path,
          fit: BoxFit.cover,
          placeholder: ColoredBox(
            color: cs.primaryContainer,
            child: Center(
              child: Icon(
                Icons.album_rounded,
                size: side * 0.28,
                color: cs.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );

    if (!isDark) {
      cover = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: cover,
      );
    }

    return Center(
      child: Transform.scale(
        scale: scale,
        child: cover,
      ),
    );
  }
}
