/-
F1 square — **the `∫ log` layer, part 1: the antiderivative step bracket and its telescope**
(`LogStep.lean`). The certified evaluation `∫₀¹ log(c+t) dt = (c+1)·log(c+1) − c·log c − 1`
(the engine the `t4` slot integrals run over) rests on one discrete fact, proven here: with

    `Gn(n) = n·log n − n`    (the antiderivative of `log` at integer arguments)

the unit step is bracketed by the endpoint `log` values,

    `Gn(i) + log i  ≤  Gn(i+1)  ≤  Gn(i) + log(i+1)`      (`Gn_step_lower`/`Gn_step_upper`)

— PURE ALGEBRA over the per-step logarithm bracket `1/(i+1) ≤ log(i+1) − log i ≤ 1/i`
(`ExpBounds.lean`): multiply the bracket by `i+1` (resp. `i`) and the rational parts collapse
to `1`. Telescoping along `[A, A+c]` gives the two-sided Riemann bound

    `Gn(A) + Σ_{j<c} log(A+j)  ≤  Gn(A+c)  ≤  Gn(A) + Σ_{j<c} log(A+j+1)`
                                              (`Gn_tele_lower`/`Gn_tele_upper`)

with the gap between the two log-folds bounded by the EXISTING rational harmonic fold:
`Σ log(A+j+1) ≤ Σ log(A+j) + hFold A c` (`logFold_gap`) — so the dyadic Riemann sums of the
`log` integrand (whose sample values ARE `logN` differences at integer arguments) converge to
the `Gn` difference at rate `hFold(c·2^m, 2^m) ≤ 1/c·2^{−m}`. Part 2 wires this into the
gateway (`riemannIntegral_logC`).

HONEST SCOPE. Substrate for the Sonine route's step-2 `W(t4)` campaign; no integral is
evaluated in this file, no positivity claim. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ExpBounds
import Core.F1.Analysis.HarmonicLog

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Rational collapses, general in the integer.
-- ===========================================================================

/-- `i·A + A ≈ (i+1)·A`. -/
private theorem iA_plus_A (i : Nat) (A : Real) :
    Req (Radd (Rmul (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos) A) A)
      (Rmul (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) A) := by
  refine Req_trans (Radd_congr (Req_refl _) (Req_symm (Rone_mul A))) ?_
  refine Req_trans (Req_symm (Rmul_distrib_right
    (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos) one A)) ?_
  refine Rmul_congr ?_ (Req_refl A)
  refine Req_trans (Radd_ofQ_ofQ (a := (⟨(i : Int), 1⟩ : Q)) (b := (⟨1, 1⟩ : Q))
    Nat.one_pos Nat.one_pos) ?_
  refine ofQ_congr (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos ?_
  show Qeq (add ⟨(i : Int), 1⟩ ⟨1, 1⟩) (⟨((i + 1 : Nat) : Int), 1⟩ : Q)
  simp only [Qeq, add]; push_cast; omega

/-- `(−i) + (i+1) ≈ 1`. -/
private theorem negI_plus_I1 (i : Nat) :
    Req (Radd (Rneg (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos))
        (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)) one := by
  refine Req_trans (Radd_congr (Rneg_ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos)
    (Req_refl _)) ?_
  refine Req_trans (Radd_ofQ_ofQ (a := neg (⟨(i : Int), 1⟩ : Q))
    (b := (⟨((i + 1 : Nat) : Int), 1⟩ : Q)) Nat.one_pos Nat.one_pos) ?_
  refine ofQ_congr (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos ?_
  show Qeq (add (neg ⟨(i : Int), 1⟩) ⟨((i + 1 : Nat) : Int), 1⟩) (⟨1, 1⟩ : Q)
  simp only [Qeq, add, neg]; push_cast; omega

/-- `(i+1)·(1/(i+1)) ≈ 1`. -/
private theorem unit_collapse_succ (i : Nat) :
    Req (Rmul (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)
        (ofQ (⟨1, i + 1⟩ : Q) (Nat.succ_pos i))) one := by
  refine Req_trans (Rmul_ofQ_ofQ (a := (⟨((i + 1 : Nat) : Int), 1⟩ : Q))
    (b := (⟨1, i + 1⟩ : Q)) Nat.one_pos (Nat.succ_pos i)) ?_
  refine ofQ_congr (Qmul_den_pos Nat.one_pos (Nat.succ_pos i)) Nat.one_pos ?_
  show Qeq (mul ⟨((i + 1 : Nat) : Int), 1⟩ ⟨1, i + 1⟩) (⟨1, 1⟩ : Q)
  simp only [Qeq, mul]; push_cast; omega

/-- `i·(1/i) ≈ 1` for `i ≥ 1`. -/
private theorem unit_collapse_base (i : Nat) (hi : 1 ≤ i) :
    Req (Rmul (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos) (ofQ (⟨1, i⟩ : Q) hi)) one := by
  refine Req_trans (Rmul_ofQ_ofQ (a := (⟨(i : Int), 1⟩ : Q)) (b := (⟨1, i⟩ : Q))
    Nat.one_pos (show 0 < (⟨1, i⟩ : Q).den from hi)) ?_
  refine ofQ_congr (Qmul_den_pos Nat.one_pos (show 0 < (⟨1, i⟩ : Q).den from hi))
    Nat.one_pos ?_
  show Qeq (mul ⟨(i : Int), 1⟩ ⟨1, i⟩) (⟨1, 1⟩ : Q)
  simp only [Qeq, mul]; push_cast; omega

-- ===========================================================================
-- The antiderivative at integer arguments, and its step bracket.
-- ===========================================================================

/-- **The `log` antiderivative at integer arguments**: `Gn(n) = n·log n − n`. -/
def Gn (n : Nat) (hn : 1 ≤ n) : Real :=
  Rsub (Rmul (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos) (logN n hn))
    (ofQ (⟨(n : Int), 1⟩ : Q) Nat.one_pos)

/-- `Gn(1) ≈ −1` (`log 1 = 0`). -/
theorem Gn_one : Req (Gn 1 (by omega)) (Rneg one) := by
  refine Req_trans (Rsub_congr (Req_trans (Rmul_congr (Req_refl _) logN_one)
    (Rmul_zero _)) (Req_refl _)) ?_
  exact Req_trans (Radd_comm zero (Rneg one)) (Radd_zero (Rneg one))

/-- **The step bracket, lower side**: `Gn(i) + log i ≤ Gn(i+1)` — the left Riemann sample
    under-estimates the unit-cell integral of `log`. From the per-step bracket
    `1/(i+1) + log i ≤ log(i+1)` multiplied by `i+1`. -/
theorem Gn_step_lower (i : Nat) (hi : 1 ≤ i) :
    Rle (Radd (Gn i hi) (logN i hi)) (Gn (i + 1) (by omega)) := by
  refine Radd_le_cancel_right (c := ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) ?_
  -- LHS + (i+1) ≈ 1 + (i+1)·log i
  refine Rle_trans (Rle_of_Req (Req_trans (Radd_assoc _ _ _)
    (Req_trans (Radd_swap (Rmul (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos) (logN i hi))
        (Rneg (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos)) (logN i hi)
        (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos))
      (Req_trans (Radd_congr (iA_plus_A i (logN i hi)) (negI_plus_I1 i))
        (Radd_comm _ one))))) ?_
  -- RHS + (i+1) ≈ (i+1)·log(i+1)
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (Req_trans (Radd_comm _ _)
    (Radd_Rsub_cancel
      (Rmul (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) (logN (i + 1) (by omega)))
      (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)))))
  -- 1 + (i+1)·log i ≤ (i+1)·log(i+1), from the bracket × (i+1)
  refine Rle_trans (Rle_of_Req (Req_symm (Req_trans
    (Rmul_distrib (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)
      (ofQ (⟨1, i + 1⟩ : Q) (Nat.succ_pos i)) (logN i hi))
    (Radd_congr (unit_collapse_succ i) (Req_refl _))))) ?_
  exact Rmul_le_Rmul_left
    (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg (i + 1)))
    (logN_step_lower i hi)

