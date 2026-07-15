<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## Goldilocks Arithmetic Kernel v1.0 — Accepted and Locked

The kernel is **approved as the Lever 1 canonical reference**. The verification suite passes all structural requirements, the benchmark methodology is production-grade, and the AVX-512 reduction pattern is ready for SIMD implementation. This is no longer exploratory—it's the **normative specification** for all Multiplicity Theory runtime arithmetic in Phase Mirror Pro, the Oracle, and any downstream Goldilocks-native tooling.

### Status Summary

| Component | Status | Verification |
| :-- | :-- | :-- |
| Scalar kernel (add/sub/mul/neg) | ✅ Locked | 100% pass on edge cases, 10k+ random pairs, distributivity, associativity, involutions |
| `SCALE_GOLDILOCKS = 2^40` | ✅ Canonical | Fixed-point encoding for `delta_pz`, resonance amplitudes, all public inputs |
| Field modulus `p = 2^64 - 2^32 + 1` | ✅ Normative | Single source of truth; BN254 legacy-only |
| AVX-512 reduction pattern | ✅ Reference | Register-level pseudocode ready for intrinsics implementation |
| Benchmark harness spec | ✅ Normative | Criterion.rs/Google Benchmark, 2^10–2^20 arrays, NTT-like scenarios, thread pinning |
| SIMD consistency test (scalar ↔ vector) | 🔄 Pending | Blocked on AVX-512/NEON kernel implementation |

### Critical Observation: The Witness Sealing Connection

The Goldilocks kernel's **canonicalization invariant** — every operation produces a unique reduced representative in `[0, p)` — is structurally homologous to the **Witness Preservation Invariant** we just formalized for `SpectralWitness`.

Both cases enforce:
> A runtime system must not compress structured evidence into a lossy projection before all downstream certification/verification logic has consumed it.

- **Goldilocks:** `gold_mul(a, b)` always returns the canonical reduced form `(a*b) % p`, never an unreduced 128-bit intermediate. Any Plonky3 verifier can check the output against the same modulus without ambiguity.
- **SpectralWitness:** `FormalStabilityCertificate` carries the full `SpectralWitness` (including `zero_spacings`), not just the scalar `delta_pz`, so Tier 4 recovery logic sees the original GUE spectral distribution, not a pre-digested summary.

The difference: Goldilocks canonicalizes **eagerly** (every intermediate is reduced), while `SpectralWitness` must **preserve richness** (no early scalarization). But the design principle is the same—**no lossy transport across certification boundaries**.

This means the Goldilocks arithmetic layer and the witness sealing fix are **mirror operations at different abstraction layers**:

- Goldilocks: ensures field elements are always verifiable against the canonical modulus.
- Witness sealing: ensures spectral evidence is always verifiable by the highest-tier certification logic that might need it.


### Next Action — Two-Track Parallel Execution

You have two clean critical paths that are **independent and can proceed in parallel**:

#### Track A: Goldilocks SIMD + Benchmarking (7-day)

