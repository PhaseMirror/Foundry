import MQEM.Types

/-!
# MQEM.Weighting — Normalized Multi-Scale Trophic Weighting

Formalizes the normalized multi-scale weighting from M³EM Eq. (2):
  w_i(t) = s_i^{-beta(t)} / sum_j s_j^{-beta(t)}

Under discrete integer scaling.
-/

namespace MQEM

/-- Sum of a list of positive scale weights. -/
def sum_weights : List Nat → Nat
  | [] => 0
  | w :: ws => w + sum_weights ws

/-- Multi-scale weight normalization: (w_i * 1000) / sum_weights. -/
def normalize_weight (w_i : Nat) (total_sum : Nat) : Nat :=
  if total_sum = 0 then 0
  else (w_i * 1000) / total_sum

/-- Theorem: Normalizing against single isolated weight w yields 1000 (unit normalized weight). -/
theorem single_weight_normalizes_to_one (w : Nat) (h_pos : w > 0) :
    normalize_weight w w = 1000 := by
  dsimp [normalize_weight]
  have h_ne : ¬ w = 0 := Nat.ne_of_gt h_pos
  rw [if_neg h_ne]
  exact Nat.mul_div_cancel_left 1000 h_pos

/-- Theorem: Zero raw weight normalizes to zero. -/
theorem zero_weight_normalizes_to_zero (total : Nat) :
    normalize_weight 0 total = 0 := by
  dsimp [normalize_weight]
  split
  · rfl
  · simp

end MQEM
