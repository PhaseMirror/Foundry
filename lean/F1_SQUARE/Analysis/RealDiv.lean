/-
F1 square — the **real inverse law** `x · (1/x) ≈ 1` (the multiplicative-substrate gap that `Inv.lean`
left open: it built the reciprocal `Rinv` and its regularity, but not the defining identity). This is the
prerequisite for the complex reciprocal `Cinv` (and hence `1/(s−1)` in the Euler–Maclaurin continuation
of `ζ`, and the `Γ`-factor place — v0.16.0 goals A and B).

The proof mirrors `RinvSeq_regular`: at the reindexed point `A`, `x_A·(1/x_b) − 1 = (x_A − x_b)·(1/x_b)`
(`b = RinvR A`, using `x_b·(1/x_b) = 1`), whose modulus is `≤ (1/(A+1)+1/(b+1))·(1/L) ≤ 2/(L·(n+1))`
by regularity and the tail lower bound `x ≥ L`. So `C = 2·L.den` is a linear bound, and `Req_of_lin_bound`
closes it.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.Inv
import F1Square.Analysis.Log

namespace UOR.Bridge.F1Square.Analysis

/-- `a·(1/b) − 1 ≈ (a − b)·(1/b)` (for `b.num > 0`, since `b·(1/b) = 1`). -/
theorem Qmul_Qinv_sub_one {a b : Q} (had : 0 < a.den) (hbd : 0 < b.den) (hb : 0 < b.num) :
    Qeq (Qsub (mul a (Qinv b)) ⟨1, 1⟩) (mul (Qsub a b) (Qinv b)) :=
  Qeq_trans (Qsub_den_pos (Qmul_den_pos had (Qinv_den_pos hb)) (Qmul_den_pos hbd (Qinv_den_pos hb)))
    (Qsub_congr (Qeq_refl _) (Qeq_symm (Qmul_Qinv hb)))
    (Qeq_symm (Qmul_sub_right a b (Qinv b)))

/-- The cleared Step-C inequality (pure `Int`, clean atoms for `ring_uor`): `2(N+1)²D ≤ 2D(N+1)²M`
    (`M ≥ 1`), the slack `= 2D(N+1)²(M−1) ≥ 0`. -/
private theorem inv_C2_aux (N D M : Int) (hN : 0 ≤ N) (hD : 0 ≤ D) (hM : 1 ≤ M) :
    (1 * (N + 1) + 1 * (N + 1)) * D * (N + 1) ≤ 2 * D * ((N + 1) * (N + 1) * M) := by
  have key : 2 * D * ((N + 1) * (N + 1) * M) - (1 * (N + 1) + 1 * (N + 1)) * D * (N + 1)
      = 2 * D * ((N + 1) * (N + 1)) * (M - 1) := by ring_uor
  have h1 : 0 ≤ 2 * D * ((N + 1) * (N + 1)) :=
    Int.mul_nonneg (Int.mul_nonneg (by omega) hD) (Int.mul_nonneg (by omega) (by omega))
  have h2 := Int.mul_nonneg h1 (by omega : (0 : Int) ≤ M - 1)
  omega

/-- **Per-point inverse bound**: at any reindex point `A ≥ n`, `|x_A·(1/x_{R A}) − 1| ≤ 2·L.den/(n+1)`
    (`L = RL x k` the positive tail lower bound). -/
