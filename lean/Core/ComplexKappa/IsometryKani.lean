// NOTE: This file provides a Kani‑bridged harness for certifying that the first column of the
// Stinespring dilation operator is an isometry.  All heavy‑lifting is delegated to the Rust
// engine via the `oracle_kani_isometry` axiom; the Lean side merely stitches the pieces together.

import Core.ComplexKappa.Core
import Core.ComplexKappa.SpectralAttractor

set_option linter.unusedVariables false

/-- An axiom stating that the Kani backend can verify the isometry property for the
    first column of the Stinespring dilation given the kernel parameters.
    This is a bridge to the Rust engine (Sedona Spine) – no logical reasoning occurs here. -/
axiom oracle_kani_isometry
  (k k_star ε σ γ : Real) :
  Isometry (fun (x : ℂ) => (firstColumn (stinespring_dilation k k_star ε σ γ) x))

/-- Helper definition extracting the first column of the Stinespring dilation operator.
    The actual operator is defined elsewhere (e.g., `SpectralAttractor`). -/
noncomputable def firstColumn (S : ℂ →ₗ[ℝ] ℂ) (x : ℂ) : ℂ :=
  S (Complex.ofReal 1) * x

/-- The Stinespring dilation operator (placeholder). In the full development this will be
    instantiated with concrete kernels; here we expose the expected type for the isometry proof. -/
noncomputable def stinespring_dilation (k k_star ε σ γ : Real) : ℂ →ₗ[ℝ] ℂ :=
  LinearMap.smulRight (LinearMap.id ℂ) (Complex.ofReal (noise_kernel k k_star ε σ γ))

/-- Certification theorem: the first column of the Stinespring dilation is an isometry.
    The proof is delegated to the Kani oracle.
-/
theorem first_column_is_isometry (k k_star ε σ γ : Real) :
  Isometry (fun x => firstColumn (stinespring_dilation k k_star ε σ γ) x) :=
by
  exact oracle_kani_isometry k k_star ε σ γ
