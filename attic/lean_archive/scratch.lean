import F1.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

def replace_one (k n : Nat) : List Nat → List Nat
| [] => []
| x :: xs => if x = k then n :: xs else x :: replace_one k n xs

theorem perm_replace_one (k n : Nat) (l : List Nat) (h : k ∈ l) :
  (replace_one k n l ++ [k]).Perm (l ++ [n]) := by
  induction l with
  | nil => contradiction
  | cons x xs ih =>
    unfold replace_one
    split
    · next hx =>
      have hxk : x = k := hx
      rw [hxk]
      have p1 : (xs ++ [k]).Perm (k :: xs) := List.perm_append_comm
      have p1' : (n :: (xs ++ [k])).Perm (n :: k :: xs) := List.Perm.cons n p1
      have p2 : (n :: k :: xs).Perm (k :: n :: xs) := List.Perm.swap k n xs
      have p3_aux : ([n] ++ xs).Perm (xs ++ [n]) := List.perm_append_comm
      have p3 : (k :: n :: xs).Perm (k :: (xs ++ [n])) := List.Perm.cons k p3_aux
      exact List.Perm.trans p1' (List.Perm.trans p2 p3)
    · next hx =>
      have h_in : k ∈ xs := by
        cases h with
        | head => contradiction
        | tail _ h_tail => exact h_tail
      have p1 : (x :: replace_one k n xs ++ [k]) = (x :: (replace_one k n xs ++ [k])) := by rfl
      rw [p1]
      have p2 : (x :: xs ++ [n]) = (x :: (xs ++ [n])) := by rfl
      rw [p2]
      exact List.Perm.cons x (ih h_in)

theorem map_sigma_eq_of_not_mem (σ : Nat → Nat) (n k : Nat) (σ' : Nat → Nat)
    (h_sigma' : ∀ x, σ' x = if σ x = n then k else σ x)
    (l : List Nat)
    (hl : k ∉ l)
    (h_not_n : ∀ x ∈ l, σ x ≠ n) :
    List.map σ' l = List.map σ l := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    have hx_in : x ∈ x :: xs := List.Mem.head xs
    have h1 : σ x ≠ n := h_not_n x hx_in
    have h2 : σ' x = σ x := by rw [h_sigma', if_neg h1]
    have h3 : k ∉ xs := fun h => hl (List.Mem.tail x h)
    have h4 : ∀ y ∈ xs, σ y ≠ n := fun y hy => h_not_n y (List.Mem.tail x hy)
    rw [List.map_cons, List.map_cons, h2, ih h3 h4]

theorem map_sigma_eq_replace_one (σ : Nat → Nat) (n k : Nat) (σ' : Nat → Nat)
    (h_sigma' : ∀ x, σ' x = if σ x = n then k else σ x)
    (h_k : σ k = n)
    (h_not_n : ∀ x ∈ l, x ≠ k → σ x ≠ n)
    (h_not_k : ∀ x ∈ l, x ≠ k → σ x ≠ k)
    (l : List Nat)
    (h_nodup : l.Nodup) :
    List.map σ l = replace_one k n (List.map σ' l) := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    rw [List.map_cons, List.map_cons]
    have h_nodup_xs : xs.Nodup := List.Nodup.of_cons h_nodup
    have h_not_mem : x ∉ xs := List.Nodup.not_mem h_nodup
    have h_sigma'x : σ' x = if σ x = n then k else σ x := h_sigma' x
    if h_eq : x = k then
      have h1 : σ x = n := by rw [h_eq, h_k]
      have h2 : σ' x = k := by rw [h_sigma'x, if_pos h1]
      rw [h2]
      unfold replace_one
      rw [if_pos rfl]
      have h3 : k ∉ xs := by rw [←h_eq]; exact h_not_mem
      have h4 : ∀ y ∈ xs, σ y ≠ n := by
        intro y hy
        have y_neq_k : y ≠ k := fun h_yk => h3 (h_yk ▸ hy)
        exact h_not_n y (List.Mem.tail x hy) y_neq_k
      have h5 : List.map σ' xs = List.map σ xs := map_sigma_eq_of_not_mem σ n k σ' h_sigma' xs h3 h4
      rw [h1, h5]
    else
      have hx_in : x ∈ x :: xs := List.Mem.head xs
      have h1 : σ x ≠ n := h_not_n x hx_in h_eq
      have h2 : σ' x = σ x := by rw [h_sigma'x, if_neg h1]
      rw [h2]
      unfold replace_one
      have h3 : σ x ≠ k := h_not_k x hx_in h_eq
      rw [if_neg h3]
      have h_not_n_xs : ∀ y ∈ xs, y ≠ k → σ y ≠ n := fun y hy => h_not_n y (List.Mem.tail x hy)
      have h_not_k_xs : ∀ y ∈ xs, y ≠ k → σ y ≠ k := fun y hy => h_not_k y (List.Mem.tail x hy)
      rw [ih h_nodup_xs h_not_n_xs h_not_k_xs]

