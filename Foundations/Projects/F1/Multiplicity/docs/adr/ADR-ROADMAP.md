# ADR Roadmap — F1-Square Prime Substrate

## Purpose

This roadmap indexes every Architecture Decision Record (ADR) governing the **F1-Square Prime** production track. All records below are sourced from the verified markdown corpus in `Prime/` and are kept **inside `Prime/`** per the production convention.

## Directory Layout

```
Prime/
├── docs/
│   ├── ADR-ROADMAP.md                 ← this file
│   ├── adr/
│   │   ├── ADR-000-Roadmap.md         ← this index
│   │   ├── ADR-100-Conditional-Proof-Scaffold.md
│   │   ├── ADR-101-Characteristic-1-Substrate.md
│   │   ├── ADR-102-Missing-Object-Formalization.md
│   │   ├── ADR-103-T3-Intersection-Harness.md
│   │   ├── ADR-104-Weil-Explicit-Formula-Docking.md
│   │   ├── ADR-105-Li-Face-Bright-Line.md
│   │   ├── ADR-106-Sovereign-Stack.md
│   │   ├── ADR-107-MT-Central-Tension.md
│   │   └── ADR-108-Defensive-Publication.md
│   ├── F1SQUARE_FORMALIZATION.md      ← manuscript
│   └── RH_STATUS_LEDGER.md            ← status ledger
├── F1Square Lean Formalization.md    ← source corpus
├── characteristic_1_constructions.md ← source corpus
├── missing_object_over_Q.md          ← source corpus
├── f1_square_intersection_theory.md  ← source corpus
├── F1-Square T3 Harness Milestone.md ← source corpus
├── RH-Neutral Weil Explicit Formula Reconstruction.md ← source corpus
└── ... (other Prime artifacts)
```

## Cross-References

| External ADR | Relation |
|---|---|
| `docs/adr/ADR-001-Combined-Mandate.md` | Sedona Spine governance supersedes; L0 invariants flow down |
| `docs/adr/ADR-013-F1-Square-Signature-Check.md` | Precursor to ADR-103; T1 truncation work elevated to full T3 harness |
| `docs/adr/ADR-043-Combined-Sedona-Spine-Phase-Mirror-Mandate.md` | Phase Mirror orchestration layer; Λ_m consciousness interface binding |

## ADR Register

| ID | Title | Status | Horizon |
|---|---|---|---|
| ADR-100 | F1-Square Conditional Proof Scaffold | Accepted | v1.0 baseline |
| ADR-101 | Characteristic-1 Substrate Foundation | Accepted | v0.15–v0.17 |
| ADR-102 | Missing Object Formalization (Spec ℤ ×_𝔽₁ Spec ℤ) | Accepted | v0.17–v0.21 |
| ADR-103 | T3 Intersection Harness & Candidate Testing | Accepted | v0.18–v0.22 |
| ADR-104 | Weil Explicit Formula RH-Neutral Docking | Accepted | v0.19–v0.22 |
| ADR-105 | Li Face Bright Line & Pos λ₁ Anchor | Accepted | v0.15–v0.22 |
| ADR-106 | Sovereign Stack (Recursive Proof + TEE + Λ-Trace) | Accepted | v0.21–v0.22 |
| ADR-107 | Multiplicity-MT Central Tension Integration | Proposed | 7-day horizon |
| ADR-108 | Defensive Publication & Manuscript Pipeline | Accepted | 30-day horizon |

## Release-to-ADR Traceability

| Release | What Shipped | Governing ADR(s) |
|---|---|---|
| v0.15.0 | Complex analytic engine (exp, cos/sin, ζ for Re s > 1) | ADR-101 |
| v0.16.0 | Analytic continuation, higher λₙ (n ≥ 2), γ₂ ≥ −0.02 | ADR-101 |
| v0.17.0 | Arithmetic square 𝕊 (canonical, universal property, intersection lattice) | ADR-101, ADR-102 |
| v0.18.0 | Bridge (geometric ⟺ analytic), λ₂ decomposition, attempt | ADR-102, ADR-103 |
| v0.19.0 | Weil functional, dominance face, explicit formula, unconditional window | ADR-104 |
| v0.20.0 | UOR-based H¹ object, dictionary ⟨Cₙ,Cₙ⟩ = −2λₙ as theorem, forced signature | ADR-102, ADR-103 |
| v0.21.0 | Atlas isometric embedding, Stage G localization, no-smuggling audit | ADR-102, ADR-103, ADR-106 |
| v0.22.0 | Frontier research (Sonine projection, discharged interfaces) | ADR-104, ADR-105, ADR-107 |

## Invariant Flow

```
Ξ-Constitution (docs/)
    └── ADR-001 Combined Mandate (L0 invariants)
            ├── ADR-101 Characteristic-1 Substrate (no sorry, no Mathlib, {propext, Quot.sound})
            ├── ADR-102 Missing Object (hodgeIndexHolds = none / liPositivityHolds = none)
            ├── ADR-103 T3 Harness (decidable candidate testing)
            ├── ADR-104 Weil Explicit Formula (RH-neutral, band-limited reconstruction)
            ├── ADR-105 Li Face (Bright Line: Pos λ₁ anchored, full sequence none)
            ├── ADR-106 Sovereign Stack (TEE + Λ-Trace + Archivum)
            ├── ADR-107 MT Central Tension (multiplicity functor as divisor candidate)
            └── ADR-108 Defensive Publication (manuscript pipeline, Zenodo, arXiv)
```
