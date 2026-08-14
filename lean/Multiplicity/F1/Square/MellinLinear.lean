/-
F1 square — **the pre-Hilbert layer, brick 21** (`MellinLinear.lean`): **THE TRANSFORM IS
LINEAR** — `f̂` is additive in the test, so the transform-side vanishing conditions cut out
SUBSPACES.

`mellinHat_add`: for tests sharing an exponent-`(n+2)` decay constant `C`,

    `(φ + ψ)^(n) ≈ φ̂(n) + ψ̂(n)`.

The compact piece is brick 7's pairing additivity (`innerI_add_left` at the monomial test); the
twisted tail is additive because each twisted window integral is (`twTerm_add` — the
`innerI_add_left` pattern at the interval level, through the new `riemannIntegralI_certif_irrel`
and `riemannIntegralI_congr`), the window sums add termwise (`genSum_Radd_of_termwise`), and the
Bishop limits combine (`Rlim_add_of_approx`) — all three tails running on the SAME schedule
because the decay constant is shared (exactly the shared-modulus design of
`riemannIntegral_add`).

WHY (the Sonine route, steps 3–4). The genuine co-support condition ("`f̂` vanishes on the
band") must cut out a linear SUBSPACE for the coupling to be an orthogonal-projection-type
mechanism — that is what the skeleton's `bandProj` has and what the genuine transform side
needed. With linearity, `{φ : mellinHat φ n ≈ 0 for n ∈ band}` is closed under addition: the
transform-side support condition is now subspace-shaped, about CONSTRUCTED objects.

HONEST SCOPE. Additivity at a shared decay constant (the shared-modulus statement, mirroring
`riemannIntegral_add`); no scalar action, no continuous parameter, no coupling. The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MellinHat
import Multiplicity.F1Square.Analysis.IntegralBilinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Interval-integral plumbing: certificate independence and congruence.
-- ===========================================================================

/-- **Certificate independence of the interval integral** — the unit-interval independence
    (brick 6) lifted through the width factor. -/
theorem riemannIntegralI_certif_irrel {f : Real → Real} {L L' : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (hL'd : 0 < L'.den) (hL'n : 0 ≤ L'.num)
    (hlip' : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L' hL'd) (Rabs (Rsub x y))))
    (hfc' : ∀ x y, Req x y → Req (f x) (f y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn)
        (riemannIntegralI hL'd hL'n hlip' hfc' a w ha hw hwn) :=
  Rmul_congr (Req_refl _) (riemannIntegral_certif_irrel
    (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn) _ _
    (Qmul_den_pos hL'd hw) (Int.mul_nonneg hL'n hwn) _ _)

-- ===========================================================================
-- Additivity of the twisted window integrals.
-- ===========================================================================

/-- **The twisted window integrals are additive**: `twTerm (φ+ψ) ≈ twTerm φ + twTerm ψ` — the
    `innerI_add_left` pattern at the interval level: all three product integrands weakened to
    the common modulus, distributed, added there, and moved back by certificate independence. -/
theorem twTerm_add (φ ψ : L2Test) (n m : Nat) :
    Req (twTerm (L2Test.add φ ψ) n m) (Radd (twTerm φ n m) (twTerm ψ n m)) := by
  have hLcd : 0 < (add (l2L φ (powWinTest m n)) (l2L ψ (powWinTest m n))).den :=
    add_den_pos (l2L_den φ (powWinTest m n)) (l2L_den ψ (powWinTest m n))
  have hLcn : 0 ≤ (add (l2L φ (powWinTest m n)) (l2L ψ (powWinTest m n))).num :=
    Qadd_num_nonneg_loc (l2L_num φ (powWinTest m n)) (l2L_num ψ (powWinTest m n))
  have hlip1 := lip_weaken (l2L_den φ (powWinTest m n)) hLcd
    (Qle_self_add (l2L_num ψ (powWinTest m n))) (l2lip φ (powWinTest m n))
  have hlip2 := lip_weaken (l2L_den ψ (powWinTest m n)) hLcd
    (Qle_self_add_l (l2L_num φ (powWinTest m n))) (l2lip ψ (powWinTest m n))
  have hlipS : ∀ x y, Rle (Rabs (Rsub
        (Radd (Rmul (φ.f x) ((powWinTest m n).f x)) (Rmul (ψ.f x) ((powWinTest m n).f x)))
        (Radd (Rmul (φ.f y) ((powWinTest m n).f y)) (Rmul (ψ.f y) ((powWinTest m n).f y)))))
      (Rmul (ofQ (add (l2L φ (powWinTest m n)) (l2L ψ (powWinTest m n))) hLcd)
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Radd_lipschitz_real (l2lip φ (powWinTest m n)) (l2lip ψ (powWinTest m n)) x y)
      (Rmul_le_Rmul_right (Rnonneg_Rabs _)
        (Rle_of_Req (Radd_ofQ_ofQ (l2L_den φ (powWinTest m n))
          (l2L_den ψ (powWinTest m n)))))
  have hfcS : ∀ x y, Req x y → Req
      (Radd (Rmul (φ.f x) ((powWinTest m n).f x)) (Rmul (ψ.f x) ((powWinTest m n).f x)))
      (Radd (Rmul (φ.f y) ((powWinTest m n).f y)) (Rmul (ψ.f y) ((powWinTest m n).f y))) :=
    fun x y h => Radd_congr (l2fc φ (powWinTest m n) x y h) (l2fc ψ (powWinTest m n) x y h)
  have hdist : ∀ x, Req (Rmul (Radd (φ.f x) (ψ.f x)) ((powWinTest m n).f x))
      (Radd (Rmul (φ.f x) ((powWinTest m n).f x)) (Rmul (ψ.f x) ((powWinTest m n).f x))) :=
    fun x => Rmul_distrib_right (φ.f x) (ψ.f x) ((powWinTest m n).f x)
  have hlipP : ∀ x y, Rle (Rabs (Rsub
        (Rmul (Radd (φ.f x) (ψ.f x)) ((powWinTest m n).f x))
        (Rmul (Radd (φ.f y) (ψ.f y)) ((powWinTest m n).f y))))
      (Rmul (ofQ (add (l2L φ (powWinTest m n)) (l2L ψ (powWinTest m n))) hLcd)
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (hdist x) (hdist y)))) (hlipS x y)
  have hfcP := l2fc (L2Test.add φ ψ) (powWinTest m n)
  refine Req_trans (riemannIntegralI_certif_irrel
    (l2L_den (L2Test.add φ ψ) (powWinTest m n)) (l2L_num (L2Test.add φ ψ) (powWinTest m n))
    (l2lip (L2Test.add φ ψ) (powWinTest m n)) (l2fc (L2Test.add φ ψ) (powWinTest m n))
    hLcd hLcn hlipP hfcP
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) ?_
  refine Req_trans (riemannIntegralI_congr hLcd hLcn hlipP hfcP hlipS hfcS
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide) hdist) ?_
  refine Req_trans (riemannIntegralI_add hLcd hLcn hlip1 (l2fc φ (powWinTest m n))
    hlip2 (l2fc ψ (powWinTest m n)) hlipS hfcS
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)) ?_
  exact Radd_congr
    (riemannIntegralI_certif_irrel hLcd hLcn hlip1 (l2fc φ (powWinTest m n))
      (l2L_den φ (powWinTest m n)) (l2L_num φ (powWinTest m n))
      (l2lip φ (powWinTest m n)) (l2fc φ (powWinTest m n))
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide))
    (riemannIntegralI_certif_irrel hLcd hLcn hlip2 (l2fc ψ (powWinTest m n))
      (l2L_den ψ (powWinTest m n)) (l2L_num ψ (powWinTest m n))
      (l2lip ψ (powWinTest m n)) (l2fc ψ (powWinTest m n))
      (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide))

