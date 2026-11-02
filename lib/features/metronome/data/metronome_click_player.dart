import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/utils/click_source.dart';

/// Plays metronome clicks via [AudioPool] so each beat can fire without
/// waiting for the previous short sample to finish replaying.
///
/// Uses [PlayerMode.mediaPlayer] (not low-latency SoundPool): on Linux/desktop
/// low-latency replay is unreliable, and mediaPlayer + pool resume is the
/// pattern AudioPool is designed for.
class MetronomeClickPlayer {
  AudioPool? _accentPool;
  AudioPool? _normalPool;
  bool _ready = false;
  bool _failed = false;

  bool get isReady => _ready;
  bool get failed => _failed;

  Future<void> init() async {
    if (_ready || _failed) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );

      final accentSource = await createClickSource(
        frequency: 1760,
        accent: true,
      );
      final normalSource = await createClickSource(
        frequency: 990,
        accent: false,
      );

      final results = await Future.wait([
        AudioPool.create(
          source: accentSource,
          minPlayers: 2,
          maxPlayers: 4,
        ),
        AudioPool.create(
          source: normalSource,
          minPlayers: 2,
          maxPlayers: 4,
        ),
      ]);

      _accentPool = results[0];
      _normalPool = results[1];
      _ready = true;
      _failed = false;
    } catch (error, stackTrace) {
      debugPrint('MetronomeClickPlayer init failed: $error\n$stackTrace');
      _ready = false;
      _failed = true;
      await dispose();
    }
  }

  /// Fire-and-forget click. Safe to call every beat.
  Future<void> click({required bool accent}) async {
    final pool = accent ? _accentPool : _normalPool;
    if (pool == null || !_ready) return;
    try {
      await pool.start(volume: accent ? 1.0 : 0.72);
    } catch (error) {
      debugPrint('MetronomeClickPlayer click failed: $error');
    }
  }

  Future<void> dispose() async {
    final accent = _accentPool;
    final normal = _normalPool;
    _accentPool = null;
    _normalPool = null;
    _ready = false;
    await Future.wait([
      if (accent != null) accent.dispose(),
      if (normal != null) normal.dispose(),
    ]);
  }
}
