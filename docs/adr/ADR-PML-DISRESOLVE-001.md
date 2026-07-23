# ADR-PML-DISRESOLVE-001: Resolve Ghost Theorems and Unproven Invariants

## Status
Proposed

## Date
2026-07-22

## Owners
- `the-examiner` (ghost theorem elimination)
- `the-publisher` (invariant risk ownership)
- `the-guardian` (verification gatekeeping)

## Addresses
- ADR-PML-056: Ghost theorems — 47 documented Lean theorems with no implementation (score 124)
- ADR-PML-057: Unproven invariants — 11 physical/mathematical invariants asserted but risk not owned (score 120)
- Combined dissonance: **308 points** (58% of total 532)

---

## Executive Summary

47 theorems are claimed as "verified" in completed ADRs but have no declaration in `lean/`.
11 physical/mathematical invariants are documented as "guaranteed" but lack Lean proofs or
have only vacuous/trivial proofs. Together these two tensions account for 308 of 532
dissonance points. This ADR provides a phased resolution plan that eliminates the gaps
through proof, manifestation, or honest reclassification.

---

## 1. Taxonomy of Gaps

### 1.1 Ghost Theorem Classification

| Class | Count | Definition | Resolution Strategy |
|-------|-------|------------|-------------------|
| **A: Definitional** | 12 | Theorem is really a `def` or data record; ADR overclaimed | Instantiate as `def`/`structure` in `lean/Core/` |
| **B: Tactic-provable** | 11 | Proof exists in ADR notes but was never transferred to Lean | Transfer proof to Lean; close `sorry` |
| **C: Lemma-dependent** | 13 | Requires new lemmas before the main proof can proceed | Scaffold with `sorry` + manifest; prove lemmas first |
| **D: Research-level** | 5 | Open mathematical problems or conjectures | Mark as `sorry` + manifest; reclassify ADR status to `Proposed` |
| **E: Unnamed gaps** | 6 | Referenced by count in ADRs, not individually named | Discover via `lake build` errors; classify per A–D |

### 1.2 Invariant Classification

| Class | Invariants | Definition | Resolution Strategy |
|-------|-----------|------------|-------------------|
| **α: Vacuous proof** | I-1, I-2 | Lean theorem exists but only covers trivial zero-state | Strengthen to cover actual PIRTM transitions |
| **β: Runtime-only** | I-3, I-8 | Enforced by Rust `if` checks, no Lean formalization | Lift to Lean `def` + `decide` or `sorry` manifest |
| **γ: Scaffold stub** | I-5, I-6, I-10 | `True.intro` or no Lean code at all | Scaffold with `sorry` + manifest; prove or reclassify |
| **δ: Partial proof** | I-4, I-7, I-9, I-11 | Individual operator theorems exist; universal claim unproven | Prove universal quantification or narrow the claim |

---

## 2. Phased Resolution Plan

### Phase 1: Manifest All Gaps (Tractability: High | Effort: 1 day)

**Goal**: Every gap is either (a) in `alp_sorry_manifest.json` or (b) has a Lean
declaration. No silent leaks.

**Actions**:
1. Scaffold all 47 ghost theorems as `sorry`-bearing declarations in
   `lean/Core/phase_mirror_loop_scaffolds/` with the theorem signature from the
   source ADR.
2. Register all 47 in `alp_sorry_manifest.json`.
3. Scaffold all 11 invariant gaps (I-1 through I-11) as `sorry`-bearing declarations
   in `lean/Core/phase_mirror_loop_scaffolds/` if not already present.
4. Register all 11 in `alp_sorry_manifest.json`.
5. Downgrade ADR-115, ADR-090, ADR-068, ADR-061, ADR-075, ADR-077 from
   `Completed` to `Proposed` or `Partially Implemented` to reflect actual state.

**Exit criteria**: `scripts/phase_mirror_loop.py` reports 0 LEAK tensions for
these clusters. `alp_sorry_manifest.json` contains all gaps.

### Phase 2: Close Definitional Gaps (Tractability: High | Effort: 1 week)

**Goal**: Resolve all Class-A ghost theorems (12 trivial definitional gaps).

**Targets** (in priority order):

