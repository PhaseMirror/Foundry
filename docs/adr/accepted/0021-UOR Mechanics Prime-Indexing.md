# ADR-0021: UOR Mechanics — The Exact Math of Prime-Indexing

**Status:** Accepted

## Context
Distributed state identification by mutable file paths permits duplication, reordering, and platform-dependent drift. The UOR framework requires an identity scheme that is collision-free, compositionally rich, and exactly reproducible across heterogeneous nodes. The mathematical bedrock is locked as the canonical substrate for execution receipts, settlement, and integrity sealing; downstream market structures (Holotrade liquidity engine, Six Auditable Multipliers, Flux Core failover, TimeOps/GlowChain causal propagation, BountyForge, the 1B-node edge lattice) are exploratory applications of this same substrate and feed future ADRs.

## Decision
Adopt the exact math of prime-indexing as the canonical UOR substrate.

- **Irreducible identity.** A prime number is the invariant identity of a node or object, constant across computational contexts. Composites encode relations. Identity is irreducible yet compositionally rich.
- **Exponents as memory (OFA-ii).** For an integer n = ∏ pᵢ^kᵢ, the exponent kᵢ is a surplus ledger — the definitive record of a prime's carried-forward participation history. The prime does not reset; it accumulates (p → p² → p³), making multiplicity recursive memory and time a linear, irreversible scalar.
- **Lawful composition.** A merge of two prime-indexed states is the least common multiple, K₁ ⊗ K₂ = lcm(K₁, K₂) — a lossless structural join preserving the strongest exponent per prime without double-counting, mathematically preventing duplication and computational drift.
- **Multiplicative union.** An aggregate union is exact exponent aggregation, K₁ ⊕ K₂ = ∏ₚ p^(vₚ(K₁) + vₚ(K₂)).
- **Zero-drift architecture.** Strict exact rational (integer-ratio) arithmetic; floating point is banned. $1.00 is always $1.00; no rounding site exists for penny-shaving or drift.
- **Cryptographic verification.** (1) Binary Canonical Serialization (BCS): state metrics and parameters deterministically serialized with fixed field orders and ULEB128-prefixed sequences, stripping platform-dependent padding. (2) Poseidon2 ZK sealing: the canonical payload is compressed via a Poseidon2 sponge configuration (t = 9, r = 8) into a succinct tamper-evident validity seal — a self-contained passport of mathematical coherence.
- **Settlement cleavage (Holotrade micro-structure, phase-gated).** Fee = 1/10·ΔP; node yield = ask + 9/10·ΔP, in exact rationals with receipt-locked ledger finality. Cold-start uses institutional forward reserves, phase-dependent validator weighting (probation tiers), and standby arbitrage incentives; execution is non-commutative (order sequence changes the hash), monotonic (exponents accumulate), and fail-closed (contractivity invariants halt the node on breach).

## Consequences
* State is never identified by mutable path; identity, history, and compensation all derive from one prime-indexed ledger.
* Merges are lossless and deduplicating by construction (lcm), and unions are exact by exponent addition — no drift, no double count.
* Deterministic BCS + Poseidon2 sealing make execution receipts tamper-evident and cross-platform (Rust/Lean) reproducible.
* Banning floats forecloses a whole class of settlement attacks (penny-shaving, IEEE-754 drift).
* The substrate already has a machine-checked core: this is the mathematical basis of the ADR-0013 canonical BCS wire format and PWEH integrity chain.

## Traceability & Artifact Links
* **[Source File]** `docs/papers/UOR Mechanics_ The Exact Math of Prime-Indexing.docx` — "UOR Mechanics: The Exact Math of Prime-Indexing" (mathematical bedrock).
* **[Related ADR]** ADR-0013 — canonical BCS wire format, fail-closed interlocks, and PWEH integrity chain implementing this math (Lean `lean/MTPI/ADR0013.lean`; Rust `packages/rust/crmf`, Kani-verified).
* **[Related ADR]** `ADR-005.md` — BLAKE2b-16 personalization and canonical bytecode wire format lineage.
* **[Related ADR]** `ADR-008.md` — Prime Signature Canonical Monoid as the exclusive Rust kernel substrate.