// Commitment API for QKD Hybrid Encryption v1.0.1
// Implements Pedersen commitment (WASM-backed, BN254), fallback warning if unavailable
// Inputs: message, randomness, profile (optional)
// Outputs: deterministic commitment output
// Contract: deterministic, matches WASM vectors, testable
// Week 3: prime-indexed domain separation — PM-COMMIT-p${prime} tag makes commitments
// at different prime indices non-interchangeable without changing the WASM ABI.

import { MultiplicityProfile, getPrimeAtIndex, defaultProfile } from './multiplicity';

export interface CommitmentInput {
  message: Buffer;
  randomness: Buffer;
  profile?: MultiplicityProfile; // optional — defaults to defaultProfile(); selects domain tag
}

export interface CommitmentOutput {
  commitment: Buffer;
}

let wasmModule: any = null;
let fallbackWarned = false;

try {
  wasmModule = require('../rust/pkg/commitment_wasm');
} catch (e) {
  // Silent catch here, we will warn during computation
}

export function computeCommitment({ message, randomness, profile }: CommitmentInput): CommitmentOutput {
  const p = profile ?? defaultProfile();
  const prime = getPrimeAtIndex(p.prime_index);
  // Domain tag encodes the resolved prime — commitments across prime indices cannot collide.
  const domainTag = Buffer.from(`PM-COMMIT-p${prime}`, 'utf8');

  if (wasmModule && wasmModule.compute_pedersen_commitment) {
    try {
      // Pass domainTag as additional input context; WASM API accepts optional third arg.
      const result = wasmModule.compute_pedersen_commitment(message, randomness, domainTag);
      return { commitment: Buffer.from(result) };
    } catch (e) {
      if (!fallbackWarned) {
        console.warn('WASM execution failed, falling back to simple hash commitment:', e);
        fallbackWarned = true;
      }
    }
  } else if (!fallbackWarned) {
    console.warn('WASM BN254 module not found or failed to load. Falling back to SHA-256 stub commitment. ZK compatibility disabled.');
    fallbackWarned = true;
  }

  // SHA-256 fallback: domain-separate by prime index
  const data = Buffer.concat([domainTag, message, randomness]);
  const commitment = require('crypto').createHash('sha256').update(data).digest();
  return { commitment };
}
