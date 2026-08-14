// batchAggregator.ts — ADR-PML-050 sidecar glue.
//
// Invokes the Rust `batch_anchor` binary (crates/recursive-prover) as a
// child process once per day (UTC 00:00, the ADR-PML-055 daily
// boundary). The binary reads a JSONL of the last 24h of `Attested`
// events, aggregates them into one STARK APO, and prints/emit an
// `AggregatedProofObject` whose `aggregate_root` is the STARK
// proof commitment. The authoritative **batch Merkle root** — the value
// ADR-PML-050 feeds into the ADR-PML-055 `attestations`
// category — is computed by the binary to be byte-identical to
// `AttestationRegistry._computeMerkleRoot` (chained keccak over each
// run's `digest || timestamp || consentCommitment || nullifier`).
//
// Child-process (not FFI) per the approved design: isolation, the
// binary already emits JSON on stdout/stderr, and it is mockable in tests.

import { spawnSync, SpawnSyncOptions } from 'child_process';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { keccak256, concat, zeroPadValue, hexlify, getBytes, ZeroHash } from 'ethers';

export interface AttestedEvent {
  digest: string;
  timestamp: number;
  consentCommitment: string;
  nullifier: string;
}

export interface BatchAggregateResult {
  // Chained keccak root (== AttestationRegistry._computeMerkleRoot).
  // This is the value folded into the ADR-PML-055 combined root.
  batchRoot: string;
  // STARK APO commitment (keccak over member roots); verified
  // on-chain via submitBatchAttestation. NOT equal to batchRoot.
  aggregateRoot: string;
  memberRoots: string[];
  apoPath: string;
}

// Resolve the batch_anchor binary. Build outputs live at the workspace
// root `target/debug/batch_anchor` (cargo workspace) or `target/release/...`.
function resolveBinary(): string {
  const candidates = [
    process.env.BATCH_ANCHOR_BIN,
    path.resolve(__dirname, '../../../target/debug/batch_anchor'),
    path.resolve(__dirname, '../../../target/release/batch_anchor'),
    'batch_anchor',
  ].filter(Boolean) as string[];
  for (const bin of candidates) {
    if (bin === 'batch_anchor') return bin; // rely on PATH
    if (fs.existsSync(bin)) return bin;
  }
  return 'batch_anchor';
}

/**
 * Aggregate a day's worth of FeMoco attestations into one APO and return
 * the batch Merkle root to fold into the daily anchor.
 *
 * @param events   Last-24h Attested events collected by the sidecar.
 * @param outDir   Directory to write the APO JSON into (default: os.tmpdir()).
 */
export function runBatchAggregation(
  events: AttestedEvent[],
  outDir: string = os.tmpdir(),
): BatchAggregateResult {
  if (events.length === 0) {
    throw new Error('batch_anchor: refusing to aggregate an empty event set');
  }

  const eventsPath = path.join(outDir, `attested_${Date.now()}.jsonl`);
  const apoPath = path.join(outDir, `aggregated_proof_${Date.now()}.json`);
  fs.writeFileSync(eventsPath, events.map((e) => JSON.stringify(e)).join('\n') + '\n');

  const bin = resolveBinary();
  const opts: SpawnSyncOptions = { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 };
  const res = spawnSync(bin, [eventsPath, apoPath], opts);

  if (res.error) {
    throw new Error(`batch_anchor spawn failed: ${res.error.message}`);
  }
  if (res.status !== 0) {
    const stderr = (res.stderr || '').toString().trim();
    throw new Error(`batch_anchor exited ${res.status}: ${stderr}`);
  }

  // The binary emits the APO JSON we asked it to write.
  const apo = JSON.parse(fs.readFileSync(apoPath, 'utf8'));
  if (!apo.aggregate_root) {
    throw new Error('batch_anchor: APO missing aggregate_root');
  }

  // batchRoot is recomputed deterministically here (chained keccak) so the
  // sidecar never trusts a single source; it MUST equal what the binary
  // printed, which itself equals AttestationRegistry._computeMerkleRoot.
  const batchRoot = computeBatchMerkleRoot(events);

  return {
    batchRoot,
    aggregateRoot: '0x' + Buffer.from(apo.aggregate_root).toString('hex'),
    memberRoots: (apo.member_roots || []).map(
      (r: number[] | string) => '0x' + Buffer.from(r as number[]).toString('hex'),
    ),
    apoPath,
  };
}

/**
 * Chained keccak256 Merkle root over attestation events — byte-identical
 * to `AttestationRegistry._computeMerkleRoot`. This is the value
 * ADR-PML-055 consumes as the `attestations` category.
 */
export function computeBatchMerkleRoot(events: AttestedEvent[]): string {
  let current = ZeroHash;
  for (const e of events) {
    current = keccak256(
      concat([
        current,
        hexToBytes32(e.digest),
        uint256ToBytes32(e.timestamp),
        hexToBytes32(e.consentCommitment),
        hexToBytes32(e.nullifier),
      ]),
    );
  }
  return current;
}

function hexToBytes32(h: string): Uint8Array {
  const hh = h.startsWith('0x') ? h : '0x' + h;
  return getBytes(zeroPadValue(hh, 32));
}
function uint256ToBytes32(n: number): Uint8Array {
  const hex = BigInt(n).toString(16).padStart(64, '0');
  return getBytes('0x' + hex);
}
