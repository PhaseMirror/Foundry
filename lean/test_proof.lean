def foo (util_pred conf : Nat) : util_pred < 9000 ∧ conf ≥ 9950 := by
  have h : (decide (util_pred < 9000) && decide (conf ≥ 9950)) = true := sorry
  have h1 : decide (util_pred < 9000) = true ∧ decide (conf ≥ 9950) = true := by
    rw [Bool.and_eq_true] at h
    exact h
  exact ⟨of_decide_eq_true h1.1, of_decide_eq_true h1.2⟩
