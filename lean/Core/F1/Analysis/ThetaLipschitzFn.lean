/-
F1 square — Track 1, item 3 substrate: the **Jacobi-theta Lipschitz bound** `|ψ(s) − ψ(t)| ≤ (32/3)·|s−t|`
on `[1, ∞)` — the modulus of continuity the Mellin integrand needs to enter certified integration.

Assembled from the per-term bound `thetaTerm_lip` (`ThetaLipschitz.lean`): the partial sums are
Lipschitz with the **summable** constant `Σ 16/(3(m+1)²) ≤ 32/3` (each `16/(3(m+1)²) ≤ 32/(3(m+1)(m+2))`,
telescoping `genSum_boundTele`), and the Bishop limit inherits the bound. The difference of two limits
is routed around the "`RReg` not closed under `+`" obstruction via `Rlim_le_Rlim` + `Rlim_add_const`
(comparing `ψ(s)` to `ψ(t) + C` rather than forming `ψ(s) − ψ(t)` as a limit).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ThetaLipschitz

set_option maxHeartbeats 1000000

namespace UOR.Bridge.F1Square.Analysis

/-- `genSum` distributes over `Rsub`. -/
theorem genSum_Rsub (T U : Nat → Real) :
    ∀ N, Req (genSum (fun m => Rsub (T m) (U m)) N) (Rsub (genSum T N) (genSum U N))
  | 0 => Req_symm (Radd_neg zero)
  | (N + 1) => by
    show Req (Radd (genSum (fun m => Rsub (T m) (U m)) N) (Rsub (T N) (U N)))
      (Rsub (Radd (genSum T N) (T N)) (Radd (genSum U N) (U N)))
    exact Req_trans (Radd_congr (genSum_Rsub T U N) (Req_refl _))
      (Req_symm (Rsub_Radd_Radd (genSum T N) (T N) (genSum U N) (U N)))

/-- `genSum` distributes over a constant RIGHT factor: `Σ_{m<N} g(m)·c = (Σ_{m<N} g(m))·c`. -/
theorem genSum_Rmul_const_right (g : Nat → Real) (c : Real) :
    ∀ N, Req (genSum (fun m => Rmul (g m) c) N) (Rmul (genSum g N) c)
  | 0 => Req_symm (Req_trans (Rmul_comm zero c) (Rmul_zero c))
  | (N + 1) => by
    show Req (Radd (genSum (fun m => Rmul (g m) c) N) (Rmul (g N) c))
      (Rmul (Radd (genSum g N) (g N)) c)
    exact Req_trans (Radd_congr (genSum_Rmul_const_right g c N) (Req_refl _))
      (Req_symm (Rmul_distrib_right (genSum g N) (g N) c))

/-- The summable modulus partial sum is bounded: `Σ_{m<N} 16/(3(m+1)²) ≤ 32/3`. Each term
    `16/(3(m+1)²) ≤ (32/3)·(1/((m+1)(m+2)))`, and `Σ 1/((m+1)(m+2)) = N/(N+1) ≤ 1` (`genSum_boundTele`). -/
theorem genSum_thetaMod_le (N : Nat) :
    Rle (genSum (fun m => ofQ (⟨16, 3 * ((m + 1) * (m + 1))⟩ : Q)
        (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m)))) N)
      (ofQ (⟨32, 3⟩ : Q) (by decide)) := by
  -- per-term `16/(3(m+1)²) ≤ (32/3)·boundTele m`
  have hterm : ∀ m, Rle (ofQ (⟨16, 3 * ((m + 1) * (m + 1))⟩ : Q)
      (Nat.mul_pos (by decide) (Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos m))))
      (Rmul (ofQ (⟨32, 3⟩ : Q) (by decide)) (boundTele m)) := by
    intro m
    have hmm : 0 < (m + 1) * (m + 2) := Nat.mul_pos (Nat.succ_pos m) (Nat.succ_pos (m + 1))
    refine Rle_trans ?_ (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide)
      (Qmul_den_pos (by decide) hmm))))
    refine Rle_ofQ_ofQ _ (Qmul_den_pos (by decide) (Qmul_den_pos (by decide) hmm)) ?_
    -- Qle ⟨16,3(m+1)²⟩ (mul ⟨32,3⟩ (mul ⟨1,1⟩ ⟨1,(m+1)(m+2)⟩))
    have h1 : (m + 1) * (m + 2) ≤ 2 * ((m + 1) * (m + 1)) := by
      rw [Nat.mul_comm 2 ((m + 1) * (m + 1)), Nat.mul_assoc]
      exact Nat.mul_le_mul (Nat.le_refl _) (by omega)
    have hnat : 16 * (3 * ((m + 1) * (m + 2))) ≤ (32 * (3 * 1)) * ((m + 1) * (m + 1)) :=
      Nat.le_trans (Nat.mul_le_mul (Nat.le_refl 16) (Nat.mul_le_mul (Nat.le_refl 3) h1))
        (Nat.le_of_eq (by omega))
    simp only [Qle, mul]
    have hI : (↑(16 * (3 * ((m + 1) * (m + 2)))) : Int) ≤ ↑((32 * (3 * 1)) * ((m + 1) * (m + 1))) := by
      exact_mod_cast hnat
    push_cast at hI ⊢
    omega
  have hbt : Rle (genSum boundTele N) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    Rle_trans (Rle_of_Req (genSum_boundTele N))
      (Rle_ofQ_ofQ (Nat.succ_pos N) (by decide) (by simp only [Qle]; push_cast; omega))
  refine Rle_trans (genSum_le_genSum hterm N) ?_
  refine Rle_trans (Rle_of_Req (genSum_Rmul_const (ofQ (⟨32, 3⟩ : Q) (by decide)) boundTele N)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hbt) ?_
  exact Rle_of_Req (Rmul_one (ofQ (⟨32, 3⟩ : Q) (by decide)))

