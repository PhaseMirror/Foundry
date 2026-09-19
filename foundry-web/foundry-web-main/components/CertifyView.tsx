'use client';

import React, { useState } from 'react';
import { 
  ShieldCheck, 
  Lock, 
  FileText, 
  CheckCircle2, 
  AlertTriangle, 
  Users, 
  Plus, 
  ExternalLink, 
  FileCode, 
  Terminal, 
  Check, 
  Clock,
  Layers,
  Award
} from 'lucide-react';

interface CreationItem {
  id: string;
  title: string;
  kappaHash: string;
  legalPerson: string;
  status: 'Self-attested' | 'Co-signed' | 'Requested' | 'Event recorded';
  date: string;
  gatesClosed: number;
}

const INITIAL_CREATIONS: CreationItem[] = [
  {
    id: 'cre-001',
    title: 'P2C PETC v1.2 Observable Wire Protocol',
    kappaHash: 'uor:ref:kappa:p2c-petc-v12:a9f2b',
    legalPerson: 'Operator LLC / Citizen Gardens UNA',
    status: 'Event recorded',
    date: '2026-09-15',
    gatesClosed: 4
  },
  {
    id: 'cre-002',
    title: 'CSM-001 Cryptographic Software Module Kernel',
    kappaHash: 'uor:ref:kappa:csm-001-kernel:b4e18',
    legalPerson: 'Operator LLC',
    status: 'Requested',
    date: '2026-09-17',
    gatesClosed: 2
  },
  {
    id: 'cre-003',
    title: 'Lawful Recursion Version 1.0 Specs',
    kappaHash: 'uor:ref:kappa:lawful-recursion:c7d31',
    legalPerson: 'Citizen Gardens UNA',
    status: 'Co-signed',
    date: '2026-09-18',
    gatesClosed: 1
  }
];

