/**
 * Foundry engine bridge (Node runtime only).
 *
 * Connects the foundry-web portal to the Foundry UCC / formal-methods engine:
 *
 *   - resolves the engine checkout (`FOUNDRY_ENGINE_DIR`, else repo-relative);
 *   - reads the engine's machine-checked artifacts
 *     (`docs/adr/registry.json`, `state/alp_sorry_manifest.json`,
 *     `docs/adr/results/<slug>/latest/summary.json`, `audit_trail/*.json`);
 *   - runs engine gates on demand with timeouts and a short TTL cache:
 *     `scripts/check_adr_sorry.py`, `lake build adrExport && adrExport`,
 *     and `scripts/run_adr_tests.py <adr.md>`;
 *   - falls back to the in-repo mock registry when the engine is unreachable,
 *     so the portal still renders when deployed standalone.
 *
 * Hardening:
 *   - every command executes with an argv array (no shell interpolation);
 *   - adr ids passed to the gate are validated against `/^ADR-\d{2,4}$/` and
 *     resolved to paths strictly underneath the engine's `docs/adr` tree;
 *   - writes and process execution are disabled when
 *     `FOUNDRY_ENGINE_READONLY=1` (or `true`/`yes`);
 *   - `FOUNDRY_SKIP_EXPORT=1` stops the export action from running `lake`.
 */

import { existsSync } from 'node:fs';
import { promises as fs } from 'node:fs';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { ADR, FoundryAuditEntry } from './adr-types';
import { ALL_FOUNDRY_ADRS, FOUNDRY_AUDIT_TRAIL } from './adr-data';
import { registryChecks, RegistryChecks } from './engine-invariants';
import {
  EngineInfo,
  EngineRunResult,
  EngineStatus,
  GateRun,
  ProofDebt,
  VerificationResult,
  VerificationStep,
} from './engine-types';

function flag(name: string, dflt: boolean): boolean {
  const v = process.env[name];
  if (v === undefined) return dflt;
  return ['1', 'true', 'yes', 'on'].includes(v.toLowerCase());
}

function looksLikeEngineRoot(c: string): boolean {
  return existsSync(path.join(c, 'lakefile.lean')) && existsSync(path.join(c, 'docs', 'adr'));
}

function resolveEngineRoot(): string | null {
  const explicit = process.env.FOUNDRY_ENGINE_DIR;
  const candidates = explicit
    ? [path.resolve(explicit)]
    : [
        path.resolve(process.cwd(), '..', '..'),
        path.resolve(process.cwd(), '..'),
        path.resolve(process.cwd()),
      ];
  for (const c of candidates) {
    if (looksLikeEngineRoot(c)) return c;
  }
  return null;
}

const engine = {
  root: resolveEngineRoot(),
  readonly: flag('FOUNDRY_ENGINE_READONLY', false),
  skipExport: flag('FOUNDRY_SKIP_EXPORT', false),
};

/** Short-TTL cache for artifact reads; invalidated after engine writes. */
const cache = new Map<string, { at: number; value: unknown }>();

function cached<T>(key: string, ttlMs: number, loader: () => Promise<T>): Promise<T> {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < ttlMs) return Promise.resolve(hit.value as T);
  return loader().then((value) => {
    cache.set(key, { at: Date.now(), value });
    return value;
  });
}

function invalidate(prefix: string): void {
  for (const key of cache.keys()) {
    if (key.startsWith(prefix)) cache.delete(key);
  }
}

function truncate(s: string, max = 262_144): string {
  return s.length > max ? `${s.slice(-max)}\n…(output truncated)` : s;
}

