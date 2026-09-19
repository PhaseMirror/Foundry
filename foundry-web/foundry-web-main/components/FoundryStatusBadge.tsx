'use client';

import React, { useState, useEffect } from 'react';
import { FoundryMachineryStatus } from '@/lib/adr-types';
import { Check, X, Loader2, ShieldCheck, AlertCircle } from 'lucide-react';

interface FoundryStatusBadgeProps {
  showLabel?: boolean;
}

export default function FoundryStatusBadge({ showLabel = true }: FoundryStatusBadgeProps) {
  const [status, setStatus] = useState<FoundryMachineryStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    fetch('/api/foundry')
      .then(res => {
        if (!res.ok) throw new Error('Foundry API error');
        return res.json();
      })
      .then(data => { setStatus(data); setLoading(false); })
      .catch(() => { setError(true); setLoading(false); });
  }, []);

  if (loading) {
    return (
      <div className="flex items-center space-x-2 px-3 py-1.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 text-xs">
        <Loader2 className="w-3 h-3 animate-spin" />
        {showLabel && <span>Foundry machinery…</span>}
      </div>
    );
  }

  if (error || !status) {
    return (
      <div className="flex items-center space-x-2 px-3 py-1.5 rounded-full bg-red-50 dark:bg-red-950/40 text-red-700 dark:text-red-300 text-xs border border-red-200 dark:border-red-900">
        <AlertCircle className="w-3 h-3" />
        {showLabel && <span>Foundry machinery unreachable</span>}
      </div>
    );
  }

  const engineConnected = status.engine?.connected ?? false;
  const allValid = status.registryValid && status.acyclic && status.noConflicts;
  const verification = status.verification;
  const proofDebt = status.proofDebt;

  return (
    <div className="flex items-center space-x-2">
      <div className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-full text-xs font-medium ${
        allValid
          ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-900'
          : 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-900'
      }`}>
        {allValid ? (
          <>
            <ShieldCheck className="w-3 h-3" />
            {showLabel && <span>Foundry Machinery {engineConnected ? '✓' : '✓ (mock)'}</span>}
          </>
        ) : (
          <>
            <AlertCircle className="w-3 h-3" />
            {showLabel && <span>Foundry Machinery ⚠</span>}
          </>
        )}
      </div>
      {showLabel && (
        <div className="flex flex-col">
          <div className="flex items-center space-x-1 text-[10px] text-slate-400">
            <span>{status.ADRs.total} ADRs</span>
            <span>•</span>
            <span>{status.ADRs.accepted} accepted</span>
          </div>
          {verification && (
            <div className="flex items-center space-x-1 text-[10px] text-slate-400">
              <span>{verification.passed}/{verification.total} gates passed</span>
              {proofDebt && (
                <>
                  <span>•</span>
                  <span>{proofDebt.permitted} authorized sorrys</span>
                </>
              )}
              {proofDebt && proofDebt.manifestDrift !== null && proofDebt.manifestDrift !== 0 && (
                <>
                  <span>•</span>
                  <span className="text-amber-500">drift {proofDebt.manifestDrift}</span>
                </>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
