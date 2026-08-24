# ADR-104: MKT v3 Production-Grade Development Roadmap

> **Status**: Proposed
> **Date**: 2026-04-01
> **Authors**: Multiplicity Foundation
> **Supersedes**: Ad-hoc MKT v3 prototype planning in `Multiplicity_Knot_Theory_v3.md`
> **Related**: ADR-101 (MKT bridge), ADR-102 (phase transition), ADR-103 (SlopeUB), CSL-ADR-ROADMAP-2
> **Scope**: Mathematical soundness, software hardening, cryptographic prototype, CI/release readiness

---

## Executive Summary

This roadmap turns the MKT v3 research program into a production-grade engineering plan with explicit gates, artifacts, and rollback criteria.

Primary objective: deliver a reproducible, tested, and policy-governed MKT v3 stack that can support:

1. Prime-colored braid computations with deterministic canonicalization.
2. Prime-weighted invariant/protection functional with finite-X controls.
3. Multiplicity-based commitment (MBC) prototype with measurable binding/collision behavior.
4. CI-grade validation profiles (base and async) and release packaging.

**Timeline**: 4 implementation phases + 1 hardening phase (6-8 weeks)
**Risk**: High (math assumptions + cryptographic claims), reduced by staged falsification gates.

---

## Non-Negotiable Production Criteria

A phase is considered production-ready only if all are true:

- Determinism: repeated runs produce identical canonical braid serialization and invariant vectors within tolerance.
- Traceability: every gate emits machine-readable artifacts in `checksums/`.
- Falsifiability: conjectural claims remain marked as conjectural; failed gates degrade capability rather than silently passing.
- Security posture: cryptographic claims remain heuristic unless supported by formal reductions or bounded adversarial evidence.
- CI health: tests pass under default pytest profile; async-only tests run in explicit async profile.

---

## Architecture Targets

### Target Modules

- `multiplicity/mkt_colored_braid.py`
- `multiplicity/mkt_invariant.py`
- `multiplicity/mkt_constants_estimation.py`
- `multiplicity/mkt_commitment.py`
- `multiplicity/mkt_artifacts.py`

### Target Tests

- `tests/test_adr104_mkt_colored_braid.py`
- `tests/test_adr104_mkt_invariant.py`
- `tests/test_adr104_mkt_constants.py`
- `tests/test_adr104_mkt_commitment.py`
- `tests/test_adr104_mkt_reproducibility.py`

### Target Artifacts

- `checksums/mkt_ybe_residuals_v1.json`
- `checksums/mkt_markov_restricted_invariance_v1.json`
- `checksums/mkt_constants_cutoff_sweep_v1.json`
- `checksums/mkt_commitment_collision_campaign_v1.json`
- `checksums/mkt_release_readiness_v1.json`

---

## Phase Plan

## Phase 0: Baseline and Interface Freeze (Week 1)

### Deliverables

1. Freeze MKT v3 API contracts (inputs, outputs, tolerance semantics).
2. Introduce typed dataclasses for braid words, prime assignments, and gate artifacts.
3. Add deterministic serialization standard (canonical whitespace/order/hash format).

### Implementation Tasks

- Define `BraidWord`, `PrimeAssignment`, `InvariantResult`, `GateArtifact` dataclasses.
- Define numeric tolerance policy:
  - `EPS_NUMERIC = 1e-10` for algebraic checks.
  - `EPS_EMPIRICAL = 1e-3` for finite-X/experimental checks.
- Add JSON schema files in `schema/` for all MKT gate artifacts.

### Acceptance Gate (G0)

- `tests/test_adr104_mkt_reproducibility.py::test_serialization_deterministic` passes.
- `checksums/mkt_release_readiness_v1.json` contains `"phase0": "pass"`.

Rollback: keep current ADR-101/102/103 behavior as canonical path.

---

## Phase 1: Prime-Colored Braid Core + YBE Evidence (Weeks 1-2)

### Deliverables

1. Productionized prime-colored braid representation and strand-local `R_{p,q}`.
2. Projective YBE residual harness over bounded prime triples.
3. Deterministic canonical prime assignment strategy.

### Implementation Tasks

