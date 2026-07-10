/-
F1 square — v0.22.0 Track 1: **`arctan` is continuous (respects `Req`)** — `RarctanR_congr`, the
real-argument analog of `Rartanh_congr` (`ExpLog.lean`).

This is the foundation for lifting rational arctan/log identities (the artanh addition law, hence log
multiplicativity) to general real arguments, and for the well-definedness of `arg(z)` under `Req`.
Mirrors `Rartanh_congr` exactly with `artSum → arctanSum`: the diagonal gap is bounded by the
Lipschitz estimate `geoEvenSum ρ · |t−t'|` (`arctanSum_Lip_le`, `RArctan.lean`), with `geoEvenSum ≤ 2`
(`geoEvenSum_le_two`, shared and sign-independent) and `|t−t'| ≤ 2/(R+1)` from `Req`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.RArctan
import F1Square.Analysis.ExpLog
import F1Square.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

/-- **`arctan` is continuous (respects `Req`)**: if `t ≈ t'` (both bounded by `ρ < 1`) then
    `RarctanR t ≈ RarctanR t'`. Mirrors `Rartanh_congr`. -/
theorem RarctanR_congr (t t' : Real) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
    (hbt : ∀ n, Qle (Qabs (t.seq n)) ρ) (hbt' : ∀ n, Qle (Qabs (t'.seq n)) ρ) (heq : Req t t') :
    Req (RarctanR t ρ hρ0 hρd hlt hbt) (RarctanR t' ρ hρ0 hρd hlt hbt') := by
  refine Req_of_lin_bound (C := 4) ?_
  intro n
  show Qle (Qabs (Qsub (arctanSum (t.seq (Rartanh_R ρ n)) (Rartanh_R ρ n))
      (arctanSum (t'.seq (Rartanh_R ρ n)) (Rartanh_R ρ n)))) (⟨(4 : Int), n + 1⟩ : Q)
  have hdiffd : 0 < (Qsub (t.seq (Rartanh_R ρ n)) (t'.seq (Rartanh_R ρ n))).den :=
    Qsub_den_pos (t.den_pos _) (t'.den_pos _)
  refine Qle_trans (Qmul_den_pos (geoEvenSum_den_pos hρd _) (Qabs_den_pos hdiffd))
    (arctanSum_Lip_le (t.den_pos _) (t'.den_pos _) hρd (hbt _) (hbt' _) (Rartanh_R ρ n)) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos hdiffd))
    (Qmul_le_mul_right (Qabs_num_nonneg _) (geoEvenSum_le_two hρ0 hρd hρ2 (Rartanh_R ρ n))) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos _))
    (Qmul_le_mul_left (by decide) (heq (Rartanh_R ρ n))) ?_
  have hRge : n ≤ Rartanh_R ρ n := by
    unfold Rartanh_R
    have hk : 1 ≤ ρ.den * ρ.den + 4 * ρ.den :=
      Nat.le_trans (by omega : 1 ≤ 4 * ρ.den) (Nat.le_add_left _ _)
    calc n ≤ 1 * (n + 1) := by omega
      _ ≤ (ρ.den * ρ.den + 4 * ρ.den) * (n + 1) := Nat.mul_le_mul_right _ hk
  show (2 * 2 : Int) * ((n + 1 : Nat) : Int) ≤ (4 : Int) * ((1 * (Rartanh_R ρ n + 1) : Nat) : Int)
  push_cast; omega

-- ===========================================================================
-- The exp-injectivity core of any logarithm/artanh additivity: from the exp-VALUES,
-- `exp C = exp A · exp B = exp(A+B)`, so `C = A + B`. The parameter-thicket of computing the
-- exp-values (`exp(2·artanh τ) = (1+τ)/(1−τ)` per `Rexp_two_artanh_ofQ`) is isolated into the
-- explicit hypotheses `hA`/`hB`/`hC` — the honest computed input — leaving this clean and reusable.
-- ===========================================================================

/-- **Additivity from exp-values** (the `RexpReal_inj` core): if `exp A = gA`, `exp B = gB`,
    `exp C = gC` (as rationals) with `gC = gA·gB`, and `A, B, C ≥ 0`, then `C = A + B`. The engine for
    `2·artanh c = 2·artanh a + 2·artanh b` (with `gA = (1+a)/(1−a)` etc., `gC = gA·gB`), hence for log
    multiplicativity `log(xy) = log x + log y`. -/
theorem Req_add_of_exp_values {A B C : Real} {gA gB gC : Q}
    (hgAd : 0 < gA.den) (hgBd : 0 < gB.den) (hgCd : 0 < gC.den)
    (hA : Req (RexpReal A) (ofQ gA hgAd)) (hB : Req (RexpReal B) (ofQ gB hgBd))
    (hC : Req (RexpReal C) (ofQ gC hgCd)) (hg : Qeq gC (mul gA gB))
    (hAnn : Rnonneg A) (hBnn : Rnonneg B) (hCnn : Rnonneg C) :
    Req C (Radd A B) := by
  apply RexpReal_inj hCnn (Rnonneg_Radd hAnn hBnn)
  have hmul : Req (RexpReal (Radd A B)) (ofQ gC hgCd) :=
    Req_trans (RexpReal_add A B)
      (Req_trans (Rmul_congr hA hB)
        (Req_trans (Rmul_ofQ_ofQ hgAd hgBd)
          (ofQ_congr (Qmul_den_pos hgAd hgBd) hgCd (Qeq_symm hg))))
  exact Req_trans hC (Req_symm hmul)

end UOR.Bridge.F1Square.Analysis
