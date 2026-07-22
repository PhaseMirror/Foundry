/-
F1 square — **the `∫ log` layer, part 2c(v): the evaluation** (`LogIntegralEval.lean`).
The certified integral of the totalized log integrand:

    `∫₀¹ log(c+t) dt ≈ Gn(c+1) − Gn(c)`      (`= (c+1)log(c+1) − c·log c − 1`, `1 ≤ c ≤ 3`)

— the gateway objects `riemannIntegral (gLog c)` EVALUATE. Assembly of part 2c:
`riemannSum_gLog` (the collapse) + the `logFold` bracket + `Gn_scale_identity` give the
dyadic defect `|D_m − (Gn(c+1) − Gn(c))| ≤ (1/2^m)·hFold(c·2^m, 2^m) ≤ 1/2^m`
(`hFold_le_ratio`: the harmonic block is at most `M/A`); the anchor is
`D₀ = gLog c 0 ≈ log c`; the `digammaMidx` schedule and `Rlim_eval_real` finish, exactly
the `HarmonicLogC` template. Headline instances at `c = 1, 2, 3` on the certified
`1`-Lipschitz data — the three bases the `t4PoleA` pieces consume.

HONEST SCOPE. Three certified integral evaluations; no Weil-slot field is filled here
and no positivity is claimed. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogRiemann

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small algebra: private rearrangement helpers.
-- ===========================================================================

/-- `(X+Y) − Y ≈ X` (private copy). -/
private theorem le_add_sub_cancel (X Y : Real) : Req (Rsub (Radd X Y) Y) X :=
  Req_trans (Radd_assoc X Y (Rneg Y))
    (Req_trans (Radd_congr (Req_refl X) (Radd_neg Y)) (Radd_zero X))

/-- `(x − a) − b ≈ (x − b) − a` (subtrahend swap). -/
private theorem le_sub_swap (x a b : Real) :
    Req (Rsub (Rsub x a) b) (Rsub (Rsub x b) a) :=
  Req_trans (Radd_assoc x (Rneg a) (Rneg b))
    (Req_trans (Radd_congr (Req_refl x) (Radd_comm (Rneg a) (Rneg b)))
      (Req_symm (Radd_assoc x (Rneg b) (Rneg a))))

/-- `x − y ≤ c ⟹ x ≤ y + c`. -/
private theorem le_Radd_of_Rsub_le {x y c : Real} (h : Rle (Rsub x y) c) :
    Rle x (Radd y c) := by
  have h1 : Rle (Radd (Rsub x y) y) (Radd c y) := Radd_le_add h (Rle_refl y)
  have h2 : Req (Radd (Rsub x y) y) x :=
    Req_trans (Radd_assoc x (Rneg y) y)
      (Req_trans (Radd_congr (Req_refl x)
        (Req_trans (Radd_comm (Rneg y) y) (Radd_neg y))) (Radd_zero x))
  exact Rle_trans (Rle_of_Req (Req_symm h2)) (Rle_trans h1 (Rle_of_Req (Radd_comm c y)))

/-- `Gn` transport along an index equality. -/
private theorem Gn_eq_of_eq {n n' : Nat} (h : n = n') (hn : 1 ≤ n) (hn' : 1 ≤ n') :
    Req (Gn n hn) (Gn n' hn') := by subst h; exact Req_refl _

-- ===========================================================================
-- The harmonic-block ratio bound `hFold(A, M) ≤ M/A`.
-- ===========================================================================

