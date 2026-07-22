/-
F1 square — Track 1, item 6: **integer-radius power-Lipschitz** (`RrpowAbsLipNat.lean`).

`LogDiffBoundGen`'s general-`B` power-Lipschitz carries the K-acceleration obligations as caller
hypotheses. For an **integer** bound `B = ⟨N, 1⟩` (`N ≥ 1`) — what `xBound` and the integration windows
produce — those obligations are dischargeable internally with the canonical choice
`K_B = 2((N+1)² + 4(N+1))`, `K_BB = 2((N²+1)² + 4(N²+1))`: the radius conditions reduce to the polynomial
inequality `kf_poly` (`(n+1)² ≤ 8n(n+1)(n+5)`, via one `n ≤ n²` hint) and the monotonicity `ρ_N ≤ ρ_{N²}`,
all by hand (no `nlinarith`).

Result `RrpowPos_abs_lipschitz_natB`: `|x^e − y^e| ≤ 4·|e|·|x − y|` for `e ≤ 0`, `x, y ∈ [1, N]`, ANY
integer `N ≥ 1`, K-free — the uniformly-constant Mellin-integrand base-Lipschitz.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogDiffBoundGen

namespace UOR.Bridge.F1Square.Analysis

/-- The polynomial core `(n+1)² ≤ 8n(n+1)(n+5)` for `n ≥ 1` — the K-acceleration condition after the
    `1/(1−ρ²)` rational is cleared. One `n ≤ n²` hint, then `omega` + `ring_uor`. -/
private theorem kf_poly (n : Int) (hn : 1 ≤ n) :
    (n + 1) * (n + 1) ≤ 8 * n * (n + 1) * (n + 5) := by
  have hnn : n ≤ n * n := by
    have h := Int.mul_le_mul_of_nonneg_left hn (show (0 : Int) ≤ n by omega); simpa using h
  have key : (n + 1) ≤ 8 * n * (n + 5) := by
    have e2 : 8 * n * (n + 5) = 8 * (n * n) + 40 * n := by ring_uor
    rw [e2]; omega
  have hmul := Int.mul_le_mul_of_nonneg_right key (show (0 : Int) ≤ n + 1 by omega)
  have e3 : (8 * n * (n + 5)) * (n + 1) = 8 * n * (n + 1) * (n + 5) := by ring_uor
  rw [e3] at hmul; exact hmul

set_option maxHeartbeats 2000000 in
/-- **Integer-radius symmetric power-Lipschitz** `|x^e − y^e| ≤ 4·|e|·|x − y|` for `e ≤ 0`,
    `x, y ∈ [1, N]`, ANY integer `N ≥ 1` (K-acceleration discharged internally). -/
theorem RrpowPos_abs_lipschitz_natB (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky)) (e : Real) (he : Rle e zero)
    (N : Nat) (hN1 : 1 ≤ N)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhiN : ∀ n, Qle (x.seq n) (⟨(N : Int), 1⟩ : Q))
    (hxge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (x.seq n))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhiN : ∀ n, Qle (y.seq n) (⟨(N : Int), 1⟩ : Q))
    (hyge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (y.seq n)) :
    Rle (Rabs (Rsub (RrpowPos x kx hx e) (RrpowPos y ky hy e)))
        (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs e)) (Rabs (Rsub x y))) := by
  have hNI : (1 : Int) ≤ (N : Int) := by exact_mod_cast hN1
  have hNNI : (1 : Int) ≤ (N : Int) * (N : Int) := by
    have h := Int.mul_le_mul hNI hNI (show (0 : Int) ≤ 1 by omega) (show (0 : Int) ≤ (N : Int) by omega)
    simpa using h
  have hmulBB : (mul (⟨(N : Int), 1⟩ : Q) ⟨(N : Int), 1⟩) = (⟨((N * N : Nat) : Int), 1⟩ : Q) := rfl
  have t1 : (((N : Int).toNat : Nat) : Int) = (N : Int) := Int.toNat_of_nonneg (by omega)
  have t2 : ((((N : Int) * (N : Int)).toNat : Nat) : Int) = (N : Int) * (N : Int) :=
    Int.toNat_of_nonneg (by omega)
  refine RrpowPos_abs_lipschitz_gen x y kx hx ky hy e he (⟨(N : Int), 1⟩ : Q)
    (2 * ((N + 1) * (N + 1) + 4 * (N + 1))) (2 * ((N * N + 1) * (N * N + 1) + 4 * (N * N + 1)))
    Nat.one_pos ?hBge hxpos hxhiN hxge1 hypos hyhiN hyge1 ?hρσ ?hKBF ?hKBr ?hKBBF ?hKBBr
  case hBge => show Qle (⟨1, 1⟩ : Q) (⟨(N : Int), 1⟩ : Q); simp only [Qle]; push_cast; omega
  case hKBr => exact Nat.le_refl _
  case hKBBr => rw [hmulBB]; exact Nat.le_refl _
  case hρσ =>
    rw [hmulBB]; simp only [Qle]; push_cast; simp only [t1, t2]
    have hP : ((N : Int) * (N : Int) - 1) * ((N : Int) + 1) - ((N : Int) - 1) * ((N : Int) * (N : Int) + 1)
        = ((N : Int) - 1) * (2 * (N : Int)) := by ring_uor
    have hge : (0 : Int) ≤ ((N : Int) - 1) * (2 * (N : Int)) :=
      Int.mul_nonneg (by omega) (by omega)
    exact Int.le_of_sub_nonneg (by rw [hP]; exact hge)
  case hKBF =>
    simp only [Qle, mul, Qsub, add, neg]; push_cast; simp only [t1, t2]
    calc 1 * (1 * (1 * (((N : Int) + 1) * ((N : Int) + 1))))
        = ((N : Int) + 1) * ((N : Int) + 1) := by ring_uor
      _ ≤ 8 * (N : Int) * ((N : Int) + 1) * ((N : Int) + 5) := kf_poly (N : Int) hNI
      _ = 2 * (((N : Int) + 1) * ((N : Int) + 1) + 4 * ((N : Int) + 1))
            * (1 * (((N : Int) + 1) * ((N : Int) + 1)) + -(((N : Int) - 1) * ((N : Int) - 1)) * 1) * 1 := by
          ring_uor
  case hKBBF =>
    rw [hmulBB]; simp only [Qle, mul, Qsub, add, neg]; push_cast; simp only [t1, t2]
    calc 1 * (1 * (1 * (((N : Int) * (N : Int) + 1) * ((N : Int) * (N : Int) + 1))))
        = ((N : Int) * (N : Int) + 1) * ((N : Int) * (N : Int) + 1) := by ring_uor
      _ ≤ 8 * ((N : Int) * (N : Int)) * ((N : Int) * (N : Int) + 1) * ((N : Int) * (N : Int) + 5) :=
          kf_poly ((N : Int) * (N : Int)) hNNI
      _ = 2 * (((N : Int) * (N : Int) + 1) * ((N : Int) * (N : Int) + 1) + 4 * ((N : Int) * (N : Int) + 1))
            * (1 * (((N : Int) * (N : Int) + 1) * ((N : Int) * (N : Int) + 1))
              + -(((N : Int) * (N : Int) - 1) * ((N : Int) * (N : Int) - 1)) * 1) * 1 := by
          ring_uor

end UOR.Bridge.F1Square.Analysis
