/-
F1 square — **the dilog kernel's rational brackets** (`DilogPhiVal.lean`). Every dyadic sample of
`Φ`'s inner integrand at rational `u` is the exact rational `1/(1+su)` (`phiInner_ofQ`), so the
level-`M` dyadic sum of `Φ(u)` is an exact rational fold (`phiRat`), and the monotone dyadic
bracket collapses `Φ(u)` to pure rational arithmetic:

    `phiRat(u, 2^M−1) − (3/4)/2^M  ≤  Φ(u)  ≤  phiRat(u, 2^M−1)`      (`u ∈ [0,3]` rational).

The `3/4` is the uniform endpoint variation (`1 − 1/(1+u) ≤ 3/4` for `u ≤ 3`). NO logs, NO wedges:
the entire dilog sample layer is rational `decide` material.

HONEST SCOPE. Brackets for the kernel at rational points; no dilog piece is constructed and no
sign is claimed. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.DilogPhi
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The rational sample fold.
-- ===========================================================================

/-- The rational fold `Σ_{i<n} 1/(1 + (i/D)·u)` — the exact value of the inner sample sum. -/
def qFoldPhi (u : Q) (D : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (n + 1) => add (qFoldPhi u D n)
      (Qinv (add (⟨1, 1⟩ : Q) (mul (⟨(n : Int), D⟩ : Q) u)))

/-- The fold's denominator is positive. -/
theorem qFoldPhi_den_pos (u : Q) (hud : 0 < u.den) (hun : 0 ≤ u.num) (D : Nat) (hD : 0 < D) :
    ∀ n, 0 < (qFoldPhi u D n).den
  | 0 => Nat.one_pos
  | (n + 1) => add_den_pos (qFoldPhi_den_pos u hud hun D hD n)
      (Qinv_den_pos (one_add_mul_num_pos hD hud (Int.ofNat_nonneg n) hun))

/-- **The exact rational level value**: `phiRat u N = (1/(N+1))·qFoldPhi u (N+1) (N+1)` — the
    `(N+1)`-point left Riemann sum of `Φ(u)`'s inner integrand, as one rational. -/
def phiRat (u : Q) (N : Nat) : Q := mul (⟨1, N + 1⟩ : Q) (qFoldPhi u (N + 1) (N + 1))

/-- `phiRat`'s denominator is positive. -/
theorem phiRat_den_pos (u : Q) (hud : 0 < u.den) (hun : 0 ≤ u.num) (N : Nat) :
    0 < (phiRat u N).den :=
  Qmul_den_pos (Nat.succ_pos N) (qFoldPhi_den_pos u hud hun (N + 1) (Nat.succ_pos N) (N + 1))

/-- The inner sample sum is the rational fold. -/
theorem RsumN_phi_eq (u : Q) (hud : 0 < u.den) (h0u : Qle (⟨0, 1⟩ : Q) u)
    (hu3 : Qle u (⟨3, 1⟩ : Q)) (hun : 0 ≤ u.num) (N : Nat) :
    ∀ n, Req (RsumN (fun i => phiInner (ofQ u hud)
        (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) n)
      (ofQ (qFoldPhi u (N + 1) n)
        (qFoldPhi_den_pos u hud hun (N + 1) (Nat.succ_pos N) n))
  | 0 => Req_refl _
  | (n + 1) => by
      refine Req_trans (Radd_congr (RsumN_phi_eq u hud h0u hu3 hun N n)
        (phiInner_ofQ hud (Nat.succ_pos N) h0u hu3 hun (Int.ofNat_nonneg n))) ?_
      exact Radd_ofQ_ofQ _ _

/-- **The dyadic Riemann sum of `Φ(u)`'s inner integrand is the exact rational `phiRat`.** -/
theorem riemannSum_phi_eq (u : Q) (hud : 0 < u.den) (h0u : Qle (⟨0, 1⟩ : Q) u)
    (hu3 : Qle u (⟨3, 1⟩ : Q)) (hun : 0 ≤ u.num) (N : Nat) :
    Req (riemannSum (phiInner (ofQ u hud)) N)
        (ofQ (phiRat u N) (phiRat_den_pos u hud hun N)) := by
  refine Req_trans (Rmul_congr (Req_refl (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)))
    (RsumN_phi_eq u hud h0u hu3 hun N (N + 1))) ?_
  exact Rmul_ofQ_ofQ (Nat.succ_pos N) _

-- ===========================================================================
-- Antitonicity and the variation bound of the inner integrand.
-- ===========================================================================

/-- Multiplication by a non-negative right factor is monotone. -/
private theorem qmul_le_right {p q u : Q} (hu : 0 ≤ u.num) (h : Qle p q) :
    Qle (mul p u) (mul q u) := by
  simp only [Qle, mul] at h ⊢
  push_cast
  have e1 : (p.num * u.num) * ((q.den : Int) * (u.den : Int))
      = (u.num * (u.den : Int)) * (p.num * (q.den : Int)) := by ring_uor
  have e2 : (q.num * u.num) * ((p.den : Int) * (u.den : Int))
      = (u.num * (u.den : Int)) * (q.num * (p.den : Int)) := by ring_uor
  rw [e1, e2]
  exact Int.mul_le_mul_of_nonneg_left h (Int.mul_nonneg hu (Int.ofNat_nonneg u.den))

/-- **The inner integrand is sample-antitone** (`u ≥ 0`): larger `s` gives a larger denominator. -/
theorem phiInner_sampleAnti (u : Q) (hud : 0 < u.den) (h0u : Qle (⟨0, 1⟩ : Q) u)
    (hu3 : Qle u (⟨3, 1⟩ : Q)) (hun : 0 ≤ u.num) :
    SampleAnti (phiInner (ofQ u hud)) := by
  intro a b had hbd h0a hab _hb1
  have han : 0 ≤ a.num := by
    have h := h0a; simp only [Qle] at h; push_cast at h; omega
  have hbn : 0 ≤ b.num := by
    have h := Qle_trans had h0a hab; simp only [Qle] at h; push_cast at h; omega
  refine Rle_trans (Rle_of_Req (phiInner_ofQ hud hbd h0u hu3 hun hbn)) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (phiInner_ofQ hud had h0u hu3 hun han)))
  refine Rle_ofQ_ofQ _ _ ?_
  refine Qinv_anti (one_add_mul_num_pos had hud han hun)
    (one_add_mul_num_pos hbd hud hbn hun) ?_
  exact Qadd_le_add (Qle_refl (⟨1, 1⟩ : Q)) (qmul_le_right hun hab)

