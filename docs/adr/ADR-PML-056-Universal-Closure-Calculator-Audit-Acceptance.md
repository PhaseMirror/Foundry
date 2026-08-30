# ADR-PML-056: Acceptance of the Universal Closure Calculator (UCC) Phase Mirror Audit v2

**Status:** Accepted
**Date:** 2026-08-30
**Deciders:** Principal Formal Methods Engineer (Phase Mirror), the-examiner
**Context:** Universal Closure Calculator (`github.com/PhaseMirror/UCC`) — defensive publication and Lean 4 / Rust verification stack

---

## 1. Context & Problem Statement

The Universal Closure Calculator (UCC) was the subject of a Phase Mirror audit
(v1, inspected SHA `5da5157a`) that found a gap between claims (RH proven,
Kani-verified completion kernel, EVM cryptographic seal, byte-exact Lean↔Rust
parity, committed build artifacts) and the mechanisms actually present in the
repository. A v2 audit (`Universal_Closure/PHASE MIRROR AUDIT.md`, scored against
HEAD `cce26c0`) records the remediation.

This ADR formally accepts the v2 audit outcome and records the two items the
audit leaves explicitly open as **accepted, disclosed risks**, so they are
governed rather than concealed.

## 2. Decision

We accept the v2 audit verdict: the UCC is a *conjecture stack with local
algebraic fragments*. It makes no claim of a proof of RH, no cryptographic seal
beyond what the Rust gate implements, and no hardware interlock beyond
process-exit semantics.

### Accepted closure criteria (A1–A9) — all satisfied
- **A1** — RH relabeled to CONJECTURE (README + `UCC_RH.lean` retitled
  "DUMMY INSTANCE — NOT A PROOF OF RH").
- **A2** — Certificate script fails closed (exit 1 on empty Kani logs); no
  placeholder `PASSED` rows.
- **A3** — Kani row dropped; no `cargo kani` in CI; "Kani proves" sentences
  removed from README.
- **A4** — `Foundations.F1`/`Care` imports declared OUT OF SCOPE; CI builds only
  `lean/Core`.
- **A5** — `target/` untracked (`.gitignore` lists `/target`, `**/target`).
- **A6** — Byte-exact parity claim withdrawn (`byte_exact: false`); 10 shared
  CRat fixtures added (`docs/parity_fixtures.md`).
- **A7** — Circom/Solidity rows removed; `contracts/` is YAML-only.
- **A8** — `Cargo.toml` license matches `LICENSE` title; `repository`/`homepage`
  point at `PhaseMirror/UCC`.
- **A9** — Verification badge → `PhaseMirror/UCC/actions/.../ucc-integrity.yml`.

### Recorded deferred items (governed, non-blocking)
- **B3** — `Foundations.F1`/`Care` imports remain; module declared OUT OF SCOPE
  (T3-permitted branch) and is not built by CI. Owner action **C1**: vendor or
  delete the imports.
- **B7** — `concreteUCC.li := fun _ => one` (trivial constant). Owner action
  **C2**: replace with a published Keiper–Li table (n ≤ 20) once the Lean `Real`
  constructor path is wired. Until then the instance is explicitly labeled DUMMY.

Both items are disclosed in the v2 audit, in `UCC_RH.lean`, and in the
defensive-publication footnote. They are **accepted risks**, not hidden defects.

## 3. Consequences

- The UCC closure is now under the Phase Mirror ADR governance framework (the
  zero-`sorry` discipline applies to `lean/Core`; `Foundations/` remains
  explicitly out of scope).
- B3 and B7 are tracked to closure via audit actions C1 / C2.
- The audit document (`Universal_Closure/PHASE MIRROR AUDIT.md`) is
  version-controlled; UCC CI path filters already include `Universal_Closure/**`
  and `docs/**`, so edits to it trigger the integrity workflow. No separate audit
  CI job is required.

## 4. Links
- Audit v2: `Universal_Closure/PHASE MIRROR AUDIT.md` (UCC)
- Audit v1 (superseded): `Universal_Closure/Universal Closure Calculator Audit.md` (UCC)
- Shared fixtures: `docs/parity_fixtures.md` (UCC)
- Dummy instance: `Foundations/universal_closure/UCC_RH.lean` (UCC)

---

## 5. Non-Normative Design-Philosophy Addendum

> **Scope notice.** The text below is the guiding ontological framework of the
> architecture. It is *not* a Lean 4 proof, a Kani transcript, or a runtime invariant.
> The only exercised verification is the Rust contractivity gate plus the 10 shared
> CRat parity fixtures; RH remains a conjecture; `UCC_RH.lean` is an explicitly labeled
> DUMMY tautology. Canonical LaTeX form: `Universal_Closure/The Universal Calculator.tex`,
> §"Design Philosophy: Anchoring Computation in Number-Theoretic Structure".

### Arithmetic as Lawful Transformation
Within the Multiplicity paradigm, computation is treated not as arbitrary manipulation
of floating-point bit sequences, but as a theory of lawful transformations. Classical
systems rely on floating-point approximations that accumulate micro-drifts, effectively
trapping execution inside a self-contained "synthetic universe". By contrast, the
Multiplicity architecture builds its computational substrate upon the irreducible
structure of the natural numbers — specifically utilizing the Fundamental Theorem of
Arithmetic (FTA) as a constitutional gauge anchor. Prime factorization functions as
native memory and structural identity, ensuring that composite states preserve their
compositional lineage across transformations.

### Number Theory as an Architectural Blueprint
The integration of prime-indexed operators, Hecke recurrence relations, and spectral
bounds (such as those associated with the Riemann zeta zeros) serves a dual purpose:

- **The Engineering Reality (Verified):** At the code level, prime indexing and exact
  rational arithmetic (`Ratio<i64>`) provide collision-free state spaces and eliminate
  IEEE-754 serialization drift. They allow the runtime to compute deterministic bounds
  that satisfy rigorous contraction requirements (Λₘ < 1).
- **The Philosophical Horizon (Unproven / Heuristic):** Whether analyzing the deep
  distribution of zeta zeros or framing the system around conjectures like the Riemann
  Hypothesis, the architecture borrows its structural rhythm from analytic number
  theory. Even if specific number-theoretic conjectures remain unproven externally,
  utilizing them as design blueprints ensures that the system's internal topology
  mirrors the rigid, non-arbitrary constraints of mathematical reality rather than
  human-invented heuristics.

### Separation of Engineering Invariants from Metaphysical Claims
To maintain absolute audit integrity, engineers and auditors must draw a hard line
between:

1. **Executable Guarantees:** Code-level checks (the Rust contractivity gate and the 10
   shared CRat parity fixtures) and the zero-sorry Lean 4 proofs over `lean/Core`
   verify contractivity, type safety, and memory bounds. Kani harness files exist but
   are *not* wired into CI; they are not an active executable guarantee (audit items
   A2, A3, B4, T6).
2. **Foundational Metaphors:** Number-theoretic models, zeta-comb spectral alignments,
   and ontological interpretations that explain *why* the architecture is shaped the way
   it is.

The former constitutes the functional machine; the latter provides the conceptual
grammar that keeps the machine aligned with universal invariants.
