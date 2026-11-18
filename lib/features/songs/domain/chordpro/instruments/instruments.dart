/// Instrument layer for chord voicings.
///
/// Adding an instrument:
/// 1. Extend [FrettedInstrument] (or [Instrument] for a new family), set
///    [Instrument.family], and supply tuning variants + shape data.
/// 2. Register an instance in [defaultInstruments].
/// 3. Add a localized label (and optional icon) in
///    `presentation/chordpro/instrument_selector.dart`.
/// 4. If it uses a new fingering type, add a diagram for it (see
///    `presentation/chordpro/diagrams/`) — fretted and keyboard types are
///    already handled.
library;

import 'bass_instrument.dart';
import 'guitar_instrument.dart';
import 'instrument.dart';
import 'keyboard_instrument.dart';
import 'ukulele_instrument.dart';

export 'bass_instrument.dart';
export 'fretted_instrument.dart';
export 'fretted_tuning.dart';
export 'guitar_instrument.dart';
export 'instrument.dart';
export 'instrument_preferences.dart';
export 'keyboard_instrument.dart';
export 'ukulele_instrument.dart';

/// Every instrument available to the app, in display order.
const List<Instrument> defaultInstruments = [
  GuitarInstrument(),
  BassInstrument(),
  UkuleleInstrument(),
  KeyboardInstrument(),
];

/// Lookup for the built-in instruments (id lookup + fallback).
const InstrumentRegistry instrumentRegistry =
    InstrumentRegistry(defaultInstruments);
