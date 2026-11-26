import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/chordpro/chord_dictionary.dart';
import '../../../domain/chordpro/chord_notation.dart';
import '../../../domain/chordpro/instruments/instruments.dart';
import '../chord_diagrams.dart';
import '../instrument_selector.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  required List<InstrumentFingering> Function(String chord) alternativesFor,
  required ChordNotationSystem chordNotation,
  required String tonic,
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
      alternativesFor: alternativesFor,
      chordNotation: chordNotation,
      tonic: tonic,
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
    required this.alternativesFor,
    required this.chordNotation,
    required this.tonic,
  });

  final List<String> chords;
  final int initialIndex;
  final String initialInstrument;
  final int capo;
  final InstrumentPreferences preferences;
  final ChordFingering? Function(String chord) fingeringFor;
  final List<InstrumentFingering> Function(String chord) alternativesFor;
  final ChordNotationSystem chordNotation;
  final String tonic;

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

  Future<void> _showVoicings(String chord) async {
    final alternatives = widget.alternativesFor(chord);
    if (alternatives.isEmpty) return;
    final preference = widget.preferences.forId(_instrument);
    final supportsCapo = instrumentRegistry.resolve(_instrument).supportsCapo;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _VoicingPager(
        chord: chord,
        alternatives: alternatives,
        capo: supportsCapo ? widget.capo : 0,
        preference: preference,
        onClose: () => Navigator.pop(dialogContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final chord = widget.chords[_index];
    final displayChord = ChordNotationConverter.formatChord(
      chord,
      widget.chordNotation,
      key: widget.tonic,
    );
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
                    icon: const Icon(LucideIcons.chevronLeft),
                    tooltip: l10n.songPreviousChord,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.songChordTitle(displayChord),
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
                    icon: const Icon(LucideIcons.chevronRight),
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
                      ? InkWell(
                          onTap: () => _showVoicings(chord),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: InstrumentDiagram(
                              fingering: voicing,
                              capo: diagramCapo,
                              showFingerNumbers: pref.showFingerNumbers,
                              showCapoMarker: pref.showCapoMarker,
                              showStringLabels: pref.showStringLabels,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.songChordNotFound(displayChord),
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
                    l10n.songChordNotes(
                      voicing.notes
                          .map(
                            (note) => ChordNotationConverter.formatNote(
                              note,
                              widget.chordNotation,
                            ),
                          )
                          .join(' - '),
                    ),
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

class _VoicingPager extends StatefulWidget {
  const _VoicingPager({
    required this.chord,
    required this.alternatives,
    required this.capo,
    required this.preference,
    required this.onClose,
  });

  final String chord;
  final List<InstrumentFingering> alternatives;
  final int capo;
  final InstrumentPreference preference;
  final VoidCallback onClose;

  @override
  State<_VoicingPager> createState() => _VoicingPagerState();
}

class _VoicingPagerState extends State<_VoicingPager> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.chord,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.alternatives.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => Center(
                  child: InstrumentDiagram(
                    fingering: widget.alternatives[index],
                    capo: widget.capo,
                    showFingerNumbers: widget.preference.showFingerNumbers,
                    showCapoMarker: widget.preference.showCapoMarker,
                    showStringLabels: widget.preference.showStringLabels,
                  ),
                ),
              ),
            ),
            Text(
              '${_index + 1} / ${widget.alternatives.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
