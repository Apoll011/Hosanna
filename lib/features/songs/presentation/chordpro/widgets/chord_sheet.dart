import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/chordpro/chord_dictionary.dart';
import '../../../domain/chordpro/instruments/instruments.dart';
import '../chord_diagrams.dart';
import '../instrument_selector.dart';

/// Opens the chord dictionary for [chord] as a modal bottom sheet.
///
/// [chords] is the song's chord list; the sheet lets the user step through it
/// with the arrows or a horizontal swipe.
Future<void> showChordSheet(
  BuildContext context, {
  required String chord,
  required List<String> chords,
  required String instrument,
  required int capo,
  required InstrumentPreferences preferences,
  required ChordFingering? Function(String chord) fingeringFor,
}) {
  final list = chords.contains(chord) ? chords : [chord, ...chords];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ChordSheet(
      chords: list,
      initialIndex: list.indexOf(chord),
      initialInstrument: instrument,
      capo: capo,
      preferences: preferences,
      fingeringFor: fingeringFor,
    ),
  );
}

class ChordSheet extends StatefulWidget {
  const ChordSheet({
    super.key,
    required this.chords,
    required this.initialIndex,
    required this.initialInstrument,
    required this.capo,
    required this.preferences,
    required this.fingeringFor,
  });

  final List<String> chords;
  final int initialIndex;
  final String initialInstrument;
  final int capo;
  final InstrumentPreferences preferences;
  final ChordFingering? Function(String chord) fingeringFor;

  @override
  State<ChordSheet> createState() => _ChordSheetState();
}

class _ChordSheetState extends State<ChordSheet> {
  late int _index = widget.initialIndex;
  late String _instrument = widget.initialInstrument;

  bool get _canPrev => _index > 0;
  bool get _canNext => _index < widget.chords.length - 1;

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.chords.length) return;
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final chord = widget.chords[_index];
    final fingering = widget.fingeringFor(chord);
    final voicing = fingering?.forInstrument(_instrument);
    final supportsCapo = instrumentRegistry.resolve(_instrument).supportsCapo;
    final diagramCapo = supportsCapo ? widget.capo : 0;
    final pref = widget.preferences.forId(_instrument);

    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -200) _step(1);
          if (v > 200) _step(-1);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _canPrev ? () => _step(-1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: l10n.songPreviousChord,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.songChordTitle(chord),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (fingering != null)
                          Text(
                            fingering.qualityLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (widget.chords.length > 1)
                          Text(
                            '${_index + 1} / ${widget.chords.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _canNext ? () => _step(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: l10n.songNextChord,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InstrumentSelector(
                selected: _instrument,
                onChanged: (i) => setState(() => _instrument = i),
              ),
              if (diagramCapo > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.songCapoOnFret('$diagramCapo'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(
                  key: ValueKey('$chord/$_instrument'),
                  child: fingering != null
                      ? InstrumentDiagram(
                          fingering: voicing,
                          capo: diagramCapo,
                          showFingerNumbers: pref.showFingerNumbers,
                          showCapoMarker: pref.showCapoMarker,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.songChordNotFound(chord),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
              ),
              if (voicing != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.songChordNotes(voicing.notes.join(' - ')),
                    style: theme.textTheme.bodySmall?.copyWith(
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