| # | Theorem | Location | Proof |
|---|---------|----------|-------|
| 1 | `E_τ_star` | `lean/Core/phase_mirror_loop_scaffolds/` | `def E_τ_star (T : ℝ) : ℝ := E_τ T τ_star` |
| 2 | `N` | same | `def N (T : ℝ) : ℝ := Real.exp (A_param * Real.log T)` |
| 3 | `T_crit` | same | `def T_crit : ℝ := Real.exp ((K₀ / η + 0.25) / A)` |
| 4 | `ADR_001_Riemann` | same | `structure ADR_001_Riemann where ...` |
| 5 | `SedonaSpineADR` | same | `def SedonaSpineADR : ADR := { ... }` |
| 6 | `SystemState_Phase1` | same | `def SystemState_Phase1 : SystemState := { ... }` |
| 7 | `ContextEntailsConsequence` | same | `def ContextEntailsConsequence (ctx dec cons : String) : Prop := ...` |
| 8 | `ValidADREntailment` | same | `def ValidADREntailment (adr : ADR) : Prop := ...` |
| 9 | `ZmosSupersedes` | same | `theorem ZmosSupersedes ... := by cases h <;> contradiction` |
| 10 | `Init` | `lean/Core/` | Module declaration, not a theorem — reclassify |
| 11 | `inner_sym` | same | `theorem inner_sym {α} [InnerProductSpace α] (x y : α) : ⟪x, y⟫ = ⟪y, x⟫ := by ...` |
| 12 | `FittingCheck` | same | `def FittingCheck (update : PIRTMUpdate) : Bool := ...` |

**Exit criteria**: 12 fewer ghost theorems. Score decreases by 48.

### Phase 3: Close Tactic-Provable Gaps (Tractability: Medium | Effort: 2 weeks)

**Goal**: Resolve all Class-B ghost theorems (11 proofs that exist in ADR notes
but were never transferred).

**Targets**:

| # | Theorem | Source ADR | Strategy |
|---|---------|-----------|----------|
| 1 | `resonance_preserves_contraction` | ADR-068 | `linarith` on `spectral_radius * 0.99` — source shows proof |
| 2 | `DilithiumVerifySound` | ADR-PML-051 | Kani bounded model check on lattice crypto |
| 3 | `JensenShannonMetric` | ADR-075 | Define KL divergence + JS metric; standard info theory |
| 4 | `RtaMetric` | ADR_041 | Distance computation on viability kernel |
| 5 | `BanachFixedPoint` | BasicTheorems.lean | Replace sorry with `Nat.strongRecOn` or manifest |
| 6 | `CauchySchwarzDiscrete` | BasicTheorems.lean | Sum-of-squares inequality for `Fin n → Nat` |
| 7 | `YoungInequality` | BasicTheorems.lean | Manifest pending Real number infrastructure |
| 8 | `HoldersInequality` | BasicTheorems.lean | Manifest pending Real number infrastructure |
| 9 | `MinkowskiInequality` | BasicTheorems.lean | Manifest pending Real number infrastructure |
| 10 | `LasalleInvariance` | StabilityTheorems.lean | Well-foundedness argument |
| 11 | `LyapunovNegativeImpliesStable` | StabilityTheorems.lean | Real number analysis |

**Exit criteria**: 11 fewer ghost theorems. Score decreases by 44.

### Phase 4: Strengthen Invariant Proofs (Tractability: Medium | Effort: 3 weeks)

**Goal**: Move invariants from class α/β/γ/δ to fully proven.

**Priority order by blast radius**:

#### 4a. SigmaKernel invariant (I-1, I-2) — 3 days

Current state: `sigma_kernel_preserves_contraction` proves invariant preservation
for `iteratePirtm` which always returns zero. This is vacuous.

Action:
- Generalize `iteratePirtm` to accept an arbitrary `PIRTMTransition` parameter
- Prove `SigmaKernelInvariant` preservation under the generalized transition
- Add Kani harness that exercises non-trivial transitions
- Wire breach emission into `crates/mirror-dissonance/src/physics_rules.rs`

#### 4b. Universal operator contractivity (I-4) — 1 week

Current state: Individual operator theorems exist (`sin_is_contractive`,
`log_is_contractive_on_domain`, etc.). The universal claim "every operator" has
only a `True.intro` scaffold.

Action:
- Prove `operator_contractive` for each operator in the operator catalog
- Prove the universal quantifier by exhaustive case analysis on the finite
  operator set (or manifest the gap if the set is open-ended)

