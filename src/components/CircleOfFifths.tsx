import React, { useState } from 'react';
import { CircleDot } from 'lucide-react';

const circleData = [
  { major: 'C', minor: 'Am', degrees: ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'] },
  { major: 'G', minor: 'Em', degrees: ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim'] },
  { major: 'D', minor: 'Bm', degrees: ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim'] },
  { major: 'A', minor: 'F#m', degrees: ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim'] },
  { major: 'E', minor: 'C#m', degrees: ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim'] },
  { major: 'B', minor: 'G#m', degrees: ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim'] },
  { major: 'Gb', minor: 'Ebm', degrees: ['Gb', 'Abm', 'Bbm', 'Cb', 'Db', 'Ebm', 'Fdim'] },
  { major: 'Db', minor: 'Bbm', degrees: ['Db', 'Ebm', 'Fm', 'Gb', 'Ab', 'Bbm', 'Cdim'] },
  { major: 'Ab', minor: 'Fm', degrees: ['Ab', 'Bbm', 'Cm', 'Db', 'Eb', 'Fm', 'Gdim'] },
  { major: 'Eb', minor: 'Cm', degrees: ['Eb', 'Fm', 'Gm', 'Ab', 'Bb', 'Cm', 'Ddim'] },
  { major: 'Bb', minor: 'Gm', degrees: ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim'] },
  { major: 'F', minor: 'Dm', degrees: ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim'] }
];

const intervals = [
  { roman: 'I', type: 'Maior' },
  { roman: 'ii', type: 'Menor' },
  { roman: 'iii', type: 'Menor' },
  { roman: 'IV', type: 'Maior' },
  { roman: 'V', type: 'Maior' },
  { roman: 'vi', type: 'Menor' },
  { roman: 'vii°', type: 'Diminuto' },
];

export default function CircleOfFifths() {
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const selectedData = circleData[selectedIndex];

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-6 no-scrollbar pb-24 flex flex-col items-center">
      {/* Interactive Circle UI */}
      <div className="relative w-72 h-72 sm:w-80 sm:h-80 my-4 select-none shrink-0 aspect-square">
        {/* Decorative background circles */}
        <div className="absolute inset-[8%] rounded-full border border-dashed border-m3-border/25 dark:border-m3-dark-border/25" />
        <div className="absolute inset-[22%] rounded-full border border-dashed border-m3-border/15 dark:border-m3-dark-border/15" />
        
        {/* Selected Highlight Backgrounds */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
        </div>

        {circleData.map((item, index) => {
          // 12 positions: 0 is top (12 o'clock). Each step is 30 degrees.
          // 0 -> 0 deg, 1 -> 30 deg, 2 -> 60 deg, etc.
          // Standard Math: rotate starting from -90 degrees.
          const angleDeg = index * 30 - 90;
          const angleRad = (angleDeg * Math.PI) / 180;
          
          // Outer radius for Major keys (45% from center to stay inside padding)
          const rOuter = 42;
          const xOuter = 50 + (rOuter * Math.cos(angleRad));
          const yOuter = 50 + (rOuter * Math.sin(angleRad));

          // Inner radius for Minor keys (25% from center)
          const rInner = 28;
          const xInner = 50 + (rInner * Math.cos(angleRad));
          const yInner = 50 + (rInner * Math.sin(angleRad));

          const isSelected = selectedIndex === index;

          return (
            <React.Fragment key={item.major}>
              {/* Major Key Button */}
              <button
                onClick={() => setSelectedIndex(index)}
                className={`absolute w-12 h-12 -ml-6 -mt-6 rounded-full flex items-center justify-center font-bold transition-all duration-300 ${
                  isSelected 
                    ? 'bg-m3-primary text-white scale-110 shadow-lg shadow-m3-primary/30 z-10' 
                    : 'bg-m3-card dark:bg-m3-dark-card text-m3-text dark:text-m3-dark-text border border-m3-border/40 hover:border-m3-primary/50 text-sm'
                }`}
                style={{ left: `${xOuter}%`, top: `${yOuter}%` }}
              >
                {item.major}
              </button>

              {/* Minor Key Button */}
              <button
                onClick={() => setSelectedIndex(index)}
                className={`absolute w-10 h-10 -ml-5 -mt-5 rounded-full flex items-center justify-center font-medium transition-all duration-300 ${
                  isSelected 
                    ? 'bg-m3-primary-light text-m3-primary dark:bg-m3-dark-primary-light dark:text-m3-dark-primary border-m3-primary z-10 font-bold' 
                    : 'bg-transparent text-m3-secondary dark:text-m3-dark-secondary text-xs hover:text-m3-text'
                }`}
                style={{ left: `${xInner}%`, top: `${yInner}%` }}
              >
                {item.minor}
              </button>
            </React.Fragment>
          );
        })}

        {/* Center content */}
        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
           <span className="text-3xl font-black text-m3-primary dark:text-m3-dark-primary">{selectedData.major}</span>
           <span className="text-sm font-bold text-m3-secondary dark:text-m3-dark-secondary mt-1">{selectedData.minor}</span>
        </div>
      </div>

      {/* Degrees Grid */}
      <div className="w-full max-w-sm mt-8 space-y-4">
        <div className="text-center font-bold text-xs text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-widest mb-4">
          Campo Harmónico
        </div>
        
        <div className="grid grid-cols-4 gap-2">
          {selectedData.degrees.map((chord, i) => (
            <div 
              key={i} 
              className={`flex flex-col items-center justify-center p-3 rounded-2xl border transition-all ${
                i === 0 
                  ? 'bg-m3-primary text-white border-m3-primary col-span-2 shadow-md' 
                  : i === 5 
                    ? 'bg-m3-primary-light dark:bg-m3-dark-primary-light text-m3-primary dark:text-m3-dark-primary border-m3-primary/30 col-span-2'
                    : 'bg-m3-card dark:bg-m3-dark-card text-m3-text dark:text-m3-dark-text border-m3-border/40 dark:border-m3-dark-border/40'
              }`}
            >
              <span className={`text-[10px] font-bold opacity-70 mb-1 ${i === 0 || i === 5 ? 'uppercase tracking-widest' : ''}`}>
                {i === 0 ? 'Tónica' : i === 5 ? 'Relativa Menor' : intervals[i].roman}
              </span>
              <span className={`font-black ${i === 0 || i === 5 ? 'text-xl' : 'text-base'}`}>
                {chord}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
