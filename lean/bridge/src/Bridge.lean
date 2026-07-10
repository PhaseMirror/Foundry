import MOC.Core
import Init.Data.String.Basic

namespace Bridge

/-- Translates the Lisp macro output to Lean OperatorWord -/
def bridge_moc_108 : MOC.OperatorWord :=
  MOC.OperatorWord.mk [ MOC.PrimeOp.sub 3 3, 
                        MOC.PrimeOp.sub 3 3, 
                        MOC.PrimeOp.sub 3 3, 
                        MOC.PrimeOp.sub 2 2, 
                        MOC.PrimeOp.sub 2 2 ]

/-- Verification: The bridged term is ACE-stable -/
theorem bridge_stable : MOC.isACEStable bridge_moc_108 = true := by
  rfl

end Bridge
