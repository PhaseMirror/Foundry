import Multiplicity.Spine
import moc.Valuation

namespace Multiplicity.MOC.Ostrowski

inductive ValuationType where
  | Archimedean : ValuationType
  | pAdic : (p : Nat) → ValuationType
  deriving Repr, DecidableEq

theorem ostrowski_pirtm_embedding (v : ValuationType) :
  v = ValuationType.Archimedean ∨ ∃ p : Nat, v = ValuationType.pAdic p := by
  cases v
  case Archimedean =>
    apply Or.inl
    rfl
  case pAdic p =>
    apply Or.inr
    exists p

def cycle108_valuations : List ValuationType := [
  ValuationType.pAdic 2,
  ValuationType.pAdic 3
]

end Multiplicity.MOC.Ostrowski
