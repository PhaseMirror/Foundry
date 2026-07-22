/-
F1 square — **elementary exponential bounds and the per-step logarithm bracket**
(`ExpBounds.lean`): the two series bounds

    `1 + q  ≤  exp q`          (`q ≥ 0`)
    `exp(1/(e+1))  ≤  (e+1)/e` (`e ≥ 1` — the geometric-domination bound, EXACT for the step)

and their consequence, the **per-step logarithm bracket**

    `1/(i+1)  ≤  log(i+1) − log i  ≤  1/i`     (`i ≥ 1`, stated in `Radd` form)

— the derivative of `log` at the integers, certified. This is the analytic brick behind the
harmonic-sum ⟷ `log` bridge: telescoping the bracket from `M` to `2M` squeezes `log 2` between
the left and right Riemann sums `Σ 1/(M+j)` of `∫ dx/x`, which is what identifies the certified
Riemann integral of `1/(1+t)` with `log 2` (the tent test's `f̃(0)` Weil-slot component).

Route (no new analysis, only the repo's own `exp` characterization of `log`): both directions
apply `RexpReal_reflects_le` and land on rational-vs-`exp` comparisons at rational arguments,
where the series partial sums decide them — `expSum q N ≥ 1 + q` (first two terms, tail
non-negative) and `expSum (1/(e+1)) N ≤ (e+1)/e` (termwise `q^i/i! ≤ q^i`, geometric sum with
the closed strengthened-induction bound). `exp(log n) = n` (`Rexp_logN`) and
`exp(a+b) = exp a · exp b` (`RexpReal_add`) do the rest.

HONEST SCOPE. Substrate for the crux route's steps 1–2; no positivity, no crux claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The series depth is always ≥ 1 (so `expSum` carries the linear term).
-- ===========================================================================

/-- The diagonal depth `RexpReal_R x j` is at least `1`. -/
theorem RexpReal_R_ge_one (x : Real) (j : Nat) : 1 ≤ RexpReal_R x j := by
  have hK : 1 ≤ RexpReal_K x := by unfold RexpReal_K; omega
  have h1 : 0 < 4 * (j + 1) * RexpReal_K x :=
    Nat.mul_pos (Nat.mul_pos (by omega) (Nat.succ_pos j)) hK
  unfold RexpReal_R; omega

-- ===========================================================================
-- Lower bound: `1 + q ≤ exp q` for `q ≥ 0`.
-- ===========================================================================

/-- **`1 + q ≤ exp q`** at the Real level, for a non-negative rational argument (the depth is
    always `≥ 1`, so the existing partial-sum bound `expSum_ge_one_add` applies). -/
theorem RexpReal_ofQ_ge_one_add {q : Q} (hq0 : 0 ≤ q.num) (hqd : 0 < q.den) :
    Rle (ofQ (add ⟨1, 1⟩ q) (add_den_pos Nat.one_pos hqd)) (RexpReal (ofQ q hqd)) := by
  intro n
  show Qle (add ⟨1, 1⟩ q)
    (add (expSum q (RexpReal_R (ofQ q hqd) n)) (⟨2, n + 1⟩ : Q))
  have hR : RexpReal_R (ofQ q hqd) n = (RexpReal_R (ofQ q hqd) n - 1) + 1 := by
    have := RexpReal_R_ge_one (ofQ q hqd) n; omega
  rw [hR]
  refine Qle_trans (expSum_den_pos hqd _)
    (expSum_ge_one_add hq0 hqd (RexpReal_R (ofQ q hqd) n - 1)) ?_
  exact Qle_self_add (p := (⟨2, n + 1⟩ : Q)) (show (0 : Int) ≤ 2 by decide)

-- ===========================================================================
-- Upper bound: `exp(1/(e+1)) ≤ (e+1)/e` — geometric domination, closed form.
-- ===========================================================================

/-- Powers of a unit fraction are literal: `(1/d)ⁱ = 1/dⁱ`. -/
theorem qpow_unit (d : Nat) : ∀ i, qpow (⟨1, d⟩ : Q) i = ⟨1, npow d i⟩
  | 0 => rfl
  | (i + 1) => by rw [qpow_succ, qpow_unit d i]; rfl

/-- Termwise geometric domination for unit fractions: `(1/d)ⁱ/i! ≤ (1/d)ⁱ`. -/
theorem expTerm_unit_le (d : Nat) (i : Nat) :
    Qle (expTerm (⟨1, d⟩ : Q) i) (qpow (⟨1, d⟩ : Q) i) := by
  rw [show expTerm (⟨1, d⟩ : Q) i = mul (qpow (⟨1, d⟩ : Q) i) ⟨1, fct i⟩ from rfl,
    qpow_unit d i]
  show Qle (⟨1 * 1, npow d i * fct i⟩ : Q) ⟨1, npow d i⟩
  show (1 * 1 : Int) * ((npow d i : Nat) : Int)
      ≤ (1 : Int) * (((npow d i * fct i : Nat)) : Int)
  have h : npow d i ≤ npow d i * fct i := Nat.le_mul_of_pos_right _ (fct_pos i)
  push_cast; omega

/-- **The strengthened geometric bound**: `expSum (1/(e+1)) N ≤ (e+1)/e − 1/((e+1)ᴺ·e)` —
    the exact partial-geometric closed form dominates the exp partial sums. -/
theorem expSum_unit_le_geom (e : Nat) (he : 1 ≤ e) (N : Nat) :
    Qle (expSum (⟨1, e + 1⟩ : Q) N)
      (Qsub ⟨(e : Int) + 1, e⟩ ⟨1, npow (e + 1) N * e⟩) := by
  induction N with
  | zero =>
      refine Qeq_le (show Qeq (⟨1, 1⟩ : Q) (Qsub ⟨(e : Int) + 1, e⟩ ⟨1, 1 * e⟩) from ?_)
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  | succ N ih =>
      have hstep : Qle (expSum (⟨1, e + 1⟩ : Q) (N + 1))
          (add (Qsub ⟨(e : Int) + 1, e⟩ ⟨1, npow (e + 1) N * e⟩)
            (qpow (⟨1, e + 1⟩ : Q) (N + 1))) := by
        show Qle (add (expSum (⟨1, e + 1⟩ : Q) N) (expTerm (⟨1, e + 1⟩ : Q) (N + 1))) _
        exact Qadd_le_add ih (expTerm_unit_le (e + 1) (N + 1))
      refine Qle_congr_right
        (add_den_pos
          (Qsub_den_pos (show 0 < (⟨(e : Int) + 1, e⟩ : Q).den from he)
            (Nat.mul_pos (npow_pos (Nat.succ_pos e) N) (show 0 < e from he)))
          (qpow_den_pos (Nat.succ_pos e) (N + 1))) ?_ hstep
      rw [qpow_unit (e + 1) (N + 1)]
      show Qeq (add (Qsub ⟨(e : Int) + 1, e⟩ ⟨1, npow (e + 1) N * e⟩) ⟨1, npow (e + 1) (N + 1)⟩)
        (Qsub ⟨(e : Int) + 1, e⟩ ⟨1, npow (e + 1) (N + 1) * e⟩)
      rw [npow_succ]
      generalize npow (e + 1) N = P
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- Dropping the non-positive correction: `expSum (1/(e+1)) N ≤ (e+1)/e`. -/
theorem expSum_unit_le (e : Nat) (he : 1 ≤ e) (N : Nat) :
    Qle (expSum (⟨1, e + 1⟩ : Q) N) ⟨(e : Int) + 1, e⟩ := by
  refine Qle_trans
    (Qsub_den_pos (show 0 < (⟨(e : Int) + 1, e⟩ : Q).den from he)
      (Nat.mul_pos (npow_pos (Nat.succ_pos e) N) (show 0 < e from he)))
    (expSum_unit_le_geom e he N) ?_
  show Qle (Qsub ⟨(e : Int) + 1, e⟩ ⟨1, npow (e + 1) N * e⟩) ⟨(e : Int) + 1, e⟩
  generalize hM : npow (e + 1) N * e = M
  have hM1 : 1 ≤ M := by rw [← hM]; exact Nat.mul_pos (npow_pos (Nat.succ_pos e) N) he
  show (Qsub ⟨(e : Int) + 1, e⟩ ⟨1, M⟩).num * ((e : Nat) : Int)
      ≤ ((e : Int) + 1) * (((Qsub ⟨(e : Int) + 1, e⟩ ⟨1, M⟩).den : Nat) : Int)
  show (((e : Int) + 1) * (M : Int) + (-1) * (e : Int)) * ((e : Nat) : Int)
      ≤ ((e : Int) + 1) * (((e * M : Nat)) : Int)
  have hexp : (((e : Int) + 1) * (M : Int) + (-1) * (e : Int)) * ((e : Nat) : Int)
      = ((e : Int) + 1) * ((M : Int) * (e : Int)) - (e : Int) * (e : Int) := by ring_uor
  have hsq : (0 : Int) ≤ (e : Int) * (e : Int) :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)
  have hcast : ((e * M : Nat) : Int) = (M : Int) * (e : Int) := by push_cast; ring_uor
  rw [hcast, hexp]
  omega

/-- **`exp(1/(e+1)) ≤ (e+1)/e`** at the Real level — the exact per-step upper bound. -/
theorem RexpReal_unit_le (e : Nat) (he : 1 ≤ e) :
    Rle (RexpReal (ofQ (⟨1, e + 1⟩ : Q) (Nat.succ_pos e))) (ofQ (⟨(e : Int) + 1, e⟩ : Q) he) := by
  intro n
  show Qle (expSum (⟨1, e + 1⟩ : Q) (RexpReal_R (ofQ (⟨1, e + 1⟩ : Q) (Nat.succ_pos e)) n))
    (add ⟨(e : Int) + 1, e⟩ (⟨2, n + 1⟩ : Q))
  exact Qle_trans (show 0 < (⟨(e : Int) + 1, e⟩ : Q).den from he) (expSum_unit_le e he _)
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

-- ===========================================================================
-- THE PER-STEP LOGARITHM BRACKET: `1/(i+1) ≤ log(i+1) − log i ≤ 1/i`.
-- (Stated in `Radd` form — no subtraction needed anywhere downstream.)
-- ===========================================================================

/-- **The per-step upper bound**: `log(i+1) ≤ 1/i + log i` — via `exp` reflection and
    `exp(1/i) ≥ 1 + 1/i`. -/
theorem logN_step_upper (i : Nat) (hi : 1 ≤ i) :
    Rle (logN (i + 1) (by omega))
      (Radd (ofQ (⟨1, i⟩ : Q) hi) (logN i hi)) := by
  have hdi : 0 < (⟨1, i⟩ : Q).den := hi
  have hnn1 : Rnonneg (ofQ (⟨1, i⟩ : Q) hi) :=
    Rnonneg_ofQ (c := (⟨1, i⟩ : Q)) hi (show (0 : Int) ≤ 1 by decide)
  have hnni : Rnonneg (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos) :=
    Rnonneg_ofQ (c := (⟨(i : Int), 1⟩ : Q)) Nat.one_pos (Int.ofNat_nonneg i)
  have hsplit : Req (ofQ (mul (add ⟨1, 1⟩ ⟨1, i⟩) ⟨(i : Int), 1⟩)
      (Qmul_den_pos (add_den_pos Nat.one_pos hdi) Nat.one_pos))
      (Rmul (ofQ (add ⟨1, 1⟩ ⟨1, i⟩) (add_den_pos Nat.one_pos hdi))
        (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos)) :=
    Req_symm (Rmul_ofQ_ofQ (a := add ⟨1, 1⟩ ⟨1, i⟩) (b := (⟨(i : Int), 1⟩ : Q))
      (add_den_pos Nat.one_pos hdi) Nat.one_pos)
  have hval : Req (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)
      (ofQ (mul (add ⟨1, 1⟩ ⟨1, i⟩) ⟨(i : Int), 1⟩)
        (Qmul_den_pos (add_den_pos Nat.one_pos hdi) Nat.one_pos)) :=
    ofQ_congr Nat.one_pos (Qmul_den_pos (add_den_pos Nat.one_pos hdi) Nat.one_pos)
      (show Qeq (⟨((i + 1 : Nat) : Int), 1⟩ : Q) (mul (add ⟨1, 1⟩ ⟨1, i⟩) ⟨(i : Int), 1⟩) by
        simp only [Qeq, mul, add]; push_cast; ring_uor)
  refine RexpReal_reflects_le (Rnonneg_Radd hnn1 (Rnonneg_logN i hi)) ?_
  refine Rle_trans (Rle_of_Req (Rexp_logN (i + 1) (by omega))) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (Req_trans
    (RexpReal_add (ofQ (⟨1, i⟩ : Q) hi) (logN i hi))
    (Rmul_congr (Req_refl _) (Rexp_logN i hi)))))
  -- goal: ofQ (i+1) ≤ exp(1/i) · ofQ i
  refine Rle_trans (Rle_of_Req (Req_trans hval hsplit)) ?_
  exact Rmul_le_Rmul_right hnni
    (RexpReal_ofQ_ge_one_add (q := (⟨1, i⟩ : Q)) (show (0 : Int) ≤ 1 by decide) hi)

