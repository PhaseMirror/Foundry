namespace dynamics.XIFormal

/-- Scale for discrete integer math: 10000 = 1.0 -/
def scale : Nat := 10000

/-- Absolute difference for Nat. -/
def dist (x y : Nat) : Nat :=
  if x ≥ y then x - y else y - x

theorem dist_symmetric (x y : Nat) : dist x y = dist y x := by
  unfold dist
  split <;> split <;> omega

theorem dist_nonneg (x y : Nat) : dist x y ≥ 0 := by
  unfold dist
  split <;> omega

theorem dist_zero_iff (x y : Nat) : dist x y = 0 ↔ x = y := by
  unfold dist
  constructor
  · intro h
    split at h <;> omega
  · intro h
    split <;> omega

/-- Discrete Banach contraction -/
def is_contraction (f : Nat → Nat) (kappa : Nat) : Prop :=
  kappa < scale ∧ ∀ x y, dist (f x) (f y) * scale ≤ kappa * dist x y

/-- Operator T is a stable attractor if it is a contraction on the discrete space -/
def is_stable_attractor (T : Nat → Nat) : Prop :=
  ∃ kappa, is_contraction T kappa

theorem stable_attractor_unique (T : Nat → Nat) (h : is_stable_attractor T) (x y : Nat) 
  (hx : T x = x) (hy : T y = y) : x = y := by
  rcases h with ⟨k, hk_lt, hk_dist⟩
  have h_dist := hk_dist x y
  rw [hx, hy] at h_dist
  have h_pos : dist x y = 0 := by
    cases h_d : dist x y with
    | zero => rfl
    | succ d' =>
      have hd_pos : 0 < d' + 1 := Nat.zero_lt_succ d'
      have h_lt : k * (d' + 1) < scale * (d' + 1) := Nat.mul_lt_mul_of_pos_right hk_lt hd_pos
      rw [h_d] at h_dist
      rw [Nat.mul_comm] at h_dist
      omega
  exact dist_zero_iff x y |>.mp h_pos

end dynamics.XIFormal
