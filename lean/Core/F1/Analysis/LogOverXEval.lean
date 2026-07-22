/-
F1 square — **the `∫ log/x` layer, part 8b-ii: the dyadic defect** (`LogOverXEval.lean`).
The convergence core of `∫₀¹ 2·log(c+t)/(c+t) dt = Hn(c+1) − Hn(c)`:

    `|D_m − (Hn(c+1) − Hn(c))| ≤ (5m + 5)/2^m`

assembled from the collapse (`riemannSum_gLx`), the capped sample bracket
(`Hn_sample_upper_cap` at cap `2m+4` via `lxr_cap`, and `Hn_sample_lower`), the scale
identity (`Hn_scale_diff` — the `2·log(2^m)·(log(c+1) − log c)` cross term), and the
harmonic wedge (`hFoldC_defect` — the collapse's `−2·log(2^m)·hFold` absorbs the cross
term within `2m/(c(c+1)2^m)`). The three slacks total `(4m+5)/2^m ≤ (5m+5)/2^m`, the
shape the `digammaMidx` schedule absorbs (`lxr_sched`).

HONEST SCOPE. A defect bound between constructed objects; the integral evaluation
itself (`Rlim_eval_real` + instances) is the companion brick. No positivity claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogOverXRate
import Core.F1.Analysis.TentLogPiece

namespace UOR.Bridge.F1Square.Analysis

/-- `Hn` transport along an index equality. -/
private theorem lxe_Hn_eq {n n' : Nat} (h : n = n') (hn : 1 ≤ n) (hn' : 1 ≤ n') :
    Req (Hn n hn) (Hn n' hn') := by subst h; exact Req_refl _

/-- `(X+Y) − Y ≈ X` (private copy). -/
private theorem lxe_add_sub_cancel (X Y : Real) : Req (Rsub (Radd X Y) Y) X :=
  Req_trans (Radd_assoc X Y (Rneg Y))
    (Req_trans (Radd_congr (Req_refl X) (Radd_neg Y)) (Radd_zero X))

/-- `x − y ≤ q ⟹ x ≤ y + q` (private copy). -/
private theorem lxe_le_Radd {x y q : Real} (h : Rle (Rsub x y) q) : Rle x (Radd y q) := by
  have h1 : Rle (Radd (Rsub x y) y) (Radd q y) := Radd_le_add h (Rle_refl y)
  have h2 : Req (Radd (Rsub x y) y) x :=
    Req_trans (Radd_assoc x (Rneg y) y)
      (Req_trans (Radd_congr (Req_refl x)
        (Req_trans (Radd_comm (Rneg y) y) (Radd_neg y))) (Radd_zero x))
  exact Rle_trans (Rle_of_Req (Req_symm h2)) (Rle_trans h1 (Rle_of_Req (Radd_comm q y)))

/-- The insertion `(x − u) − t ≈ (x − d) + ((d − u) − t)`. -/
private theorem lxe_insert (x u t d : Real) :
    Req (Rsub (Rsub x u) t) (Radd (Rsub x d) (Rsub (Rsub d u) t)) :=
  Req_symm (Req_trans (Radd_congr (Req_refl (Rsub x d))
      (Req_symm (Rsub_Radd_eq d u t)))
    (Req_trans (Rsub_telescope x d (Radd u t)) (Rsub_Radd_eq x u t)))

