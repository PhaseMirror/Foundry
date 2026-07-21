import Init

namespace Core.EigenSolvers

structure LanczosParams where
  matrix_dim : Nat
  prime_weight_bound : Int
  step_count : Nat

/-- 
  The prime-weighted Lanczos residual evaluation bridge. 
-/
opaque prime_weighted_lanczos_residual (p : LanczosParams) : Int

/-- 
  Convergence guard axiom for Lanczos: if steps exceed or equal matrix dimension, 
  the residual error ideally vanishes (modeled as 0 discretely).
-/
axiom lanczos_convergence (p : LanczosParams) :
  p.matrix_dim > 0 → p.step_count ≥ p.matrix_dim → prime_weighted_lanczos_residual p = 0

end Core.EigenSolvers
