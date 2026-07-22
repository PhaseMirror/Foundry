/-
F1 square — **general log-additivity and `∫₀¹ dx/(2+x) ≈ log 3 − log 2`**
(`HarmonicLog32.lean`): the base-`2M` harmonic bridge.

WHY (Sonine route, step 2 — toward the tent's remaining `WeilSlot` field). The archimedean
tail's `[1,2]` integrand is `−(1 + 2/x − 4/(x+1))`; after the affine pullback `x = 1+t` its
new core is `1/(2+t)`, whose left Riemann sums are the harmonic differences
`Σ_{j<M} 1/(2M+j)` (`H_{3M} − H_{2M}`). The per-step logarithm bracket telescoped from `2M`
to `3M` squeezes

    `log 3 − log 2  ≤  Σ_{j<M} 1/(2M+j)  ≤  log 3 − log 2 + 1/(6M)`

— the SAME `hFold`/telescope machinery as `HarmonicLog.lean` (folds and telescopes were
already general in base and count); the only genuinely new analytic input is the general
multiplicativity `log(k·m) = log k + log m` (`logN_mul_gen`, the `logN_mul` proof at an
arbitrary factor, via `exp` injectivity). `Rlim_eval_real` then evaluates

    `riemannIntegral gRecip32 ≈ logN 3 − logN 2`      (`riemannIntegral_recip32`)

with `gRecip32 t = 1/max(2+t, 1)` the `clampedInv`-totalized integrand (inert on the whole
domain, `2+t ≥ 1`).

HONEST SCOPE. Substrate for the crux route's steps 1–2; no positivity, no crux claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.HarmonicLog

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- General log-additivity: `log(k·m) = log k + log m`.
-- ===========================================================================

/-- `ofQ(k·m) ≈ ofQ(km)` (constant-real bridge at an arbitrary factor). -/
private theorem ofQ_k_mul (k m : Nat) :
    Req (ofQ (mul (⟨(k : Int), 1⟩ : Q) (⟨(m : Int), 1⟩ : Q))
        (Qmul_den_pos Nat.one_pos Nat.one_pos))
      (ofQ (⟨((k * m : Nat) : Int), 1⟩ : Q) Nat.one_pos) :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (mul (⟨(k : Int), 1⟩ : Q) (⟨(m : Int), 1⟩ : Q)) (⟨((k * m : Nat) : Int), 1⟩ : Q)
    simp only [Qeq, mul]; push_cast; ring_uor)

/-- **`log(k·m) = log k + log m`** — general multiplicativity, via `exp` injectivity
    (the `logN_mul` proof at an arbitrary factor). -/
theorem logN_mul_gen (k m : Nat) (hk : 1 ≤ k) (hm : 1 ≤ m) :
    Req (Radd (logN k hk) (logN m hm)) (logN (k * m) (Nat.mul_pos hk hm)) := by
  refine RexpReal_inj (Rnonneg_Radd (Rnonneg_logN k hk) (Rnonneg_logN m hm))
    (Rnonneg_logN (k * m) (Nat.mul_pos hk hm)) ?_
  refine Req_trans (RexpReal_add (logN k hk) (logN m hm)) ?_
  refine Req_trans (Rmul_congr (Rexp_logN k hk) (Rexp_logN m hm)) ?_
  refine Req_trans (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos) ?_
  exact Req_trans (ofQ_k_mul k m) (Req_symm (Rexp_logN (k * m) (Nat.mul_pos hk hm)))

-- ===========================================================================
-- The remaining order helper: `a + c ≤ b ⟹ a ≤ b − c`.
-- ===========================================================================

/-- `a + c ≤ b ⟹ a ≤ b − c`. -/
theorem Rle_Rsub_of_Radd_le {a b c : Real} (h : Rle (Radd a c) b) : Rle a (Rsub b c) := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle h))
  -- `b − (a+c) ≈ (b−c) − a`
  refine Req_trans (Radd_congr (Req_refl b) (Rneg_Radd a c)) ?_
  refine Req_trans (Req_symm (Radd_assoc b (Rneg a) (Rneg c))) ?_
  refine Req_trans (Radd_congr (Radd_comm b (Rneg a)) (Req_refl (Rneg c))) ?_
  refine Req_trans (Radd_assoc (Rneg a) b (Rneg c)) ?_
  exact Radd_comm (Rneg a) (Rsub b c)

-- ===========================================================================
-- The base-2M wedge: `log 3 − log 2 ≤ Σ_{j<M} 1/(2M+j) ≤ … + 1/(6M)`.
-- ===========================================================================

