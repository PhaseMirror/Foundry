/-
F1 square — **the Real additive-group normalizer** (`RsumL` canonical form).

The UOR canonical-form (κ) methodology applied to additive expressions: the substrate's
`ring_uor` is Int/Q-only, and on `Real` the only pointwise route (`Req_of_seq_Qeq`) clears
denominators *multiplicatively*, so any atom occurring 3+ times (e.g. `a²` in `3a²`) blows the
normal form past `ring_uor`. The fix is to canonicalize the ADDITIVE structure directly: a
`Radd`/`Rneg`/`Rsub` tree is normalized to the sum of a **list of signed-atom summands**
(`RsumL`), and equality is decided by the *multiset* — permutation-invariance
(`RsumL_perm`) plus pairwise cancellation (`RsumL_cancel_head`). This never touches `.seq`, so
there is no denominator blow-up; it is the abelian-group analogue of `ring_uor`, and it is the
reusable engine for the γ₂ regularity (cubic-log telescoping), the `λₙ` assemblies, and beyond.

`RsumL l = l.foldr Radd 0`. The flattening lemmas (`RsumL_append`, `RsumL_map_Rneg`) turn any
tree into a list; `RsumL_perm` + `RsumL_cancel_head` reduce two lists to a common canonical
multiset.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

/-- `−0 ≈ 0`. -/
private theorem Rneg_zero' : Req (Rneg zero) zero :=
  Req_trans (Req_symm (Radd_zero (Rneg zero))) (Req_trans (Radd_comm (Rneg zero) zero) (Radd_neg zero))

/-- The **canonical additive form**: the sum `x₀ + (x₁ + (… + 0))` of a list of summands. -/
def RsumL : List Real → Real
  | [] => zero
  | x :: xs => Radd x (RsumL xs)

@[simp] theorem RsumL_nil : RsumL [] = zero := rfl
@[simp] theorem RsumL_cons (x : Real) (xs : List Real) :
    RsumL (x :: xs) = Radd x (RsumL xs) := rfl

