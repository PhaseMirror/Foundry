import Core.ComplexKappa.Core

set_option autoImplicit false
noncomputable section

namespace ComplexKappa.WardIdentity

open ComplexKappa

/-- Stress-energy tensor (formal). -/
def stress_energy_tensor := Nat -> Nat -> Real -> Complex

/-- Covariant divergence oracle. -/
axiom oracle_kani_covariant_divergence :
  forall (T : stress_energy_tensor) (nu : Nat), Real -> Complex

/-- Covariant divergence. -/
def covariant_divergence (T : stress_energy_tensor) (nu : Nat) : Real -> Complex :=
  oracle_kani_covariant_divergence T nu

/-- Noise kernel tensor oracle. -/
axiom oracle_kani_noise_kernel_tensor : stress_energy_tensor

/-- Dissipation kernel tensor oracle. -/
axiom oracle_kani_dissipation_kernel_tensor : stress_energy_tensor

/-- Zero function oracle. -/
axiom oracle_zero_fn : Real -> Complex

/-- Noise kernel. -/
def noise_kernel : stress_energy_tensor := oracle_kani_noise_kernel_tensor

/-- Dissipation kernel. -/
def dissipation_kernel : stress_energy_tensor := oracle_kani_dissipation_kernel_tensor

/-- Ward identity oracle. -/
axiom oracle_kani_ward_identity :
  (forall (mu nu : Nat), covariant_divergence oracle_kani_noise_kernel_tensor nu = oracle_zero_fn) /\
  (forall (mu nu : Nat), covariant_divergence oracle_kani_dissipation_kernel_tensor nu = oracle_zero_fn)

/-- Ward identity. -/
theorem ward_identity :
  (forall (mu nu : Nat), covariant_divergence noise_kernel nu = oracle_zero_fn) /\
  (forall (mu nu : Nat), covariant_divergence dissipation_kernel nu = oracle_zero_fn) :=
  oracle_kani_ward_identity

end ComplexKappa.WardIdentity
end
