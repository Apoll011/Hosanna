/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export interface ChordFingering {
  chord: string;
  guitar?: {
    frets: number[]; // 6 numbers, e.g., [3, 2, 0, 0, 3, 3] for G. -1 means muted string
    fingers?: number[]; // fingers used, e.g., [2, 1, 0, 0, 3, 4] (1=index, 2=middle, 3=ring, 4=pinky, 0=none)
    barre?: number; // Fret number for barre if any
  };
  piano?: {
    notes: string[]; // Notes of the chord (e.g. ['C', 'E', 'G'])
    highlightKeys: number[]; // Semitone indices (0 = C, 1 = C#, etc.) to highlight on keyboard
  };
}

export interface IChordDictionary {
  getFingering: (chord: string) => ChordFingering | null;
}

// Map root notes to their base semitones (0-11)
const ROOT_SEMITONES: Record<string, number> = {
  'C': 0, 'B#': 0, 'DO': 0, 'Do': 0,
  'C#': 1, 'Db': 1,
  'D': 2, 'RE': 2, 'Re': 2, 'RÉ': 2, 'Ré': 2,
  'D#': 3, 'Eb': 3,
  'E': 4, 'Fb': 4, 'MI': 4, 'Mi': 4,
  'F': 5, 'E#': 5, 'FA': 5, 'Fa': 5, 'FÁ': 5, 'Fá': 5,
  'F#': 6, 'Gb': 6,
  'G': 7, 'SOL': 7, 'Sol': 7,
  'G#': 8, 'Ab': 8,
  'A': 9, 'LA': 9, 'La': 9, 'LÁ': 9, 'Lá': 9,
  'A#': 10, 'Bb': 10,
  'B': 11, 'Cb': 11, 'SI': 11, 'Si': 11
};

// Map root notes to english string representations
const ROOT_NAMES: Record<number, string> = {
  0: 'C', 1: 'C#', 2: 'D', 3: 'D#', 4: 'E', 5: 'F', 
  6: 'F#', 7: 'G', 8: 'G#', 9: 'A', 10: 'A#', 11: 'B'
};

