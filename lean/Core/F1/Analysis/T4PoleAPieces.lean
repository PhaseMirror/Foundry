/-
F1 square — **the `t4PoleA` pieces** (`T4PoleAPieces.lean`). The five interval integrals
of the cone tent `t4F(x) = 2·log 2 − |log x|` over `[1/4, 4]`, each realized in
pulled-back unit form over the certified gateway (`x = c + t` on `[c, c+1]`,
`x = (1+t)·w` on the sub-unit intervals, the substitution constants split off by
`log((1+t)w) = log(1+t) + log w`):

    `[1, 2]`:  `∫₀¹ (2log2 − log(1+t)) dt`         (`t4A12`)
    `[2, 3]`:  `∫₀¹ (2log2 − log(2+t)) dt`         (`t4A23`)
    `[3, 4]`:  `∫₀¹ (2log2 − log(3+t)) dt`         (`t4A34`)
    `[1/2, 1]`: `(1/2)·∫₀¹ (log2 + log(1+t)) dt`   (`t4Ah`)
    `[1/4, 1/2]`: `(1/4)·∫₀¹ log(1+t) dt`          (`t4Aq`)

Each is a genuine constructed `riemannIntegral` (never carried data), evaluated in the
kernel against the `∫log` layer (`riemannIntegral_logC1/2/3`): the piece values are
`2log2 − (Gn(c+1) − Gn(c))`, `(1/2)(log2 + (Gn2 − Gn1))`, `(1/4)(Gn2 − Gn1)`. The
generic vehicles `int_const_sub_eval`/`int_const_add_eval` (`∫(C − f) = C − ∫f`,
`∫(C + f) = C + ∫f`, any Real constant `C`) are proven here and reusable.

The assembly `t4PoleA ≈ 9/4` (the logs cancel exactly) is the companion brick.

HONEST SCOPE. Constructed integrals and their evaluations; no slot field is filled
here and no positivity is claimed. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogIntegralEval
import Core.F1.Analysis.TentLogPiece

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Generic certificates: `C − f` and `C + f` inherit `f`'s Lipschitz data.
-- ===========================================================================

/-- `(−x) − (−y) ≈ −(x − y)` (private copy). -/
private theorem tp_neg_sub (x y : Real) : Req (Rsub (Rneg x) (Rneg y)) (Rneg (Rsub x y)) := by
  apply Req_of_seq_Qeq; intro n
  simp only [Qeq, Rsub, Radd, Rneg, neg, add]; push_cast; ring_uor

/-- `|C − C| ≤ L·|x−y|` for any nonneg modulus (private copy of the ThetaMellinPow
    original). -/
private theorem tp_const_lip (c : Real) {Lq : Q} (hLqd : 0 < Lq.den) (hLqn : 0 ≤ Lq.num) :
    ∀ x y, Rle (Rabs (Rsub c c)) (Rmul (ofQ Lq hLqd) (Rabs (Rsub x y))) := fun x y =>
  Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Radd_neg c)) Rabs_zero))
    (Rle_zero_of_Rnonneg (Rnonneg_Rmul (Rnonneg_ofQ hLqd hLqn) (Rnonneg_Rabs _)))

/-- **`C − f` inherits `f`'s Lipschitz constant.** -/
theorem lip_const_sub (C : Real) {f : Real → Real} {L : Q} {hLd : 0 < L.den}
    (hf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y)))) :
    ∀ x y, Rle (Rabs (Rsub (Rsub C (f x)) (Rsub C (f y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_const_sub C (f x) (f y)))) ?_
  refine Rle_trans (hf y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

/-- `C − f` respects `≈`. -/
theorem congr_const_sub (C : Real) {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) :
    ∀ x y, Req x y → Req (Rsub C (f x)) (Rsub C (f y)) :=
  fun _ _ h => Rsub_congr (Req_refl C) (hfc _ _ h)

/-- **`C + f` inherits `f`'s Lipschitz constant.** -/
theorem lip_const_add (C : Real) {f : Real → Real} {L : Q} {hLd : 0 < L.den}
    (hf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y)))) :
    ∀ x y, Rle (Rabs (Rsub (Radd C (f x)) (Radd C (f y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_Radd_Radd C (f x) C (f y))
    (Req_trans (Radd_congr (Radd_neg C) (Req_refl _))
      (Req_trans (Radd_comm zero _) (Radd_zero _)))))) ?_
  exact hf x y

