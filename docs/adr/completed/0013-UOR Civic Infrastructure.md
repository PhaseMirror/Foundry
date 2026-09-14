# ADR-0013: UOR Civic Infrastructure

**Status:** Completed

## Context

The Foundry DAO progresses through three strategic developmental epochs. PrismPM governs process and packaging law; the UCC governs physical and dynamical law via the universal closure sextuple $\mathcal{U} = (X, \circ, \alpha, \mu, \Phi, \Delta)$. PWEH operationalizes contractivity and fail-closed interlocks as an active execution lock, and CRMF envelopes canonicalized under BCS provide tamper-evident attestation.

The architecture requires a canonical wire format for cryptographic commitments, a fail-closed governance mechanism, and an integrity chain that binds execution traces to prime-indexed attestations. Without these, the system cannot guarantee cross-language reproducibility, fail-closed governance, or path-dependent tamper resistance.

## Decision

Adopt the canonical BCS wire format for the `UnsignedCrmfEnvelope`, the PWEH integrity binding for execution traces, the contractivity gate for the UCC, and fail-closed interlocks for governance.

- **Canonical BCS wire format.** The `UnsignedCrmfEnvelope` is serialized with fixed field order (envelope_id [32], timestamp [8], poseidon_commitment [32], sha256_anchor [32], ed25519_signature [64], metrics [16], metadata [variable]), unsigned big-endian integers, no floating-point fields, and a ULEB128-prefixed metadata tail. Total canonical length is deterministically `188 + |metadata|`.
- **Fail-closed interlocks.** Any unmodeled associator defect ($\|\Delta\| > \varepsilon$) or expansive transition ($\Lambda_m \geq 1$) triggers a non-maskable SIG_GOV_KILL (L0_HALT) before unverified side effects materialize. The kill latch never un-halts.
- **Contractivity gate.** A UCC state transition is admitted only when the contractivity bound $\Lambda_m < 1$ holds (fixed-point scaled at SCALE = 10^9).
- **PWEH binding.** Each execution step binds a four-field integrity tuple $S(t) = \text{Hash}_{\text{PQC}}(S(t-1) \| p^t \| \|A_{p^t} T(t)\| \| M(t))$. The binding is injective and order-dependent: path dependence is a feature, not a bug.

## Consequences

* Deterministic, cross-language canonical byte streams for cryptographic commitments (Rust/Lean reproducible).
* Path-dependent tamper resistance across the whole PWEH chain — forgery is a path-collision problem.
* Fail-closed governance: any unmodeled defect halts L0 before side effects materialize.
* Poseidon2 sponge absorption (t=9, r=8) is the ZK sealing stage; the field implementation is staged.
* Floating-point is structurally excluded from all wire formats (ADR-0021).

## Traceability & Artifact Links

* **[Source File]** `docs/papers/UOR Civic Infrastructure_.docx` — "UOR Civic Infrastructure" (The Triadic Evolution: From Foundation to Multiplicity).
* **[Delivered — Lean]** `lean/MTPI/ADR0013.lean` — canonical BCS wire format, fail-closed interlocks, contractivity gate, and PWEH binding formalized as zero-sorry Lean 4 theorems.
* **[Delivered — Lean]** `lean/MTPI/ADR0013Test.lean` — runtime witness executing closed-form claims of the formal scaffold.
* **[Delivered — Rust]** `packages/rust/crmf/src/canonical.rs` — canonical BCS wire format (Kani-verified).
* **[Delivered — Rust]** `packages/rust/crmf/src/failgate.rs` — fail-closed interlocks (contractivity, fail latch) (Kani-verified).
* **[Delivered — Rust]** `packages/rust/crmf/src/pweh.rs` — PWEH integrity chain (Kani-verified).
* **[Related ADR]** ADR-0014 — the operator product this infrastructure serves.
* **[Related ADR]** ADR-0015 — the legal/operating scaffold the infrastructure runs on.
* **[Related ADR]** ADR-0021 — prime-indexing math underlying BCS and PWEH.

## Appendix: BCS Wire Format Detail

### Universal BCS Packing Rules

* **Fixed Field Order:** Struct fields are packed consecutively in their exact declaration order, stripping all labels and keys.
* **Deterministic Integer Types:** All floating-point numbers are excluded; integers are packed as unsigned, big-endian values.
* **Length-Prefixed Sequences:** Variable-length sequences are prefixed using ULEB128 element counts or standard u32 lengths.
* **Optional Fields:** Any optional fields are represented by a leading boolean byte.

### CRMF Envelope Byte Sequence

1. `envelope_id`: Fixed [u8; 32] — SHA-256 digest of the fields.
2. `timestamp`: u64 epoch integer.
3. `poseidon_commitment`: Fixed [u8; 32] — BN254 scalar field element output.
4. `sha256_anchor`: Fixed [u8; 32] — canonical payload digest.
5. `ed25519_signature`: Fixed [u8; 64] — local enterprise attestation.
6. `metrics.lambda_m`: u64 — fixed-point contractivity invariant $\Lambda_m$.
7. `metrics.drift`: u64 — bounded drift limits.
8. `metadata`: Dynamic Vec<u8> prefixed by its length count (may be empty).

### Poseidon2 Sponge Absorption

* **Field Element Chunking:** BCS byte stream divided into little-endian 32-byte chunks → single BN254 field element each.
* **Sponge Ingestion:** Field elements absorbed in chunks corresponding to rate $r = 8$.
* **Compression:** Poseidon2 permutation (width $t = 9$) processes rate chunks and squeezes a 256-bit validity seal digest.
