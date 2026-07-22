import Core.universal_closure.PartialUC
import Core.universal_closure.UniversalClosure

/-!
# Defect Algebra — Formal Spec

Pure definitions. No proofs. No sorry. No Mathlib.
Kani verifies the defect measure properties.
-/

structure Defect where
  value : Nat

namespace Defect

def zero : Defect := ⟨0⟩

def add (d₁ d₂ : Defect) : Defect := ⟨d₁.value + d₂.value⟩

instance : Add Defect := ⟨add⟩

instance : LE Defect := ⟨fun d₁ d₂ => d₁.value ≤ d₂.value⟩

def le (d₁ d₂ : Defect) : Prop := d₁ ≤ d₂

end Defect

open Defect in
structure HasDefect {X : Type} (U : UC X) where
  mu : X → Defect
  monotone_closure : ∀ x, (mu (U.closure x)) ≤ (mu x)

namespace HasDefect

variable {X : Type} {U : UC X} (hd : HasDefect U)

def associator_defect (x y z : X) : Defect :=
  let xy_z := hd.mu (U.compose (U.compose x y) z)
  let x_yz := hd.mu (U.compose x (U.compose y z))
  let cost_xy := hd.mu (U.compose x y)
  let cost_yz := hd.mu (U.compose y z)
  ⟨max (xy_z.value + cost_xy.value + (hd.mu z).value)
       (x_yz.value + (hd.mu x).value + cost_yz.value)⟩

def binary_residual (x y : X) : Defect :=
  let bound := hd.mu (U.compose x y)
  Defect.add bound (hd.mu y)

end HasDefect