// Standard Guitar Fingering Database for common chords
const GUITAR_CHORD_DB: Record<string, { frets: number[]; fingers?: number[]; barre?: number }> = {
  // C family
  'C': { frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0] },
  'Cm': { frets: [-1, 3, 5, 5, 4, 3], fingers: [0, 1, 3, 4, 2, 1], barre: 3 },
  'C7': { frets: [-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0] },
  'Cmaj7': { frets: [-1, 3, 2, 0, 0, 0], fingers: [0, 3, 2, 0, 0, 0] },
  'Cm7': { frets: [-1, 3, 5, 3, 4, 3], fingers: [0, 1, 3, 1, 2, 1], barre: 3 },
  'Csus4': { frets: [-1, 3, 3, 0, 1, 1], fingers: [0, 3, 4, 0, 1, 1] },
  'Csus2': { frets: [-1, 3, 0, 0, 1, 3], fingers: [0, 2, 0, 0, 1, 4] },
  'Cadd9': { frets: [-1, 3, 2, 0, 3, 0], fingers: [0, 2, 1, 0, 3, 0] },
  'C9': { frets: [-1, 3, 2, 3, 3, 3], fingers: [0, 2, 1, 3, 3, 3], barre: 3 },

  // C# family
  'C#': { frets: [-1, 4, 6, 6, 6, 4], fingers: [0, 1, 2, 3, 4, 1], barre: 4 },
  'C#m': { frets: [-1, 4, 6, 6, 5, 4], fingers: [0, 1, 3, 4, 2, 1], barre: 4 },
  'C#7': { frets: [-1, 4, 3, 4, 2, -1], fingers: [0, 3, 2, 4, 1, 0] },
  'C#maj7': { frets: [-1, 4, 6, 5, 6, 4], fingers: [0, 1, 3, 2, 4, 1], barre: 4 },
  'C#m7': { frets: [-1, 4, 6, 4, 5, 4], fingers: [0, 1, 3, 1, 2, 1], barre: 4 },

  // D family
  'D': { frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2] },
  'Dm': { frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1] },
  'D7': { frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3] },
  'Dmaj7': { frets: [-1, -1, 0, 2, 2, 2], fingers: [0, 0, 0, 1, 1, 1], barre: 2 },
  'Dm7': { frets: [-1, -1, 0, 2, 1, 1], fingers: [0, 0, 0, 2, 1, 1], barre: 1 },
  'Dsus4': { frets: [-1, -1, 0, 2, 3, 3], fingers: [0, 0, 0, 1, 2, 3] },
  'Dsus2': { frets: [-1, -1, 0, 2, 3, 0], fingers: [0, 0, 0, 1, 2, 0] },
  'Dadd9': { frets: [-1, -1, 0, 2, 5, 2], fingers: [0, 0, 0, 1, 4, 2] },

  // Eb family
  'Eb': { frets: [-1, 6, 8, 8, 8, 6], fingers: [0, 1, 2, 3, 4, 1], barre: 6 },
  'Ebm': { frets: [-1, 6, 8, 8, 7, 6], fingers: [0, 1, 3, 4, 2, 1], barre: 6 },
  'Eb7': { frets: [-1, 6, 5, 6, 4, -1], fingers: [0, 3, 2, 4, 1, 0] },

  // E family
  'E': { frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0] },
  'Em': { frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0] },
  'E7': { frets: [0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0] },
  'Emaj7': { frets: [0, 2, 1, 1, 0, 0], fingers: [0, 3, 1, 2, 0, 0] },
  'Em7': { frets: [0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0] },
  'Esus4': { frets: [0, 2, 2, 2, 0, 0], fingers: [0, 2, 3, 4, 0, 0] },
  'Eadd9': { frets: [0, 2, 4, 1, 0, 0], fingers: [0, 2, 4, 1, 0, 0] },

  // F family
  'F': { frets: [1, 3, 3, 2, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: 1 },
  'Fm': { frets: [1, 3, 3, 1, 1, 1], fingers: [1, 3, 4, 1, 1, 1], barre: 1 },
  'F7': { frets: [1, 3, 1, 2, 1, 1], fingers: [1, 3, 1, 2, 1, 1], barre: 1 },
  'Fmaj7': { frets: [-1, 3, 3, 2, 1, 0], fingers: [0, 3, 4, 2, 1, 0] },
  'Fm7': { frets: [1, 3, 1, 1, 1, 1], fingers: [1, 3, 1, 1, 1, 1], barre: 1 },

  // F# family
  'F#': { frets: [2, 4, 4, 3, 2, 2], fingers: [1, 3, 4, 2, 1, 1], barre: 2 },
  'F#m': { frets: [2, 4, 4, 2, 2, 2], fingers: [1, 3, 4, 1, 1, 1], barre: 2 },
  'F#7': { frets: [2, 4, 2, 3, 2, 2], fingers: [1, 3, 1, 2, 1, 1], barre: 2 },
  'F#m7': { frets: [2, 4, 2, 2, 2, 2], fingers: [1, 3, 1, 1, 1, 1], barre: 2 },

  // G family
  'G': { frets: [3, 2, 0, 0, 3, 3], fingers: [2, 1, 0, 0, 3, 4] },
  'Gm': { frets: [3, 5, 5, 3, 3, 3], fingers: [1, 3, 4, 1, 1, 1], barre: 3 },
  'G7': { frets: [3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1] },
  'Gmaj7': { frets: [3, 2, 0, 0, 0, 2], fingers: [2, 1, 0, 0, 0, 3] },
  'Gm7': { frets: [3, 5, 3, 3, 3, 3], fingers: [1, 3, 1, 1, 1, 1], barre: 3 },
  'Gsus4': { frets: [3, 3, 0, 0, 3, 3], fingers: [2, 3, 0, 0, 1, 4] },
  'Gadd9': { frets: [3, 2, 0, 2, 0, 3], fingers: [2, 1, 0, 3, 0, 4] },

  // Ab family
  'Ab': { frets: [4, 6, 6, 5, 4, 4], fingers: [1, 3, 4, 2, 1, 1], barre: 4 },
  'Abm': { frets: [4, 6, 6, 4, 4, 4], fingers: [1, 3, 4, 1, 1, 1], barre: 4 },

  // A family
  'A': { frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0] },
  'Am': { frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0] },
  'A7': { frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 0, 1, 0, 2, 0] },
  'Amaj7': { frets: [-1, 0, 2, 1, 2, 0], fingers: [0, 0, 2, 1, 3, 0] },
  'Am7': { frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 0, 2, 0, 1, 0] },
  'Asus4': { frets: [-1, 0, 2, 2, 3, 0], fingers: [0, 0, 1, 2, 4, 0] },
  'Asus2': { frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 0, 1, 2, 0, 0] },
  'Aadd9': { frets: [-1, 0, 2, 4, 2, 0], fingers: [0, 0, 1, 3, 2, 0] },

  // Bb family
  'Bb': { frets: [-1, 1, 3, 3, 3, 1], fingers: [0, 1, 2, 3, 4, 1], barre: 1 },
  'Bbm': { frets: [-1, 1, 3, 3, 2, 1], fingers: [0, 1, 3, 4, 2, 1], barre: 1 },
  'Bb7': { frets: [-1, 1, 3, 1, 3, 1], fingers: [0, 1, 3, 1, 4, 1], barre: 1 },

  // B family
  'B': { frets: [-1, 2, 4, 4, 4, 2], fingers: [0, 1, 2, 3, 4, 1], barre: 2 },
  'Bm': { frets: [-1, 2, 4, 4, 3, 2], fingers: [0, 1, 3, 4, 2, 1], barre: 2 },
  'B7': { frets: [-1, 2, 1, 2, 0, 2], fingers: [0, 2, 1, 3, 0, 4] },
  'Bmaj7': { frets: [-1, 2, 4, 3, 4, 2], fingers: [0, 1, 3, 2, 4, 1], barre: 2 },
  'Bm7': { frets: [-1, 2, 4, 2, 3, 2], fingers: [0, 1, 3, 1, 2, 1], barre: 2 }
};