function runCmd(cmd: string, args: string[], cwd: string, timeoutMs: number): Promise<EngineRunResult> {
  return new Promise((resolve) => {
    const started = Date.now();
    let stdout = '';
    let stderr = '';
    let settled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    let child: ReturnType<typeof spawn>;
    const finish = (ok: boolean, exitCode: number | null, errMsg?: string) => {
      if (settled) return;
      settled = true;
      if (timer) clearTimeout(timer);
      resolve({
        ok,
        command: `${cmd} ${args.join(' ')}`,
        exitCode,
        stdout: truncate(stdout),
        stderr: truncate(errMsg ? `${errMsg}\n${stderr}` : stderr),
        durationMs: Date.now() - started,
      });
    };
    try {
      child = spawn(cmd, args, {
        cwd,
        env: process.env as NodeJS.ProcessEnv,
        stdio: ['ignore', 'pipe', 'pipe'],
      });
    } catch (err) {
      return finish(false, null, String(err));
    }
    timer = setTimeout(() => {
      child.kill('SIGKILL');
      finish(false, null, `timed out after ${timeoutMs}ms`);
    }, timeoutMs);
    child.stdout.on('data', (d: Buffer) => {
      stdout += d.toString();
    });
    child.stderr.on('data', (d: Buffer) => {
      stderr += d.toString();
    });
    child.on('error', (err) => finish(false, null, err.message));
    child.on('close', (code) => finish(code === 0, code));
  });
}

export function engineInfo(): EngineInfo {
  return { connected: engine.root !== null, root: engine.root, readonly: engine.readonly };
}

/* ------------------------------------------------------------------------- *
 * Artifact readers
 * ------------------------------------------------------------------------- */

function isADR(x: unknown): x is ADR {
  if (!x || typeof x !== 'object') return false;
  const o = x as Record<string, unknown>;
  return (
    typeof o.id === 'string' &&
    typeof o.title === 'string' &&
    typeof o.status === 'string' &&
    typeof o.decision === 'string' &&
    Array.isArray(o.consequences)
  );
}

export interface RegistryRead {
  adrs: ADR[];
  version: string;
  source: 'engine' | 'fallback';
}

export async function readEngineRegistry(): Promise<RegistryRead> {
  return cached('registry', 30_000, async () => {
    const root = engine.root;
    if (root) {
      const regPath = path.join(root, 'docs', 'adr', 'registry.json');
      try {
        const raw = JSON.parse(await fs.readFile(regPath, 'utf8')) as { version?: string; adrs?: unknown };
        if (Array.isArray(raw.adrs) && raw.adrs.every(isADR)) {
          return {
            adrs: raw.adrs as ADR[],
            version: raw.version ?? '1.0.0',
            source: 'engine',
          } satisfies RegistryRead;
        }
      } catch {
        /* fall through to fallback */
      }
    }
    return { adrs: ALL_FOUNDRY_ADRS, version: 'mock', source: 'fallback' } satisfies RegistryRead;
  });
}

export async function readSingleADR(id: string): Promise<ADR | null> {
  const reg = await readEngineRegistry();
  return reg.adrs.find((a) => a.id === id) ?? null;
}

async function statMtime(p: string): Promise<string | null> {
  try {
    const st = await fs.stat(p);
    return new Date(st.mtimeMs).toISOString();
  } catch {
    return null;
  }
}

export async function readProofDebt(): Promise<ProofDebt> {
  return cached('proofDebt', 60_000, async () => {
    const root = engine.root;
    if (root) {
      const mPath = path.join(root, 'state', 'alp_sorry_manifest.json');
      try {
        const m = JSON.parse(await fs.readFile(mPath, 'utf8')) as {
          manifest_version?: string;
          permitted_sorrys?: unknown[];
          manifest_drift?: number;
          last_audit?: string;
        };
        const permitted = Array.isArray(m.permitted_sorrys) ? m.permitted_sorrys.length : 0;
        const drift = typeof m.manifest_drift === 'number' ? m.manifest_drift : 0;
        return {
          manifestVersion: m.manifest_version ?? null,
          permitted,
          found: null,
          manifestDrift: drift,
          lastAudit: m.last_audit ?? null,
          ok: drift === 0,
          detail: 'state/alp_sorry_manifest.json',
        } satisfies ProofDebt;
      } catch {
        /* engine reachable but manifest missing */
      }
    }
    return {
      manifestVersion: null,
      permitted: 0,
      found: null,
      manifestDrift: null,
      lastAudit: null,
      ok: false,
      detail: engine.root ? 'proof-debt manifest unavailable' : 'engine unavailable',
    } satisfies ProofDebt;
  });
}

