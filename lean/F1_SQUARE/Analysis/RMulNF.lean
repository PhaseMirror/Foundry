/-
F1 square — **the Real multiplicative normalizer** (`RprodL` canonical form), the κ-form companion of
`RAddNF`.

The substrate has `ring_uor` only on ℤ/ℚ, and on `Real` the pointwise route (`Req_of_seq_Qeq`) cannot
see through `Rmul`'s Bishop reindexing — so MULTIPLICATIVE identities had no tactic, exactly as
ADDITIVE ones had none before `RAddNF`. The fix is the same UOR canonical-form (κ) move applied to the
multiplicative monoid: a `Rmul` tree is normalized to the product of a **list of factors** (`RprodL`),
and equality is decided by the *multiset* — permutation-invariance (`RprodL_perm`) via the genuine
`Rmul` commutativity/associativity. (Unlike `RAddNF` there is no cancellation layer: `Real` has no
universal multiplicative inverse, so `RprodL` is permutation-only — which is all that degree-`d`
monomial normalization needs.) Together `RAddNF` (sum of signed atoms) and `RMulNF` (product of
factors) are the reusable abelian-monoid engines that stand in for a `Real` `ring` tactic: expand a
polynomial identity to a sum of monomials, normalize each monomial with `RprodL_perm`, and match the
sum with `RsumL_perm` — e.g. the Brahmagupta–Fibonacci `|zw|² = |z|²|w|²`.

`RprodL l = l.foldr Rmul one`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

/-- The **canonical multiplicative form**: the product `x₀ · (x₁ · (… · 1))` of a list of factors. -/
def RprodL : List Real → Real
  | [] => one
  | x :: xs => Rmul x (RprodL xs)

@[simp] theorem RprodL_nil : RprodL [] = one := rfl
@[simp] theorem RprodL_cons (x : Real) (xs : List Real) :
    RprodL (x :: xs) = Rmul x (RprodL xs) := rfl

