/-
F1 square — **the harmonic–logarithm bridge and `∫₀¹ dx/(1+x) ≈ log 2`**
(`HarmonicLog.lean`): the first certified integral evaluation to a NON-RATIONAL value, and
the constructive fundamental-theorem step for `1/x`.

WHAT (Sonine route, step 2). The tent test's remaining `WeilSlot` components (`f̃(0) = log 2`,
the archimedean tail) have reciprocal integrands. Their evaluation bottoms out here: the
totalized reciprocal `gRecip t = 1/max(1+t, 1)` (the `clampedInv` gadget, inert on the whole
domain) has left Riemann sums that are EXACT harmonic differences

    `R_N(gRecip) = Σ_{j=0}^{M−1} 1/(M+j)`   (`M = N+1` — the fold `hFold M M`),

and the per-step logarithm bracket (`ExpBounds.lean`) telescoped from `M` to `2M` squeezes

    `log 2  ≤  Σ_{j<M} 1/(M+j)  ≤  log 2 + 1/(2M)`

(`logN_mul` supplies `log(2M) = log 2 + log M`, and the two ends differ by the exact
telescoping defect `1/M − 1/(2M)`). So the dyadic sums converge to `log 2` with certified
rate, and the new limit engine `Rlim_eval_real` (the `Rlim_eval` generalization to a REAL
limit value — the extra cost is one regularity step of the target) evaluates the integral:

    `riemannIntegral gRecip ≈ logN 2`      (`riemannIntegral_recip`).

HONEST SCOPE. Substrate for the crux route's steps 1–2; no positivity, no crux claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ExpBounds
import Core.F1.Analysis.ClampedInv
import Core.F1.Analysis.IntegralEval

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The limit-evaluation engine for a REAL value (generalizing `Rlim_eval`).
-- ===========================================================================

/-- **A rate-convergent Bishop limit evaluates to its real target**: if every `X j` is within
    `1/(j+1)` of `L` (as reals), then `Rlim X ≈ L`. The diagonal argument of `Rlim_eval`
    plus one regularity step of `L` (from index `4n+3` back to `n`). -/
theorem Rlim_eval_real {X : Nat → Real} (hX : RReg X) (L : Real)
    (hrate : ∀ j, Rle (Rabs (Rsub (X j) L)) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) :
    Req (Rlim X hX) L := by
  refine Req_of_lin_bound (C := 3) (fun n => ?_)
  have h := hrate (4 * n + 3) (2 * n + 1)
  have hshape : Qle (Qabs (Qsub ((X (4 * n + 3)).seq (2 * (2 * n + 1) + 1))
      (L.seq (2 * (2 * n + 1) + 1))))
      (add (⟨1, 4 * n + 3 + 1⟩ : Q) (⟨2, 2 * n + 1 + 1⟩ : Q)) := h
  have hidx : 2 * (2 * n + 1) + 1 = 4 * n + 3 := by omega
  rw [hidx] at hshape
  show Qle (Qabs (Qsub ((X (4 * n + 3)).seq (4 * n + 3)) (L.seq n))) (⟨(3 : Int), n + 1⟩ : Q)
  have htri := Qabs_sub_triangle (a := (X (4 * n + 3)).seq (4 * n + 3))
    (b := L.seq (4 * n + 3)) (c := L.seq n)
    ((X (4 * n + 3)).den_pos _) (L.den_pos _) (L.den_pos n)
  have hreg := L.reg (4 * n + 3) n
  refine Qle_trans (add_den_pos
    (Qabs_den_pos (Qsub_den_pos ((X (4 * n + 3)).den_pos _) (L.den_pos _)))
    (Qabs_den_pos (Qsub_den_pos (L.den_pos _) (L.den_pos n)))) htri ?_
  refine Qle_trans (add_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
    (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)))
    (Qadd_le_add hshape hreg) ?_
  -- `(1/(4n+4) + 2/(2n+2)) + (1/(4n+4) + 1/(n+1)) = 10/(4n+4) ≤ 3/(n+1)`.
  have hcol : Qeq (add (add (⟨1, 4 * n + 3 + 1⟩ : Q) (⟨2, 2 * n + 1 + 1⟩ : Q))
      (add (Qbound (4 * n + 3)) (Qbound n))) (⟨10, 4 * n + 4⟩ : Q) := by
    simp only [Qeq, add, Qbound]; push_cast; ring_uor
  refine Qle_congr_left (show 0 < 4 * n + 4 by omega) (Qeq_symm hcol) ?_
  show (10 : Int) * ((n + 1 : Nat) : Int) ≤ (3 : Int) * ((4 * n + 4 : Nat) : Int)
  push_cast; omega

