/-
F1 square — **the `t4PoleB` pieces, part 1: the combinators** (`T4PoleBPieces.lean`).
The poleB piece integrands are sums `C·gRecipC + q·gLx` (real constant `C`, rational
`q`); this file supplies the generic Lipschitz combinators they need —

    `smul_lip`  : `|C| ≤ B`, `f` `L_f`-Lipschitz ⟹ `C·f` is `(B·L_f)`-Lipschitz,
    `add_lip`   : `f` `L_f`-, `g` `L_g`-Lipschitz ⟹ `f + g` is `(L_f + L_g)`-Lipschitz

— and the cone-height bounds `0 ≤ t4H = 2·log 2 ≤ 2` (`|t4H| ≤ 2`), feeding
`riemannIntegral_recipC_smul` at `B = 2`.

HONEST SCOPE. Certificate combinators and a constant bound; no integral, no
positivity. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.RecipSmulEval
import Multiplicity.F1.Analysis.T4PoleAPieces

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- `a·z + b·z ≈ (a+b)·z` (private copy). -/
private theorem tb_smul_add {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) (z : Real) :
    Req (Radd (Rmul (ofQ a ha) z) (Rmul (ofQ b hb) z))
      (Rmul (ofQ (add a b) (add_den_pos ha hb)) z) := by
  refine Req_trans (Radd_congr (Rmul_comm _ z) (Rmul_comm _ z)) ?_
  refine Req_trans (Req_symm (Rmul_distrib z (ofQ a ha) (ofQ b hb))) ?_
  refine Req_trans (Rmul_comm z _) ?_
  exact Rmul_congr (Radd_ofQ_ofQ ha hb) (Req_refl z)

/-- **The real-scalar Lipschitz combinator**: `|C| ≤ B` and `f` `L_f`-Lipschitz give
    `C·f` `(B·L_f)`-Lipschitz. -/
theorem smul_lip {C : Real} {Bq : Q} (hBd : 0 < Bq.den) (hCb : Rle (Rabs C) (ofQ Bq hBd))
    {f : Real → Real} {Lf : Q} (hLfd : 0 < Lf.den) (hLfn : 0 ≤ Lf.num)
    (hf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ Lf hLfd) (Rabs (Rsub x y)))) :
    ∀ x y, Rle (Rabs (Rsub (Rmul C (f x)) (Rmul C (f y))))
      (Rmul (ofQ (mul Bq Lf) (Qmul_den_pos hBd hLfd)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr
    (Req_symm (Rmul_sub_distrib C (f x) (f y))))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rmul C _)) ?_
  refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs _)
    (Rnonneg_Rmul (Rnonneg_ofQ hLfd hLfn) (Rnonneg_Rabs _)) hCb (hf x y)) ?_
  exact Rle_of_Req (Req_trans (Req_symm (Rmul_assoc _ _ _))
    (Rmul_congr (Rmul_ofQ_ofQ hBd hLfd) (Req_refl _)))

/-- `C·f` respects `≈`, given `f`'s congruence. -/
theorem smul_congr (C : Real) {f : Real → Real}
    (hfc : ∀ x y : Real, Req x y → Req (f x) (f y)) :
    ∀ x y : Real, Req x y → Req (Rmul C (f x)) (Rmul C (f y)) :=
  fun _ _ h => Rmul_congr (Req_refl C) (hfc _ _ h)

/-- **The sum Lipschitz combinator**: `f` `L_f`-, `g` `L_g`-Lipschitz give `f + g`
    `(L_f + L_g)`-Lipschitz. -/
theorem add_lip {f g : Real → Real} {Lf Lg : Q}
    (hLfd : 0 < Lf.den) (hLgd : 0 < Lg.den)
    (hf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ Lf hLfd) (Rabs (Rsub x y))))
    (hg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ Lg hLgd) (Rabs (Rsub x y)))) :
    ∀ x y, Rle (Rabs (Rsub (Radd (f x) (g x)) (Radd (f y) (g y))))
      (Rmul (ofQ (add Lf Lg) (add_den_pos hLfd hLgd)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr
    (Rsub_Radd_Radd (f x) (g x) (f y) (g y)))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add (hf x y) (hg x y)) ?_
  exact Rle_of_Req (tb_smul_add hLfd hLgd (Rabs (Rsub x y)))

