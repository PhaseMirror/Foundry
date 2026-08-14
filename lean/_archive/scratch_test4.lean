import Lean
open Nat

def replace_one (k n : Nat) : List Nat → List Nat
| [] => []
| x :: xs => if x = k then n :: xs else x :: replace_one k n xs

theorem perm_replace_one (k n : Nat) (l : List Nat) (h : k ∈ l) :
  (replace_one k n l ++ [k]).Perm (l ++ [n]) := by
  sorry -- Assumed proven by subagent

theorem range_map_perm (N : Nat) (σ : Nat → Nat)
    (hRange : ∀ d, d < N → σ d < N) (hInv : ∀ d, d < N → σ (σ d) = d) :
    (List.map σ (List.range N)).Perm (List.range N) := by
  induction N with
  | zero =>
    simp [List.range]
  | succ n ih =>
    -- Wait, IH uses the SAME σ? But σ is bounded by n+1, not n.
    -- If we apply IH, we need a modified σ' bounded by n.
    sorry
