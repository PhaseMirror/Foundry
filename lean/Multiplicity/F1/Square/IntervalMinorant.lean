/-
F1 square — **certified integration, brick 73** (`IntervalMinorant.lean`): **A POINTWISE LOWER
BOUND ON A PIECE IS A NUMERIC LOWER BOUND ON THE INTEGRAL** —

    `c ≤ g` on `[a, a+w]`   ⟹   `w·c ≤ ∫_a^{a+w} g`   (`riemannIntegralI_ge_const`),

together with the identification of the unit interval integral with the plain one
(`riemannIntegralI_unit`). With brick 72 these compose into the shape the definiteness argument
needs: a positive constant on one dyadic piece forces the whole integral positive
(`riemannIntegral_pos_of_piece`) — **for a non-negative integrand**. That hypothesis
(`hgnn : ∀ x, Rnonneg (g x)`) is load-bearing and easy to lose in prose: without it the other
pieces could cancel the good one, and the descent of brick 72 does not hold.

Everything here is assembly. The constant integrand is certified at modulus `0` (`const_lip0`),
so it must be weakened to the integrand's own modulus before `riemannIntegralI_le_unit` — which is
the *local* comparison lemma, requiring `c ≤ g` only on the affine image of `[0,1]`, i.e. only on
the piece. That locality is what makes the argument usable: the bound is available on the small
interval and nowhere else.

HONEST SCOPE. Given a piece and a certified pointwise bound on it, this produces the integral
bound. It does **not** produce the piece or the bound: for `L²` definiteness one still has to
choose the dyadic depth from the Lipschitz constant and the size of `|φ|` at the point, which is
the arithmetic step and is not done here. Integration substrate; nothing here touches the Weil
form. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.DyadicDescent

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 1000000 in
/-- **THE CONSTANT MINORANT**: a pointwise lower bound on the piece bounds the integral below. -/
theorem riemannIntegralI_ge_const {g : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y))
    (c : Real) (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hlow : ∀ x, Rle zero x → Rle x one → Rle c (g (affineMap a w ha hw x))) :
    Rle (Rmul (ofQ w hw) c) (riemannIntegralI hLd hLn hlipg hfcg a w ha hw hwn) := by
  have hcl : ∀ x y, Rle (Rabs (Rsub c c)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
    lip_weaken (by decide) hLd (by
      show (0 : Int) * ((L.den : Nat) : Int) ≤ L.num * ((1 : Nat) : Int)
      push_cast; omega) (const_lip0 c)
  have hcf : ∀ x y : Real, Req x y → Req c c := fun _ _ _ => Req_refl c
  have hconst : Req (riemannIntegralI (f := fun _ => c) hLd hLn hcl hcf a w ha hw hwn)
      (Rmul (ofQ w hw) c) :=
    Rmul_congr (Req_refl _) (riemannIntegral_const_gen c _ _ _ _)
  refine Rle_trans (Rle_of_Req (Req_symm hconst)) ?_
  exact riemannIntegralI_le_unit hLd hLn hcl hcf hlipg hfcg a w ha hw hwn hlow

set_option maxHeartbeats 1000000 in
/-- **The unit interval integral is the plain one**: `∫_0^{0+1} f ≈ ∫₀¹ f`. -/
theorem riemannIntegralI_unit {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) :
    Req (riemannIntegralI hLd hLn hlip hfc (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)
          (by decide) (by decide) (by decide))
        (riemannIntegral hLd hLn hlip hfc) := by
  refine Req_trans (Rmul_congr (Req_of_seq_Qeq (fun _ => Qeq_refl _)) (Req_refl _)) ?_
  refine Req_trans (Req_trans (Rmul_comm one _) (Rmul_one _)) ?_
  refine riemannIntegral_congr_mod _ _ _ _ _ _ _ _
    (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)) (fun x => hfc _ _ ?_)
  show Req (Radd (ofQ (⟨0, 1⟩ : Q) (by decide))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) x)) x
  refine Req_trans (Radd_congr (Req_of_seq_Qeq (fun _ => Qeq_refl _))
    (Req_trans (Rmul_comm _ x) (Rmul_one x))) ?_
  exact Req_trans (Radd_comm zero x) (Radd_zero x)

set_option maxHeartbeats 2000000 in
/-- **POSITIVE ON ONE DYADIC PIECE ⟹ POSITIVE OVERALL**: brick 72's descent composed with the
    constant minorant. This is the shape an `L²` definiteness argument consumes. -/
theorem riemannIntegral_pos_of_piece {g : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcg : ∀ x y, Req x y → Req (g x) (g y)) (hgnn : ∀ x, Rnonneg (g x))
    (m j : Nat) (hj : j < 2 ^ m) (c : Real) (hc : Pos c)
    (hlow : ∀ x, Rle zero x → Rle x one →
      Rle c (g (affineMap (dyadA (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) m j) (dyadW (⟨1, 1⟩ : Q) m)
        (dyadA_den (by decide) (by decide) m j) (dyadW_den (by decide) m) x))) :
    Pos (riemannIntegral hLd hLn hlipg hfcg) := by
  have hpiece : Rle (Rmul (ofQ (dyadW (⟨1, 1⟩ : Q) m) (dyadW_den (by decide) m)) c)
      (riemannIntegralI hLd hLn hlipg hfcg
        (dyadA (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) m j) (dyadW (⟨1, 1⟩ : Q) m)
        (dyadA_den (by decide) (by decide) m j) (dyadW_den (by decide) m)
        (dyadW_num (by decide) m)) :=
    riemannIntegralI_ge_const hLd hLn hlipg hfcg c
      (dyadA (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) m j) (dyadW (⟨1, 1⟩ : Q) m)
      (dyadA_den (by decide) (by decide) m j) (dyadW_den (by decide) m)
      (dyadW_num (by decide) m) hlow
  have hwpos : Pos (ofQ (dyadW (⟨1, 1⟩ : Q) m) (dyadW_den (by decide) m)) := by
    refine Pos_of_Rle_ofQ (c := dyadW (⟨1, 1⟩ : Q) m) ?_ (dyadW_den (by decide) m) (Rle_refl _)
    show (0 : Int) < 1 * 1
    decide
  have hposPiece : Pos (riemannIntegralI hLd hLn hlipg hfcg
      (dyadA (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) m j) (dyadW (⟨1, 1⟩ : Q) m)
      (dyadA_den (by decide) (by decide) m j) (dyadW_den (by decide) m)
      (dyadW_num (by decide) m)) :=
    Pos_mono hpiece (Pos_Rmul hwpos hc)
  have hdesc := riemannIntegralI_ge_dyadic hLd hLn hlipg hfcg hgnn
    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) m j hj
  exact Pos_congr (riemannIntegralI_unit hLd hLn hlipg hfcg) (Pos_mono hdesc hposPiece)

end Multiplicity.UOR.Bridge.F1Square.Square
