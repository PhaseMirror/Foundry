/-
F1 square — **the `t4` archimedean tail, part 2: the improper remainder**
(`T4TailImproper.lean`). The `t4` arch tail's improper piece is
`−4log2·∫₄^∞ dx/(x²−1)`; substituting `x = w + 3` and splitting the partial
fractions, the core object is

    `∫₁^∞ (1/(w+2) − 1/(w+4)) dw ≈ log 5 − log 3`

— the shifted mirror of the tent's `improperTail` (`TentArchTail`): blocks evaluate to
telescoping `logN` differences through `riemannIntegral_recipC_gen` at bases `m+3`,
`m+5`; the partial sums close to `(log(N+3) − log 3) − (log(N+5) − log 5)`; the block
decay is `K = 3` from the per-step log bracket; and the deviation
`log(N+5) − log(N+3) ≤ 2/(N+3)`-shape meets the `K = 3` schedule.

HONEST SCOPE. One improper-integral evaluation; the slot assembly is the companion
brick. No positivity claim. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.T4ArchPieces
import Multiplicity.F1Square.Analysis.TentArchTail

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- `(P−Q) − (P'−Q') ≈ (P−P') + (Q'−Q)` (private copy). -/
private theorem t4t_sub_pair (P Q P' Q' : Real) :
    Req (Rsub (Rsub P Q) (Rsub P' Q')) (Radd (Rsub P P') (Rsub Q' Q)) :=
  Req_trans (Rsub_Radd_Radd P (Rneg Q) P' (Rneg Q'))
    (Radd_congr (Req_refl (Rsub P P')) (Rsub_Rneg_pair Q Q'))

/-- The shifted clamp core is `1`-Lipschitz (any rational shift). -/
private theorem t4t_shift_lip (q : Q) (hq : 0 < q.den) (x y : Real) :
    Rle (Rabs (Rsub
      (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ q hq) x))
      (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ q hq) y))))
      (Rabs (Rsub x y)) := by
  refine Rle_trans (Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide) _ _)
    (Rle_of_Req (Rone_mul _))) ?_
  refine Rle_of_Req (Rabs_congr ?_)
  refine Req_trans (Rsub_Radd_Radd (ofQ q hq) x (ofQ q hq) y) ?_
  refine Req_trans (Radd_congr (Radd_neg (ofQ q hq)) (Req_refl (Rsub x y))) ?_
  exact Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y))

-- ===========================================================================
-- The integrand `1/(w+2) − 1/(w+4)`, total via the floor-1 clamps.
-- ===========================================================================

/-- The `t4` tail integrand `t4Tail w = 1/max(w+2,1) − 1/max(w+4,1)` — on `[1, ∞)`
    this is `1/(w+2) − 1/(w+4)`, the substituted `2/(x²−1)` at `x = w+3`. -/
def t4Tail : Real → Real :=
  fun w => Rsub
    (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) w))
    (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ (⟨4, 1⟩ : Q) (by decide)) w))

/-- `t4Tail` is `2`-Lipschitz. -/
theorem t4Tail_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (t4Tail x) (t4Tail y)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (t4t_sub_pair _ _ _ _))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add (t4t_shift_lip (⟨2, 1⟩ : Q) (by decide) x y)
    (Rle_trans (t4t_shift_lip (⟨4, 1⟩ : Q) (by decide) y x)
      (Rle_of_Req (Rabs_Rsub_swap x y)))) ?_
  exact Rle_of_Req (Req_symm (Rmul_two_eq (Rabs (Rsub x y))))

/-- `t4Tail` respects `≈`. -/
theorem t4Tail_congr : ∀ x y : Real, Req x y → Req (t4Tail x) (t4Tail y) :=
  fun _ _ h => Rsub_congr
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) (Radd_congr (Req_refl _) h))
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) (Radd_congr (Req_refl _) h))

-- ===========================================================================
-- The block pullback and evaluation.
-- ===========================================================================

/-- **The block pullback, pointwise**:
    `t4Tail((m+1) + t) ≈ gRecipC (m+3) t − gRecipC (m+5) t`. -/
