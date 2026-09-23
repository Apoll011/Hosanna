/// Instrument layer for chord voicings.
///
/// Adding an instrument:
/// 1. Extend [FrettedInstrument] (or [Instrument] for a new family) and
///    supply its tuning/shape data.
/// 2. Register an instance in [defaultInstruments].
/// 3. If it uses a new fingering type, add a diagram for it (see
///    `presentation/chordpro/diagrams/`) — fretted and keyboard types are
///    already handled.
library;

import 'guitar_instrument.dart';
import 'instrument.dart';
import 'keyboard_instrument.dart';
import 'ukulele_instrument.dart';

export 'fretted_instrument.dart';
export 'guitar_instrument.dart';
export 'instrument.dart';
export 'keyboard_instrument.dart';
export 'ukulele_instrument.dart';

/// Every instrument available to the app, in display order.
const List<Instrument> defaultInstruments = [
  GuitarInstrument(),
  UkuleleInstrument(),
  KeyboardInstrument(),
];

/// Lookup for the built-in instruments (id lookup + fallback).
const InstrumentRegistry instrumentRegistry =
    InstrumentRegistry(defaultInstruments);