function normalizeSummary(raw: unknown): VerificationResult | null {
  if (!raw || typeof raw !== 'object') return null;
  const s = raw as Record<string, unknown>;
  const adrId = typeof s.adr_id === 'string' ? s.adr_id : 'UNKNOWN';
  const slug = typeof s.slug === 'string' ? s.slug : adrId;
  const steps: VerificationStep[] = Array.isArray(s.steps)
    ? (s.steps as Record<string, unknown>[]).map((st) => ({
        name: typeof st.name === 'string' ? st.name : 'step',
        description: typeof st.description === 'string' ? st.description : '',
        status: st.status === 'PASS' ? 'PASS' : 'FAIL',
        exitCode: typeof st.exit_code === 'number' ? st.exit_code : -1,
        durationMs: typeof st.duration_ms === 'number' ? st.duration_ms : 0,
        summaryLine: typeof st.summary_line === 'string' ? st.summary_line : '',
      }))
    : [];
  return {
    adrId,
    slug,
    startedAt: typeof s.started_at === 'string' ? s.started_at : '',
    durationMs: typeof s.duration_ms === 'number' ? s.duration_ms : 0,
    overall: s.overall === 'PASS' ? 'PASS' : 'FAIL',
    steps,
  };
}

export async function listVerificationResults(): Promise<VerificationResult[]> {
  return cached('verification', 120_000, async () => {
    const root = engine.root;
    if (!root) return [];
    const resultsDir = path.join(root, 'docs', 'adr', 'results');
    let entries;
    try {
      entries = await fs.readdir(resultsDir, { withFileTypes: true });
    } catch {
      return [];
    }
    const out: VerificationResult[] = [];
    for (const dir of entries) {
      if (!dir.isDirectory()) continue;
      const summaryPath = path.join(resultsDir, dir.name, 'latest', 'summary.json');
      try {
        const raw = JSON.parse(await fs.readFile(summaryPath, 'utf8'));
        const rec = normalizeSummary(raw);
        if (rec) out.push(rec);
      } catch {
        /* not a valid run, skip */
      }
    }
    out.sort((a, b) => (b.startedAt ?? '').localeCompare(a.startedAt ?? ''));
    return out;
  });
}

function toAuditEntry(adrId: string, action: string, ts: string, status: string, author: string): FoundryAuditEntry {
  return { ADR_ID: adrId, Action: action, Timestamp: ts, Status: status, Author: author };
}

export async function readAuditTrail(): Promise<FoundryAuditEntry[]> {
  const entries: FoundryAuditEntry[] = [];
  const root = engine.root;
  if (root) {
    const dir = path.join(root, 'audit_trail');
    try {
      for (const file of await fs.readdir(dir)) {
        if (!file.endsWith('.json')) continue;
        try {
          const raw = JSON.parse(await fs.readFile(path.join(dir, file), 'utf8')) as Record<string, unknown>;
          entries.push(
            toAuditEntry(
              String(raw.ADR_ID ?? raw.adr_id ?? 'UNKNOWN'),
              String(raw.Action ?? raw.action ?? 'Unknown'),
              String(raw.Timestamp ?? raw.timestamp ?? ''),
              String(raw.Status ?? raw.status ?? 'Pending'),
              String(raw.Author ?? raw.author ?? 'Unknown'),
            ),
          );
        } catch {
          /* skip malformed */
        }
      }
    } catch {
      /* no engine audit dir */
    }
  }
  for (const r of await listVerificationResults()) {
    entries.push(toAuditEntry(r.adrId, 'verify', r.startedAt, r.overall, 'Foundry Gate'));
  }
  if (entries.length === 0) return FOUNDRY_AUDIT_TRAIL;
  entries.sort((a, b) => (b.Timestamp ?? '').localeCompare(a.Timestamp ?? ''));
  return entries;
}

export async function lastExportTime(): Promise<string | null> {
  const root = engine.root;
  if (!root) return null;
  return statMtime(path.join(root, 'docs', 'adr', 'registry.json'));
}

export async function exportAvailable(): Promise<boolean> {
  const root = engine.root;
  if (!root) return false;
  return existsSync(path.join(root, '.lake', 'build', 'bin', 'adrExport'));
}

/* ------------------------------------------------------------------------- *
 * Engine status aggregation
 * ------------------------------------------------------------------------- */

