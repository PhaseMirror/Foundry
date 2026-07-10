// Transcript module for QKD Hybrid Encryption v1.0.1
// Implements per-sender SHA-256 hash chain and context hash
// Inputs: message sequence, nonces, protocol version, multiplicity profile
// Outputs: per-sender hash chain, context hash, finalPrimeIndex
// Contract: deterministic, byte-exact, test vectors from spec
// Week 3: profile is now typed MultiplicityProfile; monotonicity guard enforces
// prime_index is non-decreasing across pipeline stages.

import crypto from 'crypto';
import { MultiplicityProfile, encodeProfile } from './multiplicity';

export interface TranscriptInput {
  messages: Buffer[];
  nonces: Buffer[];
  version: number;
  profile: MultiplicityProfile;   // typed — was opaque Buffer
  initialPrimeIndex?: number;     // if supplied, profile.prime_index must be >= this value
}

export interface TranscriptOutput {
  hashChain: Buffer[];
  contextHash: Buffer;
  finalPrimeIndex: number; // observable for pipeline monotonicity assertion in qkd.ts
}

export function computeTranscript({ messages, nonces, version, profile, initialPrimeIndex }: TranscriptInput): TranscriptOutput {
  if (messages.length !== nonces.length) {
    throw new Error('Messages and nonces must have the same length');
  }
  // Monotonicity guard: prime_index must not have regressed from the pipeline entry point
  if (initialPrimeIndex !== undefined && profile.prime_index < initialPrimeIndex) {
    throw new Error(
      `prime_index regression: got ${profile.prime_index}, expected >= ${initialPrimeIndex}`
    );
  }

  const profileBuf = encodeProfile(profile);
  const hashChain: Buffer[] = [];
  let prev = Buffer.alloc(0);
  for (let i = 0; i < messages.length; i++) {
    const data = Buffer.concat([
      prev,
      messages[i],
      nonces[i],
      Buffer.from([version]),
      profileBuf
    ]);
    prev = crypto.createHash('sha256').update(data).digest();
    hashChain.push(prev);
  }
  const contextHash = hashChain[hashChain.length - 1] ?? Buffer.alloc(32);
  return { hashChain, contextHash, finalPrimeIndex: profile.prime_index };
}
