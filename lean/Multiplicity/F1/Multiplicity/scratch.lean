import Init

theorem range_map_perm (N : Nat) (σ : Nat → Nat)
    (_hRange : ∀ d, d < N → σ d < N) (_hInv : ∀ d, d < N → σ (σ d) = d)
    (h_perm : (List.map σ (List.range N)).Perm (List.range N)) :
    (List.map σ (List.range N)).Perm (List.range N) := h_perm
