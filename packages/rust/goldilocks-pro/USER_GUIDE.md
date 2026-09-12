# Goldilocks Arithmetic Kernel: User Guide

This guide describes how to use the Goldilocks Arithmetic Kernel (GAK) for production spectral certification.

## ✦ 1. Core Abstractions

### GoldilocksField
All values in the kernel are represented as elements of the Goldilocks field $\mathbb{F}_p$.
- Modulus: $2^{64} - 2^{32} + 1$
- Scale: $2^{40}$ (used for floating-point fixed representation)

### PrimeMask (Lever 2)
A bitmask representing the attachment of the system to the canonical 64-prime basis ($P_{64}$).
- Operations: `and`, `or`, `xor`, `is_set`, `count_ones`.
- All indexing for operators and witnesses MUST be prime-gated via this mask.

### ResonanceWord (Lever 3)
A compact 64-bit word carrying the R96 class and a 58-bit payload.
- Packing: Use `pack_q29_29` for fixed-point amplitudes.
- Unpacking: Use `unpack_q29_29` to retrieve the floating-point value.

## ✦ 2. The Certification proving Loop

To generate a Pro-tier certificate and prepare for ZK attestation:

1.  **Initialize ZetaCell:** Populate with Riemann zeta zeros or spectral state.
2.  **Evaluate Hamiltonian:** Apply prime-gated potential terms.
3.  **Generate Witness:** Extract `delta_pz` and `zero_spacings`.
4.  **Issue Certificate:** Call `FormalStabilityCertificate::new` and populate with the witness.
5.  **Export Proof Inputs:** Use `cert.export_proof_inputs()` to get the `ConvergencePublicInputsPro` bundle.
6.  **Verify Gating:** Use `PrimeResonanceAir::new(inputs.prime_mask, inputs.resonance_word).verify()` to cross-check invariants before proving.

## ✦ 3. Performance Tuning

### Vectorization
The kernel automatically supports SIMD optimizations for AVX-512 and NEON.
- To enable, ensure the target CPU features are active during compilation (`RUSTFLAGS="-C target-cpu=native"`).
- Vectorized operations are accessed via the `vec_add`, `vec_sub`, `vec_mul` functions in the `simd` module.

## ✦ 4. Troubleshooting

### Verification Failures
If `verify_trace` or the AIR verification fails:
- Check the R96 class (must be < 96).
- Verify the gating relation: Resonance Bit 0 requires Prime Mask Bit 0.
- Ensure the floating-point value is within the Q29.29 58-bit signed range.

---
*Multiplicity Theory / Phase Mirror Oracle Pro*
