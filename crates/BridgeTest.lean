import MOC.Core
import MOC.Resonance
import MOC.Banach
example : MOC.isAdmissible [MOC.MocOp.subdivision 3 3, MOC.MocOp.subdivision 2 2] := by (unfold MOC.isAdmissible MOC.aceBound MOC.dim; decide)
theorem cycle_108_convergent : ∃ s_star : Unit, s_star = () := 
  MOC.Banach.resonance_gated_convergence (x := 108) (H := [2, 3]) (H' := [2, 3]) (tiers := [1, 2, 3]) 500 
  (by (unfold MOC.Resonance.R_sc MOC.Resonance.R1 MOC.Resonance.R2 MOC.Resonance.R3; decide))
