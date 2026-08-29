import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/shared/utils/click_synth.dart';

void main() {
  group('ClickSynth WAV output', () {
    final bytes = ClickSynth.generate(frequency: 1500);
    final data = ByteData.sublistView(bytes);

    String ascii(int offset, int length) =>
        String.fromCharCodes(bytes.sublist(offset, offset + length));

    test('starts with a RIFF/WAVE header', () {
      expect(ascii(0, 4), 'RIFF');
      expect(ascii(8, 4), 'WAVE');
      expect(ascii(12, 4), 'fmt ');
    });

    test('describes 16-bit PCM mono at 44100 Hz', () {
      expect(data.getUint16(20, Endian.little), 1, reason: 'PCM format');
      expect(data.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(data.getUint32(24, Endian.little), 44100, reason: 'sample rate');
      expect(
        data.getUint32(28, Endian.little),
        44100 * 2,
        reason: 'byte rate (mono, 16-bit)',
      );
      expect(data.getUint16(32, Endian.little), 2, reason: 'block align');
      expect(data.getUint16(34, Endian.little), 16, reason: 'bits/sample');
    });

    test('has a data chunk consistent with the header', () {
      expect(ascii(36, 4), 'data');
      final dataLength = data.getUint32(40, Endian.little);
      expect(dataLength, bytes.length - 44);
      expect(dataLength, greaterThan(0));
      // RIFF chunk size covers everything after the RIFF size field.
      expect(data.getUint32(4, Endian.little), 36 + dataLength);
    });

    test('actually contains audible samples (non-silent)', () {
      var peak = 0;
      for (var i = 0; i < (bytes.length - 44) ~/ 2; i++) {
        peak = peak > (data.getInt16(44 + i * 2, Endian.little).abs())
            ? peak
            : data.getInt16(44 + i * 2, Endian.little).abs();
      }
      expect(peak, greaterThan(1000), reason: 'sample peaks well above noise');
    });
  });
}
