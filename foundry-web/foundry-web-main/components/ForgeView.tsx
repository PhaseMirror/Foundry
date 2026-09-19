'use client';

import React, { useState } from 'react';
import { 
  Hammer, 
  ShieldCheck, 
  Lock, 
  FileCode, 
  Terminal, 
  Layers, 
  CheckCircle2, 
  AlertTriangle, 
  HelpCircle,
  ExternalLink,
  Cpu,
  ArrowRight
} from 'lucide-react';

export default function ForgeView() {
  const [activeTab, setActiveTab] = useState<'workflow' | 'cli' | 'ladder' | 'levers'>('workflow');

  return (
    <div className="space-y-8 pb-16">
      
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 text-white p-6 sm:p-8 rounded-2xl shadow-xl border border-indigo-900/50">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-2 text-xs font-mono text-indigo-300 uppercase tracking-wider mb-1">
              <span>PrismPM-WF-001</span>
              <span>•</span>
              <span>18 September 2026</span>
              <span>•</span>
              <span>OSCAL-PM-001</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight flex items-center space-x-3">
              <Hammer className="w-7 h-7 text-indigo-400" />
              <span>Forge — PrismPM Shape and Workflow</span>
            </h1>
            <p className="text-sm text-indigo-200/80 mt-1 max-w-2xl">
              From idea and profile to a cryptographic software module. OSCAL is the filing cabinet. PrismPM is the lock. CMVP-shaped certification is a separate event.
            </p>
          </div>
          <div className="flex items-center space-x-2 bg-indigo-900/60 border border-indigo-700/60 px-4 py-2.5 rounded-xl text-xs font-mono">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
            <span>app.uor.foundation/prism</span>
          </div>
        </div>
      </div>

      {/* Navigation Sub-Tabs */}
      <div className="flex flex-wrap items-center gap-2 border-b border-slate-200 dark:border-slate-800 pb-4">
        {[
          { id: 'workflow', label: '1–5. Workflow & Stations' },
          { id: 'cli', label: '2.1 CLI Contract & Verbs' },
          { id: 'ladder', label: '6–7. Claim Ladder & Rungs' },
          { id: 'levers', label: '10–16. Fail-Closed & Levers' },
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

      {/* Workflow & Stations Tab */}
      {activeTab === 'workflow' && (
        <div className="space-y-6">
          
          {/* One Sentence Section */}
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
            <div className="flex items-center space-x-2 text-indigo-600 dark:text-indigo-400 font-bold text-xs uppercase tracking-wider">
              <span>1. One Sentence</span>
            </div>
            <p className="text-lg font-medium text-slate-900 dark:text-white leading-relaxed">
              PrismPM is the SDK and lifecycle that compiles a Foundry idea into OSCAL cabinets and refuses to print <span className="font-bold text-indigo-600 dark:text-indigo-400">Certified</span> when the only thing that happened is a profile resolution.
            </p>
            <div className="p-4 rounded-xl bg-indigo-50/60 dark:bg-indigo-950/40 border border-indigo-200 dark:border-indigo-900 text-xs text-indigo-900 dark:text-indigo-200">
              <strong>The rule this paper protects:</strong> Catalogs define. Profiles select. Overlays cannot weaken C-controls. Modeled → Implemented → Assessed → Accepted. Certified is C-24: a separate credential event. Equity never mints it. A valid XML file is not a locked door.
            </div>
          </div>

          {/* What PrismPM Looks Like */}
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">2. What PrismPM Should Look Like</h3>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              PrismPM is not a GRC website and not a second company. It is three surfaces on one hostname:
            </p>

            <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 dark:bg-slate-800 text-xs uppercase text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <tr>
                    <th className="px-4 py-3">Surface</th>
                    <th className="px-4 py-3">Job</th>
                    <th className="px-4 py-3">Must Not Become</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                  <tr>
                    <td className="px-4 py-3 font-semibold font-mono text-indigo-600 dark:text-indigo-400">SDK + CLI (prismpm)</td>
                    <td className="px-4 py-3 text-slate-700 dark:text-slate-300">Check predicates F-01–F-18. Resolve profiles. Emit OSCAL objects as kappa artifacts. Refuse skip-rung claims.</td>
                    <td className="px-4 py-3 text-slate-500">A badge printer. A FedRAMP consultant in a binary.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold font-mono text-indigo-600 dark:text-indigo-400">Model home (uor-foundry)</td>
                    <td className="px-4 py-3 text-slate-700 dark:text-slate-300">Authoritative Foundation / Foundry / module claims in LexLean. foundry-web only renders accepted Holograms.</td>
                    <td className="px-4 py-3 text-slate-500">Handwritten compliance HTML beside the model.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold font-mono text-indigo-600 dark:text-indigo-400">Portal view (/prism)</td>
                    <td className="px-4 py-3 text-slate-700 dark:text-slate-300">Claim ladder, completeness chain, package wall, Phase Mirror on conflicts.</td>
                    <td className="px-4 py-3 text-slate-500">A nurture funnel. A shop that sells Certified.</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          {/* OSCAL Cabinet, PrismPM Lock */}
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">3. OSCAL Cabinet, PrismPM Lock</h3>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              OSCAL files the drawers. PrismPM locks Profile through Accepted. Certified sits off the lock bar on purpose.
            </p>

            <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 dark:bg-slate-800 text-xs uppercase text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <tr>
                    <th className="px-4 py-3">OSCAL Object</th>
                    <th className="px-4 py-3">PrismPM Object</th>
                    <th className="px-4 py-3">Crypto-Module Reading</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                  <tr>
                    <td className="px-4 py-3 font-semibold">Catalog</td>
                    <td className="px-4 py-3 font-mono text-xs text-indigo-600 dark:text-indigo-400">PRISMPM-CAT-BASE plus pinned imports</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">FIPS 140-3 / ISO 19790 / SP 800-140 family imported as native IDs.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">Profile</td>
                    <td className="px-4 py-3 font-mono text-xs text-indigo-600 dark:text-indigo-400">PRISMPM-PRF-BASE + module overlay</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Selects every C-control. Adds module controls. Cannot drop C-24.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">Component Definition</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Reusable how: boundary, algorithms, keys, entropy, self-tests, roles</td>
                    <td className="px-4 py-3 text-slate-500">A person is not a component you own.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">SSP</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">One plan per bounded system</td>
                    <td className="px-4 py-3 text-slate-500">CSM-001 ≠ portal ≠ UCC kernel ≠ physical Foundry.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">SAP / SAR</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Assessment plan and results at a named evidence grade</td>
                    <td className="px-4 py-3 text-slate-500">CST or equivalent at E4+. Eloquence is not E4.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">POA&M</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Visible deficiency with owner, metric, horizon</td>
                    <td className="px-4 py-3 text-slate-500">Open C-control POA&M blocks Accepted. L0_HALT→POA&M still unbound.</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          {/* Idea -> Profile -> Module Stations */}
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">5. Idea → Profile → Module — The Stations</h3>
            
            <div className="space-y-4 text-sm text-slate-600 dark:text-slate-300">
              <div>
                <h4 className="font-bold text-slate-900 dark:text-white mb-1">5.1 Idea (Foundry Concept)</h4>
                <p>A module begins as a kappa object + idea-of on /foundry/inbox. Required fields before catalog pin: legal person, intended boundary, why it is not the UCC kernel, and which door would pay a lab.</p>
              </div>

              <div>
                <h4 className="font-bold text-slate-900 dark:text-white mb-1">5.2 Catalog (Define)</h4>
                <p>Pin PRISMPM-CAT-BASE. Import additive catalogs with IRI, dated version, and content hash (NIST FIPS 140-3, SP 800-140x, NIST SP 800-53 controls like SC-12, SC-13, SC-17).</p>
              </div>

              <div>
                <h4 className="font-bold text-slate-900 dark:text-white mb-1">5.3 Profile (Select)</h4>
                <p>Resolve PRISMPM-PRF-BASE first — every C-02–C-24, no exclusions. Then apply module overlay as addition. Fail closed if any C-ID is missing.</p>
              </div>

              <div>
                <h4 className="font-bold text-slate-900 dark:text-white mb-2">5.4 Component Definition (How)</h4>
                <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 dark:bg-slate-800 uppercase text-slate-500 border-b border-slate-200 dark:border-slate-700">
                      <tr>
                        <th className="px-3 py-2">Component</th>
                        <th className="px-3 py-2">What it names</th>
                        <th className="px-3 py-2">What it is not</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                      <tr>
                        <td className="px-3 py-2 font-semibold">Cryptographic boundary</td>
                        <td className="px-3 py-2">What is inside vs outside</td>
                        <td className="px-3 py-2 text-slate-400">The portal, garden, membership list</td>
                      </tr>
                      <tr>
                        <td className="px-3 py-2 font-semibold">Approved service</td>
                        <td className="px-3 py-2">Generate / zeroize / encrypt / sign / hash mapped to algorithm+mode</td>
                        <td className="px-3 py-2 text-slate-400">A shop SKU named &ldquo;Certified crypto.&rdquo;</td>
                      </tr>
                      <tr>
                        <td className="px-3 py-2 font-semibold">Key material</td>
                        <td className="px-3 py-2">Key types, generation, storage, zeroization</td>
                        <td className="px-3 py-2 text-slate-400">Calibration data, operator collateral</td>
                      </tr>
                      <tr>
                        <td className="px-3 py-2 font-semibold">Self-tests</td>
                        <td className="px-3 py-2">Power-up and conditional tests, failure behavior</td>
                        <td className="px-3 py-2 text-slate-400">A runtime firewall over membership</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <div>
                <h4 className="font-bold text-slate-900 dark:text-white mb-1">5.5 to 5.9 SSP, Implement, SAP/SAR, POA&M, Certified</h4>
                <p>One SSP per bounded system. Implementation via reproducible code, Lean/Kani bounds. SAP/SAR evaluation at E4+. Open POA&M blocks Accepted. Certified means a separate credential event (CMVP certificate against FIPS 140-3) — never emitted from profile machinery.</p>
              </div>
            </div>
          </div>

        </div>
      )}

      {/* CLI Contract Tab */}
      {activeTab === 'cli' && (
        <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
          <div className="flex items-center space-x-2 text-indigo-600 dark:text-indigo-400">
            <Terminal className="w-6 h-6" />
            <h2 className="text-xl font-bold">2.1 CLI Contract — Day-One Verbs</h2>
          </div>
          <p className="text-sm text-slate-600 dark:text-slate-300">
            The <code className="px-1.5 py-0.5 rounded bg-slate-100 dark:bg-slate-800 font-mono text-xs">prismpm</code> CLI executes strict validation predicates without skip-rung claims:
          </p>

          <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 dark:bg-slate-800 text-xs uppercase text-slate-500 border-b border-slate-200 dark:border-slate-700">
                <tr>
                  <th className="px-4 py-3">Verb</th>
                  <th className="px-4 py-3">Input</th>
                  <th className="px-4 py-3">Output</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 dark:divide-slate-700 font-mono text-xs">
                <tr>
                  <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">prismpm model check</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">uor-foundry snapshot</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Predicate report. Fail-closed on F-01–F-18.</td>
                </tr>
                <tr>
                  <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">prismpm catalog pin</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">External catalog IRI + version + hash</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Pinned import. Native IDs preserved. Never relabeled C-*.</td>
                </tr>
                <tr>
                  <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">prismpm profile resolve</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">PRISMPM-PRF-BASE + overlays + imports</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Resolved control set. C-10 conflicts visible, not merged.</td>
                </tr>
                <tr>
                  <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">prismpm oscal export</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Named bounded system</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Seven OSCAL objects on kappa, each with its own address.</td>
                </tr>
                <tr>
                  <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">prismpm chain show</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Control ID + SSP</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Five-link completeness chain. Broken links named.</td>
                </tr>
                <tr>
                  <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">prismpm ladder</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Bounded system</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Current rung. Cannot be set to Certified.</td>
                </tr>
                <tr>
                  <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">prismpm mirror</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Conflict object</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Five-step PMD report. Warn-only write-free on the oracle path.</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Claim Ladder Tab */}
      {activeTab === 'ladder' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">6. Claim Ladder and Evidence Grades</h3>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              Certified is locked on the ladder. Imported FIPS IDs stay native. Allowed copy on the banner is Modeled only until a recorded rung-change.
            </p>

            <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 dark:bg-slate-800 text-xs uppercase text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <tr>
                    <th className="px-4 py-3">Rung</th>
                    <th className="px-4 py-3">Meaning</th>
                    <th className="px-4 py-3">Crypto-Module Gate</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 dark:divide-slate-700 text-sm">
                  <tr>
                    <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">Modeled</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Objects and relationships exist. Chain not closed.</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">CSM-001 named in uor-foundry. Catalogs pinned. Profile resolves without F-01/F-07.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">Implemented</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Links 1–4 closed for named scope.</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Boundary, services, keys, tests, build identity exist as deployed subjects.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">Assessed</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Link 5 present. POA&Ms allowed.</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">SAP executed. CST or named independent method at E4 or the gap is a POA&M.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-bold text-indigo-600 dark:text-indigo-400">Accepted</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Every in-scope C-control closed. No open C POA&M.</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Base profile accepted for module SSP. Imported FIPS gaps remain visible.</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-bold text-red-600 dark:text-red-400">Certified</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Separate credential event under C-24.</td>
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300">CMVP or equivalent certificate pinned. Not a prismpm export field.</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Fail-Closed & Levers Tab */}
      {activeTab === 'levers' && (
        <div className="space-y-6">
          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">10. Fail-Closed Additions for This Workflow</h3>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              Module-scoped predicates block Accepted on CSM-001 without rewriting the portal inventory:
            </p>

            <div className="space-y-3">
              {[
                { id: 'F-CSM-01', rule: 'A module SSP that includes the membership list, a garden, or a portal view inside the cryptographic boundary fails closed.' },
                { id: 'F-CSM-02', rule: 'Emitting Certified, FIPS-validated, or FedRAMP-ready from prismpm export is F-16 plus this defect.' },
                { id: 'F-CSM-03', rule: 'Relabeling a FIPS 140-3 requirement as a C-control is C-09/C-10.' },
                { id: 'F-CSM-04', rule: 'Claiming P²C v1.1, PWEH-PQ, or UAC as Implemented evidence for the module is grade inflation.' },
                { id: 'F-CSM-05', rule: 'Crypto-officer role stored as person_id inside Hundian K fails F-14 as well.' },
                { id: 'F-CSM-06', rule: 'Skipping Modeled → Implemented → Assessed → Accepted on the way to a lab package is a broken chain, not a fast lane.' },
              ].map(rule => (
                <div key={rule.id} className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/80 flex items-start space-x-3">
                  <span className="font-mono text-xs px-2 py-1 rounded bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 font-semibold shrink-0">
                    {rule.id}
                  </span>
                  <p className="text-sm text-slate-700 dark:text-slate-300">{rule.rule}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 p-6 sm:p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">16. Levers</h3>
            
            <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 dark:bg-slate-800 text-xs uppercase text-slate-500 border-b border-slate-200 dark:border-slate-700">
                  <tr>
                    <th className="px-4 py-3">Owner</th>
                    <th className="px-4 py-3">Lever</th>
                    <th className="px-4 py-3">Metric</th>
                    <th className="px-4 py-3">Horizon</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 dark:divide-slate-700 text-xs">
                  <tr>
                    <td className="px-4 py-3 font-semibold">PrismPM steward</td>
                    <td className="px-4 py-3">Ship check / resolve / export / ladder / chain verbs; Certified unsettable</td>
                    <td className="px-4 py-3">0 exports containing Certified</td>
                    <td className="px-4 py-3 text-slate-500">21 days after SDK cut</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">uor-foundry model steward</td>
                    <td className="px-4 py-3">Name CSM-001 as a distinct bounded system; pin FIPS catalog as import</td>
                    <td className="px-4 py-3">Two SSPs visible on /prism; wall intact</td>
                    <td className="px-4 py-3 text-slate-500">30 days</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">Formal-methods steward</td>
                    <td className="px-4 py-3">Reuse UCC receipt shape on module builds; do not seat P²C v1.1 by announcement</td>
                    <td className="px-4 py-3">Build receipts = hash+version+build+time</td>
                    <td className="px-4 py-3 text-slate-500">with first module build</td>
                  </tr>
                  <tr>
                    <td className="px-4 py-3 font-semibold">Examiner / Guardian</td>
                    <td className="px-4 py-3">Refuse Examiner controls for ≥10% operator owners on module SAR</td>
                    <td className="px-4 py-3">Zero dual-seat collisions</td>
                    <td className="px-4 py-3 text-slate-500">21 days</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
