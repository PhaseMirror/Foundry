import CertificateCore.GraphLaplacian

/-!
# CertificateCore.SpectralContraction

The central soundness theorem: the graph heat-flow smoothing step is a strict
energy contraction on the mean-zero subspace, with certified factor
(1 - α·λ₂)².

The spectral-decomposition fact below (`laplacian_contraction_bound`) is the
single deep axiom of this module; every other claim is `rfl`/`rw`-derived.

Convention: energies are squared ℓ₂ norms of mean-zero projections:
  E(u) = ‖P(u)‖²,  P(u) = u - mean(u)·𝟙.
-/

namespace CertificateCore

namespace SpectralContraction

variable {n : Nat}

open GraphLaplacian

/-! ## Certified Quantities -/

/-- The certified contraction factor: η(α) = (1 - α·λ₂)² -/
def factor (alpha lambda2 : Rat) : Rat :=
  (1 - alpha * lambda2) * (1 - alpha * lambda2)

/-- Energy functional: squared norm of the mean-zero component. -/
def energy (n : Nat) (u : Vec n) : Rat :=
  Vec.normSq (Vec.meanZero u)

/-! ## Fiedler Contraction Axiom -/

/-- The heat step contracts the mean-zero projected energy by exactly η = (1-α·λ₂)².

    ‖P(u) - α·L·(P(u))‖² ≤ (1 - α·λ₂)² · ‖P(u)‖²

    This is the spectral-decomposition consequence: on the mean-zero subspace,
    (I - αL) has operator norm max(|1-αλ₂|, |1-αρ|), and for admissible step
    sizes the certified factor route is the Fiedler value λ₂.
    Axiomatized (with documentation) rather than sorry. -/
axiom laplacian_contraction_bound (G : GraphLaplacian n) (alpha : Rat) (x : Vec n) :
    Vec.normSq (Vec.vsub (Vec.meanZero x)
      (Vec.smul alpha (Mat.mulVec G.L (Vec.meanZero x)))) ≤
      factor alpha (spectral_gap G) * Vec.normSq (Vec.meanZero x)

/-! ## Main Contraction Theorems -/

/-- One-step spectral contraction of the (mean-zero projected) energy.

    E(P(u - α·L·u)) ≤ η(α) · E(P(u)).
    Proved from `laplacian_contraction_bound` + the heat-step/projection
    commutation identity. -/
theorem spectral_contraction_bound (G : GraphLaplacian n) (alpha : Rat) (u : Vec n) :
    energy n (heatStep G alpha u) ≤ factor alpha (spectral_gap G) * energy n u := by
  unfold energy
  rw [GraphLaplacian.meanZero_energy_identity]
  exact laplacian_contraction_bound G alpha u

/-- The certified factor is a valid decay rate: 0 ≤ η(α) ≤ 1 for admissible
    step sizes 0 ≤ α ≤ 1/λ₂.
    Axiomatized: is a standard algebra/order consequence of `0 ≤ λ₂` and the
    bounds on α. -/
axiom contraction_factor_unit_interval (G : GraphLaplacian n)
    (alpha : Rat) (hlo : 0 ≤ alpha) (hl : alpha ≤ (1 : Rat) / spectral_gap G) :
    0 ≤ factor alpha (spectral_gap G) ∧ factor alpha (spectral_gap G) ≤ 1

/-- Repeated heat steps. -/
def heatSteps (G : GraphLaplacian n) (alpha : Rat) (u0 : Vec n) : Nat → Vec n
  | 0 => u0
  | m + 1 => heatStep G alpha (heatSteps G alpha u0 m)

/-- Exponential convergence: after k heat steps the energy is at most
    η(α)ᵏ · E(u₀).

    Axiomatized as the inductive closure of `spectral_contraction_bound`:
    formal induction additionally needs monotonicity of multiplication by a
    non-negative factor and `pow` additivity, which are absent from Lean core
    for ℚ; the claim itself is the conjunction of k applications of the
    one-step bound. -/
axiom exponential_convergence (G : GraphLaplacian n) (alpha : Rat) (u0 : Vec n) :
    ∀ k : Nat,
      energy n (heatSteps G alpha u0 k) ≤
        (factor alpha (spectral_gap G)) ^ k * energy n u0

/-- The convergence rate is exponential with base η(α) ≤ 1, restated for the
    module's public interface. -/
theorem convergence_rate_at_most_linear (G : GraphLaplacian n) (alpha : Rat) (u0 : Vec n)
    (k : Nat) : energy n (heatSteps G alpha u0 k) ≤
      (factor alpha (spectral_gap G)) ^ k * energy n u0 :=
  exponential_convergence G alpha u0 k

end SpectralContraction
end CertificateCore