/-- Cons is a congruence in the head (up to `Req`). -/
theorem RsumL_cons_congr {x x' : Real} (l : List Real) (h : Req x x') :
    Req (RsumL (x :: l)) (RsumL (x' :: l)) :=
  Radd_congr h (Req_refl _)

/-- Swapping the first two summands. -/
theorem RsumL_swap_head (x y : Real) (l : List Real) :
    Req (RsumL (x :: y :: l)) (RsumL (y :: x :: l)) := by
  show Req (Radd x (Radd y (RsumL l))) (Radd y (Radd x (RsumL l)))
  refine Req_trans (Req_symm (Radd_assoc x y (RsumL l))) ?_
  exact Req_trans (Radd_congr (Radd_comm x y) (Req_refl _)) (Radd_assoc y x (RsumL l))

/-- **PERMUTATION INVARIANCE** — the canonical sum depends only on the multiset of summands. -/
theorem RsumL_perm {l l' : List Real} (h : l.Perm l') : Req (RsumL l) (RsumL l') := by
  induction h with
  | nil => exact Req_refl _
  | cons x _ ih => exact Radd_congr (Req_refl x) ih
  | swap x y l => exact RsumL_swap_head y x l
  | trans _ _ ih₁ ih₂ => exact Req_trans ih₁ ih₂

/-- **PAIRWISE CANCELLATION** at the head: `x + (−x) + rest ≈ rest`. -/
theorem RsumL_cancel_head (x : Real) (l : List Real) :
    Req (RsumL (x :: Rneg x :: l)) (RsumL l) := by
  show Req (Radd x (Radd (Rneg x) (RsumL l))) (RsumL l)
  refine Req_trans (Req_symm (Radd_assoc x (Rneg x) (RsumL l))) ?_
  refine Req_trans (Radd_congr (Radd_neg x) (Req_refl _)) ?_
  exact Req_trans (Radd_comm zero (RsumL l)) (Radd_zero (RsumL l))

/-- Flattening: the sum of an appended list splits as `Radd`. -/
theorem RsumL_append (l l' : List Real) :
    Req (RsumL (l ++ l')) (Radd (RsumL l) (RsumL l')) := by
  induction l with
  | nil => exact Req_trans (Req_refl _) (Req_symm (Req_trans (Radd_comm zero (RsumL l'))
      (Radd_zero (RsumL l'))))
  | cons x xs ih =>
      show Req (Radd x (RsumL (xs ++ l'))) (Radd (Radd x (RsumL xs)) (RsumL l'))
      refine Req_trans (Radd_congr (Req_refl x) ih) ?_
      exact Req_symm (Radd_assoc x (RsumL xs) (RsumL l'))

/-- **Head cancels its negation anywhere in the tail** (choice-free, structural — no `decide`
    on `List.Perm`, whose `Decidable` instance pulls `Classical.choice`): `x + (l₁ + (−x) + l₂)
    ≈ l₁ + l₂`. -/
theorem RsumL_cancel_cons (x : Real) : ∀ (l₁ l₂ : List Real),
    Req (RsumL (x :: (l₁ ++ Rneg x :: l₂))) (RsumL (l₁ ++ l₂))
  | [], l₂ => RsumL_cancel_head x l₂
  | y :: l₁', l₂ =>
      Req_trans (RsumL_swap_head x y (l₁' ++ Rneg x :: l₂))
        (Radd_congr (Req_refl y) (RsumL_cancel_cons x l₁' l₂))

/-- **Cancel a ± pair at known positions** (the ergonomic, choice-free cancellation): give the
    segments `l₁` (before `x`), `l₂` (between `x` and `−x`), `l₃` (after), and the pair drops. -/
theorem RsumL_cancel_anywhere (x : Real) (l₁ l₂ l₃ : List Real) :
    Req (RsumL (l₁ ++ x :: (l₂ ++ Rneg x :: l₃))) (RsumL (l₁ ++ (l₂ ++ l₃))) := by
  refine Req_trans (RsumL_append l₁ (x :: (l₂ ++ Rneg x :: l₃))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (RsumL_cancel_cons x l₂ l₃)) ?_
  exact Req_symm (RsumL_append l₁ (l₂ ++ l₃))

/-- A single leaf as a one-element canonical sum: `x ≈ RsumL [x]`. -/
theorem RsumL_singleton (x : Real) : Req x (RsumL [x]) :=
  Req_symm (Req_trans (Radd_congr (Req_refl x) (RsumL_nil ▸ Req_refl zero)) (Radd_zero x))

/-- `Radd x y ≈ RsumL [x, y]` — binary flattening. -/
theorem Radd_eq_RsumL (x y : Real) : Req (Radd x y) (RsumL [x, y]) := by
  show Req (Radd x y) (Radd x (Radd y zero))
  exact Radd_congr (Req_refl x) (Req_symm (Radd_zero y))

/-- `(x + y) + z ≈ RsumL [x, y, z]` — ternary flattening. -/
theorem Radd_eq_RsumL3 (x y z : Real) : Req (Radd (Radd x y) z) (RsumL [x, y, z]) := by
  show Req (Radd (Radd x y) z) (Radd x (Radd y (Radd z zero)))
  refine Req_trans (Radd_assoc x y z) ?_
  exact Radd_congr (Req_refl x) (Radd_congr (Req_refl y) (Req_symm (Radd_zero z)))

/-- **Decidable permutations via ℕ-indices** — the ergonomic engine. `Real` has no
    `DecidableEq`, so `List.Perm` of `Real`-lists can't be `decide`d; but a permutation of the
    underlying ℕ-index lists IS decidable, and `List.Perm.map` transports it. So an additive
    identity reduces to: write both sides as `RsumL (il.map f)` / `RsumL (il'.map f)`, then
    `RsumL_perm_map f (by decide)`. -/
theorem RsumL_perm_map (f : Nat → Real) {il il' : List Nat} (h : il.Perm il') :
    Req (RsumL (il.map f)) (RsumL (il'.map f)) :=
  RsumL_perm (h.map f)

/-- Negation distributes over the canonical sum: `−(Σ l) ≈ Σ (map Rneg l)`. -/
theorem RsumL_map_Rneg (l : List Real) :
    Req (Rneg (RsumL l)) (RsumL (l.map Rneg)) := by
  induction l with
  | nil => exact Rneg_zero'
  | cons x xs ih =>
      show Req (Rneg (Radd x (RsumL xs))) (Radd (Rneg x) (RsumL (xs.map Rneg)))
      exact Req_trans (Rneg_Radd x (RsumL xs)) (Radd_congr (Req_refl _) ih)

end UOR.Bridge.F1Square.Analysis
