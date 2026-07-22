/-
F1 square — constant precision: **the `log 4π` LOWER bracket** (`log 4π ≥ 2.53038`) and the
first TWO-SIDED Li coefficient (`λ₁ ≤ 0.02381`, joining `Rlambda1_pos`).

WHY. The substrate carried only UPPER log brackets (`Rlog2c_le`, `Rlogπc_le` — built for the
λ-positivity proofs, where `log 4π` enters negatively) plus the crude `log π ≥ 1`
(`LogPiLower`). Every λ UPPER bound needs the complement — `log 4π` from BELOW — and λ upper
bounds are what the Gate-A finite-list prunes consume next (the general order-1 class
`(K, a) = (1, c)` dies on `λ₃λ₁ ≉ λ₂²`, which needs λ uppers; `Square/GateAFiniteList.lean`).
This brick supplies the missing side with the same certified-series discipline:

- `artSum_le_base` — NEW substrate lemma: the artanh partial sum is monotone in the BASE
  (via `qpow_le_base`), the lower-side companion of the dominance used by `Rlogπc_le`.
- `Rpi_seq_ge_314` — every Machin approximant is `≥ 3.14`: the depth-6 sharpening of
  `Rpi_seq_ge_three` (`arctan(1/5) ≥ 0.197354`, `arctan(1/239) ≤ 0.004226`, tail `(1/2)¹⁵`),
  giving `π_seq ≥ 16·0.197354 − 4·0.004226 = 3.14076`.
- `tmap_ge_314` — `q ≥ 314/100 ⟹ (q−1)/(q+1) ≥ 107/207` (the cleared form is exactly
  `100·q ≥ 314`), hence `RpiTmap.seq n ≥ 107/207` pointwise (`RpiTmap_ge_107207`).
- `Rlog2c_ge_69314` — `log 2 ≥ 0.69314`: the artanh(1/3) partial sum at depth 8 is a LOWER
  bound (all terms positive; `artSum_mono` + the reindex `Rartanh_R (1/3) m = 21(m+1) ≥ 8`).
- `Rlogpic_ge_11441` — `log π ≥ 1.1441`: `artanh(RpiTmap) ≥ artSum(107/207, 5)` by
  base-monotonicity + depth-monotonicity (`Rartanh_R (15/29) m = 957(m+1) ≥ 5`).
- `Rlog4pic_ge` — **`log 4π ≥ 253038/100000 = 2.53038`** (true value `2.531024`).
- `Rtwolambda1_le` / **`Rlambda1_le`** — `2λ₁ = 2 + γ − log4π ≤ 0.04762`, so
  **`λ₁ ≤ 2381/100000 = 0.02381`** (true value `0.0230957`): with `Rlambda1_pos`, the first
  Li coefficient is now bracketed two-sidedly. This is the enabling bracket for the
  next Gate-A class prunes (λ-upper-side arithmetic).

HONEST SCOPE. Finite certified brackets; no positivity claim beyond `n = 1`; the crux
fields stay `none` (the uniform `∀ n` = RH is untouched).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LambdaOne
import Core.F1.Analysis.GammaZeroBracket
import Core.F1.Analysis.RealPow
import Core.F1.Analysis.GammaOne

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Base-monotonicity of the artanh partial sums (the lower-side companion of
-- the dominance bound behind `Rlogπc_le`).
-- ===========================================================================

