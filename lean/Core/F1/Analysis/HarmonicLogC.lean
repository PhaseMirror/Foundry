/-
F1 square — **the general-base harmonic bridge: `∫₀¹ dx/(c+x) ≈ log(c+1) − log c`**
(`HarmonicLogC.lean`), for every natural base `c ≥ 1`.

WHY (Sonine route, step 2 — the improper archimedean tail). The tail past the tent's support,
`∫₂^∞ −2/(x²−1) dx = −log 3`, is a `genSum` of unit blocks `∫_{m+1}^{m+2}(1/w − 1/(w+2))`
(`ImproperIntegral.lean`), and EVERY block is a translate `∫₀¹ dt/(c+t)` at a different base
`c`. This file is the `HarmonicLog32.lean` construction with the base as a parameter: left
Riemann sums are `Σ_{j<M} 1/(cM+j) = H_{(c+1)M} − H_{cM}`, the per-step logarithm bracket
telescoped from `cM` to `(c+1)M` squeezes

    `log(c+1) − log c  ≤  Σ_{j<M} 1/(cM+j)  ≤  log(c+1) − log c + 1/(c(c+1)M)`

(`logN_mul_gen` supplies both cancellations), and `Rlim_eval_real` evaluates the integral of
the totalized `gRecipC c t = 1/max(c+t, 1)` from the rational anchor `D₀ = 1/c`.

HONEST SCOPE. Substrate for the crux route's steps 1–2; no positivity, no crux claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.HarmonicLog32

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The general-base wedge.
-- ===========================================================================

/-- **The wedge, lower side**: `log(c+1) − log c ≤ Σ_{j<M} 1/(cM+j)`. -/
theorem logC_le_hFold (c M : Nat) (hc : 1 ≤ c) (hM : 1 ≤ M) :
    Rle (Rsub (logN (c + 1) (by omega)) (logN c hc))
      (ofQ (hFold (c * M) M)
        (hFold_den_pos (c * M) (Nat.mul_pos hc hM) M)) := by
  have hcM : 1 ≤ c * M := Nat.mul_pos hc hM
  have hchain : Rle (Radd (logN (c + 1) (by omega)) (logN M hM))
      (Radd (Radd (ofQ (hFold (c * M) M) (hFold_den_pos (c * M) (Nat.mul_pos hc hM) M))
        (logN c hc)) (logN M hM)) := by
    refine Rle_trans (Rle_of_Req (Req_trans (logN_mul_gen (c + 1) M (by omega) hM)
      (logN_eq_of_eq (Nat.succ_mul c M) (Nat.mul_pos (by omega) hM)
        (Nat.le_trans hcM (Nat.le_add_right (c * M) M))))) ?_
    refine Rle_trans (logN_telescope_upper (c * M) hcM M) ?_
    refine Rle_of_Req ?_
    refine Req_trans (Radd_congr (Req_refl _)
      (Req_symm (logN_mul_gen c M hc hM))) ?_
    exact Req_symm (Radd_assoc _ _ _)
  refine Rsub_le_of_le_Radd ?_
  exact Rle_trans (Radd_le_cancel_right hchain) (Rle_of_Req (Radd_comm _ _))