/-- `1 + 1·u ≤ 4` for `u ≤ 3`. -/
private theorem one_add_u_le_four {u : Q} (hu3 : Qle u (⟨3, 1⟩ : Q)) :
    Qle (add (⟨1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) u)) (⟨4, 1⟩ : Q) := by
  have h := hu3; simp only [Qle] at h; push_cast at h
  show ((1 : Int) * ((1 * u.den : Nat) : Int) + (1 * u.num) * ((1 : Nat) : Int))
      * ((1 : Nat) : Int) ≤ (4 : Int) * ((1 * (1 * u.den) : Nat) : Int)
  push_cast
  omega

/-- **The uniform endpoint variation**: `f(0) − f(1) ≤ 3/4` for the inner integrand (`u ≤ 3`). -/
theorem phiInner_var (u : Q) (hud : 0 < u.den) (h0u : Qle (⟨0, 1⟩ : Q) u)
    (hu3 : Qle u (⟨3, 1⟩ : Q)) (hun : 0 ≤ u.num) :
    Rle (Rsub (phiInner (ofQ u hud) (ofQ (⟨0, 1⟩ : Q) Nat.one_pos))
              (phiInner (ofQ u hud) (ofQ (⟨1, 1⟩ : Q) Nat.one_pos)))
        (ofQ (⟨3, 4⟩ : Q) (by decide)) := by
  have hA0n : 0 < (add (⟨1, 1⟩ : Q) (mul (⟨0, 1⟩ : Q) u)).num :=
    one_add_mul_num_pos Nat.one_pos hud (by decide) hun
  have hA1n : 0 < (add (⟨1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) u)).num :=
    one_add_mul_num_pos Nat.one_pos hud (by decide) hun
  -- `1/(1+0·u) ≤ 1`
  have hq0 : Qle (Qinv (add (⟨1, 1⟩ : Q) (mul (⟨0, 1⟩ : Q) u))) (⟨1, 1⟩ : Q) :=
    Qle_trans (Qinv_den_pos (by decide))
      (Qinv_anti (by decide) hA0n (one_le_one_add_mul (by decide) hun)) (by decide)
  -- `1/4 ≤ 1/(1+1·u)`
  have hq1 : Qle (⟨1, 4⟩ : Q) (Qinv (add (⟨1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) u))) :=
    Qle_trans (Qinv_den_pos (by decide)) (by decide)
      (Qinv_anti hA1n (by decide) (one_add_u_le_four hu3))
  have hsub : Qle (Qsub (Qinv (add (⟨1, 1⟩ : Q) (mul (⟨0, 1⟩ : Q) u)))
      (Qinv (add (⟨1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) u))))
      (Qsub (⟨1, 1⟩ : Q) (⟨1, 4⟩ : Q)) :=
    Qadd_le_add hq0 (Qneg_le_neg hq1)
  have hfinal : Qle (Qsub (Qinv (add (⟨1, 1⟩ : Q) (mul (⟨0, 1⟩ : Q) u)))
      (Qinv (add (⟨1, 1⟩ : Q) (mul (⟨1, 1⟩ : Q) u)))) (⟨3, 4⟩ : Q) :=
    Qle_trans (Qsub_den_pos (by decide) (by decide)) hsub (by decide)
  refine Rle_trans (Rle_of_Req (Rsub_congr
    (phiInner_ofQ hud Nat.one_pos h0u hu3 hun (by decide))
    (phiInner_ofQ hud Nat.one_pos h0u hu3 hun (by decide)))) ?_
  refine Rle_trans (Rle_of_Req (Rsub_ofQ_ofQ _ _)) ?_
  exact Rle_ofQ_ofQ _ _ hfinal

