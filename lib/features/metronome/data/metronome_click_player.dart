import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/utils/click_source.dart';

/// Plays metronome clicks with platform-aware triggering.
///
/// [AudioPool.start] only calls [AudioPlayer.resume] after [AudioPlayer.setSource].
/// On mediaPlayer backends (Linux / desktop / iOS), `resume()` is a no-op until
/// [AudioPlayer.play] has run at least once — which made the metronome silent
/// after the AudioPool refactor. Android's SoundPool path still uses
/// stop+resume after a preload; everyone else uses stop+play(source).
class MetronomeClickPlayer {
  AudioPlayer? _accentPlayer;
  AudioPlayer? _normalPlayer;
  Source? _accentSource;
  Source? _normalSource;
  bool _ready = false;
  bool _failed = false;

  static final bool _usesAndroidSoundPool =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

      final accentPlayer = AudioPlayer();
      final normalPlayer = AudioPlayer();
      final accentSource = await createClickSource(
        frequency: 1760,
        accent: true,
      );
      final normalSource = await createClickSource(
        frequency: 990,
        accent: false,
      );

      // Prefer low-latency on Android SoundPool; other platforms keep the
      // default mediaPlayer mode (lowLatency replay is unreliable on desktop).
      if (_usesAndroidSoundPool) {
        try {
          await Future.wait([
            accentPlayer.setPlayerMode(PlayerMode.lowLatency),
            normalPlayer.setPlayerMode(PlayerMode.lowLatency),
          ]);
        } catch (error) {
          debugPrint(
            'Metronome lowLatency unavailable, using mediaPlayer: $error',
          );
        }
      }

      await Future.wait([
        accentPlayer.setReleaseMode(ReleaseMode.stop),
        normalPlayer.setReleaseMode(ReleaseMode.stop),
        accentPlayer.setVolume(1.0),
        normalPlayer.setVolume(0.72),
      ]);

      if (_usesAndroidSoundPool) {
        // Preload into SoundPool so the first resume() is instant.
        await Future.wait([
          accentPlayer.setSource(accentSource),
          normalPlayer.setSource(normalSource),
        ]);
      }

      _accentPlayer = accentPlayer;
      _normalPlayer = normalPlayer;
      _accentSource = accentSource;
      _normalSource = normalSource;
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
    final player = accent ? _accentPlayer : _normalPlayer;
    final source = accent ? _accentSource : _normalSource;
    if (!_ready || player == null || source == null) return;

    try {
      if (_usesAndroidSoundPool) {
        // SoundPool: stop resets the stream id; resume fires soundPool.play().
        await player.stop();
        await player.resume();
      } else {
        // MediaPlayer backends: resume() is a no-op until play() has run once.
        await player.stop();
        await player.play(source);
      }
    } catch (error) {
      debugPrint('MetronomeClickPlayer click failed: $error');
      try {
        final rebuilt = await createClickSource(
          frequency: accent ? 1760 : 990,
          accent: accent,
        );
        if (accent) {
          _accentSource = rebuilt;
        } else {
          _normalSource = rebuilt;
        }
        if (_usesAndroidSoundPool) {
          await player.setSource(rebuilt);
          await player.stop();
          await player.resume();
        } else {
          await player.stop();
          await player.play(rebuilt);
        }
      } catch (retryError) {
        debugPrint('MetronomeClickPlayer click retry failed: $retryError');
      }
    }
  }

  Future<void> dispose() async {
    final accent = _accentPlayer;
    final normal = _normalPlayer;
    _accentPlayer = null;
    _normalPlayer = null;
    _accentSource = null;
    _normalSource = null;
    _ready = false;
    await Future.wait([
      if (accent != null) accent.dispose(),
      if (normal != null) normal.dispose(),
    ]);
  }
}
