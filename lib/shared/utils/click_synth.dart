// lib/shared/utils/click_synth.dart
import 'dart:math' as math;
import 'dart:typed_data';

/// Synthesizes short percussive metronome clicks as 16-bit PCM WAV bytes.
///
/// The click mixes a pitched transient with a brief noise burst so accents and
/// normal beats read as woodblock-like taps rather than soft sine beeps.
class ClickSynth {
  /// Generates a short percussive click as 16-bit PCM WAV bytes.
  static Uint8List generate({
    required double frequency,
    int sampleRate = 44100,
    double durationMs = 55,
    double amplitude = 0.98,
    bool accent = false,
  }) {
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final rawSamples = Float64List(sampleCount);
    // Deterministic noise so identical frequencies produce identical WAVs
    // (important for temp-file caching and tests).
    var noiseState = (frequency * 97).round() & 0x7fffffff;
    if (noiseState == 0) noiseState = 1;

    final decay = accent ? 46.0 : 58.0;
    final noiseMix = accent ? 0.35 : 0.22;
    final toneMix = 1.0 - noiseMix;

    var maxAbs = 0.0;
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      // Fast attack, exponential decay → sharp percussive tap.
      final envelope = math.exp(-t * decay) * (1 - math.exp(-t * 2200));

      final fundamental = math.sin(2 * math.pi * frequency * t);
      final partial = 0.4 * math.sin(2 * math.pi * frequency * 2.0 * t);
      final tone = fundamental + partial;

      // xorshift-ish noise for wood character
      noiseState ^= noiseState << 13;
      noiseState ^= noiseState >> 17;
      noiseState ^= noiseState << 5;
      final noise = ((noiseState & 0xffff) / 0x8000) - 1.0;

      final val = (tone * toneMix + noise * noiseMix) * envelope;
      rawSamples[i] = val;
      final absVal = val.abs();
      if (absVal > maxAbs) {
        maxAbs = absVal;
      }
    }

    final targetPeak = accent ? 32000.0 : 26000.0;
    final scale = maxAbs > 0.0001 ? (targetPeak / maxAbs) : 1.0;

    final samples = Int16List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      final scaled = (rawSamples[i] * scale).round();
      samples[i] = scaled.clamp(-32768, 32767);
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