/-- **The wedge, lower side**: `log 3 − log 2 ≤ Σ_{j<M} 1/(2M+j)`. -/
theorem log32_le_hFold (M : Nat) (hM : 1 ≤ M) :
    Rle (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
      (ofQ (hFold (2 * M) M) (hFold_den_pos (2 * M) (show 1 ≤ 2 * M by omega) M)) := by
  have hchain : Rle (Radd (logN 3 (by omega)) (logN M hM))
      (Radd (Radd (ofQ (hFold (2 * M) M)
          (hFold_den_pos (2 * M) (show 1 ≤ 2 * M by omega) M)) (logN 2 (by omega)))
        (logN M hM)) := by
    refine Rle_trans (Rle_of_Req (Req_trans (logN_mul_gen 3 M (by omega) hM)
      (logN_eq_of_eq (show 3 * M = 2 * M + M by omega) (Nat.mul_pos (by omega) hM)
        (Nat.le_trans (show 1 ≤ 2 * M by omega) (Nat.le_add_right (2 * M) M))))) ?_
    refine Rle_trans (logN_telescope_upper (2 * M) (show 1 ≤ 2 * M by omega) M) ?_
    refine Rle_of_Req ?_
    refine Req_trans (Radd_congr (Req_refl _)
      (Req_symm (logN_mul_gen 2 M (by omega) hM))) ?_
    exact Req_symm (Radd_assoc _ _ _)
  refine Rsub_le_of_le_Radd ?_
  exact Rle_trans (Radd_le_cancel_right hchain) (Rle_of_Req (Radd_comm _ _))

/-- **The wedge, upper side**: `Σ_{j<M} 1/(2M+j) ≤ (log 3 − log 2) + 1/(6M)`. -/
theorem hFold32_le (M : Nat) (hM : 1 ≤ M) :
    Rle (ofQ (hFold (2 * M) M) (hFold_den_pos (2 * M) (show 1 ≤ 2 * M by omega) M))
      (Radd (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
        (ofQ (⟨1, 6 * M⟩ : Q) (show 0 < 6 * M by omega))) := by
  have hlo : Rle (ofQ (hFoldLo (2 * M) M) (hFoldLo_den_pos (2 * M) M))
      (Rsub (logN 3 (by omega)) (logN 2 (by omega))) := by
    have hchain : Rle (Radd (Radd (ofQ (hFoldLo (2 * M) M) (hFoldLo_den_pos (2 * M) M))
        (logN 2 (by omega))) (logN M hM))
        (Radd (logN 3 (by omega)) (logN M hM)) := by
      refine Rle_trans (Rle_of_Req (Radd_assoc _ _ _)) ?_
      refine Rle_trans (Rle_of_Req (Radd_congr (Req_refl _)
        (logN_mul_gen 2 M (by omega) hM))) ?_
      refine Rle_trans (logN_telescope_lower (2 * M) (show 1 ≤ 2 * M by omega) M) ?_
      refine Rle_of_Req ?_
      refine Req_trans (logN_eq_of_eq (show 2 * M + M = 3 * M by omega)
        (Nat.le_trans (show 1 ≤ 2 * M by omega) (Nat.le_add_right (2 * M) M))
        (Nat.mul_pos (by omega) hM)) ?_
      exact Req_symm (logN_mul_gen 3 M (by omega) hM)
    exact Rle_Rsub_of_Radd_le (Radd_le_cancel_right hchain)
  have hsplit : Req (ofQ (hFold (2 * M) M)
      (hFold_den_pos (2 * M) (show 1 ≤ 2 * M by omega) M))
      (Radd (ofQ (hFoldLo (2 * M) M) (hFoldLo_den_pos (2 * M) M))
        (ofQ (⟨1, 6 * M⟩ : Q) (show 0 < 6 * M by omega))) := by
    refine Req_trans (ofQ_congr (hFold_den_pos (2 * M) (show 1 ≤ 2 * M by omega) M)
      (add_den_pos (hFoldLo_den_pos (2 * M) M)
        (show 0 < (⟨1, 6 * M⟩ : Q).den from (show 0 < 6 * M by omega))) ?_) ?_
    · refine Qeq_trans (add_den_pos (hFoldLo_den_pos (2 * M) M)
        (Qsub_den_pos (show 0 < 2 * M by omega) (show 0 < 2 * M + M by omega)))
        (hFold_eq_hFoldLo (2 * M) (show 1 ≤ 2 * M by omega) M) ?_
      refine Qadd_congr (Qeq_refl _) ?_
      show Qeq (Qsub ⟨1, 2 * M⟩ ⟨1, 2 * M + M⟩) (⟨1, 6 * M⟩ : Q)
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    · exact Req_symm (Radd_ofQ_ofQ (hFoldLo_den_pos (2 * M) M)
        (show 0 < 6 * M by omega))
  refine Rle_trans (Rle_of_Req hsplit) ?_
  exact Radd_le_add hlo (Rle_refl _)

/-- **The wedge as an absolute defect**: `|Σ_{j<M} 1/(2M+j) − (log 3 − log 2)| ≤ 1/(6M)`. -/
theorem hFold32_defect (M : Nat) (hM : 1 ≤ M) :
    Rle (Rabs (Rsub (ofQ (hFold (2 * M) M)
        (hFold_den_pos (2 * M) (show 1 ≤ 2 * M by omega) M))
      (Rsub (logN 3 (by omega)) (logN 2 (by omega)))))
      (ofQ (⟨1, 6 * M⟩ : Q) (show 0 < 6 * M by omega)) := by
  refine Rabs_le_of_both (Rsub_le_of_le_Radd (hFold32_le M hM)) ?_
  refine Rle_trans (Rle_of_Req (Rneg_Rsub _ _)) ?_
  refine Rle_trans (Rsub_nonpos_of_Rle (log32_le_hFold M hM)) ?_
  exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (c := (⟨1, 6 * M⟩ : Q))
    (show 0 < 6 * M by omega) (show (0 : Int) ≤ 1 by decide))

-- ===========================================================================
-- The integrand `1/(2+t)` (total via the floor-1 clamp — inert on [0,1]).
-- ===========================================================================

/-- **The base-2 reciprocal integrand** `gRecip32 t = 1/max(2+t, 1)`. -/
def gRecip32 : Real → Real :=
  fun t => clampedInv ⟨1, 1⟩ (by decide) (by decide)
    (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) t)