/-- The collapse transported along `M = M'` (the `2^m − 1 + 1 = 2^m` seam). -/
private theorem lxe_transport (c : Nat) (hc1 : 1 ≤ c) {M M' : Nat} (h : M = M')
    (hM : 0 < M) (hM' : 0 < M') :
    Req (Rsub (hsSample (c * M) (Nat.mul_pos hc1 hM) M)
        (Rmul (Radd (logN M hM) (logN M hM))
          (ofQ (hFold (c * M) M) (hFold_den_pos (c * M) (Nat.mul_pos hc1 hM) M))))
      (Rsub (hsSample (c * M') (Nat.mul_pos hc1 hM') M')
        (Rmul (Radd (logN M' hM') (logN M' hM'))
          (ofQ (hFold (c * M') M') (hFold_den_pos (c * M') (Nat.mul_pos hc1 hM') M')))) := by
  subst h; exact Req_refl _

/-- `D_m ≈ hsSample(c·2^m, 2^m) − 2·log(2^m)·hFold(c·2^m, 2^m)`. -/
theorem dyadicR_gLx_pow (c m : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    Req (dyadicR (gLx c) m)
      (Rsub (hsSample (c * 2 ^ m) (Nat.mul_pos hc1 (Nat.pos_pow_of_pos m (by omega))) (2 ^ m))
        (Rmul (Radd (logN (2 ^ m) (Nat.pos_pow_of_pos m (by omega)))
            (logN (2 ^ m) (Nat.pos_pow_of_pos m (by omega))))
          (ofQ (hFold (c * 2 ^ m) (2 ^ m))
            (hFold_den_pos (c * 2 ^ m)
              (Nat.mul_pos hc1 (Nat.pos_pow_of_pos m (by omega))) (2 ^ m))))) := by
  have hE : 2 ^ m - 1 + 1 = 2 ^ m := by
    have : (1 : Nat) ≤ 2 ^ m := Nat.one_le_two_pow; omega
  exact Req_trans (riemannSum_gLx c (2 ^ m - 1) hc1 hc3)
    (lxe_transport c hc1 hE (Nat.succ_pos (2 ^ m - 1)) (Nat.pos_pow_of_pos m (by omega)))

set_option maxHeartbeats 1600000 in
/-- **The dyadic defect**: `|D_m − (Hn(c+1) − Hn(c))| ≤ (5m+5)/2^m`. -/
theorem dyadicR_gLx_defect (c m : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    Rle (Rabs (Rsub (dyadicR (gLx c) m)
        (Rsub (Hn (c + 1) (by omega)) (Hn c hc1))))
      (ofQ (⟨((5 * m + 5 : Nat) : Int), 2 ^ m⟩ : Q) (Nat.pos_pow_of_pos m (by omega))) := by
  have hp : 0 < 2 ^ m := Nat.pos_pow_of_pos m (by omega)
  have hp1 : (1 : Nat) ≤ 2 ^ m := hp
  have hcM : 1 ≤ c * 2 ^ m := Nat.mul_pos hc1 hp
  -- shorthands (all literal; no lets, to keep unification syntactic)
  -- ΔHn with the (c+1)·2^m seam, and the scale identity
  have hseam : Req (Rsub (Hn (c * 2 ^ m + 2 ^ m) (by omega)) (Hn (c * 2 ^ m) hcM))
      (Radd (Rsub (Hn (c + 1) (by omega)) (Hn c hc1))
        (Rmul (Radd (logN (2 ^ m) hp) (logN (2 ^ m) hp))
          (Rsub (logN (c + 1) (by omega)) (logN c hc1)))) :=
    Req_trans (Rsub_congr (lxe_Hn_eq (Eq.symm (Nat.succ_mul c (2 ^ m))) (by omega)
        (Nat.mul_pos (by omega) hp))
      (Req_refl _)) (Hn_scale_diff c (2 ^ m) hc1 hp1)
  -- the decomposition of the deviation
  have hdecomp : Req (Rsub (dyadicR (gLx c) m)
      (Rsub (Hn (c + 1) (by omega)) (Hn c hc1)))
      (Radd (Rsub (hsSample (c * 2 ^ m) (Nat.mul_pos hc1 hp) (2 ^ m))
          (Rsub (Hn (c * 2 ^ m + 2 ^ m) (by omega)) (Hn (c * 2 ^ m) hcM)))
        (Rmul (Radd (logN (2 ^ m) hp) (logN (2 ^ m) hp))
          (Rsub (Rsub (logN (c + 1) (by omega)) (logN c hc1))
            (ofQ (hFold (c * 2 ^ m) (2 ^ m))
              (hFold_den_pos (c * 2 ^ m) (Nat.mul_pos hc1 hp) (2 ^ m)))))) := by
    refine Req_trans (Rsub_congr (dyadicR_gLx_pow c m hc1 hc3) (Req_refl _)) ?_
    refine Req_trans (lxe_insert _ _ _
      (Rsub (Hn (c * 2 ^ m + 2 ^ m) (by omega)) (Hn (c * 2 ^ m) hcM))) ?_
    refine Radd_congr (Req_refl _) ?_
    -- ((ΔHn − LM2·hF) − T) ≈ LM2·(Δlog − hF)
    refine Req_trans (Rsub_congr (Rsub_congr hseam (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Rsub_congr (Radd_assoc _ _ _) (Req_refl _)) ?_
    refine Req_trans (Rsub_congr (Radd_comm _ _) (Req_refl _)) ?_
    refine Req_trans (lxe_add_sub_cancel _ _) ?_
    exact Req_symm (Rmul_sub_distrib _ _ _)
  -- term 1: |hsSample − ΔHn| ≤ (2m+5)·2^m / (c·2^m)²
  have ht1 : Rle (Rabs (Rsub (hsSample (c * 2 ^ m) (Nat.mul_pos hc1 hp) (2 ^ m))
      (Rsub (Hn (c * 2 ^ m + 2 ^ m) (by omega)) (Hn (c * 2 ^ m) hcM))))
      (ofQ (⟨(((2 * m + 5) * 2 ^ m : Nat) : Int), (c * 2 ^ m) * (c * 2 ^ m)⟩ : Q)
        (Nat.mul_pos hcM hcM)) := by
    refine Rabs_le_of_both ?_ ?_
    · -- upper: ≤ gapQE ≤ (2m+4)·2^m/A² ≤ (2m+5)·2^m/A²
      refine Rle_trans (Rsub_le_of_le_Radd
        (Hn_sample_upper_cap (c * 2 ^ m) (2 ^ m) (2 * m + 4) hcM
          (lxr_cap c m hc1 hc3))) ?_
      refine Rle_ofQ_ofQ (gapQE_den_pos _ _ hcM _) (Nat.mul_pos hcM hcM) ?_
      refine Qle_trans (Nat.mul_pos hcM hcM)
        (gapQE_le (c * 2 ^ m) (2 * m + 4) hcM (2 ^ m)) ?_
      show ((( 2 * m + 4) * 2 ^ m : Nat) : Int) * (((c * 2 ^ m) * (c * 2 ^ m) : Nat) : Int)
        ≤ (((2 * m + 5) * 2 ^ m : Nat) : Int) * (((c * 2 ^ m) * (c * 2 ^ m) : Nat) : Int)
      refine Int.mul_le_mul_of_nonneg_right ?_ (Int.ofNat_nonneg _)
      exact Int.ofNat_le.mpr (Nat.mul_le_mul_right (2 ^ m) (by omega))
    · -- lower: −(hsS − ΔHn) ≈ ΔHn − hsS ≤ 2^m/A² ≤ (2m+5)·2^m/A²
      refine Rle_trans (Rle_of_Req (Rneg_Rsub _ _)) ?_
      refine Rle_trans (Rsub_le_of_le_Radd (Rle_trans
        (lxe_le_Radd (Hn_sample_lower (c * 2 ^ m) (2 ^ m) hcM))
        (Rle_of_Req (Radd_comm _ _)))) ?_
      refine Rle_ofQ_ofQ (Nat.mul_pos hcM hcM) (Nat.mul_pos hcM hcM) ?_
      show ((2 ^ m : Nat) : Int) * (((c * 2 ^ m) * (c * 2 ^ m) : Nat) : Int)
        ≤ (((2 * m + 5) * 2 ^ m : Nat) : Int) * (((c * 2 ^ m) * (c * 2 ^ m) : Nat) : Int)
      refine Int.mul_le_mul_of_nonneg_right ?_ (Int.ofNat_nonneg _)
      refine Int.ofNat_le.mpr ?_
      have : 1 * 2 ^ m ≤ (2 * m + 5) * 2 ^ m :=
        Nat.mul_le_mul_right (2 ^ m) (by omega)
      omega
  -- term 2: |LM2·(Δlog − hF)| ≤ 2m · 1/(c(c+1)2^m)
  have ht2 : Rle (Rabs (Rmul (Radd (logN (2 ^ m) hp) (logN (2 ^ m) hp))
      (Rsub (Rsub (logN (c + 1) (by omega)) (logN c hc1))
        (ofQ (hFold (c * 2 ^ m) (2 ^ m))
          (hFold_den_pos (c * 2 ^ m) (Nat.mul_pos hc1 hp) (2 ^ m))))))
      (Rmul (ofQ (⟨((2 * m : Nat) : Int), 1⟩ : Q) Nat.one_pos)
        (ofQ (⟨1, c * (c + 1) * 2 ^ m⟩ : Q)
          (show 0 < c * (c + 1) * 2 ^ m from
            Nat.mul_pos (Nat.mul_pos hc1 (by omega)) hp))) := by
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rmul_le_Rmul_both (Rnonneg_Rabs _)
      (Rnonneg_ofQ _ (show (0 : Int) ≤ (⟨1, c * (c + 1) * 2 ^ m⟩ : Q).num from
        (by decide : (0 : Int) ≤ 1))) ?_ ?_
    · -- |LM2| ≈ LM2 ≤ m + m ≈ 2m
      refine Rle_trans (Rle_of_Req (Rabs_of_nonneg
        (Rnonneg_Radd (Rnonneg_logN _ hp1) (Rnonneg_logN _ hp1)))) ?_
      refine Rle_trans (Radd_le_add (logN_two_pow_le m) (logN_two_pow_le m)) ?_
      refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
        (ofQ_congr (b := (⟨((2 * m : Nat) : Int), 1⟩ : Q))
          (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos ?_))
      show Qeq (add (⟨(m : Int), 1⟩ : Q) (⟨(m : Int), 1⟩ : Q))
        (⟨((2 * m : Nat) : Int), 1⟩ : Q)
      simp only [Qeq, add]; push_cast; ring_uor
    · -- |Δlog − hF| ≈ |hF − Δlog| ≤ the wedge width
      refine Rle_trans (Rle_of_Req (Rabs_Rsub_swap _ _)) ?_
      exact hFoldC_defect c (2 ^ m) hc1 hp1
  -- assemble
  refine Rle_trans (Rle_of_Req (Rabs_congr hdecomp)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add ht1 ht2) ?_
  -- rational close: (2m+5)·2^m/A² + 2m/(c(c+1)·2^m) ≤ (5m+5)/2^m
  have hb1 : Qle (⟨(((2 * m + 5) * 2 ^ m : Nat) : Int), (c * 2 ^ m) * (c * 2 ^ m)⟩ : Q)
      (⟨((2 * m + 5 : Nat) : Int), 2 ^ m⟩ : Q) := by
    show (((2 * m + 5) * 2 ^ m : Nat) : Int) * ((2 ^ m : Nat) : Int)
      ≤ ((2 * m + 5 : Nat) : Int) * (((c * 2 ^ m) * (c * 2 ^ m) : Nat) : Int)
    have hNat : ((2 * m + 5) * 2 ^ m) * 2 ^ m ≤ (2 * m + 5) * ((c * 2 ^ m) * (c * 2 ^ m)) := by
      rw [Nat.mul_assoc]
      refine Nat.mul_le_mul_left (2 * m + 5) ?_
      exact Nat.mul_le_mul (Nat.le_mul_of_pos_left (2 ^ m) hc1)
        (Nat.le_mul_of_pos_left (2 ^ m) hc1)
    exact_mod_cast hNat
  have hb2 : Qle (mul (⟨((2 * m : Nat) : Int), 1⟩ : Q) (⟨1, c * (c + 1) * 2 ^ m⟩ : Q))
      (⟨((2 * m : Nat) : Int), 2 ^ m⟩ : Q) := by
    show (((2 * m : Nat) : Int) * 1) * ((2 ^ m : Nat) : Int)
      ≤ ((2 * m : Nat) : Int) * ((1 * (c * (c + 1) * 2 ^ m) : Nat) : Int)
    have hNat : (2 * m) * 2 ^ m ≤ (2 * m) * (1 * (c * (c + 1) * 2 ^ m)) := by
      refine Nat.mul_le_mul_left (2 * m) ?_
      have h1 : 2 ^ m ≤ c * (c + 1) * 2 ^ m :=
        Nat.le_mul_of_pos_left (2 ^ m) (Nat.mul_pos hc1 (by omega))
      omega
    simp only [Int.mul_one]
    exact_mod_cast hNat
  refine Rle_trans (Radd_le_add
    (Rle_ofQ_ofQ (Nat.mul_pos hcM hcM) hp hb1)
    (Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ Nat.one_pos
      (show 0 < (⟨1, c * (c + 1) * 2 ^ m⟩ : Q).den from
        Nat.mul_pos (Nat.mul_pos hc1 (by omega)) hp)))
      (Rle_ofQ_ofQ (Qmul_den_pos Nat.one_pos
        (Nat.mul_pos (Nat.mul_pos hc1 (by omega)) hp)) hp hb2))) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hp hp)) ?_
  refine Rle_ofQ_ofQ (add_den_pos hp hp) hp ?_
  show (((2 * m + 5 : Nat) : Int) * ((2 ^ m : Nat) : Int)
      + ((2 * m : Nat) : Int) * ((2 ^ m : Nat) : Int)) * ((2 ^ m : Nat) : Int)
    ≤ ((5 * m + 5 : Nat) : Int) * (((2 ^ m) * (2 ^ m) : Nat) : Int)
  have hM0 : (0 : Int) ≤ ((2 ^ m : Nat) : Int) := Int.ofNat_nonneg _
  have hco : ((2 * m + 5 : Nat) : Int) + ((2 * m : Nat) : Int) ≤ ((5 * m + 5 : Nat) : Int) := by
    push_cast; omega
  have hMM : (((2 ^ m) * (2 ^ m) : Nat) : Int) = ((2 ^ m : Nat) : Int) * ((2 ^ m : Nat) : Int) := by
    exact_mod_cast rfl
  rw [hMM]
  have h1 : (((2 * m + 5 : Nat) : Int) + ((2 * m : Nat) : Int)) * ((2 ^ m : Nat) : Int)
      ≤ ((5 * m + 5 : Nat) : Int) * ((2 ^ m : Nat) : Int) :=
    Int.mul_le_mul_of_nonneg_right hco hM0
  have h2 : (((2 * m + 5 : Nat) : Int) * ((2 ^ m : Nat) : Int)
      + ((2 * m : Nat) : Int) * ((2 ^ m : Nat) : Int))
      = (((2 * m + 5 : Nat) : Int) + ((2 * m : Nat) : Int)) * ((2 ^ m : Nat) : Int) :=
    (Int.add_mul _ _ _).symm
  have h3 : (((2 * m + 5 : Nat) : Int) * ((2 ^ m : Nat) : Int)
      + ((2 * m : Nat) : Int) * ((2 ^ m : Nat) : Int)) * ((2 ^ m : Nat) : Int)
      ≤ (((5 * m + 5 : Nat) : Int) * ((2 ^ m : Nat) : Int)) * ((2 ^ m : Nat) : Int) := by
    rw [h2]
    exact Int.mul_le_mul_of_nonneg_right h1 hM0
  have h4 : (((5 * m + 5 : Nat) : Int) * ((2 ^ m : Nat) : Int)) * ((2 ^ m : Nat) : Int)
      = ((5 * m + 5 : Nat) : Int) * (((2 ^ m : Nat) : Int) * ((2 ^ m : Nat) : Int)) :=
    Int.mul_assoc _ _ _
  omega


-- ===========================================================================
-- Part 8c: the anchor, the schedule rate, and the evaluation.
-- ===========================================================================

/-- Cell transport along an index equality. -/
private theorem lxe_cell_eq {n n' : Nat} (h : n = n') (hn : 0 < n) (hn' : 0 < n')
    (h1 : 1 ≤ n) (h1' : 1 ≤ n') :
    Req (Rmul (ofQ (⟨1, n⟩ : Q) hn) (Radd (logN n h1) (logN n h1)))
      (Rmul (ofQ (⟨1, n'⟩ : Q) hn') (Radd (logN n' h1') (logN n' h1'))) := by
  subst h; exact Req_refl _

/-- **The anchor**: `D₀ = gLx c (0) ≈ (1/c)·2·log c`. -/
theorem dyadicR_gLx_zero (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    Req (dyadicR (gLx c) 0)
      (Rmul (ofQ (⟨1, c⟩ : Q) hc1) (Radd (logN c hc1) (logN c hc1))) := by
  have e : c * 2 ^ 0 + 0 = c := by simp only [Nat.pow_zero]; omega
  refine Req_trans (dyadicR_gLx_pow c 0 hc1 hc3) ?_
  refine Req_trans (Rsub_congr
    (Req_trans (Radd_comm zero _) (Req_trans (Radd_zero _)
      (lxe_cell_eq e (by omega) hc1 (by omega) hc1)))
    (Req_trans (Rmul_congr (Req_trans (Radd_congr logN_one logN_one) (Radd_zero zero))
      (Req_refl _)) (Req_trans (Rmul_comm zero _) (Rmul_zero _)))) ?_
  exact Rsub_zero _

/-- **The dyadic rate** at any schedule dominating `5(j+1)`: the telescoped sums sit
    within `1/(j+1)` of `(Hn(c+1) − Hn(c)) − D₀`. -/
theorem genSum_gLx_rate (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) (L : Q) (j : Nat)
    (hsch : 5 * (j + 1) ≤ digammaMidx L j) :
    Rle (Rabs (Rsub (genSum (dyadicTerm (gLx c)) (digammaMidx L j))
        (Rsub (Rsub (Hn (c + 1) (by omega)) (Hn c hc1))
          (Rmul (ofQ (⟨1, c⟩ : Q) hc1) (Radd (logN c hc1) (logN c hc1))))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hgen : Req (genSum (dyadicTerm (gLx c)) (digammaMidx L j))
      (Rsub (dyadicR (gLx c) (digammaMidx L j))
        (Rmul (ofQ (⟨1, c⟩ : Q) hc1) (Radd (logN c hc1) (logN c hc1)))) :=
    Req_trans (genSum_telescope (gLx c) (digammaMidx L j))
      (Rsub_congr (Req_refl _) (dyadicR_gLx_zero c hc1 hc3))
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_congr hgen (Req_refl _))
    (Rsub_shift_drop _ (Rsub (Hn (c + 1) (by omega)) (Hn c hc1))
      (Rmul (ofQ (⟨1, c⟩ : Q) hc1) (Radd (logN c hc1) (logN c hc1))))))) ?_
  refine Rle_trans (dyadicR_gLx_defect c (digammaMidx L j) hc1 hc3) ?_
  refine Rle_ofQ_ofQ (Nat.pos_pow_of_pos _ (by omega)) (Nat.succ_pos j) ?_
  show ((5 * digammaMidx L j + 5 : Nat) : Int) * ((j + 1 : Nat) : Int)
    ≤ 1 * ((2 ^ digammaMidx L j : Nat) : Int)
  have hNat : (5 * digammaMidx L j + 5) * (j + 1) ≤ 2 ^ digammaMidx L j :=
    lxr_sched (digammaMidx L j) j hsch
  have hInt : (((5 * digammaMidx L j + 5) * (j + 1) : Nat) : Int)
      ≤ ((2 ^ digammaMidx L j : Nat) : Int) := Int.ofNat_le.mpr hNat
  push_cast at hInt ⊢
  omega

/-- **`∫₀¹ 2·log(c+t)/(c+t) dt ≈ Hn(c+1) − Hn(c)`, general in the Lipschitz datum**
    (the schedule domination `5(j+1) ≤ midx` is a hypothesis, discharged per
    instance). -/
theorem riemannIntegral_gLx_gen (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (gLx c x) (gLx c y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (gLx c x) (gLx c y))
    (hsch : ∀ j, 5 * (j + 1) ≤ digammaMidx L j) :
    Req (riemannIntegral (f := gLx c) hLd hLn hlip hfc)
      (Rsub (Hn (c + 1) (by omega)) (Hn c hc1)) := by
  show Req (Radd (dyadicR (gLx c) 0) _) _
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm (gLx c)) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (Rsub (Rsub (Hn (c + 1) (by omega)) (Hn c hc1))
        (Rmul (ofQ (⟨1, c⟩ : Q) hc1) (Radd (logN c hc1) (logN c hc1)))) :=
    Rlim_eval_real _ _ (fun j => genSum_gLx_rate c hc1 hc3 L j (hsch j))
  refine Req_trans (Radd_congr (dyadicR_gLx_zero c hc1 hc3) hlim) ?_
  exact Radd_Rsub_cancel (Rsub (Hn (c + 1) (by omega)) (Hn c hc1))
    (Rmul (ofQ (⟨1, c⟩ : Q) hc1) (Radd (logN c hc1) (logN c hc1)))

/-- **`∫₀¹ 2·log(1+t)/(1+t) dt ≈ Hn 2`** (`= (log 2)²`; `Hn 1 = 0` is dropped at the
    consumer). -/
theorem riemannIntegral_gLx1 :
    Req (riemannIntegral (f := gLx 1)
        (L := add (mul (⟨((2 * 1 : Nat) : Int), 1⟩ : Q) (⟨1, 1⟩ : Q))
          (mul (⟨1, 1⟩ : Q) (⟨2, 1⟩ : Q)))
        (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
          (Qmul_den_pos Nat.one_pos Nat.one_pos)) (by decide)
        (gLx_lip_of 1 (by omega) gLog1_lip) (gLx_congr_of 1 gLog1_congr))
      (Rsub (Hn 2 (by omega)) (Hn 1 (by omega))) :=
  riemannIntegral_gLx_gen 1 (by omega) (by omega) _ (by decide)
    (gLx_lip_of 1 (by omega) gLog1_lip) (gLx_congr_of 1 gLog1_congr)
    (fun j => by show 5 * (j + 1) ≤ 5 * (j + 1); omega)

/-- **`∫₀¹ 2·log(2+t)/(2+t) dt ≈ Hn 3 − Hn 2`**. -/
theorem riemannIntegral_gLx2 :
    Req (riemannIntegral (f := gLx 2)
        (L := add (mul (⟨((2 * 2 : Nat) : Int), 1⟩ : Q) (⟨1, 1⟩ : Q))
          (mul (⟨1, 1⟩ : Q) (⟨2, 1⟩ : Q)))
        (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
          (Qmul_den_pos Nat.one_pos Nat.one_pos)) (by decide)
        (gLx_lip_of 2 (by omega) gLog2_lip) (gLx_congr_of 2 gLog2_congr))
      (Rsub (Hn 3 (by omega)) (Hn 2 (by omega))) :=
  riemannIntegral_gLx_gen 2 (by omega) (by omega) _ (by decide)
    (gLx_lip_of 2 (by omega) gLog2_lip) (gLx_congr_of 2 gLog2_congr)
    (fun j => by show 5 * (j + 1) ≤ 7 * (j + 1); omega)

/-- **`∫₀¹ 2·log(3+t)/(3+t) dt ≈ Hn 4 − Hn 3`**. -/
theorem riemannIntegral_gLx3 :
    Req (riemannIntegral (f := gLx 3)
        (L := add (mul (⟨((2 * 3 : Nat) : Int), 1⟩ : Q) (⟨1, 1⟩ : Q))
          (mul (⟨1, 1⟩ : Q) (⟨2, 1⟩ : Q)))
        (add_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos)
          (Qmul_den_pos Nat.one_pos Nat.one_pos)) (by decide)
        (gLx_lip_of 3 (by omega) gLog3_lip) (gLx_congr_of 3 gLog3_congr))
      (Rsub (Hn 4 (by omega)) (Hn 3 (by omega))) :=
  riemannIntegral_gLx_gen 3 (by omega) (by omega) _ (by decide)
    (gLx_lip_of 3 (by omega) gLog3_lip) (gLx_congr_of 3 gLog3_congr)
    (fun j => by show 5 * (j + 1) ≤ 9 * (j + 1); omega)

end UOR.Bridge.F1Square.Analysis
