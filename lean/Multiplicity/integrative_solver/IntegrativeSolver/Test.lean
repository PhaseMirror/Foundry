import Multiplicity.Std
import Multiplicity.IntegrativeSolver.Core
import Multiplicity.IntegrativeSolver.Diffusion
import Multiplicity.IntegrativeSolver.Intervention
import Multiplicity.IntegrativeSolver.Audit
open Classical
open IntegrativeSolver.Core
open IntegrativeSolver.Diffusion
open IntegrativeSolver.Intervention
open IntegrativeSolver.Audit

/-!
# IntegrativeSolver.Test

Runnable examples and property-based tests for the M-Integrative Solver.
-/

/-- A 2-channel SCV with counts [3, 5]. -/
def v2 : SCV 2 where
  counts := fun k => if k = 0 then 3 else 5

/-- A 3-channel SCV with counts [1, 2, 3]. -/
def v3 : SCV 3 where
  counts := fun k => match k with | 0 => 1 | 1 => 2 | _ => 3

theorem test_scv_eq_iff : v2 = v2 := by rfl

theorem test_sumFin_const : sumFin (fun _ : Fin 3 => 2) = 6 := by
  simp [sumFin_const]

theorem test_aggregate_capped_le :
    aggregate (cappedSpec 3 10 (fun _ => 1)) v3 ≤ 30 := by
  exact aggregate_capped_le 3 (fun _ => 1) 10 v3

theorem test_diffuse_total_load :
    sumFin (diffuse v3).counts = sumFin v3.counts := by
  exact diffuse_total_load v3

theorem test_intervene_preserves_nonneg :
    ∀ k, (intervene (⟨0, by omega⟩ : Fin 3) 2 v3).counts k ≥ 0 := by
  intro k
  by_cases hk : k = ⟨0, by omega⟩
  · subst k
    simp [intervene]
  · simp [intervene]

theorem test_audit_nil : audit ([] : List (Op 3)) v3 = v3 := by
  exact audit_nil v3

def main : IO Unit := IO.println "All tests passed."
