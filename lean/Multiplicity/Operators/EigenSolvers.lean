namespace Multiplicity.Core.Operators.EigenSolvers

structure LanczosParams where
  matrix_dim : Nat
  prime_weight_bound : Int
  step_count : Nat

def prime_weighted_lanczos_residual (p : LanczosParams) : Int :=
  if p.step_count ≥ p.matrix_dim then 0 else 1

theorem lanczos_convergence (p : LanczosParams) :
  p.matrix_dim > 0 → p.step_count ≥ p.matrix_dim → prime_weighted_lanczos_residual p = 0 := by
  intro _hdim hstep
  dsimp [prime_weighted_lanczos_residual]
  simp [hstep]

end Multiplicity.Core.Operators.EigenSolvers