/-- **The step bracket, upper side**: `Gn(i+1) ≤ Gn(i) + log(i+1)` — the right Riemann
    sample over-estimates the unit-cell integral. From `log(i+1) ≤ 1/i + log i`
    multiplied by `i`. -/
theorem Gn_step_upper (i : Nat) (hi : 1 ≤ i) :
    Rle (Gn (i + 1) (by omega)) (Radd (Gn i hi) (logN (i + 1) (by omega))) := by
  refine Radd_le_cancel_right (c := ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) ?_
  -- LHS + (i+1) ≈ (i+1)·log(i+1) ≈ i·log(i+1) + log(i+1)
  refine Rle_trans (Rle_of_Req (Req_trans (Radd_comm _ _)
    (Req_trans (Radd_Rsub_cancel
      (Rmul (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) (logN (i + 1) (by omega)))
      (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos))
      (Req_symm (iA_plus_A i (logN (i + 1) (by omega))))))) ?_
  -- RHS + (i+1) ≈ (i·log i + log(i+1)) + 1
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (Req_trans (Radd_assoc _ _ _)
    (Req_trans (Radd_swap (Rmul (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos) (logN i hi))
        (Rneg (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos)) (logN (i + 1) (by omega))
        (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos))
      (Radd_congr (Req_refl _) (negI_plus_I1 i))))))
  -- i·log(i+1) + log(i+1) ≤ (i·log i + log(i+1)) + 1, from the bracket × i
  refine Rle_trans (Rle_of_Req (Radd_comm _ _)) ?_
  refine Rle_trans (Radd_le_add (Rle_refl (logN (i + 1) (by omega)))
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg i))
      (logN_step_upper i hi))
      (Rle_of_Req (Req_trans
        (Rmul_distrib (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos)
          (ofQ (⟨1, i⟩ : Q) hi) (logN i hi))
        (Radd_congr (unit_collapse_base i hi) (Req_refl _)))))) ?_
  -- log(i+1) + (1 + i·log i) ≈ (i·log i + log(i+1)) + 1
  refine Rle_of_Req ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_comm one _)) ?_
  refine Req_trans (Req_symm (Radd_assoc (logN (i + 1) (by omega))
    (Rmul (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos) (logN i hi)) one)) ?_
  exact Radd_congr (Radd_comm _ _) (Req_refl one)