/-- `f + g` respects `≈`. -/
theorem add_congr_fn {f g : Real → Real}
    (hfc : ∀ x y : Real, Req x y → Req (f x) (f y))
    (hgc : ∀ x y : Real, Req x y → Req (g x) (g y)) :
    ∀ x y : Real, Req x y → Req (Radd (f x) (g x)) (Radd (f y) (g y)) :=
  fun _ _ h => Radd_congr (hfc _ _ h) (hgc _ _ h)

/-- `t4H = 2·log 2 ≥ 0`. -/
theorem t4H_nonneg : Rnonneg t4H :=
  Rnonneg_Rmul (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg 2)) (Rnonneg_logN 2 (by omega))

/-- **`|t4H| ≤ 2`** — the cone height under the `recipC_smul` bound. -/
theorem t4H_abs : Rle (Rabs t4H) (ofQ (⟨2, 1⟩ : Q) (by decide)) := by
  refine Rle_trans (Rle_of_Req (Rabs_of_nonneg t4H_nonneg)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg 2))
    logN_two_le_one) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos) ?_)
  exact ofQ_congr (Qmul_den_pos Nat.one_pos Nat.one_pos) (by decide) (by decide)

/-- `|log 2| ≤ 1` — the half-height bound (for the `[1/2, 1]` piece). -/
theorem oneL_abs : Rle (Rabs (logN 2 (by omega))) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
  Rle_trans (Rle_of_Req (Rabs_of_nonneg (Rnonneg_logN 2 (by omega)))) logN_two_le_one


-- ===========================================================================
-- Part 2: the upper pieces `[c, c+1]` — `(2log2 − log x)/x` as `t4H·recip − ½·gLx`.
-- ===========================================================================

/-- `|−1/2| ≤ 1/2`. -/
theorem negHalf_abs :
    Rle (Rabs (ofQ (⟨-1, 2⟩ : Q) (by decide))) (ofQ (⟨1, 2⟩ : Q) (by decide)) :=
  Rle_trans (Rle_of_Req (Rabs_ofQ (by decide)))
    (Rle_of_Req (ofQ_congr (by decide) (by decide) (by decide)))

/-- The `gLx` natural Lipschitz constant (`2c + 2`). -/
def LxQ (c : Nat) : Q :=
  add (mul (⟨((2 * c : Nat) : Int), 1⟩ : Q) (⟨1, 1⟩ : Q))
    (mul (⟨1, 1⟩ : Q) (⟨2, 1⟩ : Q))

theorem LxQ_den_pos (c : Nat) : 0 < (LxQ c).den :=
  add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos) (Qmul_den_pos Nat.one_pos Nat.one_pos)

theorem LxQ_num_nonneg (c : Nat) : 0 ≤ (LxQ c).num :=
  Int.add_nonneg
    (Int.mul_nonneg (Int.mul_nonneg (Int.ofNat_nonneg _) (by decide)) (Int.ofNat_nonneg _))
    (Int.mul_nonneg (by decide) (Int.ofNat_nonneg _))

set_option maxHeartbeats 1600000 in
/-- **The upper-piece evaluation, general in the base and the weakening certificates**:
    `∫₀¹ (t4H·(1/(c+t)) + (−1/2)·gLx c) dt ≈ t4H·(log(c+1) − log c) − (1/2)·(Hn(c+1) −
    Hn(c))` — the pulled-back `∫_c^{c+1} (2log2 − log x)/x dx`. -/