/-- **The ratio bound**: `Σ_{k<M} 1/(A+k) ≤ M/A` (each term at most `1/A`). -/
theorem hFold_le_ratio (A : Nat) (hA : 1 ≤ A) : ∀ M, Qle (hFold A M) ⟨((M : Nat) : Int), A⟩
  | 0 => by
    show (0 : Int) * ((A : Nat) : Int) ≤ ((0 : Nat) : Int) * 1
    push_cast; omega
  | (M + 1) => by
    have hterm : Qle (⟨1, A + M⟩ : Q) (⟨1, A⟩ : Q) := by
      show (1 : Int) * ((A : Nat) : Int) ≤ 1 * ((A + M : Nat) : Int)
      push_cast; omega
    have hmid : 0 < (add (⟨((M : Nat) : Int), A⟩ : Q) (⟨1, A⟩ : Q)).den :=
      add_den_pos hA hA
    refine Qle_trans hmid
      (Qadd_le_add (hFold_le_ratio A hA M) hterm) (Qeq_le ?_)
    show Qeq (add (⟨((M : Nat) : Int), A⟩ : Q) (⟨1, A⟩ : Q)) (⟨((M + 1 : Nat) : Int), A⟩ : Q)
    simp only [Qeq, add]
    push_cast; ring_uor

/-- **The scaled defect bound**: `(1/2^m)·hFold(c·2^m, 2^m) ≤ 1/2^m` (`c ≥ 1`). -/
theorem scaled_hFold_le (c m : Nat) (hc : 1 ≤ c) :
    Qle (mul (⟨1, 2 ^ m⟩ : Q)
        (hFold (c * 2 ^ m) (2 ^ m)))
      (⟨1, 2 ^ m⟩ : Q) := by
  have hp : 1 ≤ 2 ^ m := Nat.one_le_two_pow
  have hcM : 1 ≤ c * 2 ^ m := Nat.mul_pos hc hp
  have h1 : Qle (mul (⟨1, 2 ^ m⟩ : Q) (hFold (c * 2 ^ m) (2 ^ m)))
      (mul (⟨1, 2 ^ m⟩ : Q) (⟨((2 ^ m : Nat) : Int), c * 2 ^ m⟩ : Q)) :=
    Qmul_le_mul_left (show (0 : Int) ≤ (⟨1, 2 ^ m⟩ : Q).num from (by decide : (0 : Int) ≤ 1))
      (hFold_le_ratio (c * 2 ^ m) hcM (2 ^ m))
  have hmid : 0 < (mul (⟨1, 2 ^ m⟩ : Q) (⟨((2 ^ m : Nat) : Int), c * 2 ^ m⟩ : Q)).den :=
    Qmul_den_pos hp hcM
  refine Qle_trans hmid h1 ?_
  show (1 * ((2 ^ m : Nat) : Int)) * ((2 ^ m : Nat) : Int)
    ≤ 1 * ((2 ^ m * (c * 2 ^ m) : Nat) : Int)
  have hNat : 2 ^ m * 2 ^ m ≤ 2 ^ m * (c * 2 ^ m) :=
    Nat.mul_le_mul_left (2 ^ m) (Nat.le_mul_of_pos_left (2 ^ m) hc)
  simp only [Int.one_mul]
  exact_mod_cast hNat

-- ===========================================================================
-- The dyadic sums: power transport, zero anchor, and the defect.
-- ===========================================================================