/-- `qpow` is monotone in a non-negative base. -/
theorem qpow_le_base {q t : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (ht0 : 0 ≤ t.num)
    (htd : 0 < t.den) (h : Qle q t) : ∀ k, Qle (qpow q k) (qpow t k) := by
  intro k
  induction k with
  | zero => exact Qle_refl _
  | succ k ih =>
    rw [qpow_succ q k, qpow_succ t k]
    exact Qle_trans (Qmul_den_pos hqd (qpow_den_pos htd k))
      (Qmul_le_mul_left hq0 ih) (Qmul_le_mul_right (qpow_nonneg ht0 k) h)

/-- Each artanh term is monotone in a non-negative base. -/
theorem artTerm_le_base {q t : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (ht0 : 0 ≤ t.num)
    (htd : 0 < t.den) (h : Qle q t) (n : Nat) : Qle (artTerm q n) (artTerm t n) :=
  Qmul_le_mul_right (by show (0 : Int) ≤ 1; decide)
    (qpow_le_base hq0 hqd ht0 htd h (2 * n + 1))

/-- **The artanh partial sum is monotone in a non-negative base** — the NEW substrate lemma
    this brick rests on (`artSum_mono` is depth-monotonicity; this is base-monotonicity). -/
theorem artSum_le_base {q t : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) (ht0 : 0 ≤ t.num)
    (htd : 0 < t.den) (h : Qle q t) : ∀ N, Qle (artSum q N) (artSum t N) := by
  intro N
  induction N with
  | zero => exact artTerm_le_base hq0 hqd ht0 htd h 0
  | succ N ih => exact Qadd_le_add ih (artTerm_le_base hq0 hqd ht0 htd h (N + 1))

-- ===========================================================================
-- π approximants ≥ 3.14 (depth-6 sharpening of `Rpi_seq_ge_three`).
-- ===========================================================================

/-- Depth `a = 6` is admissible at every diagonal index used by `Rpi_seq`
    (the reindex is `12·(20j+20) ≥ 240`). -/
private theorem six_le_Rpi_reindex (j : Nat) : 6 ≤ Rartanh_R (⟨1, 2⟩ : Q) (20 * j + 19) := by
  unfold Rartanh_R
  show 6 ≤ (2 * 2 + 4 * 2) * (20 * j + 19 + 1)
  omega

/-- **Every Machin approximant is `≥ 3.14`** — from `arctan(1/5) ≥ 197354/10⁶` and
    `arctan(1/239) ≤ 4226/10⁶` at truncation depth `a = 6` (tail `(1/2)¹⁵ = 1/32768`), giving
    `π_seq ≥ 16·0.197354 − 4·0.004226 = 3.14076`. Sharpens `Rpi_seq_ge_three`. -/
theorem Rpi_seq_ge_314 (n : Nat) : Qle (⟨314, 100⟩ : Q) (Rpi_seq n) := by
  have hL5 : Qle (⟨197354, 1000000⟩ : Q) (arctanSum ⟨1, 5⟩ (Rpi_g n)) :=
    arctanSum_diag_ge_at ⟨1, 5⟩ (by decide) (ρ := ⟨1, 2⟩) (by decide) (by decide) (by decide)
      (by decide) 6 (by decide) (by decide) (six_le_Rpi_reindex n)
  have hU239 : Qle (arctanSum ⟨1, 239⟩ (Rpi_g n)) (⟨4226, 1000000⟩ : Q) :=
    arctanSum_diag_le_at ⟨1, 239⟩ (by decide) (ρ := ⟨1, 2⟩) (by decide) (by decide) (by decide)
      (by decide) 6 (by decide) (by decide) (six_le_Rpi_reindex n)
  have hmid : Qle (Qsub (mul ⟨16, 1⟩ (⟨197354, 1000000⟩ : Q)) (mul ⟨4, 1⟩ (⟨4226, 1000000⟩ : Q)))
      (Rpi_seq n) :=
    Qsub_le_2 (Qmul_le_mul_left (by decide) hL5) (Qmul_le_mul_left (by decide) hU239)
  exact Qle_trans (by decide) (by decide) hmid

/-- **`tmap(q) ≥ 107/207` for `q ≥ 3.14`**: cleared, `(q−1)/(q+1) ≥ 107/207 ⟺ 100q ≥ 314`
    (note `107/207 = tmap(314/100)` exactly). Sharpens `tmap_ge_half`. -/
theorem tmap_ge_314 {q : Q} (hqd : 0 < q.den) (hq : Qle (⟨314, 100⟩ : Q) q) :
    Qle (⟨107, 207⟩ : Q) (tmap q) := by
  have hqn : 314 * (q.den : Int) ≤ 100 * q.num := by
    have h := hq; simp only [Qle] at h; push_cast at h; omega
  have hdpos : (0 : Int) < (q.den : Int) := by exact_mod_cast hqd
  simp only [tmap, Qle, mul, Qsub, Qinv, add, neg]
  push_cast
  rw [Int.toNat_of_nonneg (show (0 : Int) ≤ q.num * 1 + 1 * (q.den : Int) by omega)]
  have hnn : (0 : Int) ≤ (q.den : Int) * (100 * q.num - 314 * (q.den : Int)) :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (by omega)
  have hd : (q.num * 1 + -1 * (q.den : Int)) * ((q.den : Int) * 1) * 207
        - 107 * ((q.den : Int) * 1 * (q.num * 1 + 1 * (q.den : Int)))
      = (q.den : Int) * (100 * q.num - 314 * (q.den : Int)) := by ring_uor
  omega

/-- `RpiTmap ≥ 107/207` at every approximant (`π_seq ≥ 3.14` + `tmap` monotonicity). -/
theorem RpiTmap_ge_107207 (n : Nat) : Qle (⟨107, 207⟩ : Q) (RpiTmap.seq n) :=
  tmap_ge_314 (Rpi_seq_den_pos (Rlog_R n)) (Rpi_seq_ge_314 (Rlog_R n))

-- ===========================================================================
-- The log lower brackets.
-- ===========================================================================

/-- `artanh(1/3) ≥ artSum(1/3, 8)` — the depth-8 partial sum is a lower bound (all terms
    positive; the reindex `Rartanh_R (1/3) m = 21(m+1) ≥ 8`). -/
theorem Rartanh_third_ge :
    Rle (ofQ (artSum ⟨1, 3⟩ 8) (artSum_den_pos (by decide) 8))
      (Rartanh (ofQ ⟨1, 3⟩ (by decide)) ⟨1, 3⟩ (by decide) (by decide) (by decide)
        (fun _ => Qle_refl ⟨1, 3⟩)) := by
  intro m
  show Qle (artSum ⟨1, 3⟩ 8)
    (add (artSum ⟨1, 3⟩ (Rartanh_R ⟨1, 3⟩ m)) ⟨2, m + 1⟩)
  have hdepth : 8 ≤ Rartanh_R (⟨1, 3⟩ : Q) m := by
    unfold Rartanh_R
    show 8 ≤ (3 * 3 + 4 * 3) * (m + 1)
    omega
  exact Qle_trans (artSum_den_pos (by decide) _)
    (artSum_mono (by decide) (by decide) hdepth)
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- `log 2 ≥ 2·artSum(1/3, 8)`. -/
theorem Rlog2c_ge :
    Rle (ofQ (mul ⟨2, 1⟩ (artSum ⟨1, 3⟩ 8))
        (Qmul_den_pos (by decide) (artSum_den_pos (by decide) 8))) Rlog2c := by
  have hstep : Rle
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (ofQ (artSum ⟨1, 3⟩ 8) (artSum_den_pos (by decide) 8)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rartanh (ofQ ⟨1, 3⟩ (by decide)) ⟨1, 3⟩ (by decide) (by decide) (by decide)
          (fun _ => Qle_refl ⟨1, 3⟩))) :=
    Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rartanh_third_ge
  refine Rle_trans ?_ hstep
  exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (artSum_den_pos (by decide) 8)))

