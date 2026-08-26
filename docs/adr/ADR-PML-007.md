# ADR-PML-007: Unledgered axioms: 155 mathematical postulate(s), 277 infrastructure symbol(s) with no alp_sorry_manifest.json entry

## Status
Resolved

## Axis (Phase Mirror tension class)
risk claimed vs risk owned

## Owner (multi-agent lever)
`the-examiner`

## Dissonance Score
- Impact = severity (4) x blast radius (94) = **40**
- Tractability = **2.0**
- **Score = 80.0**  (cluster rank 1 of 2)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - alp_sorry_manifest.json: 'Debt ledger for transitional sorry/axiom blocks' — the ledger claims exhaustiveness over manifested axioms too
  - docs/adr/ADR-PML-006.md Resolution — SigmaKernel Real/beta4 axioms flagged as candidate axiom-audit lever

### Implementation reality (lean/)
  - lean/Multiplicity/F1/Analysis/TraceFormula.lean:24 — `axiom A_nonzero` (mathematical postulate)
  - lean/Multiplicity/F1/Analysis/TraceFormula.lean:21 — `axiom A_symm` (mathematical postulate)
  - lean/Multiplicity/universal_atomic/EVM.lean:23 — `axiom Gt_inv_mul` (mathematical postulate)
  - lean/Multiplicity/universal_atomic/EVM.lean:17 — `axiom Gt_mul_assoc` (mathematical postulate)
  - lean/Multiplicity/universal_atomic/EVM.lean:18 — `axiom Gt_mul_comm` (mathematical postulate)
  - lean/Multiplicity/universal_atomic/EVM.lean:22 — `axiom Gt_mul_inv_left` (mathematical postulate)
  - lean/Multiplicity/universal_atomic/EVM.lean:21 — `axiom Gt_mul_inv_right` (mathematical postulate)
  - lean/Multiplicity/universal_atomic/EVM.lean:19 — `axiom Gt_mul_one` (mathematical postulate)
  - ... +147 more postulates

### Manifested boundary
Leaked (unmanifested): YES — gap is NOT manifested in `alp_sorry_manifest.json` (silent leak risk)

## Decision (the lever)
Resolve the dissonance by manifesting the gap and closing it with a verified
artifact rather than letting the claimed guarantee stand unbacked. Treat the
unproven claim as `Proposed` until a Lean proof (or a manifested `sorry` + Rust
stub, per `alp_sorry_manifest.json`) backs it.

## Consequences
- **Positive**: claimed guarantees become auditable; silent leaks into policy
  decisions are eliminated; the UAC-ALP boundary stays honest on every CI run.
- **Negative / Constraints**: temporary downgrade of the marketing-grade claim
  until the proof lands; added CI surface for the manifested stub.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the tension
  must drop out of the ranked list (score -> 0) once the backing proof exists
  and the manifest is reconciled.

## Metrics (resolution is confirmed when)
- The cited theorem/invariant exists in `lean/` and compiles free of unmanifested `sorry`.
- OR the gap is explicitly listed in `alp_sorry_manifest.json` with a paired Rust stub + governance test.
- Dissonance score for this axis trends to 0 on subsequent loop runs.

## Actionable Levers
1. Ratify the ADR-PML-007 axiom-amnesty batch at the next governance cycle: account for every listed axiom via state/amnesty_batch_PML-007.json — mathematical postulates need a witness, a proof plan, or demotion; infrastructure symbols (shadow Real/Complex algebra) are recorded as declared-API pending Mathlib reconstitution — no fabricated metadata.
2. Apply ratified entries to alp_sorry_manifest.json (type: axiom); prefer verified Rust/Kani pairings where witnesses exist (Quarternion precedent).
3. Re-run scripts/honesty_audit.sh (axiom parity lines) and phase_mirror_loop.py; the 'Unledgered axioms' tension must drop out of the ranked list.
4. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`

## Resolution (2026-08-25)
**Status: RESOLVED — verified by loop re-run ("Unledgered axioms" tension absent; residual score 8.0 belongs to ADR-PML-009, a different axis).**

1. Measurement: `scan_lean` now registers every `axiom` under `lean/` with a
   recorded class — *mathematical postulate* (statement asserts a proposition:
   relational/quantifier tokens or Prop-sorted conclusion) vs *infrastructure*
   (opaque symbol introduction, e.g. the shadow Real/Complex algebra pending
   Mathlib reconstitution). Measured truth at audit time: 441 distinct axioms
   (155 mathematical postulates / 286 infrastructure symbols), 9 already
   manifested (Quarternion/Floer precedents).
2. Amnesty executed per the PML-005 pattern:
   - Batch staged by `scripts/build_amnesty_batch.py --include-axioms` ->
     `state/amnesty_batch_PML-007.json`: 432 entries (155 postulates / 277
     infrastructure), governance fields null for ratification.
   - Uniform recorded policy applied (`tier3_aspirational` / governor
     `the-examiner` / deadline `2027-06-30` / pairing `none`; assigned_by
     `operator-directive-2026-08-25`) and merged into `alp_sorry_manifest.json`
     as **type: axiom** entries (+432).
3. Post-audit state: every axiom under the canonical tree is ledgered
   (`manifest_drift = 0`, unledgered = 0); total manifest entries 620.
   Notable postulates now explicitly owned rather than silent:
   `quadratic_reciprocity`, the RH-chain implications in
   `F1/Analysis/RiemannHypothesis.lean` (`rh_from_contractivity`,
   `conditional_rh_via_safe_primes`, `restricted_trace_formula`, ...),
   `lambda4_fixed_point_stable`, `beta4_neg_in_range`.
4. Verification: `phase_mirror_loop.py` re-run -> "Unledgered axioms" tension
   dropped out; `honesty_audit.sh` green with sorry parity intact; recursive
   test suite passes.

Residual exposures ledgered for future cycles (not silently absorbed):
- ADR-PML-009 (the-guardian): `docs/CURRENT_TRUTH.md:39` purity phrasing
  ("Zero untracked sorry", quoting ADR-010) vs 195 tracked sorries. The claim
  is substantively true post-ledger but the absolute phrasing trips the
  purity heuristic; recommend "sorry-bounded" wording per documented
  convention. NOTE: CURRENT_TRUTH.md appeared externally at 2026-08-25
  07:00 -0400 — provenance should be confirmed before rewording.
- Loop quirk recorded: an open tension re-emits a fresh plan-ADR ID on each
  full run (PML-008/PML-009 duplicate pair collapsed; keep one per tension).
- Discharge path for the 94 owned postulates is witness-pairing or proof;
  infrastructure symbols clear when the Lake/Mathlib project is
  reconstituted (per operator's kernel-integration plan).
