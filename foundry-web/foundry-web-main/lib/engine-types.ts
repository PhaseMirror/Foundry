/**
 * Engine bridge types.
 *
 * Types describing the connection between the foundry-web portal and the
 * Foundry UCC/formal-methods engine: engine reachability, the machine-checked
 * ADR registry, proof-debt manifest, per-ADR verification gates, and the
 * aggregated machinery status the portal renders.
 */

/** Whether the portal resolved a live engine checkout and whether it is read-only. */
export interface EngineInfo {
  connected: boolean;
  root: string | null;
  readonly: boolean;
}

/** ADR-0010 proof-debt ledger as recorded in `state/alp_sorry_manifest.json`. */
export interface ProofDebt {
  manifestVersion: string | null;
  /** Number of manifest-authorized sorry/admit tactics. */
  permitted: number;
  /** "Found in scope" count reported by the scan (0 when the scan has not run here). */
  found: number | null;
  /** `manifest_drift` from the ledger; 0 means no drift. */
  manifestDrift: number | null;
  lastAudit: string | null;
  /** True when the manifest declares zero drift and the engine is reachable. */
  ok: boolean;
  detail: string | null;
}

/** One gate step inside a per-ADR verification run (`summary.json`). */
export interface VerificationStep {
  name: string;
  description: string;
  status: 'PASS' | 'FAIL';
  exitCode: number;
  durationMs: number;
  summaryLine: string;
}

/** A per-ADR verification run record (`docs/adr/results/<slug>/latest/summary.json`). */
export interface VerificationResult {
  adrId: string;
  slug: string;
  startedAt: string;
  durationMs: number;
  overall: 'PASS' | 'FAIL';
  steps: VerificationStep[];
}

/** Combined engine + registry status returned by `/api/foundry` and `/api/adr/registry`. */
export interface EngineStatus {
  version: string;
  engine: EngineInfo;
  ADRs: {
    total: number;
    accepted: number;
    proposed: number;
    deprecated: number;
    superseded: number;
  };
  /** All three invariant checks held (unique ids + acyclic + no conflicts). */
  registryValid: boolean;
  acyclic: boolean;
  noConflicts: boolean;
  /** `adrExport` binary present in the engine build dir. */
  exportAvailable: boolean;
  /** ISO timestamp of the last engine export artifact, or null. */
  lastExport: string | null;
  verification: {
    total: number;
    passed: number;
    failed: number;
  };
  proofDebt: ProofDebt;
  source: 'engine' | 'fallback';
}

/** A raw process run produced by the bridge. */
export interface EngineRunResult {
  ok: boolean;
  command: string;
  exitCode: number | null;
  stdout: string;
  stderr: string;
  durationMs: number;
}

/** Result of a triggered engine gate (export / sorry check / per-ADR verification). */
export interface GateRun {
  ok: boolean;
  command: string;
  exitCode: number | null;
  durationMs: number;
  output: string;
  passed: boolean | null;
  error?: string;
}