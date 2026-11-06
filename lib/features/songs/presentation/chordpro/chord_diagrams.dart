/// Chord diagram widgets.
///
/// - [FrettedDiagram] renders any fretted instrument (guitar, ukulele, …) from
///   its string frets, adapting layout to 4–7 strings.
/// - [KeyboardDiagram] renders keyboards.
/// - [InstrumentDiagram] picks the right diagram from a fingering's type.
library;

export 'diagrams/diagram_colors.dart';
export 'diagrams/fretted_diagram.dart';
export 'diagrams/fretted_diagram_layout.dart';
export 'diagrams/instrument_diagram.dart';
export 'diagrams/keyboard_diagram.dart';
