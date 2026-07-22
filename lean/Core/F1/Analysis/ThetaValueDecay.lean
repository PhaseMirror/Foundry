/-
F1 square — Track 1, item 3 substrate: the **theta value decay** `ψ(m+1) ≤ 2/((m+1)m)` (for `m ≥ 1`),
the *quadratic* (`1/m²`) decay the Mellin improper integral `∫₁^∞ t^{s−1}ψ(t)dt` needs at its abscissae.

The geometric decay bound `ψ(t) ≤ 2·e^{−πt}` (`thetaFn_decay`) is only *linear* in the ratio engine
(`Rexp_neg_le_ratio` gives `e^{−θ} ≤ 1/(1+τ)`, one power), so it cannot directly produce the quadratic
`K/((m+1)m)` form `genSum_RReg` consumes. The **square trick** supplies the missing power: at `t = m+1`,
`π(m+1) ≥ 2(m+1) = (m+1) + (m+1)`, so

  `e^{−π(m+1)} ≤ e^{−(m+1)−(m+1)} = e^{−(m+1)}·e^{−(m+1)} ≤ (1/(m+1))·(1/(m+1)) = 1/(m+1)² ≤ 1/((m+1)m)`,

each factor `≤ 1/(m+1)` via `Rexp_neg_le_ratio` (`τ = m`), the product via `Rmul_le_Rmul_both`, the
exponent split via `RexpReal_add`. Then `ψ(m+1) ≤ 2·e^{−π(m+1)} ≤ 2/((m+1)m)`. The denominator
comparison `(m+1)m ≤ (m+1)(m+1)` factors out `m+1` (`Nat.mul_le_mul`), staying linear — no nonlinear
`omega`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ThetaDecay

set_option maxHeartbeats 1000000

namespace UOR.Bridge.F1Square.Analysis

/-- The real integer `m+1` (the left endpoint of the `m`-th Mellin unit interval). -/
def RnatSucc (m : Nat) : Real := ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos

/-- `m+1 ≥ 1`. -/
theorem one_le_RnatSucc (m : Nat) : Rle one (RnatSucc m) :=
  Rle_ofQ_ofQ Nat.one_pos Nat.one_pos (by simp only [Qle]; push_cast; omega)

/-- `m+1 ≥ 0`. -/
theorem Rnonneg_RnatSucc (m : Nat) : Rnonneg (RnatSucc m) :=
  Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ (m : Int) + 1; omega)

/-- **Both-sides product monotonicity**: `0 ≤ a`, `0 ≤ d`, `a ≤ b`, `c ≤ d ⟹ a·c ≤ b·d`. -/
theorem Rmul_le_Rmul_both {a b c d : Real} (ha : Rnonneg a) (hd : Rnonneg d)
    (hab : Rle a b) (hcd : Rle c d) : Rle (Rmul a c) (Rmul b d) :=
  Rle_trans (Rmul_le_Rmul_left ha hcd) (Rmul_le_Rmul_right hd hab)

/-- **The `0`-th theta term value bound** `e^{−π(m+1)} ≤ 1/((m+1)m)` (for `m ≥ 1`), via the square
    trick. This is the quadratic decay needed for the Mellin convergence. -/