#### 4c. ANOMALY_GOV_THRESHOLD (I-3) — 1 day

Current state: Build-time Rust env var (`0.0006`), no Lean formalization.

Action:
- Add `def ANOMALY_GOV_THRESHOLD : ℝ := 0.0006` to `lean/Core/`
- Prove `theorem anomaly_threshold_valid : ANOMALY_GOV_THRESHOLD < 0.85 := by decide`
- Reference from Rust build script

#### 4d. H(ρ) entropy bound (I-5) — 1 week

Current state: Documentation-only claim. No code.

Action:
- Define entropy functional in Lean
- Prove bound for the finite-state case
- Manifest the infinite-state case as `sorry`

#### 4e. Matrix Engine contraction (I-7) — 2 days

Current state: `matrix_engine_preserves_contraction` exists but status unverified.

Action:
- Audit the existing proof body
- If sorry-bearing, fix or manifest
- Add Kani harness for the Rust engine path

#### 4f. ContractionCertificate pipeline (I-9) — 2 days

Current state: Lean theorem exists; end-to-end pipeline to Archivum unverified.

Action:
- Add end-to-end governance test: `guardian → examiner → publisher → archivum`
- Assert certificate cannot be bypassed
- Wire into CI

#### 4g. Remaining invariants (I-6, I-8, I-10, I-11) — 3 days

Action: Scaffold with `sorry` + manifest; prioritize based on blast radius.

**Exit criteria**: All invariants have either (a) a proven Lean theorem covering
actual transitions, or (b) a manifested `sorry` with a paired Rust check and
governance test.

### Phase 5: Close Lemma-Dependent Gaps (Tractability: Low | Effort: 2 months)

**Goal**: Resolve Class-C ghost theorems (13 theorems requiring new lemmas).

**Strategy**: Dependency-graph ordering. Prove foundational lemmas first;
the dependent theorems follow.

Key dependency chains:
1. `compositional_defect` → requires → defect metric formalization
2. `morphism_soundness` → requires → `compositional_defect`
3. `associator` → requires → coequalizer construction
4. `completion_adjunction` → requires → `associator` + `unit`
5. `BinduAttractor` → requires → fixed-point existence + uniqueness
6. `FockTrunc` → requires → functional analysis on Fock space
7. `gue_deviation_bounded` → requires → Tracy-Widom or Dyson Brownian motion
8. `complex_kappa_*` → requires → analytic continuation bounds

**Exit criteria**: Each theorem either proven or has a `sorry` manifest entry
with a dependency graph showing which lemmas must come first.

### Phase 6: Reclassify Research-Level Gaps (Tractability: Low | Effort: Ongoing)

**Goal**: Honest classification of 5 research-level theorems.

| Theorem | Action |
|---------|--------|
| `free_one_generator_is_nno` | Reclassify as conjecture; ADR status → `Proposed` |
| `kramers_kronig` | Manifest `sorry`; note requires complex analysis on spectral functions |
| `ward_identity_implies_bianchi` | Manifest `sorry`; note bridges QFT ↔ differential geometry |
| `complex_kappa_part_i` | Manifest `sorry`; note requires analytic continuation bounds |
| `RH_analytic_proof` | Already correctly marked as axiomatic scaffolding; no change |

**Exit criteria**: All 5 have `sorry` manifest entries. ADRs reclassified from
`Completed` to `Proposed`. Documentation updated to say "conditional on proof
of X".

---

## 3. Governance Mechanics

### 3.1 ADR Status Reclassification

The following ADRs must be reclassified from `Completed` to reflect actual state:

| ADR | Current Status | New Status | Reason |
|-----|---------------|------------|--------|
| ADR-090 (Mathlib Sorry Elimination) | Completed | Partially Implemented | `Init` ghost theorem |
| ADR-115 (UCC Production-Grade) | Completed | Partially Implemented | 6 ghost theorems (`unit`, `associator`, `completion_adjunction`, `free_one_generator_is_nno`, `compositional_defect`, `morphism_soundness`) |
| ADR-068 (MOC/CRMF Contraction Certificate) | Completed | Partially Implemented | `resonance_preserves_contraction` not proven for actual transitions |
| ADR-061 (ZMOS Production) | Completed | Partially Implemented | `ZmosSupersedes` not implemented |
| ADR-075 (ORF Coherence) | Completed | Partially Implemented | `JensenShannonMetric` not implemented |
| ADR-077 (PIRTM Fock-Space) | Completed | Partially Implemented | `FockTrunc` not implemented |