-- ===========================================================================
-- The rational brackets.
-- ===========================================================================

/-- The `Φ`-modulus schedule reaches every level `M ≤ 17`. -/
theorem phi_sched {M : Nat} (hM : M ≤ 17) :
    ∀ j, M ≤ digammaMidx (⟨16, 1⟩ : Q) j := fun j =>
  Nat.le_trans hM (show 17 ≤ 17 * (j + 1) by omega)

/-- **The upper rational bracket**: `Φ(u) ≤ phiRat u (2^M−1)` (`u ∈ [0,3]`, `M ≤ 17`). -/
theorem Phi_ofQ_le (u : Q) (hud : 0 < u.den) (h0u : Qle (⟨0, 1⟩ : Q) u)
    (hu3 : Qle u (⟨3, 1⟩ : Q)) (hun : 0 ≤ u.num) (M : Nat) (hM : M ≤ 17) :
    Rle (Phi (ofQ u hud))
        (ofQ (phiRat u (2 ^ M - 1)) (phiRat_den_pos u hud hun (2 ^ M - 1))) := by
  refine Rle_trans (riemannIntegral_anti_upper (by decide) (by decide)
    (phiInner_lip (ofQ u hud)) (phiInner_congr (ofQ u hud))
    (phiInner_sampleAnti u hud h0u hu3 hun) M (phi_sched hM)) ?_
  show Rle (riemannSum (phiInner (ofQ u hud)) (2 ^ M - 1)) _
  exact Rle_of_Req (riemannSum_phi_eq u hud h0u hu3 hun (2 ^ M - 1))

/-- **The lower rational bracket**: `phiRat u (2^M−1) − (3/4)/2^M ≤ Φ(u)` (`u ∈ [0,3]`, `M ≤ 17`). -/
theorem Phi_ofQ_ge (u : Q) (hud : 0 < u.den) (h0u : Qle (⟨0, 1⟩ : Q) u)
    (hu3 : Qle u (⟨3, 1⟩ : Q)) (hun : 0 ≤ u.num) (M : Nat) (hM : M ≤ 17) :
    Rle (ofQ (Qsub (phiRat u (2 ^ M - 1)) (mul (⟨1, 2 ^ M⟩ : Q) (⟨3, 4⟩ : Q)))
          (Qsub_den_pos (phiRat_den_pos u hud hun (2 ^ M - 1))
            (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) (by decide))))
        (Phi (ofQ u hud)) := by
  have hlow := riemannIntegral_anti_lower (by decide) (by decide)
    (phiInner_lip (ofQ u hud)) (phiInner_congr (ofQ u hud))
    (phiInner_sampleAnti u hud h0u hu3 hun) (V := (⟨3, 4⟩ : Q)) (by decide) (by decide)
    (phiInner_var u hud h0u hu3 hun) M (phi_sched hM)
  -- `ofQ phiRat ≤ Φ + cap` (the dyadic sum is the exact rational)
  have hlow' : Rle (ofQ (phiRat u (2 ^ M - 1)) (phiRat_den_pos u hud hun (2 ^ M - 1)))
      (Radd (Phi (ofQ u hud))
        (ofQ (mul (⟨1, 2 ^ M⟩ : Q) (⟨3, 4⟩ : Q))
          (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) (by decide)))) := by
    refine Rle_trans (Rle_of_Req (Req_symm
      (riemannSum_phi_eq u hud h0u hu3 hun (2 ^ M - 1)))) ?_
    exact hlow
  -- shuffle: `ofQ phiRat − cap ≤ Φ`, then collapse the rational difference.
  have hshuf : Rle (Rsub (ofQ (phiRat u (2 ^ M - 1)) (phiRat_den_pos u hud hun (2 ^ M - 1)))
      (ofQ (mul (⟨1, 2 ^ M⟩ : Q) (⟨3, 4⟩ : Q))
        (Qmul_den_pos (Nat.pos_pow_of_pos M (by decide)) (by decide))))
      (Phi (ofQ u hud)) :=
    Rsub_le_of_le_Radd (Rle_trans hlow' (Rle_of_Req (Radd_comm _ _)))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ _ _))) hshuf

end Multiplicity.UOR.Bridge.F1Square.Analysis
