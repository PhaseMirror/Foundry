import Std

theorem range_map_perm (N : Nat) (σ : Nat → Nat)
    (hRange : ∀ d, d < N → σ d < N) (hInv : ∀ d, d < N → σ (σ d) = d) :
    (List.map σ (List.range N)).Perm (List.range N) := by
  sorry
