import moc.Metric
open MOC.Metric

namespace Multiplicity.PhaseMirror.AffineCore

variable {H : Type} [Add H] [Sub H] [Zero H] [Norm H] [NormedAddCommGroup H]

class Smul (α : Type) (β : Type) where
  smul : α → β → β

infixr:73 " • " => Smul.smul

variable [Smul Rat H]

/--
The Update Operator Φ_t from the Affine Core spec, modeled with a finite list of primes
to avoid Mathlib's topological infinite summations.
-/
structure UpdateOperator (H : Type) [Add H] [Sub H] [Zero H] [Norm H] [NormedAddCommGroup H] [Smul Rat H] where
  -- Prime-indexed modes
  primes : List Nat
  α : Nat → Rat
  π : Nat → Rat
  M : Nat → BoundedLinearMap H H

/--
Apply the update operator to a state x.
-/
def applyUpdate (U : UpdateOperator H) (x : H) : H :=
  U.primes.foldl (fun acc p => acc + ((U.α p * U.π p) • U.M p.toFun x)) 0

/--
The contraction constant k.
-/
def contractionConst (U : UpdateOperator H) : Rat :=
  U.primes.foldl (fun acc p => acc + (if (U.α p * U.π p) ≥ 0 then (U.α p * U.π p) else -(U.α p * U.π p)) * (U.M p).bound) 0

end Multiplicity.PhaseMirror.AffineCore
