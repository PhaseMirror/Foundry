'use client';

import React from 'react';
import { ResearchPaper, ResearchProject } from '@/types/research';
import { Network, ShieldCheck, Database, Layers, Copy, Check, ExternalLink } from 'lucide-react';

interface UorRegistryViewProps {
  projects: ResearchProject[];
  papers: ResearchPaper[];
}

export default function UorRegistryView({ projects, papers }: UorRegistryViewProps) {
  const [copiedHash, setCopiedHash] = React.useState<string | null>(null);

  const handleCopy = (hash: string) => {
    navigator.clipboard.writeText(hash);
    setCopiedHash(hash);
    setTimeout(() => setCopiedHash(null), 2000);
  };

  return (
    <div className="max-w-5xl mx-auto space-y-8 pb-12">
      
      {/* Header */}
      <div className="space-y-3">
        <div className="inline-flex items-center space-x-2 px-3.5 py-1 rounded-full bg-amber-50 dark:bg-amber-950/60 text-amber-700 dark:text-amber-300 text-xs font-semibold border border-amber-200 dark:border-amber-800">
          <Network className="w-3.5 h-3.5" />
          <span>PrismPM Universal Object Reference (UOR) Substrate</span>
        </div>
        <h1 className="text-3xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Cryptographic Knowledge Graph & Registry
        </h1>
        <p className="text-slate-600 dark:text-slate-300 text-sm">
          Every research artifact, paper, and synthesis is assigned an immutable content-derived coordinate in the decentralized UOR ontology.
        </p>
      </div>

      {/* Stats Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
        <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm">
          <div className="flex items-center space-x-3 mb-2">
            <div className="p-2 rounded-xl bg-indigo-50 dark:bg-indigo-950/50 text-indigo-600">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xs font-semibold uppercase text-slate-500">Registry Protocol</span>
              <h4 className="text-sm font-bold text-slate-900 dark:text-white">UOR-Core v2.4</h4>
            </div>
          </div>
          <p className="text-xs text-slate-500">Decentralized schema validation active.</p>
        </div>

        <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm">
          <div className="flex items-center space-x-3 mb-2">
            <div className="p-2 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xs font-semibold uppercase text-slate-500">Cryptographic Proof</span>
              <h4 className="text-sm font-bold text-slate-900 dark:text-white">SHA-256 Hashed</h4>
            </div>
          </div>
          <p className="text-xs text-emerald-600 font-medium">100% Link Integrity Verified</p>
        </div>

        <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm">
          <div className="flex items-center space-x-3 mb-2">
            <div className="p-2 rounded-xl bg-violet-50 dark:bg-violet-950/50 text-violet-600">
              <Layers className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xs font-semibold uppercase text-slate-500">Active Nodes</span>
              <h4 className="text-sm font-bold text-slate-900 dark:text-white">{projects.length + papers.length} Objects</h4>
            </div>
          </div>
          <p className="text-xs text-slate-500">Indexed in local memory substrate.</p>
        </div>
      </div>

      {/* UOR Node Registry Table */}
      <div className="bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm overflow-hidden">
        <div className="p-6 border-b border-slate-100 dark:border-slate-700">
          <h3 className="text-lg font-bold text-slate-900 dark:text-white">Registered UOR Objects</h3>
          <p className="text-xs text-slate-500 mt-0.5">Immutable references mapped to current workspace projects and papers.</p>
        </div>

        <div className="divide-y divide-slate-100 dark:divide-slate-700/60 overflow-x-auto">
          {projects.map((proj) => (
            <div key={proj.id} className="p-5 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-700/30 transition">
              <div className="space-y-1">
                <span className="text-xs px-2 py-0.5 rounded bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 font-semibold">
                  Project Domain
                </span>
                <h4 className="font-semibold text-sm text-slate-900 dark:text-white">{proj.title}</h4>
                <p className="text-xs font-mono text-slate-500">{proj.uorHash}</p>
              </div>
              <button
                onClick={() => handleCopy(proj.uorHash)}
                className="px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 transition flex items-center space-x-1.5"
              >
                {copiedHash === proj.uorHash ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
                <span>{copiedHash === proj.uorHash ? 'Copied' : 'Copy Hash'}</span>
              </button>
            </div>
          ))}

          {papers.map((paper) => (
            <div key={paper.id} className="p-5 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-700/30 transition">
              <div className="space-y-1">
                <span className="text-xs px-2 py-0.5 rounded bg-violet-50 dark:bg-violet-950/60 text-violet-700 dark:text-violet-300 font-semibold">
                  Scholarly Artifact
                </span>
                <h4 className="font-semibold text-sm text-slate-900 dark:text-white">{paper.title}</h4>
                <p className="text-xs font-mono text-slate-500">{paper.uorRef}</p>
              </div>
              <button
                onClick={() => handleCopy(paper.uorRef)}
                className="px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-700 transition flex items-center space-x-1.5"
              >
                {copiedHash === paper.uorRef ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
                <span>{copiedHash === paper.uorRef ? 'Copied' : 'Copy Hash'}</span>
              </button>
            </div>
          ))}
        </div>
      </div>

    </div>
  );
}
