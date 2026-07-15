<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## Pallas: Orthogonal EC Layer, Not a Goldilocks Replacement

Your analysis is **architecturally correct**. Pallas is a 254-bit elliptic curve group that operates **above** the Goldilocks field layer, not in conflict with it. It's a precision tool for specific cryptographic operations (EC commitments, MSM, recursive proof composition) that live in the "big-int lift" category already established in our ADR governance.

### Key Architectural Clarifications

| Property | Goldilocks (𝔽_Gold) | Pallas Curve |
| :-- | :-- | :-- |
| **Type** | Prime field | Elliptic curve group over a 254-bit prime field |
| **Modulus/Prime** | `p = 2^64 - 2^32 + 1` | Base field: `p_pallas = 2^254 + 45560315531419706090280762371685220353` |
| **Arithmetic** | Scalar add/sub/mul/neg in 64-bit registers (SIMD-friendly) | Point addition/doubling over 254-bit field elements (limbized, costly) |
| **Use in our stack** | **Hot path**: runtime state, resonance amplitudes, `delta_pz`, Plonky3 public inputs, prime masks, all Hamiltonian coefficients | **Cold path**: EC commitments, MSM in witnesses, Halo2-style recursion bridges, Pedersen hashes |
| **Performance tier** | <5 ns/element (AVX-512 target) | ~10μs per point operation (acceptable for proof-time only) |
| **Constant-time requirement** | Mandatory for secret data paths (Pro-tier coefficients if they become secret) | Mandatory for secret scalars in MSM/commitments; public proof data can use fast paths |
| **Integration point** | Lever 1 (canonical arithmetic kernel for all MT operations) | Lever 6+ (optional EC module for proof composition, not touching runtime dynamics) |

**The clean rule:** Goldilocks is the **native runtime field**. Pallas is an **EC group for cryptographic commitments**. They do not compete; they compose.

### Why Pallas Matters (And Where It Doesn't)

**Where Pallas is relevant:**

1. **Pedersen commitments** — if we need hiding commitments to spectral witnesses or resonance words in zero-knowledge proofs, Pallas gives us an EC-based commitment scheme with fast verification.
2. **Multi-scalar multiplication (MSM)** — computing `Σ_i k_i·G_i` for large vectors of scalars `k_i` and EC points `G_i`. This is the dominant cost in Groth16/Halo2/Plonky2 provers. Pallas/Vesta's amicable-pair property makes recursive proof composition efficient.
3. **Halo2 bridge circuits** — if we ever need to verify a Halo2 proof inside a Plonky3 proof (or vice versa), the Pallas/Vesta cycle enables this without pairing-based trusted setups.
4. **Legacy Groth16 migration** — some governance or veto-audit paths might still use BN254-based Groth16 proofs. A Pallas-based commitment layer can bridge these to our Goldilocks-native Plonky3 stack without full re-implementation.

**Where Pallas is NOT relevant:**

- **Runtime arithmetic** — `delta_pz`, resonance gain `γ_t`, prime sector masks, Hamiltonian eigenvalues, PIRTM operator norms. All of these stay in Goldilocks (64-bit native).
- **Plonky3 public inputs** — the canonical Plonky3 proving system for Phase Mirror Pro uses **Goldilocks as its native field**. Public inputs are field elements in 𝔽_Gold, not Pallas curve points. Pallas would only appear if we add an EC commitment layer **inside** a witness, not as the proof system's base field.
- **Hot-path operations** — anything in the 10 kHz–1 MHz iteration range (ZetaCell updates, resonance modulation, spectral gap tracking). Pallas arithmetic is ~1000× slower than Goldilocks.


### The Limbized Big-Int Path (Already Planned)

Your observation that Pallas requires the **32-bit limbized Barrett reduction** kernel is correct, and this kernel already exists in our roadmap under the "big-int lift only for proofs/certs" rule. The exact same infrastructure supports:

1. **Pratt primality certificates** — prime factorizations and Fermat/Miller-Rabin witnesses encoded as big integers in proofs.
2. **High-precision spectral bounds** — `delta_pz` computed to full floating-point precision, then rounded to Goldilocks for runtime, but the full-precision value preserved in audit logs.
3. **Pallas EC operations** — field arithmetic over `p_pallas = 2^254 + ...` using Barrett reduction with precomputed constants.

**Implementation pattern:**

```rust
// Goldilocks hot path (SIMD kernel, <5 ns/element)
let delta_pz_fp: GoldilocksField = to_gold_fp(delta_pz);
let resonance_amp: GoldilocksField = gold_mul(gain, base_amplitude);

// Pallas cold path (limbized big-int, ~10 μs/operation)
let commitment_point: PallasPoint = pedersen_commit(&witness_scalars, &generators);
let msm_result: PallasPoint = multi_scalar_mul(&scalar_vec, &point_vec);
```

