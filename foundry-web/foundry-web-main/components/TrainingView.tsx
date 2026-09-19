'use client';

import React, { useState } from 'react';
import { 
  Compass, 
  BookOpen, 
  Users, 
  ShieldCheck, 
  Layers, 
  CheckCircle2, 
  AlertTriangle, 
  Terminal, 
  FileCode, 
  Lock, 
  ExternalLink,
  Plus,
  Clock,
  Check,
  UserCheck
} from 'lucide-react';

interface Playbook {
  id: string;
  title: string;
  code: string;
  description: string;
  category: string;
  completed: boolean;
}

const INITIAL_PLAYBOOKS: Playbook[] = [
  {
    id: 'pb-001',
    title: 'Year-One Kernel (UCC-YK-001)',
    code: 'UCC-YK-001',
    description: 'Universal Cryptographic Credential receipt shape: hash + version + build + time.',
    category: 'Infrastructures',
    completed: true,
  },
  {
    id: 'pb-002',
    title: 'Grant a Document (FWP-DOC-001)',
    code: 'FWP-DOC-001',
    description: 'Attest grant, closed register picker, and access sheet management.',
    category: 'Playbooks',
    completed: true,
  },
  {
    id: 'pb-003',
    title: 'Name a Dissonance (PM-HE-001)',
    code: 'PM-HE-001',
    description: 'Dissonance register entry and public 90-day metric card protocol.',
    category: 'Playbooks',
    completed: false,
  },
  {
    id: 'pb-004',
    title: 'Four Doors & Two Seats',
    code: 'FWP-001 §9',
    description: 'Distinguishing practice, operator equity, examiner firewall, and gift remittance.',
    category: 'Playbooks',
    completed: false,
  },
  {
    id: 'pb-005',
    title: 'Attest a Creation (FWP-ATTEST-001)',
    code: 'FWP-ATTEST-001',
    description: 'Self-attest, co-sign, and four-gate request without printing Certified.',
    category: 'Playbooks',
    completed: false,
  },
];

interface CohortRoom {
  periodId: string;
  name: string;
  occupancy: number;
  maxCapacity: number;
  supervisor: string;
}

const INITIAL_ROOMS: CohortRoom[] = [
  { periodId: 'prd-2026-q3-08', name: 'Foundry Node Alpha (Prism Core)', occupancy: 8, maxCapacity: 12, supervisor: 'Dr. Eleanor Vance (Practice Seat)' },
  { periodId: 'prd-2026-q3-09', name: 'Citizen Gardens Open Cohort', occupancy: 12, maxCapacity: 12, supervisor: 'Guardian Marcus' },
  { periodId: 'prd-2026-q3-10', name: 'Operator LLC Cryptographic Sandbox', occupancy: 5, maxCapacity: 12, supervisor: 'Operator Board' },
];