-- ===========================================================================
-- Additivity of the tail and the transform.
-- ===========================================================================

/-- **The twisted tails are additive** (shared decay constant, hence shared schedule):
    `twTail (φ+ψ) ≈ twTail φ + twTail ψ` — window sums add termwise, Bishop limits combine. -/
theorem twTail_add (φ ψ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdφ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdψ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (ψ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdS : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((L2Test.add φ ψ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (twTail (L2Test.add φ ψ) n hCd hCn hdS)
        (Radd (twTail φ n hCd hCn hdφ) (twTail ψ n hCd hCn hdψ)) := by
  refine Rlim_add_of_approx _ _ _
    (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
      (Int.mul_nonneg hCn (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd hCn hdφ))
    (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
      (Int.mul_nonneg hCn (Int.ofNat_nonneg _)) (twTerm_bound ψ n hCd hCn hdψ))
    (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
      (Int.mul_nonneg hCn (Int.ofNat_nonneg _)) (twTerm_bound (L2Test.add φ ψ) n hCd hCn hdS))
    (fun j => ?_)
  exact genSum_Radd_of_termwise (fun k => twTerm_add φ ψ n k) _

/-- **THE TRANSFORM IS LINEAR**: `(φ+ψ)^(n) ≈ φ̂(n) + ψ̂(n)` — the compact piece by the L²
    pairing's additivity (brick 7 at the monomial test), the tail by `twTail_add`. The
    transform-side vanishing conditions now cut out SUBSPACES of the test class. -/
theorem mellinHat_add (φ ψ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdφ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdψ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (ψ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdS : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((L2Test.add φ ψ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (mellinHat (L2Test.add φ ψ) n hCd hCn hdS)
        (Radd (mellinHat φ n hCd hCn hdφ) (mellinHat ψ n hCd hCn hdψ)) := by
  refine Req_trans (Radd_congr (innerI_add_left φ ψ (powTest n))
    (twTail_add φ ψ n hCd hCn hdφ hdψ hdS)) ?_
  exact Radd_swap _ _ _ _

end Multiplicity.UOR.Bridge.F1Square.Square