theorem t4Tail_pull (m : Nat) (t : Real) :
    Req (t4Tail (affineMap ⟨(m : Int) + 1, 1⟩ ⟨1, 1⟩ Nat.one_pos (by decide) t))
      (Rsub (gRecipC (m + 3) t) (gRecipC (m + 5) t)) := by
  refine Rsub_congr
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) ?_)
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) ?_)
  · refine Req_trans (Radd_congr (Req_refl _)
      (Radd_congr (Req_refl _) (Rone_mul t))) ?_
    refine Req_trans (Req_symm (Radd_assoc (ofQ (⟨2, 1⟩ : Q) (by decide))
      (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos) t)) ?_
    refine Radd_congr ?_ (Req_refl t)
    refine Req_trans (Radd_ofQ_ofQ (a := (⟨2, 1⟩ : Q)) (b := (⟨(m : Int) + 1, 1⟩ : Q))
      (by decide) Nat.one_pos) ?_
    refine ofQ_congr (add_den_pos (by decide) Nat.one_pos) Nat.one_pos ?_
    show Qeq (add (⟨2, 1⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q)) (⟨((m + 3 : Nat) : Int), 1⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor
  · refine Req_trans (Radd_congr (Req_refl _)
      (Radd_congr (Req_refl _) (Rone_mul t))) ?_
    refine Req_trans (Req_symm (Radd_assoc (ofQ (⟨4, 1⟩ : Q) (by decide))
      (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos) t)) ?_
    refine Radd_congr ?_ (Req_refl t)
    refine Req_trans (Radd_ofQ_ofQ (a := (⟨4, 1⟩ : Q)) (b := (⟨(m : Int) + 1, 1⟩ : Q))
      (by decide) Nat.one_pos) ?_
    refine ofQ_congr (add_den_pos (by decide) Nat.one_pos) Nat.one_pos ?_
    show Qeq (add (⟨4, 1⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q)) (⟨((m + 5 : Nat) : Int), 1⟩ : Q)
    simp only [Qeq, add]; push_cast; ring_uor

/-- The block value `[log(m+4) − log(m+3)] − [log(m+6) − log(m+5)]`. -/
def t4BlockVal (m : Nat) : Real :=
  Rsub (Rsub (logN (m + 3 + 1) (by omega)) (logN (m + 3) (by omega)))
    (Rsub (logN (m + 5 + 1) (by omega)) (logN (m + 5) (by omega)))

set_option maxHeartbeats 1600000 in
/-- **The block evaluation**: `∫_{m+1}^{m+2} t4Tail ≈ t4BlockVal m`. -/
theorem integralTerm_t4Tail (m : Nat) :
    Req (integralTerm (f := t4Tail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      t4Tail_lip t4Tail_congr m) (t4BlockVal m) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (riemannIntegral_congr
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide)) _ _
    (diffC_lip (m + 3) (m + 5) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (diffC_congr (m + 3) (m + 5))
    (fun t => t4Tail_pull m t)) ?_
  refine Req_trans (riemannIntegral_add
    (f := gRecipC (m + 3))
    (g := fun t => Rneg (gRecipC (m + 5) t))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at (m + 3) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (gRecipC_congr (m + 3))
    (fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Rneg_pair _ _)))
      (Rle_trans (gRecipC_lip_at (m + 5) (L := mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q))
        (Qmul_den_pos (by decide) (by decide)) (by decide) y x)
        (Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y)))))
    (fun x y h => Rneg_congr (gRecipC_congr (m + 5) x y h))
    (diffC_lip (m + 3) (m + 5) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (diffC_congr (m + 3) (m + 5))) ?_
  refine Radd_congr
    (riemannIntegral_recipC_gen (m + 3) (by omega)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecipC_lip_at (m + 3) (Qmul_den_pos (by decide) (by decide)) (by decide))
      (gRecipC_congr (m + 3))) ?_
  refine Req_trans (riemannIntegral_neg
    (f := gRecipC (m + 5))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at (m + 5) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (gRecipC_congr (m + 5))
    (fun x y => Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Rneg_pair _ _)))
      (Rle_trans (gRecipC_lip_at (m + 5) (L := mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q))
        (Qmul_den_pos (by decide) (by decide)) (by decide) y x)
        (Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y)))))
    (fun x y h => Rneg_congr (gRecipC_congr (m + 5) x y h))) ?_
  exact Rneg_congr (riemannIntegral_recipC_gen (m + 5) (by omega)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at (m + 5) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (gRecipC_congr (m + 5)))

-- ===========================================================================
-- The telescoping partial sums, the decay, the rate, the evaluation.
-- ===========================================================================