- Extract and harden `O_p`, `R_std`, `R_pq`, generator embedding into `mkt_colored_braid.py`.
- Add bounded YBE campaign:
  - Prime set default: `{2, 3, 5, 7, 11, 13}`.
  - Compute residual norms for `(p,q,r)` triples.
- Persist campaign output to `checksums/mkt_ybe_residuals_v1.json`.

### Acceptance Gate (G1)

- Max residual over campaign <= `1e-8` (configurable).
- No nondeterministic diff across 3 repeated runs.
- 100% pass on `test_adr104_mkt_colored_braid.py`.

### Current Gate 1 Status (2026-04-01)

- ✅ Determinism check implemented and passing in harness.
- ✅ Variant-comparison harness implemented (`identity`, `conjugated`, `constrained_normalized`, `pair_phase_scaled`, `shared_axis`, `log_avg_conjugated`, `axis_blend_transport`, `commutator_regularized`, `spectral_polar_transport`, `left_transport`, `right_transport`).
- ✅ Tests passing for Gate 1 suite.
- ❌ Residual threshold not met on bounded prime set `{2,3,5,7,11,13}`.
- ✅ Non-blocking Phase 2 prep scaffold added (corpus loader + prep artifact writer + tests), explicitly marked as preparation-only and not gate advancement.
- ✅ Phase 2 prep corpus expanded to 13 synthetic restricted-move cases to harden data scaffolding before gate unlock.
- ✅ CI job added for prep artifact generation only: `MKT Phase 2 Prep (Non-Blocking Artifact)` (`continue-on-error: true`).
- ✅ Phase 3 non-blocking prep lane activated: constants sweep runner + diagnostics/uncertainty metadata + CI artifact lane (`MKT Phase 3 Constants (Non-Blocking Artifact)`).

Recorded evidence:
- `checksums/mkt_ybe_residuals_v1.json`
- `checksums/mkt_ybe_variant_comparison_v1.json`
- `checksums/mkt_markov_restricted_invariance_v1.json` (Phase 2 prep-only artifact)

Observed best variant at this checkpoint:
- `best_variant = identity`
- `best_max_projective_residual = 3.6275324272664644`
- `status = fail`, `support_level = research_only`

Decision rule:
- Continue Phase 1 until G1 passes, or approve an explicit waiver to begin Phase 2 in parallel for non-blocking work only.

Falsification action:
- If residual gate fails, mark YBE as unsupported for production and downgrade to research-only mode in metadata.

---

## Phase 2: Restricted Markov Invariance + Invariant Pipeline (Weeks 2-4)

### Deliverables

1. Restricted-move invariance checker under canonicalization rules.
2. Stable `Z(K)` and finite-X `P(K;X)` computation pipeline.
3. Drift and sensitivity diagnostics over perturbations.

### Implementation Tasks

- Implement canonical move set (conjugation/stabilization subset) with explicit constraints.
- Build `mkt_invariant.py`:
  - `z_of_braid(...)`
  - `p_of_braid_x(..., X)`
  - `invariance_report(...)`
- Add perturbation tests: tiny floating-point noise, generator reorder sanity checks.
- Emit `checksums/mkt_markov_restricted_invariance_v1.json`.

### Acceptance Gate (G2)

- Invariance mismatch rate <= 0.5% over campaign corpus.
- `|delta Z|` and `|delta P|` below configured empirical tolerance for sanctioned transforms.
- Test suite pass on `test_adr104_mkt_invariant.py` and reproducibility tests.

Falsification action:
- If invariance does not hold, enforce "restricted-invariance-only" label and block cryptographic binding claims.

---

## Phase 3: Constants Estimation and Convergence Evidence (Weeks 4-5)

### Deliverables

1. Finite-X estimators for `c0(X)` and `z(X)` with uncertainty bands.
2. Reproducible sweep from `X=10^2` to at least `X=10^5` (resource aware).
3. Convergence report with explicit "conjectural" status markers.

### Implementation Tasks

- Build `mkt_constants_estimation.py` with streaming prime generation and checkpointing.
- Add confidence diagnostics:
  - windowed slope of estimator trajectory,
  - variance over multiple numeric backends where available.
