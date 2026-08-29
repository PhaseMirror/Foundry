/-
F1 square — **shrinking-dilation ("fine") window decay** (`DilateTestFineDecay.lean`): the
counterpart of `DilateTestRDecay` for a `< 1` scale. Dilating by `1/D` (`D ≥ 1`) *shrinks* the
argument (`(1/D)·y` is closer to `0`), so `φ`'s clean k-indexed half-line decay can no longer transfer
with the SAME constant — the shrink pulls the window point `[(m+1)/D, (m+2)/D]` back below the decay
threshold for the small-index band. This file shows it still transfers, at a *per-`D`* constant
`C' = (Cf + φ.M)·(2D)^{n+2}`, via a two-regime split:

  • **coarse band** `m+1 ≥ D` — the argument `(1/D)·((m+1)+x) ≥ (m+1)/D ≥ 1` is still on the half line,
    so `φ`'s decay fires at index `k = (m+1)/D − 1`; the index deflation `k+1 = (m+1)/D` costs the
    `(2D)^{n+2}` factor (`m+1 ≤ 2D·(k+1)`, a `Nat`-division fact).
  • **fine band** `m+1 < D` — the argument is `< 1`, off the decay's reach; here only the uniform
    bound `φ.M` survives, and `φ.M ≤ C'/(m+1)^{n+2}` because `(m+1)^{n+2} ≤ (2D)^{n+2}`.

HONEST SCOPE. The decay-hypothesis transport for the fixed rational fine scale `1/D` only. It builds NO
tail assembly, NO covariance application, NO `∫_t` reconstruction, NO factorization `M[f⋆g]=M[f]·M[g]`,
NO positivity, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MultShift
import Foundations.F1.Square.MellinHat
import Foundations.F1.Analysis.RingTac
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Integer cross-multiplication core for the **fine band** (`m+1 < D`): the uniform bound `φ.M`
    (`= a/(dC·dM)` after clearing) is dominated by `C'/(m+1)^{n+2}` once `(m+1)^{n+2} ≤ (2D)^{n+2}`
    (`P ≤ Q`), since `C' ≥ φ.M·(2D)^{n+2}`. -/
private theorem fine_qle_core (a b dC dM P Q : Int)
    (ha : 0 ≤ a) (hb : 0 ≤ b) (hdC : 0 ≤ dC) (hdM : 0 ≤ dM)
    (hQ : 0 ≤ Q) (hPQ : P ≤ Q) :
    a * (dC * dM * 1 * P) ≤ (b * dM + a * dC) * Q * 1 * dM := by
  have hc : 0 ≤ a * dC * dM := Int.mul_nonneg (Int.mul_nonneg ha hdC) hdM
  have key : a * dC * dM * P ≤ a * dC * dM * Q := Int.mul_le_mul_of_nonneg_left hPQ hc
  have hnn : 0 ≤ b * dM * Q * dM := Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg hb hdM) hQ) hdM
  have hL : a * (dC * dM * 1 * P) = a * dC * dM * P := by ring_uor
  have hR : (b * dM + a * dC) * Q * 1 * dM = a * dC * dM * Q + b * dM * Q * dM := by ring_uor
  omega

/-- Integer cross-multiplication core for the **coarse band** (`m+1 ≥ D`): `φ`'s index-`k` decay
    `Cf/(k+1)^{n+2}` is dominated by `C'/(m+1)^{n+2}` once `(m+1)^{n+2} ≤ (2D)^{n+2}·(k+1)^{n+2}`
    (`P ≤ Q·Rk`), since `C' ≥ Cf·(2D)^{n+2}`. -/
private theorem coarse_qle_core (a b dC dM P Q Rk : Int)
    (ha : 0 ≤ a) (hb : 0 ≤ b) (hdC : 0 ≤ dC) (hdM : 0 ≤ dM)
    (hQ : 0 ≤ Q) (hRk : 0 ≤ Rk) (hP_QR : P ≤ Q * Rk) :
    b * 1 * (dC * dM * 1 * P) ≤ (b * dM + a * dC) * Q * 1 * (dC * Rk) := by
  have hc : 0 ≤ b * dC * dM := Int.mul_nonneg (Int.mul_nonneg hb hdC) hdM
  have key : b * dC * dM * P ≤ b * dC * dM * (Q * Rk) := Int.mul_le_mul_of_nonneg_left hP_QR hc
  have hnn : 0 ≤ a * dC * Q * dC * Rk :=
    Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg ha hdC) hQ) hdC) hRk
  have hL : b * 1 * (dC * dM * 1 * P) = b * dC * dM * P := by ring_uor
  have hR : (b * dM + a * dC) * Q * 1 * (dC * Rk)
      = b * dC * dM * (Q * Rk) + a * dC * Q * dC * Rk := by ring_uor
  omega