/-- The closed telescoped form `(log(N+3) − log 3) − (log(N+5) − log 5)`. -/
def t4TailF (N : Nat) : Real :=
  Rsub (Rsub (logN (N + 3) (by omega)) (logN 3 (by omega)))
    (Rsub (logN (N + 5) (by omega)) (logN 5 (by omega)))

/-- **The partial sums telescope**: `genSum T N ≈ t4TailF N`. -/
theorem genSum_t4Tail (N : Nat) :
    Req (genSum (integralTerm (f := t4Tail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      t4Tail_lip t4Tail_congr) N) (t4TailF N) := by
  induction N with
  | zero =>
      refine Req_symm (Req_trans (Rsub_congr (Radd_neg _) (Radd_neg _)) ?_)
      exact Rsub_zero zero
  | succ N ih =>
      refine Req_trans (Radd_congr ih (integralTerm_t4Tail N)) ?_
      exact tail_step_alg (logN (N + 3) (by omega)) (logN (N + 3 + 1) (by omega))
        (logN (N + 5) (by omega)) (logN (N + 5 + 1) (by omega))
        (logN 3 (by omega)) (logN 5 (by omega))

private theorem t4t_Rneg_zero : Req (Rneg zero) zero :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (neg (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q)
    decide)

set_option maxHeartbeats 1600000 in
/-- **The block decay** (`K = 3`): `−3/((m+1)m) ≤ T m ≤ 3/((m+1)m)` for `m ≥ 1`. -/
theorem t4tail_decay : ∀ m, ∀ hm : 1 ≤ m,
    Rle (Rneg (ofQ (mul (⟨3, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))))
      (integralTerm (f := t4Tail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
        t4Tail_lip t4Tail_congr m)
    ∧ Rle (integralTerm (f := t4Tail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
        t4Tail_lip t4Tail_congr m)
      (ofQ (mul (⟨3, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))) := by
  intro m hm
  have hPhi : Rle (Rsub (logN (m + 3 + 1) (by omega)) (logN (m + 3) (by omega)))
      (ofQ (⟨1, m + 3⟩ : Q) (show 0 < m + 3 by omega)) :=
    Rsub_le_of_le_Radd (Rle_trans (logN_step_upper (m + 3) (by omega))
      (Rle_of_Req (Radd_comm _ _)))
  have hPlo : Rle (ofQ (⟨1, m + 3 + 1⟩ : Q) (Nat.succ_pos _))
      (Rsub (logN (m + 3 + 1) (by omega)) (logN (m + 3) (by omega))) :=
    Rle_Rsub_of_Radd_le (logN_step_lower (m + 3) (by omega))
  have hQhi : Rle (Rsub (logN (m + 5 + 1) (by omega)) (logN (m + 5) (by omega)))
      (ofQ (⟨1, m + 5⟩ : Q) (show 0 < m + 5 by omega)) :=
    Rsub_le_of_le_Radd (Rle_trans (logN_step_upper (m + 5) (by omega))
      (Rle_of_Req (Radd_comm _ _)))
  have hQlo : Rle (ofQ (⟨1, m + 5 + 1⟩ : Q) (Nat.succ_pos _))
      (Rsub (logN (m + 5 + 1) (by omega)) (logN (m + 5) (by omega))) :=
    Rle_Rsub_of_Radd_le (logN_step_lower (m + 5) (by omega))
  constructor
  · refine Rle_trans (Rle_trans (Rneg_le (Rle_zero_of_Rnonneg
      (Rnonneg_ofQ (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))
        (show (0 : Int) ≤ 3 * 1 by decide)))) (Rle_of_Req t4t_Rneg_zero)) ?_
    refine Rle_trans ?_ (Rle_of_Req (Req_symm (integralTerm_t4Tail m)))
    refine Rle_trans ?_ (Radd_le_add hPlo (Rneg_le hQhi))
    refine Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_ofQ
      (add_den_pos (Nat.succ_pos _) (show 0 < m + 5 by omega))
      (show (0 : Int) ≤ (add (⟨1, m + 3 + 1⟩ : Q) (neg (⟨1, m + 5⟩ : Q))).num from by
        show (0 : Int) ≤ 1 * ((m + 5 : Nat) : Int) + (-1) * ((m + 3 + 1 : Nat) : Int)
        omega))) ?_
    refine Rle_of_Req (Req_symm ?_)
    exact Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1, m + 5⟩ : Q)
      (show 0 < m + 5 by omega)))
      (Radd_ofQ_ofQ (Nat.succ_pos _) (show 0 < m + 5 by omega))
  · refine Rle_trans (Rle_of_Req (integralTerm_t4Tail m)) ?_
    refine Rle_trans (Radd_le_add hPhi (Rneg_le hQlo)) ?_
    refine Rle_trans (Rle_of_Req (Req_trans (Radd_congr (Req_refl _)
      (Rneg_ofQ (⟨1, m + 5 + 1⟩ : Q) (Nat.succ_pos _)))
      (Radd_ofQ_ofQ (show 0 < m + 3 by omega) (Nat.succ_pos _)))) ?_
    refine Rle_ofQ_ofQ (add_den_pos (show 0 < m + 3 by omega) (Nat.succ_pos _))
      (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm)) ?_
    show ((1 : Int) * ((m + 5 + 1 : Nat) : Int) + (-1) * ((m + 3 : Nat) : Int))
        * ((1 * ((m + 1) * m) : Nat) : Int)
      ≤ ((3 : Int) * 1) * (((m + 3) * (m + 5 + 1) : Nat) : Int)
    have hA : (1 : Int) * ((m + 5 + 1 : Nat) : Int) + (-1) * ((m + 3 : Nat) : Int)
        = (3 : Int) := by push_cast; ring_uor
    rw [hA]
    have hden : (1 * ((m + 1) * m) : Nat) ≤ ((m + 3) * (m + 5 + 1) : Nat) := by
      rw [Nat.one_mul]
      exact Nat.mul_le_mul (by omega) (by omega)
    have hcast : ((1 * ((m + 1) * m) : Nat) : Int) ≤ (((m + 3) * (m + 5 + 1) : Nat) : Int) :=
      Int.ofNat_le.mpr hden
    have h3 : (3 : Int) * ((1 * ((m + 1) * m) : Nat) : Int)
        ≤ (3 : Int) * (((m + 3) * (m + 5 + 1) : Nat) : Int) :=
      Int.mul_le_mul_of_nonneg_left hcast (by decide)
    omega