theorem Rmul_Rinv_perpoint {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k)) {A n : Nat} (hAn : n ≤ A) :
    Qle (Qabs (Qsub (mul (x.seq A) (Qinv (x.seq (RinvR x k A)))) ⟨1, 1⟩))
        ⟨((2 * (RL x k).den : Nat) : Int), n + 1⟩ := by
  have hbpos : 0 < (x.seq (RinvR x k A)).num := Rinv_num_pos hk (RinvR_ge A)
  have hblb : Qle (RL x k) (x.seq (RinvR x k A)) := Rinv_lb hk (RinvR_ge A)
  have hRLn : 0 < (RL x k).num := RL_num_pos hk
  have hbd : 0 < (x.seq (RinvR x k A)).den := x.den_pos _
  have hAd : 0 < (x.seq A).den := x.den_pos _
  -- `n ≤ A ≤ R A`
  have hAb : A ≤ RinvR x k A := by
    have hKpos : 0 < RinvK x k :=
      Nat.mul_pos (Nat.mul_pos (by decide) (@Rdelta_den_pos x k)) (@Rdelta_den_pos x k)
    have : A + 1 ≤ RinvK x k * (A + 1) := Nat.le_mul_of_pos_left _ hKpos
    unfold RinvR; omega
  -- identity → modulus product
  have hAbs : Qeq (Qabs (Qsub (mul (x.seq A) (Qinv (x.seq (RinvR x k A)))) ⟨1, 1⟩))
      (mul (Qabs (Qsub (x.seq A) (x.seq (RinvR x k A)))) (Qinv (x.seq (RinvR x k A)))) := by
    have h1 := Qabs_Qeq (Qmul_Qinv_sub_one hAd hbd hbpos)
    rw [Qabs_mul, Qabs_Qinv] at h1
    exact h1
  -- Step B: `≤ (1/(A+1)+1/(R A+1))·(1/L)`
  have hStepB : Qle (mul (Qabs (Qsub (x.seq A) (x.seq (RinvR x k A)))) (Qinv (x.seq (RinvR x k A))))
      (mul (add (Qbound A) (Qbound (RinvR x k A))) (Qinv (RL x k))) :=
    Qmul_le_mul (Qabs_den_pos (Qsub_den_pos hAd hbd))
      (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (Qinv_den_pos hbpos)
      (Qabs_num_nonneg _) (Int.ofNat_nonneg _) (x.reg A (RinvR x k A)) (Qinv_antitone hbpos hRLn hblb)
  -- Step C: `≤ 2·L.den/(n+1)`
  have hStepC1 : Qle (mul (add (Qbound A) (Qbound (RinvR x k A))) (Qinv (RL x k)))
      (mul (add (Qbound n) (Qbound n)) (Qinv (RL x k))) :=
    Qmul_le_mul (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
      (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (Qinv_den_pos hRLn)
      (by show (0 : Int) ≤ (add (Qbound A) (Qbound (RinvR x k A))).num
          simp only [add, Qbound]; push_cast; omega)
      (Int.ofNat_nonneg _) (Qadd_le_add (Qbound_anti hAn) (Qbound_anti (by omega : n ≤ RinvR x k A)))
      (Qle_refl _)
  have hRLtoNat : 1 ≤ (RL x k).num.toNat := by omega
  have hStepC2 : Qle (mul (add (Qbound n) (Qbound n)) (Qinv (RL x k)))
      ⟨((2 * (RL x k).den : Nat) : Int), n + 1⟩ := by
    show (mul (add (Qbound n) (Qbound n)) (Qinv (RL x k))).num * ((n + 1 : Nat) : Int)
      ≤ ((2 * (RL x k).den : Nat) : Int) * (mul (add (Qbound n) (Qbound n)) (Qinv (RL x k))).den
    simp only [mul, add, Qbound, Qinv]
    push_cast
    exact inv_C2_aux (n : Int) ((RL x k).den : Int) ((RL x k).num.toNat : Int)
      (Int.ofNat_nonneg _) (Int.ofNat_nonneg _) (by exact_mod_cast hRLtoNat)
  exact Qle_trans (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos hAd hbd)) (Qinv_den_pos hbpos))
    (Qeq_le hAbs)
    (Qle_trans (Qmul_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (Qinv_den_pos hRLn))
      hStepB
      (Qle_trans (Qmul_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (Qinv_den_pos hRLn))
        hStepC1 hStepC2))

/-- **The real inverse law** `x · (1/x) ≈ 1` (`x` positive via the witness `k`). -/
theorem Rmul_Rinv_self {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k)) :
    Req (Rmul x (Rinv x k hk)) one := by
  apply Req_of_lin_bound (C := 2 * (RL x k).den)
  intro n
  exact Rmul_Rinv_perpoint hk (Ridx_ge x (Rinv x k hk) n)

end UOR.Bridge.F1Square.Analysis
