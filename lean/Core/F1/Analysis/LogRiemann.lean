/-
F1 square — **the `∫ log` layer, part 2c(iv): the Riemann sums and the scale identity**
(`LogRiemann.lean`). The three structural facts that turn the point values
(`gLog_point`) and the telescopes (`LogStep`) into the dyadic rate for
`∫₀¹ log(c+t) dt`:

  1. the fold: `Σ_{i<k} gLog c (i/(N+1)) ≈ logFold(c(N+1), k) − k·log(N+1)`;
  2. the collapse: `riemannSum (gLog c) N ≈ (1/(N+1))·logFold(c(N+1), N+1) − log(N+1)`;
  3. the bracket: `ΔGn − hFold ≤ logFold(A, M) ≤ ΔGn` where `ΔGn = Gn(A+M) − Gn(A)`
     (the `LogStep` telescopes, closed into a two-sided `Rle` pair);
  4. the scale identity: `(1/M)·(Gn((c+1)M) − Gn(cM)) ≈ (Gn(c+1) − Gn(c)) + log M`
     — the `log`-multiplicativity cancellation (`logN_mul_gen`) that makes the
     `− log(N+1)` in (2) exactly absorb the `+ log M` in (4), so the Riemann sums
     converge to `Gn(c+1) − Gn(c) = ∫₀¹ log(c+t) dt` with defect `(1/M)·hFold(cM, M)
     ≤ 1/(cM)`.

HONEST SCOPE. Identities and brackets between constructed objects; the integral
evaluation itself (the rate at the `digammaMidx` schedule + `Rlim_eval_real`) is the
next brick. No positivity claim. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogStep
import Core.F1.Analysis.LogPointVal
import Core.F1.Analysis.HarmonicLogC

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Scalar helpers: `(k+1)·L ≈ k·L + L` and `(X+Y) − Y ≈ X`.
-- ===========================================================================

/-- `(X+Y) − Y ≈ X` (private copy; the `RealPow` original is private). -/
private theorem lr_add_sub_cancel (X Y : Real) : Req (Rsub (Radd X Y) Y) X :=
  Req_trans (Radd_assoc X Y (Rneg Y))
    (Req_trans (Radd_congr (Req_refl X) (Radd_neg Y)) (Radd_zero X))

/-- The successor collapse at the rational layer: `k + 1 = k+1`. -/
private theorem lr_succ_q (k : Nat) :
    Qeq (add (⟨(k : Int), 1⟩ : Q) (⟨1, 1⟩ : Q)) (⟨((k + 1 : Nat) : Int), 1⟩ : Q) := by
  simp only [Qeq, add]
  push_cast
  ring_uor