/-- **`log 2 ≥ 0.69314`** (true value `0.693147...`) — the lower companion of `Rlog2c_le`. -/
theorem Rlog2c_ge_69314 : Rle (ofQ (⟨69314, 100000⟩ : Q) (by decide)) Rlog2c :=
  Rle_trans (Rle_ofQ_ofQ (by decide)
    (Qmul_den_pos (by decide) (artSum_den_pos (by decide) 8)) (by decide)) Rlog2c_ge

/-- `artanh((π−1)/(π+1)) ≥ artSum(107/207, 5)`: base-monotonicity (`RpiTmap.seq ≥ 107/207`)
    then depth-monotonicity (`Rartanh_R (15/29) m = 957(m+1) ≥ 5`). -/
theorem Rartanh_RpiTmap_ge_deep :
    Rle (ofQ (artSum ⟨107, 207⟩ 5) (artSum_den_pos (by decide) 5))
      (Rartanh RpiTmap ⟨15, 29⟩ (by decide) (by decide) (by decide) RpiTmap_abs_le) := by
  intro m
  show Qle (artSum ⟨107, 207⟩ 5)
    (add (artSum (RpiTmap.seq (Rartanh_R ⟨15, 29⟩ m)) (Rartanh_R ⟨15, 29⟩ m)) ⟨2, m + 1⟩)
  have hdepth : 5 ≤ Rartanh_R (⟨15, 29⟩ : Q) m := by
    unfold Rartanh_R
    show 5 ≤ (29 * 29 + 4 * 29) * (m + 1)
    omega
  have h1 : Qle (artSum ⟨107, 207⟩ 5) (artSum ⟨107, 207⟩ (Rartanh_R ⟨15, 29⟩ m)) :=
    artSum_mono (by decide) (by decide) hdepth
  have h2 : Qle (artSum ⟨107, 207⟩ (Rartanh_R ⟨15, 29⟩ m))
      (artSum (RpiTmap.seq (Rartanh_R ⟨15, 29⟩ m)) (Rartanh_R ⟨15, 29⟩ m)) :=
    artSum_le_base (by decide) (by decide) (RpiTmap_nonneg _) (RpiTmap.den_pos _)
      (RpiTmap_ge_107207 _) _
  exact Qle_trans (artSum_den_pos (by decide) _) h1
    (Qle_trans (artSum_den_pos (RpiTmap.den_pos _) _) h2
      (Qle_self_add (by show (0 : Int) ≤ 2; decide)))