-- ===========================================================================
-- The telescopes: two-sided Riemann bounds for the Gn difference.
-- ===========================================================================

/-- The left log-fold `Σ_{j<c} log(A+j)` (Real-valued). -/
def logFold (A : Nat) (hA : 1 ≤ A) : Nat → Real
  | 0 => zero
  | (c + 1) => Radd (logFold A hA c) (logN (A + c) (by omega))

/-- The right log-fold `Σ_{j<c} log(A+j+1)`. -/
def logFoldS (A : Nat) (hA : 1 ≤ A) : Nat → Real
  | 0 => zero
  | (c + 1) => Radd (logFoldS A hA c) (logN (A + c + 1) (by omega))

/-- **The telescope, lower side**: `Gn(A) + Σ_{j<c} log(A+j) ≤ Gn(A+c)`. -/
theorem Gn_tele_lower (A : Nat) (hA : 1 ≤ A) : ∀ c : Nat,
    Rle (Radd (Gn A hA) (logFold A hA c)) (Gn (A + c) (by omega)) := by
  intro c
  induction c with
  | zero => exact Rle_of_Req (Radd_zero (Gn A hA))
  | succ k ih =>
    show Rle (Radd (Gn A hA) (Radd (logFold A hA k) (logN (A + k) (by omega))))
      (Gn (A + k + 1) (by omega))
    refine Rle_trans (Rle_of_Req (Req_symm (Radd_assoc (Gn A hA)
      (logFold A hA k) (logN (A + k) (by omega))))) ?_
    refine Rle_trans (Radd_le_add ih (Rle_refl (logN (A + k) (by omega)))) ?_
    exact Gn_step_lower (A + k) (by omega)

/-- **The telescope, upper side**: `Gn(A+c) ≤ Gn(A) + Σ_{j<c} log(A+j+1)`. -/
theorem Gn_tele_upper (A : Nat) (hA : 1 ≤ A) : ∀ c : Nat,
    Rle (Gn (A + c) (by omega)) (Radd (Gn A hA) (logFoldS A hA c)) := by
  intro c
  induction c with
  | zero => exact Rle_of_Req (Req_symm (Radd_zero (Gn A hA)))
  | succ k ih =>
    show Rle (Gn (A + k + 1) (by omega))
      (Radd (Gn A hA) (Radd (logFoldS A hA k) (logN (A + k + 1) (by omega))))
    refine Rle_trans (Gn_step_upper (A + k) (by omega)) ?_
    refine Rle_trans (Radd_le_add ih (Rle_refl (logN (A + k + 1) (by omega)))) ?_
    exact Rle_of_Req (Radd_assoc (Gn A hA) (logFoldS A hA k) (logN (A + k + 1) (by omega)))

/-- **The fold gap is harmonically small**: `Σ log(A+j+1) ≤ Σ log(A+j) + hFold A c` —
    the two Riemann bounds differ by at most the rational harmonic fold (per-step:
    `log(i+1) − log i ≤ 1/i`). -/
theorem logFold_gap (A : Nat) (hA : 1 ≤ A) : ∀ c : Nat,
    Rle (logFoldS A hA c)
      (Radd (logFold A hA c) (ofQ (hFold A c) (hFold_den_pos A hA c))) := by
  intro c
  induction c with
  | zero => exact Rle_of_Req (Req_symm (Radd_zero zero))
  | succ k ih =>
    have hAk : 0 < (⟨1, A + k⟩ : Q).den := (show 0 < A + k by omega)
    show Rle (Radd (logFoldS A hA k) (logN (A + k + 1) (by omega)))
      (Radd (Radd (logFold A hA k) (logN (A + k) (by omega)))
        (ofQ (hFold A (k + 1)) (hFold_den_pos A hA (k + 1))))
    refine Rle_trans (Radd_le_add ih (logN_step_upper (A + k) (by omega))) ?_
    -- (fold + hFold_k) + (1/(A+k) + log(A+k)): commute, then swap the middle pair
    refine Rle_trans (Rle_of_Req (Radd_congr (Req_refl _)
      (Radd_comm (ofQ (⟨1, A + k⟩ : Q) hAk) (logN (A + k) (by omega))))) ?_
    refine Rle_trans (Rle_of_Req (Radd_swap (logFold A hA k)
      (ofQ (hFold A k) (hFold_den_pos A hA k))
      (logN (A + k) (by omega)) (ofQ (⟨1, A + k⟩ : Q) hAk))) ?_
    exact Rle_of_Req (Radd_congr (Req_refl _)
      (Radd_ofQ_ofQ (a := hFold A k) (b := (⟨1, A + k⟩ : Q))
        (hFold_den_pos A hA k) hAk))

end UOR.Bridge.F1Square.Analysis
