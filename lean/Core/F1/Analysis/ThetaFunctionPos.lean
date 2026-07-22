/-
F1 square — Track 1, item 3: the **Jacobi theta function on all of `t > 0`** (`thetaFnPos`), the
generalization of `thetaFn` (which required `t ≥ 1`) needed to state the modular transformation
`θ(1/t) = √t·θ(t)` — where `1/t ≤ 1` falls outside the original domain.

For a positive `t` with a unit-fraction lower bound `t ≥ 1/D` (`D ≥ 1`; every positive real has one),
the same geometric convergence works: `π·t ≥ 3·t ≥ 3/D`, so the `m`-th exponent is
`(m+1)²·π·t ≥ (m+1)²·3/D`, and `e^{−E} ≤ 1/(1+E)` (`Rexp_neg_le_ratio`) gives a *rational*
`(D/3)/((m+1)m)` bound (`K = D/3`, independent of `m`) that feeds `genSum_RReg`. The only difference
from `t ≥ 1` is the `D`-dependent constant `K`; `π` stays opaque via `π ≥ 3` (`Rpi_lower_three`).

The modular transformation itself (Poisson summation) remains the labelled classical seam.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ThetaFunction

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 1000000 in
/-- `π·t ≥ 3/D` for `t ≥ 1/D` (`π ≥ 3`, `t ≥ 1/D ≥ 0`). -/
theorem pi_mul_ge_threeOverD (t : Real) (D : Nat) (hD : 0 < D)
    (ht : Rle (ofQ (⟨1, D⟩ : Q) hD) t) : Rle (ofQ (⟨3, D⟩ : Q) hD) (Rmul Rpi t) := by
  have ht0 : Rnonneg t :=
    Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg
      (Rnonneg_ofQ hD (by show (0 : Int) ≤ 1; decide))) ht)
  have h1 : Rle (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) t) (Rmul Rpi t) :=
    Rmul_le_Rmul_right ht0 Rpi_lower_three
  have h2 : Rle (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (ofQ (⟨1, D⟩ : Q) hD))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) t) :=
    Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) ht
  have h3 : Req (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (ofQ (⟨1, D⟩ : Q) hD)) (ofQ (⟨3, D⟩ : Q) hD) :=
    Req_trans (Rmul_ofQ_ofQ (by decide) hD)
      (ofQ_congr (Qmul_den_pos (by decide) hD) hD (by simp only [Qeq, mul]; push_cast; ring_uor))
  exact Rle_trans (Rle_of_Req (Req_symm h3)) (Rle_trans h2 h1)

set_option maxHeartbeats 1000000 in
/-- The exponent lower bound `(m+1)²·π·t ≥ (m+1)²·3/D` for `t ≥ 1/D`. -/
theorem thetaArg_lower_pos (t : Real) (D : Nat) (hD : 0 < D)
    (ht : Rle (ofQ (⟨1, D⟩ : Q) hD) t) (m : Nat) :
    Rle (ofQ (⟨((m + 1) * (m + 1) * 3 : Nat), D⟩ : Q) hD) (thetaArg t m) := by
  have hθ : Req (thetaArg t m) (Rmul (RofNat ((m + 1) * (m + 1))) (Rmul Rpi t)) := Req_refl _
  have hnn : Rnonneg (RofNat ((m + 1) * (m + 1))) :=
    Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg ((m + 1) * (m + 1)))
  have hstep : Rle (Rmul (RofNat ((m + 1) * (m + 1))) (ofQ (⟨3, D⟩ : Q) hD))
      (Rmul (RofNat ((m + 1) * (m + 1))) (Rmul Rpi t)) :=
    Rmul_le_Rmul_left hnn (pi_mul_ge_threeOverD t D hD ht)
  have heqL : Req (ofQ (⟨((m + 1) * (m + 1) * 3 : Nat), D⟩ : Q) hD)
      (Rmul (RofNat ((m + 1) * (m + 1))) (ofQ (⟨3, D⟩ : Q) hD)) :=
    Req_trans
      (ofQ_congr hD (Qmul_den_pos Nat.one_pos hD)
        (by simp only [Qeq, mul]; push_cast; ring_uor))
      (Req_symm (Rmul_ofQ_ofQ Nat.one_pos hD))
  exact Rle_trans (Rle_of_Req heqL) (Rle_trans hstep (Rle_of_Req (Req_symm hθ)))

set_option maxHeartbeats 1000000 in
/-- **The rational term bound** `e^{−(m+1)²πt} ≤ (D/3)/((m+1)m)` for `t ≥ 1/D`, `m ≥ 1` — the
    `genSum_RReg` input (`K = D/3`, independent of `m`). -/
