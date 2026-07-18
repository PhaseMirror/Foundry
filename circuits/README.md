# ΛProof Circuits

This directory contains the zk-SNARK circuits implementing ΛProof logic — zero-knowledge proofs for prime-lawful identity verification and state transitions.

## Overview

ΛProof circuits define the core zero-knowledge proof patterns for MTPI / Web4 systems:

- **Prime verification** – Miller-Rabin primality testing for prime-gated logic
- **Identity commitments** – Poseidon-based commitments for privacy-preserving identity
- **State transitions** – Lawful state changes with entropy bounds and drift control
- **Recovery flows** – Silent recovery mechanisms for system resilience

## PTau Setup

This repo does not commit the PTau file required by Groth16 setup.
The build script will automatically download it if it's missing, or you can fetch it manually.

## Fetch PTau

```bash
pnpm tsx scripts/fetch-ptau.mjs
```

Optional env:

- `PTAU_URL` - remote URL (default: Hermez S3 pot15 final)
- `PTAU_OUT` - output path (default: `circuits/pot15_final.ptau`)
- `PTAU_SHA256` - expected sha256 to verify integrity

## Build circuits

```bash
pnpm tsx scripts/build-circuits.mjs
```

The build script will check for the PTau file and exit with an error if it's missing.

## Compiled circuit invariants

- **`langlandsCheck.circom`** — fully compiled Langlands/Euler-product verifier: **170 constraints** (142 non-linear + 28 linear), 250 wires, 19 public + 32 private inputs. Verified breakdown and known soundness gaps: [`LANGANDSCHECK_170_INVARIANT.md`](./LANGANDSCHECK_170_INVARIANT.md).
- **`ace.circom`** — governance prototype: **133 constraints** (Poseidon2 hash replaced by a linear-sum stub). Targets the 5,087 architectural budget (see ADR-046); not yet reached. Phased integration plan: `docs/adr/proposed/ADR-103-Poseidon2-Integration-Roadmap.md`.
- **`constraints.circom`** — budget-lock accounting stub asserting `total_cost === 5087`; compiles to 6 linear constraints.
