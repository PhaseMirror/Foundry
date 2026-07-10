import META_RELATIVITY.Core

namespace META_RELATIVITY

/-- Theorem: If Gate 5 is valid, then the correlation slope A is bounded by [200 * scale, 500 * scale]. -/
theorem gate5_implies_g3_bounds (g5 : Gate5) (h : g5.is_valid) : 
  200 * scale ≤ g5.g3.a ∧ g5.g3.a ≤ 500 * scale := by
  unfold Gate5.is_valid at h
  unfold Gate3.is_valid at h
  exact h.right.right.left

end META_RELATIVITY