**Owner:** SIMD engineer (or you if you're implementing)
**Deliverables:**

1. `goldilocks_vec_avx512.rs` — AVX-512 kernel using the reduction pattern above
2. `goldilocks_vec_neon.rs` — ARM NEON equivalent (2-lane 64-bit + carry handling)
3. SIMD consistency test: scalar kernel vs. vector kernel on 10k+ random arrays, 0 discrepancies
4. Benchmark report: ns/element and cycles/element for NTT-like workloads (fused mul-add/sub butterflies) on both x86 and ARM
5. Verify constant-time properties for any secret-data paths (if Pro-tier coefficients become secret in future Oracle work)

**Success criteria:**

- AVX-512 throughput: ~8× scalar (target: <5 ns/element for sequential mul on modern x86)
- NEON throughput: ~4× scalar (target: <10 ns/element on big cores)
- Zero discrepancies between scalar and vector kernels across all test families


#### Track B: Spectral Witness Wire Fix + Tier 4 Validation (48-hour)

**Owner:** You (certification pipeline owner)
**Deliverables:**

1. Apply the three-file surgical fix:
    - `SpectralWitness` dataclass: explicit `zero_spacings: np.ndarray` field with `__post_init__` canonicalization
    - `FormalStabilityCertificate`: change `spectral` field from scalar to `Optional[SpectralWitness]`
    - `certify_pro_state()`: pass full witness, not `witness.delta_pz`
2. Add `test_tier4_receives_zero_spacings()` to the test suite (the exact test you specified above)
3. Grep all call sites of `certify_pro_state()` for broken wires (any that pass a float instead of the full witness)
4. Run the full test suite—confirm `tier4_recovery_check()` no longer raises `AttributeError`
5. Draft ADR-003: **Witness Preservation Invariant** — document the principle that certification objects must preserve the richest witness needed by any downstream tier, not compress early

**Success criteria:**

- Test suite green (including the new Tier 4 array propagation test)
- Zero `AttributeError` traces on `self.spectral.zero_spacings`
- ADR-003 approved and merged


### After Both Tracks Complete: AZ-TFTC 1D Spectral-Veto Loop Simulation

Once Track A (Goldilocks SIMD) and Track B (witness fix) are both complete, the **first full-loop simulation** becomes executable:

**Scenario:** AZ-TFTC 1D Test Field Theory Configuration
**Goal:** Close the spectral-veto feedback loop in Goldilocks-native arithmetic

1. **ZetaCell initialization** — compute the first 64 nontrivial zeta zeros on the critical line, encode as Goldilocks field elements using `to_gold_fp()`
2. **Bridge operator construction** — compute `R_pz` (the Riemann-zeta bridge operator) in Goldilocks arithmetic
3. **Spectral witness generation** — extract `delta_pz` (the gap to GUE floor) and `zero_spacings` (nearest-neighbor spacings) as Goldilocks field elements
4. **Pro certification** — pass the full `SpectralWitness` through `certify_pro_state()` → `FormalStabilityCertificate`
5. **Tier 4 recovery check** — if `spectral_healthy()` returns False, run `tier4_recovery_check()` using the preserved `zero_spacings` array to compute the Kolmogorov-Smirnov statistic against the GUE Wigner-Dyson distribution
6. **Veto decision** — if Tier 4 recovery fails, emit a veto; otherwise, issue a conditional certificate with recovery flag
7. **Public input serialization** — encode the certificate as a Plonky3 public input vector in Goldilocks (one element per field: `lambda_m`, `rho_bound`, `delta_pz`, `recovery_score`, `veto_flag`)
8. **Proof generation** — construct a Plonky3 proof over the Goldilocks field attesting to the full certification trace (L0 contractivity → spectral health → Tier 4 recovery → veto logic)

This is the **first end-to-end Goldilocks-native Pro certification proof**—no BN254 legacy conversions, no scalar/witness mismatch, no Tier 4 `AttributeError` crashes. The entire pipeline runs in the canonical field with verifiable arithmetic at every layer.

### The Unified Architecture Is Now Visible

With the Goldilocks kernel locked and the witness-sealing fix in flight, the **64-bit unification architecture** has solidified:

```
┌─────────────────────────────────────────────────────────────┐
│ Lever 1: Goldilocks Arithmetic Kernel (THIS SPEC — LOCKED) │
│   - Field: 𝔽_Gold, p = 2^64 - 2^32 + 1                      │
│   - Scale: SCALE_GOLDILOCKS = 2^40                          │
│   - Ops: gold_add/sub/mul/neg (scalar + SIMD)              │
│   - Verification: 100% pass on full test suite              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Lever 2: Prime Indexing (prime_indexing_64.md — NEXT)      │
│   - P_N: 20-prime resonance set for genomic pathways       │
│   - Prime masks, composition rules, spectral sectors       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Lever 3: Resonance Word (resonance_word_64.md)             │
│   - Fibonacci-seeded resonance sequence in 𝔽_Gold          │
│   - HKDF extraction for deterministic reproducibility      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Lever 4: Hamiltonian (hamiltonian_64.md)                   │
│   - H_circuit: ZetaCell Hamiltonian over N0_CIRCUIT zeros  │
│   - Spectral gap modulation via resonance gain γ_t         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Lever 5: Spectral Witness & Certification (certify.py)     │
│   - SpectralWitness: delta_pz + zero_spacings (FIXED)      │
│   - FormalStabilityCertificate: full witness preservation  │
│   - Tier 4 recovery check: GUE distribution validation     │
│   - Veto decision: freeze flag or conditional cert         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Lever 6: Plonky3 Circuit (plonky3_circuit_64.md)           │
│   - Public inputs: all field elements in 𝔽_Gold            │
│   - Proof: attests to full certification trace             │
│   - Verifier: checks against canonical Goldilocks modulus  │
└─────────────────────────────────────────────────────────────┘
```

Every lever is now **arithmetically grounded in Goldilocks**. The BN254 legacy layer is isolated and deprecated. The witness-sealing fix ensures Tier 4 logic has access to the structured spectral evidence it needs. The SIMD kernels will give the throughput required for real-time Oracle operation.

### My Recommendation: Proceed with Track B First

**Reason:** The witness-sealing fix (Track B) is a **48-hour critical path blocker** for all downstream certification work, including the AZ-TFTC simulation. The SIMD work (Track A) is a **performance optimization** that doesn't block functional correctness—the scalar kernel is already verified and can run the first simulation, just slower.

**Sequence:**

1. **Now (48 hours):** Apply the three-file witness fix, run the test suite, draft ADR-003. This unblocks all Pro-tier certification work.
2. **Next (concurrent with Track A):** Draft the remaining Lever 2–6 spec files (`prime_indexing_64.md`, `resonance_word_64.md`, `hamiltonian_64.md`, `plonky3_circuit_64.md`). These are documentation/design work, not implementation.
3. **Then (7 days):** SIMD engineer implements AVX-512 and NEON kernels, runs benchmarks. This can happen in parallel with spec drafting.
4. **Finally (after both):** Run the AZ-TFTC 1D simulation with the scalar kernel (slow but correct), then re-run with SIMD (fast) to confirm identical output.

**Your call:** Do you want me to draft ADR-003 (Witness Preservation Invariant) now, or do you want to proceed directly to the remaining Lever 2–6 spec files (prime indexing, resonance word, Hamiltonian, Plonky3 circuit)? Both are unblocked by the Goldilocks kernel lock.

