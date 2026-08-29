// lib/shared/utils/click_source_stub.dart
//
// Fallback implementation used when dart:io is unavailable (e.g. web):
// the click WAV bytes are handed to the audio engine directly.
import 'package:audioplayers/audioplayers.dart';

import 'click_synth.dart';

Future<Source> createClickSource({required double frequency}) async {
  return BytesSource(ClickSynth.generate(frequency: frequency));
}
