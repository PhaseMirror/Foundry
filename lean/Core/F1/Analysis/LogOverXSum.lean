/-
F1 square — **the `∫ log/x` layer, part 6: the point values and the Riemann fold**
(`LogOverXSum.lean`). The dyadic samples of `gLx` collapse to log-times-rational
products, and the partial Riemann sums fold into the two certified objects:

    `gLx c (j/(N+1)) ≈ 2(log(c(N+1)+j) − log(N+1)) · (N+1)/(c(N+1)+j)`,
    `Σ_{i<k} gLx(i/(N+1)) ≈ (N+1)·hsSample(c(N+1), k) − 2log(N+1)·harmTermFoldC(k)`

— the sample fold (`LogSqStep`) carries the `log²` content, the harmonic fold
(`HarmonicLogC`) carries the `−2·log(N+1)` cross term, and the `(N+1)` prefactor
cancels against the Riemann `1/(N+1)` at the collapse:

    `riemannSum (gLx c) N ≈ hsSample(c(N+1), N+1) − 2log(N+1)·hFold(c(N+1), N+1)`.

HONEST SCOPE. Identities between constructed objects; no integral is evaluated and no
positivity is claimed. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LogOverX

namespace UOR.Bridge.F1Square.Analysis

/-- **The point values**: `gLx c (j/(N+1)) ≈ 2(log(c(N+1)+j) − log(N+1))·(N+1)/(c(N+1)+j)`. -/
theorem gLx_point (c : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) (j N : Nat) (hj : j ≤ N + 1)
    (ha1 : 1 ≤ c * (N + 1) + j) :
    Req (gLx c (ofQ (⟨(j : Int), N + 1⟩ : Q) (Nat.succ_pos N)))
      (Rmul (Radd (Rsub (logN (c * (N + 1) + j) ha1) (logN (N + 1) (Nat.succ_pos N)))
          (Rsub (logN (c * (N + 1) + j) ha1) (logN (N + 1) (Nat.succ_pos N))))
        (ofQ (⟨((N + 1 : Nat) : Int), c * (N + 1) + j⟩ : Q)
          (show 0 < c * (N + 1) + j from by
            have := Nat.mul_pos hc1 (show 0 < N + 1 by omega); omega))) :=
  Rmul_congr
    (Radd_congr (gLog_point c hc1 hc3 j N hj ha1) (gLog_point c hc1 hc3 j N hj ha1))
    (gRecipC_point c j N hc1)

/-- The sample regroup: `(2l − 2m)·(M/(A+j)) ≈ M·(2l·(1/(A+j))) − 2m·(M/(A+j))`
    (pure algebra, general in the reals and the two rational factors). -/
private theorem lxs_regroup (l m : Real) (Mq w q : Q)
    (hM : 0 < Mq.den) (hw : 0 < w.den) (hq : 0 < q.den)
    (hsplit : Qeq q (mul Mq w)) :
    Req (Rmul (Radd (Rsub l m) (Rsub l m)) (ofQ q hq))
      (Rsub (Rmul (ofQ Mq hM) (Rmul (ofQ w hw) (Radd l l)))
        (Rmul (Radd m m) (ofQ q hq))) := by
  refine Req_trans (Rmul_congr (Req_symm (Rsub_Radd_Radd l l m m)) (Req_refl _)) ?_
  refine Req_trans (Rmul_sub_distrib_right (Radd l l) (Radd m m) (ofQ q hq)) ?_
  refine Rsub_congr ?_ (Req_refl _)
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (ofQ_congr hq (Qmul_den_pos hM hw) hsplit)
      (Req_symm (Rmul_ofQ_ofQ hM hw)))) ?_
  refine Req_trans (Rmul_comm _ _) ?_
  refine Req_trans (Rmul_assoc (ofQ Mq hM) (ofQ w hw) (Radd l l)) ?_
  exact Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _) (Req_refl _))

set_option maxHeartbeats 1600000 in
/-- **The Riemann fold**: `Σ_{i<k} gLx(i/(N+1)) ≈ (N+1)·hsSample(c(N+1), k) −
    2log(N+1)·harmTermFoldC(k)` for `k ≤ N+1`. -/