// Common slash chords with specific bass shapes
const SLASH_CHORD_DB: Record<string, { frets: number[]; fingers?: number[]; barre?: number }> = {
  'C/E': { frets: [0, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0] },
  'C/G': { frets: [3, 3, 2, 0, 1, 0], fingers: [3, 4, 2, 0, 1, 0] },
  'C/Bb': { frets: [-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0] },
  
  'D/F#': { frets: [2, 0, 0, 2, 3, 2], fingers: [1, 0, 0, 2, 4, 3] },
  'D/A': { frets: [-1, 0, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2] },
  
  'E/G#': { frets: [4, 2, 2, 1, 0, 0], fingers: [4, 2, 3, 1, 0, 0] },
  'E/B': { frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0] },
  
  'F/A': { frets: [-1, 0, 3, 2, 1, 1], fingers: [0, 0, 3, 2, 1, 1] },
  'F/C': { frets: [8, 8, 10, 10, 10, 8], fingers: [1, 1, 2, 3, 4, 1], barre: 8 },
  
  'G/B': { frets: [-1, 2, 0, 0, 3, 3], fingers: [0, 1, 0, 0, 3, 4] },
  'G/D': { frets: [-1, -1, 0, 0, 3, 3], fingers: [0, 0, 0, 0, 3, 4] },
  'G/F': { frets: [3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1] },
  
  'A/C#': { frets: [-1, 4, 2, 2, 2, -1], fingers: [0, 4, 1, 1, 1, 0] },
  'A/E': { frets: [0, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0] },
  'A/G': { frets: [3, 0, 2, 2, 2, 0], fingers: [4, 0, 1, 2, 3, 0] },
  
  'B/D#': { frets: [-1, 6, 4, 4, 4, -1], fingers: [0, 3, 1, 1, 1, 0] },
  'B/F#': { frets: [2, 2, 4, 4, 4, 2], fingers: [1, 1, 2, 3, 4, 1], barre: 2 },

  'Am/G': { frets: [3, 0, 2, 2, 1, 0], fingers: [4, 0, 2, 3, 1, 0] },
  'Am/F#': { frets: [2, 0, 2, 2, 1, 0], fingers: [2, 0, 3, 4, 1, 0] },
  'Am/E': { frets: [0, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0] },

  'Dm/C': { frets: [-1, 3, 0, 2, 3, 1], fingers: [0, 3, 0, 2, 4, 1] },
  'Dm/B': { frets: [-1, 2, 0, 2, 3, 1], fingers: [0, 2, 0, 3, 4, 1] },
  'Dm/A': { frets: [-1, 0, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1] },
  'Dm/F': { frets: [1, -1, 0, 2, 3, 1], fingers: [1, 0, 0, 2, 4, 3] },

  'Em/D': { frets: [0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0] },
  'Em/C#': { frets: [0, 4, 2, 0, 0, 0], fingers: [0, 3, 1, 0, 0, 0] },
  'Em/B': { frets: [7, 7, 9, 9, 8, 7], fingers: [1, 1, 3, 4, 2, 1], barre: 7 },
  'Em/G': { frets: [3, 2, 2, 0, 0, 0], fingers: [3, 1, 2, 0, 0, 0] },

  'Fm/Eb': { frets: [-1, 6, 6, 5, 6, -1], fingers: [0, 2, 3, 1, 4, 0] },
  'Gm/F': { frets: [3, 5, 3, 3, 3, 3], fingers: [1, 3, 1, 1, 1, 1], barre: 3 },
  'Bm/A': { frets: [-1, 0, 4, 4, 3, 2], fingers: [0, 0, 3, 4, 2, 1] }
};

