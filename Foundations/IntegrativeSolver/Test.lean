import Foundations.IntegrativeSolver.Core
import Foundations.IntegrativeSolver.Diffusion
import Foundations.IntegrativeSolver.Intervention
import Foundations.IntegrativeSolver.Audit

/-!
# Foundations.IntegrativeSolver.Test — Runnable Examples & Tests
-/

namespace Foundations.IntegrativeSolver.Test

open Foundations.IntegrativeSolver

def v2 : SCV 2 where
  counts := fun k => if k = 0 then 3 else 5

def v3 : SCV 3 where
  counts := fun k => match k with | 0 => 1 | 1 => 2 | _ => 3

theorem test_scv_eq_iff : v2 = v2 := rfl

theorem test_sumFin_const : sumFin (fun _ : Fin 3 => 2) = 6 := by
  have := sumFin_const 3 2
  exact this

theorem test_aggregate_capped_le :
    aggregate (cappedSpec 3 10 (fun _ => 1)) v3 ≤ 30 := by
  exact aggregate_capped_le 3 (fun _ => 1) 10 v3

theorem test_diffuse_total_load :
    sumFin (diffuse v3).counts = sumFin v3.counts := by
  exact diffuse_total_load v3

theorem test_intervene_preserves_nonneg :
    ∀ k, (intervene (⟨0, by omega⟩ : Fin 3) 2 v3).counts k ≥ 0 := by
  intro k
  exact intervene_preserves_nonneg (⟨0, by omega⟩ : Fin 3) 2 v3 k

theorem test_audit_nil : audit ([] : List (Op 3)) v3 = v3 := by
  exact audit_nil v3

end Foundations.IntegrativeSolver.Test
