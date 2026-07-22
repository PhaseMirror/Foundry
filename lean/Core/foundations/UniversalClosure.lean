namespace Core.foundations.UniversalClosure

/--
The abstract mathematical interface for any lawful computational substrate.
Instantiations include quantum hardware, distributed protocols, and topological spaces.
-/
structure UniversalClosure (X : Type u) (Obs : Type v) (Defect : Type w) where
  compose : X → X → X
  closure : X → X
  defect : X → Float
  observable : X → Obs
  associator : X → X → X → Defect

class ClosureLaw {X Obs Def} (uc : UniversalClosure X Obs Def) where
  idempotent (x : X) : uc.closure (uc.closure x) = uc.closure x

class DefectLaw {X Obs Def} (uc : UniversalClosure X Obs Def) where
  monotone (x : X) : uc.defect (uc.closure x) ≤ uc.defect x
  zero_iff_fixed (x : X) : uc.defect x = 0.0 ↔ uc.closure x = x

class AssociativityLaw {X Obs Def} (uc : UniversalClosure X Obs Def) 
  (norm : Def → Float) (ε : Float) where
  bounded (a b c : X) : norm (uc.associator a b c) ≤ ε

/-- 
If every update is lawful (via the closure operator) and the defect is 
bounded below, the defect metric is non-increasing.
-/
theorem defect_non_increasing {X Obs Def} (uc : UniversalClosure X Obs Def)
  (dl : DefectLaw uc) (x u : X) :
  uc.defect (uc.closure (uc.compose x u)) ≤ uc.defect (uc.compose x u) := by
  exact dl.monotone (uc.compose x u)

end Core.foundations.UniversalClosure
