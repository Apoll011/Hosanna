// lib/shared/utils/click_synth.dart
import 'dart:math' as math;
import 'dart:typed_data';

class ClickSynth {
  /// Generates a short percussive click as 16-bit PCM WAV bytes.
  static Uint8List generate({
    required double frequency,
    int sampleRate = 44100,
    double durationMs = 45,
    double amplitude = 0.9,
  }) {
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final samples = Int16List(sampleCount);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      // Fast exponential decay envelope -> percussive "click" rather than a tone.
      final envelope = math.exp(-t * 60);
      final wave = math.sin(2 * math.pi * frequency * t);
      samples[i] = (wave * envelope * amplitude * 32767).round().clamp(
        -32768,
        32767,
      );
    }

    return _wrapAsWav(samples, sampleRate);
  }

  static Uint8List _wrapAsWav(Int16List samples, int sampleRate) {
    final dataLength = samples.lengthInBytes;
    final buffer = ByteData(44 + dataLength);

    void writeString(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    buffer.setUint32(4, 36 + dataLength, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // fmt chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample
    writeString(36, 'data');
    buffer.setUint32(40, dataLength, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