/-- **The successor smul**: `(k+1)·L ≈ k·L + L`. -/
private theorem lr_smul_succ (k : Nat) (L : Real) :
    Req (Rmul (ofQ (⟨((k + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) L)
      (Radd (Rmul (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) L) L) := by
  have hsucc : Req (ofQ (⟨((k + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)
      (Radd (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) one) :=
    Req_symm (Req_trans (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)
      (ofQ_congr (add_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos (lr_succ_q k)))
  refine Req_trans (Rmul_congr hsucc (Req_refl L)) ?_
  refine Req_trans (Rmul_comm _ L) ?_
  refine Req_trans (Rmul_distrib L (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) one) ?_
  exact Radd_congr (Rmul_comm L _) (Req_trans (Rmul_comm L one) (Rone_mul L))

-- ===========================================================================
-- 1. The fold: the partial Riemann sums are `logFold` minus `k` copies of `log(N+1)`.
-- ===========================================================================

/-- **The fold**: `Σ_{i<k} gLog c (i/(N+1)) ≈ logFold(c(N+1), k) − k·log(N+1)` for
    `k ≤ N+1` (`1 ≤ c ≤ 3`) — the point values (`gLog_point`) accumulated. -/
theorem RsumN_gLog (c N : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    ∀ k, k ≤ N + 1 →
    Req (RsumN (fun i => gLog c (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) k)
      (Rsub (logFold (c * (N + 1)) (Nat.mul_pos hc1 (Nat.succ_pos N)) k)
        (Rmul (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) (logN (N + 1) (Nat.succ_pos N))))
  | 0, _ => by
    refine Req_symm (Req_trans (Rsub_congr (Req_refl zero)
      (Req_trans (Rmul_comm _ _) (Rmul_zero _))) ?_)
    exact Radd_neg zero
  | (k + 1), hk => by
    have hk' : k ≤ N + 1 := Nat.le_of_succ_le hk
    have ha1 : 1 ≤ c * (N + 1) + k :=
      Nat.le_trans (Nat.le_trans (Nat.succ_pos N) (Nat.le_mul_of_pos_left (N + 1) hc1))
        (Nat.le_add_right _ k)
    show Req (Radd (RsumN _ k) (gLog c (ofQ (⟨(k : Int), N + 1⟩ : Q) (Nat.succ_pos N)))) _
    refine Req_trans (Radd_congr (RsumN_gLog c N hc1 hc3 k hk')
      (gLog_point c hc1 hc3 k N hk' ha1)) ?_
    -- `(F − kL) + (g − L) ≈ (F + g) − (kL + L)`, then `(kL + L) ≈ (k+1)L`
    refine Req_trans (Req_symm (Rsub_Radd_Radd
      (logFold (c * (N + 1)) (Nat.mul_pos hc1 (Nat.succ_pos N)) k)
      (logN (c * (N + 1) + k) ha1)
      (Rmul (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) (logN (N + 1) (Nat.succ_pos N)))
      (logN (N + 1) (Nat.succ_pos N)))) ?_
    exact Rsub_congr (Req_refl _) (Req_symm (lr_smul_succ k (logN (N + 1) (Nat.succ_pos N))))

-- ===========================================================================
-- 2. The collapse: the full Riemann sum.
-- ===========================================================================

/-- The scalar collapse `(1/(N+1))·(N+1) = 1` at the rational layer. -/
private theorem lr_inv_collapse (N : Nat) :
    Qeq (mul (⟨1, N + 1⟩ : Q) (⟨((N + 1 : Nat) : Int), 1⟩ : Q)) (⟨1, 1⟩ : Q) := by
  simp only [Qeq, mul]
  push_cast
  ring_uor

/-- **The collapse**: `riemannSum (gLog c) N ≈ (1/(N+1))·logFold(c(N+1), N+1) − log(N+1)`. -/
theorem riemannSum_gLog (c N : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    Req (riemannSum (gLog c) N)
      (Rsub (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
          (logFold (c * (N + 1)) (Nat.mul_pos hc1 (Nat.succ_pos N)) (N + 1)))
        (logN (N + 1) (Nat.succ_pos N))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => gLog c (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _)
    (RsumN_gLog c N hc1 hc3 (N + 1) (Nat.le_refl _))) ?_
  refine Req_trans (Rmul_sub_distrib (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) _ _) ?_
  refine Rsub_congr (Req_refl _) ?_
  -- `(1/(N+1))·((N+1)·L) ≈ L`
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (ofQ (⟨((N + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) (logN (N + 1) (Nat.succ_pos N)))) ?_
  refine Req_trans (Rmul_congr (Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N) Nat.one_pos)
    (ofQ_congr (Qmul_den_pos (Nat.succ_pos N) Nat.one_pos) Nat.one_pos
      (lr_inv_collapse N))) (Req_refl (logN (N + 1) (Nat.succ_pos N)))) ?_
  exact Rone_mul (logN (N + 1) (Nat.succ_pos N))

-- ===========================================================================
-- 3. The bracket: `logFold` between the `Gn` differences.
-- ===========================================================================

/-- **The bracket, upper side**: `logFold(A, M) ≤ Gn(A+M) − Gn(A)`. -/
theorem logFold_le_Gn (A M : Nat) (hA : 1 ≤ A) :
    Rle (logFold A hA M) (Rsub (Gn (A + M) (by omega)) (Gn A hA)) := by
  refine Rle_Rsub_of_Radd_le ?_
  exact Rle_trans (Rle_of_Req (Radd_comm (logFold A hA M) (Gn A hA)))
    (Gn_tele_lower A hA M)

/-- **The bracket, lower side**: `(Gn(A+M) − Gn(A)) − hFold(A, M) ≤ logFold(A, M)`. -/
theorem Gn_le_logFold (A M : Nat) (hA : 1 ≤ A) :
    Rle (Rsub (Rsub (Gn (A + M) (by omega)) (Gn A hA))
        (ofQ (hFold A M) (hFold_den_pos A hA M)))
      (logFold A hA M) := by
  have hchain : Rle (Gn (A + M) (by omega))
      (Radd (Radd (Gn A hA) (ofQ (hFold A M) (hFold_den_pos A hA M))) (logFold A hA M)) := by
    refine Rle_trans (Gn_tele_upper A hA M) ?_
    refine Rle_trans (Radd_le_add (Rle_refl (Gn A hA)) (logFold_gap A hA M)) ?_
    refine Rle_of_Req ?_
    refine Req_trans (Radd_congr (Req_refl (Gn A hA))
      (Radd_comm (logFold A hA M) (ofQ (hFold A M) (hFold_den_pos A hA M)))) ?_
    exact Req_symm (Radd_assoc (Gn A hA) (ofQ (hFold A M) (hFold_den_pos A hA M))
      (logFold A hA M))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_Radd_eq (Gn (A + M) (by omega))
    (Gn A hA) (ofQ (hFold A M) (hFold_den_pos A hA M))))) ?_
  exact Rsub_le_of_le_Radd hchain

-- ===========================================================================
-- 4. The scale identity.
-- ===========================================================================

/-- The scalar collapse `(1/M)·(kM) = k` at the rational layer. -/
private theorem lr_scale_q (k M : Nat) :
    Qeq (mul (⟨1, M⟩ : Q) (⟨((k * M : Nat) : Int), 1⟩ : Q)) (⟨(k : Int), 1⟩ : Q) := by
  simp only [Qeq, mul]
  push_cast
  ring_uor

/-- **The `Gn` expansion under scaling**: `(1/M)·Gn(kM) ≈ Gn(k) + k·log M` — the
    `log`-multiplicativity (`logN_mul_gen`) driven through the antiderivative. -/
theorem Gn_scale_expand (k M : Nat) (hk : 1 ≤ k) (hM : 1 ≤ M) :
    Req (Rmul (ofQ (⟨1, M⟩ : Q) hM) (Gn (k * M) (Nat.mul_pos hk hM)))
      (Radd (Gn k hk)
        (Rmul (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) (logN M hM))) := by
  have hcol : Req (Rmul (ofQ (⟨1, M⟩ : Q) hM)
      (ofQ (⟨((k * M : Nat) : Int), 1⟩ : Q) Nat.one_pos))
      (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) :=
    Req_trans (Rmul_ofQ_ofQ (show 0 < (⟨1, M⟩ : Q).den from hM) Nat.one_pos)
      (ofQ_congr (Qmul_den_pos (show 0 < (⟨1, M⟩ : Q).den from hM) Nat.one_pos)
        Nat.one_pos (lr_scale_q k M))
  -- distribute over the `Gn` subtraction
  refine Req_trans (Rmul_sub_distrib (ofQ (⟨1, M⟩ : Q) hM) _ _) ?_
  -- the linear term: `(1/M)·(kM) ≈ k`
  refine Req_trans (Rsub_congr (Req_refl _) hcol) ?_
  -- the log term: `(1/M)·(kM·log(kM)) ≈ k·(log k + log M)`
  have hlog : Req (Rmul (ofQ (⟨1, M⟩ : Q) hM)
      (Rmul (ofQ (⟨((k * M : Nat) : Int), 1⟩ : Q) Nat.one_pos)
        (logN (k * M) (Nat.mul_pos hk hM))))
      (Radd (Rmul (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) (logN k hk))
        (Rmul (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) (logN M hM))) := by
    refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, M⟩ : Q) hM)
      (ofQ (⟨((k * M : Nat) : Int), 1⟩ : Q) Nat.one_pos)
      (logN (k * M) (Nat.mul_pos hk hM)))) ?_
    refine Req_trans (Rmul_congr hcol
      (Req_symm (logN_mul_gen k M hk hM))) ?_
    exact Rmul_distrib (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) (logN k hk) (logN M hM)
  refine Req_trans (Rsub_congr hlog (Req_refl _)) ?_
  -- `(a + b) − c ≈ (a − c) + b`
  refine Req_trans (Rsub_congr (Radd_comm _ _) (Req_refl _)) ?_
  refine Req_trans (Radd_assoc (Rmul (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) (logN M hM))
    (Rmul (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos) (logN k hk))
    (Rneg (ofQ (⟨(k : Int), 1⟩ : Q) Nat.one_pos))) ?_
  exact Radd_comm _ _

/-- **★ The scale identity**: `(1/M)·(Gn((c+1)M) − Gn(cM)) ≈ (Gn(c+1) − Gn(c)) + log M`
    — the exact value the Riemann sums chase, before the `− log(N+1)` of the collapse
    absorbs the `+ log M`. -/
theorem Gn_scale_identity (c M : Nat) (hc : 1 ≤ c) (hM : 1 ≤ M) :
    Req (Rmul (ofQ (⟨1, M⟩ : Q) hM)
        (Rsub (Gn ((c + 1) * M) (Nat.mul_pos (by omega) hM))
          (Gn (c * M) (Nat.mul_pos hc hM))))
      (Radd (Rsub (Gn (c + 1) (by omega)) (Gn c hc)) (logN M hM)) := by
  refine Req_trans (Rmul_sub_distrib (ofQ (⟨1, M⟩ : Q) hM) _ _) ?_
  refine Req_trans (Rsub_congr (Gn_scale_expand (c + 1) M (by omega) hM)
    (Gn_scale_expand c M hc hM)) ?_
  refine Req_trans (Rsub_Radd_Radd (Gn (c + 1) (by omega))
    (Rmul (ofQ (⟨((c + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) (logN M hM))
    (Gn c hc) (Rmul (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) (logN M hM))) ?_
  refine Radd_congr (Req_refl _) ?_
  -- `(c+1)·logM − c·logM ≈ logM`
  refine Req_trans (Rsub_congr (lr_smul_succ c (logN M hM)) (Req_refl _)) ?_
  refine Req_trans (Rsub_congr (Radd_comm _ _) (Req_refl _)) ?_
  exact lr_add_sub_cancel (logN M hM) (Rmul (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) (logN M hM))

end UOR.Bridge.F1Square.Analysis