/-- `log π ≥ 2·artSum(107/207, 5)`. -/
theorem Rlogpic_ge :
    Rle (ofQ (mul ⟨2, 1⟩ (artSum ⟨107, 207⟩ 5))
        (Qmul_den_pos (by decide) (artSum_den_pos (by decide) 5))) Rlogπc := by
  have hstep : Rle
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (ofQ (artSum ⟨107, 207⟩ 5) (artSum_den_pos (by decide) 5)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rartanh RpiTmap ⟨15, 29⟩ (by decide) (by decide) (by decide) RpiTmap_abs_le)) :=
    Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rartanh_RpiTmap_ge_deep
  refine Rle_trans ?_ hstep
  exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (artSum_den_pos (by decide) 5)))

/-- **`log π ≥ 1.1441`** (true value `1.144729...`) — the sharp lower companion of
    `Rlogπc_le` (`≤ 1.1453`), replacing the crude `Rlogpi_ge_one`. -/
theorem Rlogpic_ge_11441 : Rle (ofQ (⟨11441, 10000⟩ : Q) (by decide)) Rlogπc :=
  Rle_trans (Rle_ofQ_ofQ (by decide)
    (Qmul_den_pos (by decide) (artSum_den_pos (by decide) 5)) (by decide)) Rlogpic_ge

/-- **THE `log 4π` LOWER BRACKET**: `log 4π ≥ 253038/100000 = 2.53038` (true value
    `2.531024`; upper companion `Rlog4pic_le = 2.5316`). The missing side is closed. -/