- Emit `checksums/mkt_constants_cutoff_sweep_v1.json` with:
  - estimates,
  - confidence intervals,
  - convergence diagnostics,
  - status field (`conjectural_confirmed` or `not_confirmed`).

### Acceptance Gate (G3)

- Sweep completes within CI budget profile and offline full profile.
- Artifact schema validation passes.
- Any claim of `c0 = ln(10)` or `z = 1/(2 cos 1)` must include confidence metadata.

Falsification action:
- If convergence is weak, freeze constants as finite-X operational parameters only.

---

## Phase 4: MBC Prototype Hardening (Weeks 5-6)

### Deliverables

1. End-to-end MBC implementation (`Setup`, `Commit`, `Open`) with deterministic encoding.
2. Collision and double-open campaign harness.
3. Security posture document mapping assumptions to measured evidence.

### Implementation Tasks

- Implement `mkt_commitment.py` with strict validation and canonical serialization.
- Add campaign runner for:
  - random-message collision search,
  - perturbation/stability checks,
  - adversarial malformed openings.
- Emit `checksums/mkt_commitment_collision_campaign_v1.json`.

### Acceptance Gate (G4)

- Zero successful double-open events in configured baseline campaign.
- Malformed opening rejection >= 99.9% in harness.
- Test suite pass on `test_adr104_mkt_commitment.py`.

Falsification action:
- If collisions/double-open rates exceed threshold, label MBC as non-binding experimental primitive.

---

## Phase 5: CI, Packaging, and Operational Readiness (Weeks 6-8)

### Deliverables

1. CI matrix with base and async pytest profiles.
2. Performance budget and regression guards.
3. Deployment and runbook docs for reproducible campaign execution.

### Implementation Tasks

- Add CI jobs:
  - `mkt-base`: deterministic unit/integration checks.
  - `mkt-async`: optional async profile using `pytest.async.ini`.
  - `mkt-campaign-smoke`: short artifact generation campaign.
- Add performance thresholds for YBE and invariance campaigns.
- Add release checklist section in MKT docs.

### Acceptance Gate (G5)

- All MKT jobs green on mainline.
- Artifacts generated and uploaded as CI artifacts.
- `checksums/mkt_release_readiness_v1.json` has all phases `pass` or explicit waivers approved.

Rollback:
- Automatic feature flag downgrade to research-only mode when G2/G4 fail.

---

## Dependency and Critical Path

```text
Phase 0
  -> Phase 1 (core algebra)
  -> Phase 2 (invariance)
  -> Phase 3 (constants evidence)
  -> Phase 4 (MBC hardening)
  -> Phase 5 (CI/release)
```

Critical path: Phase 1 -> Phase 2 -> Phase 4.

Reason: cryptographic binding claims are invalid until restricted invariance is operationally demonstrated.

---

## Governance Rules

1. No "production" label for MBC until G4 passes.
2. No theorem-level language for `c0`, `z`, or global invariance without corresponding gate evidence.
3. Every release candidate must include all `checksums/mkt_*_v1.json` artifacts.
4. Any failed gate must emit explicit downgrade metadata in release notes.

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| YBE residuals unstable across primes | Medium | High | Bound prime domain for production; keep extended domain experimental |
| Restricted invariance not robust | High | High | Enforce canonicalization constraints and explicit unsupported-move list |
| Constants do not converge cleanly | Medium | Medium | Operate with finite-X parameters and confidence intervals |
| MBC collision rates non-negligible | Medium | High | Keep MBC experimental; require stronger encoding and/or external commitments |
| CI runtime blowup for campaigns | Medium | Medium | Split smoke vs full campaigns; use nightly full sweeps |

---

## Definition of Done

MKT v3 is "production-grade experimental" when:

- G0-G5 all pass, or explicit waivers are approved and documented.
- All new modules/tests exist and are passing in CI.
- Artifacts are reproducible and schema-valid.
- Security and mathematical claims in docs match observed evidence level.

---

## Immediate Next Actions (Execution Order)

1. Create Phase 0 dataclasses and schemas.
2. Extract braid core into `mkt_colored_braid.py` and add G1 campaign.
3. Build invariance campaign and gate artifact pipeline.
4. Implement constants sweep runner + convergence report.
5. Wire MBC harness and CI jobs.