/-- The collapse transported along `M = M'` (the `2^m − 1 + 1 = 2^m` seam). -/
private theorem rsg_transport (c : Nat) (hc1 : 1 ≤ c) {M M' : Nat} (h : M = M')
    (hM : 0 < M) (hM' : 0 < M') :
    Req (Rsub (Rmul (ofQ (⟨1, M⟩ : Q) hM)
          (logFold (c * M) (Nat.mul_pos hc1 hM) M)) (logN M hM))
      (Rsub (Rmul (ofQ (⟨1, M'⟩ : Q) hM')
          (logFold (c * M') (Nat.mul_pos hc1 hM') M')) (logN M' hM')) := by
  subst h; exact Req_refl _

/-- `D_m ≈ (1/2^m)·logFold(c·2^m, 2^m) − log(2^m)`. -/
theorem dyadicR_gLog_pow (c m : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    Req (dyadicR (gLog c) m)
      (Rsub (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) (Nat.pos_pow_of_pos m (by omega)))
          (logFold (c * 2 ^ m) (Nat.mul_pos hc1 (Nat.pos_pow_of_pos m (by omega))) (2 ^ m)))
        (logN (2 ^ m) (Nat.pos_pow_of_pos m (by omega)))) := by
  have hE : 2 ^ m - 1 + 1 = 2 ^ m := by
    have : (1 : Nat) ≤ 2 ^ m := Nat.one_le_two_pow; omega
  exact Req_trans (riemannSum_gLog c (2 ^ m - 1) hc1 hc3)
    (rsg_transport c hc1 hE (Nat.succ_pos (2 ^ m - 1)) (Nat.pos_pow_of_pos m (by omega)))

/-- **The anchor**: `D₀ = gLog c (0) ≈ log c`. -/
theorem dyadicR_gLog_zero (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    Req (dyadicR (gLog c) 0) (logN c hc1) := by
  refine Req_trans (riemannSum_gLog c 0 hc1 hc3) ?_
  refine Req_trans (Rsub_congr (Req_refl _) logN_one) ?_
  refine Req_trans (Rsub_zero _) ?_
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (Radd_comm zero _) ?_
  refine Req_trans (Radd_zero _) ?_
  exact logN_eq_of_eq (n := c * (0 + 1) + 0) (n' := c)
    (by omega) (show 1 ≤ c * (0 + 1) + 0 by omega) hc1

/-- **The dyadic defect**: `|D_m − (Gn(c+1) − Gn(c))| ≤ 1/2^m`. -/
theorem dyadicR_gLog_defect (c m : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    Rle (Rabs (Rsub (dyadicR (gLog c) m)
        (Rsub (Gn (c + 1) (by omega)) (Gn c hc1))))
      (ofQ (⟨1, 2 ^ m⟩ : Q) (Nat.pos_pow_of_pos m (by omega))) := by
  have hp : 0 < 2 ^ m := Nat.pos_pow_of_pos m (by omega)
  have hp1 : (1 : Nat) ≤ 2 ^ m := hp
  have hcM : 1 ≤ c * 2 ^ m := Nat.mul_pos hc1 hp
  have hMd : 0 < (⟨1, 2 ^ m⟩ : Q).den := hp
  have hnn : Rnonneg (ofQ (⟨1, 2 ^ m⟩ : Q) hMd) :=
    Rnonneg_ofQ hMd (show (0 : Int) ≤ 1 by decide)
  -- the scaled `ΔGn` is the target plus `log(2^m)` (index seam `cM + M = (c+1)M`)
  have hseam : Req (Rsub (Gn (c * 2 ^ m + 2 ^ m) (by omega)) (Gn (c * 2 ^ m) hcM))
      (Rsub (Gn ((c + 1) * 2 ^ m) (Nat.mul_pos (by omega) hp)) (Gn (c * 2 ^ m) hcM)) :=
    Rsub_congr (Gn_eq_of_eq (Eq.symm (Nat.succ_mul c (2 ^ m))) (by omega)
      (Nat.mul_pos (by omega) hp)) (Req_refl _)
  have hscale : Req (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
      (Rsub (Gn (c * 2 ^ m + 2 ^ m) (by omega)) (Gn (c * 2 ^ m) hcM)))
      (Radd (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (logN (2 ^ m) hp)) :=
    Req_trans (Rmul_congr (Req_refl _) hseam) (Gn_scale_identity c (2 ^ m) hc1 hp1)
  -- UPPER: `D_m ≤ T`
  have hup : Rle (dyadicR (gLog c) m)
      (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) := by
    have h1 : Rle (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
        (logFold (c * 2 ^ m) (Nat.mul_pos hc1 hp) (2 ^ m)))
        (Radd (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (logN (2 ^ m) hp)) :=
      Rle_trans (Rmul_le_Rmul_left hnn (logFold_le_Gn (c * 2 ^ m) (2 ^ m) hcM))
        (Rle_of_Req hscale)
    refine Rle_trans (Rle_of_Req (dyadicR_gLog_pow c m hc1 hc3)) ?_
    refine Rle_trans (Radd_le_add h1 (Rle_refl (Rneg (logN (2 ^ m) hp)))) ?_
    exact Rle_of_Req (le_add_sub_cancel _ (logN (2 ^ m) hp))
  -- LOWER: `T − (1/2^m)·hFold ≤ D_m`
  have hlow : Rle (Rsub (Rsub (Gn (c + 1) (by omega)) (Gn c hc1))
      (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
        (ofQ (hFold (c * 2 ^ m) (2 ^ m)) (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m)))))
      (dyadicR (gLog c) m) := by
    have h1 : Rle (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
        (Rsub (Rsub (Gn (c * 2 ^ m + 2 ^ m) (by omega)) (Gn (c * 2 ^ m) hcM))
          (ofQ (hFold (c * 2 ^ m) (2 ^ m)) (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m)))))
        (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
          (logFold (c * 2 ^ m) (Nat.mul_pos hc1 hp) (2 ^ m))) :=
      Rmul_le_Rmul_left hnn (Gn_le_logFold (c * 2 ^ m) (2 ^ m) hcM)
    have h2 : Req (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
        (Rsub (Rsub (Gn (c * 2 ^ m + 2 ^ m) (by omega)) (Gn (c * 2 ^ m) hcM))
          (ofQ (hFold (c * 2 ^ m) (2 ^ m)) (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m)))))
        (Rsub (Radd (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (logN (2 ^ m) hp))
          (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
            (ofQ (hFold (c * 2 ^ m) (2 ^ m)) (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m))))) :=
      Req_trans (Rmul_sub_distrib _ _ _) (Rsub_congr hscale (Req_refl _))
    -- subtract `log(2^m)` from both sides of `h1∘h2` and rearrange
    have h3 : Rle (Rsub (Rsub (Radd (Rsub (Gn (c + 1) (by omega)) (Gn c hc1))
          (logN (2 ^ m) hp))
        (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
          (ofQ (hFold (c * 2 ^ m) (2 ^ m)) (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m)))))
        (logN (2 ^ m) hp))
        (dyadicR (gLog c) m) := by
      refine Rle_trans (Radd_le_add (Rle_trans (Rle_of_Req (Req_symm h2)) h1)
        (Rle_refl (Rneg (logN (2 ^ m) hp)))) ?_
      exact Rle_of_Req (Req_symm (dyadicR_gLog_pow c m hc1 hc3))
    refine Rle_trans (Rle_of_Req (Req_symm (Req_trans (le_sub_swap _ _ _)
      (Rsub_congr (le_add_sub_cancel _ (logN (2 ^ m) hp)) (Req_refl _))))) h3
  -- assemble the absolute defect
  refine Rabs_le_of_both ?_ ?_
  · exact Rle_trans (Rsub_nonpos_of_Rle hup) (Rle_zero_of_Rnonneg hnn)
  · refine Rle_trans (Rle_of_Req (Rneg_Rsub _ _)) ?_
    have h4 : Rle (Rsub (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (dyadicR (gLog c) m))
        (Rmul (ofQ (⟨1, 2 ^ m⟩ : Q) hMd)
          (ofQ (hFold (c * 2 ^ m) (2 ^ m)) (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m)))) :=
      Rsub_le_of_le_Radd (Rle_trans (le_Radd_of_Rsub_le hlow)
        (Rle_of_Req (Radd_comm _ _)))
    refine Rle_trans h4 ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hMd
      (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m)))) ?_
    exact Rle_ofQ_ofQ (Qmul_den_pos hMd (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m))) hMd
      (scaled_hFold_le c m hc1)

