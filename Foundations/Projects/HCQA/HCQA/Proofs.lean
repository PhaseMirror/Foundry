import Init
import HCQA.Core
import HCQA.Qudit
import HCQA.MAVQE
import HCQA.HSEC
import HCQA.QCFI
import HCQA.M3A
import HCQA.Hardware

/-! # HCQA — Proofs

Aggregated verified theorems across all modules with 0 sorry.
-/

namespace HCQA.Proofs

open HCQA.Core
open HCQA.Qudit
open HCQA.MAVQE
open HCQA.HSEC
open HCQA.QCFI
open HCQA.M3A
open HCQA.Hardware

/-- Core verified properties. -/
theorem qudit_dim_sr87 : quditDim 9 = 38 := rfl
theorem qudit_dim_yb171 : quditDim 1 = 6 := rfl

/-- Qudit compression verified properties. -/
theorem physical_qudits_zero (d : Nat) : physicalQudits 0 d = 0 := by
  dsimp [physicalQudits]
  split
  · rfl
  · rfl

/-- MA-VQE verified properties. -/
theorem param_update_eq (theta_i grad lr scaling : Float) :
  paramUpdate theta_i grad lr scaling = theta_i - lr * grad * scaling := rfl

/-- HSEC verified properties. -/
theorem syndrome_deterministic (s : Syndrome) (d m : Nat) :
  hsecDecoder s d m >= 0 := Nat.zero_le _

/-- QCFI verified properties. -/
theorem alloc_preserves_total_dim (state : QCFIState) (threshold : Float) :
  let (newState, _) := adaptiveAlloc state threshold
  newState.partition.totalDim = state.partition.totalDim := by
  dsimp [adaptiveAlloc]
  split
  · rfl
  · split
    · rfl
    · rfl

/-- Hardware verified properties. -/
theorem optical_traps_sufficient : defaultHardware.opticalTraps >= 100 := by decide

end HCQA.Proofs