interface ChordTemplate {
  rootNote: string;
  frets: number[];
  fingers?: number[];
  barre?: number;
}

// CAGED / barre transposition templates to generate ANY quality dynamically
const TEMPLATES_DB: Record<string, ChordTemplate[]> = {
  'major': [
    { rootNote: 'F', frets: [1, 3, 3, 2, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: 1 }, // 6th string root
    { rootNote: 'Bb', frets: [-1, 1, 3, 3, 3, 1], fingers: [0, 1, 3, 3, 3, 1], barre: 1 } // 5th string root
  ],
  'minor': [
    { rootNote: 'Fm', frets: [1, 3, 3, 1, 1, 1], fingers: [1, 3, 4, 1, 1, 1], barre: 1 },
    { rootNote: 'Bbm', frets: [-1, 1, 3, 3, 2, 1], fingers: [0, 1, 3, 4, 2, 1], barre: 1 }
  ],
  '7': [
    { rootNote: 'F7', frets: [1, 3, 1, 2, 1, 1], fingers: [1, 3, 1, 2, 1, 1], barre: 1 },
    { rootNote: 'Bb7', frets: [-1, 1, 3, 1, 3, 1], fingers: [0, 1, 3, 1, 4, 1], barre: 1 }
  ],
  'm7': [
    { rootNote: 'Fm7', frets: [1, 3, 1, 1, 1, 1], fingers: [1, 3, 1, 1, 1, 1], barre: 1 },
    { rootNote: 'Bm7', frets: [-1, 2, 4, 2, 3, 2], fingers: [0, 1, 3, 1, 2, 1], barre: 2 }
  ],
  'maj7': [
    { rootNote: 'Fmaj7', frets: [-1, 3, 3, 2, 1, 0], fingers: [0, 3, 4, 2, 1, 0] },
    { rootNote: 'Bbmaj7', frets: [-1, 1, 3, 2, 3, 1], fingers: [0, 1, 3, 2, 4, 1], barre: 1 }
  ],
  'sus4': [
    { rootNote: 'Fsus4', frets: [1, 3, 3, 3, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: 1 },
    { rootNote: 'Bbsus4', frets: [-1, 1, 3, 3, 4, 1], fingers: [0, 1, 3, 4, 2, 1], barre: 1 }
  ],
  'sus2': [
    { rootNote: 'Asus2', frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 0, 1, 2, 0, 0] },
    { rootNote: 'Csus2', frets: [-1, 3, 0, 0, 1, 3], fingers: [0, 2, 0, 0, 1, 4] }
  ],
  'dim': [
    { rootNote: 'Cdim', frets: [-1, 3, 4, 2, 4, -1], fingers: [0, 2, 3, 1, 4, 0] }
  ],
  '5': [
    { rootNote: 'F5', frets: [1, 3, 3, -1, -1, -1], fingers: [1, 3, 4, 0, 0, 0] },
    { rootNote: 'Bb5', frets: [-1, 1, 3, 3, -1, -1], fingers: [0, 1, 3, 4, 0, 0] }
  ]
};

function getTransposedGuitarFingering(root: string, quality: string): { frets: number[]; fingers?: number[]; barre?: number } | null {
  const targetSemitone = ROOT_SEMITONES[root];
  if (targetSemitone === undefined) return null;

  let q = 'major';
  if (quality === '' || quality === 'M' || quality === 'maj' || quality === 'Maj') q = 'major';
  else if (quality === 'm' || quality === 'min' || quality === 'Min') q = 'minor';
  else if (quality === '7') q = '7';
  else if (quality === 'maj7' || quality === 'Maj7' || quality === 'M7') q = 'maj7';
  else if (quality === 'm7' || quality === 'min7' || quality === 'minor7') q = 'm7';
  else if (quality === 'sus4' || quality === 'sus') q = 'sus4';
  else if (quality === 'sus2') q = 'sus2';
  else if (quality === 'dim' || quality === 'dim7' || quality === 'o') q = 'dim';
  else if (quality === '5') q = '5';

  const chordTemplates = TEMPLATES_DB[q] || TEMPLATES_DB['major'];

  let bestTemplate: ChordTemplate | null = null;
  let bestShift = 999;

  for (const t of chordTemplates) {
    const baseRootName = t.rootNote.replace(/m|7|maj|sus/g, '');
    const baseRootSemitone = ROOT_SEMITONES[baseRootName];
    if (baseRootSemitone === undefined) continue;

    let shift = targetSemitone - baseRootSemitone;
    if (shift < 0) shift += 12;

    if (shift < bestShift) {
      bestShift = shift;
      bestTemplate = t;
    }
  }

  if (!bestTemplate) return null;

  const newFrets = bestTemplate.frets.map(f => {
    if (f === -1 || f === 0) return f;
    return f + bestShift;
  });

  const newBarre = bestTemplate.barre !== undefined ? bestTemplate.barre + bestShift : undefined;

  return {
    frets: newFrets,
    fingers: bestTemplate.fingers,
    barre: newBarre
  };
}

export class DefaultChordDictionary implements IChordDictionary {
  getFingering(chord: string): ChordFingering | null {
    if (!chord) return null;

    // Standardize chord naming (Portuguese, parenthesis, etc)
    let cleanedChord = chord.replace(/[()]/g, '').trim();
    if (!cleanedChord) return null;

    // Separate bass (slash) and root chord
    let baseChord = cleanedChord.split('/')[0].trim();
    let bassName = cleanedChord.includes('/') ? cleanedChord.split('/')[1].trim() : '';

    // Check 2-char root first (C#, Db, etc) or Portuguese strings (Sol, Lá, etc)
    let root = '';
    let quality = '';

    const rootMatch = baseChord.match(/^([A-G][#b]?|Do|Ré|Mi|Fá|Sol|Lá|Si|DO|RE|RÉ|MI|FA|FÁ|SOL|LA|LÁ|SI)/i);
    if (rootMatch) {
      root = rootMatch[1];
      quality = baseChord.substring(root.length);
    } else {
      return null;
    }

    // Capitalize root correctly for key lookups
    const normalizedRootName = root.charAt(0).toUpperCase() + root.slice(1).toLowerCase();
    const standardizedRoot = normalizedRootName === 'Do' ? 'C' :
                             normalizedRootName === 'Ré' ? 'D' :
                             normalizedRootName === 'Re' ? 'D' :
                             normalizedRootName === 'Mi' ? 'E' :
                             normalizedRootName === 'Fá' ? 'F' :
                             normalizedRootName === 'Fa' ? 'F' :
                             normalizedRootName === 'Sol' ? 'G' :
                             normalizedRootName === 'Lá' ? 'A' :
                             normalizedRootName === 'La' ? 'A' :
                             normalizedRootName === 'Si' ? 'B' :
                             normalizedRootName;

    // Quality mapping
    let normQuality = 'major';
    if (quality === '' || quality === 'M' || quality === 'maj' || quality === 'Maj') normQuality = 'major';
    else if (quality === 'm' || quality === 'min' || quality === 'Min') normQuality = 'minor';
    else if (quality === '7') normQuality = '7';
    else if (quality === 'maj7' || quality === 'Maj7' || quality === 'M7') normQuality = 'maj7';
    else if (quality === 'm7' || quality === 'min7' || quality === 'minor7') normQuality = 'm7';
    else if (quality === 'sus4' || quality === 'sus') normQuality = 'sus4';
    else if (quality === 'sus2') normQuality = 'sus2';
    else if (quality === 'dim' || quality === 'dim7' || quality === 'o') normQuality = 'dim';
    else if (quality === '5') normQuality = '5';

    // Look up Guitar fingerings
    let guitarData = SLASH_CHORD_DB[cleanedChord] || GUITAR_CHORD_DB[cleanedChord];
    if (!guitarData) {
      // Re-build standard lookup e.g. "C#m7"
      let buildLookupName = standardizedRoot;
      if (normQuality === 'minor') buildLookupName += 'm';
      else if (normQuality === '7') buildLookupName += '7';
      else if (normQuality === 'maj7') buildLookupName += 'maj7';
      else if (normQuality === 'm7') buildLookupName += 'm7';
      else if (normQuality === 'sus4') buildLookupName += 'sus4';
      else if (normQuality === 'sus2') buildLookupName += 'sus2';
      else if (normQuality === 'dim') buildLookupName += 'dim';
      else if (normQuality === '5') buildLookupName += '5';

      guitarData = GUITAR_CHORD_DB[buildLookupName];

      if (!guitarData) {
        // CAGED generation fallback
        const generated = getTransposedGuitarFingering(standardizedRoot, quality);
        if (generated) {
          guitarData = generated;
        }
      }
    }

    // Look up/calculate Piano notes
    const rootSemitone = ROOT_SEMITONES[standardizedRoot] !== undefined ? ROOT_SEMITONES[standardizedRoot] : 0;
    const semitones: number[] = [];

    switch (normQuality) {
      case 'minor':
        semitones.push(rootSemitone, rootSemitone + 3, rootSemitone + 7);
        break;
      case '7':
        semitones.push(rootSemitone, rootSemitone + 4, rootSemitone + 7, rootSemitone + 10);
        break;
      case 'maj7':
        semitones.push(rootSemitone, rootSemitone + 4, rootSemitone + 7, rootSemitone + 11);
        break;
      case 'm7':
        semitones.push(rootSemitone, rootSemitone + 3, rootSemitone + 7, rootSemitone + 10);
        break;
      case 'sus4':
        semitones.push(rootSemitone, rootSemitone + 5, rootSemitone + 7);
        break;
      case 'sus2':
        semitones.push(rootSemitone, rootSemitone + 2, rootSemitone + 7);
        break;
      case 'dim':
        semitones.push(rootSemitone, rootSemitone + 3, rootSemitone + 6);
        break;
      case 'major':
      default:
        semitones.push(rootSemitone, rootSemitone + 4, rootSemitone + 7);
        break;
    }

    // Build key highlights on the 24-semitone piano board
    let highlightKeys: number[] = [];
    let notes: string[] = [];

    // If there is a slash bass, e.g. G/B
    if (bassName) {
      const bassRootName = bassName.charAt(0).toUpperCase() + bassName.slice(1).toLowerCase();
      const stdBassName = bassRootName === 'Do' ? 'C' :
                          bassRootName === 'Ré' ? 'D' :
                          bassRootName === 'Re' ? 'D' :
                          bassRootName === 'Mi' ? 'E' :
                          bassRootName === 'Fá' ? 'F' :
                          bassRootName === 'Fa' ? 'F' :
                          bassRootName === 'Sol' ? 'G' :
                          bassRootName === 'Lá' ? 'A' :
                          bassRootName === 'La' ? 'A' :
                          bassRootName === 'Si' ? 'B' :
                          bassRootName;

      const bassSemitone = ROOT_SEMITONES[stdBassName];
      if (bassSemitone !== undefined) {
        // Place bass note low in the first octave (0-11)
        highlightKeys.push(bassSemitone % 12);
        notes.push(stdBassName);

        // Place chord notes in the second octave (12-23) for beautiful voicing separation!
        semitones.forEach(st => {
          highlightKeys.push((st % 12) + 12);
          const name = ROOT_NAMES[st % 12];
          if (!notes.includes(name)) {
            notes.push(name);
          }
        });
      }
    }

    if (highlightKeys.length === 0) {
      // Normal voicing representation without slash
      notes = semitones.map(st => ROOT_NAMES[st % 12]);
      highlightKeys = semitones.map((st, idx) => {
        let val = st;
        if (idx > 0 && st < semitones[0]) {
          val += 12;
        }
        return val % 24;
      });
    }

    return {
      chord: cleanedChord,
      guitar: guitarData ? {
        frets: guitarData.frets,
        fingers: guitarData.fingers,
        barre: guitarData.barre
      } : undefined,
      piano: {
        notes,
        highlightKeys
      }
    };
  }
}

export const chordDictionary = new DefaultChordDictionary();
