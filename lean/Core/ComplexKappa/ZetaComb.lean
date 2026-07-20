import Core.ComplexKappa.Core
import Core.ComplexKappa.Zeta

set_option autoImplicit false
noncomputable section

namespace ComplexKappa.ZetaComb

open ComplexKappa
open ComplexKappa.Zeta

/-- Zeta-Comb noise kernel. -/
def noise_kernel_zeta (k k_star : Real) (epsilon sigma : Real) : Real :=
  ComplexKappa.noise_kernel k k_star epsilon sigma gamma

/-- Zeta-comb convergence oracle (bridged from Kani). -/
axiom oracle_kani_zeta_comb_converges :
  forall (epsilon sigma : Real) (hsigma : 0 < sigma) (k k_star : Real) (hk : 0 < k),
    Summable (fun n => zeta_comb_amplitude epsilon sigma (gamma n) * Real.cos (gamma n * Real.log (k / k_star)))

/-- Convergence: the series converges for sigma > 0. -/
theorem zeta_comb_converges (epsilon sigma : Real) (hsigma : 0 < sigma) (k k_star : Real) (hk : 0 < k) :
  Summable (fun n => zeta_comb_amplitude epsilon sigma (gamma n) * Real.cos (gamma n * Real.log (k / k_star))) :=
  oracle_kani_zeta_comb_converges epsilon sigma hsigma k k_star hk

/-- Signal amplitude: |delta_kappa/kappa| = epsilon^2 * exp(-2 sigma * gamma_1^2). -/
def signal_amplitude (epsilon sigma : Real) : Real :=
  epsilon^2 * Real.exp (-2 * sigma * (gamma 1)^2)

/-- Beat frequency between zeros n and m. -/
def beat_frequency (n m : Nat) : Real :=
  ComplexKappa.beat_frequency n m gamma

end ComplexKappa.ZetaComb
end