-- ===========================================================================
-- Order helpers: subtraction against the order, and add-cancellation.
-- ===========================================================================

/-- `−(−y) ≈ y`. -/
theorem Rneg_involutive (y : Real) : Req (Rneg (Rneg y)) y :=
  Req_of_seq_Qeq (fun n => by
    show Qeq (neg (neg (y.seq n))) (y.seq n)
    simp only [Qeq, neg]; push_cast; ring_uor)

/-- `x ≤ y + c ⟹ x − y ≤ c`. -/
theorem Rsub_le_of_le_Radd {x y c : Real} (h : Rle x (Radd y c)) : Rle (Rsub x y) c := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle h))
  -- `(y+c) − x ≈ c − (x−y)`
  refine Req_trans (Radd_assoc y c (Rneg x)) ?_
  refine Req_trans (Radd_comm y (Radd c (Rneg x))) ?_
  refine Req_trans (Radd_assoc c (Rneg x) y) ?_
  refine Radd_congr (Req_refl c) ?_
  -- `(−x) + y ≈ −(x−y)`
  refine Req_symm ?_
  refine Req_trans (Rneg_Radd x (Rneg y)) ?_
  exact Radd_congr (Req_refl (Rneg x)) (Rneg_involutive y)

/-- `x ≤ y ⟹ x − y ≤ 0`. -/
theorem Rsub_nonpos_of_Rle {x y : Real} (h : Rle x y) : Rle (Rsub x y) zero := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle h))
  -- `y − x ≈ 0 − (x−y)`
  refine Req_symm ?_
  refine Req_trans (Radd_comm zero (Rneg (Rsub x y))) ?_
  refine Req_trans (Radd_zero (Rneg (Rsub x y))) ?_
  refine Req_trans (Rneg_Radd x (Rneg y)) ?_
  refine Req_trans (Radd_congr (Req_refl (Rneg x)) (Rneg_involutive y)) ?_
  exact Radd_comm (Rneg x) y

/-- Right add-cancellation for the order: `a + c ≤ b + c ⟹ a ≤ b`. -/
theorem Radd_le_cancel_right {a b c : Real} (h : Rle (Radd a c) (Radd b c)) : Rle a b := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle h))
  -- `(b+c) − (a+c) ≈ b − a`
  refine Req_trans (Rsub_Radd_Radd b c a c) ?_
  refine Req_trans (Radd_congr (Req_refl (Rsub b a)) (Radd_neg c)) ?_
  exact Radd_zero (Rsub b a)

/-- `(A − c) − (B − c) ≈ A − B` (the shared shift drops). -/
theorem Rsub_shift_drop (A B c : Real) :
    Req (Rsub (Rsub A c) (Rsub B c)) (Rsub A B) := by
  refine Req_trans (Rsub_Radd_Radd A (Rneg c) B (Rneg c)) ?_
  refine Req_trans (Radd_congr (Req_refl (Rsub A B)) (Radd_neg (Rneg c))) ?_
  exact Radd_zero (Rsub A B)

-- ===========================================================================
-- The harmonic folds and the telescoped logarithm wedge.
-- ===========================================================================