/-- `gRecip32` is `1`-Lipschitz. -/
theorem gRecip32_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (gRecip32 x) (gRecip32 y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) Nat.one_pos) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide)
    (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) x) (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) y)) ?_
  refine Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_congr ?_))
  refine Req_trans (Rsub_Radd_Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) x
    (ofQ (⟨2, 1⟩ : Q) (by decide)) y) ?_
  refine Req_trans (Radd_congr (Radd_neg (ofQ (⟨2, 1⟩ : Q) (by decide)))
    (Req_refl (Rsub x y))) ?_
  exact Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y))

/-- `gRecip32` respects `≈`. -/
theorem gRecip32_congr : ∀ x y : Real, Req x y → Req (gRecip32 x) (gRecip32 y) :=
  fun _ _ h => clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_congr (Req_refl _) h)

-- The cross-multiplied point identity as a pure-`Int` lemma (the established idiom).
private theorem grecip32_point_core (n j : Int) :
    (1 * n) * (2 * n + j) = n * (2 * n + j * 1) := by ring_uor

/-- **The partition-point value**: `gRecip32(j/(N+1)) ≈ (N+1)/(2(N+1)+j)`. -/
theorem gRecip32_point (j N : Nat) :
    Req (gRecip32 (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨((N + 1 : Nat) : Int), 2 * (N + 1) + j⟩ : Q)
        (show 0 < 2 * (N + 1) + j by omega)) := by
  have hqd : 0 < (add (⟨2, 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)).den :=
    Nat.mul_pos Nat.one_pos (Nat.succ_pos N)
  have hqn : 0 < (add (⟨2, 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)).num := by
    show 0 < (2 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1
    push_cast; omega
  have haq : Qle (⟨1, 1⟩ : Q) (add (⟨2, 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)) := by
    show (1 : Int) * ((1 * (N + 1) : Nat) : Int)
      ≤ ((2 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1) * 1
    push_cast; omega
  refine Req_trans (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_ofQ_ofQ Nat.one_pos (Nat.succ_pos N))) ?_
  refine Req_trans (clampedInv_ofQ (a := (⟨1, 1⟩ : Q))
    (q := add (⟨2, 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q))
    (by decide) (by decide) hqd hqn haq) ?_
  refine ofQ_congr (Qinv_den_pos hqn) (show 0 < 2 * (N + 1) + j by omega) ?_
  show ((1 * (N + 1) : Nat) : Int) * ((2 * (N + 1) + j : Nat) : Int)
    = ((N + 1 : Nat) : Int)
      * ((((2 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1).toNat : Nat) : Int)
  have htn : ((((2 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1).toNat : Nat) : Int)
      = (2 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1 := by
    push_cast; omega
  rw [htn]; push_cast
  exact grecip32_point_core ((N : Int) + 1) (j : Int)

-- ===========================================================================
-- The Riemann sums are the base-2M harmonic differences.
-- ===========================================================================

/-- The unscaled term fold `Σ_{i<k} (N+1)/(2(N+1)+i)`. -/
def harmTermFold32 (N : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (k + 1) => add (harmTermFold32 N k) ⟨((N + 1 : Nat) : Int), 2 * (N + 1) + k⟩

theorem harmTermFold32_den_pos (N : Nat) : ∀ k, 0 < (harmTermFold32 N k).den
  | 0 => Nat.one_pos
  | (k + 1) => add_den_pos (harmTermFold32_den_pos N k) (show 0 < 2 * (N + 1) + k by omega)

/-- The `ℚ`-level fold of the partition values. -/
theorem RsumN_gRecip32 (N : Nat) : ∀ k,
    Req (RsumN (fun i => gRecip32 (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) k)
      (ofQ (harmTermFold32 N k) (harmTermFold32_den_pos N k))
  | 0 => Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | (k + 1) => by
      refine Req_trans (Radd_congr (RsumN_gRecip32 N k) (gRecip32_point k N)) ?_
      exact Radd_ofQ_ofQ (harmTermFold32_den_pos N k) (show 0 < 2 * (N + 1) + k by omega)

/-- The scaling collapse: `(1/(N+1))·Σ_{i<k} (N+1)/(2(N+1)+i) = Σ_{i<k} 1/(2(N+1)+i)`. -/
theorem harmTermFold32_scale (N : Nat) :
    ∀ k, Qeq (mul (⟨1, N + 1⟩ : Q) (harmTermFold32 N k)) (hFold (2 * (N + 1)) k)
  | 0 => by simp only [Qeq, hFold, harmTermFold32, mul]; push_cast; ring_uor
  | (k + 1) => by
      refine Qeq_trans (add_den_pos
        (Qmul_den_pos (Nat.succ_pos N) (harmTermFold32_den_pos N k))
        (Qmul_den_pos (Nat.succ_pos N) (show 0 < 2 * (N + 1) + k by omega)))
        (Qmul_add_left (⟨1, N + 1⟩ : Q) (harmTermFold32 N k)
          (⟨((N + 1 : Nat) : Int), 2 * (N + 1) + k⟩ : Q)) ?_
      refine Qadd_congr (harmTermFold32_scale N k) ?_
      show Qeq (mul (⟨1, N + 1⟩ : Q) (⟨((N + 1 : Nat) : Int), 2 * (N + 1) + k⟩ : Q))
        (⟨1, 2 * (N + 1) + k⟩ : Q)
      simp only [Qeq, mul]; push_cast; ring_uor

/-- **The left Riemann sum of `1/(2+t)` is the base-2M harmonic difference**. -/
theorem riemannSum_gRecip32 (N : Nat) :
    Req (riemannSum gRecip32 N)
      (ofQ (hFold (2 * (N + 1)) (N + 1))
        (hFold_den_pos (2 * (N + 1)) (show 1 ≤ 2 * (N + 1) by omega) (N + 1))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => gRecip32 (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _) (RsumN_gRecip32 N (N + 1))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N) (harmTermFold32_den_pos N (N + 1))) ?_
  exact ofQ_congr (Qmul_den_pos (Nat.succ_pos N) (harmTermFold32_den_pos N (N + 1)))
    (hFold_den_pos (2 * (N + 1)) (show 1 ≤ 2 * (N + 1) by omega) (N + 1))
    (harmTermFold32_scale N (N + 1))

-- ===========================================================================
-- The dyadic rate and the evaluation ∫₀¹ dx/(2+x) ≈ log 3 − log 2.
-- ===========================================================================

/-- The anchor: `D₀ = R₀(gRecip32) = gRecip32(0) ≈ 1/2`. -/
theorem dyadicR_gRecip32_zero :
    Req (dyadicR gRecip32 0) (ofQ (⟨1, 2⟩ : Q) (by decide)) := by
  refine Req_trans (riemannSum_gRecip32 (2 ^ 0 - 1)) ?_
  exact ofQ_congr (hFold_den_pos 2 (by omega) 1) (by decide) (by decide)

/-- `hFold` transport along a base equality (dependency-free `Req`, the (2·) form). -/
private theorem ofQ_hFold32_eq {M M' : Nat} (h : M = M') (hM : 1 ≤ 2 * M) (hM' : 1 ≤ 2 * M') :
    Req (ofQ (hFold (2 * M) M) (hFold_den_pos (2 * M) hM M))
      (ofQ (hFold (2 * M') M') (hFold_den_pos (2 * M') hM' M')) := by
  subst h; exact Req_refl _

/-- The rate at an arbitrary dyadic depth `m` with `j + 1 ≤ 2^m`. -/
private theorem genSum_gRecip32_rate_aux (m j : Nat) (hjm : j + 1 ≤ 2 ^ m) :
    Rle (Rabs (Rsub (genSum (dyadicTerm gRecip32) m)
        (Rsub (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
          (ofQ (⟨1, 2⟩ : Q) (by decide)))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hMpos : 1 ≤ 2 ^ m := Nat.one_le_two_pow
  have hE : 2 ^ m - 1 + 1 = 2 ^ m := by omega
  have heval : Req (dyadicR gRecip32 m)
      (ofQ (hFold (2 * 2 ^ m) (2 ^ m))
        (hFold_den_pos (2 * 2 ^ m) (show 1 ≤ 2 * 2 ^ m by omega) (2 ^ m))) :=
    Req_trans (riemannSum_gRecip32 (2 ^ m - 1))
      (ofQ_hFold32_eq hE (show 1 ≤ 2 * (2 ^ m - 1 + 1) by omega)
        (show 1 ≤ 2 * 2 ^ m by omega))
  have hgen : Req (genSum (dyadicTerm gRecip32) m)
      (Rsub (ofQ (hFold (2 * 2 ^ m) (2 ^ m))
          (hFold_den_pos (2 * 2 ^ m) (show 1 ≤ 2 * 2 ^ m by omega) (2 ^ m)))
        (ofQ (⟨1, 2⟩ : Q) (by decide))) :=
    Req_trans (genSum_telescope gRecip32 m) (Rsub_congr heval dyadicR_gRecip32_zero)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_congr hgen (Req_refl _))
    (Rsub_shift_drop _ (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
      (ofQ (⟨1, 2⟩ : Q) (by decide)))))) ?_
  refine Rle_trans (hFold32_defect (2 ^ m) hMpos) ?_
  refine Rle_ofQ_ofQ (show 0 < 6 * 2 ^ m by omega) (Nat.succ_pos j) ?_
  show (1 : Int) * ((j + 1 : Nat) : Int) ≤ (1 : Int) * ((6 * 2 ^ m : Nat) : Int)
  have hc : ((j + 1 : Nat) : Int) ≤ ((6 * 2 ^ m : Nat) : Int) :=
    Int.ofNat_le.mpr (by omega)
  omega

/-- **The dyadic rate**: the telescoped sums sit within `1/(j+1)` of
    `(log 3 − log 2) − 1/2`, for every schedule. -/
theorem genSum_gRecip32_rate (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm gRecip32) (digammaMidx L j))
        (Rsub (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
          (ofQ (⟨1, 2⟩ : Q) (by decide)))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine genSum_gRecip32_rate_aux (digammaMidx L j) j ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ dx/(2+x) ≈ log 3 − log 2`, general in the Lipschitz datum**. -/
theorem riemannIntegral_recip32_gen {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (gRecip32 x) (gRecip32 y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (gRecip32 x) (gRecip32 y)) :
    Req (riemannIntegral (f := gRecip32) hLd hLn hlip hfc)
      (Rsub (logN 3 (by omega)) (logN 2 (by omega))) := by
  show Req (Radd (dyadicR gRecip32 0) _) _
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm gRecip32) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (Rsub (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
        (ofQ (⟨1, 2⟩ : Q) (by decide))) :=
    Rlim_eval_real _ _ (fun j => genSum_gRecip32_rate L j)
  refine Req_trans (Radd_congr dyadicR_gRecip32_zero hlim) ?_
  exact Radd_Rsub_cancel (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
    (ofQ (⟨1, 2⟩ : Q) (by decide))

/-- **`∫₀¹ dx/(2+x) ≈ log 3 − log 2`** — the headline instance at `L = 1`. -/
theorem riemannIntegral_recip32 :
    Req (riemannIntegral (f := gRecip32) (L := (⟨1, 1⟩ : Q)) Nat.one_pos (by decide)
      gRecip32_lip gRecip32_congr)
      (Rsub (logN 3 (by omega)) (logN 2 (by omega))) :=
  riemannIntegral_recip32_gen Nat.one_pos (by decide) gRecip32_lip gRecip32_congr

end UOR.Bridge.F1Square.Analysis