theorem t4B_upper_eval (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3)
    (hgl : ∀ x y : Real, Rle (Rabs (Rsub (gLog c x) (gLog c y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))))
    (hgc : ∀ x y : Real, Req x y → Req (gLog c x) (gLog c y))
    {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hq1 : Qle (mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q)) L)
    (hqx : Qle (LxQ c) L)
    (hq2 : Qle (mul (⟨1, 2⟩ : Q) (LxQ c)) L)
    (hqS : Qle (add (mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q)) (mul (⟨1, 2⟩ : Q) (LxQ c))) L)
    (hsch : ∀ j, 5 * (j + 1) ≤ digammaMidx L j) :
    Req (riemannIntegral
        (f := fun t => Radd (Rmul t4H (gRecipC c t))
          (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx c t)))
        hLd hLn
        (fun x y => lip_mono
          (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
            (Qmul_den_pos (by decide) (LxQ_den_pos c))) hLd hqS (Rnonneg_Rabs _)
          (add_lip (Qmul_den_pos Nat.one_pos Nat.one_pos)
            (Qmul_den_pos (by decide) (LxQ_den_pos c))
            (smul_lip Nat.one_pos t4H_abs Nat.one_pos (by decide) (gRecipC_lip c))
            (smul_lip (by decide) negHalf_abs (LxQ_den_pos c) (LxQ_num_nonneg c)
              (gLx_lip_of c hc3 hgl)) x y))
        (add_congr_fn (smul_congr t4H (gRecipC_congr c))
          (smul_congr (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx_congr_of c hgc))))
      (Radd (Rmul t4H (Rsub (logN (c + 1) (by omega)) (logN c hc1)))
        (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide))
          (Rsub (Hn (c + 1) (by omega)) (Hn c hc1)))) := by
  refine Req_trans (riemannIntegral_add (f := fun t => Rmul t4H (gRecipC c t))
    (g := fun t => Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx c t)) hLd hLn
    (fun x y => lip_mono (Qmul_den_pos Nat.one_pos Nat.one_pos) hLd hq1
      (Rnonneg_Rabs _) (smul_lip Nat.one_pos t4H_abs Nat.one_pos (by decide)
        (gRecipC_lip c) x y))
    (smul_congr t4H (gRecipC_congr c))
    (fun x y => lip_mono (Qmul_den_pos (by decide) (LxQ_den_pos c)) hLd hq2
      (Rnonneg_Rabs _) (smul_lip (by decide) negHalf_abs (LxQ_den_pos c)
        (LxQ_num_nonneg c) (gLx_lip_of c hc3 hgl) x y))
    (smul_congr (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx_congr_of c hgc))
    _ _) ?_
  refine Radd_congr ?_ ?_
  · exact riemannIntegral_recipC_smul c hc1 t4H (B := (⟨2, 1⟩ : Q)) (by decide)
      (by decide) t4H_abs hLd hLn _ _ hsch
  · refine Req_trans (riemannIntegral_smul (⟨-1, 2⟩ : Q) (by decide) hLd hLn
      (fun x y => lip_mono (LxQ_den_pos c) hLd hqx (Rnonneg_Rabs _)
        (gLx_lip_of c hc3 hgl x y))
      (gLx_congr_of c hgc) _ _) ?_
    exact Rmul_congr (Req_refl _)
      (riemannIntegral_gLx_gen c hc1 hc3 hLd hLn
        (fun x y => lip_mono (LxQ_den_pos c) hLd hqx (Rnonneg_Rabs _)
          (gLx_lip_of c hc3 hgl x y))
        (gLx_congr_of c hgc) hsch)


-- ===========================================================================
-- Part 3: the lower-piece evaluation — `(2log2 + log x)/x` pulls back with NO outer
-- weight (`dx/x` is scale-invariant): `[1/2,1] ↦ (log2 + log(1+t))/(1+t)`,
-- `[1/4,1/2] ↦ log(1+t)/(1+t)`.
-- ===========================================================================

/-- `|1/2| ≤ 1/2`. -/
theorem posHalf_abs :
    Rle (Rabs (ofQ (⟨1, 2⟩ : Q) (by decide))) (ofQ (⟨1, 2⟩ : Q) (by decide)) :=
  Rle_of_Req (Rabs_ofQ (by decide))

set_option maxHeartbeats 1600000 in
/-- **The mixed-piece evaluation with a `+(1/2)·gLx` tail**, generic in the bounded
    real constant `C`: `∫₀¹ (C·(1/(c+t)) + (1/2)·gLx c) dt ≈ C·(log(c+1) − log c) +
    (1/2)·(Hn(c+1) − Hn(c))` — the `[1/2, 1]` piece at `C = log 2`, `c = 1`. -/
