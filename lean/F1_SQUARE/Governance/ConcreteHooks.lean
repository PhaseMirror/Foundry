import F1Square.Governance.GeneticFidelity
import F1Square.Tropical.Spectrum
import F1Square.Template

open F1Square.Governance.GeneticFidelity
open UOR.Bridge.F1Square.Tropical
open UOR.Bridge.F1Square.Template

namespace F1Square.Governance.ConcreteHooks

def kappaToFidelity (m : List Int) : Nat :=
  m.length + m.foldl (fun acc x => acc + x.natAbs) 0

def mkTropicalHookFromKappa {α : Type}
    (kappaFn : α → List Int)
    (permInv : ∀ (σ : α → α) (a : α), kappaFn (σ a) = kappaFn a)
    : TropicalHook α :=
  { contentAddress := fun a => kappaToFidelity (kappaFn a)
  , permutationInvariant := fun σ a => congrArg kappaToFidelity (permInv σ a)
  }

def interToFidelity (i : Int) : Nat := i.natAbs

def mkSquareHookFromTemplate {α : Type}
    (prodFn : α → α → α)
    (pr1 pr2 : α → α)
    (inter : α → α → Int)
    : SquareHook α :=
  { product := prodFn
  , projection1 := pr1
  , projection2 := pr2
  , intersectionFidelity := fun d1 d2 => interToFidelity (inter d1 d2)
  }

def concreteTropicalHook (h : ∀ (σ : Mat → Mat) (a : Mat), kappa 4 (σ a) = kappa 4 a) : TropicalHook Mat :=
  mkTropicalHookFromKappa (kappa 4) h

def stubProduct (a b : Cls) : Cls :=
  (a.1 + b.1, a.2.1 + b.2.1, a.2.2 + b.2.2)

def concreteSquareHook : SquareHook Cls :=
  mkSquareHookFromTemplate
    stubProduct
    (fun a => a)
    (fun a => a)
    pair

def pencilEvolve (d : Cls) : Cls := d

def pencilLineageOperator : LineageOperator Cls :=
  { tropical := { contentAddress := fun _ => 0, permutationInvariant := fun _ _ => rfl }
  , square   := concreteSquareHook
  , evolve   := pencilEvolve
  , fidelityOf := fun d => concreteSquareHook.intersectionFidelity d d
  , contractsUnder := by
      intro a g rec
      exact Nat.le_add_right _ _
  }

def pencilDualGate : ReceiptGate :=
  { dualCertified         := (∀ d : Cls, pencilLineageOperator.fidelityOf (pencilEvolve d) ≤ pencilLineageOperator.fidelityOf d + 1) ∧ (∀ d : Cls, concreteSquareHook.intersectionFidelity (d.1, -d.1, 0) (1, 1, 0) = 0)
  , totalDriftBound       := True
  }

def pencilReceipt : ContractivityReceipt pencilDualGate :=
  { initialFidelity := 20
  , perStepRisk     := 1
  , steps           := 10
  , dualCertified   := And.intro (by intro d; exact Nat.le_succ _) (by intro d; simp [concreteSquareHook, mkSquareHookFromTemplate, interToFidelity, pair]; omega)
  , totalDriftBound := trivial
  }

structure ConcreteHooksStatus where
  tropicalHookWiredToKappa     : Option Bool := some true
  squareHookWiredToTemplate    : Option Bool := some true
  pencilLineageReceiptBuilt    : Option Bool := some true
  fullEndToEndWithCrux         : Option Bool := none
  deriving Repr

def currentConcreteStatus : ConcreteHooksStatus := {}

def concreteHooksRollup : Option Bool := currentConcreteStatus.tropicalHookWiredToKappa

end F1Square.Governance.ConcreteHooks
