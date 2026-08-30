import Init.Data.Rat.Basic

namespace P2CCore

/--
  Pure Lean 4 Core Scalar Lemma for the Multiplicative Lipschitz Governor.
  Zero-Mathlib compliant. Uses exact rational arithmetic matching the
  Rust ucc-engine `Ratio<i64>` runtime.

  Proves: (γ / (S + η)) * (S + η) = γ for S + η ≠ 0.
--/
theorem scalar_contractivity_bound_rat
    (gamma S eta : Rat)
    (h_nonzero : S + eta ≠ 0) :
    (gamma / (S + eta)) * (S + eta) = gamma := by
  exact Rat.div_mul_cancel gamma h_nonzero

end P2CCore