theorem t4B_lower_eval (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) (C : Real) {Bq : Q}
    (hBd : 0 < Bq.den) (hB5 : Bq.num.toNat ≤ 5) (hCb : Rle (Rabs C) (ofQ Bq hBd))
    (hgl : ∀ x y : Real, Rle (Rabs (Rsub (gLog c x) (gLog c y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))))
    (hgc : ∀ x y : Real, Req x y → Req (gLog c x) (gLog c y))
    {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hq1 : Qle (mul Bq (⟨1, 1⟩ : Q)) L)
    (hqx : Qle (LxQ c) L)
    (hq2 : Qle (mul (⟨1, 2⟩ : Q) (LxQ c)) L)
    (hqS : Qle (add (mul Bq (⟨1, 1⟩ : Q)) (mul (⟨1, 2⟩ : Q) (LxQ c))) L)
    (hsch : ∀ j, 5 * (j + 1) ≤ digammaMidx L j) :
    Req (riemannIntegral
        (f := fun t => Radd (Rmul C (gRecipC c t))
          (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (gLx c t)))
        hLd hLn
        (fun x y => lip_mono
          (add_den_pos (Qmul_den_pos hBd Nat.one_pos)
            (Qmul_den_pos (by decide) (LxQ_den_pos c))) hLd hqS (Rnonneg_Rabs _)
          (add_lip (Qmul_den_pos hBd Nat.one_pos)
            (Qmul_den_pos (by decide) (LxQ_den_pos c))
            (smul_lip hBd hCb Nat.one_pos (by decide) (gRecipC_lip c))
            (smul_lip (by decide) posHalf_abs (LxQ_den_pos c) (LxQ_num_nonneg c)
              (gLx_lip_of c hc3 hgl)) x y))
        (add_congr_fn (smul_congr C (gRecipC_congr c))
          (smul_congr (ofQ (⟨1, 2⟩ : Q) (by decide)) (gLx_congr_of c hgc))))
      (Radd (Rmul C (Rsub (logN (c + 1) (by omega)) (logN c hc1)))
        (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
          (Rsub (Hn (c + 1) (by omega)) (Hn c hc1)))) := by
  refine Req_trans (riemannIntegral_add (f := fun t => Rmul C (gRecipC c t))
    (g := fun t => Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (gLx c t)) hLd hLn
    (fun x y => lip_mono (Qmul_den_pos hBd Nat.one_pos) hLd hq1
      (Rnonneg_Rabs _) (smul_lip hBd hCb Nat.one_pos (by decide)
        (gRecipC_lip c) x y))
    (smul_congr C (gRecipC_congr c))
    (fun x y => lip_mono (Qmul_den_pos (by decide) (LxQ_den_pos c)) hLd hq2
      (Rnonneg_Rabs _) (smul_lip (by decide) posHalf_abs (LxQ_den_pos c)
        (LxQ_num_nonneg c) (gLx_lip_of c hc3 hgl) x y))
    (smul_congr (ofQ (⟨1, 2⟩ : Q) (by decide)) (gLx_congr_of c hgc))
    _ _) ?_
  refine Radd_congr ?_ ?_
  · exact riemannIntegral_recipC_smul c hc1 C hBd hB5 hCb hLd hLn _ _ hsch
  · refine Req_trans (riemannIntegral_smul (⟨1, 2⟩ : Q) (by decide) hLd hLn
      (fun x y => lip_mono (LxQ_den_pos c) hLd hqx (Rnonneg_Rabs _)
        (gLx_lip_of c hc3 hgl x y))
      (gLx_congr_of c hgc) _ _) ?_
    exact Rmul_congr (Req_refl _)
      (riemannIntegral_gLx_gen c hc1 hc3 hLd hLn
        (fun x y => lip_mono (LxQ_den_pos c) hLd hqx (Rnonneg_Rabs _)
          (gLx_lip_of c hc3 hgl x y))
        (gLx_congr_of c hgc) hsch)


-- ===========================================================================
-- Part 4: the five constructed pieces.
-- ===========================================================================

/-- **`[1, 2]`**: `∫ (2log2 − log x)/x`, constructed (`c = 1`). -/
def t4B12 : Real :=
  riemannIntegral
    (f := fun t => Radd (Rmul t4H (gRecipC 1 t))
      (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx 1 t)))
    (L := add (mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q)) (LxQ 1))
    (by decide) (by decide)
    (fun x y => lip_mono
      (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_den_pos (by decide) (LxQ_den_pos 1))) (by decide) (by decide)
      (Rnonneg_Rabs _)
      (add_lip (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_den_pos (by decide) (LxQ_den_pos 1))
        (smul_lip Nat.one_pos t4H_abs Nat.one_pos (by decide) (gRecipC_lip 1))
        (smul_lip (by decide) negHalf_abs (LxQ_den_pos 1) (LxQ_num_nonneg 1)
          (gLx_lip_of 1 (by omega) gLog1_lip)) x y))
    (add_congr_fn (smul_congr t4H (gRecipC_congr 1))
      (smul_congr (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx_congr_of 1 gLog1_congr)))