### 3.2 Verification Gate

After each phase:
1. Run `scripts/phase_mirror_loop.py`
2. Confirm tension scores decrease
3. Confirm no new LEAK tensions appear
4. Confirm `alp_sorry_manifest.json` has 0 drift
5. Run `scripts/honesty_audit.sh` — must pass

### 3.3 Agent Responsibilities

| Agent | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 | Phase 6 |
|-------|---------|---------|---------|---------|---------|---------|
| `the-examiner` | Scaffold all | Prove defs | Prove tactics | — | Dependency graph | — |
| `the-publisher` | Manifest all | Reclassify ADRs | Reclassify ADRs | Reclassify ADRs | Reclassify ADRs | Reclassify ADRs |
| `the-guardian` | Audit gate | Verify builds | Verify builds | Verify builds | Verify builds | Verify builds |

---

## 4. Dissonance Score Projection

| Phase | Tensions Resolved | Score Reduction | Projected Score |
|-------|------------------|-----------------|-----------------|
| Current | — | — | 532 |
| Phase 1 | 2 (LEAK) | -8 | 524 |
| Phase 2 | 12 ghost theorems | -48 | 476 |
| Phase 3 | 11 ghost theorems | -44 | 432 |
| Phase 4 | 11 invariants | -120 | 312 |
| Phase 5 | 13 ghost theorems | -52 | 260 |
| Phase 6 | 5 ghost theorems | -20 | 240 |

The residual 240 points come from:
- Purity claims in frozen academic papers (MSP_1.md: ~100 points) — cannot change
- Control surfaces not wired to enforcement (24 points) — separate ADR
- Remaining urgency/capacity gaps (~116 points) — addressed by Phase 5-6

---

## 5. Consequences

### Positive
- All 47 ghost theorems and 11 invariants are owned, not silent
- Dissonance score drops from 532 to ~240 (55% reduction)
- Every claimed guarantee has either a proof, a `sorry` manifest, or an honest
  reclassification
- The honesty audit covers the full gap surface

### Negative / Constraints
- 20 theorems will be explicitly `sorry`-bearing (up from current implicit state)
- 6 ADRs must be downgraded from `Completed` to `Partially Implemented`
- 5 research-level theorems must be reclassified as conjectures
- Marketing claims about "100% verified" must be retired

### Risks
- Phase 4 (invariant strengthening) is the critical path; if SigmaKernel
  generalization proves intractable, the core safety invariant remains vacuously proven
- Phase 5 has external dependencies on mathematical infrastructure (functional
  analysis, analytic number theory) that may require Mathlib — violating the
  Sedona Spine Mandate

---

## 6. Metrics (resolution confirmed when)

- [ ] `alp_sorry_manifest.json` contains all 58 gaps (47 theorems + 11 invariants)
- [ ] `scripts/phase_mirror_loop.py` reports 0 LEAK tensions for these clusters
- [ ] All 12 Class-A theorems exist as compilable Lean declarations
- [ ] All 11 Class-B theorems have proofs or manifested `sorry` blocks
- [ ] SigmaKernel invariant (I-1/I-2) proven for non-trivial transitions
- [ ] ANOMALY_GOV_THRESHOLD (I-3) formalized in Lean
- [ ] 6 ADRs reclassified from `Completed` to `Partially Implemented`
- [ ] Dissonance score for "risk claimed vs risk owned" trends toward 0
- [ ] `scripts/honesty_audit.sh` passes on every run
- [ ] No unmanifested `sorry` blocks anywhere in `lean/`

---

## 7. Links
- Phase Mirror Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Tension ADRs: `docs/adr/ADR-PML-056.md`, `docs/adr/ADR-PML-057.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Honesty audit: `scripts/honesty_audit.sh`
- Loop script: `scripts/phase_mirror_loop.py`
- Dissonance report: `docs/PHASE_MIRROR_DISSONANCE_REPORT_2026-07-22.md`
- Goal: `Phase_Mirror_Loop_Goal.md`
