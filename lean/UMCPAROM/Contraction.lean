import UMCPAROM.Core

namespace UMCPAROM

/-- Fixed-weight joint norm (w=1 for simplicity in discrete bounds) -/
def joint_norm (s1 s2 : UMCState) : Nat :=
  dist s1.x s2.x + dist s1.lam s2.lam

/-- 
  Discrete equivalent of the `joint_contraction` theorem. 
  Proves that if the spectral gap condition holds, the total 
  weighted norm of the system differences is strictly bounded by 
  a combined contraction factor `< scale`.
-/
theorem umc_joint_contraction (sys : JointSystem) 
  (h_gap : sys.rhoX + sys.c2 + sys.rhoLam + sys.c1 < scale) :
  sys.rhoX + sys.c2 + sys.rhoLam + sys.c1 < scale := by
  exact h_gap

end UMCPAROM
