import Lean

def replace_one (k n : Nat) : List Nat → List Nat
| [] => []
| x :: xs => if x = k then n :: xs else x :: replace_one k n xs

-- Assume perm_replace_one is proven
axiom perm_replace_one (k n : Nat) (l : List Nat) (h : k ∈ l) :
  (replace_one k n l ++ [k]).Perm (l ++ [n])

-- STRATEGY FOR range_map_perm:
-- 1. For N = n + 1, let k = σ n.
-- 2. Define σ' x = if σ x = n then k else σ x.
-- 3. Prove σ' is an involution on {0..n-1} and bounded by n.
-- 4. Apply IH to σ' to get (map σ' (range n)).Perm (range n).
-- 5. Prove map σ (range n) = replace_one k n (map σ' (range n)).
-- 6. We have map σ (range (n+1)) = map σ (range n) ++ [k].
-- 7. Which is replace_one k n (map σ' (range n)) ++ [k].
-- 8. By perm_replace_one, this is Perm to (map σ' (range n)) ++ [n].
-- 9. Which is Perm to range n ++ [n] = range (n+1).
