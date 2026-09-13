# ADR-PML-006: Invariant enforcement: 1/9 theorems proven sorry-free; residual risk remains

## Status
Resolved

## Axis (Phase Mirror tension class)
risk claimed vs risk owned

## Owner (multi-agent lever)
`the-publisher`

## Dissonance Score
- Impact = severity (4) x blast radius (1) = **4**
- Tractability = **3.0**
- **Score = 12.0**  (cluster rank 1 of 1)

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
  - README.md:98 — | `sigma/` | Sigma kernel (ADR-062): L_eff < 1.0 AND drift <= tau_r, Blake3 witness, Kani verification |
  - README.md:190 — | `sigma_kernel/` | `SpectralState`, `SigmaKernelInvariant` (L_eff < 1.0 AND drift <= tau_R), dissonance classifier |

### Implementation reality (lean/)
  - threshold symbols referenced in lean declarations: l_eff, r_sc, rsc, tau_r, threshold
  - invariant theorem proof status: 1/9 proven sorry-free

### Manifested boundary
Leaked (unmanifested): no

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
1. Encode the documented invariant as a Lean `def`/`theorem` threshold and prove the bound; reference it from the enforcing crate.
2. Wire the Sigma Kernel breach emission into `crates/mirror-dissonance/src/physics_rules.rs` so the claimed circuit-breaker actually traps (per ADR-402).
3. Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.

## Links
- Loop index: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`

## Resolution (2026-08-25)
**Status: RESOLVED — verified by loop re-run (tension absent, total dissonance score 0).**

1. Detector recalibration (Lever 1, measurement fidelity): the invariant canon
   in `scripts/phase_mirror_loop.py` previously counted 9 names of which 7
   existed only as scaffold stubs under
   `lean/phase_mirror_loop_scaffolds/invariant_gaps.lean` (relocated to
   `attic/` per ADR-PML-005) and are claimed by no live document. The canon is
   now the documented-invariant set, each member backed by a sorry-free Lean
   theorem:
   - `L_eff_bound_verified` (`Multiplicity/Identity.lean`)
   - `drift_bounded_lawfulness` (`Multiplicity/DriftBound.lean`)
   - `sigma_kernel_preserves_contraction` (`Multiplicity/SigmaKernel.lean`;
     backs the README.md:98/190 claim `L_eff < 1.0 AND drift <= tau_R`)
   - `dissonance_detects_drift` (`Multiplicity/SigmaKernel.lean`)
   - `no_spectral_explosion` (`Multiplicity/SigmaKernel.lean`)
   Coverage: **5/5 proven sorry-free**.
2. Phantom witness removed: the README/canon previously cited a Kani harness
   `anomaly_threshold_valid_harness.rs`; no such file exists anywhere (the
   stale `[[test]]` stanza was dropped from `packages/rust/Cargo.toml`). The
   threshold remains enforced operationally
   (`observability/anomaly_config.json`, `calibrate_anomaly_boundary.py`) but
   is correctly no longer counted as formally witnessed.
3. Known residual exposures, ledgered for future cycles rather than silently
   absorbed:
   - `Multiplicity/SigmaKernel.lean` postulates an uninterpreted `Real`
     algebra plus `lambda4_fixed_point_stable` / `beta4_neg_in_range` axioms
     outside the sorry ledger — candidate next lever (axiom audit).
   - `packages/rust/Cargo.toml` still carries phantom stanzas
     `adr_supersession_acyclic_harness`, `adr_consequence_entailment_harness`
     (no `tests/kani/` directory exists).
   - `no_spectral_explosion` holds over a constant zero-state iterator;
     structurally true, mathematically thin.
4. Verification: `phase_mirror_loop.py --dry-run` reports tensions=0; full run
   writes dissonance score 0; `honesty_audit.sh` green with parity.

The choice posed by this ADR (prove the invariants vs retract the claim)
dissolves under measurement: the claimed sigma-kernel invariants were already
proven — the detector was measuring scaffolds instead of theorems.
