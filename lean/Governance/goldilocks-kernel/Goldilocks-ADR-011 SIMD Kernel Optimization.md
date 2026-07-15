<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# ADR-029: SIMD Kernel Optimization for Goldilocks Arithmetic

**Status:** Proposed
**Date:** 2026-05-16
**Deciders:** Phase Mirror Pro / AGI-OS Core Arithmetic Layer
**Consulted:** PIRTM certification pipeline, Z-MOS bridge, Plonky3 proving path
**Informed:** Oracle runtime, AceAir, Track A performance engineering

## Context

The Goldilocks-native Pro-tier certification pipeline has been validated end-to-end at production scale with a successful AZ-TFTC 1D simulation and verified proof generation in the Plonky3 path. The current scalar arithmetic layer is functionally correct, but the runtime still relies on non-vectorized Goldilocks operations even though the Plonky3 ecosystem explicitly supports Goldilocks together with AVX-512 and NEON backends.[^1][^2][^3][^4]

The canonical runtime field remains Goldilocks, and no change to field semantics, public input encoding, or certification structure is permitted under this ADR. This ADR therefore addresses only implementation throughput for `gold_add`, `gold_sub`, `gold_mul`, and related slice-level kernels while preserving bit-for-bit equivalence with the scalar reference.[^2][^1]

## Decision

Implement production SIMD backends for Goldilocks arithmetic on:

- x86-64 with AVX-512 as the primary wide-vector target.[^3][^1]
- ARM64 with NEON as the required mobile and big-core target.[^4][^1]
- Scalar reference code as the normative correctness oracle and fallback path.[^2]

The SIMD layer MUST be a drop-in optimization only. It MUST NOT alter:

- the Goldilocks modulus or encoding,
- `SCALE_GOLDILOCKS`,
- public input formats such as `delta_pz_fp`, `prime_mask_fp`, or resonance words,
- certification semantics, witness structure, or Tier 4 behavior.


## Rationale

Plonky3 documents Goldilocks as a supported field and lists AVX-512 and NEON among supported acceleration targets, which makes SIMD optimization aligned with the target proving ecosystem rather than an architectural detour. Because the first proof milestone is already complete, optimization can proceed safely against a fixed scalar baseline and a known-good certification trace.[^5][^1][^3][^4][^2]

This sequencing preserves the existing invariant: correctness first, throughput second. SIMD is therefore treated as an implementation refinement, not a semantic migration.

## Technical Requirements

### Arithmetic scope

The implementation MUST provide vectorized kernels for:

- elementwise addition,
- elementwise subtraction,
- elementwise multiplication,
- fused butterfly-style add/sub and mul-add patterns for NTT-like workloads,
- masked tail handling for non-multiple-of-lane lengths.


### Correctness requirements

The SIMD implementation MUST satisfy all scalar verification families:

- edge-case canonicalization,
- random pair equivalence,
- associativity and distributivity sampling,
- negation and involution checks,
- overflow-boundary behavior,
- end-to-end equivalence on AZ-TFTC workloads.[^2]


### Benchmark methodology

Benchmarks MUST include:

- array sizes from $2^{10}$ to $2^{20}$,
- sequential slice arithmetic,
- random-access arithmetic,
- NTT-like butterfly workloads,
- measurements in ns/element, cycles/element, and effective bandwidth.

Thread pinning and cache warming are required for all reported benchmark results. This matches the already locked methodology for the Goldilocks kernel and keeps results comparable across architectures.

### Constant-time policy

For public proving data, the fast path is permitted. For any future secret-bearing coefficients or witness-side arithmetic, SIMD reductions and conditional subtraction logic MUST use branchless masks or equivalent constant-time techniques.[^5]

## Consequences

### Positive

- Throughput improvements can be realized without touching certification semantics.[^1][^2]
- The scalar kernel remains the reference oracle, which sharply lowers regression risk.
- The Oracle and AceAir runtime gain a realistic path toward real-time or near-real-time spectral certification throughput.