/-- **The wedge, upper side**: `Σ_{j<M} 1/(cM+j) ≤ (log(c+1) − log c) + 1/(c(c+1)M)`. -/
theorem hFoldC_le (c M : Nat) (hc : 1 ≤ c) (hM : 1 ≤ M) :
    Rle (ofQ (hFold (c * M) M) (hFold_den_pos (c * M) (Nat.mul_pos hc hM) M))
      (Radd (Rsub (logN (c + 1) (by omega)) (logN c hc))
        (ofQ (⟨1, c * (c + 1) * M⟩ : Q)
          (show 0 < c * (c + 1) * M from
            Nat.mul_pos (Nat.mul_pos hc (by omega)) hM))) := by
  have hcM : 1 ≤ c * M := Nat.mul_pos hc hM
  have hlo : Rle (ofQ (hFoldLo (c * M) M) (hFoldLo_den_pos (c * M) M))
      (Rsub (logN (c + 1) (by omega)) (logN c hc)) := by
    have hchain : Rle (Radd (Radd (ofQ (hFoldLo (c * M) M) (hFoldLo_den_pos (c * M) M))
        (logN c hc)) (logN M hM))
        (Radd (logN (c + 1) (by omega)) (logN M hM)) := by
      refine Rle_trans (Rle_of_Req (Radd_assoc _ _ _)) ?_
      refine Rle_trans (Rle_of_Req (Radd_congr (Req_refl _)
        (logN_mul_gen c M hc hM))) ?_
      refine Rle_trans (logN_telescope_lower (c * M) hcM M) ?_
      refine Rle_of_Req ?_
      refine Req_trans (logN_eq_of_eq (Eq.symm (Nat.succ_mul c M))
        (Nat.le_trans hcM (Nat.le_add_right (c * M) M))
        (Nat.mul_pos (by omega) hM)) ?_
      exact Req_symm (logN_mul_gen (c + 1) M (by omega) hM)
    exact Rle_Rsub_of_Radd_le (Radd_le_cancel_right hchain)
  have hsplit : Req (ofQ (hFold (c * M) M)
      (hFold_den_pos (c * M) (Nat.mul_pos hc hM) M))
      (Radd (ofQ (hFoldLo (c * M) M) (hFoldLo_den_pos (c * M) M))
        (ofQ (⟨1, c * (c + 1) * M⟩ : Q)
          (show 0 < c * (c + 1) * M from
            Nat.mul_pos (Nat.mul_pos hc (by omega)) hM))) := by
    refine Req_trans (ofQ_congr (hFold_den_pos (c * M) (Nat.mul_pos hc hM) M)
      (add_den_pos (hFoldLo_den_pos (c * M) M)
        (show 0 < (⟨1, c * (c + 1) * M⟩ : Q).den from
          Nat.mul_pos (Nat.mul_pos hc (by omega)) hM)) ?_) ?_
    · refine Qeq_trans (add_den_pos (hFoldLo_den_pos (c * M) M)
        (Qsub_den_pos (show 0 < c * M from Nat.mul_pos hc hM)
          (show 0 < c * M + M by have := Nat.mul_pos hc hM; omega)))
        (hFold_eq_hFoldLo (c * M) hcM M) ?_
      refine Qadd_congr (Qeq_refl _) ?_
      show Qeq (Qsub ⟨1, c * M⟩ ⟨1, c * M + M⟩) (⟨1, c * (c + 1) * M⟩ : Q)
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    · exact Req_symm (Radd_ofQ_ofQ (hFoldLo_den_pos (c * M) M)
        (show 0 < c * (c + 1) * M from Nat.mul_pos (Nat.mul_pos hc (by omega)) hM))
  refine Rle_trans (Rle_of_Req hsplit) ?_
  exact Radd_le_add hlo (Rle_refl _)

/-- **The wedge as an absolute defect**: `|Σ_{j<M} 1/(cM+j) − (log(c+1) − log c)| ≤ 1/(c(c+1)M)`. -/
theorem hFoldC_defect (c M : Nat) (hc : 1 ≤ c) (hM : 1 ≤ M) :
    Rle (Rabs (Rsub (ofQ (hFold (c * M) M)
        (hFold_den_pos (c * M) (Nat.mul_pos hc hM) M))
      (Rsub (logN (c + 1) (by omega)) (logN c hc))))
      (ofQ (⟨1, c * (c + 1) * M⟩ : Q)
        (show 0 < c * (c + 1) * M from Nat.mul_pos (Nat.mul_pos hc (by omega)) hM)) := by
  refine Rabs_le_of_both (Rsub_le_of_le_Radd (hFoldC_le c M hc hM)) ?_
  refine Rle_trans (Rle_of_Req (Rneg_Rsub _ _)) ?_
  refine Rle_trans (Rsub_nonpos_of_Rle (logC_le_hFold c M hc hM)) ?_
  exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (c := (⟨1, c * (c + 1) * M⟩ : Q))
    (show 0 < c * (c + 1) * M from Nat.mul_pos (Nat.mul_pos hc (by omega)) hM)
    (show (0 : Int) ≤ 1 by decide))

