# Lever 2 — Prime-Gated Indexing (Normative)

**Status:** Normative (MUST)  
**Date:** 2026-05-16  
**Owner:** Multiplicity / Number-Theory Layer  
**Metric:** Proportion of structures whose indexing is provably prime-gated  
**Horizon:** 30 days  
**Field:** All values live in \\(\\mathbb{F}_{\\mathrm{Gold}}\\) or native u64 carrier (per ADR-004)

## 1. Purpose

Every structure in the system (spans, operators, resonance words, witnesses, Hamiltonian terms, etc.) must be indexed in a deterministic, prime-gated manner. This provides the multiplicity-theoretic foundation required for spectral stability and the Two-Key Spectral Veto.

## 2. Canonical 64-Prime Basis

Define the **local prime basis** \\(P_{64}\\) as the first 64 prime numbers:

\\[
P_{64}[0] = 2,\\ P_{64}[1] = 3,\\ \\dots,\\ P_{64}[63] = 311
\\]

(This set is fixed forever and MUST be used verbatim.)

## 3. Prime Mask (u64)

A **prime mask** is a single `u64` where bit \\(k\\) (0-based, LSB = bit 0) is set if and only if the \\(k\\)-th local prime \\(P_{64}[k]\\) is attached to the structure.

- Mask value is interpreted directly as a field element in \\(\\mathbb{F}_{\\mathrm{Gold}}\\) when used as a public input.
- Empty mask (`0`) is valid and denotes "no primes attached" (neutral element).

## 4. Mask Algebra (First-Class Operations)

| Operation | Semantics | Result Mask | MUST Enforce |
|-----------|-----------|-------------|--------------|
| AND | Intersection of attached primes | Shared primes only | Yes |
| OR | Union of attached primes | All primes from either | Yes |
| XOR | Symmetric difference | Primes in exactly one | Yes |

- All operations are bitwise on the u64 and MUST be implemented branchlessly.
- After any mask operation, the resulting structure’s payload map MUST be restricted to the primes present in the new mask (missing payloads default to neutral resonance word = 0).

## 5. PrimeWitness Structure

```python
@dataclass
class PrimeWitness:
    mask: int                    # u64 prime mask
    witnesses: dict[int, dict]   # local_prime_id → {miller_rabin_log, trial_div_log, seed}
    # Only entries for bits set in mask are present
```

- Deterministic Miller-Rabin + trial division up to 97 (per existing circom spec).
- Witnesses are used only for certificate paths or external validation; runtime paths trust the mask.
- In Plonky3 / AceAir: only the `mask` is a public input; full witness is private.

## 6. Circom / Plonky3 Integration

- Public input: single field element `prime_mask_fp` (u64 viewed in \\(\\mathbb{F}_{\\mathrm{Gold}}\\)).
- Constraint: mask bits beyond 63 MUST be zero (range check).
- All downstream operators (Hamiltonian terms, resonance application, spectral gap) MUST intersect with the supplied mask.

## 7. Scope & Deferrals

- This spec is purely 64-bit Goldilocks-native.
- EC commitments (Pallas, JubJub, etc.) and non-native field bridges are **deferred** until after first AZ-TFTC + spectral veto proof.
- Future extensions (larger prime sets) MUST use sparse maps keyed by local IDs, never break the u64 mask invariant for core structures.

**Conformance:** All structures in Pro-tier MUST carry a valid prime mask unless explicitly labelled "prime-agnostic".