theorem Rlog4pic_ge : Rle (ofQ (⟨253038, 100000⟩ : Q) (by decide)) Rlog4pic := by
  have h22 : Rle (Radd (ofQ (⟨69314, 100000⟩ : Q) (by decide)) (ofQ (⟨69314, 100000⟩ : Q) (by decide)))
      (Radd Rlog2c Rlog2c) := Radd_le_add Rlog2c_ge_69314 Rlog2c_ge_69314
  have h3 : Rle (Radd (Radd (ofQ (⟨69314, 100000⟩ : Q) (by decide))
        (ofQ (⟨69314, 100000⟩ : Q) (by decide))) (ofQ (⟨11441, 10000⟩ : Q) (by decide)))
      Rlog4pic := Radd_le_add h22 Rlogpic_ge_11441
  have hstep1 : Rle (ofQ (⟨253038, 100000⟩ : Q) (by decide))
      (ofQ (add (add (⟨69314, 100000⟩ : Q) (⟨69314, 100000⟩ : Q)) (⟨11441, 10000⟩ : Q))
        (add_den_pos (add_den_pos (by decide) (by decide)) (by decide))) :=
    Rle_ofQ_ofQ (by decide)
      (add_den_pos (add_den_pos (by decide) (by decide)) (by decide)) (by decide)
  have hstep2 : Rle (ofQ (add (add (⟨69314, 100000⟩ : Q) (⟨69314, 100000⟩ : Q)) (⟨11441, 10000⟩ : Q))
        (add_den_pos (add_den_pos (by decide) (by decide)) (by decide)))
      (Radd (ofQ (add (⟨69314, 100000⟩ : Q) (⟨69314, 100000⟩ : Q))
          (add_den_pos (by decide) (by decide)))
        (ofQ (⟨11441, 10000⟩ : Q) (by decide))) :=
    Rle_ofQ_add_Radd (add_den_pos (by decide) (by decide)) (by decide)
  have hstep3 : Rle (Radd (ofQ (add (⟨69314, 100000⟩ : Q) (⟨69314, 100000⟩ : Q))
          (add_den_pos (by decide) (by decide)))
        (ofQ (⟨11441, 10000⟩ : Q) (by decide)))
      (Radd (Radd (ofQ (⟨69314, 100000⟩ : Q) (by decide)) (ofQ (⟨69314, 100000⟩ : Q) (by decide)))
        (ofQ (⟨11441, 10000⟩ : Q) (by decide))) :=
    Radd_le_add (Rle_ofQ_add_Radd (by decide) (by decide))
      (Rle_refl (ofQ (⟨11441, 10000⟩ : Q) (by decide)))
  exact Rle_trans hstep1 (Rle_trans hstep2 (Rle_trans hstep3 h3))

-- ===========================================================================
-- The first two-sided Li coefficient: λ₁ ≤ 0.02381.
-- ===========================================================================

/-- `2λ₁ = 2 + γ − log 4π ≤ 2 + 0.578 − 2.53038 = 0.04762`. -/
theorem Rtwolambda1_le : Rle Rtwolambda1 (ofQ (⟨4762, 100000⟩ : Q) (by decide)) := by
  have hng : Rle (Rneg Rlog4pic) (ofQ (neg (⟨253038, 100000⟩ : Q)) (by decide)) :=
    Rle_trans (Rneg_le Rlog4pic_ge)
      (Rle_of_Req (Rneg_ofQ (⟨253038, 100000⟩ : Q) (by decide)))
  have h2g : Rle (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma_h)
      (ofQ (add (⟨2, 1⟩ : Q) (⟨578, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add (Rle_refl (ofQ (⟨2, 1⟩ : Q) (by decide))) Rgamma_h_le_578)
      (Radd_Rle_ofQ_add (by decide) (by decide))
  refine Rle_trans (Radd_le_add h2g hng) ?_
  refine Rle_trans (Radd_Rle_ofQ_add (by decide) (by decide)) ?_
  exact Rle_ofQ_ofQ (add_den_pos (by decide) (by decide)) (by decide) (by decide)

/-- **`λ₁ ≤ 2381/100000 = 0.02381`** (true value `0.0230957`). With `Rlambda1_pos`, the first
    Li coefficient is now TWO-SIDED — the first λ with both certified sides, and the
    enabling bracket for the λ-upper-side Gate-A class prunes. -/
theorem Rlambda1_le : Rle Rlambda1 (ofQ (⟨2381, 100000⟩ : Q) (by decide)) := by
  refine Rle_trans (Rhalf_le_Rhalf Rtwolambda1_le) ?_
  refine Rle_trans (Rle_of_Req (Rhalf_ofQ (⟨4762, 100000⟩ : Q) (by decide))) ?_
  exact Rle_ofQ_ofQ (Qmul_den_pos (by decide) (by decide)) (by decide) (by decide)

end UOR.Bridge.F1Square.Analysis
