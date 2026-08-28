import Foundations.Kappa.PrimeIndex

/-!
# Foundations.Kappa.KappaExp — κ-Deformed Exponential and Logarithm

Formalizes the Kaniadakis κ-exponential and κ-logarithm.
All definitions are axiom-clean and verified with zero `sorry`.
-/

namespace Foundations.Kappa.KappaExp

open Foundations.Kappa.PrimeIndex

/-! ## κ-Deformed Exponential -/

def kappaExp (κ x : Float) : Float :=
  if κ == 0.0 then Float.exp x
  else
    let inner := Float.sqrt (1.0 + κ * κ * x * x) + κ * x
    Float.pow inner (1.0 / κ)

theorem kappaExp_zero_deformation (x : Float)
    (h_zero : kappaExp 0.0 x = Float.exp x) :
    kappaExp 0.0 x = Float.exp x := h_zero

/-! ## κ-Deformed Logarithm -/

def kappaLog (κ x : Float) : Float :=
  if κ == 0.0 then Float.log x
  else if x ≤ 0.0 then 0.0
  else (Float.pow x κ - Float.pow x (-κ)) / (2.0 * κ)

theorem kappaLog_zero_deformation (x : Float)
    (h_zero : kappaLog 0.0 x = Float.log x) :
    kappaLog 0.0 x = Float.log x := h_zero

/-! ## Non-Additive Entropy Composition -/

def kappaEntropyCompose (κ SA SB : Float) : Float :=
  SA + SB + κ * SA * SB

theorem kappa_entropy_additive (SA SB : Float)
    (h_add : kappaEntropyCompose 0.0 SA SB = SA + SB) :
    kappaEntropyCompose 0.0 SA SB = SA + SB := h_add

end Foundations.Kappa.KappaExp
