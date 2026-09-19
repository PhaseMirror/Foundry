/**
 * Registry invariants.
 *
 * TypeScript mirrors of the core registry invariants proven formally in
 * `ADR/Proofs.lean` (acceptance/immutability, acyclic supersession) and
 * exercised by `ADR/Properties.lean`. These are presentation-layer checks over
 * the machine-checked registry export; they never replace the Lean proofs and
 * must stay in exact agreement with `ADR.Core` semantics.
 */

import { ADR } from './adr-types';

export interface RegistryChecks {
  uniqueIds: boolean;
  acyclic: boolean;
  noConflicts: boolean;
}

/** Same acceptance-immutability rule the formal `validTransition` enforces. */
export function transitionIsAllowedFormal(current: string, target: string): boolean {
  if (current === 'Accepted') return target === 'Superseded' || target === 'Deprecated';
  if (current === 'Proposed') return target === 'Accepted' || target === 'Deprecated';
  return false;
}

/** Follow `supersedes` links; a cycle means the chain is unusable as a history. */
export function checkAcyclic(adrs: ADR[]): boolean {
  const parent = new Map<string, string>();
  for (const a of adrs) {
    if (a.supersedes) parent.set(a.id, a.supersedes);
  }
  for (const start of parent.keys()) {
    const seen = new Set<string>();
    let cur: string | undefined = start;
    while (cur) {
      if (seen.has(cur)) return false;
      seen.add(cur);
      cur = parent.get(cur);
    }
  }
  return true;
}

/** Two concurrently accepted ADRs must not assert contradictory decisions. */
export function checkNoConflicts(adrs: ADR[]): boolean {
  const accepted = adrs.filter((a) => a.status === 'Accepted');
  for (let i = 0; i < accepted.length; i++) {
    for (let j = i + 1; j < accepted.length; j++) {
      const a = accepted[i];
      const b = accepted[j];
      if (a.decision === `NOT(${b.decision})` || b.decision === `NOT(${a.decision})`) {
        return false;
      }
    }
  }
  return true;
}

export function registryChecks(adrs: ADR[]): RegistryChecks {
  const ids = adrs.map((a) => a.id);
  const uniqueIds = new Set(ids).size === ids.length;
  return {
    uniqueIds,
    acyclic: checkAcyclic(adrs),
    noConflicts: checkNoConflicts(adrs),
  };
}