theorem thetaTerm_le_pos (t : Real) (D : Nat) (hD : 0 < D)
    (ht : Rle (ofQ (⟨1, D⟩ : Q) hD) t) (m : Nat) (hm : 1 ≤ m) :
    Rle (thetaTerm t m)
      (ofQ (mul (⟨(D : Int), 3⟩ : Q) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (by show 0 < 3; decide) (digamma_succ_mul_pos hm))) := by
  have hPpos : 0 < (m + 1) * (m + 1) * 3 :=
    Nat.mul_pos (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)) (by decide)
  have hPi : (0 : Int) < (((m + 1) * (m + 1) * 3 : Nat) : Int) := by exact_mod_cast hPpos
  have hD0 : (0 : Int) ≤ (D : Int) := Int.ofNat_nonneg D
  have hτn : 0 < (⟨((m + 1) * (m + 1) * 3 : Nat), D⟩ : Q).num := by
    show (0 : Int) < ((m + 1) * (m + 1) * 3 : Nat); exact hPi
  have hden : (0 : Int) < 1 * (D : Int) + (((m + 1) * (m + 1) * 3 : Nat) : Int) * ((1 : Nat) : Int) := by
    omega
  refine Rle_trans (Rexp_neg_le_ratio hτn hD (thetaArg_lower_pos t D hD ht m)) ?_
  refine Rle_ofQ_ofQ (Qinv_den_pos hden)
    (Qmul_den_pos (by show 0 < 3; decide) (digamma_succ_mul_pos hm)) ?_
  have hmul : (m + 1) * m ≤ (m + 1) * (m + 1) := Nat.mul_le_mul_left _ (Nat.le_succ m)
  have hcore : (((m + 1) * m : Nat) : Int) * 3 ≤ (D : Int) + (((m + 1) * (m + 1) * 3 : Nat) : Int) := by
    have h1 : (((m + 1) * m : Nat) : Int) ≤ (((m + 1) * (m + 1) : Nat) : Int) := by exact_mod_cast hmul
    have h2 : (((m + 1) * (m + 1) * 3 : Nat) : Int) = (((m + 1) * (m + 1) : Nat) : Int) * 3 := by
      push_cast; ring_uor
    omega
  have key : (D : Int) * ((((m + 1) * m : Nat) : Int) * 3)
      ≤ (D : Int) * ((D : Int) + (((m + 1) * (m + 1) * 3 : Nat) : Int)) :=
    Int.mul_le_mul_of_nonneg_left hcore hD0
  simp only [Qle, Qinv, add, mul]
  rw [Int.toNat_of_nonneg (Int.le_of_lt hden)]
  have hgoaleq : (((1 * D : Nat)) : Int) * (((3 * ((m + 1) * m) : Nat)) : Int)
      = (D : Int) * ((((m + 1) * m : Nat) : Int) * 3) := by push_cast; ring_uor
  have hgoalrq : ((D : Int) * 1) * (1 * (D : Int) + (((m + 1) * (m + 1) * 3 : Nat) : Int) * ((1 : Nat) : Int))
      = (D : Int) * ((D : Int) + (((m + 1) * (m + 1) * 3 : Nat) : Int)) := by push_cast; ring_uor
  rw [hgoaleq, hgoalrq]; exact key

/-- **The theta terms are regular** for `t ≥ 1/D` (`genSum_RReg` with `thetaTerm_le_pos`, `K = D/3`). -/
theorem thetaTerm_RReg_pos (t : Real) (D : Nat) (hD : 0 < D)
    (ht : Rle (ofQ (⟨1, D⟩ : Q) hD) t) :
    RReg (fun j => genSum (thetaTerm t) (digammaMidx (⟨(D : Int), 3⟩ : Q) j)) :=
  genSum_RReg (thetaTerm t) (by show 0 < 3; decide)
    (by show (0 : Int) ≤ (D : Int); exact Int.ofNat_nonneg D) (fun m hm =>
    ⟨Rle_trans
        (Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg
          (Rnonneg_ofQ (Qmul_den_pos (by show 0 < 3; decide) (digamma_succ_mul_pos hm))
            (by show (0 : Int) ≤ (D : Int) * 1; have : 0 ≤ (D : Int) := Int.ofNat_nonneg D; omega))))
          (Rle_of_Req Rneg_zero))
        (Rle_zero_of_Rnonneg (RexpReal_nonneg _)),
      thetaTerm_le_pos t D hD ht m hm⟩)

/-- **The Jacobi theta function on `t > 0`** (`t ≥ 1/D`): `ψ(t) = Σ_{n≥1} e^{−πn²t}`, the limit of the
    regular reindexed partial sums. -/
def thetaFnPos (t : Real) (D : Nat) (hD : 0 < D) (ht : Rle (ofQ (⟨1, D⟩ : Q) hD) t) : Real :=
  Rlim (fun j => genSum (thetaTerm t) (digammaMidx (⟨(D : Int), 3⟩ : Q) j))
    (thetaTerm_RReg_pos t D hD ht)

/-- **`ψ(t) ≥ 0`** on `t > 0`. -/
theorem thetaFnPos_nonneg (t : Real) (D : Nat) (hD : 0 < D) (ht : Rle (ofQ (⟨1, D⟩ : Q) hD) t) :
    Rnonneg (thetaFnPos t D hD ht) :=
  Rnonneg_Rlim_theta (thetaTerm_RReg_pos t D hD ht)
    (fun j => genSum_nonneg (fun _ => RexpReal_nonneg _) (digammaMidx (⟨(D : Int), 3⟩ : Q) j))

end UOR.Bridge.F1Square.Analysis
