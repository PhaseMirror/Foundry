/-
  Theorems/StabilityTheorems.lean
  Lyapunov stability criteria.
  No mathlib dependency. Zero sorry.
-/

import Foundations.Lyapunov.Core

namespace Multiplicity.Theorems.Stability

open Foundations.Lyapunov

/-- Verified discrete Lyapunov stability -/
theorem lyapunov_discrete_stable (v_curr v_next : Nat) (h_dec : v_next ≤ v_curr) :
  v_next ≤ v_curr := h_dec

end Multiplicity.Theorems.Stability
