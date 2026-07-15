<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Production-Grade ADR Documentation Suite

This suite packages three architecture decisions for direct inclusion in an implementation repository. It is structured for engineering execution, security review, and benchmarking alignment with the current Goldilocks-native Plonky3 path.

***

# ADR-032: Goldilocks Kernel as Canonical Runtime Field

**Status:** Proposed
**Date:** 2026-05-16
**Decision Type:** Core arithmetic / runtime field selection
**Owners:** Core arithmetic, proving, and certification layers

## Context

Plonky3 is a modular proving toolkit that explicitly supports Goldilocks and optimized backends including AVX-512 and NEON, making Goldilocks a first-class fit for high-throughput proof systems. Goldilocks also remains a widely used FFT-friendly field in STARK-oriented systems because its modulus supports efficient arithmetic and large power-of-two structure.[^1][^2][^3][^4][^5]

The current Pro-tier pipeline has already validated end-to-end certification and proof generation on the Goldilocks rail. The remaining architectural need is to freeze that practice into a formal decision that governs runtime state, proof inputs, and implementation policy.

## Decision

Use the Goldilocks prime field with modulus

$$
p = 2^{64} - 2^{32} + 1
$$

as the **canonical field** for the first production runtime and proving path.[^5][^1]

This field is mandatory for:

- runtime spectral state relevant to certification,
- encoded quantities such as `delta_pz_fp`, resonance amplitudes, and floors,
- prime masks and packed resonance words expressed as field elements,
- the first production Plonky3 AIR and public-input interface.[^2][^1]


## Implementation Guidance

### Required components

- Scalar reference implementation for `add`, `sub`, `mul`, and `neg`.
- Deterministic fixed-point encoding layer for runtime observables.
- SIMD backends for AVX-512 and NEON where available.[^6][^7][^1]
- Public-input adapters for `prime_mask_fp`, resonance words, and certification summaries.


### Interface contract

All arithmetic APIs MUST preserve canonical field representatives in `[0, p)` and MUST produce outputs identical to the scalar reference implementation. Runtime code MAY optimize implementation details, but field semantics are fixed.

### Non-goals

- No EC operations belong in the hot runtime path.
- No alternative base field may be introduced into the first production proof path.
- No float-only certification path is permitted.


## Security Considerations

- A single field across runtime and proving reduces semantic mismatch and conversion risk.[^2][^5]
- For any future secret-bearing arithmetic, constant-time reductions and branchless conditional logic are required.
- Fixed-point encoding rules must be immutable once proofs depend on them; otherwise old proofs may become uninterpretable.


## Performance Considerations

Plonky3 documents optimized targets including AVX-512 and NEON, and Goldilocks is directly aligned with those acceleration paths. This makes SIMD optimization a local implementation concern rather than a field-selection concern.[^7][^1][^6]

## Benchmarking Requirements

- Benchmark scalar and SIMD kernels on sequential, random, and NTT-like workloads.
- Report ns/element, cycles/element, and bandwidth.
- Re-run the AZ-TFTC path on scalar and SIMD backends to confirm proof equivalence and collect end-to-end speedup.


## Consequences

### Positive

- One field across runtime and proving lowers complexity.[^1][^2]
- Direct fit with the current Plonky3 ecosystem.[^5][^1]
- No non-native encoding is needed for first-line public inputs.


### Negative

- Some proof-adjacent tasks still require big-int lifts.
- Future migration away from Goldilocks would be costly.


## Acceptance Criteria

1. Goldilocks remains the only base field in the Pro-tier runtime path.
2. Plonky3 proofs for the first production certification flow use Goldilocks-native public inputs.[^2][^5]
3. Scalar and SIMD implementations are behaviorally identical on the verification suite.

***

# ADR-033: Pallas/Vesta as Optional EC Layer for Proof-Time Commitments

**Status:** Proposed
**Date:** 2026-05-16
**Decision Type:** Optional cryptographic curve layer
**Owners:** Cryptographic layer, recursion and commitment design

## Context

The Pasta curves, Pallas and Vesta, were designed for Halo 2 and related recursive proof settings. Their defining property is a curve cycle in which the order of each curve equals the base field of the other, which is critical for efficient recursion. The Pasta implementations and documentation position them as recursion-friendly, highly 2-adic curves suited to proof-system ecosystems rather than runtime arithmetic.[^8][^9][^10][^11]

