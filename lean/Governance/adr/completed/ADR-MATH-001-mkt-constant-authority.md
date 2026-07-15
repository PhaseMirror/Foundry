# ADR-MATH-001 — MKT Constant Definitions (Authoritative)

**Status**: Accepted (2026-05-22)
**Authority**: Ryan O. Van Gelder, "Multiplicity Knot Theory: A Parameter-Free Pipeline from Primes to Physical Admissibility," March 29, 2026.

---

## Context
A discrepancy was identified between the Python source code formula for `ALPHA_K` and the provided numeric constants. This ADR establishes the canonical derivation and values to ensure cross-language consistency and mathematical integrity.

---

## Decisions

### 1. ALPHA_K (Kauffman Locking Parameter)
**Definition**: α_K = (π − 1) / 2
**Value**: ≈ 1.07080 radians
**Clarification**: The value `π/2 − 1 ≈ 0.57080` found in some Python constant files was a transcription error and is formally rejected.

### 2. Derived Constants
All derived constants must be computed from `ALPHA_K`, never hardcoded as literals in implementation.

| Symbol | Expression | Approx value |
|--------|-----------|-------------|
| cos(α_K) | cos((π−1)/2) | ≈ 0.47943 |
| q_global | e^(i·α_K) | complex unit |
| A_K | e^(i(π−1)/2) | satisfies −(A_K² + A_K⁻²) = 2cos(1) |

### 3. Z_MARKOV (Wavefunction Renormalization Factor)
**Definition**: Z = 2 · α_K^(γ_K)
**Note**: `γ_K` is to be formally defined in the Canonical Axis Theorem implementation. Until then, `Z_MARKOV` computation is gated.

---

## Invariants
1. No MKT constant may be hardcoded as a numeric literal in any Rust crate.
2. All values must be computed from `ALPHA_K` at compile-time or runtime.
3. Any deviation from these formulas requires a formal amendment to this ADR.

---

## Verification
- `cargo test -p multiplicity-math` confirms that `ALPHA_K` matches the authoritative definition.
- The SU(2) identity `-(A_K² + A_K⁻²) = 2cos(1)` is satisfied within `1e-10` tolerance.
