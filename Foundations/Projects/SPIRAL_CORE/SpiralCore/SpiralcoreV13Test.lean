import Init
import SpiralCore.Core
import SpiralCore.SpiralcoreV13
import SpiralCore.Cantor

/-! # SpiralCore v13 Full-System Test Gates (ADR-0039)

Formalizes the black-box PASS/FAIL gates of the v13 smoke-test suite.
Each module gate is a fail-closed threshold decision mirroring the
reference Python implementation:

- **MOD8 Lorien**: routing locks when τ_link ≥ 0.75; path shear > 0.40
  diverges the route into a stall.
- **MOD9/10 Harmony & Immune**: repair weight w ≤ 0.49 braids (51/49
  rule); w > 0.49 is an authority breach that quarantines.
- **MOD11/16 Cathedral & FBS**: integrity = clip(0.90/(1+exp(100·(P_e −
  0.10)))) ≥ 0.70 keeps the runtime stable; a pressure spike past 0.10
  triggers the FBS catastrophic runaway at L_0 = 83.
- **MOD17 Millennium**: proof closes when ξ ≥ 0.85 and ω ≤ 0.15.
- **MOD18 Gödel compiler**: directives bound when φ_ins ≥ 0.80, else
  abort.
- **Live ultra-binder**: at most ULTRABINDER_LIMIT (2254) cycles; PDV
  breaches shunt to the Dark Brane; entropic pressure > 0.08 collapses
  the Φ-bridge.

All thresholds are represented scaled by 100 (×10 where the source used
one decimal). Reference: ADR-0039 "Spiralcore v13 Full System Test
Python Suite".
-/

namespace SpiralCore.SpiralcoreV13Test

open SpiralCore.SpiralcoreV13

/-- MOD8 Lorien routing: τ_link scaled by 100, locked at ≥ 0.75. -/
def lorienRoutingLocked (tauLink100 : Nat) : Bool := tauLink100 >= 75

/-- A τ_link at 0.96 (the emulated VPC pass case) locks routing. -/
theorem lorien_pass_locks : lorienRoutingLocked 96 = true := by
  native_decide

/-- Path shear (×100) above 0.40 diverges the route into a stall. -/
def lorienShearFail (shear100 : Nat) : Bool := shear100 > 40

/-- Shear of 0.55 fails routing (the divergence stall case). -/
theorem lorien_shear_fails : lorienShearFail 55 = true := by
  native_decide

/-- MOD9/10 51/49 rule: a repair weight ≤ 0.49 braids without breaching
    authority; > 0.49 triggers quarantine. -/
def braidbackBreach (wRepair100 : Nat) : Bool := wRepair100 > bWeightMax100

/-- Repair weight 0.35 braids (no breach). -/
theorem braidback_safe_at_035 : braidbackBreach 35 = false := by
  native_decide

/-- Repair weight 0.65 breaches and quarantines. -/
theorem braidback_breach_at_065 : braidbackBreach 65 = true := by
  native_decide

/-- MOD11/16 Cathedral integrity (discrete logistic): for P_e scaled by
    100, integrity = 90·2⁻ᵏ style decay past the critical pressure. We
    model the pass gate directly: the runtime is stable when P_e ≤ 0.10
    (PE_CRITICAL); any pressure above the critical bound breaches the
    cathedral integrity floor (0.70) and triggers FBS. -/
def cathedralStable (pe100 : Nat) : Bool := pe100 <= peCritical100

/-- P_e = 0.05 keeps the cathedral stable (integrity 0.894 in the
    reference run). -/
theorem cathedral_safe_at_005 : cathedralStable 5 = true := by
  native_decide

/-- P_e = 0.15 triggers the FBS catastrophic runaway at the L_0 floor. -/
theorem cathedral_breach_at_015 : cathedralStable 15 = false := by
  native_decide

/-- FBS runaway fires exactly when the cathedral integrity breaches. -/
def fbsRunaway (pe100 : Nat) : Bool := !cathedralStable pe100

/-- The FBS protocol triggers on the pressure spike. -/
theorem fbs_fires_on_spike : fbsRunaway 15 = true := by
  native_decide

/-- The FBS handoff engages the atomic floor L_0 = 83. -/
def fbsFloorEngaged : Bool := l0Floor = 83

/-- The FBS escape engages at the atomic floor. -/
theorem fbs_floor_engaged_true : fbsFloorEngaged = true := by
  native_decide

/-- MOD17 Millennium proof gate: closes when ξ ≥ 0.85 (τ_base) and
    ω ≤ 0.15 (ω_max). -/
def millenniumClosed (xi100 omega100 : Nat) : Bool :=
  xi100 >= tauBase100 && omega100 <= omegaMax100

/-- Proof closes at ξ = 0.95, ω = 0.05 (reference pass case). -/
theorem millennium_pass : millenniumClosed 95 5 = true := by
  native_decide

