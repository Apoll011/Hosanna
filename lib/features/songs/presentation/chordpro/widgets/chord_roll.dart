import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/chordpro/chord_dictionary.dart';
import '../../../domain/chordpro/instruments/instruments.dart';
import '../chord_diagrams.dart';

/// Horizontal strip of diagrams for every chord used in the song.
class ChordRoll extends StatelessWidget {
  const ChordRoll({
    super.key,
    required this.chords,
    required this.capo,
    required this.instrument,
    required this.preferences,
    required this.fingeringFor,
    required this.onChordTap,
  });

  /// Transposed chords in order of appearance.
  final List<String> chords;
  final int capo;
  final String instrument;
  final InstrumentPreferences preferences;
  final ChordFingering? Function(String chord) fingeringFor;
  final void Function(String chord) onChordTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final pref = preferences.forId(instrument);
    final showCapo =
        instrumentRegistry.resolve(instrument).supportsCapo && capo > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCapo)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l10n.songCapoOnFret('$capo'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final chord in chords)
                  _ChordRollItem(
                    chord: chord,
                    voicing: fingeringFor(chord)?.forInstrument(instrument),
                    capo: capo,
                    preference: pref,
                    onTap: onChordTap,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordRollItem extends StatelessWidget {
  const _ChordRollItem({
    required this.chord,
    required this.voicing,
    required this.capo,
    required this.preference,
    required this.onTap,
  });

  final String chord;
  final InstrumentFingering? voicing;
  final int capo;
  final InstrumentPreference preference;
  final void Function(String chord) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final voicing = this.voicing;
    return Semantics(
      button: true,
      label: l10n.songChordSemantics(chord),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onTap(chord),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              Text(
                chord,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 116,
                child: InstrumentDiagram(
                  fingering: voicing,
                  capo: capo,
                  showFingerNumbers: preference.showFingerNumbers,
                  showCapoMarker: preference.showCapoMarker,
                  showStringLabels: preference.showStringLabels,
                ),
              ),
              if (voicing != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    voicing.notes.join(' - '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
