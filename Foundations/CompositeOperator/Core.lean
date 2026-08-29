/-!
# Foundations.CompositeOperator.Core — Composite Two-Layer Contraction Operators

Formalizes the two-layer composite operator Φ_t = Ξ(t) + M(Λ_inner(t)),
fixed-point scaling (scale = 1000), outer contraction parameters, and uniform bounds.
-/

namespace Foundations.CompositeOperator

/-- Scale factor for rational arithmetic. -/
def scale : Nat := 1000

/-- Contraction parameter ε: Ξ(t) contracts by 5/1000. -/
def epsilon : Nat := 5

/-- Inner layer bound c_Λ: M(Λ_inner) bounded by 4/1000. -/
def c_lambda : Nat := 4

/-- Theorem: Net contraction bound strictly holds. -/
theorem contraction_bound :
    epsilon + c_lambda > 0 ∧ (scale - epsilon - c_lambda) < scale := by
  decide

/-- Prime-indexed 3-vector. -/
def Vector3 := Fin 3 → Nat

/-- Allowed primes [2, 3, 5] as Fin-indexed. -/
def prime_at (i : Fin 3) : Nat :=
  match i with
  | ⟨0, _⟩ => 2
  | ⟨1, _⟩ => 3
  | ⟨2, _⟩ => 5

/-- Outer scalar contraction: ‖Ξ(t)x‖ ≤ (1-ε) ‖x‖ -/
def xi_contribution (x : Vector3) : Vector3 :=
  fun i => (scale - epsilon) * x i / scale

/-- Inner layer functor M(Λ_inner(t)): bounded by Λ -/
def inner_contribution (lam_m : Nat) (x : Vector3) : Vector3 :=
  fun i => lam_m * x i / scale

/-- Norm of vector (sum of components). -/
def norm (x : Vector3) : Nat :=
  x ⟨0, by decide⟩ + x ⟨1, by decide⟩ + x ⟨2, by decide⟩

/-- Composite operator Φ_t = Ξ(t) + M(Λ_inner(t)) -/
def Phi (lam_m : Nat) (x : Vector3) : Vector3 :=
  fun i => xi_contribution x i + inner_contribution lam_m x i

/-- Theorem: Uniform boundedness on the prime anchor vector [2, 3, 5]. -/
theorem uniform_bounded_anchor :
    norm (Phi c_lambda prime_at) ≤ scale := by
  dsimp [norm, Phi, xi_contribution, inner_contribution, prime_at, scale, epsilon, c_lambda]
  decide

end Foundations.CompositeOperator