export async function getEngineStatus(): Promise<EngineStatus> {
  const [reg] = await Promise.all([readEngineRegistry()]);
  const counts = {
    total: reg.adrs.length,
    accepted: reg.adrs.filter((a) => a.status === 'Accepted').length,
    proposed: reg.adrs.filter((a) => a.status === 'Proposed').length,
    deprecated: reg.adrs.filter((a) => a.status === 'Deprecated').length,
    superseded: reg.adrs.filter((a) => a.status === 'Superseded').length,
  };
  const checks: RegistryChecks = registryChecks(reg.adrs);
  const [debt, results, exportAvail, lastExport] = await Promise.all([
    readProofDebt(),
    listVerificationResults(),
    exportAvailable(),
    lastExportTime(),
  ]);
  const passed = results.filter((r) => r.overall === 'PASS').length;
  return {
    version: reg.version,
    engine: engineInfo(),
    ADRs: counts,
    registryValid: checks.uniqueIds && checks.acyclic && checks.noConflicts,
    acyclic: checks.acyclic,
    noConflicts: checks.noConflicts,
    exportAvailable: exportAvail,
    lastExport,
    verification: { total: results.length, passed, failed: results.length - passed },
    proofDebt: debt,
    source: reg.source,
  };
}

/* ------------------------------------------------------------------------- *
 * Gate runners (explicit POST actions; skipped in read-only mode)
 * ------------------------------------------------------------------------- */

export async function runSorryCheck(): Promise<GateRun> {
  const root = engine.root;
  if (!root) return { ok: false, command: 'check_adr_sorry', exitCode: null, durationMs: 0, output: 'engine unavailable', passed: null, error: 'engine unavailable' };
  if (engine.readonly) return { ok: false, command: 'check_adr_sorry', exitCode: null, durationMs: 0, output: '', passed: null, error: 'engine is read-only (FOUNDRY_ENGINE_READONLY)' };
  const res = await runCmd('python3', ['scripts/check_adr_sorry.py'], root, 300_000);
  const passed = res.exitCode === 0;
  invalidate('proofDebt');
  return {
    ok: res.ok,
    command: res.command,
    exitCode: res.exitCode,
    durationMs: res.durationMs,
    output: `${res.stdout}\n${res.stderr}`.trim(),
    passed,
  };
}

export async function runEngineExport(): Promise<GateRun> {
  const root = engine.root;
  if (!root) return { ok: false, command: 'adrExport', exitCode: null, durationMs: 0, output: 'engine unavailable', passed: null, error: 'engine unavailable' };
  if (engine.readonly) return { ok: false, command: 'adrExport', exitCode: null, durationMs: 0, output: '', passed: null, error: 'engine is read-only (FOUNDRY_ENGINE_READONLY)' };
  if (engine.skipExport) return { ok: false, command: 'adrExport', exitCode: null, durationMs: 0, output: '', passed: null, error: 'export disabled (FOUNDRY_SKIP_EXPORT)' };
  const build = await runCmd('lake', ['build', 'adrExport'], root, 900_000);
  if (!build.ok) {
    return {
      ok: false,
      command: build.command,
      exitCode: build.exitCode,
      durationMs: build.durationMs,
      output: `${build.stdout}\n${build.stderr}`.trim(),
      passed: false,
      error: 'lake build adrExport failed',
    };
  }
  const bin = path.join(root, '.lake', 'build', 'bin', 'adrExport');
  const run = await runCmd(bin, [], root, 120_000);
  const passed = run.exitCode === 0;
  if (passed) {
    invalidate('registry');
    invalidate('verification');
  }
  return {
    ok: run.ok,
    command: run.command,
    exitCode: run.exitCode,
    durationMs: run.durationMs,
    output: `${run.stdout}\n${run.stderr}`.trim(),
    passed,
  };
}

function findAdrMarkdown(root: string, adrId: string): string | null {
  const places = ['docs/adr', 'docs/adr/completed', 'docs/adr/proposed', 'docs/adr/grp'];
  for (const dir of places) {
    let files: string[];
    try {
      files = fs.readdirSync(path.join(root, dir));
    } catch {
      continue;
    }
    const match =
      files.find((f) => f.toLowerCase() === `${adrId.toLowerCase()}.md`) ??
      files.find((f) => f.toLowerCase().startsWith(adrId.toLowerCase()));
    if (match) return path.join(root, dir, match);
  }
  return null;
}