/-- `t4B12 ≈ 2log2·(log 2 − log 1) − (1/2)·(Hn 2 − Hn 1)`. -/
theorem t4B12_eq : Req t4B12
    (Radd (Rmul t4H (Rsub (logN 2 (by omega)) (logN 1 (by omega))))
      (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide))
        (Rsub (Hn 2 (by omega)) (Hn 1 (by omega))))) :=
  t4B_upper_eval 1 (by omega) (by omega) gLog1_lip gLog1_congr
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)
    (fun j => by show 5 * (j + 1) ≤ 7 * (j + 1); omega)

/-- **`[2, 3]`**: `∫ (2log2 − log x)/x`, constructed (`c = 2`). -/
def t4B23 : Real :=
  riemannIntegral
    (f := fun t => Radd (Rmul t4H (gRecipC 2 t))
      (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx 2 t)))
    (L := add (mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q)) (LxQ 2))
    (by decide) (by decide)
    (fun x y => lip_mono
      (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_den_pos (by decide) (LxQ_den_pos 2))) (by decide) (by decide)
      (Rnonneg_Rabs _)
      (add_lip (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_den_pos (by decide) (LxQ_den_pos 2))
        (smul_lip Nat.one_pos t4H_abs Nat.one_pos (by decide) (gRecipC_lip 2))
        (smul_lip (by decide) negHalf_abs (LxQ_den_pos 2) (LxQ_num_nonneg 2)
          (gLx_lip_of 2 (by omega) gLog2_lip)) x y))
    (add_congr_fn (smul_congr t4H (gRecipC_congr 2))
      (smul_congr (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx_congr_of 2 gLog2_congr)))

/-- `t4B23 ≈ 2log2·(log 3 − log 2) − (1/2)·(Hn 3 − Hn 2)`. -/
theorem t4B23_eq : Req t4B23
    (Radd (Rmul t4H (Rsub (logN 3 (by omega)) (logN 2 (by omega))))
      (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide))
        (Rsub (Hn 3 (by omega)) (Hn 2 (by omega))))) :=
  t4B_upper_eval 2 (by omega) (by omega) gLog2_lip gLog2_congr
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)
    (fun j => by show 5 * (j + 1) ≤ 9 * (j + 1); omega)

/-- **`[3, 4]`**: `∫ (2log2 − log x)/x`, constructed (`c = 3`). -/
def t4B34 : Real :=
  riemannIntegral
    (f := fun t => Radd (Rmul t4H (gRecipC 3 t))
      (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx 3 t)))
    (L := add (mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q)) (LxQ 3))
    (by decide) (by decide)
    (fun x y => lip_mono
      (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_den_pos (by decide) (LxQ_den_pos 3))) (by decide) (by decide)
      (Rnonneg_Rabs _)
      (add_lip (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_den_pos (by decide) (LxQ_den_pos 3))
        (smul_lip Nat.one_pos t4H_abs Nat.one_pos (by decide) (gRecipC_lip 3))
        (smul_lip (by decide) negHalf_abs (LxQ_den_pos 3) (LxQ_num_nonneg 3)
          (gLx_lip_of 3 (by omega) gLog3_lip)) x y))
    (add_congr_fn (smul_congr t4H (gRecipC_congr 3))
      (smul_congr (ofQ (⟨-1, 2⟩ : Q) (by decide)) (gLx_congr_of 3 gLog3_congr)))

/-- `t4B34 ≈ 2log2·(log 4 − log 3) − (1/2)·(Hn 4 − Hn 3)`. -/
theorem t4B34_eq : Req t4B34
    (Radd (Rmul t4H (Rsub (logN 4 (by omega)) (logN 3 (by omega))))
      (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide))
        (Rsub (Hn 4 (by omega)) (Hn 3 (by omega))))) :=
  t4B_upper_eval 3 (by omega) (by omega) gLog3_lip gLog3_congr
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)
    (fun j => by show 5 * (j + 1) ≤ 11 * (j + 1); omega)

/-- **`[1/2, 1]`**: `∫ (2log2 + log x)/x` — pulls back to `(log2 + log(1+t))/(1+t)`,
    no outer weight (`dx/x` scale-invariant). -/