-- ===========================================================================
-- The rate at the schedule, and the evaluation.
-- ===========================================================================

/-- The rate at dyadic depth `m` with `j + 1 ≤ 2^m`. -/
private theorem genSum_gLog_rate_aux (c m j : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3)
    (hjm : j + 1 ≤ 2 ^ m) :
    Rle (Rabs (Rsub (genSum (dyadicTerm (gLog c)) m)
        (Rsub (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (logN c hc1))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hgen : Req (genSum (dyadicTerm (gLog c)) m)
      (Rsub (dyadicR (gLog c) m) (logN c hc1)) :=
    Req_trans (genSum_telescope (gLog c) m)
      (Rsub_congr (Req_refl _) (dyadicR_gLog_zero c hc1 hc3))
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_congr hgen (Req_refl _))
    (Rsub_shift_drop _ (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (logN c hc1))))) ?_
  refine Rle_trans (dyadicR_gLog_defect c m hc1 hc3) ?_
  refine Rle_ofQ_ofQ (Nat.pos_pow_of_pos m (by omega)) (Nat.succ_pos j) ?_
  show (1 : Int) * ((j + 1 : Nat) : Int) ≤ 1 * ((2 ^ m : Nat) : Int)
  have hcast : ((j + 1 : Nat) : Int) ≤ ((2 ^ m : Nat) : Int) := Int.ofNat_le.mpr hjm
  omega

