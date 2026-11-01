import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

import 'music_audio_handler.dart';

/// Boots audio_session + audio_service once.
///
/// LG G8 Hi-Fi Quad DAC / Boombox: use the standard **music** session
/// (USAGE_MEDIA + CONTENT_TYPE_MUSIC). Do not force voice/communication
/// routing or low-quality resampling — let the OEM DAC path engage for
/// wired headphones / USB-C DAC; speaker uses normal media volume.
class MusicPlayerService {
  MusicPlayerService._();
  static final MusicPlayerService instance = MusicPlayerService._();

  MusicAudioHandler? _handler;
  bool _ready = false;

  MusicAudioHandler get handler {
    final h = _handler;
    if (h == null) {
      throw StateError('MusicPlayerService not initialized');
    }
    return h;
  }

  bool get isReady => _ready;

  Future<MusicAudioHandler> ensureInitialized() async {
    if (_ready && _handler != null) return _handler!;

    final session = await AudioSession.instance;
    // DAC-friendly: music configuration maps to USAGE_MEDIA / CONTENT_TYPE_MUSIC.
    // Avoid speech / voiceChat attributes that can bypass Hi-Fi Quad DAC.
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    _handler = await AudioService.init(
      builder: MusicAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.wiwcn.neoreader.music',
        androidNotificationChannelName: 'NeoMedia Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    _ready = true;
    return _handler!;
  }

  /// Desktop / test: soft init without native foreground service when unsupported.
  Future<MusicAudioHandler?> tryInit() async {
    try {
      return await ensureInitialized();
    } catch (e, st) {
      debugPrint('MusicPlayerService init failed: $e\n$st');
      _handler = MusicAudioHandler();
      _ready = true;
      return _handler;
    }
  }
}