/-- The window lower-bound cross-multiplication: `(k+1) ≤ (m+1)/D` (as `(k+1)·D ≤ m+1`) lifts to the
    rational `(k+1) ≤ (1/D)·(m+1)`. -/
private theorem lower_qle_core (k m D : Int) (h : (k + 1) * D ≤ m + 1) :
    (k + 1) * (D * 1) ≤ 1 * (m + 1) * 1 := by
  have e1 : (k + 1) * (D * 1) = (k + 1) * D := by ring_uor
  have e2 : (1 : Int) * (m + 1) * 1 = m + 1 := by ring_uor
  omega

/-- **Shrinking-dilation ("fine") window decay.** For a test `φ` with clean k-indexed order-`(n+2)`
    half-line decay (constant `Cf`) and uniform bound `φ.M`, and any `D ≥ 1`, the fine dilation
    `dilateTest (1/D) φ` (whose `.f y = φ.f((1/D)·y)`) has window decay at the per-`D` constant
    `C' = (Cf + φ.M)·(2D)^{n+2}`. The two bands (coarse `m+1 ≥ D` via deflated `φ`-decay, fine
    `m+1 < D` via the uniform bound) are stitched by `rcases Nat.lt_or_ge (m+1) D`. -/
theorem dilateTest_fine_window_decay (phi : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (phi.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (D : Nat) (hD : 0 < D) :
    ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, D⟩ : Q) Int.zero_lt_one hD phi).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul (mul (add Cf phi.M) (⟨(((2 * D) ^ (n + 2) : Nat) : Int), 1⟩ : Q))
              (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos (add_den_pos hCfd phi.hMd) Nat.one_pos)
            (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) := by
  intro m x hx0 hx1
  rcases Nat.lt_or_ge (m + 1) D with hlt | hge
  · -- FINE band: `m+1 < D`, the argument is `< 1`, only `φ.M` survives
    refine Rle_trans (phi.hbd (Rmul (ofQ (⟨1, D⟩ : Q) hD)
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
      (Rle_ofQ_ofQ phi.hMd _ ?_)
    -- `φ.M ≤ C'/(m+1)^{n+2}`
    simp only [Qle, mul, add]
    push_cast
    refine fine_qle_core phi.M.num Cf.num _ _ _ _ phi.hMn hCfn ?_ ?_ ?_ ?_
    · omega
    · omega
    · exact_mod_cast Nat.zero_le ((2 * D) ^ (n + 2))
    · have hnat : (m + 1) ^ (n + 2) ≤ (2 * D) ^ (n + 2) :=
        Nat.pow_le_pow_left (by omega) (n + 2)
      exact_mod_cast hnat
  · -- COARSE band: `m+1 ≥ D`, the argument is `≥ 1`, `φ`'s decay fires at `k = (m+1)/D − 1`
    have hK1 : 1 ≤ (m + 1) / D := Nat.le_div_iff_mul_le hD |>.mpr (by omega)
    have hk : (m + 1) / D - 1 + 1 = (m + 1) / D := by omega
    -- window-point lower bound `(m+1) + x ≥ m+1`
    have hAB : Rle (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos)
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x) :=
      Rle_self_Radd_right (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
        (Rnonneg_of_Rle_zero hx0))
    -- `arg ≥ (1/D)·(m+1) = (m+1)/D`
    have harg_mD : Rle (ofQ (mul (⟨1, D⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q))
          (Qmul_den_pos hD Nat.one_pos))
        (Rmul (ofQ (⟨1, D⟩ : Q) hD)
          (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) :=
      Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hD Nat.one_pos)))
        (Rmul_le_Rmul_left (Rnonneg_ofQ hD (show (0 : Int) ≤ 1 by decide)) hAB)
    -- `(m+1)/D ≥ k+1`
    have hqkD : Qle (⟨((m + 1) / D - 1 : Nat) + 1, 1⟩ : Q)
        (mul (⟨1, D⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q)) := by
      have hnatC : ((m + 1) / D - 1 + 1) * D ≤ m + 1 := by
        rw [hk]; exact Nat.div_mul_le_self (m + 1) D
      have hInt : (((m + 1) / D - 1 : Nat) + 1 : Int) * (D : Int) ≤ (m : Int) + 1 := by
        exact_mod_cast hnatC
      simp only [Qle, mul]
      push_cast
      exact lower_qle_core _ _ _ hInt
    have hkD : Rle (ofQ (⟨((m + 1) / D - 1 : Nat) + 1, 1⟩ : Q) Nat.one_pos)
        (ofQ (mul (⟨1, D⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q)) (Qmul_den_pos hD Nat.one_pos)) :=
      Rle_ofQ_ofQ Nat.one_pos (Qmul_den_pos hD Nat.one_pos) hqkD
    have harg_k : Rle (ofQ (⟨((m + 1) / D - 1 : Nat) + 1, 1⟩ : Q) Nat.one_pos)
        (Rmul (ofQ (⟨1, D⟩ : Q) hD)
          (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) :=
      Rle_trans hkD harg_mD
    -- `arg ≥ 0`
    have harg_nn : Rnonneg (Rmul (ofQ (⟨1, D⟩ : Q) hD)
        (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)) :=
      Rnonneg_of_Rle_zero (Rle_trans
        (Rle_zero_of_Rnonneg (Rnonneg_ofQ Nat.one_pos
          (show (0 : Int) ≤ (((m + 1) / D - 1 : Nat) : Int) + 1 by omega))) harg_k)
    -- feed the k-indexed decay at `k = (m+1)/D − 1`
    have hlow : Rle (ofQ (⟨((m + 1) / D - 1 : Nat) + 1, 1⟩ : Q) Nat.one_pos)
        (Rabs (Rmul (ofQ (⟨1, D⟩ : Q) hD)
          (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))) :=
      Rle_trans harg_k (Rle_of_Req (Req_symm (Rabs_of_nonneg harg_nn)))
    refine Rle_trans (hfdec ((m + 1) / D - 1) _ hlow) (Rle_ofQ_ofQ _ _ ?_)
    -- `Cf/(k+1)^{n+2} ≤ C'/(m+1)^{n+2}`
    have hcrux : m + 1 ≤ 2 * D * (((m + 1) / D - 1) + 1) := by
      have hDX : D ≤ D * (((m + 1) / D - 1) + 1) :=
        Nat.le_mul_of_pos_right D (by omega : 0 < ((m + 1) / D - 1) + 1)
      have hdm : D * (((m + 1) / D - 1) + 1) + (m + 1) % D = m + 1 := by
        rw [hk]; exact Nat.div_add_mod (m + 1) D
      have hmod : (m + 1) % D < D := Nat.mod_lt (m + 1) hD
      have hh : 2 * D * (((m + 1) / D - 1) + 1)
          = D * (((m + 1) / D - 1) + 1) + D * (((m + 1) / D - 1) + 1) := by
        rw [Nat.two_mul, Nat.add_mul]
      omega
    have hP_QR : ((m : Int) + 1) ^ (n + 2)
        ≤ (2 * (D : Int)) ^ (n + 2) * (((((m + 1) / D - 1 : Nat)) : Int) + 1) ^ (n + 2) := by
      have hnat : (m + 1) ^ (n + 2) ≤ (2 * D * (((m + 1) / D - 1) + 1)) ^ (n + 2) :=
        Nat.pow_le_pow_left hcrux (n + 2)
      have hmp : (2 * D * (((m + 1) / D - 1) + 1)) ^ (n + 2)
          = (2 * D) ^ (n + 2) * (((m + 1) / D - 1) + 1) ^ (n + 2) := by rw [Nat.mul_pow]
      rw [hmp] at hnat
      exact_mod_cast hnat
    simp only [Qle, mul, add]
    push_cast
    refine coarse_qle_core phi.M.num Cf.num _ _ _ _ _ phi.hMn hCfn ?_ ?_ ?_ ?_ hP_QR
    · omega
    · omega
    · exact_mod_cast Nat.zero_le ((2 * D) ^ (n + 2))
    · exact_mod_cast Nat.zero_le ((((m + 1) / D - 1) + 1) ^ (n + 2))

end Multiplicity.UOR.Bridge.F1Square.Square