/-- **The per-step lower bound**: `1/(i+1) + log i ≤ log(i+1)` — via `exp` reflection and
    the exact geometric cap `exp(1/(i+1)) ≤ (i+1)/i`. -/
theorem logN_step_lower (i : Nat) (hi : 1 ≤ i) :
    Rle (Radd (ofQ (⟨1, i + 1⟩ : Q) (Nat.succ_pos i)) (logN i hi))
      (logN (i + 1) (by omega)) := by
  have hd1 : 0 < (⟨(i : Int) + 1, i⟩ : Q).den := hi
  have hnni : Rnonneg (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos) :=
    Rnonneg_ofQ (c := (⟨(i : Int), 1⟩ : Q)) Nat.one_pos (Int.ofNat_nonneg i)
  have hjoin : Req (Rmul (ofQ (⟨(i : Int) + 1, i⟩ : Q) hi) (ofQ (⟨(i : Int), 1⟩ : Q) Nat.one_pos))
      (ofQ (mul ⟨(i : Int) + 1, i⟩ ⟨(i : Int), 1⟩) (Qmul_den_pos hd1 Nat.one_pos)) :=
    Rmul_ofQ_ofQ (a := (⟨(i : Int) + 1, i⟩ : Q)) (b := (⟨(i : Int), 1⟩ : Q)) hi Nat.one_pos
  have hval : Req (ofQ (mul ⟨(i : Int) + 1, i⟩ ⟨(i : Int), 1⟩) (Qmul_den_pos hd1 Nat.one_pos))
      (ofQ (⟨((i + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) :=
    ofQ_congr (Qmul_den_pos hd1 Nat.one_pos) Nat.one_pos
      (show Qeq (mul ⟨(i : Int) + 1, i⟩ ⟨(i : Int), 1⟩) (⟨((i + 1 : Nat) : Int), 1⟩ : Q) by
        simp only [Qeq, mul]; push_cast; ring_uor)
  refine RexpReal_reflects_le (Rnonneg_logN (i + 1) (by omega)) ?_
  refine Rle_trans (Rle_of_Req (Req_trans
    (RexpReal_add (ofQ (⟨1, i + 1⟩ : Q) (Nat.succ_pos i)) (logN i hi))
    (Rmul_congr (Req_refl _) (Rexp_logN i hi)))) ?_
  refine Rle_trans (Rmul_le_Rmul_right hnni (RexpReal_unit_le i hi)) ?_
  refine Rle_trans (Rle_of_Req (Req_trans hjoin hval)) ?_
  exact Rle_of_Req (Req_symm (Rexp_logN (i + 1) (by omega)))

end UOR.Bridge.F1Square.Analysis