export default function CertifyView() {
  const [activeTab, setActiveTab] = useState<'library' | 'sheet' | 'gates' | 'rules'>('library');
  const [creations, setCreations] = useState<CreationItem[]>(INITIAL_CREATIONS);
  const [selectedCreation, setSelectedCreation] = useState<CreationItem>(INITIAL_CREATIONS[0]);

  // New Creation Modal state
  const [isNewModalOpen, setIsNewModalOpen] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newPerson, setNewPerson] = useState('Operator LLC');

  // Gate simulation state
  const [gates, setGates] = useState([
    { id: 1, title: 'Mastery', closed: true, desc: 'Examiner records demonstrated work meets adopted playbook.' },
    { id: 2, title: 'Vertical Playbook', closed: true, desc: 'Named playbook version + hash mapped to work.' },
    { id: 3, title: 'Compliance Clearance', closed: false, desc: 'No open C-control POA&M; civic L0 cited where applicable.' },
    { id: 4, title: 'Supervised Engagement', closed: false, desc: 'Logged supervised session with named practice-seat supervisor.' },
  ]);

  const handleToggleGate = (gateId: number) => {
    setGates(prev => prev.map(g => g.id === gateId ? { ...g, closed: !g.closed } : g));
  };

  const handleCreateCreation = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;

    const newItem: CreationItem = {
      id: `cre-${Date.now()}`,
      title: newTitle,
      kappaHash: `uor:ref:kappa:${newTitle.toLowerCase().replace(/\s+/g, '-')}:${Date.now().toString(36)}`,
      legalPerson: newPerson,
      status: 'Self-attested',
      date: new Date().toISOString().split('T')[0],
      gatesClosed: 0
    };

    setCreations(prev => [newItem, ...prev]);
    setSelectedCreation(newItem);
    setIsNewModalOpen(false);
    setNewTitle('');
  };

  return (
    <div className="space-y-8 pb-16">
      
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-violet-950 via-indigo-900 to-slate-900 text-white p-6 sm:p-8 rounded-2xl shadow-xl border border-indigo-900/50">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2 text-xs font-mono text-indigo-300 uppercase tracking-wider mb-1">
              <span>FWP-ATTEST-001</span>
              <span>•</span>
              <span>18 September 2026</span>
              <span>•</span>
              <span>C-24 Lock</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight flex items-center space-x-3">
              <ShieldCheck className="w-7 h-7 text-indigo-400" />
              <span>Certify — Founder Creation Attestation View</span>
            </h1>
            <p className="text-sm text-indigo-200/80 mt-1 max-w-2xl">
              app.uor.foundation/creations — A UI for attesting uniqueness, not a diploma printer. Self-attest, co-sign, and credential request remain separate acts.
            </p>
          </div>
          <div className="flex items-center space-x-2 bg-indigo-900/60 border border-indigo-700/60 px-4 py-2.5 rounded-xl text-xs font-mono">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
            <span>app.uor.foundation/creations</span>
          </div>
        </div>
      </div>

      {/* Sub-Navigation Tabs */}
      <div className="flex flex-wrap items-center gap-2 border-b border-slate-200 dark:border-slate-800 pb-4">
        {[
          { id: 'library', label: '1. Library (/creations)' },
          { id: 'sheet', label: '2. Attestation Sheet (/creations/{κ})' },
          { id: 'gates', label: '3. Four-Gate Request (/request)' },
          { id: 'rules', label: '4. Fail-Closed Rules & Levers' },
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition ${
              activeTab === tab.id
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab 1: Library */}
      {activeTab === 'library' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div>
                <h3 className="text-lg font-bold text-slate-900 dark:text-white">Founder Creations & Attestation Library</h3>
                <p className="text-sm text-slate-500 dark:text-slate-400">Select a creation payload κ to view its attestation sheet and four-gate status.</p>
              </div>
              <button
                onClick={() => setIsNewModalOpen(true)}
                className="inline-flex items-center space-x-2 px-4 py-2.5 rounded-xl bg-indigo-600 text-white font-semibold text-sm hover:bg-indigo-700 transition shadow-sm shrink-0"
              >
                <Plus className="w-4 h-4" />
                <span>Register Creation Payload</span>
              </button>
            </div>

            <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 dark:bg-slate-800 text-xs uppercase text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <tr>
                    <th className="px-4 py-3">Creation Title & Kappa Hash</th>
                    <th className="px-4 py-3">Legal Person</th>
                    <th className="px-4 py-3">Attestation Status</th>
                    <th className="px-4 py-3">Gates Closed</th>
                    <th className="px-4 py-3 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                  {creations.map(item => {
                    const isSelected = selectedCreation.id === item.id;
                    return (
                      <tr key={item.id} className={isSelected ? 'bg-indigo-50/50 dark:bg-indigo-950/40' : ''}>
                        <td className="px-4 py-3">
                          <div className="font-bold text-slate-900 dark:text-white">{item.title}</div>
                          <div className="font-mono text-xs text-indigo-600 dark:text-indigo-400 mt-0.5">{item.kappaHash}</div>
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600 dark:text-slate-300">{item.legalPerson}</td>
                        <td className="px-4 py-3">
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold ${
                            item.status === 'Event recorded' 
                              ? 'bg-emerald-100 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-900'
                              : item.status === 'Requested'
                              ? 'bg-amber-100 dark:bg-amber-950 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-900'
                              : 'bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-900'
                          }`}>
                            {item.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-sm font-mono text-slate-600 dark:text-slate-300">{item.gatesClosed} / 4 gates</td>
                        <td className="px-4 py-3 text-right">
                          <button
                            onClick={() => { setSelectedCreation(item); setActiveTab('sheet'); }}
                            className="px-3.5 py-1.5 rounded-lg bg-indigo-50 dark:bg-indigo-950 text-indigo-600 dark:text-indigo-400 hover:bg-indigo-100 text-xs font-semibold transition"
                          >
                            Open Sheet →
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Tab 2: Attestation Sheet */}
      {activeTab === 'sheet' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 dark:border-slate-800 pb-4">
              <div>
                <span className="text-xs font-mono text-indigo-600 dark:text-indigo-400 font-semibold block mb-1">
                  {selectedCreation.kappaHash}
                </span>
                <h2 className="text-xl font-bold text-slate-900 dark:text-white">{selectedCreation.title}</h2>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Custodian / Legal Person: {selectedCreation.legalPerson}</p>
              </div>
              <div className="flex items-center space-x-3">
                <span className="px-3 py-1 rounded-full text-xs font-semibold bg-violet-100 dark:bg-violet-950 text-violet-700 dark:text-violet-300 border border-violet-200 dark:border-violet-900">
                  Status: {selectedCreation.status}
                </span>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              
              {/* Act 1: Self-attest */}
              <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="font-bold text-slate-900 dark:text-white text-sm">1. Self-Attest (Authored / Controlled)</h4>
                  <span className="text-xs font-mono text-emerald-600 dark:text-emerald-400 font-semibold">Attested</span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                  Signed assertion: I authored or control this payload κ. Grants self-attested status on the attestation sheet.
                </p>
                <button
                  onClick={() => alert('Self-attestation signature cryptographically pinned to session controller.')}
                  className="w-full py-2.5 rounded-xl bg-indigo-600 text-white text-xs font-semibold hover:bg-indigo-700 transition shadow-xs"
                >
                  Renew Self-Attestation Signature
                </button>
              </div>

              {/* Act 2: Co-sign */}
              <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="font-bold text-slate-900 dark:text-white text-sm">2. Co-Sign (Peer Assertion)</h4>
                  <span className="text-xs font-mono text-indigo-600 dark:text-indigo-400 font-semibold">2 Co-signers</span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                  Named holders already on an edge attach saw / reviewed / co-signed. Register search is closed (L0-3).
                </p>
                <button
                  onClick={() => alert('Co-signature request dispatched to closed neighbor ring.')}
                  className="w-full py-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-300 text-xs font-semibold hover:bg-slate-100 dark:hover:bg-slate-800 transition shadow-xs"
                >
                  Request Neighbor Co-Sign
                </button>
              </div>

              {/* Act 3: Credential Request */}
              <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="font-bold text-slate-900 dark:text-white text-sm">3. Credential Request (Four Gates)</h4>
                  <span className="text-xs font-mono text-amber-600 dark:text-amber-400 font-semibold">{selectedCreation.gatesClosed}/4 Gates</span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                  Packet to an Examiner through mastery, playbook, clearance, and supervised engagement. Never Certified.
                </p>
                <button
                  onClick={() => setActiveTab('gates')}
                  className="w-full py-2.5 rounded-xl bg-violet-600 text-white text-xs font-semibold hover:bg-violet-700 transition shadow-xs"
                >
                  Manage Four-Gate Packet →
                </button>
              </div>

              {/* Act 4: Pin External Evidence */}
              <div className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="font-bold text-slate-900 dark:text-white text-sm">4. Pin External Evidence (E4+)</h4>
                  <span className="text-xs font-mono text-slate-500 font-semibold">Optional</span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                  Store a lab / CMVP / third-party PDF as evidence at E4. Does not write Certified or Event recorded.
                </p>
                <button
                  onClick={() => alert('External evidence PDF pinned with hash checksum.')}
                  className="w-full py-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-slate-700 dark:text-slate-300 text-xs font-semibold hover:bg-slate-100 dark:hover:bg-slate-800 transition shadow-xs"
                >
                  Pin Lab Report / Certificate PDF
                </button>
              </div>

            </div>
          </div>
        </div>
      )}

      {/* Tab 3: Four-Gate Request */}
      {activeTab === 'gates' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
            <div>
              <h3 className="text-lg font-bold text-slate-900 dark:text-white">3. Four-Gate Request Packet (/request)</h3>
              <p className="text-sm text-slate-500 dark:text-slate-400">All four gates must be closed by an Examiner before a credential event can be recorded.</p>
            </div>

            <div className="space-y-4">
              {gates.map((gate) => (
                <div 
                  key={gate.id}
                  onClick={() => handleToggleGate(gate.id)}
                  className={`p-4 rounded-xl border transition cursor-pointer flex items-center justify-between ${
                    gate.closed
                      ? 'bg-emerald-50/50 dark:bg-emerald-950/30 border-emerald-200 dark:border-emerald-900 text-slate-900 dark:text-white'
                      : 'bg-slate-50 dark:bg-slate-800/60 border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300'
                  }`}
                >
                  <div className="flex items-center space-x-3">
                    <div className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0 ${
                      gate.closed ? 'bg-emerald-600 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-500'
                    }`}>
                      {gate.closed ? <Check className="w-4 h-4" /> : <Clock className="w-4 h-4" />}
                    </div>
                    <div>
                      <h4 className="font-bold text-sm">Gate {gate.id}: {gate.title}</h4>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">{gate.desc}</p>
                    </div>
                  </div>
                  <span className={`text-xs px-2.5 py-1 rounded-full font-semibold ${
                    gate.closed ? 'bg-emerald-100 dark:bg-emerald-900 text-emerald-700 dark:text-emerald-300' : 'bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
                  }`}>
                    {gate.closed ? 'Closed by Examiner' : 'Open / Pending'}
                  </span>
                </div>
              ))}
            </div>

            <div className="p-4 rounded-xl bg-indigo-50/60 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-900 text-xs text-indigo-900 dark:text-indigo-200 space-y-1">
              <strong>C-24 Credential Event Rule:</strong> When all four gates have Examiner receipts, the packet is eligible for a credential event. Eligibility is not the event. The event is recorded by the named authority of Citizen Gardens UNA as a hashed artifact.
            </div>
          </div>
        </div>
      )}

      {/* Tab 4: Fail-Closed Rules & Levers */}
      {activeTab === 'rules' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">4. Default Posture — Fail-Closed Rules (F-ATTEST-01–10)</h3>
            
            <div className="space-y-3">
              {[
                { id: 'F-ATTEST-01', rule: 'No button, export, badge, or Open Graph tag on this view contains the word Certified.' },
                { id: 'F-ATTEST-02', rule: 'Self-attest cannot be issued on a payload the session does not control.' },
                { id: 'F-ATTEST-03', rule: 'Co-sign picker is the closed picker from FWP-DOC-001. Register search is closed (L0-3).' },
                { id: 'F-ATTEST-04', rule: 'Credential request without all four gate slots modeled fails closed. Partial packets stay Requested.' },
                { id: 'F-ATTEST-05', rule: 'Examiner controls hide for anyone ≥10% of the operator or holding an operator board seat.' },
                { id: 'F-ATTEST-06', rule: 'Youth creations require guardian co-sign on every attestation write (L0-6).' },
                { id: 'F-ATTEST-07', rule: 'Withdrawal of a self-attest, co-sign, or request is logged, not argued (L0-7). Public cards update.' },
                { id: 'F-ATTEST-08', rule: 'An exam fee on /shop does not write Event recorded. Money is not a gate.' },
                { id: 'F-ATTEST-09', rule: 'Credits, tokens, and M = 2R + 1 do not overweight a credential event (L0-8).' },
                { id: 'F-ATTEST-10', rule: 'Invented guilds, invented boards, and invented diploma authorities are not vertex types.' },
              ].map(item => (
                <div key={item.id} className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 flex items-start space-x-3">
                  <span className="font-mono text-xs px-2 py-1 rounded bg-violet-100 dark:bg-violet-950 text-violet-700 dark:text-violet-300 font-semibold shrink-0">
                    {item.id}
                  </span>
                  <p className="text-sm text-slate-700 dark:text-slate-300">{item.rule}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* New Creation Modal */}
      {isNewModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 max-w-md w-full p-6 shadow-2xl space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">Register Creation Payload κ</h3>
            <form onSubmit={handleCreateCreation} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Creation Title</label>
                <input
                  type="text"
                  required
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="e.g., Quantum Memory Dispatcher"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold uppercase text-slate-500 mb-1">Legal Person / Custodian</label>
                <select
                  value={newPerson}
                  onChange={(e) => setNewPerson(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-white text-sm"
                >
                  <option value="Operator LLC">Operator LLC</option>
                  <option value="Citizen Gardens UNA">Citizen Gardens UNA</option>
                  <option value="Founder Member">Founder Member</option>
                </select>
              </div>
              <div className="flex justify-end space-x-3 pt-2">
                <button
                  type="button"
                  onClick={() => setIsNewModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-sm font-medium text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-sm font-semibold bg-indigo-600 text-white hover:bg-indigo-700 shadow-sm"
                >
                  Register Payload
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
