import { ADR, ADRRegistry, ADRStatus, FoundryMachineryStatus, ArtifactLink, FoundryAuditEntry } from './adr-types';

const ADR_API_BASE = '/api/adr';
const FOUNDRY_API_BASE = '/api/foundry';

export async function fetchADRs(): Promise<ADR[]> {
  const res = await fetch(ADR_API_BASE);
  if (!res.ok) throw new Error(`ADR fetch failed: ${res.status}`);
  const data: ADR[] = await res.json();
  return data;
}

export async function fetchADRRegistry(): Promise<ADRRegistry> {
  const res = await fetch(`${ADR_API_BASE}/registry`);
  if (!res.ok) throw new Error(`ADR registry fetch failed: ${res.status}`);
  const data: ADRRegistry = await res.json();
  return data;
}

export async function fetchADRById(id: string): Promise<ADR | null> {
  const res = await fetch(`${ADR_API_BASE}/${encodeURIComponent(id)}`);
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`ADR ${id} fetch failed: ${res.status}`);
  const data: ADR = await res.json();
  return data;
}

export async function fetchFoundryStatus(): Promise<FoundryMachineryStatus> {
  const res = await fetch(FOUNDRY_API_BASE);
  if (!res.ok) throw new Error(`Foundry status fetch failed: ${res.status}`);
  const data: FoundryMachineryStatus = await res.json();
  return data;
}

/** Route a proposal into the engine's `docs/adr/proposed/` inbox. */
export async function proposeADR(adr: ADR): Promise<{ accepted: boolean; inbox?: string; error?: string; proposal?: ADR }> {
  const res = await fetch(ADR_API_BASE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(adr),
  });
  const data = await res.json();
  if (!res.ok && !data.accepted) {
    throw new Error(data.error ?? `Proposal rejected: ${res.status}`);
  }
  return data;
}

/** Validate a status transition against the engine transition machine. */
export async function requestTransition(
  adrId: string,
  fromStatus: ADRStatus,
  toStatus: ADRStatus,
  supersedes?: string | null,
): Promise<{ valid: boolean; reason?: string }> {
  const res = await fetch(`${ADR_API_BASE}/validate-transition`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ adrId, fromStatus, toStatus, supersedes }),
  });
  if (!res.ok) throw new Error(`Transition validation failed: ${res.status}`);
  return res.json();
}

/** Record a typed event in the engine audit trail. */
export async function appendAudit(entry: {
  adrId: string;
  action: string;
  status: string;
  author: string;
}): Promise<FoundryAuditEntry & { accepted: boolean; file?: string; error?: string }> {
  const res = await fetch(`${ADR_API_BASE}/audit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(entry),
  });
  return res.json();
}

/** Run an engine gate: per-ADR verification or the proof-debt scan. */
export async function runEngineVerify(opts: { adrId?: string; sorryCheck?: boolean }) {
  const res = await fetch(`${FOUNDRY_API_BASE}/verify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(opts),
  });
  if (!res.ok) throw new Error(`Engine verify failed: ${res.status}`);
  return res.json();
}

/** Regenerate `docs/adr/` from the machine-checked Lean registry. */
export async function runEngineExport() {
  const res = await fetch(`${FOUNDRY_API_BASE}/export`, { method: 'POST' });
  if (!res.ok) throw new Error(`Engine export failed: ${res.status}`);
  return res.json();
}

export function transitionIsAllowed(currentStatus: ADRStatus, targetStatus: ADRStatus): boolean {
  if (currentStatus === 'Accepted') {
    return targetStatus === 'Superseded' || targetStatus === 'Deprecated';
  }
  if (currentStatus === 'Proposed') {
    return targetStatus === 'Accepted' || targetStatus === 'Deprecated';
  }
  return false;
}

export function validateTransition(
  currentStatus: ADRStatus,
  targetStatus: ADRStatus,
  supersedes?: string | null,
): { valid: boolean; reason?: string } {
  if (!transitionIsAllowed(currentStatus, targetStatus)) {
    return { valid: false, reason: `Transition ${currentStatus} → ${targetStatus} is forbidden by Foundry machinery` };
  }
  if (currentStatus === 'Accepted' && targetStatus === 'Superseded' && !supersedes) {
    return { valid: false, reason: 'Accepted ADR must specify a successor ID when superseding' };
  }
  return { valid: true };
}

export function findConflicts(adrs: ADR[]): Array<{ a: ADR; b: ADR }> {
  const conflicts: Array<{ a: ADR; b: ADR }> = [];
  const accepted = adrs.filter((a) => a.status === 'Accepted');
  for (let i = 0; i < accepted.length; i++) {
    for (let j = i + 1; j < accepted.length; j++) {
      const a = accepted[i];
      const b = accepted[j];
      if (a.decision === `NOT(${b.decision})` || b.decision === `NOT(${a.decision})`) {
        conflicts.push({ a, b });
      }
    }
  }
  return conflicts;
}

export function buildArtifactLink(uri: string, kind: ArtifactLink['kind'], description: string): ArtifactLink {
  return { uri, kind, description };
}