import Kernel

/-!
# Aztftc — linearity of the discrete integral (Fundamental Theorem, additive part)

The continuous Fundamental Theorem of Calculus has, as its discrete analog, the
*linearity* of summation. We formalize the discrete integral as a list sum and prove
it is additive and homogeneous over `Nat`. No `Mathlib`, no `sorry`.
-/
namespace Aztftc

open proofs.Kernel

/-- Discrete integral of `f` over a sample set `xs`. -/
def discreteIntegral (f : Nat → Nat) (xs : List Nat) : Nat := lsum (xs.map f)

/-- Additivity: ∫(f+g) = ∫f + ∫g. -/
theorem integral_linear (xs : List Nat) (f g : Nat → Nat) :
    discreteIntegral (fun x => f x + g x) xs =
    discreteIntegral f xs + discreteIntegral g xs := by
  simp [discreteIntegral]
  induction xs <;> simp [*]

/-- Homogeneity: ∫(k·f) = k·∫f for a constant scalar `k`. -/
theorem integral_scale (k : Nat) (f : Nat → Nat) (xs : List Nat) :
    discreteIntegral (fun x => k * f x) xs = k * discreteIntegral f xs := by
  simp [discreteIntegral]
  induction xs <;> simp [*]

end Aztftc