def t4Bh : Real :=
  riemannIntegral
    (f := fun t => Radd (Rmul (logN 2 (by omega)) (gRecipC 1 t))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (gLx 1 t)))
    (L := add (mul (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q)) (LxQ 1))
    (by decide) (by decide)
    (fun x y => lip_mono
      (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_den_pos (by decide) (LxQ_den_pos 1))) (by decide) (by decide)
      (Rnonneg_Rabs _)
      (add_lip (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qmul_den_pos (by decide) (LxQ_den_pos 1))
        (smul_lip Nat.one_pos oneL_abs Nat.one_pos (by decide) (gRecipC_lip 1))
        (smul_lip (by decide) posHalf_abs (LxQ_den_pos 1) (LxQ_num_nonneg 1)
          (gLx_lip_of 1 (by omega) gLog1_lip)) x y))
    (add_congr_fn (smul_congr (logN 2 (by omega)) (gRecipC_congr 1))
      (smul_congr (ofQ (⟨1, 2⟩ : Q) (by decide)) (gLx_congr_of 1 gLog1_congr)))

/-- `t4Bh ≈ log2·(log2 − log1) + (1/2)·(Hn 2 − Hn 1)`. -/
theorem t4Bh_eq : Req t4Bh
    (Radd (Rmul (logN 2 (by omega)) (Rsub (logN 2 (by omega)) (logN 1 (by omega))))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
        (Rsub (Hn 2 (by omega)) (Hn 1 (by omega))))) :=
  t4B_lower_eval 1 (by omega) (by omega) (logN 2 (by omega)) (by decide) (by decide)
    oneL_abs gLog1_lip gLog1_congr
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)
    (fun j => by show 5 * (j + 1) ≤ 6 * (j + 1); omega)

/-- **`[1/4, 1/2]`**: `∫ (2log2 + log x)/x` — pulls back to `log(1+t)/(1+t)
    = (1/2)·gLx 1`, the substitution constant cancelling the cone height. -/
def t4Bq : Real :=
  riemannIntegral
    (f := fun t => Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (gLx 1 t))
    (L := LxQ 1) (by decide) (by decide)
    (fun x y => lip_mono (Qmul_den_pos (by decide) (LxQ_den_pos 1)) (by decide)
      (by decide) (Rnonneg_Rabs _)
      (smul_lip (by decide) posHalf_abs (LxQ_den_pos 1) (LxQ_num_nonneg 1)
        (gLx_lip_of 1 (by omega) gLog1_lip) x y))
    (smul_congr (ofQ (⟨1, 2⟩ : Q) (by decide)) (gLx_congr_of 1 gLog1_congr))

/-- `t4Bq ≈ (1/2)·(Hn 2 − Hn 1)`. -/
theorem t4Bq_eq : Req t4Bq
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rsub (Hn 2 (by omega)) (Hn 1 (by omega)))) := by
  refine Req_trans (riemannIntegral_smul (⟨1, 2⟩ : Q) (by decide) (by decide) (by decide)
    (fun x y => lip_mono (LxQ_den_pos 1) (by decide) (by decide) (Rnonneg_Rabs _)
      (gLx_lip_of 1 (by omega) gLog1_lip x y))
    (gLx_congr_of 1 gLog1_congr) _ _) ?_
  exact Rmul_congr (Req_refl _)
    (riemannIntegral_gLx_gen 1 (by omega) (by omega) (by decide) (by decide)
      (fun x y => lip_mono (LxQ_den_pos 1) (by decide) (by decide) (Rnonneg_Rabs _)
        (gLx_lip_of 1 (by omega) gLog1_lip x y))
      (gLx_congr_of 1 gLog1_congr)
      (fun j => by show 5 * (j + 1) ≤ 5 * (j + 1); omega))

/-- **The `t4` test's `∫ f/x` pole component, CONSTRUCTED**: the five pieces summed. -/
def t4PoleB : Real := Radd (Radd (Radd t4B12 t4B23) (Radd t4B34 t4Bh)) t4Bq


-- ===========================================================================
-- Part 5: the assembly — `t4PoleB ≈ t4H·t4H` (`= 4(log2)²`, EXACT).
-- ===========================================================================

/-- `(d + d) ≈ 2·d` (private copy). -/
private theorem tb_two_smul (d : Real) :
    Req (Radd d d) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) d) :=
  Req_symm (Req_trans (Rmul_congr
      (Req_trans (ofQ_congr (by decide) (add_den_pos (by decide) (by decide))
        (by decide : Qeq (⟨2, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q))))
        (Req_symm (Radd_ofQ_ofQ (by decide) (by decide)))) (Req_refl d))
    (Req_trans (Rmul_comm (Radd one one) d)
      (Req_trans (Rmul_distrib d one one)
        (Radd_congr (Rmul_one d) (Rmul_one d)))))

