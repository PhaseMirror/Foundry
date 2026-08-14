# Lever 3: Resonance Encoding (Normative)

## 1. Resonance Word Format
A single `u64` consisting of:
- Bits 0–5: `c` ∈ {0, ..., 95} (R96 class).
- Bits 6–63: 58-bit payload `π`.

## 2. R96 Class Semantics
Exactly 96 classes derived from Tetrahedral Rhythm invariants.
- 32 classes of degeneracy 4.
- 64 classes of degeneracy 2.

## 3. Payload Interpretation (Q29.29)
The payload π is used as a signed fixed-point value with 29 bits of precision below the decimal.
- Range: $[-2^{28}, 2^{28}-1]$.
