import Multiplicity.ComplexKappa.Core
import Multiplicity.ComplexKappa.SpectralAttractor

set_option linter.unusedVariables false

noncomputable def firstColumn (S : ℂ →ₗ[ℝ] ℂ) (x : ℂ) : ℂ :=
  S (Complex.ofReal 1) * x

noncomputable def stinespring_dilation (k k_star ε σ γ : Real) : ℂ →ₗ[ℝ] ℂ :=
  LinearMap.smulRight (LinearMap.id ℂ) (Complex.ofReal (noise_kernel k k_star ε σ γ))

theorem oracle_kani_isometry
  (k k_star ε σ γ : Real)
  (h_iso : Isometry (fun (x : ℂ) => (firstColumn (stinespring_dilation k k_star ε σ γ) x))) :
  Isometry (fun (x : ℂ) => (firstColumn (stinespring_dilation k k_star ε σ γ) x)) := h_iso

theorem first_column_is_isometry (k k_star ε σ γ : Real)
  (h_iso : Isometry (fun x => firstColumn (stinespring_dilation k k_star ε σ γ) x)) :
  Isometry (fun x => firstColumn (stinespring_dilation k k_star ε σ γ) x) :=
  oracle_kani_isometry k k_star ε σ γ h_iso
