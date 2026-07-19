import React, { useState, useEffect, useRef } from 'react';
import { Play, Square, Plus, Minus, Flame } from 'lucide-react';

export default function Metronome() {
  const [bpm, setBpm] = useState<number>(120);
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [beatsPerMeasure, setBeatsPerMeasure] = useState<number>(4);
  const [currentBeat, setCurrentBeat] = useState<number>(0);
  
  const timerRef = useRef<number | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const nextNoteTimeRef = useRef<number>(0);
  const tapTimesRef = useRef<number[]>([]);

  // Calculate BPM on Tap
  const handleTap = () => {
    const now = performance.now();
    const times = tapTimesRef.current;
    times.push(now);
    
    // Keep last 4 taps
    if (times.length > 4) {
      times.shift();
    }
    
    if (times.length > 1) {
      const intervals: number[] = [];
      for (let i = 1; i < times.length; i++) {
        intervals.push(times[i] - times[i - 1]);
      }
      const averageInterval = intervals.reduce((sum, val) => sum + val, 0) / intervals.length;
      const calculatedBPM = Math.round(60000 / averageInterval);
      if (calculatedBPM >= 30 && calculatedBPM <= 250) {
        setBpm(calculatedBPM);
      }
    }
  };

  // Initialize AudioContext
  useEffect(() => {
    audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)();
    return () => {
      if (audioContextRef.current?.state !== 'closed') {
        audioContextRef.current?.close();
      }
    };
  }, []);

  const playClick = (time: number, isFirstBeat: boolean) => {
    if (!audioContextRef.current) return;
    
    const osc = audioContextRef.current.createOscillator();
    const gainNode = audioContextRef.current.createGain();
    
    osc.connect(gainNode);
    gainNode.connect(audioContextRef.current.destination);
    
    osc.frequency.value = isFirstBeat ? 880 : 440; // Higher pitch for first beat
    
    // Envelope to make it clicky
    gainNode.gain.setValueAtTime(1, time);
    gainNode.gain.exponentialRampToValueAtTime(0.001, time + 0.05);
    
    osc.start(time);
    osc.stop(time + 0.05);
  };

  const scheduleNotes = () => {
    if (!audioContextRef.current) return;
    
    // While there are notes that will need to play before the next interval, schedule them
    while (nextNoteTimeRef.current < audioContextRef.current.currentTime + 0.1) {
      setCurrentBeat(prev => {
        const beat = (prev + 1) % beatsPerMeasure;
        playClick(nextNoteTimeRef.current, beat === 0);
        return beat;
      });
      
      const secondsPerBeat = 60.0 / bpm;
      nextNoteTimeRef.current += secondsPerBeat;
    }
    
    timerRef.current = window.setTimeout(scheduleNotes, 25);
  };

  useEffect(() => {
    if (isPlaying) {
      if (audioContextRef.current?.state === 'suspended') {
        audioContextRef.current.resume();
      }
      nextNoteTimeRef.current = audioContextRef.current!.currentTime + 0.05;
      setCurrentBeat(-1); // Reset so the first beat played is beat 0
      scheduleNotes();
    } else {
      if (timerRef.current !== null) {
        window.clearTimeout(timerRef.current);
        timerRef.current = null;
      }
    }
    
    return () => {
      if (timerRef.current !== null) {
        window.clearTimeout(timerRef.current);
      }
    };
  }, [isPlaying, bpm, beatsPerMeasure]);

  const handleToggle = () => setIsPlaying(!isPlaying);

  return (
    <div className="flex-1 overflow-y-auto p-4 pt-10 md:pt-14 space-y-8 no-scrollbar pb-24 flex flex-col items-center justify-start md:justify-center">
      <div className="text-center">
        <p className="text-xs font-bold text-m3-secondary dark:text-m3-dark-secondary">
          Mantenha o tempo exato para os seus ensaios
        </p>
      </div>

      <div className="bg-m3-card dark:bg-m3-dark-card p-8 rounded-[40px] shadow-sm border border-m3-border/40 w-full max-w-sm flex flex-col items-center">
        
        {/* BPM Display */}
        <div className="text-7xl font-black text-m3-primary dark:text-m3-dark-primary tracking-tighter mb-2 select-none">
          {bpm}
        </div>
        <div className="text-xs font-bold text-m3-secondary dark:text-m3-dark-secondary uppercase tracking-widest mb-6">
          BPM
        </div>

        {/* BPM Controls */}
        <div className="flex items-center gap-6 mb-6 w-full">
          <button 
            onClick={() => setBpm(b => Math.max(30, b - 1))}
            className="w-12 h-12 rounded-full bg-m3-sidebar dark:bg-m3-dark-sidebar flex items-center justify-center border border-m3-border/50 hover:bg-m3-hover dark:hover:bg-m3-dark-hover active:scale-95 transition-all text-m3-text dark:text-m3-dark-text shrink-0"
          >
            <Minus className="w-5 h-5" />
          </button>
          
          <input 
            type="range" 
            min="30" max="250" 
            value={bpm} 
            onChange={(e) => setBpm(Number(e.target.value))}
            className="w-full accent-m3-primary h-2 bg-m3-border/30 rounded-full appearance-none outline-none cursor-pointer"
          />
          
          <button 
            onClick={() => setBpm(b => Math.min(250, b + 1))}
            className="w-12 h-12 rounded-full bg-m3-sidebar dark:bg-m3-dark-sidebar flex items-center justify-center border border-m3-border/50 hover:bg-m3-hover dark:hover:bg-m3-dark-hover active:scale-95 transition-all text-m3-text dark:text-m3-dark-text shrink-0"
          >
            <Plus className="w-5 h-5" />
          </button>
        </div>

        {/* Tap Tempo Button */}
        <button
          onClick={handleTap}
          className="w-full mb-8 py-3 px-4 rounded-2xl bg-m3-sidebar dark:bg-m3-dark-sidebar border border-m3-border/40 hover:border-m3-primary/40 text-xs font-bold text-m3-text dark:text-m3-dark-text flex items-center justify-center gap-2 transition-all active:scale-[0.98]"
        >
          <Flame className="w-4 h-4 text-m3-primary dark:text-m3-dark-primary" />
          <span>Marcar Andamento (Tap Tempo)</span>
        </button>

        {/* Time Signature Controls */}
        <div className="flex gap-2 mb-8">
          {[2, 3, 4, 5, 6].map(beats => (
             <button
               key={beats}
               onClick={() => {
                 setBeatsPerMeasure(beats);
                 setCurrentBeat(0);
               }}
               className={`w-10 h-10 rounded-xl flex items-center justify-center font-bold text-sm transition-all ${
                 beatsPerMeasure === beats
                   ? 'bg-m3-primary text-white shadow-md'
                   : 'bg-m3-sidebar dark:bg-m3-dark-sidebar text-m3-secondary dark:text-m3-dark-secondary border border-m3-border/30 hover:border-m3-primary/50'
               }`}
             >
               {beats}/4
             </button>
          ))}
        </div>

        {/* Beat Indicators */}
        <div className="flex gap-3 mb-10 h-4">
          {Array.from({ length: beatsPerMeasure }).map((_, i) => (
            <div 
              key={i}
              className={`w-4 h-4 rounded-full transition-all duration-75 ${
                isPlaying && currentBeat === i 
                  ? i === 0 
                    ? 'bg-m3-primary scale-125 shadow-md' 
                    : 'bg-m3-primary/60 scale-110'
                  : 'bg-m3-border dark:bg-m3-dark-border'
              }`}
            />
          ))}
        </div>

        {/* Play/Pause Button */}
        <button 
          onClick={handleToggle}
          className={`w-20 h-20 rounded-full flex items-center justify-center text-white shadow-lg transition-all active:scale-95 ${
            isPlaying ? 'bg-red-500 hover:bg-red-600 shadow-red-500/30' : 'bg-m3-primary hover:bg-m3-primary/90 shadow-m3-primary/30'
          }`}
        >
          {isPlaying ? <Square className="w-8 h-8 fill-current" /> : <Play className="w-8 h-8 fill-current ml-1" />}
        </button>

      </div>
    </div>
  );
}