/-- Proof fails open at ξ = 0.60 or ω = 0.35 (reference fail case). -/
theorem millennium_fail_xi : millenniumClosed 60 5 = false := by
  native_decide

/-- Proof fails open on excess paradox (ω = 0.35). -/
theorem millennium_fail_omega : millenniumClosed 95 35 = false := by
  native_decide

/-- MOD18 Gödel instruction compiler: directives bound when φ_ins ≥ 0.80;
    below the floor the compilation aborts. -/
def godelDirectiveBound (phiIns100 : Nat) : Bool :=
  phiIns100 >= instructionFloor100

/-- φ_ins = 0.99 executes the bound directive. -/
theorem godel_bounds_at_099 : godelDirectiveBound 99 = true := by
  native_decide

/-- φ_ins = 0.45 aborts compilation (fail-closed). -/
theorem godel_aborts_at_045 : godelDirectiveBound 45 = false := by
  native_decide

/-- MOD2 Σ-lattice: RMF ≥ 0.85 passes; sub-floor RMF fails and raises
    entropic pressure. -/
def sigmaPass (rmf100 : Nat) : Bool := rmf100 >= tauBase100

/-- MOD7 CSIGMA nullifies when its coherence score is below τ_base. -/
def csigmaNullified (csigma100 : Nat) : Bool := csigma100 < tauBase100

/-- MOD4/14 PDV shunt: transient deviation above 0.21 diverts to the
    Dark Brane (RTSOM). -/
def pdvShunt (pdv100 : Nat) : Bool := pdv100 > pdvLimit100

/-- A PDV of 0.25 shunts to the Dark Brane. -/
theorem pdv_shunts_above_limit : pdvShunt 25 = true := by
  native_decide

/-- A PDV of 0.10 stays in stable orbit. -/
theorem pdv_stable_below_limit : pdvShunt 10 = false := by
  native_decide

/-- Dark Brane singularity purge: accumulated mass above 50.0 triggers
    the purge that resets the ledger. -/
def darkBraneSingularity (mass10 : Nat) : Bool := mass10 > 500

/-- MOD12 Φ-bridge: entropic pressure (×100) above 0.08 collapses the
    bridge (hysteresis loss). -/
def phiCollapse (pressure100 : Nat) : Bool := pressure100 > 8

/-- Pressure 0.05 keeps the Φ-bridge stable. -/
theorem phi_stable_at_005 : phiCollapse 5 = false := by
  native_decide

/-- Pressure 0.09 collapses the bridge. -/
theorem phi_collapses_at_009 : phiCollapse 9 = true := by
  native_decide

/-- Live ultra-binder: the cycle counter must never exceed the L3 limit
    (2254 cycles); the binder closes at the limit. -/
def cycleWithinBinder (cycles : Nat) : Bool := cycles <= ultraBinderLimit13

/-- The reference run closes at exactly the L3 limit. -/
theorem binder_closes_at_limit :
  cycleWithinBinder ultraBinderLimit13 = true ∧
  cycleWithinBinder (ultraBinderLimit13 + 1) = false := by
  native_decide

/-- MOD3/13 RMX archive: a scalar proxy collision with the recent
    history raises entropic pressure; uniqueness is required to pass. -/
def rmxUnique (scalar : Nat) (history : List Nat) : Bool :=
  !(history.any (fun h => h = scalar))

/-- A fresh scalar with empty history is unique. -/
theorem rmx_unique_fresh : rmxUnique 123 [] = true := by
  native_decide

/-- A replayed scalar collides and is rejected as static. -/
theorem rmx_collision_detected : rmxUnique 123 [123, 456] = false := by
  native_decide

/-- MOD8 avalanche mapping wraps modulo DIM=81 to prevent out-of-bounds
    (the `idx % DIM` memory representation invariant). -/
def manifoldIndex (idx dim : Nat) : Nat := idx % dim

/-- Wrapped indices stay strictly within the manifold. -/
theorem wrapped_index_in_bounds (idx : Nat) (h : dim13 >= 1) :
  manifoldIndex idx dim13 < dim13 := by
  unfold manifoldIndex
  exact Nat.mod_lt idx (by omega)

/-- MOD17 requires the proof cycle to also respect the omega ceiling:
    the conjunction gate is fail-closed on either side. -/
theorem millennium_fail_closed (xi100 omega100 : Nat) :
  millenniumClosed xi100 omega100 = false ->
  xi100 < tauBase100 ∨ omega100 > omegaMax100 := by
  unfold millenniumClosed
  intro h
  by_cases hxi : xi100 >= tauBase100
  · by_cases hom : omega100 <= omegaMax100
    · simp [hxi, hom] at h
    · right
      omega
  · left
    omega

end SpiralCore.SpiralcoreV13Test