export default function TrainingView() {
  const [activeTab, setActiveTab] = useState<'home' | 'playbooks' | 'rooms' | 'rules'>('home');
  const [playbooks, setPlaybooks] = useState<Playbook[]>(INITIAL_PLAYBOOKS);
  const [rooms, setRooms] = useState<CohortRoom[]>(INITIAL_ROOMS);
  
  // Selected playbook for exercise runner
  const [selectedPb, setSelectedPb] = useState<Playbook>(INITIAL_PLAYBOOKS[0]);
  const [exerciseDraft, setExerciseDraft] = useState('# Founder Exercise Draft\nOwner: Operator LLC\nMetric: ||Δ|| < ε\nHorizon: 90 days');
  const [receiptLog, setReceiptLog] = useState<string | null>(null);

  const handleCloseExercise = () => {
    setReceiptLog(`RECEIPT: hash=0x8f3c2... | version=1.0 | build=lean4-kani | time=${new Date().toISOString()}`);
    setPlaybooks(prev => prev.map(p => p.id === selectedPb.id ? { ...p, completed: true } : p));
  };

  const handleJoinRoom = (room: CohortRoom) => {
    if (room.occupancy >= room.maxCapacity) {
      alert('Room cap of 12 (Hundian limit) reached. Joining refused; split offered.');
      return;
    }
    setRooms(prev => prev.map(r => r.periodId === room.periodId ? { ...r, occupancy: r.occupancy + 1 } : r));
    alert(`Successfully joined room ${room.name}. Role class: co-learner / peer.`);
  };

  return (
    <div className="space-y-8 pb-16">
      
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 text-white p-6 sm:p-8 rounded-2xl shadow-xl border border-indigo-900/50">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2 text-xs font-mono text-indigo-300 uppercase tracking-wider mb-1">
              <span>FWP-TRAIN-001</span>
              <span>•</span>
              <span>18 September 2026</span>
              <span>•</span>
              <span>Training Playground</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight flex items-center space-x-3">
              <Compass className="w-7 h-7 text-indigo-400" />
              <span>Training Playground View (/train)</span>
            </h1>
            <p className="text-sm text-indigo-200/80 mt-1 max-w-2xl">
              The bench a founder can use without a lord, and without a diploma printer. Five infrastructures as playbooks, rooms that split at 12, and zero Certified diplomas.
            </p>
          </div>
          <div className="flex items-center space-x-2 bg-indigo-900/60 border border-indigo-700/60 px-4 py-2.5 rounded-xl text-xs font-mono">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
            <span>app.uor.foundation/train</span>
          </div>
        </div>
      </div>

      {/* Sub-Navigation Tabs */}
      <div className="flex flex-wrap items-center gap-2 border-b border-slate-200 dark:border-slate-800 pb-4">
        {[
          { id: 'home', label: '1. Infrastructure Spine (/train)' },
          { id: 'playbooks', label: '2. Playbook Runner (/playbooks)' },
          { id: 'rooms', label: '3. Cohort Rooms (/rooms)' },
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

      {/* Tab 1: Infrastructure Spine */}
      {activeTab === 'home' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
            <div>
              <span className="text-xs font-mono text-indigo-600 dark:text-indigo-400 font-semibold uppercase tracking-wider">The Curriculum Spine</span>
              <h3 className="text-xl font-bold text-slate-900 dark:text-white mt-1">Five Infrastructure Cards</h3>
              <p className="text-sm text-slate-500 dark:text-slate-400 mt-0.5">Playbooks are anchored in the five permanent foundations of the UOR stack, not arbitrary vendor courses.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {[
                { title: '1. UNA / DUNA', desc: 'Legal person, register, one member one vote, four doors.', tag: 'Civic L0' },
                { title: '2. Buurtzorg', desc: 'Node size ≤ 12, split not manage, overhead ≤ 15%.', tag: 'Topology' },
                { title: '3. Bushidō', desc: 'Duty cards, resignation intact, /duty.', tag: 'Operational' },
                { title: '4. Phase Mirror', desc: 'Extract → Map → Rank → levers → one precision question.', tag: 'Epistemic' },
                { title: '5. Multiplicity', desc: 'M = 2R + 1. Reciprocity is social energy. Credits never buy votes.', tag: 'Consensus' },
              ].map((card, idx) => (
                <div key={idx} className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 space-y-2 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-mono text-xs px-2 py-0.5 rounded bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 font-semibold">
                        {card.tag}
                      </span>
                    </div>
                    <h4 className="font-bold text-slate-900 dark:text-white text-base mt-2">{card.title}</h4>
                    <p className="text-xs text-slate-600 dark:text-slate-300 mt-1 leading-relaxed">{card.desc}</p>
                  </div>
                  <button
                    onClick={() => setActiveTab('playbooks')}
                    className="mt-4 text-xs font-semibold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center space-x-1"
                  >
                    <span>Browse Playbooks →</span>
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Tab 2: Playbook Runner */}
      {activeTab === 'playbooks' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Playbook List */}
          <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4 lg:col-span-1">
            <h3 className="font-bold text-slate-900 dark:text-white text-base">Day-One Playbooks</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400">Select an exercise to load into the draft runner.</p>
            
            <div className="space-y-2.5">
              {playbooks.map(pb => {
                const isSelected = selectedPb.id === pb.id;
                return (
                  <div
                    key={pb.id}
                    onClick={() => { setSelectedPb(pb); setReceiptLog(null); }}
                    className={`p-3.5 rounded-xl border transition cursor-pointer flex items-center justify-between ${
                      isSelected 
                        ? 'bg-indigo-50 dark:bg-indigo-950/50 border-indigo-300 dark:border-indigo-800'
                        : 'bg-slate-50 dark:bg-slate-800/60 border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800'
                    }`}
                  >
                    <div>
                      <div className="font-bold text-sm text-slate-900 dark:text-white">{pb.title}</div>
                      <div className="font-mono text-xs text-indigo-600 dark:text-indigo-400 mt-0.5">{pb.code}</div>
                    </div>
                    {pb.completed && (
                      <span className="p-1 rounded-full bg-emerald-100 dark:bg-emerald-950 text-emerald-600">
                        <Check className="w-3.5 h-3.5" />
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Exercise Runner & Draft */}
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6 lg:col-span-2">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-4">
              <div>
                <span className="text-xs font-mono text-indigo-600 dark:text-indigo-400 font-semibold">{selectedPb.code}</span>
                <h3 className="text-xl font-bold text-slate-900 dark:text-white mt-0.5">{selectedPb.title}</h3>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">{selectedPb.description}</p>
              </div>
            </div>

            <div className="space-y-4">
              <label className="block text-xs font-semibold uppercase text-slate-500">Exercise Draft & Parameters</label>
              <textarea
                rows={6}
                value={exerciseDraft}
                onChange={(e) => setExerciseDraft(e.target.value)}
                className="w-full p-4 rounded-xl font-mono text-xs bg-slate-50 dark:bg-slate-800 border border-slate-300 dark:border-slate-700 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />

              <div className="flex items-center justify-between pt-2">
                <button
                  onClick={handleCloseExercise}
                  className="px-5 py-2.5 rounded-xl bg-indigo-600 text-white font-semibold text-xs hover:bg-indigo-700 transition shadow-sm"
                >
                  Close This Exercise (Emit Receipt)
                </button>
                <span className="text-xs text-slate-400">Status: In playground — not Certified</span>
              </div>

              {receiptLog && (
                <div className="p-4 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 border border-emerald-200 dark:border-emerald-900 text-xs font-mono text-emerald-800 dark:text-emerald-200 space-y-1">
                  <strong>Exercise Closed Successfully</strong>
                  <div className="break-all">{receiptLog}</div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Tab 3: Cohort Rooms */}
      {activeTab === 'rooms' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div>
                <h3 className="text-lg font-bold text-slate-900 dark:text-white">Active Cohort Rooms (/train/rooms)</h3>
                <p className="text-sm text-slate-500 dark:text-slate-400">Hundian room cap is 12 occupants. At capacity, joining is refused and split is offered.</p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {rooms.map(room => {
                const isFull = room.occupancy >= room.maxCapacity;
                return (
                  <div key={room.periodId} className="p-5 rounded-2xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 space-y-4 flex flex-col justify-between">
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="font-mono text-xs px-2 py-0.5 rounded bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300">
                          {room.periodId}
                        </span>
                        <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                          isFull ? 'bg-red-100 dark:bg-red-950 text-red-600' : 'bg-emerald-100 dark:bg-emerald-950 text-emerald-600'
                        }`}>
                          {room.occupancy} / {room.maxCapacity} Seats
                        </span>
                      </div>
                      <h4 className="font-bold text-slate-900 dark:text-white text-base">{room.name}</h4>
                      <p className="text-xs text-slate-500 dark:text-slate-400">Supervisor: {room.supervisor}</p>
                    </div>

                    <button
                      onClick={() => handleJoinRoom(room)}
                      className={`w-full py-2.5 rounded-xl font-semibold text-xs transition shadow-xs ${
                        isFull
                          ? 'bg-slate-200 dark:bg-slate-700 text-slate-400 cursor-not-allowed'
                          : 'bg-indigo-600 text-white hover:bg-indigo-700'
                      }`}
                    >
                      {isFull ? 'Room Full (Split Required)' : 'Join Room Seat'}
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* Tab 4: Rules & Levers */}
      {activeTab === 'rules' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">5. Fail-Closed Rules (F-TRAIN-01–12)</h3>
            
            <div className="space-y-3">
              {[
                { id: 'F-TRAIN-01', rule: 'No chrome, certificate, share card, or transcript on /train contains Certified.' },
                { id: 'F-TRAIN-02', rule: 'A cohort room that would seat a 13th occupant refuses the write and offers split (C-14, F-14).' },
                { id: 'F-TRAIN-03', rule: 'Roster displays role_class, slot_id, period_id. person_id is not the chair label.' },
                { id: 'F-TRAIN-04', rule: 'Closed picker for inviting a supervisor or co-learner. No register search (L0-3).' },
                { id: 'F-TRAIN-05', rule: 'Youth path requires confirmed guardian co-presence on every write (L0-6). Withdrawal logged (L0-7).' },
                { id: 'F-TRAIN-06', rule: 'XP, streaks, credits, or M = 2R + 1 do not overweight a gate, a vote, or a room seat (L0-8).' },
                { id: 'F-TRAIN-07', rule: 'Supervisor / Examiner chrome hides at ≥10% operator or operator board seat.' },
                { id: 'F-TRAIN-08', rule: 'A /shop payment does not mark a playbook complete and does not write a credential event.' },
              ].map(item => (
                <div key={item.id} className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 flex items-start space-x-3">
                  <span className="font-mono text-xs px-2 py-1 rounded bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 font-semibold shrink-0">
                    {item.id}
                  </span>
                  <p className="text-sm text-slate-700 dark:text-slate-300">{item.rule}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
