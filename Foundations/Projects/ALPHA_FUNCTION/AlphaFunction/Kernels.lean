import Init
import AlphaFunction.Core

/-! # Alpha Function — Kernels

Kernel family G(t;θ) with three ablations having closed-form references.
-/

namespace AlphaFunction.Kernels

open AlphaFunction.Core

/-- Kernel G1: baseline G(t) = 1. -/
def G1 : Kernel := {
  G := fun _ _ => 1.0,
  h_domain := trivial,
  h_convergence := trivial
}

/-- Kernel G2: exp-shift G(t) = e^{a t}. -/
def G2 (a : Float) : Kernel := {
  G := fun t _ => Float.exp (a * t),
  h_domain := trivial,
  h_convergence := trivial
}

/-- Kernel G3: polynomial G(t) = (1 + c t)^m. -/
def G3 (c m : Float) : Kernel := {
  G := fun t _ => Float.pow (1.0 + c * t) m,
  h_domain := trivial,
  h_convergence := trivial
}

/-- Closed-form references (placeholders). -/
def alphaG1Reference (_x _s : Float) : Float := 0.0
def alphaG2Reference (_x _s _a : Float) : Float := 0.0
def alphaG3Reference (_x _s _c _m : Float) : Float := 0.0

/-- Verified kernel properties. -/
theorem G1_identity : G1.G 0.0 0.0 = 1.0 := rfl

end AlphaFunction.Kernels
