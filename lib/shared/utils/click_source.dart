// lib/shared/utils/click_source.dart
import 'package:audioplayers/audioplayers.dart';

import 'click_source_stub.dart'
    if (dart.library.io) 'click_source_io.dart' as click_source_impl;

/// Builds the audio [Source] used for one metronome click at [frequency].
///
/// The click is synthesized as a short 16-bit PCM WAV. Most platforms can
/// feed those bytes straight to the audio engine, but Android's low-latency
/// player (SoundPool) cannot play raw byte buffers, so on Android the WAV is
/// written to a temp file and exposed as a [DeviceFileSource] instead.
Future<Source> createClickSource({required double frequency}) {
  return click_source_impl.createClickSource(frequency: frequency);
}