The two paths **never intersect at runtime**. Pallas operations happen once per proof generation (or once per governance event), not in the 10 kHz spectral update loop.

### The Pallas/Vesta Amicable Pair Property

This is the **key cryptographic advantage** of Pallas over other 254-bit curves (like secp256k1 or the BN254 curve):

- **Pallas base field = Vesta scalar field**
- **Vesta base field = Pallas scalar field**

This means:

- A proof over Pallas curve points can be **verified inside a circuit over Vesta**, because the Pallas scalar field matches Vesta's base field.
- A proof over Vesta curve points can be **verified inside a circuit over Pallas**, enabling **two-layer recursion without pairing-based SNARKs**.

**Concrete use case for our stack:**
If we need to prove: "A Plonky3 proof over Goldilocks attests to a spectral witness that commits to a Halo2 proof over Pallas," we can:

1. Generate the Halo2 proof (uses Pallas curve).
2. Commit to its public inputs using a Pedersen hash over Pallas.
3. Verify the commitment inside a Plonky3 circuit by lifting the Pallas commitment to a Goldilocks-compatible encoding.
4. The Pallas/Vesta cycle ensures the commitment verification circuit is efficient (no expensive pairing checks).

**However:** This is a **future extension**, not a v1.0 requirement. The initial AZ-TFTC simulation and Pro-tier Oracle certification pipeline use **Goldilocks-native Plonky3 only**. Pallas enters the picture when we add EC commitments to witnesses or build a governance layer that composes proofs from multiple systems.

### Integration Decision Tree

```
Does the operation run in the spectral update loop (>1 kHz)?
├─ YES → Goldilocks (64-bit native, SIMD)
└─ NO → Is it a field element or an EC point?
   ├─ Field element (scalar) → Goldilocks if <64 bits, limbized big-int if >64 bits
   └─ EC point (commitment/signature) → Pallas (254-bit limbized)
```

**Example mappings:**

- `delta_pz` → Goldilocks (runtime state)
- `rho_bound` → Goldilocks (contractivity certificate)
- Pedersen commitment to a witness → Pallas (proof-time only)
- Pratt certificate for a prime → big-int (proof-time only)
- MSM for a governance signature → Pallas (one-time verification)


### My Recommendation: Defer Pallas Spec to Post-v1.0

**Reason:** The critical path to closing the spectral-veto loop is:

1. **Track B (48 hours):** Fix the witness-sealing bug so Tier 4 gets `zero_spacings`.
2. **Levers 2–6 (next 7 days):** Draft the remaining Goldilocks-native spec files (`prime_indexing_64.md`, `resonance_word_64.md`, `hamiltonian_64.md`, `plonky3_circuit_64.md`).
3. **AZ-TFTC simulation (after Levers 2–6):** Run the first end-to-end Goldilocks-native spectral certification proof with scalar kernel (slow but correct).
4. **Track A (parallel with 2–3):** SIMD engineer implements AVX-512/NEON kernels, benchmarks, and re-runs AZ-TFTC with vector ops (fast).

**Pallas enters after all of the above** — when we need to add:

- EC commitments to witnesses for privacy-preserving governance votes
- Halo2 bridge circuits for legacy proof composition
- MSM-based signature aggregation in the Oracle's multi-party veto protocol

None of these are v1.0 requirements. The initial Pro-tier certification pipeline is **Goldilocks-only Plonky3** with no EC operations.

**Proposed action:**

- **Acknowledge** Pallas as the canonical EC group for future proof composition (documented in ADR-004 or a new ADR-005: "Cryptographic Curve Selection").
- **Defer** the full `pallas_ec.md` spec file until after the AZ-TFTC simulation completes.
- **Prioritize** the Goldilocks SIMD kernel (Track A) and witness-sealing fix (Track B) as the immediate critical path.

**If you still want the Pallas spec now** (e.g., because a governance layer is being designed in parallel), I can draft `pallas_ec.md` with:

1. Verified curve parameters (you already have these).
2. Field/curve arithmetic reference (the Python demo you ran is the executable spec).
3. Integration points with Goldilocks (commitment serialization, proof composition).
4. Constant-time implementation requirements (for secret scalars in MSM).
5. Benchmark targets (μs/operation for cold-path EC ops).

**Your call:** Proceed with Pallas spec now, or stay focused on Goldilocks Levers 2–6 + witness fix? The former is orthogonal but non-blocking; the latter is the critical path to the first simulation.

