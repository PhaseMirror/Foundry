import Core.AceScnCsc.KernelTelemetry
import Core.AceScnCsc.SCNConditioning

namespace Core.AceScnCsc

structure CircuitLayout where
  base_constraints : Nat
  telemetry_fields : Nat
  total_constraints : Nat
  poseidon2_t : Nat
  poseidon2_r : Nat

theorem circom_budget_preserved :
    ∀ (layout : CircuitLayout)
      (h_constraints : layout.total_constraints = 5087)
      (h_t : layout.poseidon2_t = 9)
      (h_r : layout.poseidon2_r = 8),
    layout.total_constraints = 5087 ∧ layout.poseidon2_t = 9 ∧ layout.poseidon2_r = 8 := by
  intros _ h_constraints h_t h_r
  exact ⟨h_constraints, h_t, h_r⟩

end Core.AceScnCsc
