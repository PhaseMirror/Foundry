'use client';

import React, { useState, useEffect } from 'react';
import { ADR, ADRStatus } from '@/lib/adr-types';
import { transitionIsAllowed, requestTransition, appendAudit } from '@/lib/foundry-service';
import { ShieldCheck, XCircle, AlertTriangle, ArrowRight, RefreshCw, Check, Loader2 } from 'lucide-react';

interface ADRViewProps {
  initialADRs?: ADR[];
  showActions?: boolean;
}

const STATUS_COLORS: Record<ADRStatus, string> = {
  Proposed: 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300',
  Accepted: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300',
  Deprecated: 'bg-red-100 text-red-800 dark:bg-red-950 dark:text-red-300',
  Superseded: 'bg-slate-100 text-slate-800 dark:bg-slate-950 dark:text-slate-300',
};

const STATUS_ICONS: Record<ADRStatus, React.ReactNode> = {
  Proposed: <AlertTriangle className="w-3 h-3" />,
  Accepted: <ShieldCheck className="w-3 h-3" />,
  Deprecated: <XCircle className="w-3 h-3" />,
  Superseded: <RefreshCw className="w-3 h-3" />,
};

export default function ADRView({ initialADRs, showActions = false }: ADRViewProps) {
  const [adrs, setADRs] = useState<ADR[]>(initialADRs ?? []);
  const [loading, setLoading] = useState(!initialADRs);
  const [error, setError] = useState<string | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [actionBusy, setActionBusy] = useState<string | null>(null);

  const loadADRs = () => {
    setLoading(true);
    fetch('/api/adr')
      .then(res => res.json())
      .then(data => { setADRs(data); setLoading(false); })
      .catch(err => { setError(err.message); setLoading(false); });
  };

  useEffect(() => {
    if (initialADRs) return;
    loadADRs();
  }, [initialADRs]);

  const handleDeprecation = async (adr: ADR) => {
    setActionBusy(adr.id);
    setError(null);
    try {
      const verdict = await requestTransition(adr.id, adr.status as ADRStatus, 'Deprecated');
      if (!verdict.valid) {
        setError(`${adr.id} cannot be deprecated: ${verdict.reason ?? 'transition forbidden'}`);
        return;
      }
      const audit = await appendAudit({
        adrId: adr.id,
        action: 'Deprecation requested',
        status: 'Pending',
        author: 'Foundry Portal',
      });
      if (!audit.accepted) {
        setError(`${adr.id}: deprecation request recorded but audit trail is ${audit.error ?? 'unavailable'}`);
        return;
      }
      setExpandedId(null);
      loadADRs();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Deprecation request failed');
    } finally {
      setActionBusy(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <RefreshCw className="w-6 h-6 animate-spin text-indigo-500" />
        <span className="ml-3 text-sm text-slate-500">Loading Foundry ADRs…</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-4 rounded-xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 text-red-700 dark:text-red-300 text-sm">
        Failed to load ADRs: {error}
      </div>
    );
  }

  const acceptedCount = adrs.filter(a => a.status === 'Accepted').length;
  const supersededCount = adrs.filter(a => a.status === 'Superseded').length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <ShieldCheck className="w-5 h-5 text-indigo-600" />
          <h2 className="text-lg font-bold text-slate-900 dark:text-white">Foundry Machinery ADRs</h2>
        </div>
        <div className="flex items-center space-x-3 text-xs text-slate-500">
          <span>{adrs.length} total</span>
          <span>•</span>
          <span className="text-emerald-600">{acceptedCount} accepted</span>
          {supersededCount > 0 && (
            <>
              <span>•</span>
              <span className="text-slate-500">{supersededCount} superseded</span>
            </>
          )}
        </div>
      </div>

      <div className="space-y-3">
        {adrs.map(adr => {
          const isExpanded = expandedId === adr.id;
          return (
            <div
              key={adr.id}
              className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-sm"
            >
              <button
                onClick={() => setExpandedId(isExpanded ? null : adr.id)}
                className="w-full p-4 flex items-center justify-between text-left hover:bg-slate-50 dark:hover:bg-slate-800/50 transition"
              >
                <div className="flex items-center space-x-3 min-w-0">
                  <span className="font-mono text-xs font-semibold text-indigo-600 dark:text-indigo-400 shrink-0">
                    {adr.id}
                  </span>
                  <span className="truncate font-medium text-sm text-slate-900 dark:text-white">
                    {adr.title}
                  </span>
                </div>
                <div className="flex items-center space-x-2 shrink-0 ml-3">
                  <span className={`inline-flex items-center space-x-1 px-2 py-0.5 rounded-full text-[10px] font-semibold ${STATUS_COLORS[adr.status]}`}>
                    {STATUS_ICONS[adr.status]}
                    <span>{adr.status}</span>
                  </span>
                  <ArrowRight className={`w-4 h-4 text-slate-400 transition-transform ${isExpanded ? 'rotate-90' : ''}`} />
                </div>
              </button>

              {isExpanded && (
                <div className="px-4 pb-4 space-y-3 border-t border-slate-100 dark:border-slate-800 pt-3">
                  <div>
                    <h4 className="text-xs font-semibold uppercase text-slate-500 mb-1">Decision</h4>
                    <p className="text-sm text-slate-700 dark:text-slate-300 leading-relaxed">{adr.decision}</p>
                  </div>
                  <div>
                    <h4 className="text-xs font-semibold uppercase text-slate-500 mb-1">Context</h4>
                    <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">{adr.context}</p>
                  </div>
                  {adr.consequences.length > 0 && (
                    <div>
                      <h4 className="text-xs font-semibold uppercase text-slate-500 mb-1">Consequences</h4>
                      <ul className="space-y-1">
                        {adr.consequences.map((c, i) => (
                          <li key={i} className="text-sm text-slate-600 dark:text-slate-400 flex items-start space-x-1.5">
                            <Check className="w-3 h-3 text-emerald-500 mt-0.5 shrink-0" />
                            <span>{c}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                  {adr.links.length > 0 && (
                    <div>
                      <h4 className="text-xs font-semibold uppercase text-slate-500 mb-1">Traceability</h4>
                      <ul className="space-y-1">
                        {adr.links.map((link, i) => (
                          <li key={i} className="text-xs font-mono text-slate-500 dark:text-slate-400">
                            [{link.kind}] {link.uri} — {link.description}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                  {adr.supersedes && (
                    <div>
                      <h4 className="text-xs font-semibold uppercase text-slate-500 mb-1">Supersedes</h4>
                      <span className="text-xs font-mono text-slate-500">{adr.supersedes}</span>
                    </div>
                  )}
                  {showActions && transitionIsAllowed(adr.status as ADRStatus, 'Deprecated') && (
                    <div className="pt-2">
                      <button
                        onClick={() => handleDeprecation(adr)}
                        disabled={actionBusy === adr.id}
                        className="px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 text-xs font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition disabled:opacity-50"
                      >
                        {actionBusy === adr.id ? (
                          <span className="inline-flex items-center space-x-1">
                            <Loader2 className="w-3 h-3 animate-spin" />
                            <span>Routing to machinery…</span>
                          </span>
                        ) : (
                          'Request Deprecation'
                        )}
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