/-- `(X+Y) − Y ≈ X` (private copy). -/
private theorem t4t_add_sub_cancel (X Y : Real) : Req (Rsub (Radd X Y) Y) X :=
  Req_trans (Radd_assoc X Y (Rneg Y))
    (Req_trans (Radd_congr (Req_refl X) (Radd_neg Y)) (Radd_zero X))

set_option maxHeartbeats 1600000 in
/-- The rate at depth `N` with `2(j+1) ≤ N+3`. -/
private theorem t4tail_rate_aux (N j : Nat) (hjN : 2 * (j + 1) ≤ N + 3) :
    Rle (Rabs (Rsub (genSum (integralTerm (f := t4Tail) (L := (⟨2, 1⟩ : Q))
        (by decide) (by decide) t4Tail_lip t4Tail_congr) N)
      (Rsub (logN 5 (by omega)) (logN 3 (by omega)))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have halg : Req (Rsub (t4TailF N) (Rsub (logN 5 (by omega)) (logN 3 (by omega))))
      (Rsub (logN (N + 3) (by omega)) (logN (N + 5) (by omega))) := by
    refine Req_trans (Rsub_congr (t4t_sub_pair (logN (N + 3) (by omega))
      (logN 3 (by omega)) (logN (N + 5) (by omega)) (logN 5 (by omega)))
      (Req_refl (Rsub (logN 5 (by omega)) (logN 3 (by omega))))) ?_
    exact t4t_add_sub_cancel
      (Rsub (logN (N + 3) (by omega)) (logN (N + 5) (by omega)))
      (Rsub (logN 5 (by omega)) (logN 3 (by omega)))
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_congr (genSum_t4Tail N) (Req_refl _)) halg))) ?_
  refine Rabs_le_of_both ?_ ?_
  · refine Rle_trans (Rsub_nonpos_of_Rle
      (logN_mono (by omega) (show N + 3 ≤ N + 5 by omega))) ?_
    exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (Nat.succ_pos j)
      (show (0 : Int) ≤ 1 by decide))
  · refine Rle_trans (Rle_of_Req (Rneg_Rsub _ _)) ?_
    have hb2 : Rle (logN (N + 5) (by omega))
        (Radd (logN (N + 3) (by omega))
          (ofQ (add (⟨1, N + 4⟩ : Q) (⟨1, N + 3⟩ : Q))
            (add_den_pos (show 0 < N + 4 by omega) (show 0 < N + 3 by omega)))) := by
      refine Rle_trans (logN_step_upper (N + 4) (by omega)) ?_
      refine Rle_trans (Radd_le_add
        (Rle_refl (ofQ (⟨1, N + 4⟩ : Q) (show 0 < N + 4 by omega)))
        (logN_step_upper (N + 3) (by omega))) ?_
      refine Rle_of_Req ?_
      refine Req_trans (Req_symm (Radd_assoc (ofQ (⟨1, N + 4⟩ : Q) (show 0 < N + 4 by omega))
        (ofQ (⟨1, N + 3⟩ : Q) (show 0 < N + 3 by omega)) (logN (N + 3) (by omega)))) ?_
      refine Req_trans (Radd_congr (Radd_ofQ_ofQ (show 0 < N + 4 by omega)
        (show 0 < N + 3 by omega)) (Req_refl (logN (N + 3) (by omega)))) ?_
      exact Radd_comm _ _
    refine Rle_trans (Rsub_le_of_le_Radd hb2) ?_
    refine Rle_ofQ_ofQ (add_den_pos (show 0 < N + 4 by omega) (show 0 < N + 3 by omega))
      (Nat.succ_pos j) ?_
    show ((1 : Int) * ((N + 3 : Nat) : Int) + (1 : Int) * ((N + 4 : Nat) : Int))
        * ((j + 1 : Nat) : Int)
      ≤ (1 : Int) * (((N + 4) * (N + 3) : Nat) : Int)
    have hA : (1 : Int) * ((N + 3 : Nat) : Int) + (1 : Int) * ((N + 4 : Nat) : Int)
        = ((2 * N + 7 : Nat) : Int) := by push_cast; ring_uor
    rw [hA, Int.one_mul, ← Int.natCast_mul]
    refine Int.ofNat_le.mpr ?_
    calc (2 * N + 7) * (j + 1) ≤ (2 * (N + 4)) * (j + 1) :=
          Nat.mul_le_mul_right _ (by omega)
      _ = (N + 4) * (2 * (j + 1)) := by
          rw [Nat.mul_assoc, Nat.mul_left_comm]
      _ ≤ (N + 4) * (N + 3) := Nat.mul_le_mul_left _ hjN

