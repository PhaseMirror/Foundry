'use client';

import React from 'react';
import { motion } from 'motion/react';

export default function PrismTesseractLogo({ className = "w-10 h-10" }: { className?: string }) {
  // Generate spiral nodes data along logarithmic spiral arms
  const nodes = [
    // Core
    { id: 0, x: 25, y: 25, size: 4, type: 'core' },
    // Arm 1
    { id: 1, x: 32, y: 20, size: 2.5, arm: 1 },
    { id: 2, x: 40, y: 22, size: 2, arm: 1 },
    { id: 3, x: 44, y: 32, size: 2, arm: 1 },
    { id: 4, x: 38, y: 42, size: 2.5, arm: 1 },
    { id: 5, x: 25, y: 45, size: 2, arm: 1 },
    // Arm 2
    { id: 6, x: 18, y: 30, size: 2.5, arm: 2 },
    { id: 7, x: 10, y: 28, size: 2, arm: 2 },
    { id: 8, x: 8, y: 18, size: 2, arm: 2 },
    { id: 9, x: 15, y: 10, size: 2.5, arm: 2 },
    { id: 10, x: 28, y: 8, size: 2, arm: 2 },
    // Arm 3 (Outer connecting nodes / bridge)
    { id: 11, x: 42, y: 12, size: 1.5, arm: 3 },
    { id: 12, x: 12, y: 40, size: 1.5, arm: 3 },
  ];

  // Self-organizing network edges connecting nodes
  const edges = [
    { from: 0, to: 1 }, { from: 0, to: 6 }, { from: 0, to: 4 },
    { from: 1, to: 2 }, { from: 2, to: 3 }, { from: 3, to: 4 }, { from: 4, to: 5 },
    { from: 6, to: 7 }, { from: 7, to: 8 }, { from: 8, to: 9 }, { from: 9, to: 10 },
    { from: 2, to: 11 }, { from: 11, to: 3 },
    { from: 7, to: 12 }, { from: 12, to: 5 },
    { from: 1, to: 6 }, { from: 3, to: 9 }
  ];

  return (
    <div className={`relative flex items-center justify-center group cursor-pointer ${className}`}>
      {/* Outer Rotating Prism Containment Ring */}
      <motion.div
        animate={{ rotate: 360 }}
        transition={{ duration: 22, repeat: Infinity, ease: "linear" }}
        className="absolute inset-0 rounded-2xl border border-indigo-500/50 dark:border-indigo-400/60 bg-gradient-to-br from-indigo-500/15 via-violet-500/10 to-purple-600/20 backdrop-blur-xs shadow-lg shadow-indigo-500/10 group-hover:border-indigo-400 transition-colors"
      />

      {/* Secondary Counter-Rotating Geometric Frame */}
      <motion.div
        animate={{ rotate: -360 }}
        transition={{ duration: 16, repeat: Infinity, ease: "linear" }}
        className="absolute inset-1 rounded-xl border border-dashed border-violet-500/30 dark:border-violet-400/40 pointer-events-none"
      />

      {/* Internal Spiral Galaxy Housing with Nodes & Edges */}
      <motion.div
        animate={{ rotate: 360 }}
        transition={{ duration: 28, repeat: Infinity, ease: "linear" }}
        className="absolute inset-1.5 flex items-center justify-center overflow-hidden rounded-lg"
      >
        <svg viewBox="0 0 50 50" className="w-full h-full">
          <defs>
            <radialGradient id="galacticCore" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="#ffffff" stopOpacity="1" />
              <stop offset="40%" stopColor="#818cf8" stopOpacity="0.9" />
              <stop offset="100%" stopColor="#4f46e5" stopOpacity="0" />
            </radialGradient>
            <linearGradient id="edgeGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#c084fc" stopOpacity="0.7" />
              <stop offset="100%" stopColor="#6366f1" stopOpacity="0.25" />
            </linearGradient>
          </defs>

          {/* Background Galactic Nebula Glow */}
          <circle cx="25" cy="25" r="18" fill="url(#galacticCore)" className="animate-pulse" />

          {/* Self-Organizing Edges */}
          {edges.map((edge, idx) => {
            const n1 = nodes[edge.from];
            const n2 = nodes[edge.to];
            return (
              <motion.line
                key={`edge-${idx}`}
                x1={n1.x}
                y1={n1.y}
                x2={n2.x}
                y2={n2.y}
                stroke="url(#edgeGradient)"
                strokeWidth="0.6"
                initial={{ opacity: 0.3 }}
                animate={{ opacity: [0.2, 0.8, 0.2] }}
                transition={{ duration: 2.5 + (idx % 3), repeat: Infinity, ease: "easeInOut" }}
              />
            );
          })}

          {/* Nodes (Stars & Network Hubs) */}
          {nodes.map((node) => (
            <g key={`node-${node.id}`}>
              {node.type === 'core' ? (
                <>
                  <circle cx={node.x} cy={node.y} r={node.size * 1.5} fill="#ffffff" filter="blur(1px)" className="animate-ping" opacity="0.6" />
                  <circle cx={node.x} cy={node.y} r={node.size} fill="#ffffff" className="shadow-glow" />
                </>
              ) : (
                <motion.circle
                  cx={node.x}
                  cy={node.y}
                  r={node.size}
                  fill={node.arm === 1 ? "#d8b4fe" : node.arm === 2 ? "#818cf8" : "#38bdf8"}
                  initial={{ scale: 0.8 }}
                  animate={{ scale: [0.8, 1.35, 0.8], opacity: [0.7, 1, 0.7] }}
                  transition={{ duration: 2 + (node.id % 3), repeat: Infinity, ease: "easeInOut" }}
                />
              )}
            </g>
          ))}
        </svg>
      </motion.div>

      {/* Floating Sparkles */}
      <motion.div
        animate={{ y: [-3, 3, -3], x: [-2, 2, -2], opacity: [0.4, 1, 0.4] }}
        transition={{ duration: 3.5, repeat: Infinity, ease: "easeInOut" }}
        className="absolute -top-0.5 -right-0.5 w-1.5 h-1.5 rounded-full bg-cyan-300 shadow-glow pointer-events-none"
      />
      <motion.div
        animate={{ y: [2, -2, 2], x: [2, -2, 2], opacity: [0.5, 0.9, 0.5] }}
        transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
        className="absolute -bottom-0.5 -left-0.5 w-1 h-1 rounded-full bg-purple-300 shadow-glow pointer-events-none"
      />
    </div>
  );
}