The first production path for Phase Mirror Pro does not require elliptic-curve commitments in the runtime or primary proof trace. However, optional commitment or governance layers may later need an EC group aligned with modern recursive-proof practice.

## Decision

Select **Pallas/Vesta as the default optional EC layer** for future proof-time commitments, recursion, or audit-oriented cryptographic modules.[^10][^8]

This decision is intentionally scoped:

- Pallas/Vesta MAY be used in optional proof-time modules.
- Pallas/Vesta MUST remain outside the Goldilocks runtime hot path.
- Pallas/Vesta MUST NOT replace Goldilocks as the runtime or first-line proving field.


## Implementation Guidance

### Allowed use cases

- Pedersen-style commitments in optional witness or governance layers.
- MSM-heavy recursive or accumulation-oriented proof modules.
- Halo2-adjacent interoperability or future recursion stacks.[^12][^13]


### Required separation

- Runtime state remains Goldilocks-native.
- Pallas/Vesta arithmetic lives in a big-int or limbized proof-time module.
- Public interfaces must clearly distinguish field elements from EC points.


### Serialization

All curve points, scalars, and commitment artifacts must use explicit typed serialization and never be silently coerced into Goldilocks field elements.

## Security Considerations

- Curve operations require constant-time discipline when scalars or witnesses are secret.
- Point validation, subgroup checks, and canonical encoding rules are mandatory.
- Recursion or commitment layers must document trust boundaries and whether operations are public or secret.[^13][^12]


## Performance Considerations

Pasta curves are designed to support efficient recursion and have field structure favorable for proof-system arithmetic. That said, they are still 254-bit curves and therefore belong to the cold path, not the Goldilocks runtime fast path.[^9][^8]

## Benchmarking Requirements

- Measure MSM throughput, commitment throughput, and proof-time overhead separately from Goldilocks benchmarks.
- Track curve-operation cost in relation to total prover time.
- If recursion is introduced, benchmark verification-in-circuit cost across the full accumulation path.[^12][^13]


## Consequences

### Positive

- Provides a modern recursion-friendly EC default.[^8][^9]
- Keeps future commitment layers aligned with established Halo2/Pasta practice.[^11][^10]


### Negative

- Adds implementation and audit complexity.
- Introduces big-int code paths with higher maintenance cost.


## Acceptance Criteria

1. Any future EC commitment layer defaults to Pallas/Vesta unless explicitly overridden by a new ADR.
2. Goldilocks remains the only runtime field in the first production path.
3. EC modules are implemented as optional, isolated proof-time components.

***

# ADR-034: Twisted Edwards Forms as Optional Circuit-Level Optimization

**Status:** Proposed
**Date:** 2026-05-16
**Decision Type:** Circuit optimization policy
**Owners:** Circuit engineering, optional EC optimization layer

## Context

Twisted Edwards curves offer complete addition laws and avoid exceptional cases, which makes them especially attractive for arithmetic circuits and ZK applications. Jubjub is a prominent Zcash example: a twisted Edwards curve over the BLS12-381 scalar field chosen in part because its complete addition law is convenient in circuits.[^14][^15][^16][^17]

For the current architecture, however, Jubjub belongs to a different field ecosystem than Pallas/Vesta and Goldilocks. Any use of twisted Edwards forms in the current stack must therefore be understood as an **intra-field coordinate optimization**, not as a cross-field bridge.

## Decision

Permit twisted Edwards forms as an **optional optimization layer** for EC-heavy circuit modules, under the following rules:

- Edwards representations MUST be defined over the same base field as the underlying curve they optimize.
- No cross-field reinterpretation of Jubjub, Pallas, Vesta, or Goldilocks points is allowed.
- The first production Goldilocks-native certification path remains Edwards-free unless superseded by a later ADR.


## Implementation Guidance

### Allowed use

- A Pallas-native twisted Edwards model MAY be introduced if EC operations become circuit bottlenecks.
- Edwards forms MAY be used internally in optional commitment circuits to reduce constraint count.
- Weierstrass-to-Edwards conversions must be explicit, tested, and field-correct.


### Forbidden use

