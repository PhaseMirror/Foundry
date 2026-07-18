import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';

// Defined by your WASM output and parsed in useCollatzEngine
export interface CollatzResult {
  start_bound: bigint;
  max_value_reached: bigint;
  max_steps: number;
  cycle_detected: boolean;
}

interface GlassConsoleProps {
  isRunning: boolean;
  currentStart: bigint;
  latestResults: CollatzResult[];
  startEngine: () => void;
  haltEngine: () => void;
  telemetry: {
    msPerChunk: number;
    boundsPerSecond: bigint;
  };
}

export const GlassConsole: React.FC<GlassConsoleProps> = ({
  isRunning,
  currentStart,
  latestResults,
  startEngine,
  haltEngine,
  telemetry,
}) => {
  // Derive aggregate metrics from the latest chunk
  const globalMaxSteps = Math.max(...latestResults.map(r => r.max_steps), 0);
  
  // Sort to find the most "explosive" trajectory in the current buffer
  const peakTrajectory = latestResults.reduce((max, current) => 
    (current.max_value_reached > (max?.max_value_reached || 0n)) ? current : max
  , latestResults[0]);

  return (
    <div className="min-h-screen bg-neutral-950 text-emerald-400 font-mono p-8 selection:bg-emerald-900">
      
      {/* HEADER / CONTROL PANEL */}
      <header className="flex items-center justify-between pb-6 border-b border-white/10 mb-8">
        <div>
          <h1 className="text-2xl tracking-widest font-bold text-white uppercase">
            P²C Witness Calculus
          </h1>
          <p className="text-xs text-neutral-500 mt-1">Collatz Bounded Space Verification</p>
        </div>
        
        <div className="flex gap-4">
          <button 
            onClick={isRunning ? haltEngine : startEngine}
            className={`px-6 py-2 text-sm font-bold tracking-wider uppercase transition-all duration-300 border 
              ${isRunning 
                ? 'bg-red-500/10 border-red-500/50 text-red-500 hover:bg-red-500/20' 
                : 'bg-emerald-500/10 border-emerald-500/50 text-emerald-500 hover:bg-emerald-500/20'
              }`}
          >
            {isRunning ? 'SIG_GOV_KILL' : 'Initialize Engine'}
          </button>
        </div>
      </header>

      {/* DASHBOARD GRID */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* LEFT COLUMN: ACTIVE METRICS (THE GLASS PANELS) */}
        <div className="col-span-1 flex flex-col gap-6">
          
          {/* Engine Status Panel */}
          <div className="bg-white/5 backdrop-blur-md border border-white/10 p-6 rounded-lg relative overflow-hidden">
            <div className="text-xs text-neutral-400 uppercase tracking-widest mb-4">Engine Status</div>
            <div className="flex items-center gap-3">
              <span className="relative flex h-3 w-3">
                {isRunning && <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>}
                <span className={`relative inline-flex rounded-full h-3 w-3 ${isRunning ? 'bg-emerald-500' : 'bg-neutral-600'}`}></span>
              </span>
              <span className="text-lg text-white">
                {isRunning ? 'Iterating 128-bit Span' : 'Halted'}
              </span>
            </div>
          </div>

          {/* Engine Telemetry / Velocity Panel */}
          <div className="bg-white/5 backdrop-blur-md border border-white/10 p-6 rounded-lg relative overflow-hidden">
            {/* Optional subtle animated background glow to indicate extreme velocity */}
            {isRunning && (
              <div className="absolute -inset-4 bg-gradient-to-r from-blue-500/10 to-emerald-500/10 opacity-30 animate-pulse blur-xl pointer-events-none" />
            )}
            
            <div className="text-xs text-blue-400/80 uppercase tracking-widest mb-4">
              Engine Telemetry
            </div>
            
            <div className="flex flex-col gap-3">
              <div className="flex justify-between border-b border-white/5 pb-2">
                <span className="text-neutral-500 text-sm">Compute Delta (ms)</span>
                {/* toFixed(2) keeps the jitter readable */}
                <span className="text-white font-mono">
                  {telemetry.msPerChunk.toFixed(2)} ms
                </span>
              </div>
              
              <div className="flex justify-between">
                <span className="text-neutral-500 text-sm">WASM Throughput</span>
                {/* toLocaleString() adds commas to the BigInt (e.g., 2,400,000 bounds/s) */}
                <span className="text-blue-400 font-mono font-bold">
                  {telemetry.boundsPerSecond.toLocaleString()} / sec
                </span>
              </div>
            </div>
          </div>

          {/* Current Trajectory Vector */}
          <div className="bg-white/5 backdrop-blur-md border border-white/10 p-6 rounded-lg">
             <div className="text-xs text-neutral-400 uppercase tracking-widest mb-4">Current N-Vector</div>
             {/* Using a motion.div to smoothly update the massive integer */}
             <motion.div 
               key={currentStart.toString()}
               initial={{ opacity: 0, y: -10 }}
               animate={{ opacity: 1, y: 0 }}
               className="text-2xl text-white break-all"
             >
               {currentStart.toString()}
             </motion.div>
          </div>

          {/* Local Maxima Panel */}
          <div className="bg-white/5 backdrop-blur-md border border-white/10 p-6 rounded-lg">
             <div className="text-xs text-amber-500/70 uppercase tracking-widest mb-4">Buffer Peak Topology</div>
             <div className="flex flex-col gap-2">
                <div className="flex justify-between border-b border-white/5 pb-2">
                  <span className="text-neutral-500">Seed (n)</span>
                  <span className="text-white">{peakTrajectory?.start_bound.toString() || '0'}</span>
                </div>
                <div className="flex justify-between border-b border-white/5 pb-2">
                  <span className="text-neutral-500">Max Peak</span>
                  <span className="text-amber-400">{peakTrajectory?.max_value_reached.toString() || '0'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-neutral-500">Path Length</span>
                  <span className="text-white">{globalMaxSteps} steps</span>
                </div>
             </div>
          </div>

        </div>

        {/* RIGHT COLUMN: TERMINAL LOG FEED */}
        <div className="col-span-2 bg-black/60 backdrop-blur-lg border border-white/10 p-6 rounded-lg flex flex-col h-[600px]">
          <div className="text-xs text-neutral-400 uppercase tracking-widest mb-4 flex justify-between">
            <span>Live Terminal Feed (Sub-Sampling)</span>
            <span>Batch Size: 10,000</span>
          </div>
          
          <div className="flex-1 overflow-y-auto space-y-1 pr-2 scrollbar-thin scrollbar-thumb-white/10 scrollbar-track-transparent">
            <AnimatePresence initial={false}>
              {/* Only render the last 50 to prevent DOM bloat, since 10,000 is too much for humans to read anyway */}
              {latestResults.slice(-50).reverse().map((res) => (
                <motion.div
                  key={res.start_bound.toString()}
                  layout
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  className="flex gap-4 text-xs font-mono py-1 border-b border-white/5"
                >
                  <span className="text-neutral-600 w-16 shrink-0">[{res.max_steps} stp]</span>
                  <span className="text-emerald-400/80 truncate w-1/2">
                    n = {res.start_bound.toString()}
                  </span>
                  <span className="text-neutral-400 truncate w-1/2 text-right">
                    peak = {res.max_value_reached.toString()}
                  </span>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        </div>

      </div>
    </div>
  );
};
