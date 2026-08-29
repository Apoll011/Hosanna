// lib/shared/utils/click_source_io.dart
//
// Native (dart:io) implementation of the metronome click source.
//
// Android's low-latency audio backend (SoundPool) does not support raw byte
// buffers — the audioplayers plugin throws "Bytes sources are not supported
// on LOW_LATENCY mode yet" — so on Android the synthesized WAV is written to
// a temp file and loaded as a DeviceFileSource (SoundPool loads local files
// natively). All other platforms keep streaming the bytes directly.
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'click_synth.dart';

Future<Source> createClickSource({required double frequency}) async {
  if (!Platform.isAndroid) {
    return BytesSource(ClickSynth.generate(frequency: frequency));
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/metronome_click_${frequency.round()}.wav');
  await file.writeAsBytes(ClickSynth.generate(frequency: frequency));
  return DeviceFileSource(file.path);
}