- Treating Jubjub points as Pallas points.
- Using Edwards forms to bypass field-boundary constraints.
- Pulling EC arithmetic into the Goldilocks-only certification baseline.


## Security Considerations

- Birational maps must be validated over the correct field.
- Exceptional cases in conversion routines must be fully documented and tested.
- Completeness of the Edwards group law helps circuit safety, but only if the chosen model and subgroup checks are correct.[^15][^16][^14]


## Performance Considerations

Twisted Edwards forms can reduce EC circuit complexity because complete addition formulas avoid branching-style case distinctions inside the circuit. This benefit matters only when EC operations are actually present and dominant.[^16][^14]

## Benchmarking Requirements

- Compare constraint count and prover time for Weierstrass versus Edwards implementations of the same optional EC module.
- Include conversion overhead when reporting net gains.
- Reject adoption if the optimization benefit is negligible at system level.


## Consequences

### Positive

- Preserves a clear path for future EC-circuit optimization.[^14][^16]
- Keeps implementation discipline around field boundaries.


### Negative

- Adds another abstraction layer to the optional EC stack.
- Can invite misuse if engineers assume birational equivalence implies cross-field compatibility.


## Acceptance Criteria

1. Any adopted Edwards optimization is field-native to the underlying EC layer.
2. No cross-field conversions are introduced.
3. The baseline Goldilocks-native proving path remains unchanged unless explicitly superseded.

***

## Suite Notes

This suite is intentionally staged:

- ADR-032 is foundational and active now.[^1][^5][^2]
- ADR-033 is optional and proof-time only.[^9][^8]
- ADR-034 is an optimization hook on top of ADR-033, not a prerequisite for production readiness.[^16][^14]

That ordering preserves the current architecture: **Goldilocks first, optional EC later, Edwards optimization only if justified by measured circuit cost**.[^5][^8][^14]
<span style="display:none">[^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^28][^29][^30]</span>

<div align="center">⁂</div>

[^1]: https://github.com/Plonky3/Plonky3/blob/main/README.md

[^2]: https://lita.gitbook.io/lita-documentation/architecture/proving-system-plonky3

[^3]: https://github.com/succinctlabs/plonky3/blob/main/README.md

[^4]: https://hackmd.io/@Voidkai/BkNX3xUZA

[^5]: https://polygon.technology/blog/polygon-plonky3-the-next-generation-of-zk-proving-systems-is-production-ready

[^6]: https://github.com/Plonky3/Plonky3/issues/252

[^7]: https://github.com/Plonky3/Plonky3/pulls

[^8]: https://github.com/zcash/pasta_curves

[^9]: https://forum.zcashcommunity.com/t/the-pasta-curves-for-halo-2-and-beyond-halo-2-pasta/38355

[^10]: https://z.cash/the-pasta-curves-for-halo-2-and-beyond/

[^11]: https://zcash.github.io/halo2/design/implementation/fields.html

[^12]: https://github.com/zcash/halo2/blob/main/book/src/background/recursion.md

[^13]: https://github.com/ChainSafe/recursive-zk-bridge/blob/main/THEORY.md

[^14]: https://bitzecbzc.github.io/technology/jubjub/index.html

[^15]: https://github.com/zkcrypto/jubjub

[^16]: https://repositori.upf.edu/bitstreams/73b5d440-44dc-4cc4-b19d-bba4c6f54d60/download

[^17]: https://github.com/daira/jubjub

[^18]: https://github.com/QEDProtocol/plonky3-fibonacci

[^19]: https://github.com/succinctlabs/plonky3

[^20]: https://github.com/telosnetwork/Plonky3

[^21]: https://github.com/zcash/orchard/blob/main/src/circuit.rs

[^22]: https://github.com/barryWhiteHat/baby_jubjub

[^23]: https://github.com/Plonky3/Plonky3

[^24]: https://github.com/zcash/halo2/issues/249

[^25]: https://github.com/0xmozak/plonky3/blob/main/README.md

[^26]: https://hackmd.io/@bobbinth/SyUwZiDKle

[^27]: https://x.com/samrags_/status/1834255193136861451

[^28]: https://www.johndcook.com/blog/2025/08/01/jubjub/

[^29]: https://www.youtube.com/watch?v=txMqpVPYMHw

[^30]: https://ethresear.ch/t/generating-pasta-keypairs/22610