/-- **Directed `genSum` Lipschitz**: `Σ_{m<N} e^{−aₘs} − Σ_{m<N} e^{−aₘt} ≤ (32/3)·|s−t|` (needs `s ≥ 1`,
    order-free in `t`). Termwise `thetaTerm_diff_le`, factored constant `|s−t|`, summable modulus. -/
theorem genSum_thetaDiff_le (s t : Real) (hs : Rle one s) (N : Nat) :
    Rle (Rsub (genSum (thetaTerm s) N) (genSum (thetaTerm t) N))
      (Rmul (ofQ (⟨32, 3⟩ : Q) (by decide)) (Rabs (Rsub s t))) := by
  refine Rle_trans (Rle_of_Req (Req_symm (genSum_Rsub (thetaTerm s) (thetaTerm t) N))) ?_
  refine Rle_trans (genSum_le_genSum (fun m => thetaTerm_diff_le m s t hs) N) ?_
  refine Rle_trans (Rle_of_Req (genSum_Rmul_const_right _ (Rabs (Rsub s t)) N)) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (genSum_thetaMod_le N)

/-- **Directed `ψ` Lipschitz**: `ψ(u) − ψ(v) ≤ (32/3)·|u−v|` for `u ≥ 1` (order-free in `v`). Routes
    around the "`RReg` not closed under `+`" obstruction: compare `ψ(u)` to `ψ(v) + C` via `Rlim_le_Rlim`
    and `Rlim_add_const`, never forming the difference of limits. -/
theorem thetaFn_diff_le {u v : Real} (hu : Rle one u) (hv : Rle one v) :
    Rle (Rsub (thetaFn u hu) (thetaFn v hv))
      (Rmul (ofQ (⟨32, 3⟩ : Q) (by decide)) (Rabs (Rsub u v))) := by
  refine Rsub_le_of_le_add ?_
  have hcReg : RReg (fun j => Radd (Rmul (ofQ (⟨32, 3⟩ : Q) (by decide)) (Rabs (Rsub u v)))
      (genSum (thetaTerm v) (digammaMidx (⟨1, 1⟩ : Q) j))) :=
    RReg_add_const _ _ (thetaTerm_RReg v hv)
  refine Rle_trans (Rlim_le_Rlim (thetaTerm_RReg u hu) hcReg (fun j => ?_))
    (Rle_of_Req (Rlim_add_const _ _ (thetaTerm_RReg v hv) hcReg))
  exact Rle_trans (Rle_add_of_Rsub_le (genSum_thetaDiff_le u v hu (digammaMidx (⟨1, 1⟩ : Q) j)))
    (Rle_of_Req (Radd_comm _ _))

/-- **The Jacobi-theta Lipschitz bound** `|ψ(s) − ψ(t)| ≤ (32/3)·|s−t|` for `s, t ≥ 1` — symmetric form
    via `Rabs_le_of_both` and the directed bound both ways. -/
theorem thetaFn_lip {s t : Real} (hs : Rle one s) (ht : Rle one t) :
    Rle (Rabs (Rsub (thetaFn s hs) (thetaFn t ht)))
      (Rmul (ofQ (⟨32, 3⟩ : Q) (by decide)) (Rabs (Rsub s t))) := by
  refine Rabs_le_of_both (thetaFn_diff_le hs ht) ?_
  refine Rle_trans (Rle_of_Req (Rneg_Rsub (thetaFn s hs) (thetaFn t ht))) ?_
  refine Rle_trans (thetaFn_diff_le ht hs)
    (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (Rle_of_Req ?_))
  exact Req_trans (Req_symm (Rabs_Rneg (Rsub t s))) (Rabs_congr (Rneg_Rsub t s))

end UOR.Bridge.F1Square.Analysis
