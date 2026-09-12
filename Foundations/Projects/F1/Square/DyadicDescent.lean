/-
F1 square — **certified integration, brick 72** (`DyadicDescent.lean`): **EVERY DYADIC
SUB-INTERVAL LOWER-BOUNDS THE WHOLE** —

    `f ≥ 0`,  `j < 2^m`   ⟹   `∫_{a + j·w/2^m}^{a + (j+1)·w/2^m} f  ≤  ∫_a^{a+w} f`
      (`riemannIntegralI_ge_dyadic`).

This is the induction bricks 70 and 71 were built for, and it is the form "positive on a piece ⟹
positive overall" has to take before it is usable: the piece may be *arbitrarily small*, which is
what a locality argument needs.

The induction is on the depth. At depth `m+1` the index splits as `j = 2q` or `j = 2q+1`, and the
corresponding interval is exactly the left or right half of the depth-`m` interval at index `q` —
so brick 71's one-step bound applies and the inductive hypothesis finishes. The endpoints computed
along the two routes (`a + 2q·w/2^{m+1}` against `a + q·w/2^m`) are equal rationals but not equal
terms, which is precisely what `riemannIntegralI_congr_Q` exists to bridge.

Two mechanical points. The index `j` occurs inside the denominator-positivity *proof terms* the
statement carries, so it must be eliminated by `subst` — obtained from
`∃ q, j = 2q ∨ j = 2q+1` — and never by `rw`, which would not be type-correct. And the depth is
moved by `Nat.pow_succ` inside the `Qeq` goals only, where no proof terms live.

HONEST SCOPE. A lower bound by one dyadic sub-interval of an arbitrary interval, for a
non-negative Lipschitz integrand. It is **not** a subdivision identity (the pieces are not summed),
and it is not yet an `L²` definiteness statement: that additionally needs the constructive
location step — choosing the dyadic piece around a point of non-vanishing using only rational
comparisons, never a decidable order on reals. Integration substrate; nothing here touches the
Weil form. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.IntervalPiece
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The left endpoint of the `j`-th dyadic sub-interval of `[a, a+w]` at depth `m`. -/
def dyadA (a w : Q) (m j : Nat) : Q := add a (mul (⟨(j : Int), 2 ^ m⟩ : Q) w)

/-- Its width, `w/2^m`. -/
def dyadW (w : Q) (m : Nat) : Q := mul (⟨1, 2 ^ m⟩ : Q) w

theorem two_pow_pos (m : Nat) : 0 < 2 ^ m := Nat.pos_pow_of_pos m (by decide)

theorem dyadW_den {w : Q} (hw : 0 < w.den) (m : Nat) : 0 < (dyadW w m).den :=
  Qmul_den_pos (two_pow_pos m) hw

theorem dyadW_num {w : Q} (hwn : 0 ≤ w.num) (m : Nat) : 0 ≤ (dyadW w m).num :=
  Int.mul_nonneg (by show (0 : Int) ≤ 1; decide) hwn

theorem dyadA_den {a w : Q} (ha : 0 < a.den) (hw : 0 < w.den) (m j : Nat) :
    0 < (dyadA a w m j).den :=
  add_den_pos ha (Qmul_den_pos (two_pow_pos m) hw)

set_option maxHeartbeats 2000000 in
/-- **EVERY DYADIC SUB-INTERVAL LOWER-BOUNDS THE WHOLE**, for a non-negative integrand. -/
theorem riemannIntegralI_ge_dyadic {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (hfnn : ∀ x, Rnonneg (f x))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    ∀ (m j : Nat), j < 2 ^ m →
      Rle (riemannIntegralI hLd hLn hlip hfc (dyadA a w m j) (dyadW w m)
            (dyadA_den ha hw m j) (dyadW_den hw m) (dyadW_num hwn m))
          (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn)
  | 0, j, hj => by
      -- depth 0: the "sub-interval" is `[a, a+w]` itself, up to `Qeq`
      have hj0 : j = 0 := by simpa using hj
      subst hj0
      refine Rle_of_Req (riemannIntegralI_congr_Q hLd hLn hlip hfc _ _ a w _ _ _ ha hw hwn ?_ ?_)
      · simp only [dyadA, Qeq, add, mul]; push_cast; ring_uor
      · simp only [dyadW, Qeq, mul]; push_cast; ring_uor
  | m + 1, j, hj => by
      have hpow : (2 : Nat) ^ (m + 1) = 2 * 2 ^ m := by rw [Nat.pow_succ]; omega
      obtain ⟨q, hq⟩ : ∃ q, j = 2 * q ∨ j = 2 * q + 1 := ⟨j / 2, by omega⟩
      have hIH := riemannIntegralI_ge_dyadic hLd hLn hlip hfc hfnn a w ha hw hwn m q
      rcases hq with h | h
      · subst h
        have hqlt : q < 2 ^ m := by omega
        refine Rle_trans (Rle_of_Req (riemannIntegralI_congr_Q hLd hLn hlip hfc
          _ _ (dyadA a w m q) (halfQ (dyadW w m)) _ _ _
          (dyadA_den ha hw m q) (halfQ_den (dyadW_den hw m)) (halfQ_num (dyadW_num hwn m))
          ?_ ?_)) ?_
        · simp only [dyadA, Qeq, add, mul, hpow]; push_cast; ring_uor
        · simp only [dyadW, halfQ, Qeq, mul, hpow]; push_cast; ring_uor
        · exact Rle_trans (riemannIntegralI_ge_left_half hLd hLn hlip hfc hfnn
            (dyadA a w m q) (dyadW w m) (dyadA_den ha hw m q) (dyadW_den hw m)
            (dyadW_num hwn m)) (hIH hqlt)
      · subst h
        have hqlt : q < 2 ^ m := by omega
        refine Rle_trans (Rle_of_Req (riemannIntegralI_congr_Q hLd hLn hlip hfc
          _ _ (add (dyadA a w m q) (halfQ (dyadW w m))) (halfQ (dyadW w m)) _ _ _
          (add_den_pos (dyadA_den ha hw m q) (halfQ_den (dyadW_den hw m)))
          (halfQ_den (dyadW_den hw m)) (halfQ_num (dyadW_num hwn m))
          ?_ ?_)) ?_
        · simp only [dyadA, dyadW, halfQ, Qeq, add, mul, hpow]; push_cast; ring_uor
        · simp only [dyadW, halfQ, Qeq, mul, hpow]; push_cast; ring_uor
        · exact Rle_trans (riemannIntegralI_ge_right_half hLd hLn hlip hfc hfnn
            (dyadA a w m q) (dyadW w m) (dyadA_den ha hw m q) (dyadW_den hw m)
            (dyadW_num hwn m)) (hIH hqlt)

end Multiplicity.UOR.Bridge.F1Square.Square
