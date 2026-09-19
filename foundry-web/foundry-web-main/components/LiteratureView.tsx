'use client';

import React, { useState } from 'react';
import { ResearchPaper, ResearchProject } from '@/types/research';
import { 
  FileText, 
  Shield, 
  Lock, 
  Users, 
  Globe, 
  Key, 
  Plus, 
  Trash2, 
  Check, 
  ExternalLink, 
  Sparkles, 
  AlertCircle,
  HelpCircle,
  UserCheck,
  Calendar,
  Layers
} from 'lucide-react';

interface LiteratureViewProps {
  papers: ResearchPaper[];
  projects: ResearchProject[];
  onAddPaper: (paper: ResearchPaper) => void;
  initialSearchQuery?: string;
}

interface GrantRecord {
  id: string;
  holder: string;
  verb: 'view' | 'comment' | 'attest' | 'edit';
  horizon: string;
  status: 'ACTIVE' | 'EXPIRED' | 'WITHDRAWN';
}

export default function LiteratureView({ papers, projects, onAddPaper, initialSearchQuery = '' }: LiteratureViewProps) {
  const [searchQuery, setSearchQuery] = useState(initialSearchQuery);
  const [selectedGrantState, setSelectedGrantState] = useState<'all' | 'Private' | 'Node occupancy' | 'Named grant' | 'Published'>('all');
  
  // Active control sheet view (payload_κ) or null (library list)
  const [activeControlPayload, setActiveControlPayload] = useState<ResearchPaper | null>(null);

  // Grant dialog state
  const [isGrantDialogOpen, setIsGrantDialogOpen] = useState(false);
  const [grantHolderInput, setGrantHolderInput] = useState('');
  const [grantVerb, setGrantVerb] = useState<'view' | 'comment' | 'attest' | 'edit'>('view');
  const [grantHorizon, setGrantHorizon] = useState('+1y');
  const [youthCoSign, setYouthCoSign] = useState(false);

  // Mock grants for the active control sheet
  const [grantsList, setGrantsList] = useState<GrantRecord[]>([
    { id: 'g-1', holder: 'Capability holder — Natural person - verified edge', verb: 'view', horizon: 'This object — Until withdrawn', status: 'ACTIVE' },
    { id: 'g-2', holder: 'Node-scoped grant — Sovereignty Node #12', verb: 'comment', horizon: 'Dies when chair empty', status: 'ACTIVE' },
    { id: 'g-3', holder: 'Examiner practice seat — Candidate #089', verb: 'attest', horizon: '30 days', status: 'ACTIVE' },
  ]);

  // Visibility state per paper (mocked)
  const [documentVisibilities, setDocumentVisibilities] = useState<Record<string, string>>({
    'paper-1': 'Private',
    'paper-2': 'Node occupancy',
    'paper-3': 'Named grant',
    'paper-4': 'Published',
    'paper-5': 'Private (Privacy-zone)'
  });

  const handleVisibilityChange = (paperId: string, vis: string) => {
    setDocumentVisibilities(prev => ({ ...prev, [paperId]: vis }));
  };

  const handleWithdrawGrant = (grantId: string) => {
    setGrantsList(prev => prev.map(g => g.id === grantId ? { ...g, status: 'WITHDRAWN' } : g));
  };

  const handleWithdrawAll = () => {
    setGrantsList(prev => prev.map(g => ({ ...g, status: 'WITHDRAWN' })));
  };

  const handleIssueGrantSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!grantHolderInput) return;

    const newGrant: GrantRecord = {
      id: `grant-${Date.now()}`,
      holder: grantHolderInput,
      verb: grantVerb,
      horizon: grantHorizon,
      status: 'ACTIVE'
    };

    setGrantsList(prev => [newGrant, ...prev]);
    setIsGrantDialogOpen(false);
    setGrantHolderInput('');
  };

  const filteredPapers = papers.filter(p => {
    const matchesSearch = p.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.uorRef.toLowerCase().includes(searchQuery.toLowerCase());
    
    const vis = documentVisibilities[p.id] || 'Private';
    const matchesState = selectedGrantState === 'all' || 
      (selectedGrantState === 'Private' && vis.includes('Private')) ||
      (selectedGrantState === 'Node occupancy' && vis === 'Node occupancy') ||
      (selectedGrantState === 'Named grant' && vis === 'Named grant') ||
      (selectedGrantState === 'Published' && vis === 'Published');

    return matchesSearch && matchesState;
  });

  return (
    <div className="space-y-6 pb-16">
      
      {/* Top Banner & Context Header */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 text-white p-6 rounded-2xl shadow-xl border border-indigo-900/50">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2 text-xs font-mono text-indigo-300 uppercase tracking-wider mb-1">
              <span>Citizen Gardens UNA</span>
              <span>•</span>
              <span>FWP-DOC-001</span>
              <span>•</span>
              <span>Document Control View</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight">Documents</h1>
            <p className="text-sm text-indigo-200/80 mt-1">
              <span className="font-mono text-indigo-300">app.uor.foundation/docs</span> — sharing is a grant the founder writes, and can withdraw.
            </p>
          </div>
          <div className="flex items-center space-x-3 bg-slate-800/80 border border-slate-700/80 px-4 py-2.5 rounded-xl backdrop-blur-sm self-start md:self-auto">
            <div className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
            <div className="text-xs">
              <p className="text-slate-400 font-medium">Session Identity</p>
              <p className="font-semibold text-white">Dr. Eleanor Vance · uniqueness card</p>
            </div>
          </div>
        </div>
      </div>

      {/* If activeControlPayload is set, show Control Sheet (/docs/{payload_κ}) */}
      {activeControlPayload ? (
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xl overflow-hidden">
          {/* Control Sheet Header */}
          <div className="bg-slate-50 dark:bg-slate-800/70 p-6 border-b border-slate-200 dark:border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <button
                onClick={() => setActiveControlPayload(null)}
                className="text-xs font-semibold text-indigo-600 dark:text-indigo-400 hover:underline mb-2 inline-flex items-center space-x-1"
              >
                <span>← Back to /docs Library</span>
              </button>
              <h2 className="text-xl font-bold text-slate-900 dark:text-white">
                Control Sheet: {activeControlPayload.title}
              </h2>
            </div>
            <button
              onClick={() => setIsGrantDialogOpen(true)}
              className="inline-flex items-center space-x-2 px-4 py-2.5 rounded-xl bg-indigo-600 text-white font-semibold text-sm hover:bg-indigo-700 transition shadow-sm self-start"
            >
              <Plus className="w-4 h-4" />
              <span>Issue grant ↗</span>
            </button>
          </div>

          <div className="p-6 sm:p-8 space-y-6">
            
            {/* Addresses Box */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 p-4 rounded-xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700/60 font-mono text-xs">
              <div>
                <span className="text-slate-400 block mb-0.5">Payload κ</span>
                <span className="text-indigo-600 dark:text-indigo-400 font-semibold">{activeControlPayload.uorRef}</span>
              </div>
              <div>
                <span className="text-slate-400 block mb-0.5">Pin κ</span>
                <span className="text-slate-700 dark:text-slate-300">pin:0x9f8e...7d6c</span>
              </div>
              <div>
                <span className="text-slate-400 block mb-0.5">View κ</span>
                <span className="text-slate-700 dark:text-slate-300">view:0x5b4c...3a2b</span>
              </div>
            </div>

            {/* Legal Person Banner */}
            <div className="p-4 rounded-xl bg-indigo-50/60 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-900 flex items-center justify-between">
              <div>
                <span className="text-xs font-semibold uppercase text-indigo-700 dark:text-indigo-300">Legal Person of this object</span>
                <p className="text-sm font-bold text-slate-900 dark:text-white">Citizen Gardens UNA</p>
              </div>
              <span className="px-3 py-1 rounded-full bg-indigo-200/60 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200 text-xs font-semibold">
                Verified Controller
              </span>
            </div>

            {/* Visibility State Selector */}
            <div className="space-y-3">
              <h3 className="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400 tracking-wider">
                Visibility State (Writes grants; does not patch file)
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                {[
                  { id: 'Private', label: 'Private', desc: 'Controller only (plus guardian on youth objects).' },
                  { id: 'Named grant', label: 'Named grant', desc: 'Holders with existing edge or pasted capability.' },
                  { id: 'Node occupancy', label: 'Node occupancy', desc: 'Current occupants of one named Sovereignty Node (≤ 12).' },
                  { id: 'Published', label: 'Literary public', desc: 'Public visitor, after PrismPM accept-gate.' },
                ].map(state => {
                  const currentVis = documentVisibilities[activeControlPayload.id] || 'Private';
                  const isChecked = currentVis === state.id;
                  return (
                    <div
                      key={state.id}
                      onClick={() => handleVisibilityChange(activeControlPayload.id, state.id)}
                      className={`p-4 rounded-xl border transition cursor-pointer flex flex-col justify-between ${
                        isChecked
                          ? 'bg-indigo-50 dark:bg-indigo-950/60 border-indigo-500 shadow-sm'
                          : 'bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700 hover:border-slate-300'
                      }`}
                    >
                      <div className="flex items-center space-x-2 mb-2">
                        <div className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                          isChecked ? 'border-indigo-600 bg-indigo-600 text-white' : 'border-slate-400'
                        }`}>
                          {isChecked && <div className="w-1.5 h-1.5 rounded-full bg-white" />}
                        </div>
                        <span className="font-semibold text-sm text-slate-900 dark:text-white">{state.label}</span>
                      </div>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{state.desc}</p>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Grants Table */}
            <div className="space-y-4 pt-4 border-t border-slate-100 dark:border-slate-800">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="font-bold text-slate-900 dark:text-white">Active Grants & Capabilities</h3>
                  <p className="text-xs text-slate-500">Every issue and withdrawal is a UCC-shaped receipt (hash + version + build + time).</p>
                </div>
                <button
                  onClick={handleWithdrawAll}
                  className="px-3 py-1.5 rounded-lg border border-red-200 dark:border-red-900/60 text-red-600 dark:text-red-400 text-xs font-semibold hover:bg-red-50 dark:hover:bg-red-950/40 transition flex items-center space-x-1.5"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  <span>Withdraw All</span>
                </button>
              </div>

              <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
                <table className="w-full text-left text-sm">
                  <thead className="bg-slate-50 dark:bg-slate-800 text-xs uppercase text-slate-500 dark:text-slate-400 border-b border-slate-200 dark:border-slate-700">
                    <tr>
                      <th className="px-4 py-3">Holder</th>
                      <th className="px-4 py-3">Verb</th>
                      <th className="px-4 py-3">Horizon</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3 text-right">Withdraw</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 dark:divide-slate-700 bg-white dark:bg-slate-900">
                    {grantsList.map((g) => (
                      <tr key={g.id} className={g.status === 'WITHDRAWN' ? 'opacity-50 line-through bg-slate-50 dark:bg-slate-800/30' : ''}>
                        <td className="px-4 py-3 font-mono text-xs text-slate-900 dark:text-white">{g.holder}</td>
                        <td className="px-4 py-3 font-semibold uppercase text-xs text-indigo-600 dark:text-indigo-400">{g.verb}</td>
                        <td className="px-4 py-3 text-xs text-slate-600 dark:text-slate-300">{g.horizon}</td>
                        <td className="px-4 py-3">
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${
                            g.status === 'ACTIVE' ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300' : 'bg-red-100 text-red-800 dark:bg-red-950 dark:text-red-300'
                          }`}>
                            {g.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-right">
                          {g.status === 'ACTIVE' && (
                            <button
                              onClick={() => handleWithdrawGrant(g.id)}
                              className="p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950 transition"
                              title="Withdraw grant"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Banner Notice */}
              <div className="p-4 rounded-xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/60 flex items-center space-x-3 text-amber-800 dark:text-amber-300 text-xs">
                <AlertCircle className="w-5 h-5 shrink-0" />
                <span><strong>The membership list is not a picker.</strong> Invite only holders you already have an edge to (Civic L0-3).</span>
              </div>
            </div>

          </div>
        </div>
      ) : (
        /* Library View (/docs) */
        <div className="space-y-6">
          
          {/* Grant-State Filter Tabs */}
          <div className="flex flex-wrap items-center gap-2 border-b border-slate-200 dark:border-slate-800 pb-4">
            {[
              { id: 'all', label: 'All Documents' },
              { id: 'Private', label: 'Private' },
              { id: 'Node occupancy', label: 'Node occupancy' },
              { id: 'Named grant', label: 'Named grant' },
              { id: 'Published', label: 'Published' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setSelectedGrantState(tab.id as any)}
                className={`px-4 py-2 rounded-xl text-sm font-semibold transition ${
                  selectedGrantState === tab.id
                    ? 'bg-indigo-600 text-white shadow-sm'
                    : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* Search bar */}
          <div className="relative">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search documents by title or payload hash (κ)..."
              className="w-full pl-4 pr-4 py-3 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-900 dark:text-white text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 shadow-sm"
            />
          </div>

          {/* Documents Table / Cards */}
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-sm overflow-hidden">
            <div className="divide-y divide-slate-100 dark:divide-slate-800">
              {filteredPapers.length === 0 ? (
                <div className="p-12 text-center text-slate-400">
                  No documents found matching the selected grant state.
                </div>
              ) : (
                filteredPapers.map((paper) => {
                  const vis = documentVisibilities[paper.id] || 'Private';
                  const isPrivacyZone = vis.includes('Privacy-zone') || paper.id === 'paper-5';
                  return (
                    <div 
                      key={paper.id}
                      className="p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-slate-50/80 dark:hover:bg-slate-800/40 transition"
                    >
                      <div className="space-y-1.5 flex-1">
                        <div className="flex items-center space-x-2">
                          <span className="font-mono text-xs text-indigo-600 dark:text-indigo-400 font-semibold">{paper.uorRef}</span>
                          <span className="text-slate-300 dark:text-slate-700">•</span>
                          <span className="text-xs px-2 py-0.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 font-medium">
                            Citizen Gardens UNA
                          </span>
                        </div>
                        <h3 className="font-bold text-base text-slate-900 dark:text-white">
                          {paper.title}
                        </h3>
                        <p className="text-xs text-slate-500 dark:text-slate-400 line-clamp-1">
                          {paper.abstract}
                        </p>
                      </div>

                      <div className="flex items-center space-x-3 shrink-0">
                        {isPrivacyZone ? (
                          <span className="px-3 py-1 rounded-full text-xs font-semibold bg-red-100 dark:bg-red-950/80 text-red-700 dark:text-red-300 border border-red-200 dark:border-red-900">
                            Privacy zone — no public share
                          </span>
                        ) : (
                          <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                            vis === 'Published' 
                              ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300'
                              : vis === 'Node occupancy'
                              ? 'bg-purple-100 text-purple-800 dark:bg-purple-950 dark:text-purple-300'
                              : 'bg-indigo-100 text-indigo-800 dark:bg-indigo-950 dark:text-indigo-300'
                          }`}>
                            {vis}
                          </span>
                        )}

                        <button
                          onClick={() => setActiveControlPayload(paper)}
                          className="px-4 py-2 rounded-xl bg-slate-900 dark:bg-slate-800 text-white hover:bg-indigo-600 dark:hover:bg-indigo-600 transition text-xs font-semibold shadow-sm"
                        >
                          Manage access
                        </button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          {/* Footer Notice */}
          <div className="p-4 rounded-xl bg-slate-100 dark:bg-slate-900 text-slate-600 dark:text-slate-400 text-xs flex items-center justify-between">
            <span>Public visitors never see this index. Session chip reads &ldquo;Founder · uniqueness card.&rdquo;</span>
            <span className="font-mono">FWP-DOC-001 §10.1</span>
          </div>

        </div>
      )}

      {/* Grant Dialog Modal (/docs/{payload_κ}/grant) */}
      {isGrantDialogOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 max-w-lg w-full p-6 shadow-2xl space-y-6">
            
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-4">
              <div>
                <h3 className="text-lg font-bold text-slate-900 dark:text-white">Issue a grant — not a mailing list</h3>
                <p className="text-xs text-slate-500">Register search is closed (civic L0-3).</p>
              </div>
              <button 
                onClick={() => setIsGrantDialogOpen(false)}
                className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleIssueGrantSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">1) Holder Capability Address</label>
                <input
                  type="text"
                  required
                  value={grantHolderInput}
                  onChange={(e) => setGrantHolderInput(e.target.value)}
                  placeholder="Paste capability address or pick from existing edges..."
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">2) Verb (Bounded)</label>
                <div className="grid grid-cols-4 gap-2">
                  {(['view', 'comment', 'attest', 'edit'] as const).map(v => (
                    <button
                      key={v}
                      type="button"
                      onClick={() => setGrantVerb(v)}
                      className={`py-2 rounded-xl text-xs font-bold uppercase transition ${
                        grantVerb === v
                          ? 'bg-indigo-600 text-white shadow-sm'
                          : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200'
                      }`}
                    >
                      {v}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">3) Horizon Date</label>
                <div className="grid grid-cols-4 gap-2">
                  {['+30d', '+90d', '+1y', '+2y'].map(h => (
                    <button
                      key={h}
                      type="button"
                      onClick={() => setGrantHorizon(h)}
                      className={`py-2 rounded-xl text-xs font-semibold transition ${
                        grantHorizon === h
                          ? 'bg-indigo-600 text-white shadow-sm'
                          : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200'
                      }`}
                    >
                      {h}
                    </button>
                  ))}
                </div>
              </div>

              <div className="flex items-center space-x-3 p-3 rounded-xl bg-slate-50 dark:bg-slate-800/50">
                <input
                  type="checkbox"
                  id="youthCheck"
                  checked={youthCoSign}
                  onChange={(e) => setYouthCoSign(e.target.checked)}
                  className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500"
                />
                <label htmlFor="youthCheck" className="text-xs text-slate-700 dark:text-slate-300">
                  <strong>Youth document (civic L0-6):</strong> Guardian co-sign required or write fails closed.
                </label>
              </div>

              <div className="p-3 rounded-xl bg-indigo-50 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-900 text-xs text-indigo-800 dark:text-indigo-300">
                <strong>Phase Mirror Note:</strong> The Mirror names if this grant would become a manager costume or a fifth door. It does not auto-approve.
              </div>

              <div className="flex justify-end space-x-3 pt-4 border-t border-slate-100 dark:border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsGrantDialogOpen(false)}
                  className="px-4 py-2 rounded-xl text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-sm font-semibold bg-indigo-600 text-white hover:bg-indigo-700 shadow-sm"
                >
                  Write grant receipt
                </button>
              </div>
            </form>

          </div>
        </div>
      )}

    </div>
  );
}