/-- The left harmonic fold `Σ_{i<c} 1/(M+i)`. -/
def hFold (M : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (c + 1) => add (hFold M c) ⟨1, M + c⟩

theorem hFold_den_pos (M : Nat) (hM : 1 ≤ M) : ∀ c, 0 < (hFold M c).den
  | 0 => Nat.one_pos
  | (c + 1) => add_den_pos (hFold_den_pos M hM c) (show 0 < M + c by omega)

/-- The right harmonic fold `Σ_{i<c} 1/(M+i+1)`. -/
def hFoldLo (M : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (c + 1) => add (hFoldLo M c) ⟨1, M + c + 1⟩

theorem hFoldLo_den_pos (M : Nat) : ∀ c, 0 < (hFoldLo M c).den
  | 0 => Nat.one_pos
  | (c + 1) => add_den_pos (hFoldLo_den_pos M c) (Nat.succ_pos _)

/-- **Telescoped upper bound**: `log(M+c) ≤ Σ_{i<c} 1/(M+i) + log M`. -/
theorem logN_telescope_upper (M : Nat) (hM : 1 ≤ M) :
    ∀ c, Rle (logN (M + c) (Nat.le_trans hM (Nat.le_add_right M c)))
      (Radd (ofQ (hFold M c) (hFold_den_pos M hM c)) (logN M hM))
  | 0 => Rle_of_Req (Req_symm (Req_trans (Radd_comm _ _) (Radd_zero _)))
  | (c + 1) => by
      refine Rle_trans (logN_step_upper (M + c) (Nat.le_trans hM (Nat.le_add_right M c))) ?_
      refine Rle_trans (Radd_le_add
        (Rle_refl (ofQ (⟨1, M + c⟩ : Q) (Nat.le_trans hM (Nat.le_add_right M c))))
        (logN_telescope_upper M hM c)) ?_
      refine Rle_of_Req ?_
      refine Req_trans (Req_symm (Radd_assoc _ _ _)) ?_
      refine Radd_congr ?_ (Req_refl (logN M hM))
      refine Req_trans (Radd_ofQ_ofQ (Nat.le_trans hM (Nat.le_add_right M c))
        (hFold_den_pos M hM c)) ?_
      exact ofQ_congr (add_den_pos (Nat.le_trans hM (Nat.le_add_right M c))
        (hFold_den_pos M hM c)) (hFold_den_pos M hM (c + 1)) (add_comm _ _)

/-- **Telescoped lower bound**: `Σ_{i<c} 1/(M+i+1) + log M ≤ log(M+c)`. -/
theorem logN_telescope_lower (M : Nat) (hM : 1 ≤ M) :
    ∀ c, Rle (Radd (ofQ (hFoldLo M c) (hFoldLo_den_pos M c)) (logN M hM))
      (logN (M + c) (Nat.le_trans hM (Nat.le_add_right M c)))
  | 0 => Rle_of_Req (Req_trans (Radd_comm _ _) (Radd_zero _))
  | (c + 1) => by
      refine Rle_trans ?_ (logN_step_lower (M + c) (Nat.le_trans hM (Nat.le_add_right M c)))
      refine Rle_trans (Rle_of_Req ?_) (Radd_le_add
        (Rle_refl (ofQ (⟨1, M + c + 1⟩ : Q) (Nat.succ_pos _)))
        (logN_telescope_lower M hM c))
      -- `ofQ(fold + 1/(M+c+1)) + log M ≈ 1/(M+c+1) + (fold + log M)`
      refine Req_trans (Radd_congr (Req_symm (Req_trans
        (Radd_ofQ_ofQ (Nat.succ_pos (M + c)) (hFoldLo_den_pos M c))
        (ofQ_congr (add_den_pos (Nat.succ_pos (M + c)) (hFoldLo_den_pos M c))
          (hFoldLo_den_pos M (c + 1)) (add_comm _ _)))) (Req_refl (logN M hM))) ?_
      exact Radd_assoc _ _ _

/-- The exact telescoping defect: `hFold M c = hFoldLo M c + (1/M − 1/(M+c))`. -/
theorem hFold_eq_hFoldLo (M : Nat) (hM : 1 ≤ M) :
    ∀ c, Qeq (hFold M c) (add (hFoldLo M c) (Qsub ⟨1, M⟩ ⟨1, M + c⟩))
  | 0 => by simp only [Qeq, hFold, hFoldLo, Qsub, add, neg]; push_cast; ring_uor
  | (c + 1) => by
      have ih := hFold_eq_hFoldLo M hM c
      have hstep : Qeq (hFold M (c + 1))
          (add (add (hFoldLo M c) (Qsub ⟨1, M⟩ ⟨1, M + c⟩)) ⟨1, M + c⟩) :=
        Qadd_congr ih (Qeq_refl _)
      refine Qeq_trans (add_den_pos (add_den_pos (hFoldLo_den_pos M c)
        (Qsub_den_pos (show 0 < M from hM) (show 0 < M + c by omega)))
        (show 0 < M + c by omega)) hstep ?_
      show Qeq (add (add (hFoldLo M c) (Qsub ⟨1, M⟩ ⟨1, M + c⟩)) ⟨1, M + c⟩)
        (add (add (hFoldLo M c) ⟨1, M + c + 1⟩) (Qsub ⟨1, M⟩ ⟨1, M + c + 1⟩))
      generalize hFoldLo M c = q
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- **The wedge, lower side**: `log 2 ≤ Σ_{j<M} 1/(M+j)`. -/
theorem log2_le_hFold (M : Nat) (hM : 1 ≤ M) :
    Rle (logN 2 (by omega)) (ofQ (hFold M M) (hFold_den_pos M hM M)) := by
  refine Radd_le_cancel_right (c := logN M hM) ?_
  refine Rle_trans (Rle_of_Req (Req_trans (logN_mul M hM)
    (logN_eq_of_eq (show 2 * M = M + M by omega) (show 1 ≤ 2 * M by omega)
      (Nat.le_trans hM (Nat.le_add_right M M))))) ?_
  exact logN_telescope_upper M hM M

/-- **The wedge, upper side**: `Σ_{j<M} 1/(M+j) ≤ log 2 + 1/(2M)`. -/
theorem hFold_le_log2_add (M : Nat) (hM : 1 ≤ M) :
    Rle (ofQ (hFold M M) (hFold_den_pos M hM M))
      (Radd (logN 2 (by omega)) (ofQ (⟨1, 2 * M⟩ : Q) (show 0 < 2 * M by omega))) := by
  have hlo : Rle (ofQ (hFoldLo M M) (hFoldLo_den_pos M M)) (logN 2 (by omega)) := by
    refine Radd_le_cancel_right (c := logN M hM) ?_
    refine Rle_trans (logN_telescope_lower M hM M) ?_
    exact Rle_of_Req (Req_symm (Req_trans (logN_mul M hM)
      (logN_eq_of_eq (show 2 * M = M + M by omega) (show 1 ≤ 2 * M by omega)
        (Nat.le_trans hM (Nat.le_add_right M M)))))
  have hsplit : Req (ofQ (hFold M M) (hFold_den_pos M hM M))
      (Radd (ofQ (hFoldLo M M) (hFoldLo_den_pos M M)) (ofQ (⟨1, 2 * M⟩ : Q) (show 0 < 2 * M by omega))) := by
    refine Req_trans (ofQ_congr (hFold_den_pos M hM M)
      (add_den_pos (hFoldLo_den_pos M M)
        (show 0 < (⟨1, 2 * M⟩ : Q).den from (show 0 < 2 * M by omega))) ?_) ?_
    · refine Qeq_trans (add_den_pos (hFoldLo_den_pos M M)
        (Qsub_den_pos (show 0 < M from hM) (show 0 < M + M by omega)))
        (hFold_eq_hFoldLo M hM M) ?_
      refine Qadd_congr (Qeq_refl _) ?_
      show Qeq (Qsub ⟨1, M⟩ ⟨1, M + M⟩) (⟨1, 2 * M⟩ : Q)
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    · exact Req_symm (Radd_ofQ_ofQ (hFoldLo_den_pos M M) (show 0 < 2 * M by omega))
  refine Rle_trans (Rle_of_Req hsplit) ?_
  exact Radd_le_add hlo (Rle_refl _)

/-- **The wedge as an absolute defect**: `|Σ_{j<M} 1/(M+j) − log 2| ≤ 1/(2M)`. -/
theorem hFold_log2_defect (M : Nat) (hM : 1 ≤ M) :
    Rle (Rabs (Rsub (ofQ (hFold M M) (hFold_den_pos M hM M)) (logN 2 (by omega))))
      (ofQ (⟨1, 2 * M⟩ : Q) (show 0 < 2 * M by omega)) := by
  refine Rabs_le_of_both (Rsub_le_of_le_Radd (hFold_le_log2_add M hM)) ?_
  refine Rle_trans (Rle_of_Req (Rneg_Rsub _ _)) ?_
  refine Rle_trans (Rsub_nonpos_of_Rle (log2_le_hFold M hM)) ?_
  exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (c := (⟨1, 2 * M⟩ : Q)) (show 0 < 2 * M by omega) (show (0 : Int) ≤ 1 by decide))

-- ===========================================================================
-- The reciprocal integrand `1/(1+t)` (total, via the clamp — inert on [0,1]).
-- ===========================================================================

/-- **The reciprocal integrand** `gRecip t = 1/max(1+t, 1)` — the totalized `1/(1+t)`. -/
def gRecip : Real → Real :=
  fun t => clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd one t)

