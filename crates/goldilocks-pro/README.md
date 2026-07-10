# Goldilocks Arithmetic Kernel (GAK)

A production-grade, 64-bit normative arithmetic substrate for Multiplicity Theory certification and spectral-veto proofs.

## ✦ Overview

The Goldilocks Arithmetic Kernel (GAK) provides the foundational arithmetical layer for the Phase Mirror ecosystem. It is built entirely over the Goldilocks field ($\mathbb{F}_{p}, p = 2^{64} - 2^{32} + 1$) and implements the six high-leverage components (Levers 1–6) required for cryptographically verifiable spectral stability proofs.

### Key Features

*   **Lever 1: Scalar & SIMD Kernels** — Bit-perfect scalar arithmetic with optimized AVX-512 and NEON vectorization paths.
*   **Lever 2: Prime-Gated Indexing** — Canonical $P_{64}$ basis and branchless u64 mask algebra.
*   **Lever 3: Resonance Encoding** — R96 resonance class word packing with Q29.29 fixed-point precision.
*   **Lever 4: Sparse Hamiltonian** — Prime-gated potential terms and resonance-modulated coefficients.
*   **Lever 5: Spectral Witnessing** — Preservation of the full `zero_spacings` array for Tier 4 Kolmogorov-Smirnov recovery.
*   **Lever 6: Plonky3 Integration** — Native Plonky3 circuit scaffold for bit-decomposition and gating attestation.

## ✦ Status: PHASE 2 COMPLETE

| Layer | Status | Verification |
| :--- | :--- | :--- |
| **Arithmetic** | ✅ LOCKED | SSE4.2/AVX-512/NEON Bit-Perfect |
| **Recovery** | ✅ LOCKED | Tier 4 Hardened (Boundary + Dist) |
| **Proving** | ✅ LOCKED | Plonky3 AIR Gating & Trace Gen |
| **Simulation** | ✅ VERIFIED | AZ-TFTC End-to-End lifecycle pass |

## ✦ Getting Started

### Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
goldilocks-arithmetic-kernel = { path = "goldilocks-kernel/arithmetic-kernel" }
```

### Basic Usage

```rust
use goldilocks_arithmetic_kernel::{GoldilocksField, PrimeMask, ResonanceWord};

// Field arithmetic
let a = GoldilocksField::new(10);
let b = a.inv();
assert_eq!(a * b, GoldilocksField::ONE);

// Prime Indexing (Lever 2)
let mask = PrimeMask::from_bit(0).or(PrimeMask::from_bit(1)); // Gated by P2 and P3

// Resonance (Lever 3)
let rw = ResonanceWord::pack_q29_29(42, 1.0); // Class 42, unit amplitude
```

## ✦ Normative Specifications

Full specifications are located in the `docs/spec/` directory:

1.  `Lever_1_Arithmetic.md`: Field properties and reduction patterns.
2.  `Lever_2_Indexing.md`: The canonical $P_{64}$ basis.
3.  `Lever_3_Resonance.md`: R96 class semantics and Φ injection.
4.  `Lever_4_Hamiltonian.md`: Operator field laws.
5.  `Lever_5_Certification.md`: Tier 4 recovery and veto invariants.
6.  `Lever_6_Circuit.md`: AIR constraint definitions.

## ✦ Verification

Run the full test suite (including the AZ-TFTC simulation):

```bash
cargo test -- --nocapture
```

Current results show **100% pass rate** across all 11 core verification tracks.

---
**Multiplicity Theory / Phase Mirror Oracle Pro**
*Sealed Authority • Public Scrutiny*
