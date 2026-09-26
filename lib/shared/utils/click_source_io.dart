// lib/shared/utils/click_source_io.dart
//
// Native (dart:io) implementation of the metronome click source.
//
// Always write the synthesized WAV to a temp file. Android's SoundPool cannot
// play byte buffers, and file sources are also the most reliable path on
// desktop (Linux/macOS/Windows) where BytesSource + lowLatency is flaky.
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'click_synth.dart';

Future<Source> createClickSource({required double frequency}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/metronome_click_${frequency.round()}.wav');
  await file.writeAsBytes(
    ClickSynth.generate(frequency: frequency),
    flush: true,
  );
  return DeviceFileSource(file.path);
}
