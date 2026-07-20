import META_RELATIVITY.Core

/-!
# META_RELATIVITY Gate Theorems

Gate implication theorems and concrete witness verification.
All proofs are pure propositional logic over Nat inequalities — no axioms, no sorry.
-/

namespace META_RELATIVITY

/-! ## Concrete Witness Verification -/

/-- Gate1 validity of the standard witness. -/
private theorem std_g1_valid : ({ f_nl := 0, coupling_strength := 500 } : Gate1).is_valid := by
  show 0 = 0 ∧ 500 ≤ 1000
  exact ⟨rfl, by omega⟩

/-- Gate2 validity of the standard witness. -/
private theorem std_g2_valid : ({ theta_1 := 20000 } : Gate2).is_valid := by
  show dist 20000 20000 < 4000
  simp only [dist]
  split <;> omega

/-- Gate3 validity of the standard witness. -/
private theorem std_g3_valid : ({ a := 3000000 } : Gate3).is_valid := by
  show 2000000 ≤ 3000000 ∧ 3000000 ≤ 5000000
  exact ⟨by omega, by omega⟩

/-- Gate4 validity of the standard witness. -/
private theorem std_g4_valid : ({ beta_lambda_8 := 1, beta_lambda_6 := 100, delta_c_ratio := 0 } : Gate4).is_valid := by
  show 1 * 100 < 100 * 3 ∧ 0 < 400
  exact ⟨by omega, by omega⟩

/-- The standard witness satisfies Gate5. -/
theorem valid_witness_is_valid :
    ({ g1 := { f_nl := 0, coupling_strength := 500 }
       g2 := { theta_1 := 20000 }
       g3 := { a := 3000000 }
       g4 := { beta_lambda_8 := 1, beta_lambda_6 := 100, delta_c_ratio := 0 } } : Gate5).is_valid :=
  ⟨std_g1_valid, std_g2_valid, std_g3_valid, std_g4_valid⟩

/-- Gate3 bounds follow from Gate5 validity of the standard witness. -/
theorem valid_witness_gate3 :
    2000000 ≤ 3000000 ∧ 3000000 ≤ 5000000 :=
  ⟨by omega, by omega⟩

/-! ## Gate 3 Band Properties -/

/-- Gate 3 band [200·scale, 500·scale] is non-empty. -/
theorem gate3_band_nonempty : ∃ a, 2000000 ≤ a ∧ a ≤ 5000000 :=
  ⟨3000000, by omega, by omega⟩

/-- Gate 3 band width is 300·scale. -/
theorem gate3_band_width : 5000000 - 2000000 = 3000000 := by omega

/-! ## Gate 4 Hierarchy Properties -/

/-- If beta_lambda_8 = 0, Gate4 beta constraint is trivially satisfied. -/
theorem gate4_beta_zero_satisfied (g : Gate4) (h8 : g.beta_lambda_8 = 0)
    (h6 : g.beta_lambda_6 > 0) :
    g.beta_lambda_8 * 100 < g.beta_lambda_6 * 3 := by
  omega

/-! ## Gate 5 Chain Composition -/

/-- Gate 5 is the conjunction of four gate validities. -/
theorem gate5_decompose (g5 : Gate5) :
    g5.is_valid ↔ g5.g1.is_valid ∧ g5.g2.is_valid ∧ g5.g3.is_valid ∧ g5.g4.is_valid :=
  Iff.rfl

/-- Gate 5 validity is preserved under Gate1 field update that maintains validity. -/
theorem gate5_update_g1_preserves (g5 : Gate5) (h : g5.is_valid)
    (g1' : Gate1) (hg1 : g1'.is_valid) :
    (⟨g1', g5.g2, g5.g3, g5.g4⟩ : Gate5).is_valid :=
  ⟨hg1, h.right.left, h.right.right.left, h.right.right.right⟩

/-- Gate 5 validity is preserved under Gate3 field update that maintains validity. -/
theorem gate5_update_g3_preserves (g5 : Gate5) (h : g5.is_valid)
    (g3' : Gate3) (hg3 : g3'.is_valid) :
    (⟨g5.g1, g5.g2, g3', g5.g4⟩ : Gate5).is_valid :=
  ⟨h.left, h.right.left, hg3, h.right.right.right⟩

/-! ## Multiple Witnesses -/

/-- Second witness Gate2 validity (theta=18000). -/
private theorem w2_g2_valid : ({ theta_1 := 18000 } : Gate2).is_valid := by
  show dist 18000 20000 < 4000
  simp only [dist]
  split <;> omega

/-- Second witness Gate3 validity (a=2500000). -/
private theorem w2_g3_valid : ({ a := 2500000 } : Gate3).is_valid := by
  show 2000000 ≤ 2500000 ∧ 2500000 ≤ 5000000
  exact ⟨by omega, by omega⟩

/-- Second witness is also valid (theta=18000, coupling=0, a=2500000). -/
theorem valid_witness_2_is_valid :
    ({ g1 := { f_nl := 0, coupling_strength := 0 }
       g2 := { theta_1 := 18000 }
       g3 := { a := 2500000 }
       g4 := { beta_lambda_8 := 0, beta_lambda_6 := 100, delta_c_ratio := 399 } } : Gate5).is_valid := by
  refine ⟨?_, w2_g2_valid, w2_g3_valid, ?_⟩
  · show 0 = 0 ∧ 0 ≤ 1000
    exact ⟨rfl, by omega⟩
  · show 0 * 100 < 100 * 3 ∧ 399 < 400
    exact ⟨by omega, by omega⟩

/-! ## Invalid Witness Rejection -/

/-- Invalid witness is rejected by Gate1: f_nl = 1 ≠ 0. -/
theorem invalid_witness_fnl_rejected :
    ¬ Gate1.is_valid { f_nl := 1, coupling_strength := 500 } := by
  simp only [Gate1.is_valid]
  omega

end META_RELATIVITY