/-- **The dyadic rate**: the telescoped sums sit within `1/(j+1)` of
    `(Gn(c+1) − Gn(c)) − log c`, for every schedule. -/
theorem genSum_gLog_rate (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm (gLog c)) (digammaMidx L j))
        (Rsub (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (logN c hc1))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine genSum_gLog_rate_aux c (digammaMidx L j) j hc1 hc3 ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ log(c+t) dt ≈ Gn(c+1) − Gn(c)`, general in the base and the Lipschitz
    datum** — the log-integral evaluation (`= (c+1)log(c+1) − c·log c − 1`). -/
theorem riemannIntegral_logC_gen (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (gLog c x) (gLog c y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (gLog c x) (gLog c y)) :
    Req (riemannIntegral (f := gLog c) hLd hLn hlip hfc)
      (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) := by
  show Req (Radd (dyadicR (gLog c) 0) _) _
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm (gLog c)) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (Rsub (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (logN c hc1)) :=
    Rlim_eval_real _ _ (fun j => genSum_gLog_rate c hc1 hc3 L j)
  refine Req_trans (Radd_congr (dyadicR_gLog_zero c hc1 hc3) hlim) ?_
  exact Radd_Rsub_cancel (Rsub (Gn (c + 1) (by omega)) (Gn c hc1)) (logN c hc1)

/-- **`∫₀¹ log(1+t) dt ≈ Gn(2) − Gn(1)`** (`= 2log2 − 1`). -/
theorem riemannIntegral_logC1 :
    Req (riemannIntegral (f := gLog 1) (L := (⟨1, 1⟩ : Q)) Nat.one_pos (by decide)
        gLog1_lip gLog1_congr)
      (Rsub (Gn 2 (by omega)) (Gn 1 (by omega))) :=
  riemannIntegral_logC_gen 1 (by omega) (by omega) Nat.one_pos (by decide)
    gLog1_lip gLog1_congr

/-- **`∫₀¹ log(2+t) dt ≈ Gn(3) − Gn(2)`** (`= 3log3 − 2log2 − 1`). -/
theorem riemannIntegral_logC2 :
    Req (riemannIntegral (f := gLog 2) (L := (⟨1, 1⟩ : Q)) Nat.one_pos (by decide)
        gLog2_lip gLog2_congr)
      (Rsub (Gn 3 (by omega)) (Gn 2 (by omega))) :=
  riemannIntegral_logC_gen 2 (by omega) (by omega) Nat.one_pos (by decide)
    gLog2_lip gLog2_congr

/-- **`∫₀¹ log(3+t) dt ≈ Gn(4) − Gn(3)`** (`= 8log2 − 3log3 − 1`). -/
theorem riemannIntegral_logC3 :
    Req (riemannIntegral (f := gLog 3) (L := (⟨1, 1⟩ : Q)) Nat.one_pos (by decide)
        gLog3_lip gLog3_congr)
      (Rsub (Gn 4 (by omega)) (Gn 3 (by omega))) :=
  riemannIntegral_logC_gen 3 (by omega) (by omega) Nat.one_pos (by decide)
    gLog3_lip gLog3_congr

end UOR.Bridge.F1Square.Analysis
