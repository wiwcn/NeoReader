import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/play_mode.dart';
import '../models/track.dart';

/// Background audio handler: notification / lock screen / headset.
class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  MusicAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onCompleted();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final List<Track> _queue = [];
  int _index = 0;
  PlayMode _mode = PlayMode.listLoop;
  final _shuffleOrder = <int>[];

  AudioPlayer get player => _player;
  List<Track> get tracks => List.unmodifiable(_queue);
  int get currentIndex => _index;
  PlayMode get playMode => _mode;
  Track? get currentTrack =>
      _queue.isEmpty || _index < 0 || _index >= _queue.length
          ? null
          : _queue[_index];

  final _queueController = StreamController<List<Track>>.broadcast();
  Stream<List<Track>> get queueStream => _queueController.stream;

  final _indexController = StreamController<int>.broadcast();
  Stream<int> get indexStream => _indexController.stream;

  final _modeController = StreamController<PlayMode>.broadcast();
  Stream<PlayMode> get modeStream => _modeController.stream;

  Future<void> setPlayMode(PlayMode mode) async {
    _mode = mode;
    _modeController.add(mode);
    if (mode == PlayMode.shuffle) {
      _rebuildShuffle(keepCurrent: true);
    }
    await _player.setLoopMode(
      mode == PlayMode.single ? LoopMode.one : LoopMode.off,
    );
  }

  void _rebuildShuffle({bool keepCurrent = false}) {
    _shuffleOrder
      ..clear()
      ..addAll(List.generate(_queue.length, (i) => i));
    _shuffleOrder.shuffle();
    if (keepCurrent && _queue.isNotEmpty) {
      _shuffleOrder.remove(_index);
      _shuffleOrder.insert(0, _index);
    }
  }

  Future<void> loadQueue(
    List<Track> tracks, {
    int startIndex = 0,
    bool autoplay = true,
  }) async {
    _queue
      ..clear()
      ..addAll(tracks);
    _index = tracks.isEmpty ? 0 : startIndex.clamp(0, tracks.length - 1);
    if (_mode == PlayMode.shuffle) _rebuildShuffle(keepCurrent: true);
    _queueController.add(List.unmodifiable(_queue));
    _indexController.add(_index);
    queue.add(_queueMediaItems());
    if (_queue.isEmpty) {
      await _player.stop();
      mediaItem.add(null);
      return;
    }
    await _loadCurrent(play: autoplay);
  }

  Future<void> addToQueue(List<Track> tracks, {bool playNext = false}) async {
    if (tracks.isEmpty) return;
    if (_queue.isEmpty) {
      await loadQueue(tracks, autoplay: true);
      return;
    }
    if (playNext) {
      _queue.insertAll(_index + 1, tracks);
    } else {
      _queue.addAll(tracks);
    }
    if (_mode == PlayMode.shuffle) _rebuildShuffle(keepCurrent: true);
    _queueController.add(List.unmodifiable(_queue));
    queue.add(_queueMediaItems());
  }

  Future<void> clearQueue() async {
    _queue.clear();
    _index = 0;
    _shuffleOrder.clear();
    _queueController.add(const []);
    _indexController.add(0);
    queue.add([]);
    mediaItem.add(null);
    await _player.stop();
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex >= _queue.length) {
      return;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    if (_index == oldIndex) {
      _index = newIndex;
    } else if (oldIndex < _index && newIndex >= _index) {
      _index--;
    } else if (oldIndex > _index && newIndex <= _index) {
      _index++;
    }
    _queueController.add(List.unmodifiable(_queue));
    _indexController.add(_index);
    queue.add(_queueMediaItems());
  }

  Future<void> playTrackAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    _indexController.add(_index);
    await _loadCurrent(play: true);
  }

  Future<void> _loadCurrent({required bool play}) async {
    final track = currentTrack;
    if (track == null) return;
    final item = _toMediaItem(track);
    mediaItem.add(item);
    try {
      final duration = await _player.setFilePath(track.path);
      if (duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
      if (play) await _player.play();
    } catch (_) {
      // Skip broken file → try next
      await skipToNext();
    }
  }

  List<MediaItem> _queueMediaItems() =>
      _queue.map(_toMediaItem).toList(growable: false);

  MediaItem _toMediaItem(Track t) {
    return MediaItem(
      id: t.id,
      title: t.title,
      artist: t.displayArtist,
      album: t.displayAlbum,
      duration: t.durationMs > 0 ? Duration(milliseconds: t.durationMs) : null,
      artUri: t.coverPath != null ? Uri.file(t.coverPath!) : null,
      extras: {'path': t.path},
    );
  }

  Future<void> _onCompleted() async {
    switch (_mode) {
      case PlayMode.single:
        await _player.seek(Duration.zero);
        await _player.play();
      case PlayMode.sequential:
        if (_index + 1 < _queue.length) {
          await skipToNext();
        } else {
          await _player.seek(Duration.zero);
          await _player.pause();
        }
      case PlayMode.listLoop:
      case PlayMode.shuffle:
        await skipToNext();
    }
  }

  int _nextIndex() {
    if (_queue.isEmpty) return 0;
    if (_mode == PlayMode.shuffle) {
      final pos = _shuffleOrder.indexOf(_index);
      if (pos < 0) return (_index + 1) % _queue.length;
      return _shuffleOrder[(pos + 1) % _shuffleOrder.length];
    }
    if (_mode == PlayMode.sequential && _index + 1 >= _queue.length) {
      return _index;
    }
    return (_index + 1) % _queue.length;
  }

  int _prevIndex() {
    if (_queue.isEmpty) return 0;
    if (_mode == PlayMode.shuffle) {
      final pos = _shuffleOrder.indexOf(_index);
      if (pos < 0) return (_index - 1 + _queue.length) % _queue.length;
      return _shuffleOrder[(pos - 1 + _shuffleOrder.length) % _shuffleOrder.length];
    }
    return (_index - 1 + _queue.length) % _queue.length;
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    final next = _nextIndex();
    if (_mode == PlayMode.sequential && next == _index && _index == _queue.length - 1) {
      await pause();
      return;
    }
    _index = next;
    _indexController.add(_index);
    await _loadCurrent(play: true);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    _index = _prevIndex();
    _indexController.add(_index);
    await _loadCurrent(play: true);
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _index,
      ),
    );
  }

  Future<void> dispose() async {
    await _queueController.close();
    await _indexController.close();
    await _modeController.close();
    await _player.dispose();
  }
}
