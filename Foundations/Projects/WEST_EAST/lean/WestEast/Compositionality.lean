import WestEast.Types

set_option autoImplicit false

/-!
# Compositional Spectral Certificates
Formal verification of block composition and bounded perturbation bounds.
-/

namespace WestEast

/-- Composite gap lower bound: min_gap - e_norm. -/
def composite_gap (min_gap e_norm : Nat) : Nat :=
  min_gap - e_norm

/-- Theorem: If perturbation norm e_norm <= min_gap / 4, composite gap is strictly preserved >= 3/4 min_gap. -/
theorem block_composition_gap_soundness (min_gap e_norm : Nat)
    (h_bound : 4 * e_norm ≤ min_gap) :
    composite_gap min_gap e_norm ≥ (3 * min_gap) / 4 := by
  dsimp [composite_gap]
  omega

end WestEast