export async function runVerificationGate(adrId: string): Promise<GateRun> {
  const root = engine.root;
  if (!root) return { ok: false, command: 'run_adr_tests', exitCode: null, durationMs: 0, output: 'engine unavailable', passed: null, error: 'engine unavailable' };
  if (engine.readonly) return { ok: false, command: 'run_adr_tests', exitCode: null, durationMs: 0, output: '', passed: null, error: 'engine is read-only (FOUNDRY_ENGINE_READONLY)' };
  if (!/^ADR-\d{2,4}$/.test(adrId)) {
    return { ok: false, command: 'run_adr_tests', exitCode: null, durationMs: 0, output: '', passed: null, error: `invalid ADR id: ${adrId}` };
  }
  const mdFile = findAdrMarkdown(root, adrId);
  if (!mdFile) {
    return { ok: false, command: 'run_adr_tests', exitCode: null, durationMs: 0, output: '', passed: null, error: `no markdown source for ${adrId} under docs/adr` };
  }
  const res = await runCmd('python3', ['scripts/run_adr_tests.py', mdFile], root, 1_800_000);
  invalidate('verification');
  return {
    ok: res.ok,
    command: res.command,
    exitCode: res.exitCode,
    durationMs: res.durationMs,
    output: `${res.stdout}\n${res.stderr}`.trim(),
    passed: res.exitCode === 0,
  };
}

/* ------------------------------------------------------------------------- *
 * Write paths (proposal inbox + audit trail; read-only-safe)
 * ------------------------------------------------------------------------- */

function safeToken(s: string): string {
  return s.replace(/[^0-9A-Za-z._-]/g, '-');
}

export async function appendAudit(entry: FoundryAuditEntry): Promise<{ ok: boolean; file?: string; error?: string }> {
  const root = engine.root;
  if (!root) return { ok: false, error: 'engine unavailable' };
  if (engine.readonly) return { ok: false, error: 'engine is read-only (FOUNDRY_ENGINE_READONLY)' };
  try {
    const dir = path.join(root, 'audit_trail');
    await fs.mkdir(dir, { recursive: true });
    const ts = safeToken(entry.Timestamp ?? new Date().toISOString());
    const file = path.join(dir, `adr_${safeToken(entry.ADR_ID ?? 'UNKNOWN')}_${ts}.json`);
    await fs.writeFile(file, `${JSON.stringify({ ...entry, schema: 'foundry-web-audit-event' }, null, 2)}\n`);
    return { ok: true, file: path.relative(root, file) };
  } catch (err) {
    return { ok: false, error: String(err) };
  }
}

export async function writeProposal(adr: ADR): Promise<{ ok: boolean; file?: string; error?: string }> {
  const root = engine.root;
  if (!root) return { ok: false, error: 'engine unavailable' };
  if (engine.readonly) return { ok: false, error: 'engine is read-only (FOUNDRY_ENGINE_READONLY)' };
  if (!/^ADR-\d{2,4}$/.test(adr.id ?? '')) {
    return { ok: false, error: `invalid ADR id: ${adr.id}` };
  }
  try {
    const titleWords = (adr.title ?? '').replace(/[^\w ()[\]-]/g, '').trim().slice(0, 60);
    const dir = path.join(root, 'docs', 'adr', 'proposed');
    await fs.mkdir(dir, { recursive: true });
    const file = path.join(dir, `${safeToken(adr.id)}-${titleWords || 'Untitled'}.md`);
    const md = [
      `# ${adr.id}: ${adr.title}\n`,
      '**Status:** Proposed\n',
      '## Context',
      adr.context ?? '',
      '## Decision',
      adr.decision ?? '',
      '## Consequences',
      ...(adr.consequences ?? []).map((c) => `- ${c}`),
      '## Traceability & Artifact Links',
      'None',
      '',
    ].join('\n');
    await fs.writeFile(file, md);
    return { ok: true, file: path.relative(root, file) };
  } catch (err) {
    return { ok: false, error: String(err) };
  }
}

/** Export the resolved engine layout for diagnostics. */
export async function engineDebugInfo() {
  const reg = await readEngineRegistry();
  const debt = await readProofDebt();
  const results = await listVerificationResults();
  const audit = await readAuditTrail();
  return {
    engine: engineInfo(),
    registry: { source: reg.source, version: reg.version, total: reg.adrs.length },
    proofDebt: debt,
    verification: { total: results.length, passed: results.filter((r) => r.overall === 'PASS').length },
    auditEntries: audit.length,
    lastExport: await lastExportTime(),
  };
}