/-- `log2 + log2 ≈ t4H`. -/
private theorem tb_LL : Req (Radd (logN 2 (by omega)) (logN 2 (by omega))) t4H :=
  tb_two_smul (logN 2 (by omega))

/-- `log 4 ≈ t4H`. -/
private theorem tb_l4 : Req (logN 4 (by omega)) t4H :=
  Req_trans (Req_symm (logN_mul_gen 2 2 (by omega) (by omega))) tb_LL

/-- The upper `A`-cluster telescopes: `Σ_c t4H·Δlog_c ≈ t4H·t4H`. -/
private theorem tb_Acluster :
    Req (Radd (Radd (Rmul t4H (Rsub (logN 2 (by omega)) (logN 1 (by omega))))
        (Rmul t4H (Rsub (logN 3 (by omega)) (logN 2 (by omega)))))
      (Rmul t4H (Rsub (logN 4 (by omega)) (logN 3 (by omega)))))
      (Rmul t4H t4H) := by
  refine Req_trans (Radd_congr (Req_symm (Rmul_distrib t4H
    (Rsub (logN 2 (by omega)) (logN 1 (by omega)))
    (Rsub (logN 3 (by omega)) (logN 2 (by omega)))))
    (Req_refl _)) ?_
  refine Req_trans (Req_symm (Rmul_distrib t4H _ _)) ?_
  refine Rmul_congr (Req_refl t4H) ?_
  refine Req_trans (Radd_congr (Req_trans (Radd_comm _ _)
    (Rsub_telescope (logN 3 (by omega)) (logN 2 (by omega)) (logN 1 (by omega))))
    (Req_refl _)) ?_
  refine Req_trans (Radd_comm _ _) ?_
  refine Req_trans (Rsub_telescope (logN 4 (by omega)) (logN 3 (by omega))
    (logN 1 (by omega))) ?_
  refine Req_trans (Rsub_congr (Req_refl _) logN_one) ?_
  exact Req_trans (Rsub_zero _) tb_l4

/-- The upper `B`-cluster telescopes: `Σ_c (−1/2)·ΔHn_c ≈ (−1/2)·(t4H·t4H)`. -/
private theorem tb_Bcluster :
    Req (Radd (Radd (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide))
        (Rsub (Hn 2 (by omega)) (Hn 1 (by omega))))
        (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide))
          (Rsub (Hn 3 (by omega)) (Hn 2 (by omega)))))
      (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide))
        (Rsub (Hn 4 (by omega)) (Hn 3 (by omega)))))
      (Rmul (ofQ (⟨-1, 2⟩ : Q) (by decide)) (Rmul t4H t4H)) := by
  refine Req_trans (Radd_congr (Req_symm (Rmul_distrib (ofQ (⟨-1, 2⟩ : Q) (by decide))
    (Rsub (Hn 2 (by omega)) (Hn 1 (by omega)))
    (Rsub (Hn 3 (by omega)) (Hn 2 (by omega))))) (Req_refl _)) ?_
  refine Req_trans (Req_symm (Rmul_distrib (ofQ (⟨-1, 2⟩ : Q) (by decide)) _ _)) ?_
  refine Rmul_congr (Req_refl _) ?_
  refine Req_trans (Radd_congr (Req_trans (Radd_comm _ _)
    (Rsub_telescope (Hn 3 (by omega)) (Hn 2 (by omega)) (Hn 1 (by omega))))
    (Req_refl _)) ?_
  refine Req_trans (Radd_comm _ _) ?_
  refine Req_trans (Rsub_telescope (Hn 4 (by omega)) (Hn 3 (by omega)) (Hn 1 (by omega))) ?_
  refine Req_trans (Rsub_congr (Req_refl _) Hn_one) ?_
  refine Req_trans (Rsub_zero _) ?_
  exact Rmul_congr tb_l4 tb_l4

/-- The `[1/2,1]` head: `log2·(log2 − log1) ≈ log2·log2`. -/
private theorem tb_C :
    Req (Rmul (logN 2 (by omega)) (Rsub (logN 2 (by omega)) (logN 1 (by omega))))
      (Rmul (logN 2 (by omega)) (logN 2 (by omega))) :=
  Rmul_congr (Req_refl _) (Req_trans (Rsub_congr (Req_refl _) logN_one) (Rsub_zero _))

