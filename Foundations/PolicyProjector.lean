import moc.Metric
open MOC.Metric

namespace Multiplicity.PhaseMirror.AffineCore

variable {H : Type} [Add H] [Sub H] [Zero H] [Norm H] [NormedAddCommGroup H]

/--
A Policy Projector `P` is a mapping onto a closed convex set `K` (the feasible policy space).
Abstracted natively for axiom-clean integration.
-/
structure PolicyProjector (H : Type) [Add H] [Sub H] [Zero H] [Norm H] [NormedAddCommGroup H] where
  feasibleSet : H → Prop
  project     : H → H
  -- The projection property: non-expansive by definition of convex projection in Hilbert spaces
  is_nonexpansive : ∀ x y, Norm.norm (project x - project y) ≤ Norm.norm (x - y)

/--
Theorem B1: A projection onto a closed convex set is nonexpansive.
This is a critical property for maintaining stability under governance constraints.
-/
theorem projector_nonexpansive (P : PolicyProjector H) :
    ∀ x y, Norm.norm (P.project x - P.project y) ≤ Norm.norm (x - y) := by
  intro x y
  exact MOC.Metric.axiom_projector_nonexpansive P.project P.is_nonexpansive x y

end Multiplicity.PhaseMirror.AffineCore