/-- The rate at the improper integral\'s own schedule (`K = 3`). -/
theorem t4tail_rate (j : Nat) :
    Rle (Rabs (Rsub (genSum (integralTerm (f := t4Tail) (L := (⟨2, 1⟩ : Q))
        (by decide) (by decide) t4Tail_lip t4Tail_congr)
        (digammaMidx (⟨3, 1⟩ : Q) j))
      (Rsub (logN 5 (by omega)) (logN 3 (by omega)))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine t4tail_rate_aux (digammaMidx (⟨3, 1⟩ : Q) j) j ?_
  have hN : digammaMidx (⟨3, 1⟩ : Q) j = 4 * (j + 1) := rfl
  omega

/-- **The `t4` improper tail, CONSTRUCTED**: `∫₁^∞ (1/(w+2) − 1/(w+4)) dw` as a
    certified half-line integral (`= ∫₄^∞ 2/(x²−1) dx`). -/
def t4Improper : Real :=
  improperIntegral1 (L := (⟨2, 1⟩ : Q)) (K := (⟨3, 1⟩ : Q)) (by decide) (by decide)
    t4Tail_lip t4Tail_congr (by decide) (by decide) t4tail_decay

/-- **THE `t4` IMPROPER TAIL EVALUATES**: `t4Improper ≈ log 5 − log 3`. -/
theorem t4Improper_eq :
    Req t4Improper (Rsub (logN 5 (by omega)) (logN 3 (by omega))) :=
  Rlim_eval_real
    (genSum_RReg (integralTerm (f := t4Tail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      t4Tail_lip t4Tail_congr) (by decide) (by decide) t4tail_decay)
    (Rsub (logN 5 (by omega)) (logN 3 (by omega))) (fun j => t4tail_rate j)

end Multiplicity.UOR.Bridge.F1Square.Analysis
