'use client';

import React, { useState } from 'react';
import { ResearchPaper, LiteratureSynthesis } from '@/types/research';
import { Sparkles, Loader2, BookOpen, Layers, CheckCircle2, AlertCircle, ArrowRight } from 'lucide-react';

interface SynthesisViewProps {
  papers: ResearchPaper[];
}

export default function SynthesisView({ papers }: SynthesisViewProps) {
  const [topic, setTopic] = useState('Autonomous multi-agent LLM reasoning and memory verification');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [synthesis, setSynthesis] = useState<LiteratureSynthesis | null>({
    id: 'syn-initial',
    topic: 'Autonomous multi-agent LLM reasoning and memory verification',
    overview: 'Recent advancements in language agent architectures (such as Reflexion and AutoGen) highlight a shift from static prompt generation to dynamic, self-correcting feedback loops. By integrating episodic memory and evaluator-actor abstractions, agents can verify intermediate outputs and mitigate hallucination across complex execution trees. Universal Object References (UOR) further strengthen this ecosystem by anchoring scholarly assertions to cryptographic identifiers.',
    keyThemes: [
      {
        theme: 'Episodic Memory & Self-Reflection',
        description: 'Agents utilize verbal reinforcement learning and trial-and-error memory to refine behavior across iterations.',
        papers: ['Reflexion: Language Agents with Verbal Reinforcement Learning']
      },
      {
        theme: 'Multi-Agent Conversational Abstractions',
        description: 'Coordinating specialized agents through structured messaging protocols to solve multi-step computational tasks.',
        papers: ['AutoGen: Enabling Next-Gen Multi-Agent Conversations']
      },
      {
        theme: 'Cryptographic Provenance & UOR Substrates',
        description: 'Binding research assertions to content-derived addresses to prevent link rot and ensure open science reproducibility.',
        papers: ['Universal Object Reference: A Computational Substrate']
      }
    ],
    methodologies: ['Actor-Evaluator Feedback Loops', 'Decentralized Content Hashing', 'Multi-Agent Message Passing'],
    researchGaps: ['Scalability of agent memory under extremely long context windows', 'Deterministic evaluation metrics for open-ended creative reasoning'],
    futureDirections: ['Integration of hardware-secured UOR nodes with decentralized agent execution networks'],
    createdAt: '2026-03-01'
  });

  const handleSynthesize = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!topic.trim()) return;

    setLoading(true);
    setError(null);

    try {
      const res = await fetch('/api/research/synthesize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ topic, papers })
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed to synthesize literature');

      setSynthesis({
        id: `syn-${Date.now()}`,
        topic,
        overview: data.synthesis.overview,
        keyThemes: data.synthesis.keyThemes || [],
        methodologies: data.synthesis.methodologies || [],
        researchGaps: data.synthesis.researchGaps || [],
        futureDirections: data.synthesis.futureDirections || [],
        createdAt: new Date().toISOString().split('T')[0]
      });
    } catch (err: any) {
      setError(err.message || 'An error occurred during synthesis.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8 pb-12 max-w-5xl mx-auto">
      
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto space-y-3">
        <div className="inline-flex items-center space-x-2 px-3.5 py-1 rounded-full bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 text-xs font-semibold border border-indigo-200 dark:border-indigo-800">
          <Sparkles className="w-3.5 h-3.5" />
          <span>Gemini AI Literature Review Engine</span>
        </div>
        <h1 className="text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Automated Evidence Synthesis
        </h1>
        <p className="text-slate-600 dark:text-slate-300 text-sm">
          Synthesize indexed papers, map research themes, uncover open questions, and generate comprehensive academic reviews powered by PrismPM.
        </p>
      </div>

      {/* Query Input Card */}
      <div className="bg-white dark:bg-slate-800 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm">
        <form onSubmit={handleSynthesize} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold uppercase text-slate-500 dark:text-slate-400 mb-2">
              Research Synthesis Focus / Topic Question
            </label>
            <div className="flex gap-3">
              <input
                type="text"
                required
                value={topic}
                onChange={(e) => setTopic(e.target.value)}
                placeholder="e.g., How do multi-agent memory systems mitigate hallucination?"
                className="flex-1 px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 shadow-sm"
              />
              <button
                type="submit"
                disabled={loading}
                className="px-6 py-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-semibold text-sm transition shadow-md flex items-center space-x-2 shrink-0 disabled:opacity-50"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Synthesizing...</span>
                  </>
                ) : (
                  <>
                    <Sparkles className="w-4 h-4" />
                    <span>Run Synthesis</span>
                  </>
                )}
              </button>
            </div>
          </div>
          <div className="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
            <span>Analyzing {papers.length} indexed papers in active workspace</span>
            <span>Powered by Gemini 2.5 Flash</span>
          </div>
        </form>
      </div>

      {error && (
        <div className="p-4 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 text-red-700 dark:text-red-300 text-sm flex items-center space-x-3">
          <AlertCircle className="w-5 h-5 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {/* Synthesis Results */}
      {synthesis && (
        <div className="space-y-6">
          
          {/* Overview Card */}
          <div className="bg-white dark:bg-slate-800 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-4">
              <div className="flex items-center space-x-2">
                <span className="w-3 h-3 rounded-full bg-indigo-600"></span>
                <h2 className="text-lg font-bold text-slate-900 dark:text-white">Literature Overview & Synthesis</h2>
              </div>
              <span className="text-xs text-slate-400 font-mono">Generated: {synthesis.createdAt}</span>
            </div>
            <p className="text-slate-700 dark:text-slate-300 leading-relaxed text-base">
              {synthesis.overview}
            </p>
          </div>

          {/* Key Themes Grid */}
          <div className="space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">Core Research Themes</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {synthesis.keyThemes.map((item, idx) => (
                <div key={idx} className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm space-y-3">
                  <div className="flex items-center space-x-2">
                    <span className="w-6 h-6 rounded-full bg-indigo-100 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 text-xs font-bold flex items-center justify-center">
                      {idx + 1}
                    </span>
                    <h4 className="font-bold text-slate-900 dark:text-white text-base">{item.theme}</h4>
                  </div>
                  <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
                    {item.description}
                  </p>
                  {item.papers && item.papers.length > 0 && (
                    <div className="pt-2 border-t border-slate-100 dark:border-slate-700/60">
                      <span className="text-xs font-semibold text-slate-400 block mb-1">Associated Sources:</span>
                      <div className="flex flex-wrap gap-1.5">
                        {item.papers.map((p, pIdx) => (
                          <span key={pIdx} className="text-xs px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 truncate max-w-full">
                            {p}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Methodologies & Gaps Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            
            {/* Methodologies */}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm space-y-4">
              <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center space-x-2">
                <Layers className="w-4 h-4 text-indigo-600" />
                <span>Dominant Methodologies</span>
              </h3>
              <ul className="space-y-2">
                {synthesis.methodologies.map((m, idx) => (
                  <li key={idx} className="flex items-start space-x-2 text-sm text-slate-700 dark:text-slate-300 bg-slate-50 dark:bg-slate-900/50 p-3 rounded-xl">
                    <CheckCircle2 className="w-4 h-4 text-emerald-500 mt-0.5 shrink-0" />
                    <span>{m}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* Research Gaps */}
            <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm space-y-4">
              <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center space-x-2">
                <Sparkles className="w-4 h-4 text-amber-500" />
                <span>Open Research Gaps</span>
              </h3>
              <ul className="space-y-2">
                {synthesis.researchGaps.map((g, idx) => (
                  <li key={idx} className="flex items-start space-x-2 text-sm text-slate-700 dark:text-slate-300 bg-slate-50 dark:bg-slate-900/50 p-3 rounded-xl">
                    <ArrowRight className="w-4 h-4 text-amber-500 mt-0.5 shrink-0" />
                    <span>{g}</span>
                  </li>
                ))}
              </ul>
            </div>

          </div>

        </div>
      )}

    </div>
  );
}