theorem range_map_perm (N : Nat) : ∀ (σ : Nat → Nat)
    (hRange : ∀ d, d < N → σ d < N) (hInv : ∀ d, d < N → σ (σ d) = d),
    (List.map σ (List.range N)).Perm (List.range N) := by
  induction N with
  | zero =>
    intro σ hR hI
    exact List.Perm.refl _
  | succ n ih =>
    intro σ hRange hInv
    let k := σ n
    have hk_lt : k ≤ n := Nat.lt_succ_iff.mp (hRange n (Nat.lt_succ_self n))
    have h_range_succ : List.range (n + 1) = List.range n ++ [n] := List.range_succ n

    if hk_eq : k = n then
      have hRange_n : ∀ d < n, σ d < n := by
        intro d hd
        have h1 : σ d < n + 1 := hRange d (Nat.lt_trans hd (Nat.lt_succ_self n))
        have h2 : σ d ≠ n := by
          intro h_eq
          have h_d_eq_n : d = n := by
            calc d = σ (σ d) := (hInv d (Nat.lt_trans hd (Nat.lt_succ_self n))).symm
            _ = σ n := by rw [h_eq]
            _ = n := hk_eq
          omega
        omega
      have hInv_n : ∀ d < n, σ (σ d) = d := fun d hd => hInv d (Nat.lt_trans hd (Nat.lt_succ_self n))
      have ih_n := ih σ hRange_n hInv_n
      rw [h_range_succ]
      have h_map_succ : List.map σ (List.range n ++ [n]) = List.map σ (List.range n) ++ [n] := by
        rw [List.map_append, List.map_singleton]
        exact congrArg _ hk_eq
      rw [h_map_succ]
      exact List.Perm.append_right [n] ih_n
    else
      have h_k_lt_n : k < n := by omega
      let σ' := fun x => if σ x = n then k else σ x
      have h_k_val : σ k = n := by
        calc σ k = σ (σ n) := rfl
        _ = n := hInv n (Nat.lt_succ_self n)
      have hd_eq_k_of_eq_n : ∀ d < n, σ d = n → d = k := by
        intro d hd h_eq
        calc d = σ (σ d) := (hInv d (Nat.lt_trans hd (Nat.lt_succ_self n))).symm
        _ = σ n := by rw [h_eq]
        _ = k := rfl
      have hk_eq_d_of_eq_k : ∀ d < n, σ d = k → d = n := by
        intro d hd h_eq
        have h1 : σ (σ d) = σ k := by rw [h_eq]
        have h2 : σ (σ d) = d := hInv d (Nat.lt_trans hd (Nat.lt_succ_self n))
        rw [h2, h_k_val] at h1
        exact h1

      have hRange' : ∀ d, d < n → σ' d < n := by
        intro d hd
        unfold σ'
        split
        · next h_eq =>
          have hdk : d = k := hd_eq_k_of_eq_n d hd h_eq
          rw [← hdk]
          exact hd
        · next h_neq =>
          have h1 : σ d < n + 1 := hRange d (Nat.lt_trans hd (Nat.lt_succ_self n))
          omega

      have hInv' : ∀ d, d < n → σ' (σ' d) = d := by
        intro d hd
        unfold σ'
        split
        · next h1 =>
          have hdk : d = k := hd_eq_k_of_eq_n d hd h1
          have h2 : σ k = n := h_k_val
          have h_if : (if σ k = n then k else σ k) = k := if_pos h2
          rw [h_if, ← hdk]
        · next h1 =>
          have h2 : σ d < n := by
            have h3 : σ d < n + 1 := hRange d (Nat.lt_trans hd (Nat.lt_succ_self n))
            omega
          have h_if : (if σ (σ d) = n then k else σ (σ d)) = σ (σ d) := by
            have h3 : σ (σ d) = d := hInv d (Nat.lt_trans hd (Nat.lt_succ_self n))
            rw [h3]
            have h4 : d ≠ n := by omega
            exact if_neg h4
          rw [h_if]
          exact hInv d (Nat.lt_trans hd (Nat.lt_succ_self n))

      have ih' := ih σ' hRange' hInv'
      have h_sigma' : ∀ x, σ' x = if σ x = n then k else σ x := fun x => rfl
      have h_not_n : ∀ x ∈ List.range n, x ≠ k → σ x ≠ n := by
        intro x hx h_neq h_eq
        have hx_lt : x < n := List.mem_range.mp hx
        have hxk : x = k := hd_eq_k_of_eq_n x hx_lt h_eq
        exact h_neq hxk
      have h_not_k : ∀ x ∈ List.range n, x ≠ k → σ x ≠ k := by
        intro x hx h_neq h_eq
        have hx_lt : x < n := List.mem_range.mp hx
        have hxn : x = n := hk_eq_d_of_eq_k x hx_lt h_eq
        omega
      have h_nodup : (List.range n).Nodup := List.nodup_range n
      
      have h_map_eq : List.map σ (List.range n) = replace_one k n (List.map σ' (List.range n)) :=
        map_sigma_eq_replace_one σ n k σ' h_sigma' h_k_val h_not_n h_not_k (List.range n) h_nodup
        
      rw [h_range_succ]
      have h_map_succ : List.map σ (List.range n ++ [n]) = List.map σ (List.range n) ++ [k] := by
        rw [List.map_append, List.map_singleton]
        rfl
        
      rw [h_map_succ, h_map_eq]
      
      have h_k_in_range : k ∈ List.range n := List.mem_range.mpr h_k_lt_n
      have h_k_in_map : k ∈ List.map σ' (List.range n) := by
        -- Use ih' : List.map σ' (List.range n) ~ List.range n
        exact List.Perm.subset ih'.symm h_k_in_range
        
      have h_perm1 : (replace_one k n (List.map σ' (List.range n)) ++ [k]).Perm (List.map σ' (List.range n) ++ [n]) :=
        perm_replace_one k n (List.map σ' (List.range n)) h_k_in_map
        
      have h_perm2 : (List.map σ' (List.range n) ++ [n]).Perm (List.range n ++ [n]) :=
        List.Perm.append_right [n] ih'
        
      exact List.Perm.trans h_perm1 h_perm2

end UOR.Bridge.F1Square.Analysis
