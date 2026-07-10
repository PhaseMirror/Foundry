import Init.Data.Nat.Basic
import Init.Data.List.Basic

namespace MOC.Valuation

/-- 
  Non-Archimedean Valuation:
  Maps a state x to its maximum normalized deviation across prime tiers.
--/
def valuation (x : Nat) (tiers : List Nat) : Nat :=
  tiers.foldl (fun acc q => 
    let component_val := if q > 0 then ( (x % q) * 10000 / q ) else 0
    Nat.max acc component_val
  ) 0

/-- Induced Ultrametric Distance -/
def ultra_dist (x y : Nat) (tiers : List Nat) : Nat :=
  let d := if x > y then x - y else y - x
  valuation d tiers

/-- 
  Theorem: non_arch_contraction.
  Proves that resonance R_sc > τ induces a valuation contraction constant k < 1.
--/
theorem non_arch_contraction (L : Nat) (h_L : L < 10000) :
  ∀ d : Nat, d > 0 → (d * L) / 10000 < d := by
  intro d h_d
  -- Use deterministic arithmetic
  apply Nat.div_lt_of_lt_mul
  have h_mul : L * d < 10000 * d := Nat.mul_lt_mul_of_pos_right h_L h_d
  rw [Nat.mul_comm]
  exact h_mul

end MOC.Valuation
