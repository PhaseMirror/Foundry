# Architecture Decision Record (ADR‑0006) – Production‑Grade Hybrid Verification Pipeline for Lean 4 and Rust/Kani

**Status:** ✅ Accepted & Implemented
**Date:** 2026‑08‑29
**Domain:** Multiplicity Theory, PhaseMirror‑Prime Stack (P²C Core v1.1 / Sedona Spine)
**Supersedes:** None

---

## 1. Executive Summary & Context
Formalizing complex mathematical physics and high‑assurance runtime architectures (such as Complex Gravitational Coupling, Prime‑Indexed Recursive Tensor Mathematics (PIRTM), and Operator‑First Arithmetic) requires absolute logical rigor. Traditional verification approaches often force a choice between unexecutable abstract mathematics or unprovable floating‑point software systems. To resolve this, we enforce a strict hybrid verification architecture:

- **Zero‑Mathlib, Zero‑Sorry Lean 4 Core** (`/lean`) to manage foundational invariants.
- **Rust/Kani Bounded Execution** (`/rust`) using exact rational intervals (`num_rational::Rational64`) to eliminate IEEE‑754 floating‑point ambiguity.
- **Automated Proof‑Contracts & FFI Bridging** to bind model‑checking results into Lean via deterministic certificate generation.

---

## 2. Decision Architecture
### Pillar 1: Pure Constructivist Lean 4 Proofs (`/lean`)
- **No‑Mathlib Policy:** To minimise the trusted computing base (TCB) and ensure maximum portability, the core specifications rely entirely on core Lean 4 without expansive external libraries.
- **Zero‑Sorry Mandate:** Build pipelines enforce an explicit token scan (`grep -rn "sorry" lean/Core`) failing closed on any unverified placeholder outside designated quarantine manifests.

### Pillar 2: Rust Execution Engine & Kani Model Checking (`/rust`)
- **Exact Rational Arithmetic:** All continuous numeric bounds are implemented using `num_rational::Rational64` to prevent serialization tears and platform‑dependent non‑determinism.
- **Exhaustive Bounded Verification:** Kani explores execution trees up to defined parameters (e.g., matrix dimension bounds or trial‑division loops) to guarantee runtime contractivity (‖Φ‖ ≤ γ < 1).

### Pillar 3: FFI Axiom Proxies & Certificate Generation
- **Automated Translation:** Scripts (`scripts/generate_certificates.py`) parse Kani logs, recompute invariants, and generate authoritative JSON telemetry alongside Lean axioms (`KaniCertificates.lean`).
- **Fail‑Closed Governance:** Any drift between generated proofs and committed source code breaks the CI pipeline via strict byte‑exact matching (`--check`).

---

## 3. Production File Tree Layout
```
uor‑r4/
├── .github/
│   └── workflows/
│       └── apex‑integrity.yml        # CI/CD: Kani model checking + Lean proof gates
├── contracts/
│   └── fpes_invariants.yaml          # Provable‑contracts specification
├── lean/
│   ├── lakefile.lean                 # Zero‑mathlib configuration
│   └── Core/
│       ├── Axioms.lean               # Quarantined FFI proxies (kani_stability_certificate)
│       └── GravitationalCoupling.lean# Zero‑sorry Lean 4 gravitational coupling proof
├── src/
│   ├── engine/
│   │   └── complex_gravitational.rs  # 3‑D vector math, MassiveBody, Newtonian pairwise forces
│   ├── adr/
│   │   ├── mod.rs                    # Core ADR struct, state‑transition rules, proofs
│   │   ├── status.rs                 # ADRStatus enum (Proposed, Accepted, etc.)
│   │   └── link.rs                   # ArtifactLink struct for external references
│   └── main.rs                       # Entry point & three‑body simulation harness
├── tests/
│   └── adr_invariants.rs             # Test harness exercising invariant bounds
└── scripts/
    └── validate_zero_drift.sh        # Pre‑commit CI enforcer
```

---

## 4. Verification Protocol & Execution Sequence
1. **Run Bounded Model Checking**
   ```bash
   cargo kani
   ```
2. **Build Zero‑Sorry Lean Core**
   ```bash
   cd lean && lake build
   ```
3. **Execute Integration Test Suite**
   ```bash
   cargo test
   ```
If any execution path violates the constitutional contraction bounds or introduces unverified tokens, the pipeline halts immediately with a fail‑closed `SIG_GOV_KILL` response.

---

## 5. Acceptance Criteria
- All Lean files compile with `lake build` and contain **zero** `sorry` tokens outside of `Axioms.lean`.
- `cargo kani` completes without verification failures, confirming the bounded‑execution invariants.
- CI workflow (`apex‑integrity.yml`) passes both the Lean and Kani stages.
- The generated Kani certificates match the Lean axioms exactly (byte‑for‑byte).

---

*This ADR establishes a reproducible, auditable, and formally verified pipeline that unites constructive theorem proving (Lean 4) with exhaustive execution‑level model checking (Rust/Kani), satisfying both the PhaseMirror‑Prime and Sedona‑Spine mandates.*

