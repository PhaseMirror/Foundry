'use client';

import React, { useState } from 'react';
import { 
  Folder, 
  FileCode, 
  FileText, 
  Terminal as TerminalIcon, 
  Sparkles, 
  Play, 
  Send, 
  Copy, 
  Check, 
  ChevronRight, 
  ChevronDown, 
  Layers, 
  Cpu, 
  ShieldCheck, 
  Hammer,
  Search,
  Maximize2,
  RefreshCw
} from 'lucide-react';

interface CorpusFile {
  path: string;
  name: string;
  type: 'markdown' | 'typescript' | 'json' | 'css';
  content: string;
}

const CORPUS_FILES: CorpusFile[] = [
  {
    path: 'docs/FWP-001.md',
    name: 'FWP-001.md',
    type: 'markdown',
    content: `# FOUNDRY WEB PORTAL (FWP-001)
*Status: Binding view contract under FWP-001, FWP-DOC-001, PrismPM-BP-001 C-24.*

## Core Thesis
The Foundry Web Portal is an autonomous research and cryptographic verification interface. It does not mint certified badges from profile resolution; OSCAL is the filing cabinet, PrismPM is the lock, and Certified is a separate credential event (C-24).

### Key Architectural Invariants
1. **No Unsolicited SDK Integrations**: Strict scope adherence.
2. **Fail-Closed Posture**: Missing C-controls or gateway failures block acceptance.
3. **Two Persons, Two Seats, Four Doors**: Separation of practice, equity, and examiner roles.
`
  },
  {
    path: 'docs/PrismPM-WF-001.md',
    name: 'PrismPM-WF-001.md',
    type: 'markdown',
    content: `# PRISMPM WORKFLOW & SHAPE (PrismPM-WF-001)
*From idea and profile to a cryptographic software module.*

## The Stations
- **Idea (Foundry Concept)**: Kappa object + idea-of on /foundry/inbox.
- **Catalog (Define)**: Pin PRISMPM-CAT-BASE + additive FIPS 140-3 catalogs.
- **Profile (Select)**: Resolve PRISMPM-PRF-BASE. Every C-02–C-24 required.
- **Component Definition**: Cryptographic boundary, approved services, key material, self-tests.
- **SSP / Implementation / Assessed / Accepted**: Claim ladder progression.
`
  },
  {
    path: 'docs/FWP-ATTEST-001.md',
    name: 'FWP-ATTEST-001.md',
    type: 'markdown',
    content: `# FOUNDER CREATION ATTESTATION VIEW (FWP-ATTEST-001)
*app.uor.foundation/creations — a UI for attesting uniqueness, not a diploma printer.*

## Four Acts, Four Objects
1. **Self-attest**: Signed assertion of authoring or control over payload κ.
2. **Co-sign**: Named holders on an edge attach reviews.
3. **Credential request**: Packet to an Examiner through mastery, playbook, clearance, and supervised engagement.
4. **Credential event**: Named authority of Citizen Gardens UNA records that four gates closed (C-24).
`
  },
  {
    path: 'docs/FWP-TRAIN-001.md',
    name: 'FWP-TRAIN-001.md',
    type: 'markdown',
    content: `# TRAINING PLAYGROUND VIEW (FWP-TRAIN-001)
*app.uor.foundation/train — the bench a founder can use without a lord.*

## Curriculum Spine
Five infrastructure cards as playbooks:
- UNA / DUNA
- Buurtzorg (Node ≤ 12, split not manage)
- Bushidō (Duty cards)
- Phase Mirror (Extract, Map, Rank)
- Multiplicity (M = 2R + 1)
`
  },
  {
    path: 'src/db/schema.ts',
    name: 'schema.ts',
    type: 'typescript',
    content: `// UOR Foundry Database Schema (Drizzle ORM)
import { pgTable, text, timestamp, jsonb, boolean } from 'drizzle-orm/pg-core';

export const projectsTable = pgTable('projects', {
  id: text('id').primaryKey(),
  title: text('title').notNull(),
  description: text('description'),
  uorHash: text('uor_hash').notNull(),
  createdAt: timestamp('created_at').defaultNow(),
  papersCount: text('papers_count').default('0'),
});

export const corpusFilesTable = pgTable('corpus_files', {
  path: text('path').primaryKey(),
  content: text('content').notNull(),
  updatedAt: timestamp('updated_at').defaultNow(),
});
`
  },
  {
    path: 'package.json',
    name: 'package.json',
    type: 'json',
    content: `{
  "name": "uor-foundry-workbench",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "@google/genai": "^0.1.1",
    "lucide-react": "^1.16.0",
    "next": "15.1.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
`
  }
];

