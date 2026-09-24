/// Chord diagram widgets.
///
/// - [FrettedDiagram] renders any fretted instrument (guitar, ukulele, …) from
///   its string frets.
/// - [KeyboardDiagram] renders keyboards.
/// - [InstrumentDiagram] picks the right diagram from a fingering's type.
library;

export 'diagrams/fretted_diagram.dart';
export 'diagrams/instrument_diagram.dart';
export 'diagrams/keyboard_diagram.dart';