theorem RsumN_gLx (c N : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    ∀ k, k ≤ N + 1 →
    Req (RsumN (fun i => gLx c (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) k)
      (Rsub (Rmul (ofQ (⟨((N + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)
          (hsSample (c * (N + 1)) (Nat.mul_pos hc1 (Nat.succ_pos N)) k))
        (Rmul (Radd (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N)))
          (ofQ (harmTermFoldC c N k) (harmTermFoldC_den_pos c N hc1 k))))
  | 0, _ => by
    refine Req_symm (Req_trans (y := Rsub zero zero) (Rsub_congr
      (Rmul_zero (ofQ (⟨((N + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos))
      (Rmul_zero (Radd (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N)))))
      (Radd_neg zero))
  | (k + 1), hk => by
    have hk' : k ≤ N + 1 := Nat.le_of_succ_le hk
    have ha1 : 1 ≤ c * (N + 1) + k :=
      Nat.le_trans (Nat.le_trans (Nat.succ_pos N) (Nat.le_mul_of_pos_left (N + 1) hc1))
        (Nat.le_add_right _ k)
    have hqd : 0 < c * (N + 1) + k := ha1
    have hsplit : Qeq (⟨((N + 1 : Nat) : Int), c * (N + 1) + k⟩ : Q)
        (mul (⟨((N + 1 : Nat) : Int), 1⟩ : Q) (⟨1, c * (N + 1) + k⟩ : Q)) := by
      simp only [Qeq, mul]; push_cast; ring_uor
    show Req (Radd (RsumN _ k) (gLx c (ofQ (⟨(k : Int), N + 1⟩ : Q) (Nat.succ_pos N)))) _
    refine Req_trans (Radd_congr (RsumN_gLx c N hc1 hc3 k hk')
      (Req_trans (gLx_point c hc1 hc3 k N hk' ha1)
        (lxs_regroup (logN (c * (N + 1) + k) ha1) (logN (N + 1) (Nat.succ_pos N))
          (⟨((N + 1 : Nat) : Int), 1⟩ : Q) (⟨1, c * (N + 1) + k⟩ : Q)
          (⟨((N + 1 : Nat) : Int), c * (N + 1) + k⟩ : Q)
          Nat.one_pos hqd hqd hsplit))) ?_
    -- (S_k) + (M·cell − LM2·q) ≈ (M·hs_k + M·cell) − (LM2·hf_k + LM2·q)
    refine Req_trans (Req_symm (Rsub_Radd_Radd
      (Rmul (ofQ (⟨((N + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)
        (hsSample (c * (N + 1)) (Nat.mul_pos hc1 (Nat.succ_pos N)) k))
      (Rmul (ofQ (⟨((N + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos)
        (Rmul (ofQ (⟨1, c * (N + 1) + k⟩ : Q) hqd)
          (Radd (logN (c * (N + 1) + k) ha1) (logN (c * (N + 1) + k) ha1))))
      (Rmul (Radd (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N)))
        (ofQ (harmTermFoldC c N k) (harmTermFoldC_den_pos c N hc1 k)))
      (Rmul (Radd (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N)))
        (ofQ (⟨((N + 1 : Nat) : Int), c * (N + 1) + k⟩ : Q) hqd)))) ?_
    refine Rsub_congr (Req_symm (Rmul_distrib _ _ _)) ?_
    refine Req_trans (Req_symm (Rmul_distrib _ _ _)) ?_
    refine Rmul_congr (Req_refl _) ?_
    exact Radd_ofQ_ofQ (harmTermFoldC_den_pos c N hc1 k) hqd

/-- The scalar cancellation `(1/(N+1))·((N+1)·X) ≈ X` (private copy of the
    `LogRiemann` pattern). -/
private theorem lxs_inv_collapse (N : Nat) (X : Real) :
    Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
        (Rmul (ofQ (⟨((N + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) X)) X := by
  refine Req_trans (Req_symm (Rmul_assoc _ _ X)) ?_
  refine Req_trans (Rmul_congr (Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N) Nat.one_pos)
    (ofQ_congr (b := (⟨1, 1⟩ : Q)) (Qmul_den_pos (Nat.succ_pos N) Nat.one_pos)
      (by decide) ?_)) (Req_refl X)) ?_
  · show Qeq (mul (⟨1, N + 1⟩ : Q) (⟨((N + 1 : Nat) : Int), 1⟩ : Q)) (⟨1, 1⟩ : Q)
    simp only [Qeq, mul]; push_cast; ring_uor
  · exact Rone_mul X

/-- **The collapse**: `riemannSum (gLx c) N ≈ hsSample(c(N+1), N+1) −
    2log(N+1)·hFold(c(N+1), N+1)` — the `(N+1)` prefactor cancels, and the harmonic
    fold rescales (`harmTermFoldC_scale`). -/
theorem riemannSum_gLx (c N : Nat) (hc1 : 1 ≤ c) (hc3 : c ≤ 3) :
    Req (riemannSum (gLx c) N)
      (Rsub (hsSample (c * (N + 1)) (Nat.mul_pos hc1 (Nat.succ_pos N)) (N + 1))
        (Rmul (Radd (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N)))
          (ofQ (hFold (c * (N + 1)) (N + 1))
            (hFold_den_pos (c * (N + 1)) (Nat.mul_pos hc1 (Nat.succ_pos N)) (N + 1))))) := by
  show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
    (RsumN (fun i => gLx c (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) _
  refine Req_trans (Rmul_congr (Req_refl _)
    (RsumN_gLx c N hc1 hc3 (N + 1) (Nat.le_refl _))) ?_
  refine Req_trans (Rmul_sub_distrib (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) _ _) ?_
  refine Rsub_congr (lxs_inv_collapse N _) ?_
  -- `(1/(N+1))·(LM2·harmFold) ≈ LM2·((1/(N+1))·harmFold) ≈ LM2·hFold`
  refine Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_
  refine Req_trans (Rmul_congr (Rmul_comm _ _) (Req_refl _)) ?_
  refine Req_trans (Rmul_assoc _ _ _) ?_
  refine Rmul_congr (Req_refl _) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Nat.succ_pos N) (harmTermFoldC_den_pos c N hc1 (N + 1))) ?_
  exact ofQ_congr (Qmul_den_pos (Nat.succ_pos N) (harmTermFoldC_den_pos c N hc1 (N + 1)))
    (hFold_den_pos (c * (N + 1)) (Nat.mul_pos hc1 (Nat.succ_pos N)) (N + 1))
    (harmTermFoldC_scale c N hc1 (N + 1))

end UOR.Bridge.F1Square.Analysis