/-- The two half-`ΔHn` tails sum to `Hn 2 = log2·log2`. -/
private theorem tb_D :
    Req (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
        (Rsub (Hn 2 (by omega)) (Hn 1 (by omega))))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
        (Rsub (Hn 2 (by omega)) (Hn 1 (by omega)))))
      (Rmul (logN 2 (by omega)) (logN 2 (by omega))) := by
  refine Req_trans (tb_smul_add (by decide) (by decide) _) ?_
  refine Req_trans (Rmul_congr (ofQ_congr (b := (⟨1, 1⟩ : Q))
    (add_den_pos (by decide) (by decide)) (by decide) (by decide)) (Req_refl _)) ?_
  refine Req_trans (Rone_mul _) ?_
  exact Req_trans (Rsub_congr (Req_refl _) Hn_one) (Rsub_zero _)

/-- `log2·log2 + log2·log2 ≈ (1/2)·(t4H·t4H)`. -/
private theorem tb_half :
    Req (Radd (Rmul (logN 2 (by omega)) (logN 2 (by omega)))
        (Rmul (logN 2 (by omega)) (logN 2 (by omega))))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul t4H t4H)) := by
  refine Req_trans (Req_symm (Rmul_distrib (logN 2 (by omega))
    (logN 2 (by omega)) (logN 2 (by omega)))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) tb_LL) ?_
  refine Req_symm ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 2⟩ : Q) (by decide)) t4H t4H)) ?_
  refine Rmul_congr ?_ (Req_refl t4H)
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 2⟩ : Q) (by decide))
    (ofQ (⟨((2 : Nat) : Int), 1⟩ : Q) Nat.one_pos) (logN 2 (by omega)))) ?_
  refine Req_trans (Rmul_congr (Req_trans (Rmul_ofQ_ofQ (by decide) Nat.one_pos)
    (ofQ_congr (b := (⟨1, 1⟩ : Q)) (Qmul_den_pos (by decide) Nat.one_pos)
      (by decide) (by decide))) (Req_refl _)) ?_
  exact Rone_mul _

set_option maxHeartbeats 1600000 in
/-- **★ `t4PoleB ≈ t4H·t4H = 4(log2)²` — the cone tent's `∫ f/x` pole component,
    EXACT**: the upper telescopes give `t4H·log4 − ½·Hn4 = 4L² − 2L²`, the lower
    pieces give `L² + L²`, and the halves cancel to the exact square. -/
theorem t4PoleB_eq : Req t4PoleB (Rmul t4H t4H) := by
  show Req (Radd (Radd (Radd t4B12 t4B23) (Radd t4B34 t4Bh)) t4Bq) _
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr t4B12_eq t4B23_eq)
    (Radd_congr t4B34_eq t4Bh_eq)) t4Bq_eq) ?_
  -- regroup ((U1+U2)+(U3+Lo1))+Lo2 ≈ ((U1+U2)+U3) + (Lo1+Lo2)
  refine Req_trans (Radd_congr (Req_symm (Radd_assoc _ _ _)) (Req_refl _)) ?_
  refine Req_trans (Radd_assoc _ _ _) ?_
  -- split the upper cluster into A- and B-parts (two swaps)
  refine Req_trans (Radd_congr (Req_trans (Radd_congr (Radd_swap _ _ _ _) (Req_refl _))
    (Radd_swap _ _ _ _)) (Req_refl _)) ?_
  -- evaluate the four clusters
  refine Req_trans (Radd_congr (Radd_congr tb_Acluster tb_Bcluster)
    (Req_trans (Radd_assoc _ _ _) (Radd_congr tb_C tb_D))) ?_
  -- (P + (−½)P) + (L² + L²) ≈ (P + (−½)P) + (½)P ≈ P
  refine Req_trans (Radd_congr (Req_refl _) tb_half) ?_
  refine Req_trans (Radd_assoc _ _ _) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_trans (tb_smul_add (by decide) (by decide) _)
      (Req_trans (Rmul_congr (ofQ_congr (b := (⟨0, 1⟩ : Q))
        (add_den_pos (by decide) (by decide)) (by decide) (by decide)) (Req_refl _))
        (Req_trans (Rmul_comm _ _) (Rmul_zero _))))) ?_
  exact Radd_zero _

end Multiplicity.UOR.Bridge.F1Square.Analysis