### Negative

- Platform-specific code paths increase maintenance burden.
- Cross-architecture reproducibility testing becomes mandatory, not optional.
- SIMD gains may be limited by surrounding prover bottlenecks if arithmetic is not the dominant cost.


## Acceptance Criteria

This ADR is accepted as implemented only when all of the following are true:

1. AVX-512 and NEON kernels compile and run on target hardware.[^4][^1]
2. Scalar-versus-SIMD discrepancy rate is exactly zero across the full verification suite and sampled AZ-TFTC traces.
3. Benchmarks are recorded for all required workload classes.
4. AZ-TFTC 1D simulation is re-run on the SIMD backend with identical certification and proof-verification outcomes.
5. Fallback to scalar remains available and tested.

## Deferred Items

This ADR does not introduce:

- EC arithmetic,
- Pallas/Vesta commitment logic,
- Jubjub or cross-field bridges,
- changes to AIR design,
- changes to proof system selection.

Those remain outside Track A and are governed by separate ADRs or deferred work items.icitly defers:[^6][^7]

- Jubjub integration,
- Pallas-native Edwards optimization,
- non-native field bridges,
- Halo2 interoperability,
- governance-commitment layers.[^7][^6]
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^28][^29][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://github.com/Plonky3/Plonky3/blob/main/README.md

[^2]: https://polygon.technology/blog/polygon-plonky3-the-next-generation-of-zk-proving-systems-is-production-ready

[^3]: https://github.com/Plonky3/Plonky3

[^4]: https://github.com/succinctlabs/plonky3/blob/main/README.md

[^5]: https://leastauthority.com/wp-content/uploads/2024/11/Updated_071124_Polygon_Plonky3_Final_Audit_Report.pdf

[^6]: https://bitzecbzc.github.io/technology/jubjub/index.html

[^7]: https://z.cash/the-pasta-curves-for-halo-2-and-beyond/

[^8]: https://github.com/Plonky3/Plonky3/tree/main/goldilocks

[^9]: https://github.com/0xmozak/plonky3/blob/main/README.md

[^10]: https://github.com/oskarth/nova-bench

[^11]: https://github.com/ConsenSys/gnark-crypto/blob/master/ecc/ecc.md

[^12]: https://github.com/telosnetwork/plonky2_goldibear/blob/main/README.md

[^13]: http://github.com/topics/pasta-curves

[^14]: https://gist.github.com/oxarbitrage/033bcf655212dd3b57136d01e70ab472

[^15]: https://github.com/Plonky3/Plonky3/issues

[^16]: https://github.com/privacy-scaling-explorations/nova-bench

[^17]: https://github.com/filecoin-project/research/issues/53

[^18]: https://github.com/Plonky3/Plonky3/activity

[^19]: https://github.com/nccgroup/pasta-curves

[^20]: https://github.com/BrianSeong99/Plonky3_RangeCheck

[^21]: https://crates.io/crates/p3-goldilocks

[^22]: https://lita.gitbook.io/lita-documentation/architecture/proving-system-plonky3

[^23]: https://forum.zcashcommunity.com/t/the-pasta-curves-for-halo-2-and-beyond-halo-2-pasta/38355

[^24]: https://github.com/zcash/zcash/issues/2502

[^25]: https://crates.io/crates/p3-miden-goldilocks

[^26]: https://www.facebook.com/eth.news.doge/posts/-the-pasta-curves-for-halo-2-and-beyond️-daira-hopwood️-crawled-from-electriccoi/4288386377876005/

[^27]: https://www.reddit.com/r/crypto/comments/prs8qf/bandersnatch_a_fast_elliptic_curve_built_over_the/

[^28]: https://github.com/Plonky3/awesome-plonky3/blob/main/README.md

[^29]: https://github.com/zcash/pasta