export default function DashboardIdeView() {
  const [files, setFiles] = useState<CorpusFile[]>(CORPUS_FILES);
  const [activeFile, setActiveFile] = useState<CorpusFile>(CORPUS_FILES[0]);
  const [terminalInput, setTerminalInput] = useState('');
  const [terminalLogs, setTerminalLogs] = useState<string[]>([
    'UOR Foundry IDE Kernel v2026.9 initialized.',
    'Connected to local corpus tree (6 files indexed).',
    'Type "prismpm model check" or "help" for available verbs.'
  ]);
  const [copilotInput, setCopilotInput] = useState('');
  const [copilotMessages, setCopilotMessages] = useState<Array<{role: 'user' | 'assistant', text: string}>>([
    { role: 'assistant', text: 'Hello, Dr. Vance. I am your Prism Copilot. How can I assist you with analyzing the FWP corpus or verifying C-24 cryptographic locks today?' }
  ]);
  const [isCopilotLoading, setIsCopilotLoading] = useState(false);
  const [copied, setCopied] = useState(false);

  const handleRunTerminal = (e: React.FormEvent) => {
    e.preventDefault();
    if (!terminalInput.trim()) return;

    const cmd = terminalInput.trim();
    const newLogs = [...terminalLogs, `$ ${cmd}`];

    if (cmd === 'prismpm model check') {
      newLogs.push('[PASS] F-01 through F-18 predicate checks cleared.');
      newLogs.push('[PASS] CSM-001 boundary verified: no membership lists inside crypto boundary.');
    } else if (cmd === 'prismpm profile resolve') {
      newLogs.push('[OK] PRISMPM-PRF-BASE resolved with 24 C-controls.');
      newLogs.push('[OK] C-24 credential event restriction intact.');
    } else if (cmd === 'help') {
      newLogs.push('Available commands: prismpm model check, prismpm profile resolve, prismpm chain show, npm run build, clear');
    } else if (cmd === 'clear') {
      setTerminalLogs(['UOR Foundry IDE Kernel v2026.9 initialized.']);
      setTerminalInput('');
      return;
    } else {
      newLogs.push(`Command executed: ${cmd}. Exit code 0.`);
    }

    setTerminalLogs(newLogs);
    setTerminalInput('');
  };

  const handleSendCopilot = (e: React.FormEvent) => {
    e.preventDefault();
    if (!copilotInput.trim() || isCopilotLoading) return;

    const userMsg = copilotInput.trim();
    setCopilotMessages(prev => [...prev, { role: 'user', text: userMsg }]);
    setCopilotInput('');
    setIsCopilotLoading(true);

    setTimeout(() => {
      let reply = 'I have analyzed the current corpus file and verified that all C-24 fail-closed invariants are respected.';
      if (userMsg.toLowerCase().includes('c-24') || userMsg.toLowerCase().includes('certified')) {
        reply = 'C-24 mandates that Certified is a separate credential event under association authority. Profile machinery and OSCAL export will never print Certified.';
      } else if (userMsg.toLowerCase().includes('four gates') || userMsg.toLowerCase().includes('gate')) {
        reply = 'The four gates (Mastery, Vertical Playbook, Compliance Clearance, Supervised Engagement) must all be closed by an Examiner before a credential event packet is eligible.';
      }
      setCopilotMessages(prev => [...prev, { role: 'assistant', text: reply }]);
      setIsCopilotLoading(false);
    }, 700);
  };

  const handleCopyCode = () => {
    navigator.clipboard.writeText(activeFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="h-[calc(100vh-2rem)] flex flex-col bg-white dark:bg-slate-900 overflow-hidden font-sans">
      
      {/* Main IDE Workspace */}
      <div className="flex-1 flex overflow-hidden">
        
        {/* Left Sidebar: File Tree */}
        <div className="w-72 bg-slate-50 dark:bg-slate-950 border-r border-slate-200 dark:border-slate-800 flex flex-col">
          <div className="p-3.5 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between text-xs font-bold uppercase tracking-wider text-slate-500">
            <span>Corpus Tree</span>
            <Folder className="w-4 h-4 text-indigo-500" />
          </div>
          <div className="p-2 space-y-1 overflow-y-auto flex-1 font-mono text-xs">
            <div className="text-slate-400 px-2 py-1 font-semibold">📁 /docs (Specifications)</div>
            {files.filter(f => f.path.startsWith('docs/')).map(file => (
              <button
                key={file.path}
                onClick={() => setActiveFile(file)}
                className={`w-full text-left px-3 py-2 rounded-lg flex items-center space-x-2 transition ${
                  activeFile.path === file.path 
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-800'
                }`}
              >
                <FileText className="w-3.5 h-3.5 shrink-0" />
                <span className="truncate">{file.name}</span>
              </button>
            ))}

            <div className="text-slate-400 px-2 pt-3 pb-1 font-semibold">📁 /src & Config</div>
            {files.filter(f => !f.path.startsWith('docs/')).map(file => (
              <button
                key={file.path}
                onClick={() => setActiveFile(file)}
                className={`w-full text-left px-3 py-2 rounded-lg flex items-center space-x-2 transition ${
                  activeFile.path === file.path 
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-800'
                }`}
              >
                <FileCode className="w-3.5 h-3.5 shrink-0" />
                <span className="truncate">{file.name}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Center Main Pane: Document Viewer & Terminal */}
        <div className="flex-1 flex flex-col overflow-hidden bg-white dark:bg-slate-900">
          
          {/* File Tab Header */}
          <div className="bg-slate-100 dark:bg-slate-800/80 border-b border-slate-200 dark:border-slate-800 px-4 py-2 flex items-center justify-between text-xs font-mono">
            <div className="flex items-center space-x-2 text-slate-700 dark:text-slate-200 font-semibold">
              <FileText className="w-4 h-4 text-indigo-500" />
              <span>{activeFile.path}</span>
            </div>
            <button
              onClick={handleCopyCode}
              className="inline-flex items-center space-x-1.5 px-3 py-1 rounded-md bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 hover:bg-slate-50 transition text-slate-700 dark:text-slate-300"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
              <span>{copied ? 'Copied' : 'Copy Content'}</span>
            </button>
          </div>

          {/* Document Content Viewer */}
          <div className="flex-1 p-6 overflow-y-auto font-mono text-xs sm:text-sm text-slate-800 dark:text-slate-200 leading-relaxed whitespace-pre-wrap bg-white dark:bg-slate-900">
            {activeFile.content}
          </div>

          {/* Bottom Terminal Panel */}
          <div className="h-44 border-t border-slate-200 dark:border-slate-800 bg-slate-950 text-slate-300 flex flex-col font-mono text-xs">
            <div className="px-4 py-2 bg-slate-900 border-b border-slate-800 flex items-center justify-between">
              <div className="flex items-center space-x-2 text-slate-400">
                <TerminalIcon className="w-3.5 h-3.5 text-emerald-400" />
                <span className="font-bold text-slate-200">Integrated Terminal</span>
              </div>
              <span className="text-slate-500">bash • port 3000</span>
            </div>
            <div className="flex-1 p-3 overflow-y-auto space-y-1 text-slate-300">
              {terminalLogs.map((log, idx) => (
                <div key={idx} className={log.startsWith('$') ? 'text-indigo-300 font-bold' : log.includes('[PASS]') || log.includes('[OK]') ? 'text-emerald-400' : 'text-slate-300'}>
                  {log}
                </div>
              ))}
            </div>
            <form onSubmit={handleRunTerminal} className="p-2 bg-slate-900 border-t border-slate-800 flex items-center space-x-2">
              <span className="text-emerald-400 font-bold">$</span>
              <input
                type="text"
                value={terminalInput}
                onChange={(e) => setTerminalInput(e.target.value)}
                placeholder="Type command (e.g. prismpm model check)..."
                className="flex-1 bg-transparent border-none outline-none text-slate-100 font-mono text-xs"
              />
              <button type="submit" className="px-3 py-1 rounded bg-indigo-600 text-white font-semibold text-xs hover:bg-indigo-700 transition">
                Run
              </button>
            </form>
          </div>

        </div>

        {/* Right Sidebar: Copilot Chat Panel */}
        <div className="w-80 bg-slate-50 dark:bg-slate-950 border-l border-slate-200 dark:border-slate-800 flex flex-col">
          <div className="p-3.5 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between text-xs font-bold uppercase tracking-wider text-slate-500">
            <div className="flex items-center space-x-2">
              <Sparkles className="w-4 h-4 text-violet-500" />
              <span>Prism Copilot</span>
            </div>
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          </div>

          <div className="flex-1 p-3 overflow-y-auto space-y-3 font-sans text-xs">
            {copilotMessages.map((msg, idx) => (
              <div key={idx} className={`p-3 rounded-xl space-y-1 ${
                msg.role === 'assistant'
                  ? 'bg-indigo-50 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-900 text-indigo-950 dark:text-indigo-200'
                  : 'bg-slate-200 dark:bg-slate-800 text-slate-900 dark:text-slate-100 ml-4'
              }`}>
                <div className="font-bold text-[10px] uppercase opacity-70">
                  {msg.role === 'assistant' ? 'Gemini Copilot' : 'You'}
                </div>
                <p className="leading-relaxed">{msg.text}</p>
              </div>
            ))}
            {isCopilotLoading && (
              <div className="p-3 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-900 text-indigo-600 animate-pulse">
                Thinking & analyzing corpus...
              </div>
            )}
          </div>

          <form onSubmit={handleSendCopilot} className="p-3 border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 flex items-center space-x-2">
            <input
              type="text"
              value={copilotInput}
              onChange={(e) => setCopilotInput(e.target.value)}
              placeholder="Ask Copilot about corpus..."
              className="flex-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs text-slate-900 dark:text-white outline-none"
            />
            <button
              type="submit"
              disabled={isCopilotLoading}
              className="p-2 rounded-xl bg-indigo-600 text-white hover:bg-indigo-700 transition disabled:opacity-50"
            >
              <Send className="w-4 h-4" />
            </button>
          </form>
        </div>

      </div>

    </div>
  );
}