/-- `C + f` respects `≈`. -/
theorem congr_const_add (C : Real) {f : Real → Real}
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) :
    ∀ x y, Req x y → Req (Radd C (f x)) (Radd C (f y)) :=
  fun _ _ h => Radd_congr (Req_refl C) (hfc _ _ h)

/-- `−f` inherits `f`'s Lipschitz constant. -/
theorem lip_neg {f : Real → Real} {L : Q} {hLd : 0 < L.den}
    (hf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y)))) :
    ∀ x y, Rle (Rabs (Rsub (Rneg (f x)) (Rneg (f y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (tp_neg_sub (f x) (f y)))) ?_
  exact Rle_trans (Rle_of_Req (Rabs_Rneg _)) (hf x y)

/-- `−f` respects `≈`. -/
theorem congr_neg {f : Real → Real} (hfc : ∀ x y, Req x y → Req (f x) (f y)) :
    ∀ x y, Req x y → Req (Rneg (f x)) (Rneg (f y)) :=
  fun _ _ h => Rneg_congr (hfc _ _ h)

-- ===========================================================================
-- The generic evaluations: `∫(C − f) = C − ∫f` and `∫(C + f) = C + ∫f`.
-- ===========================================================================

/-- **`∫₀¹ (C + f) = C + V`** given `∫₀¹ f = V` — the shifted-integrand evaluation,
    generic in the constant, the integrand, and the modulus. -/
theorem int_const_add_eval (C : Real) {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hflip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) {V : Real}
    (hV : Req (riemannIntegral (f := f) hLd hLn hflip hfc) V) :
    Req (riemannIntegral (f := fun t => Radd C (f t)) hLd hLn
        (lip_const_add C hflip) (congr_const_add C hfc))
      (Radd C V) :=
  Req_trans (riemannIntegral_add (f := fun _ => C) (g := f) hLd hLn
      (tp_const_lip C hLd hLn) (fun _ _ _ => Req_refl C) hflip hfc
      (lip_const_add C hflip) (congr_const_add C hfc))
    (Radd_congr (riemannIntegral_const_gen C hLd hLn _ _) hV)

/-- **`∫₀¹ (C − f) = C − V`** given `∫₀¹ f = V` — the reflected-integrand evaluation,
    generic in the constant, the integrand, and the modulus. -/
theorem int_const_sub_eval (C : Real) {f : Real → Real} {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hflip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) {V : Real}
    (hV : Req (riemannIntegral (f := f) hLd hLn hflip hfc) V) :
    Req (riemannIntegral (f := fun t => Rsub C (f t)) hLd hLn
        (lip_const_sub C hflip) (congr_const_sub C hfc))
      (Rsub C V) :=
  Req_trans (riemannIntegral_add (f := fun _ => C) (g := fun t => Rneg (f t)) hLd hLn
      (tp_const_lip C hLd hLn) (fun _ _ _ => Req_refl C)
      (lip_neg hflip) (congr_neg hfc)
      (lip_const_sub C hflip) (congr_const_sub C hfc))
    (Radd_congr (riemannIntegral_const_gen C hLd hLn _ _)
      (Req_trans (riemannIntegral_neg hLd hLn hflip hfc (lip_neg hflip) (congr_neg hfc))
        (Rneg_congr hV)))

-- ===========================================================================
-- The five pieces.
-- ===========================================================================

/-- The cone height `2·log 2` (the `Gn 2` log term's exact shape). -/
def t4H : Real :=
  Rmul (ofQ (⟨((2 : Nat) : Int), 1⟩ : Q) Nat.one_pos) (logN 2 (by omega))

/-- **`[1, 2]`**: `∫₀¹ (2log2 − log(1+t)) dt`, constructed. -/
def t4A12 : Real :=
  riemannIntegral (f := fun t => Rsub t4H (gLog 1 t)) (L := (⟨1, 1⟩ : Q))
    (by decide) (by decide) (lip_const_sub t4H gLog1_lip) (congr_const_sub t4H gLog1_congr)

/-- **`[2, 3]`**: `∫₀¹ (2log2 − log(2+t)) dt`, constructed. -/
def t4A23 : Real :=
  riemannIntegral (f := fun t => Rsub t4H (gLog 2 t)) (L := (⟨1, 1⟩ : Q))
    (by decide) (by decide) (lip_const_sub t4H gLog2_lip) (congr_const_sub t4H gLog2_congr)

/-- **`[3, 4]`**: `∫₀¹ (2log2 − log(3+t)) dt`, constructed. -/
def t4A34 : Real :=
  riemannIntegral (f := fun t => Rsub t4H (gLog 3 t)) (L := (⟨1, 1⟩ : Q))
    (by decide) (by decide) (lip_const_sub t4H gLog3_lip) (congr_const_sub t4H gLog3_congr)

/-- **`[1/2, 1]`**: `(1/2)·∫₀¹ (log2 + log(1+t)) dt` — the substitution `x = (1+t)/2`
    with `log((1+t)/2) = log(1+t) − log 2` absorbed into `2log2 − |log x|`. -/
def t4Ah : Real :=
  Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
    (riemannIntegral (f := fun t => Radd (logN 2 (by omega)) (gLog 1 t)) (L := (⟨1, 1⟩ : Q))
      (by decide) (by decide)
      (lip_const_add (logN 2 (by omega)) gLog1_lip)
      (congr_const_add (logN 2 (by omega)) gLog1_congr))

/-- **`[1/4, 1/2]`**: `(1/4)·∫₀¹ log(1+t) dt` — the substitution `x = (1+t)/4` with
    `log((1+t)/4) = log(1+t) − 2log2` cancelling the cone height exactly. -/
def t4Aq : Real :=
  Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
    (riemannIntegral (f := gLog 1) (L := (⟨1, 1⟩ : Q)) Nat.one_pos (by decide)
      gLog1_lip gLog1_congr)

/-- **The `t4` test's `∫ f` pole component, CONSTRUCTED**: the five pieces summed. -/
def t4PoleA : Real := Radd (Radd (Radd t4A12 t4A23) (Radd t4A34 t4Ah)) t4Aq

-- ===========================================================================
-- The piece evaluations.
-- ===========================================================================

/-- `t4A12 ≈ 2log2 − (Gn 2 − Gn 1)`. -/
theorem t4A12_eq :
    Req t4A12 (Rsub t4H (Rsub (Gn 2 (by omega)) (Gn 1 (by omega)))) :=
  int_const_sub_eval t4H (by decide) (by decide) gLog1_lip gLog1_congr riemannIntegral_logC1

/-- `t4A23 ≈ 2log2 − (Gn 3 − Gn 2)`. -/
theorem t4A23_eq :
    Req t4A23 (Rsub t4H (Rsub (Gn 3 (by omega)) (Gn 2 (by omega)))) :=
  int_const_sub_eval t4H (by decide) (by decide) gLog2_lip gLog2_congr riemannIntegral_logC2

/-- `t4A34 ≈ 2log2 − (Gn 4 − Gn 3)`. -/
theorem t4A34_eq :
    Req t4A34 (Rsub t4H (Rsub (Gn 4 (by omega)) (Gn 3 (by omega)))) :=
  int_const_sub_eval t4H (by decide) (by decide) gLog3_lip gLog3_congr riemannIntegral_logC3

/-- `t4Ah ≈ (1/2)·(log2 + (Gn 2 − Gn 1))`. -/
theorem t4Ah_eq :
    Req t4Ah (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
      (Radd (logN 2 (by omega)) (Rsub (Gn 2 (by omega)) (Gn 1 (by omega))))) :=
  Rmul_congr (Req_refl _)
    (int_const_add_eval (logN 2 (by omega)) (by decide) (by decide)
      gLog1_lip gLog1_congr riemannIntegral_logC1)

/-- `t4Aq ≈ (1/4)·(Gn 2 − Gn 1)`. -/
theorem t4Aq_eq :
    Req t4Aq (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
      (Rsub (Gn 2 (by omega)) (Gn 1 (by omega)))) :=
  Rmul_congr (Req_refl _) riemannIntegral_logC1

end UOR.Bridge.F1Square.Analysis