/-- `gRecip` is `1`-Lipschitz (clamped-reciprocal at floor `1`, composed with a unit shift). -/
theorem gRecip_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (gRecip x) (gRecip y)))
      (Rmul (ofQ (⟨1, 1⟩ : Q) Nat.one_pos) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide)
    (Radd one x) (Radd one y)) ?_
  refine Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_congr ?_))
  -- `(1+x) − (1+y) ≈ x − y`
  refine Req_trans (Rsub_Radd_Radd one x one y) ?_
  refine Req_trans (Radd_congr (Radd_neg one) (Req_refl (Rsub x y))) ?_
  exact Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y))

/-- `gRecip` respects `≈`. -/
theorem gRecip_congr : ∀ x y : Real, Req x y → Req (gRecip x) (gRecip y) :=
  fun _ _ h => clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_congr (Req_refl one) h)

-- The cross-multiplied point identity as a pure-`Int` lemma (`push_cast` leaves `mdata`
-- that `ring_uor`'s frontend rejects — the established Inv.lean idiom).
private theorem grecip_point_core (n j : Int) :
    (1 * n) * (n + j) = n * (1 * n + j * 1) := by ring_uor

/-- **The partition-point value**: `gRecip(j/(N+1)) ≈ (N+1)/(N+1+j)`. -/
theorem gRecip_point (j N : Nat) :
    Req (gRecip (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (ofQ (⟨((N + 1 : Nat) : Int), N + 1 + j⟩ : Q) (show 0 < N + 1 + j by omega)) := by
  have hqd : 0 < (add (⟨1, 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)).den :=
    Nat.mul_pos Nat.one_pos (Nat.succ_pos N)
  have hqn : 0 < (add (⟨1, 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)).num := by
    show 0 < (1 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1
    push_cast; omega
  have haq : Qle (⟨1, 1⟩ : Q) (add (⟨1, 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q)) := by
    show (1 : Int) * ((1 * (N + 1) : Nat) : Int)
      ≤ ((1 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1) * 1
    push_cast; omega
  refine Req_trans (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
    (Radd_ofQ_ofQ Nat.one_pos (Nat.succ_pos N))) ?_
  refine Req_trans (clampedInv_ofQ (a := (⟨1, 1⟩ : Q))
    (q := add (⟨1, 1⟩ : Q) (⟨(j : Int), N + 1⟩ : Q))
    (by decide) (by decide) hqd hqn haq) ?_
  refine ofQ_congr (Qinv_den_pos hqn) (show 0 < N + 1 + j by omega) ?_
  show ((1 * (N + 1) : Nat) : Int) * ((N + 1 + j : Nat) : Int)
    = ((N + 1 : Nat) : Int)
      * ((((1 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1).toNat : Nat) : Int)
  have htn : ((((1 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1).toNat : Nat) : Int)
      = (1 : Int) * ((N + 1 : Nat) : Int) + (j : Int) * 1 := by
    push_cast; omega
  rw [htn]; push_cast
  exact grecip_point_core ((N : Int) + 1) (j : Int)

-- ===========================================================================
-- The Riemann sums are harmonic differences.
-- ===========================================================================

/-- The unscaled term fold `Σ_{i<k} (N+1)/(N+1+i)`. -/
def harmTermFold (N : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (k + 1) => add (harmTermFold N k) ⟨((N + 1 : Nat) : Int), N + 1 + k⟩

theorem harmTermFold_den_pos (N : Nat) : ∀ k, 0 < (harmTermFold N k).den
  | 0 => Nat.one_pos
  | (k + 1) => add_den_pos (harmTermFold_den_pos N k) (show 0 < N + 1 + k by omega)

/-- The `ℚ`-level fold of the partition values. -/
theorem RsumN_gRecip (N : Nat) : ∀ k,
    Req (RsumN (fun i => gRecip (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) k)
      (ofQ (harmTermFold N k) (harmTermFold_den_pos N k))
  | 0 => Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | (k + 1) => by
      refine Req_trans (Radd_congr (RsumN_gRecip N k) (gRecip_point k N)) ?_
      exact Radd_ofQ_ofQ (harmTermFold_den_pos N k) (show 0 < N + 1 + k by omega)

/-- The scaling collapse: `(1/(N+1))·Σ_{i<k} (N+1)/(N+1+i) = Σ_{i<k} 1/(N+1+i)`. -/
theorem harmTermFold_scale (N : Nat) :
    ∀ k, Qeq (mul (⟨1, N + 1⟩ : Q) (harmTermFold N k)) (hFold (N + 1) k)
  | 0 => by simp only [Qeq, hFold, harmTermFold, mul]; push_cast; ring_uor
  | (k + 1) => by
      refine Qeq_trans (add_den_pos
        (Qmul_den_pos (Nat.succ_pos N) (harmTermFold_den_pos N k))
        (Qmul_den_pos (Nat.succ_pos N) (show 0 < N + 1 + k by omega)))
        (Qmul_add_left (⟨1, N + 1⟩ : Q) (harmTermFold N k)
          (⟨((N + 1 : Nat) : Int), N + 1 + k⟩ : Q)) ?_
      refine Qadd_congr (harmTermFold_scale N k) ?_
      show Qeq (mul (⟨1, N + 1⟩ : Q) (⟨((N + 1 : Nat) : Int), N + 1 + k⟩ : Q))
        (⟨1, N + 1 + k⟩ : Q)
      simp only [Qeq, mul]; push_cast; ring_uor

/-- **The left Riemann sum of `1/(1+t)` is the harmonic difference**
    `Σ_{j<M} 1/(M+j)` at `M = N+1`. -/
theorem riemannSum_gRecip (N : Nat) :
    Req (riemannSum gRecip N)
      (ofQ (hFold (N + 1) (N + 1)) (hFold_den_pos (N + 1) (Nat.succ_pos N) (N + 1))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => gRecip (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _) (RsumN_gRecip N (N + 1))) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N) (harmTermFold_den_pos N (N + 1))) ?_
  exact ofQ_congr (Qmul_den_pos (Nat.succ_pos N) (harmTermFold_den_pos N (N + 1)))
    (hFold_den_pos (N + 1) (Nat.succ_pos N) (N + 1)) (harmTermFold_scale N (N + 1))

-- ===========================================================================
-- The dyadic rate and the evaluation ∫₀¹ dx/(1+x) ≈ log 2.
-- ===========================================================================

/-- The anchor: `D₀ = R₀(gRecip) = gRecip(0) ≈ 1`. -/
theorem dyadicR_gRecip_zero : Req (dyadicR gRecip 0) one := by
  refine Req_trans (riemannSum_gRecip (2 ^ 0 - 1)) ?_
  exact ofQ_congr (hFold_den_pos 1 Nat.one_pos 1) Nat.one_pos (by decide)

/-- `hFold` transport along an equality of the base (dependency-free `Req`). -/
private theorem ofQ_hFold_eq {M M' : Nat} (h : M = M') (hM : 1 ≤ M) (hM' : 1 ≤ M') :
    Req (ofQ (hFold M M) (hFold_den_pos M hM M))
      (ofQ (hFold M' M') (hFold_den_pos M' hM' M')) := by
  subst h; exact Req_refl _

/-- The rate at an arbitrary dyadic depth `m` with `j + 1 ≤ 2^m`. -/
private theorem genSum_gRecip_rate_aux (m j : Nat) (hjm : j + 1 ≤ 2 ^ m) :
    Rle (Rabs (Rsub (genSum (dyadicTerm gRecip) m)
        (Rsub (logN 2 (by omega)) one)))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have hMpos : 1 ≤ 2 ^ m := Nat.one_le_two_pow
  have hE : 2 ^ m - 1 + 1 = 2 ^ m := by omega
  have heval : Req (dyadicR gRecip m)
      (ofQ (hFold (2 ^ m) (2 ^ m)) (hFold_den_pos (2 ^ m) hMpos (2 ^ m))) :=
    Req_trans (riemannSum_gRecip (2 ^ m - 1))
      (ofQ_hFold_eq hE (Nat.succ_pos (2 ^ m - 1)) hMpos)
  have hgen : Req (genSum (dyadicTerm gRecip) m)
      (Rsub (ofQ (hFold (2 ^ m) (2 ^ m)) (hFold_den_pos (2 ^ m) hMpos (2 ^ m))) one) :=
    Req_trans (genSum_telescope gRecip m) (Rsub_congr heval dyadicR_gRecip_zero)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_congr hgen (Req_refl (Rsub (logN 2 (by omega)) one)))
    (Rsub_shift_drop _ (logN 2 (by omega)) one)))) ?_
  refine Rle_trans (hFold_log2_defect (2 ^ m) hMpos) ?_
  refine Rle_ofQ_ofQ (show 0 < 2 * 2 ^ m by omega) (Nat.succ_pos j) ?_
  show (1 : Int) * ((j + 1 : Nat) : Int) ≤ (1 : Int) * ((2 * 2 ^ m : Nat) : Int)
  have hc : ((j + 1 : Nat) : Int) ≤ ((2 * 2 ^ m : Nat) : Int) :=
    Int.ofNat_le.mpr (by omega)
  omega

/-- **The dyadic rate**: the telescoped sums sit within `1/(j+1)` of `log 2 − 1`, for every
    schedule (`M = digammaMidx L j ≥ j+1`, and the wedge width is `1/(2·2^M)`). -/
theorem genSum_gRecip_rate (L : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm gRecip) (digammaMidx L j))
        (Rsub (logN 2 (by omega)) one)))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine genSum_gRecip_rate_aux (digammaMidx L j) j ?_
  have h1 : j + 1 < 2 ^ (j + 1) := Nat.lt_two_pow_self
  have h2 : 2 ^ (j + 1) ≤ 2 ^ (digammaMidx L j) := by
    refine Nat.pow_le_pow_right (by decide) ?_
    show j + 1 ≤ (L.num.toNat + 1) * (j + 1)
    have h3 : 1 * (j + 1) ≤ (L.num.toNat + 1) * (j + 1) :=
      Nat.mul_le_mul_right (j + 1) (by omega)
    omega
  omega

/-- **`∫₀¹ dx/(1+x) ≈ log 2`, general in the Lipschitz datum** — the first certified
    integral evaluation to a non-rational value. -/
theorem riemannIntegral_recip_gen {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (gRecip x) (gRecip y)))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y : Real, Req x y → Req (gRecip x) (gRecip y)) :
    Req (riemannIntegral (f := gRecip) hLd hLn hlip hfc) (logN 2 (by omega)) := by
  show Req (Radd (dyadicR gRecip 0) _) (logN 2 (by omega))
  have hlim : Req (Rlim (fun j => genSum (dyadicTerm gRecip) (digammaMidx L j))
      (dyadicSum_RReg hLd hLn hlip hfc))
      (Rsub (logN 2 (by omega)) one) :=
    Rlim_eval_real _ (Rsub (logN 2 (by omega)) one) (fun j => genSum_gRecip_rate L j)
  refine Req_trans (Radd_congr dyadicR_gRecip_zero hlim) ?_
  exact Radd_Rsub_cancel (logN 2 (by omega)) one

/-- **`∫₀¹ dx/(1+x) ≈ log 2`** — the headline instance at the canonical modulus `L = 1`. -/
theorem riemannIntegral_recip :
    Req (riemannIntegral (f := gRecip) (L := (⟨1, 1⟩ : Q)) Nat.one_pos (by decide)
      gRecip_lip gRecip_congr) (logN 2 (by omega)) :=
  riemannIntegral_recip_gen Nat.one_pos (by decide) gRecip_lip gRecip_congr

end UOR.Bridge.F1Square.Analysis
