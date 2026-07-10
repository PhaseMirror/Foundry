# Lever 2: Prime-Gated Indexing (Normative)

## 1. Canonical 64-Prime Basis $P_{64}$
The local prime basis is fixed and MUST be used verbatim:
[2, 3, 5, 7, 11, ..., 311]

## 2. Prime Mask
A single `u64` where bit $k$ is set iff the $k$-th prime is attached.

## 3. Mask Algebra
- `AND`: Intersection of attached primes.
- `OR`: Union of attached primes.
- `XOR`: Symmetric difference.

All operations MUST be implemented branchlessly.