-- ===========================================================================
-- The integrand `1/(c+t)` (total via the floor-1 clamp — inert on [0,1] for c ≥ 1).
-- ===========================================================================

/-- **The base-`c` reciprocal integrand** `gRecipC c t = 1/max(c+t, 1)`. -/
def gRecipC (c : Nat) : Real → Real :=
  fun t => clampedInv ⟨1, 1⟩ (by decide) (by decide)
    (Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) t)

/-- `gRecipC` is `1`-Lipschitz. -/
theorem gRecipC_lip (c : Nat) : ∀ x y : Real,
    Rle (Rabs (Rsub (gRecipC c x) (gRecipC c y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) Nat.one_pos) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide)
    (Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) x)
    (Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) y)) ?_
  refine Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_congr ?_))
  refine Req_trans (Rsub_Radd_Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) x
    (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) y) ?_
  refine Req_trans (Radd_congr (Radd_neg (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos))
    (Req_refl (Rsub x y))) ?_
  exact Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y))

/-- `gRecipC` respects `≈`. -/
theorem gRecipC_congr (c : Nat) : ∀ x y : Real, Req x y →
    Req (gRecipC c x) (gRecipC c y) :=
  fun _ _ h => clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_congr (Req_refl _) h)

/-- `gRecipC` at any modulus `L ≥ 1`. -/
theorem gRecipC_lip_at (c : Nat) {L : Q} (hLd : 0 < L.den) (h1L : Qle ⟨1, 1⟩ L) :
    ∀ x y : Real,
    Rle (Rabs (Rsub (gRecipC c x) (gRecipC c y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
  fun x y => lip_mono Nat.one_pos hLd h1L (Rnonneg_Rabs _) (gRecipC_lip c x y)

-- The cross-multiplied point identity as a pure-`Int` lemma.
private theorem grecipC_point_core (c n j : Int) :
    (1 * n) * (c * n + j) = n * (c * n + j * 1) := by ring_uor

/-- **The partition-point value**: `gRecipC c (j/(N+1)) ≈ (N+1)/(c(N+1)+j)` for `c ≥ 1`. -/
theorem gRecipC_point (c j N : Nat) (hc : 1 ≤ c) :
    Req (gRecipC c (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨((N + 1 : Nat) : Int), c * (N + 1) + j⟩ : Q)
        (show 0 < c * (N + 1) + j from by
          have := Nat.mul_pos hc (show 0 < N + 1 by omega); omega)) := by
  have hqd : 0 < (add (⟨(c : Int), 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)).den :=
    Nat.mul_pos Nat.one_pos (Nat.succ_pos N)
  have hqn : 0 < (add (⟨(c : Int), 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)).num := by
    show 0 < (c : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1
    have hc' : (1 : Int) ≤ (c : Int) := by exact_mod_cast hc
    have h1 : (1 : Int) * ((N + 1 : Nat) : Int) ≤ (c : Int) * ((N + 1 : Nat) : Int) :=
      Int.mul_le_mul_of_nonneg_right hc' (Int.ofNat_nonneg _)
    push_cast at h1 ⊢; omega
  have haq : Qle (⟨1, 1⟩ : Q) (add (⟨(c : Int), 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)) := by
    show (1 : Int) * ((1 * (N + 1) : Nat) : Int)
      ≤ ((c : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1) * 1
    have hc' : (1 : Int) ≤ (c : Int) := by exact_mod_cast hc
    have h1 : (1 : Int) * ((N + 1 : Nat) : Int) ≤ (c : Int) * ((N + 1 : Nat) : Int) :=
      Int.mul_le_mul_of_nonneg_right hc' (Int.ofNat_nonneg _)
    push_cast at h1 ⊢; omega
  refine Req_trans (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_ofQ_ofQ Nat.one_pos (Nat.succ_pos N))) ?_
  refine Req_trans (clampedInv_ofQ (a := (⟨1, 1⟩ : Q))
    (q := add (⟨(c : Int), 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q))
    (by decide) (by decide) hqd hqn haq) ?_
  refine ofQ_congr (Qinv_den_pos hqn)
    (show 0 < c * (N + 1) + j from by
      have := Nat.mul_pos hc (show 0 < N + 1 by omega); omega) ?_
  show ((1 * (N + 1) : Nat) : Int) * ((c * (N + 1) + j : Nat) : Int)
    = ((N + 1 : Nat) : Int)
      * ((((c : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1).toNat : Nat) : Int)
  have htn : ((((c : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1).toNat : Nat) : Int)
      = (c : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1 := by
    have hc' : (1 : Int) ≤ (c : Int) := by exact_mod_cast hc
    have h1 : (1 : Int) * ((N + 1 : Nat) : Int) ≤ (c : Int) * ((N + 1 : Nat) : Int) :=
      Int.mul_le_mul_of_nonneg_right hc' (Int.ofNat_nonneg _)
    push_cast at h1 ⊢; omega
  rw [htn]; push_cast
  exact grecipC_point_core (c : Int) ((N : Int) + 1) (j : Int)

-- ===========================================================================
-- The Riemann sums are the base-cM harmonic differences.
-- ===========================================================================

/-- The unscaled term fold `Σ_{i<k} (N+1)/(c(N+1)+i)`. -/
def harmTermFoldC (c N : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (k + 1) => add (harmTermFoldC c N k) ⟨((N + 1 : Nat) : Int), c * (N + 1) + k⟩

theorem harmTermFoldC_den_pos (c N : Nat) (hc : 1 ≤ c) :
    ∀ k, 0 < (harmTermFoldC c N k).den
  | 0 => Nat.one_pos
  | (k + 1) => add_den_pos (harmTermFoldC_den_pos c N hc k)
      (show 0 < c * (N + 1) + k from by
        have := Nat.mul_pos hc (show 0 < N + 1 by omega); omega)

/-- The `ℚ`-level fold of the partition values. -/
theorem RsumN_gRecipC (c N : Nat) (hc : 1 ≤ c) : ∀ k,
    Req (RsumN (fun i => gRecipC c (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) k)
      (ofQ (harmTermFoldC c N k) (harmTermFoldC_den_pos c N hc k))
  | 0 => Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | (k + 1) => by
      refine Req_trans (Radd_congr (RsumN_gRecipC c N hc k) (gRecipC_point c k N hc)) ?_
      exact Radd_ofQ_ofQ (harmTermFoldC_den_pos c N hc k)
        (show 0 < c * (N + 1) + k from by
          have := Nat.mul_pos hc (show 0 < N + 1 by omega); omega)

/-- The scaling collapse: `(1/(N+1))·Σ_{i<k} (N+1)/(c(N+1)+i) = Σ_{i<k} 1/(c(N+1)+i)`. -/
theorem harmTermFoldC_scale (c N : Nat) (hc : 1 ≤ c) :
    ∀ k, Qeq (mul (⟨1, N + 1⟩ : Q) (harmTermFoldC c N k)) (hFold (c * (N + 1)) k)
  | 0 => by simp only [Qeq, hFold, harmTermFoldC, mul]; push_cast; ring_uor
  | (k + 1) => by
      refine Qeq_trans (add_den_pos
        (Qmul_den_pos (Nat.succ_pos N) (harmTermFoldC_den_pos c N hc k))
        (Qmul_den_pos (Nat.succ_pos N)
          (show 0 < c * (N + 1) + k from by
            have := Nat.mul_pos hc (show 0 < N + 1 by omega); omega)))
        (Qmul_add_left (⟨1, N + 1⟩ : Q) (harmTermFoldC c N k)
          (⟨((N + 1 : Nat) : Int), c * (N + 1) + k⟩ : Q)) ?_
      refine Qadd_congr (harmTermFoldC_scale c N hc k) ?_
      show Qeq (mul (⟨1, N + 1⟩ : Q) (⟨((N + 1 : Nat) : Int), c * (N + 1) + k⟩ : Q))
        (⟨1, c * (N + 1) + k⟩ : Q)
      simp only [Qeq, mul]; push_cast; ring_uor

/-- **The left Riemann sum of `1/(c+t)` is the base-`cM` harmonic difference**. -/
theorem riemannSum_gRecipC (c N : Nat) (hc : 1 ≤ c) :
    Req (riemannSum (gRecipC c) N)
      (ofQ (hFold (c * (N + 1)) (N + 1))
        (hFold_den_pos (c * (N + 1)) (Nat.mul_pos hc (Nat.succ_pos N)) (N + 1))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => gRecipC c (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _) (RsumN_gRecipC c N hc (N + 1))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N) (harmTermFoldC_den_pos c N hc (N + 1))) ?_
  exact ofQ_congr (Qmul_den_pos (Nat.succ_pos N) (harmTermFoldC_den_pos c N hc (N + 1)))
    (hFold_den_pos (c * (N + 1)) (Nat.mul_pos hc (Nat.succ_pos N)) (N + 1))
    (harmTermFoldC_scale c N hc (N + 1))

-- ===========================================================================
-- The dyadic rate and the evaluation ∫₀¹ dx/(c+x) ≈ log(c+1) − log c.
-- ===========================================================================

/-- The anchor: `D₀ = R₀(gRecipC c) = gRecipC c (0) ≈ 1/c`. -/
theorem dyadicR_gRecipC_zero (c : Nat) (hc : 1 ≤ c) :
    Req (dyadicR (gRecipC c) 0) (ofQ (⟨1, c⟩ : Q) hc) := by
  refine Req_trans (riemannSum_gRecipC c (2 ^ 0 - 1) hc) ?_
  refine ofQ_congr (hFold_den_pos (c * 1) (Nat.mul_pos hc Nat.one_pos) 1)
    (show 0 < (⟨1, c⟩ : Q).den from hc) ?_
  show Qeq (add (⟨0, 1⟩ : Q) (⟨1, c * 1 + 0⟩ : Q)) (⟨1, c⟩ : Q)
  simp only [Qeq, add]; push_cast; ring_uor

/-- `hFold` transport along a base equality (the (c·) form). -/
private theorem ofQ_hFoldC_eq (c : Nat) {M M' : Nat} (h : M = M')
    (hM : 1 ≤ c * M) (hM' : 1 ≤ c * M') :
    Req (ofQ (hFold (c * M) M) (hFold_den_pos (c * M) hM M))
      (ofQ (hFold (c * M') M') (hFold_den_pos (c * M') hM' M')) := by
  subst h; exact Req_refl _

/-- The rate at an arbitrary dyadic depth `m` with `j + 1 ≤ 2^m`. -/
private theorem genSum_gRecipC_rate_aux (c m j : Nat) (hc : 1 ≤ c) (hjm : j + 1 ≤ 2 ^ m) :
    Rle (Rabs (Rsub (genSum (dyadicTerm (gRecipC c)) m)
        (Rsub (Rsub (logN (c + 1) (by omega)) (logN c hc)) (ofQ (⟨1, c⟩ : Q) hc))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hMpos : 1 ≤ 2 ^ m := Nat.one_le_two_pow
  have hE : 2 ^ m - 1 + 1 = 2 ^ m := by omega
  have hcM : 1 ≤ c * 2 ^ m := Nat.mul_pos hc hMpos
  have heval : Req (dyadicR (gRecipC c) m)
      (ofQ (hFold (c * 2 ^ m) (2 ^ m)) (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m))) :=
    Req_trans (riemannSum_gRecipC c (2 ^ m - 1) hc)
      (ofQ_hFoldC_eq c hE (Nat.mul_pos hc (Nat.succ_pos (2 ^ m - 1))) hcM)
  have hgen : Req (genSum (dyadicTerm (gRecipC c)) m)
      (Rsub (ofQ (hFold (c * 2 ^ m) (2 ^ m)) (hFold_den_pos (c * 2 ^ m) hcM (2 ^ m)))
        (ofQ (⟨1, c⟩ : Q) hc)) :=
    Req_trans (genSum_telescope (gRecipC c) m)
      (Rsub_congr heval (dyadicR_gRecipC_zero c hc))
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_congr hgen (Req_refl _))
    (Rsub_shift_drop _ (Rsub (logN (c + 1) (by omega)) (logN c hc))
      (ofQ (⟨1, c⟩ : Q) hc))))) ?_
  refine Rle_trans (hFoldC_defect c (2 ^ m) hc hMpos) ?_
  refine Rle_ofQ_ofQ
    (show 0 < c * (c + 1) * 2 ^ m from
      Nat.mul_pos (Nat.mul_pos hc (by omega)) hMpos) (Nat.succ_pos j) ?_
  show (1 : Int) * ((j + 1 : Nat) : Int) ≤ (1 : Int) * ((c * (c + 1) * 2 ^ m : Nat) : Int)
  have hcc : 2 ^ m ≤ c * (c + 1) * 2 ^ m :=
    Nat.le_mul_of_pos_left _ (Nat.mul_pos hc (by omega))
  have hcast : ((j + 1 : Nat) : Int) ≤ ((c * (c + 1) * 2 ^ m : Nat) : Int) :=
    Int.ofNat_le.mpr (by omega)
  omega

/-- **The dyadic rate**: the telescoped sums sit within `1/(j+1)` of
    `(log(c+1) − log c) − 1/c`, for every schedule. -/
theorem genSum_gRecipC_rate (c : Nat) (hc : 1 ≤ c) (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm (gRecipC c)) (digammaMidx L j))
        (Rsub (Rsub (logN (c + 1) (by omega)) (logN c hc)) (ofQ (⟨1, c⟩ : Q) hc))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine genSum_gRecipC_rate_aux c (digammaMidx L j) j hc ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ dx/(c+x) ≈ log(c+1) − log c`, general in the base and the Lipschitz datum** —
    the general-base harmonic evaluation. -/
theorem riemannIntegral_recipC_gen (c : Nat) (hc : 1 ≤ c) {L : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (gRecipC c x) (gRecipC c y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (gRecipC c x) (gRecipC c y)) :
    Req (riemannIntegral (f := gRecipC c) hLd hLn hlip hfc)
      (Rsub (logN (c + 1) (by omega)) (logN c hc)) := by
  show Req (Radd (dyadicR (gRecipC c) 0) _) _
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm (gRecipC c)) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (Rsub (Rsub (logN (c + 1) (by omega)) (logN c hc)) (ofQ (⟨1, c⟩ : Q) hc)) :=
    Rlim_eval_real _ _ (fun j => genSum_gRecipC_rate c hc L j)
  refine Req_trans (Radd_congr (dyadicR_gRecipC_zero c hc) hlim) ?_
  exact Radd_Rsub_cancel (Rsub (logN (c + 1) (by omega)) (logN c hc))
    (ofQ (⟨1, c⟩ : Q) hc)

/-- **`∫₀¹ dx/(c+x) ≈ log(c+1) − log c`** — the headline instance at `L = 1`. -/
theorem riemannIntegral_recipC (c : Nat) (hc : 1 ≤ c) :
    Req (riemannIntegral (f := gRecipC c) (L := (⟨1, 1⟩ : Q)) Nat.one_pos (by decide)
      (gRecipC_lip c) (gRecipC_congr c))
      (Rsub (logN (c + 1) (by omega)) (logN c hc)) :=
  riemannIntegral_recipC_gen c hc Nat.one_pos (by decide) (gRecipC_lip c) (gRecipC_congr c)

end UOR.Bridge.F1Square.Analysis