/-- Cons is a congruence in the head (up to `Req`). -/
theorem RprodL_cons_congr {x x' : Real} (l : List Real) (h : Req x x') :
    Req (RprodL (x :: l)) (RprodL (x' :: l)) :=
  Rmul_congr h (Req_refl _)

/-- Swapping the first two factors. -/
theorem RprodL_swap_head (x y : Real) (l : List Real) :
    Req (RprodL (x :: y :: l)) (RprodL (y :: x :: l)) := by
  show Req (Rmul x (Rmul y (RprodL l))) (Rmul y (Rmul x (RprodL l)))
  refine Req_trans (Req_symm (Rmul_assoc x y (RprodL l))) ?_
  exact Req_trans (Rmul_congr (Rmul_comm x y) (Req_refl _)) (Rmul_assoc y x (RprodL l))

/-- **PERMUTATION INVARIANCE** — the canonical product depends only on the multiset of factors. -/
theorem RprodL_perm {l l' : List Real} (h : l.Perm l') : Req (RprodL l) (RprodL l') := by
  induction h with
  | nil => exact Req_refl _
  | cons x _ ih => exact Rmul_congr (Req_refl x) ih
  | swap x y l => exact RprodL_swap_head y x l
  | trans _ _ ih₁ ih₂ => exact Req_trans ih₁ ih₂

/-- Flattening: the product of an appended list splits as `Rmul`. -/
theorem RprodL_append (l l' : List Real) :
    Req (RprodL (l ++ l')) (Rmul (RprodL l) (RprodL l')) := by
  induction l with
  | nil => exact Req_trans (Req_refl _) (Req_symm (Req_trans (Rmul_comm one (RprodL l'))
      (Rmul_one (RprodL l'))))
  | cons x xs ih =>
      show Req (Rmul x (RprodL (xs ++ l'))) (Rmul (Rmul x (RprodL xs)) (RprodL l'))
      refine Req_trans (Rmul_congr (Req_refl x) ih) ?_
      exact Req_symm (Rmul_assoc x (RprodL xs) (RprodL l'))

/-- A single leaf as a one-element canonical product: `x ≈ RprodL [x]`. -/
theorem RprodL_singleton (x : Real) : Req x (RprodL [x]) :=
  Req_symm (Req_trans (Rmul_congr (Req_refl x) (RprodL_nil ▸ Req_refl one)) (Rmul_one x))

/-- `Rmul x y ≈ RprodL [x, y]` — binary flattening. -/
theorem Rmul_eq_RprodL (x y : Real) : Req (Rmul x y) (RprodL [x, y]) := by
  show Req (Rmul x y) (Rmul x (Rmul y one))
  exact Rmul_congr (Req_refl x) (Req_symm (Rmul_one y))

/-- `(x · y) · z ≈ RprodL [x, y, z]` — ternary flattening. -/
theorem Rmul_eq_RprodL3 (x y z : Real) : Req (Rmul (Rmul x y) z) (RprodL [x, y, z]) := by
  show Req (Rmul (Rmul x y) z) (Rmul x (Rmul y (Rmul z one)))
  refine Req_trans (Rmul_assoc x y z) ?_
  exact Rmul_congr (Req_refl x) (Rmul_congr (Req_refl y) (Req_symm (Rmul_one z)))

/-- **Decidable permutations via ℕ-indices** — the ergonomic engine (mirrors `RsumL_perm_map`).
    `Real` has no `DecidableEq`, but a permutation of the underlying ℕ-index lists IS decidable and
    `List.Perm.map` transports it: write both monomials as `RprodL (il.map f)` / `RprodL (il'.map f)`
    and discharge with `RprodL_perm_map f (by decide)`. -/
theorem RprodL_perm_map (f : Nat → Real) {il il' : List Nat} (h : il.Perm il') :
    Req (RprodL (il.map f)) (RprodL (il'.map f)) :=
  RprodL_perm (h.map f)

/-- Degree-4 flattening: `(x·y)·(z·w) ≈ RprodL [x,y,z,w]` — the entry point for monomial normalization. -/
theorem Rmul_pair_eq_RprodL4 (x y z w : Real) :
    Req (Rmul (Rmul x y) (Rmul z w)) (RprodL [x, y, z, w]) :=
  Req_trans (Rmul_congr (Rmul_eq_RprodL x y) (Rmul_eq_RprodL z w))
    (Req_symm (RprodL_append [x, y] [z, w]))

/-- **Validation / building block — the square law** `(a·c)² ≈ a²·c²` (factor multiset
    `{a,c,a,c} = {a,a,c,c}`), via `RprodL_perm_map` on the ℕ-index lists. The monomial atom for
    `|z|²·|w|²`. -/
theorem prod_sq_reassoc (a c : Real) :
    Req (Rmul (Rmul a c) (Rmul a c)) (Rmul (Rmul a a) (Rmul c c)) := by
  refine Req_trans (Rmul_pair_eq_RprodL4 a c a c) ?_
  -- [a,c,a,c] ~ [a,a,c,c]  (explicit, choice-free — `decide` on `List.Perm` would pull choice)
  refine Req_trans (RprodL_perm (List.Perm.cons a (List.Perm.swap a c [c]))) ?_
  exact Req_symm (Rmul_pair_eq_RprodL4 a a c c)

/-- **Validation / building block — the cross law** `(a·c)·(b·d) ≈ (a·d)·(b·c)` (both `= abcd`). The
    cross-term that CANCELS in `|zw|²`. -/
theorem prod_cross_reassoc (a b c d : Real) :
    Req (Rmul (Rmul a c) (Rmul b d)) (Rmul (Rmul a d) (Rmul b c)) := by
  refine Req_trans (Rmul_pair_eq_RprodL4 a c b d) ?_
  -- [a,c,b,d] ~ [a,d,b,c]  via  [c,b,d] ~ [b,c,d] ~ [b,d,c] ~ [d,b,c]  (explicit, choice-free)
  refine Req_trans (RprodL_perm (List.Perm.cons a
    ((List.Perm.swap b c [d]).trans
      ((List.Perm.cons b (List.Perm.swap d c [])).trans (List.Perm.swap d b [c]))))) ?_
  exact Req_symm (Rmul_pair_eq_RprodL4 a d b c)

end UOR.Bridge.F1Square.Analysis
