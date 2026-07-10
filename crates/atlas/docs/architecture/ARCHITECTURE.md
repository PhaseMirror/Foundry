# Architecture

This document defines **how** the source specification
([`../conceptual-model/00-source.md`](../conceptual-model/00-source.md)) is realized: the
development flow, the workspace organization, and the parametric framework.

## 1. The docs-as-code flow

Development is strictly directional. Nothing is implemented before it is *defined*, and
nothing is *defined* without a place in the conceptual model.

```
        docs/conceptual-model/00-source.md          (1) the cited authority (prose)
                     │  transcribed, row by row, into
                     ▼
        model/{dictionary,status,oracles}.toml      (2) the model as typed data
                     │  parsed + invariant-checked by
                     ▼
        crates/tqc-model                             (3) typed registries (single source of truth)
                     │  each dictionary row names a
                     ▼
        features/<stage>/<row>.feature               (4) the BDD definition (Gherkin)
                     │  whose steps are bound in
                     ▼
        crates/tqc-conformance (cucumber steps)      (5) the test
                     │  which exercises the
                     ▼
        crates/tqc-core  (+ tqc-atlas instance)      (6) the PARAMETRIC implementation
                     │  validated against
                     ▼
        crates/tqc-vv + oracles/                     (7) the external authoritative oracle
```

A feature is **done** only when (4)→(7) are all present and green in CI. The honesty gate
(below) mechanically forbids skipping any link — e.g. a dictionary row with no feature, a
feature with a pending step, or a witness that asserts a claim its ledger status does not
permit.

## 2. Workspace organization

A virtual Cargo workspace. Crate boundaries are drawn along **axes of change** so that a
change in one concern touches one crate.

| Crate | Responsibility | Changes when… |
|---|---|---|
| `tqc-model` | Parses `model/*.toml` into typed, invariant-checked registries (dictionary, status ledger, oracle registry) and the parametric `UseCaseParams`. No math, no substrate. | the conceptual model changes |
| `tqc-core` | The **parametric** MTC framework: label space, generators, inner product, spectrum, coxeter, modular, octonion eight-square, E8 PSD anchor, amplitude encoding — generic over a use-case, `no_std`. DRY home of all pure behavior. | the mathematics changes |
| `tqc-atlas` | The UOR Atlas **use-case instance** `(q=4, T=3, O=8)` over `tqc-core`, the use-case registry, and the E8 Cartan/Gram. | the Atlas instance changes |
| `tqc-mtc` | The **MTC builds**: the modular `S`/`T` and braiding `R` constructed as the quantum double `D(Z_n)` and validated against the MTC axioms. Generic over the use-case; `std`. | the MTC construction changes |
| `tqc-substrate` | The **sole** importer of holospaces / hologram / uor-addr. Exposes κ-addressing and the realized `g2`/`f4`/`e6`/`e7`/`e8` compositions across all five σ-axes. | the substrate API changes |
| `tqc-vv` | V&V witnesses + loaders for external oracle artifacts (with checksum verification); binds each row to its oracle. | an oracle or a witness changes |
| `tqc-conformance` | The cucumber BDD runner (gating suites + the open-probe harness), the step definitions, and the honesty meta-gate (model ⇄ features ⇄ witnesses cross-check + parametricity leak-check). | the BDD/gate wiring changes |
| `xtask` | Automation: oracle verification, F1 pin checking, conformance reporting. | tooling changes |

**Why a facade for the substrate.** Exactly one crate (`tqc-substrate`) may name
holospaces/hologram/uor-addr. The pure math crates (`tqc-model`, `tqc-core`, `tqc-atlas`,
`tqc-mtc`) stay substrate-free and offline/`no_std`-testable; when the pinned substrate revision
moves, the blast radius is one crate.

## 3. The parametric framework

The source specification describes the UOR Atlas concretely: scope `q=4`, modality `T=3`,
context `O=8`, giving `96` classes. **The implementation does not hardcode these.** Every
quantity the Atlas fixes is instead a function of a `UseCaseParams { scope, modality,
context }`, so arbitrary use-cases instantiate the same code:

| Atlas quantity | Parametric definition | Atlas value |
|---|---|---|
| class count | `scope · modality · context` | `4·3·8 = 96` |
| class stride | `modality · context` | `3·8 = 24` |
| `classIndex(h2,d,l)` | `stride·h2 + context·d + l` | — |
| carrier dimension | `modality · context` | `24` |
| generator `σ` order | `scope` | `4` |
| generator `τ` order | `context` | `8` |
| generator `μ` order | `2` (mirror, always) | `2` |

The Atlas is therefore one *instance*. The framework is validated two ways:

1. **Against F1** at the Atlas instance — the parametric formulas must reproduce the
   machine-checked constants F1 proves (`96`, `24`, `{10,7,2,−1}`, `{1,2,7,14}`, σ/τ/μ
   orders, …). This is the authoritative anchor.
2. **Across instances** — the framework is exercised at a *second*, arbitrary `UseCaseParams`
   to prove genuine parametricity (no Atlas constant leaks into the generic code). Known
   small MTCs (e.g. the trivial / cyclic models, and later Fibonacci/Ising) double as oracles
   for the MTC-axiom predicates.

DRY is structural: a quantity is defined once, in `tqc-core`, as a function of the
parameters; `tqc-atlas` supplies the parameters and the F1 expectations, never re-derives the
formula.

## 4. Status discipline & the honesty gate

Each dictionary row carries one of three levels (see
[`../conceptual-model/03-status-discipline.md`](../conceptual-model/03-status-discipline.md)):
`some-true`, `build`, `open`. The honesty meta-gate (in `tqc-conformance`) enforces, in CI:

- **Coverage** — every dictionary row has a feature *and* a witness; every feature/witness
  maps back to a row (bidirectional).
- **Status discipline** — a `some-true` row's witness must be a green, gating check; a
  `build` row is validated **only against MTC axioms / sourced reductions**, never assumed
  sound; an `open` row may be *probed and reported* but never asserted true.
- **Euclidean inner product** — the inner product is the positive-definite Euclidean
  composition norm `Σxᵢ²`, so "generators are unitary" is genuine orthogonality, established
  directly.

This mirrors F1's own `scripts/honesty_audit.sh`, promoted from a script to a typed,
test-enforced invariant.

## 5. Portability

`tqc-model`, `tqc-core`, and `tqc-atlas` are `#![no_std]`-friendly (`alloc` only) so the
parametric core compiles for `wasm32-unknown-unknown` and `thumbv7em-none-eabi`, matching the
holospaces substrate's portability posture. The V&V, BDD, and substrate-engine surfaces are
`std`-only and gated accordingly.