theorem thetaTerm0_value_le (m : Nat) (hm : 1 ≤ m) :
    Rle (thetaTerm (RnatSucc m) 0) (ofQ (⟨1, (m + 1) * m⟩ : Q) (Nat.mul_pos (Nat.succ_pos m) hm)) := by
  -- (a) `e^{−(m+1)} ≤ 1/(m+1)` (ratio engine, `τ = m`)
  have he1 : Rle (RexpReal (Rneg (RnatSucc m))) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) := by
    refine Rle_trans (Rexp_neg_le_ratio (θ := RnatSucc m) (τ := (⟨(m : Int), 1⟩ : Q))
        (by show (0 : Int) < (m : Int); omega) Nat.one_pos
        (Rle_ofQ_ofQ Nat.one_pos Nat.one_pos (by simp only [Qle]; push_cast; omega))) ?_
    refine Rle_ofQ_ofQ (Qinv_den_pos (by
        show (0 : Int) < (add (⟨1, 1⟩ : Q) (⟨(m : Int), 1⟩ : Q)).num
        simp only [add]; push_cast; omega)) (Nat.succ_pos m) ?_
    simp only [Qle, Qinv, add]; push_cast; omega
  -- (b) `(e^{−(m+1)})² ≤ 1/(m+1)²`
  have hprod : Rle (Rmul (RexpReal (Rneg (RnatSucc m))) (RexpReal (Rneg (RnatSucc m))))
      (Rmul (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m))) :=
    Rmul_le_Rmul_both (RexpReal_nonneg _) (Rnonneg_ofQ (Nat.succ_pos m) (by show (0 : Int) ≤ 1; decide)) he1 he1
  -- (c) `e^{−(Radd t t)} ≈ (e^{−(m+1)})²`
  have hLHS : Req (RexpReal (Rneg (Radd (RnatSucc m) (RnatSucc m))))
      (Rmul (RexpReal (Rneg (RnatSucc m))) (RexpReal (Rneg (RnatSucc m)))) :=
    Req_trans (RexpReal_congr (Rneg_Radd (RnatSucc m) (RnatSucc m)))
      (RexpReal_add (Rneg (RnatSucc m)) (Rneg (RnatSucc m)))
  -- (d) `Radd t t = 2t ≤ thetaArg t 0 = π·t`
  have hpit : Req (thetaArg (RnatSucc m) 0) (Rmul Rpi (RnatSucc m)) := by
    show Req (Rmul (RofNat 1) (Rmul Rpi (RnatSucc m))) (Rmul Rpi (RnatSucc m))
    exact Req_trans (Rmul_comm (RofNat 1) (Rmul Rpi (RnatSucc m))) (Rmul_one (Rmul Rpi (RnatSucc m)))
  have heq2t : Req (Radd (RnatSucc m) (RnatSucc m))
      (Rmul (ofQ (⟨2, 1⟩ : Q) Nat.one_pos) (RnatSucc m)) := by
    unfold RnatSucc
    refine Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
      (Req_trans (ofQ_congr (add_den_pos Nat.one_pos Nat.one_pos)
          (Qmul_den_pos Nat.one_pos Nat.one_pos) ?_)
        (Req_symm (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos)))
    simp only [Qeq, add, mul]; push_cast; ring_uor
  have h2pi : Rle (ofQ (⟨2, 1⟩ : Q) Nat.one_pos) Rpi :=
    Rle_trans (Rle_ofQ_ofQ Nat.one_pos Nat.one_pos (by decide)) Rpi_lower_three
  have hle_arg : Rle (Radd (RnatSucc m) (RnatSucc m)) (thetaArg (RnatSucc m) 0) :=
    Rle_trans (Rle_of_Req heq2t)
      (Rle_trans (Rmul_le_Rmul_right (Rnonneg_RnatSucc m) h2pi) (Rle_of_Req (Req_symm hpit)))
  -- (e) `e^{−π(m+1)} ≤ e^{−(Radd t t)}`
  have hstep : Rle (thetaTerm (RnatSucc m) 0)
      (RexpReal (Rneg (Radd (RnatSucc m) (RnatSucc m)))) :=
    RexpReal_le_of_le (Rle_Rneg hle_arg)
  -- assemble: `e^{−π(m+1)} ≤ (e^{−(m+1)})² ≤ 1/(m+1)² ≤ 1/((m+1)m)`
  refine Rle_trans hstep (Rle_trans (Rle_of_Req hLHS) (Rle_trans hprod ?_))
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (Nat.succ_pos m) (Nat.succ_pos m))) ?_
  refine Rle_ofQ_ofQ (Qmul_den_pos (Nat.succ_pos m) (Nat.succ_pos m))
    (Nat.mul_pos (Nat.succ_pos m) hm) ?_
  have hnat : (m + 1) * m ≤ (m + 1) * (m + 1) := Nat.mul_le_mul (Nat.le_refl _) (by omega)
  have hI : (((m + 1) * m : Nat) : Int) ≤ (((m + 1) * (m + 1) : Nat) : Int) := by exact_mod_cast hnat
  simp only [Qle, mul]; omega

/-- **The theta value decay** `ψ(m+1) ≤ 2/((m+1)m)` (for `m ≥ 1`): `ψ(m+1) ≤ 2·e^{−π(m+1)}`
    (`thetaFn_decay`) times the square-trick term bound `e^{−π(m+1)} ≤ 1/((m+1)m)`
    (`thetaTerm0_value_le`). This is the per-interval majorant for the Mellin integral's decay. -/
theorem thetaFn_value_decay (m : Nat) (hm : 1 ≤ m) (hr : Rle one (RnatSucc m)) :
    Rle (thetaFn (RnatSucc m) hr) (ofQ (⟨2, (m + 1) * m⟩ : Q) (Nat.mul_pos (Nat.succ_pos m) hm)) := by
  refine Rle_trans (thetaFn_decay (RnatSucc m) hr) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos (by decide))
    (thetaTerm0_value_le m hm)) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos (Nat.mul_pos (Nat.succ_pos m) hm))
    (ofQ_congr (Qmul_den_pos Nat.one_pos (Nat.mul_pos (Nat.succ_pos m) hm))
      (Nat.mul_pos (Nat.succ_pos m) hm) ?_))
  simp only [Qeq, mul]; push_cast; ring_uor

end UOR.Bridge.F1Square.Analysis
