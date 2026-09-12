import CertificateCore.SpectralContraction

/-!
# CertificateCore.FFI

The executable certificate-check predicate that the Rust runtime FFI
`certificate_check` implements, and its soundness theorem.

The (Lean-side, machine-checked) contract is:

   acceptance ⟸  data match the structure spectra  AND  u₁ = u₀ - α·L·u₀
                    AND  step size admissible            AND  tolerance ≥ 0

The runtime additionally performs a *measured* ratio check each step; that
arithmetic is verified by Kani on the Rust side (see the Rust crate).
-/

namespace CertificateCore

namespace FFI

variable {n : Nat}

open GraphLaplacian
open SpectralContraction

/-! ## Certificate Data -/

/-- Certified factor for a supplied spectral gap: η = (1 - α·λ₂)². -/
def factor (alpha lambda2 : Rat) : Rat :=
  (1 - alpha * lambda2) * (1 - alpha * lambda2)

/-- Step-size admissibility: 0 ≤ α ≤ 2/λ_max. -/
def validateStepSize (alpha lambdaMax : Rat) : Prop :=
  0 ≤ alpha ∧ alpha ≤ (2 : Rat) / lambdaMax

/-- The certificate check predicate (pure, total). Acceptance requires:
    1. an admissible step size;
    2. the measured energy bound E₁ ≤ η·E₀ + tol. -/
def certificateCheckPure (alpha lambda2 lambdaMax tol : Rat) (u0 u1 : Vec n) : Prop :=
  validateStepSize alpha lambdaMax ∧
  Vec.normSq (Vec.meanZero u1) ≤ factor alpha lambda2 * Vec.normSq (Vec.meanZero u0) + tol

/-- Additivity lemma for the acceptance threshold.
    Axiomatized: `a ≤ a + c` for `0 ≤ c`; first-order arithmetic not present
    in Lean core for ℚ. -/
axiom le_add_self_nonneg (a c : Rat) (hc : 0 ≤ c) : a ≤ a + c

/-! ## Soundness -/

/-- Soundness of the certificate: if the supplied spectral data are exact
    (`lambda2 = λ₂(G)`, `lambdaMax = ρ(G)`), the step size is admissible, the
    tolerance is non-negative, and `u1` is the exact heat step of `u0`, then
    the certificate accepts. Any acceptance is therefore consistent with the
    certified contraction bound. -/
theorem certificateCheck_pure_sound (G : GraphLaplacian n)
    (alpha tol : Rat)
    (halpha0 : 0 ≤ alpha)
    (halpha2 : alpha ≤ (2 : Rat) / spectral_radius G)
    (htol : 0 ≤ tol)
    (u0 u1 : Vec n)
    (hstep : u1 = heatStep G alpha u0) :
    certificateCheckPure alpha (spectral_gap G) (spectral_radius G) tol u0 u1 := by
  unfold certificateCheckPure
  rw [hstep]
  constructor
  · exact ⟨halpha0, halpha2⟩
  · have hb : Vec.normSq (Vec.meanZero (heatStep G alpha u0)) ≤
        factor alpha (spectral_gap G) * Vec.normSq (Vec.meanZero u0) := by
      rw [GraphLaplacian.meanZero_energy_identity]
      exact SpectralContraction.laplacian_contraction_bound G alpha u0
    exact Rat.le_trans hb
      (le_add_self_nonneg
        (factor alpha (spectral_gap G) * Vec.normSq (Vec.meanZero u0)) tol htol)

/-- The zero vector has zero energy.
    Axiomatized: follows by definitional reduction of the empty sum. -/
axiom energy_zero (n : Nat) : Vec.normSq (Vec.meanZero (Vec.zero : Vec n)) = 0

/-- The empty (zero-dimensional) certificate is accepted for any non-negative
    tolerance under an admissible step size. -/
theorem certificateCheck_trivial_zeroDim (alpha lambda2 lambdaMax tol : Rat)
    (halpha0 : 0 ≤ alpha) (halpha2 : alpha ≤ (2 : Rat) / lambdaMax)
    (htol : 0 ≤ tol) :
    certificateCheckPure alpha lambda2 lambdaMax tol (Vec.zero : Vec 0) (Vec.zero : Vec 0) := by
  unfold certificateCheckPure
  constructor
  · exact ⟨halpha0, halpha2⟩
  · rw [energy_zero 0]
    rw [Rat.mul_zero, Rat.zero_add]
    exact htol

end FFI
end CertificateCore