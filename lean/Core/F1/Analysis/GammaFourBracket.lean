/-
F1 square — stage F: **foundations of the `γ₄` numeric bracket** (the sole remaining `n = 5` gate,
toward `Pos λ₅`), via DISCRETE Euler–Maclaurin (NO constructive integration).

The companion-in-progress of `GammaFour.lean` (which built `γ₄ = Rlim g4SeqDyadic`).  THIS FILE builds
the two foundations the bracket rests on:

  (1) the **quartic log cap** `(ln p)⁴ ≤ 256·p` (`logQuart_le_self256`), completing the
      polynomial-log cap family (`logSq_le_self4`, `logCube_le_self27`); the `(ln p)⁴` factor in the
      bracket's leading `b⁴·C2` term is killed by this cap against the `C2 = Θ(1/p³)` trapezoidal
      smallness, giving a CONSTANT per-step bound `sStep4 ≤ C/(p(p+1))` (no log growth);

  (2) the **further-accelerated sequence** `hSeq4 j = g₄(j) − ½·(ln(j+1))⁴/(j+1)` (`→ γ₄`) and its
      per-step trapezoidal residual `sStep4 = O((ln p)⁴/p³)` (`sStep4`, `hSeq4_step_eq`).

What remains (the documented continuation): the `a = b+δ` decomposition
`decompForm4 = b⁴C2 + b³R2 + b²R1 + b·R0 + R0'` (`sStep4 ≈ decompForm4`, the quartic/quintic-binomial
algebra), the per-step bound `sStep4 ≤ C/(p(p+1))`, the telescope `γ₄ ≤ hSeq4(N) + C/(N+1)`, and the
rational evaluator `decide` — exactly the `GammaThreeBracket` ladder one degree up.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.GammaFour
import Core.F1.Analysis.GammaThreeBracket

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- The quartic cap `(ln p)⁴ ≤ 256·p`.  With `L = ln p ≥ 0`, `M = L/4`:
-- `exp(M) ≥ 1+M ≥ M ≥ 0`, so `exp(L) = exp(4M) = exp(M)⁴ ≥ M⁴`, hence `256·exp(L) ≥ 256·M⁴ = L⁴`.
-- ===========================================================================

/-- **`(a·x)⁴ ≈ a⁴·x⁴`** (quart of a product splits) — `cube_prod_split` plus one reassoc. -/
theorem quart_prod_split (a x : Real) :
    Req (Rmul (Rmul (Rmul (Rmul a x) (Rmul a x)) (Rmul a x)) (Rmul a x))
        (Rmul (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul x x) x) x)) := by
  refine Req_trans (Rmul_congr (cube_prod_split a x) (Req_refl (Rmul a x))) ?_
  refine Req_trans (Rmul_assoc (Rmul (Rmul a a) a) (Rmul (Rmul x x) x) (Rmul a x)) ?_
  refine Req_trans (Rmul_congr (Req_refl (Rmul (Rmul a a) a))
    (Rmul_left_comm3 (Rmul (Rmul x x) x) a x)) ?_
  exact Req_symm (Rmul_assoc (Rmul (Rmul a a) a) a (Rmul (Rmul (Rmul x x) x) x))

/-- **`L⁴ ≤ 256·exp(L)`** for `L ≥ 0`.  With `M = L/4`: `exp(M) ≥ M ≥ 0`, so
    `exp(L) = exp(M+M+M+M) = exp(M)⁴ ≥ M⁴`, and `256·M⁴ = L⁴`. -/
theorem quart_le_256_exp (L : Real) (hL : Rnonneg L) :
    Rle (Rmul (Rmul (Rmul L L) L) L) (Rmul (ofQ (⟨256, 1⟩ : Q) (by decide)) (RexpReal L)) := by
  have hMnn : Rnonneg (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) hL
  have hEnn : Rnonneg (RexpReal (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)) := RexpReal_nonneg _
  have hMleE : Rle (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)
      (RexpReal (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)) :=
    Rle_trans (Rle_self_Radd_left Rnonneg_one) (RexpReal_ge_one_add_nonneg hMnn)
  -- M⁴ ≤ E⁴
  have hquart := quartic_mono hMnn hEnn hMleE
  -- M+M+M+M ≈ L
  have hcoef : Req (Radd (Radd (Radd (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)
        (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)) (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L))
      (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)) L := by
    refine Req_trans (Radd_congr (Radd_congr (Req_symm (Rmul_distrib_right _ _ L)) (Req_refl _))
      (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Req_symm (Rmul_distrib_right _ _ L)) (Req_refl _)) ?_
    refine Req_trans (Req_symm (Rmul_distrib_right _ _ L)) ?_
    refine Req_trans (Rmul_congr ?_ (Req_refl L)) (Rone_mul L)
    refine Req_trans (Radd_congr (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _))
      (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _)) ?_
    exact Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  -- E⁴ ≈ exp(L)
  have hE4 : Req (Rmul (Rmul (Rmul (RexpReal (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L))
          (RexpReal (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)))
        (RexpReal (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)))
        (RexpReal (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L))) (RexpReal L) := by
    refine Req_trans (Rmul_congr (Rmul_congr (Req_symm (RexpReal_add _ _)) (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Rmul_congr (Req_symm (RexpReal_add _ _)) (Req_refl _)) ?_
    exact Req_trans (Req_symm (RexpReal_add _ _)) (RexpReal_congr hcoef)
  -- L⁴ ≈ 256·M⁴
  have hconst : Req (Rmul (ofQ (⟨256, 1⟩ : Q) (by decide))
      (Rmul (Rmul (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))
        (ofQ (⟨1, 4⟩ : Q) (by decide))) (ofQ (⟨1, 4⟩ : Q) (by decide)))) one := by
    refine Req_trans (Rmul_congr (Req_refl _)
        (Req_trans (Rmul_congr (Rmul_congr (Rmul_ofQ_ofQ (by decide) (by decide)) (Req_refl _))
          (Req_refl _)) (Req_trans (Rmul_congr (Rmul_ofQ_ofQ (by decide) (by decide)) (Req_refl _))
            (Rmul_ofQ_ofQ (by decide) (by decide))))) ?_
    exact Req_trans (Rmul_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (by decide) (by decide) (by decide))
  have hL4 : Req (Rmul (Rmul (Rmul L L) L) L)
      (Rmul (ofQ (⟨256, 1⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L) (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L))
            (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L)) (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) L))) := by
    refine Req_symm ?_
    refine Req_trans (Rmul_congr (Req_refl _) (quart_prod_split (ofQ (⟨1, 4⟩ : Q) (by decide)) L)) ?_
    refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨256, 1⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))
          (ofQ (⟨1, 4⟩ : Q) (by decide))) (ofQ (⟨1, 4⟩ : Q) (by decide))) (Rmul (Rmul (Rmul L L) L) L))) ?_
    exact Req_trans (Rmul_congr hconst (Req_refl _)) (Rone_mul _)
  refine Rle_trans (Rle_of_Req hL4) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hquart) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) hE4)

/-- **`(ln p)⁴ ≤ 256·p`** — the quartic cap (`logQuartic p ≤ 256p`), via `quart_le_256_exp` and
    `exp(ln p) = p`.  Completes the polynomial-log cap family (`logSq_le_self4`, `logCube_le_self27`). -/
theorem logQuart_le_self256 (p : Nat) (hp : 1 ≤ p) :
    Rle (logQuartic p hp) (ofQ (⟨256 * (p : Int), 1⟩ : Q) Nat.one_pos) := by
  unfold logQuartic logCube
  refine Rle_trans (quart_le_256_exp (logN p hp) (Rnonneg_logN p hp)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _) (Rexp_logN p hp))) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide) Nat.one_pos)
    (ofQ_congr (Qmul_den_pos (by decide) Nat.one_pos) Nat.one_pos
      (by show Qeq (mul (⟨256, 1⟩ : Q) (⟨(p : Int), 1⟩ : Q)) (⟨256 * (p : Int), 1⟩ : Q)
          simp only [Qeq, mul])))

-- ===========================================================================
-- The accelerated sequence `hSeq4 j = g₄(j) − ½·(ln(j+1))⁴/(j+1)` and its per-step residual `sStep4`.
-- ===========================================================================

/-- The trapezoidal-corrected sequence `hSeq4 j = g₄(j) − ½·(ln(j+1))⁴/(j+1)` (`→ γ₄`). -/
def hSeq4 (j : Nat) : Real :=
  Rsub (g4Seq j) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (j + 1) (Nat.succ_pos j)))

/-- The **per-step trapezoidal residual** `s_p = ½[(ln(p+1))⁴/(p+1) + (ln p)⁴/p] − (1/5)[(ln(p+1))⁵ −
    (ln p)⁵]` (`p ≥ 1`) — `O((ln p)⁴/p³)`, the increment of `hSeq4`. -/
def sStep4 (p : Nat) (hp : 1 ≤ p) : Real :=
  Rsub (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (p + 1) (Nat.succ_pos p)))
             (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver p hp)))
       (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
         (Rsub (logQuintic (p + 1) (Nat.succ_pos p)) (logQuintic p hp)))

/-- **`hSeq4(j+1) − hSeq4 j ≈ s_{j+1}`** — the increment of the accelerated sequence is the trapezoidal
    residual (`g4Seq_step_eq` gives `e_{j+1}`; `half_add_self`/`resid_regroup` move the correction). -/
theorem hSeq4_step_eq (j : Nat) :
    Req (Rsub (hSeq4 (j + 1)) (hSeq4 j)) (sStep4 (j + 1) (Nat.succ_pos j)) := by
  unfold hSeq4 sStep4
  refine Req_trans (Rsub_sub_sub (g4Seq (j + 1))
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (j + 2) (Nat.succ_pos (j + 1))))
    (g4Seq j) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (j + 1) (Nat.succ_pos j)))) ?_
  refine Req_trans (Rsub_congr (g4Seq_step_eq j) (Req_refl _)) ?_
  show Req
    (Rsub (Rsub (lnQuartOver (j + 2) (Nat.succ_pos (j + 1)))
        (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
          (Rsub (logQuintic (j + 2) (Nat.succ_pos (j + 1))) (logQuintic (j + 1) (Nat.succ_pos j)))))
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (j + 2) (Nat.succ_pos (j + 1))))
        (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (j + 1) (Nat.succ_pos j))))) _
  refine Req_trans (Rsub_congr
    (Rsub_congr (half_add_self (lnQuartOver (j + 2) (Nat.succ_pos (j + 1)))) (Req_refl _))
    (Req_refl _)) ?_
  exact resid_regroup (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (j + 2) (Nat.succ_pos (j + 1))))
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (j + 1) (Nat.succ_pos j)))
    (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
      (Rsub (logQuintic (j + 2) (Nat.succ_pos (j + 1))) (logQuintic (j + 1) (Nat.succ_pos j))))

/-- **The quartic binomial** `(b+d)⁴ ≈ b⁴ + 4·b³d + 6·b²d² + 4·bd³ + d⁴` (the `4`s/`6` as `ofQ`
    factors), mirroring `cube_binom` one degree up: start from `cube_binom`, distribute the trailing
    `(b+d)`, normalize the eight monomials with `Rmul_swap_last`/`Rmul_comm`/`Rmul_assoc`, then merge
    like terms via `three_plus_one`/`three_plus_three`/`one_plus_three`. -/
theorem quartic_binom (b d : Real) :
    Req (Rmul (Rmul (Rmul (Radd b d) (Radd b d)) (Radd b d)) (Radd b d))
        (Radd (Radd (Radd (Radd
                  (Rmul (Rmul (Rmul b b) b) b)
                  (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d)))
              (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)))
            (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)))
          (Rmul (Rmul (Rmul d d) d) d)) := by
  -- (b+d)³ = ((b³ + 3b²d) + 3bd²) + d³, call it C
  refine Req_trans (Rmul_congr (cube_binom b d) (Req_refl (Radd b d))) ?_
  -- distribute trailing (b+d): C·(b+d) = C·b + C·d
  refine Req_trans (Rmul_distrib
    (Radd (Radd (Radd (Rmul (Rmul b b) b)
              (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)))
      (Rmul (Rmul d d) d)) b d) ?_
  -- expand C·b into its four monomials, and C·d into its four monomials
  refine Req_trans (Radd_congr
    (Req_trans (Rmul_distrib_right (Radd (Radd (Rmul (Rmul b b) b)
              (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)))
        (Rmul (Rmul d d) d) b)
      (Radd_congr (Req_trans (Rmul_distrib_right (Radd (Rmul (Rmul b b) b)
              (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)) b)
        (Radd_congr (Rmul_distrib_right (Rmul (Rmul b b) b)
              (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)) b)
          (Req_refl _))) (Req_refl _)))
    (Req_trans (Rmul_distrib_right (Radd (Radd (Rmul (Rmul b b) b)
              (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)))
        (Rmul (Rmul d d) d) d)
      (Radd_congr (Req_trans (Rmul_distrib_right (Radd (Rmul (Rmul b b) b)
              (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)) d)
        (Radd_congr (Rmul_distrib_right (Rmul (Rmul b b) b)
              (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)) d)
          (Req_refl _))) (Req_refl _)))) ?_
  -- normalize the eight monomials.  Canonical: b⁴=((b·b)·b)·b, b³d=((b·b)·b)·d,
  -- b²d²=((b·b)·d)·d, bd³=((b·d)·d)·d, d⁴=((d·d)·d)·d.
  -- (3·X)·f → 3·(X·f) via Rmul_assoc, then normalize X·f.
  have e3b2d_b : Req (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)) b)
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d)) :=
    Req_trans (Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d) b)
      (Rmul_congr (Req_refl _) (Rmul_swap_last (Rmul b b) d b))
  have e3bd2_b : Req (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)) b)
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)) :=
    Req_trans (Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d) b)
      (Rmul_congr (Req_refl _)
        (Req_trans (Rmul_swap_last (Rmul b d) d b)
          (Rmul_congr (Rmul_swap_last b d b) (Req_refl d))))
  have ed3_b : Req (Rmul (Rmul (Rmul d d) d) b) (Rmul (Rmul (Rmul b d) d) d) :=
    Req_trans (Rmul_swap_last (Rmul d d) d b)
      (Rmul_congr (Req_trans (Rmul_swap_last d d b) (Rmul_congr (Rmul_comm d b) (Req_refl d)))
        (Req_refl d))
  have e3b2d_d : Req (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)) d)
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)) :=
    Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d) d
  have e3bd2_d : Req (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)) d)
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)) :=
    Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d) d
  refine Req_trans (Radd_congr
    (Radd_congr (Radd_congr (Radd_congr (Req_refl _) e3b2d_b) e3bd2_b) ed3_b)
    (Radd_congr (Radd_congr (Radd_congr (Req_refl _) e3b2d_d) e3bd2_d) (Req_refl _))) ?_
  -- now: ((b⁴ + 3b³d) + 3b²d²) + bd³  ++  ((b³d + 3b²d²) + 3bd³) + d⁴ ; flatten each 4-term side
  refine Req_trans (Radd_congr
    (Req_trans (Radd_congr (Radd_eq_RsumL3 (Rmul (Rmul (Rmul b b) b) b)
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)))
        (RsumL_singleton (Rmul (Rmul (Rmul b d) d) d)))
      (Req_symm (RsumL_append
        [Rmul (Rmul (Rmul b b) b) b,
         Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d),
         Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)]
        [Rmul (Rmul (Rmul b d) d) d])))
    (Req_trans (Radd_congr (Radd_eq_RsumL3 (Rmul (Rmul (Rmul b b) b) d)
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)))
        (RsumL_singleton (Rmul (Rmul (Rmul d d) d) d)))
      (Req_symm (RsumL_append
        [Rmul (Rmul (Rmul b b) b) d,
         Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
         Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)]
        [Rmul (Rmul (Rmul d d) d) d])))) ?_
  -- join the two RsumL's into one 8-list
  refine Req_trans (Req_symm (RsumL_append
    [Rmul (Rmul (Rmul b b) b) b,
     Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d),
     Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
     Rmul (Rmul (Rmul b d) d) d]
    [Rmul (Rmul (Rmul b b) b) d,
     Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
     Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d),
     Rmul (Rmul (Rmul d d) d) d])) ?_
  -- permute [A,B,C1,D,E,C2,G,H] → [A,B,E,C1,C2,D,G,H] (like terms adjacent)
  refine Req_trans (RsumL_perm
    (List.Perm.cons (Rmul (Rmul (Rmul b b) b) b) (List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      ((List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)) (List.Perm.swap (Rmul (Rmul (Rmul b b) b) d) (Rmul (Rmul (Rmul b d) d) d) [(Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)), (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)), (Rmul (Rmul (Rmul d d) d) d)])).trans
        ((List.Perm.swap (Rmul (Rmul (Rmul b b) b) d) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)) [(Rmul (Rmul (Rmul b d) d) d), (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)), (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)), (Rmul (Rmul (Rmul d d) d) d)]).trans
          (List.Perm.cons (Rmul (Rmul (Rmul b b) b) d) (List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
            (List.Perm.swap (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)) (Rmul (Rmul (Rmul b d) d) d) [(Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)), (Rmul (Rmul (Rmul d d) d) d)])))))))) ?_
  -- RsumL [A, 3b³d, b³d, 3b²d², 3b²d², bd³, 3bd³, d⁴]; merge adjacent like terms
  -- merge B+E = 3b³d + b³d → 4b³d
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (Rmul (Rmul (Rmul b b) b) d)
      (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
        (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
          (Radd (Rmul (Rmul (Rmul b d) d) d)
            (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
              (Radd (Rmul (Rmul (Rmul d d) d) d) zero)))))))) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_congr (three_plus_one (Rmul (Rmul (Rmul b b) b) d)) (Req_refl _))) ?_
  -- merge C1+C2 = 3b²d² + 3b²d² → 6b²d²
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
      (Radd (Rmul (Rmul (Rmul b d) d) d)
        (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
          (Radd (Rmul (Rmul (Rmul d d) d) d) zero))))))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (three_plus_three (Rmul (Rmul (Rmul b b) d) d)) (Req_refl _)))) ?_
  -- merge D+G = bd³ + 3bd³ → 4bd³
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (Rmul (Rmul b d) d) d)
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
      (Radd (Rmul (Rmul (Rmul d d) d) d) zero)))))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (one_plus_three (Rmul (Rmul (Rmul b d) d) d)) (Req_refl _))))) ?_
  -- strip trailing zero
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (Req_refl _) (Radd_zero (Rmul (Rmul (Rmul d d) d) d)))))) ?_
  -- right-nested  A·(F·(Sx·(Fo·H)))  →  left-nested  (((A·F)·Sx)·Fo)·H  (3 top-level reassocs)
  refine Req_trans (Req_symm (Radd_assoc (Rmul (Rmul (Rmul b b) b) b) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d)) (Radd (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)) (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)) (Rmul (Rmul (Rmul d d) d) d))))) ?_
  refine Req_trans (Req_symm (Radd_assoc (Radd (Rmul (Rmul (Rmul b b) b) b) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)) (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)) (Rmul (Rmul (Rmul d d) d) d)))) ?_
  exact Req_symm (Radd_assoc (Radd (Radd (Rmul (Rmul (Rmul b b) b) b) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)) (Rmul (Rmul (Rmul d d) d) d))

-- ===========================================================================
-- Coefficient-merge helpers for the degree-4 collection (`W4_expand`): the binomial coefficients
-- `1+4=5`, `4+1=5`, `4+6=10`, `6+4=10`.  Same pattern as `four_merge`/`three_plus_one`
-- (`GammaThreeBracket`): rewrite `x → 1·x`, factor `Rmul_distrib_right`, collapse the rational sum.
-- ===========================================================================

/-- `x + 4·x ≈ 5·x` (coefficient merge `1 + 4 = 5`). -/
theorem one_plus_four (x : Real) :
    Req (Radd x (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x)) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) x) := by
  have h5 : Req (Radd one (ofQ (⟨4, 1⟩ : Q) (by decide))) (ofQ (⟨5, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr hx1 (Req_refl _)) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right one (ofQ (⟨4, 1⟩ : Q) (by decide)) x))
    (Rmul_congr h5 (Req_refl x))

/-- `4·x + x ≈ 5·x` (coefficient merge `4 + 1 = 5`). -/
theorem four_plus_one (x : Real) :
    Req (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x) x) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) x) := by
  have h5 : Req (Radd (ofQ (⟨4, 1⟩ : Q) (by decide)) one) (ofQ (⟨5, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr (Req_refl _) hx1) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right (ofQ (⟨4, 1⟩ : Q) (by decide)) one x))
    (Rmul_congr h5 (Req_refl x))

/-- `4·x + 6·x ≈ 10·x` (coefficient merge `4 + 6 = 10`). -/
theorem four_plus_six (x : Real) :
    Req (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) x))
        (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) x) := by
  have h10 : Req (Radd (ofQ (⟨4, 1⟩ : Q) (by decide)) (ofQ (⟨6, 1⟩ : Q) (by decide)))
      (ofQ (⟨10, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, ofQ, add, Qeq]; push_cast
  exact Req_trans (Req_symm (Rmul_distrib_right (ofQ (⟨4, 1⟩ : Q) (by decide))
    (ofQ (⟨6, 1⟩ : Q) (by decide)) x)) (Rmul_congr h10 (Req_refl x))

/-- `6·x + 4·x ≈ 10·x` (coefficient merge `6 + 4 = 10`). -/
theorem six_plus_four (x : Real) :
    Req (Radd (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) x) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x))
        (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) x) := by
  have h10 : Req (Radd (ofQ (⟨6, 1⟩ : Q) (by decide)) (ofQ (⟨4, 1⟩ : Q) (by decide)))
      (ofQ (⟨10, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, ofQ, add, Qeq]; push_cast
  exact Req_trans (Req_symm (Rmul_distrib_right (ofQ (⟨6, 1⟩ : Q) (by decide))
    (ofQ (⟨4, 1⟩ : Q) (by decide)) x)) (Rmul_congr h10 (Req_refl x))

/-- Left-nested degree-4 sum flattening: `(((x+y)+z)+w) ≈ RsumL [x,y,z,w]`. -/
theorem Radd_eq_RsumL4 (x y z w : Real) :
    Req (Radd (Radd (Radd x y) z) w) (RsumL [x, y, z, w]) :=
  Req_trans (Radd_congr (Radd_eq_RsumL3 x y z) (RsumL_singleton w))
    (Req_symm (RsumL_append [x, y, z] [w]))

/-- Left-nested degree-5 sum flattening: `((((x+y)+z)+w)+v) ≈ RsumL [x,y,z,w,v]`. -/
theorem Radd_eq_RsumL5 (x y z w v : Real) :
    Req (Radd (Radd (Radd (Radd x y) z) w) v) (RsumL [x, y, z, w, v]) :=
  Req_trans (Radd_congr (Radd_eq_RsumL4 x y z w) (RsumL_singleton v))
    (Req_symm (RsumL_append [x, y, z, w] [v]))

/-- **The degree-4 aligned-polynomial adder.**  Adds the `a⁴` expansion (5 coeff-monomials)
    to the `W₃·b` expansion (4 coeff-monomials, same degree order) and merges the binomial
    coefficients (`1+4=5`, `4+6=10`, `6+4=10`, `4+1=5`) — the degree-4 analogue of `W_collect`. -/
theorem W4_collect (b d : Real) :
    Req (Radd
          (Radd (Radd (Radd (Radd
                    (Rmul (Rmul (Rmul b b) b) b)
                    (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d)))
                  (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)))
                (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)))
              (Rmul (Rmul (Rmul d d) d) d))
          (Radd (Radd (Radd
                    (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
                    (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d)))
                  (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)))
                (Rmul (Rmul (Rmul b d) d) d)))
        (Radd (Radd (Radd (Radd
                  (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
                  (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d)))
                (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)))
              (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d)))
            (Rmul (Rmul (Rmul d d) d) d)) := by
  refine Req_trans (Radd_congr
    (Radd_eq_RsumL5 (Rmul (Rmul (Rmul b b) b) b)
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
      (Rmul (Rmul (Rmul d d) d) d))
    (Radd_eq_RsumL4
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
      (Rmul (Rmul (Rmul b d) d) d))) ?_
  refine Req_trans (Req_symm (RsumL_append
    [Rmul (Rmul (Rmul b b) b) b,
     Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d),
     Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
     Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d),
     Rmul (Rmul (Rmul d d) d) d]
    [Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b),
     Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d),
     Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
     Rmul (Rmul (Rmul b d) d) d])) ?_
  -- perm [B4,4B3d,6B2d2,4Bd3,D4,4B4,6B3d,4B2d2,Bd3] -> [B4,4B4,4B3d,6B3d,6B2d2,4B2d2,4Bd3,Bd3,D4]
  -- bubble 4B4 left (across D4,4Bd3,6B2d2,4B3d): 4 swaps
  have s1a := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
        (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
          (List.Perm.swap (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
            (Rmul (Rmul (Rmul d d) d) d)
            [Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d),
             Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
             Rmul (Rmul (Rmul b d) d) d]))))
  have s1b := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
        (List.Perm.swap (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
          [Rmul (Rmul (Rmul d d) d) d,
           Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d),
           Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
           Rmul (Rmul (Rmul b d) d) d])))
  have s1c := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (List.Perm.swap (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
        (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
        [Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d),
         Rmul (Rmul (Rmul d d) d) d,
         Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d),
         Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
         Rmul (Rmul (Rmul b d) d) d]))
  have s1d := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.swap (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      [Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
       Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d),
       Rmul (Rmul (Rmul d d) d) d,
       Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d),
       Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
       Rmul (Rmul (Rmul b d) d) d])
  -- now [B4,4B4,4B3d,6B2d2,4Bd3,D4,6B3d,4B2d2,Bd3]; bubble 6B3d left to pos3 (across D4,4Bd3,6B2d2): 3 swaps
  have s2a := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
        (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
          (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
            (List.Perm.swap (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
              (Rmul (Rmul (Rmul d d) d) d)
              [Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
               Rmul (Rmul (Rmul b d) d) d])))))
  have s2b := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
        (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
          (List.Perm.swap (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
            (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
            [Rmul (Rmul (Rmul d d) d) d,
             Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
             Rmul (Rmul (Rmul b d) d) d]))))
  have s2c := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
        (List.Perm.swap (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
          (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
          [Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d),
           Rmul (Rmul (Rmul d d) d) d,
           Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d),
           Rmul (Rmul (Rmul b d) d) d])))
  -- now [B4,4B4,4B3d,6B3d,6B2d2,4Bd3,D4,4B2d2,Bd3]; bubble 4B2d2 left to pos5 (across D4,4Bd3): 2 swaps
  have s3a := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
        (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
          (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
            (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
              (List.Perm.swap (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
                (Rmul (Rmul (Rmul d d) d) d)
                [Rmul (Rmul (Rmul b d) d) d]))))))
  have s3b := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
        (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
          (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
            (List.Perm.swap (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
              (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
              [Rmul (Rmul (Rmul d d) d) d,
               Rmul (Rmul (Rmul b d) d) d])))))
  -- now [B4,4B4,4B3d,6B3d,6B2d2,4B2d2,4Bd3,D4,Bd3]; bubble Bd3 left to pos7 (across D4): 1 swap
  have s4a := List.Perm.cons (Rmul (Rmul (Rmul b b) b) b)
    (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
        (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
          (List.Perm.cons (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
            (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
              (List.Perm.cons (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
                (List.Perm.swap (Rmul (Rmul (Rmul b d) d) d)
                  (Rmul (Rmul (Rmul d d) d) d) [])))))))
  refine Req_trans (RsumL_perm
    (((((((((s1a.trans s1b).trans s1c).trans s1d).trans s2a).trans s2b).trans s2c).trans s3a).trans s3b).trans s4a)) ?_
  -- now RsumL [B4,4B4,4B3d,6B3d,6B2d2,4B2d2,4Bd3,Bd3,D4]; merge pairs
  -- merge B4 + 4B4 = 5B4 (outermost, no Radd_congr)
  refine Req_trans (Req_symm (Radd_assoc (Rmul (Rmul (Rmul b b) b) b)
    (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
    (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (Radd (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
        (Radd (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
          (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
            (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
              (Radd (Rmul (Rmul (Rmul b d) d) d)
                (Radd (Rmul (Rmul (Rmul d d) d) d) zero))))))))) ?_
  refine Req_trans (Radd_congr (one_plus_four (Rmul (Rmul (Rmul b b) b) b)) (Req_refl _)) ?_
  -- merge 4B3d + 6B3d = 10B3d (depth 1)
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
      (Radd (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
        (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
          (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
            (Radd (Rmul (Rmul (Rmul b d) d) d)
              (Radd (Rmul (Rmul (Rmul d d) d) d) zero)))))))) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_congr (four_plus_six (Rmul (Rmul (Rmul b b) b) d)) (Req_refl _))) ?_
  -- merge 6B2d2 + 4B2d2 = 10B2d2 (depth 2)
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
      (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
        (Radd (Rmul (Rmul (Rmul b d) d) d)
          (Radd (Rmul (Rmul (Rmul d d) d) d) zero))))))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (six_plus_four (Rmul (Rmul (Rmul b b) d) d)) (Req_refl _)))) ?_
  -- merge 4Bd3 + Bd3 = 5Bd3 (depth 3)
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
      (Rmul (Rmul (Rmul b d) d) d)
      (Radd (Rmul (Rmul (Rmul d d) d) d) zero)))))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (four_plus_one (Rmul (Rmul (Rmul b d) d) d)) (Req_refl _))))) ?_
  -- strip trailing zero on D4 (depth 4)
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (Req_refl _) (Radd_zero (Rmul (Rmul (Rmul d d) d) d)))))) ?_
  -- right-nested -> left-nested target (4 top-level reassocs)
  refine Req_trans (Req_symm (Radd_assoc (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
    (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d))
    (Radd (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
      (Radd (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
        (Rmul (Rmul (Rmul d d) d) d))))) ?_
  refine Req_trans (Req_symm (Radd_assoc
    (Radd (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
      (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d)))
    (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d))
    (Radd (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
      (Rmul (Rmul (Rmul d d) d) d)))) ?_
  exact Req_symm (Radd_assoc
    (Radd (Radd (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
        (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) d)))
      (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) d) d)))
    (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b d) d) d))
    (Rmul (Rmul (Rmul d d) d) d))

/-- **W₄-expansion** `W₄ = a⁴ + a³b + a²b² + ab³ + b⁴ ≈ 5b⁴ + 10b³δ + 10b²δ² + 5bδ³ + δ⁴`
    (`δ = a − b`), the degree-4 analogue of `W_expand`, for the `partC` of the `γ₄` bracket.
    Factor `·b` out of the last four terms to expose `W₃·b` (via `W_expand`); add `a⁴` (via
    `quartic_binom`); flatten, group like terms, and merge the coefficients (`1+4=5`, `4+6=10`,
    `6+4=10`, `4+1=5`). -/
theorem W4_expand (a b : Real) :
    Req (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
            (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b))
          (Rmul (Rmul (Rmul b b) b) b))
        (Radd (Radd (Radd (Radd
                  (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
                  (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
              (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
            (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))))
          (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b))) := by
  have ha := sub_add_cancel_real a b
  -- a⁴ ≈ b⁴ + 4b³δ + 6b²δ² + 4bδ³ + δ⁴
  have ha4 : Req (Rmul (Rmul (Rmul a a) a) a)
      (Radd (Radd (Radd (Radd
                (Rmul (Rmul (Rmul b b) b) b)
                (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
              (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
            (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))))
          (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b))) :=
    Req_trans (Rmul_congr (Rmul_congr (Rmul_congr ha ha) ha) ha) (quartic_binom b (Rsub a b))
  -- S2 = (((a³b + a²b²) + ab³) + b⁴) ≈ ((a³+a²b)+ab²)+b³)·b  (factor `·b` out)
  have hfac : Req (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) b) (Rmul (Rmul (Rmul a a) b) b))
            (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b))
      (Rmul (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
            (Rmul (Rmul b b) b)) b) := by
    refine Req_trans (Radd_congr (Radd_congr
        (Req_symm (Rmul_distrib_right (Rmul (Rmul a a) a) (Rmul (Rmul a a) b) b)) (Req_refl _))
        (Req_refl _)) ?_
    refine Req_trans (Radd_congr
        (Req_symm (Rmul_distrib_right (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b) b))
        (Req_refl _)) ?_
    exact Req_symm (Rmul_distrib_right
      (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b)) (Rmul (Rmul b b) b) b)
  -- inner W₃ ≈ 4b³ + 6b²δ + 4bδ² + δ³  (via W_expand)
  -- then distribute ·b and normalize → 4b⁴ + 6b³δ + 4b²δ² + bδ³
  have hbd2b : Req (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) b)
      (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b)) :=
    Req_trans (Rmul_swap_last (Rmul b (Rsub a b)) (Rsub a b) b)
      (Rmul_congr (Rmul_swap_last b (Rsub a b) b) (Req_refl (Rsub a b)))
  have hd3b : Req (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) b)
      (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b)) :=
    Req_trans (Rmul_swap_last (Rmul (Rsub a b) (Rsub a b)) (Rsub a b) b)
      (Rmul_congr (Req_trans (Rmul_swap_last (Rsub a b) (Rsub a b) b)
          (Rmul_congr (Rmul_comm (Rsub a b) b) (Req_refl (Rsub a b))))
        (Req_refl (Rsub a b)))
  have hS2 : Req (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) b) (Rmul (Rmul (Rmul a a) b) b))
            (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b))
      (Radd (Radd (Radd
                (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
                (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
              (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
            (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))) := by
    refine Req_trans hfac ?_
    refine Req_trans (Rmul_congr (W_expand a b) (Req_refl b)) ?_
    -- distribute ·b over the 4-term W₃ output
    refine Req_trans (Rmul_distrib_right
      (Radd (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
              (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
            (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
      (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) b) ?_
    refine Req_trans (Radd_congr (Rmul_distrib_right
      (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
            (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))) b) (Req_refl _)) ?_
    refine Req_trans (Radd_congr (Radd_congr (Rmul_distrib_right
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
      (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))) b) (Req_refl _))
      (Req_refl _)) ?_
    -- normalize the four monomials
    refine Radd_congr (Radd_congr (Radd_congr ?_ ?_) ?_) hd3b
    · -- (4·b³)·b → 4·b⁴
      exact Rmul_assoc (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b) b
    · -- (6·b²δ)·b → 6·b³δ
      exact Req_trans (Rmul_assoc (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b)) b)
        (Rmul_congr (Req_refl _) (Rmul_swap_last (Rmul b b) (Rsub a b) b))
    · -- (4·bδ²)·b → 4·b²δ²
      exact Req_trans (Rmul_assoc (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b)) b)
        (Rmul_congr (Req_refl _) hbd2b)
  -- regroup W₄ = a⁴ + (((a³b+a²b²)+ab³)+b⁴) = a⁴ + S2
  refine Req_trans (Radd_congr (Radd_congr
      (Radd_assoc (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b)
        (Rmul (Rmul (Rmul a a) b) b)) (Req_refl (Rmul (Rmul (Rmul a b) b) b)))
      (Req_refl (Rmul (Rmul (Rmul b b) b) b))) ?_
  refine Req_trans (Radd_congr
      (Radd_assoc (Rmul (Rmul (Rmul a a) a) a)
        (Radd (Rmul (Rmul (Rmul a a) a) b) (Rmul (Rmul (Rmul a a) b) b))
        (Rmul (Rmul (Rmul a b) b) b)) (Req_refl (Rmul (Rmul (Rmul b b) b) b))) ?_
  refine Req_trans (Radd_assoc (Rmul (Rmul (Rmul a a) a) a)
      (Radd (Radd (Rmul (Rmul (Rmul a a) a) b) (Rmul (Rmul (Rmul a a) b) b))
        (Rmul (Rmul (Rmul a b) b) b)) (Rmul (Rmul (Rmul b b) b) b)) ?_
  -- now: a⁴ + S2; collect via the aligned-polynomial adder `W4_collect`
  exact Req_trans (Radd_congr ha4 hS2) (W4_collect b (Rsub a b))

-- ===========================================================================
-- Coefficient-collapse helpers for the degree-4 part expansions (`partA4`/`partC4`):
-- `½·4 = 2`, `½·6 = 3` (for `partA4`); `(1/5)·5 = 1`, `(1/5)·10 = 2` (for `partC4`).
-- Same pattern as `half_three`/`quarter_six` (`GammaThreeBracket`).
-- ===========================================================================

/-- **`½·(4·x) ≈ 2·x`** — the coefficient collapse `½·4 = 2`. -/
theorem half_four (x : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x) := by
  have hc : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨4, 1⟩ : Q) (by decide)))
      (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  exact Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨4, 1⟩ : Q) (by decide)) x))
    (Rmul_congr hc (Req_refl x))

/-- **`½·(6·x) ≈ 3·x`** — the coefficient collapse `½·6 = 3`. -/
theorem half_six (x : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) x))
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x) := by
  have hc : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨6, 1⟩ : Q) (by decide)))
      (ofQ (⟨3, 1⟩ : Q) (by decide)) :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  exact Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨6, 1⟩ : Q) (by decide)) x))
    (Rmul_congr hc (Req_refl x))

/-- **`(1/5)·(5·x) ≈ x`** — the coefficient collapse `(1/5)·5 = 1`. -/
theorem fifth_five (x : Real) :
    Req (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide)) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) x)) x := by
  have hc : Req (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨5, 1⟩ : Q) (by decide))) one :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  exact Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨5, 1⟩ : Q) (by decide)) x))
    (Req_trans (Rmul_congr hc (Req_refl x)) (Rone_mul x))

/-- **`(1/5)·(10·x) ≈ 2·x`** — the coefficient collapse `(1/5)·10 = 2`. -/
theorem fifth_ten (x : Real) :
    Req (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide)) (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) x))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x) := by
  have hc : Req (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨10, 1⟩ : Q) (by decide)))
      (ofQ (⟨2, 1⟩ : Q) (by decide)) :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  exact Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 5⟩ : Q) (by decide)) (ofQ (⟨10, 1⟩ : Q) (by decide)) x))
    (Rmul_congr hc (Req_refl x))

/-- **PART A** of `lhsForm4`: `½·a⁴·u1 → ½b⁴u1 + 2b³δu1 + 3b²δ²u1 + 2bδ³u1 + ½δ⁴u1` (`a = b+δ`,
    `quartic_binom`, distribute, `½·4 = 2` / `½·6 = 3`), as the 5 canonical monomials
    (`δ = a − b`). -/
theorem partA4_eq (a b u1 : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul (Rmul a a) a) a) u1))
      (Radd (Radd (Radd (Radd
          (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1])
          (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1]))
          (RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1]))
          (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1]))
          (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1])) := by
  have ha := sub_add_cancel_real a b
  -- a⁴ ≈ b⁴ + 4b³δ + 6b²δ² + 4bδ³ + δ⁴
  have ha4 : Req (Rmul (Rmul (Rmul a a) a) a)
      (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul b b) b) b)
                (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
              (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
            (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))))
          (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b))) :=
    Req_trans (Rmul_congr (Rmul_congr (Rmul_congr ha ha) ha) ha) (quartic_binom b (Rsub a b))
  -- ½·(a⁴·u1): rewrite a⁴, distribute u1 then ½
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr ha4 (Req_refl u1))) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (Rmul_distrib_right (Radd (Radd (Radd (Rmul (Rmul (Rmul b b) b) b)
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
          (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))))
        (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)) u1)
      (Radd_congr (Req_trans (Rmul_distrib_right (Radd (Radd (Rmul (Rmul (Rmul b b) b) b)
            (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
            (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))) u1)
        (Radd_congr (Req_trans (Rmul_distrib_right (Radd (Rmul (Rmul (Rmul b b) b) b)
              (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
            (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))) u1)
          (Radd_congr (Rmul_distrib_right (Rmul (Rmul (Rmul b b) b) b)
            (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))) u1)
            (Req_refl _))) (Req_refl _))) (Req_refl _)))) ?_
  refine Req_trans (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Radd (Radd (Radd (Rmul (Rmul (Rmul (Rmul b b) b) b) u1)
          (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))) u1))
        (Rmul (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))) u1))
      (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))) u1))
    (Rmul (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)) u1)) ?_
  refine Req_trans (Radd_congr (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Radd (Radd (Rmul (Rmul (Rmul (Rmul b b) b) b) u1)
          (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))) u1))
        (Rmul (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))) u1))
    (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))) u1))
    (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Radd (Rmul (Rmul (Rmul (Rmul b b) b) b) u1)
        (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))) u1))
    (Rmul (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))) u1))
    (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Rmul (Rmul (Rmul (Rmul b b) b) b) u1)
    (Rmul (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))) u1))
    (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_
  -- now normalize the five monomials
  refine Radd_congr (Radd_congr (Radd_congr (Radd_congr ?_ ?_) ?_) ?_) ?_
  · exact Rmul_congr (Req_refl _) (Rmul_eq_RprodL5L b b b b u1)
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_assoc (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b)) u1))
      (Req_trans (half_four (Rmul (Rmul (Rmul (Rmul b b) b) (Rsub a b)) u1))
        (Rmul_congr (Req_refl _) (Rmul_eq_RprodL5L b b b (Rsub a b) u1)))
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_assoc (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b)) u1))
      (Req_trans (half_six (Rmul (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b)) u1))
        (Rmul_congr (Req_refl _) (Rmul_eq_RprodL5L b b (Rsub a b) (Rsub a b) u1)))
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_assoc (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b)) u1))
      (Req_trans (half_four (Rmul (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b)) u1))
        (Rmul_congr (Req_refl _) (Rmul_eq_RprodL5L b (Rsub a b) (Rsub a b) (Rsub a b) u1)))
  · exact Rmul_congr (Req_refl _)
      (Rmul_eq_RprodL5L (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b) u1)

/-- **PART C** of `lhsForm4`: `(1/5)·δ·W₄ → b⁴δ + 2b³δ² + 2b²δ³ + bδ⁴ + (1/5)δ⁵` (`δ = a−b`,
    `W₄ = a⁴+a³b+a²b²+ab³+b⁴`), the POSITIVE monomials.  `W4_expand`, distribute `δ` and `(1/5)`,
    collapse `(1/5)·5 = 1` / `(1/5)·10 = 2`, normalize. -/
theorem partC4_eq (a b : Real) :
    Req (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
          (Rmul (Rsub a b)
            (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
                  (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b))
              (Rmul (Rmul (Rmul b b) b) b))))
      (Radd (Radd (Radd (Radd (RprodL [b, b, b, b, Rsub a b])
            (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]))
          (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]))
          (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]))
        (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])) := by
  -- W₄ ≈ 5b⁴+10b³δ+10b²δ²+5bδ³+δ⁴
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl (Rsub a b)) (W4_expand a b))) ?_
  -- distribute δ over the 5-term sum
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (Rmul_distrib (Rsub a b)
        (Radd (Radd (Radd (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
            (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
          (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
          (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))))
        (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)))
      (Radd_congr (Req_trans (Rmul_distrib (Rsub a b)
          (Radd (Radd (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
              (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
            (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
          (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))))
        (Radd_congr (Req_trans (Rmul_distrib (Rsub a b)
            (Radd (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
              (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
            (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
          (Radd_congr (Rmul_distrib (Rsub a b)
            (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b))
            (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b)))) (Req_refl _)))
          (Req_refl _))) (Req_refl _)))) ?_
  -- distribute (1/5) over the 5-term sum
  refine Req_trans (Rmul_distrib (ofQ (⟨1, 5⟩ : Q) (by decide))
    (Radd (Radd (Radd (Rmul (Rsub a b) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b)))
          (Rmul (Rsub a b) (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b)))))
        (Rmul (Rsub a b) (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b)))))
      (Rmul (Rsub a b) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b)))))
    (Rmul (Rsub a b) (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)))) ?_
  refine Req_trans (Radd_congr (Rmul_distrib (ofQ (⟨1, 5⟩ : Q) (by decide))
    (Radd (Radd (Rmul (Rsub a b) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b)))
          (Rmul (Rsub a b) (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b)))))
        (Rmul (Rsub a b) (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b)))))
      (Rmul (Rsub a b) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b)))))
    (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Rmul_distrib (ofQ (⟨1, 5⟩ : Q) (by decide))
    (Radd (Rmul (Rsub a b) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b)))
        (Rmul (Rsub a b) (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b)))))
      (Rmul (Rsub a b) (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b)))))
    (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Rmul_distrib (ofQ (⟨1, 5⟩ : Q) (by decide))
    (Rmul (Rsub a b) (Rmul (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b)))
    (Rmul (Rsub a b) (Rmul (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b)))))
    (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_
  -- normalize the five monomials
  refine Radd_congr (Radd_congr (Radd_congr (Radd_congr ?_ ?_) ?_) ?_) ?_
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_left_comm3 (Rsub a b) (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) b)))
      (Req_trans (fifth_five (Rmul (Rsub a b) (Rmul (Rmul (Rmul b b) b) b)))
        (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul (Rmul b b) b) b))
          (Rmul_eq_RprodL5L b b b b (Rsub a b))))
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_left_comm3 (Rsub a b) (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
      (Req_trans (fifth_ten (Rmul (Rsub a b) (Rmul (Rmul (Rmul b b) b) (Rsub a b))))
        (Rmul_congr (Req_refl _)
          (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul (Rmul b b) b) (Rsub a b)))
            (Rmul_eq_RprodL5L b b b (Rsub a b) (Rsub a b)))))
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_left_comm3 (Rsub a b) (ofQ (⟨10, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
      (Req_trans (fifth_ten (Rmul (Rsub a b) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b))))
        (Rmul_congr (Req_refl _)
          (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul (Rmul b b) (Rsub a b)) (Rsub a b)))
            (Rmul_eq_RprodL5L b b (Rsub a b) (Rsub a b) (Rsub a b)))))
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_left_comm3 (Rsub a b) (ofQ (⟨5, 1⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))))
      (Req_trans (fifth_five (Rmul (Rsub a b) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b))))
        (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) (Rsub a b)))
          (Rmul_eq_RprodL5L b (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b))))
  · exact Rmul_congr (Req_refl _)
      (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)))
        (Rmul_eq_RprodL5L (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b)))

-- ===========================================================================
-- (C2b) The quintic residual decomposition `sStep4 ≈ decompForm4 = b⁴·C2 + b³·R3 + b²·R2 + b·R1 + R0`
-- (`d = a − b`, `C2 = ½(u0+u1) − d`, `R3 = 2·d·(u1−d)`, `R2 = d²·(3u1 − 2d)`, `R1 = d³·(2u1 − d)`,
-- `R0 = ½d⁴u1 − (1/5)d⁵`).
-- ===========================================================================

/-- The **stage-1 residual form** (`sStep4` after `quintic_diff_identity`), parameterized:
    `½a⁴u1 − ½b⁴u0 − (1/5)·(a−b)·(a⁴+a³b+a²b²+ab³+b⁴)`. -/
def lhsForm4 (a b u0 u1 : Real) : Real :=
  Rsub (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul (Rmul a a) a) a) u1))
             (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul (Rmul b b) b) b) u0)))
       (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
         (Rmul (Rsub a b)
           (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
                 (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b))
             (Rmul (Rmul (Rmul b b) b) b))))

/-- The **bound-ready decomposition** `b⁴·C2 + b³·R3 + b²·R2 + b·R1 + R0` of the trapezoidal residual
    (`d = a − b`, `C2 = ½(u0+u1) − d`, `R3 = 2·d·(u1−d)`, `R2 = d²·(3u1 − 2d)`, `R1 = d³·(2u1 − d)`,
    `R0 = ½d⁴u1 − (1/5)d⁵`). -/
def decompForm4 (a b u0 u1 : Real) : Real :=
  Radd (Radd (Radd (Radd
      (Rmul (Rmul (Rmul (Rmul b b) b) b)
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)))
      (Rmul (Rmul (Rmul b b) b)
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rsub u1 (Rsub a b))))))
      (Rmul (Rmul b b)
        (Rmul (Rmul (Rsub a b) (Rsub a b))
          (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) u1) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b))))))
      (Rmul b
        (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))
          (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) u1) (Rsub a b)))))
    (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (Rmul (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)) u1))
          (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
            (Rmul (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)) (Rsub a b))))

/-- Left-nested degree-6 flattening: `(((((x·y)·z)·w)·v)·t) ≈ RprodL [x,y,z,w,v,t]`. -/
theorem Rmul_eq_RprodL6L (x y z w v t : Real) :
    Req (Rmul (Rmul (Rmul (Rmul (Rmul x y) z) w) v) t) (RprodL [x, y, z, w, v, t]) :=
  Req_trans (Rmul_congr (Rmul_eq_RprodL5L x y z w v) (Req_refl t))
    (Req_trans (Rmul_congr (Req_refl (RprodL [x, y, z, w, v])) (Req_symm (Rmul_one t)))
      (Req_symm (RprodL_append [x, y, z, w, v] [t])))

/-- **Monomial normalizer `X·(c·u) → RprodL [x₁,x₂,x₃,x₄,c,u]`** where `X = ((x₁·x₂)·x₃)·x₄` is a
    left-nested quart: reassociate `X·(c·u) ≈ ((X·c)·u)` then flatten. -/
theorem quart_times_pair (x₁ x₂ x₃ x₄ c u : Real) :
    Req (Rmul (Rmul (Rmul (Rmul x₁ x₂) x₃) x₄) (Rmul c u))
        (RprodL [x₁, x₂, x₃, x₄, c, u]) :=
  Req_trans (Req_symm (Rmul_assoc (Rmul (Rmul (Rmul x₁ x₂) x₃) x₄) c u))
    (Rmul_eq_RprodL6L x₁ x₂ x₃ x₄ c u)

/-- **Monomial normalizer `((x₁·x₂)·x₃)·(c·(z·w)) → RprodL [x₁,x₂,x₃,c,z,w]`**. -/
theorem cube_times_triple (x₁ x₂ x₃ c z w : Real) :
    Req (Rmul (Rmul (Rmul x₁ x₂) x₃) (Rmul c (Rmul z w))) (RprodL [x₁, x₂, x₃, c, z, w]) :=
  Req_trans (Req_symm (Rmul_assoc (Rmul (Rmul x₁ x₂) x₃) c (Rmul z w)))
    (Req_trans (Req_symm (Rmul_assoc (Rmul (Rmul (Rmul x₁ x₂) x₃) c) z w))
      (Rmul_eq_RprodL6L x₁ x₂ x₃ c z w))

/-- **Monomial normalizer `(x·y)·((z₁·z₂)·(c·w)) → RprodL [x,y,z₁,z₂,c,w]`**. -/
theorem pair_times_sqpair (x y z₁ z₂ c w : Real) :
    Req (Rmul (Rmul x y) (Rmul (Rmul z₁ z₂) (Rmul c w))) (RprodL [x, y, z₁, z₂, c, w]) :=
  Req_trans (Req_symm (Rmul_assoc (Rmul x y) (Rmul z₁ z₂) (Rmul c w)))
    (Req_trans (Rmul_congr (Req_symm (Rmul_assoc (Rmul x y) z₁ z₂)) (Req_refl _))
      (Req_trans (Req_symm (Rmul_assoc (Rmul (Rmul (Rmul x y) z₁) z₂) c w))
        (Rmul_eq_RprodL6L x y z₁ z₂ c w)))

/-- **Monomial normalizer `x·(((z₁·z₂)·z₃)·(c·w)) → RprodL [x,z₁,z₂,z₃,c,w]`**. -/
theorem single_times_cubepair (x z₁ z₂ z₃ c w : Real) :
    Req (Rmul x (Rmul (Rmul (Rmul z₁ z₂) z₃) (Rmul c w))) (RprodL [x, z₁, z₂, z₃, c, w]) :=
  Req_trans (Req_symm (Rmul_assoc x (Rmul (Rmul z₁ z₂) z₃) (Rmul c w)))
    (Req_trans (Req_symm (Rmul_assoc (Rmul x (Rmul (Rmul z₁ z₂) z₃)) c w))
      (Req_trans (Rmul_congr (Rmul_congr (Req_symm (Rmul_assoc x (Rmul z₁ z₂) z₃)) (Req_refl _)) (Req_refl _))
        (Req_trans (Rmul_congr (Rmul_congr (Rmul_congr (Req_symm (Rmul_assoc x z₁ z₂)) (Req_refl _)) (Req_refl _)) (Req_refl _))
          (Rmul_eq_RprodL6L x z₁ z₂ z₃ c w))))

/-- **`decompForm4` expands to its 11 canonical monomials** (coefficient-first `RprodL`, `d = a − b`
    an atom): distribute each of the five grouped terms and normalize. -/
theorem decompForm4_eq_RsumL (a b u0 u1 : Real) :
    Req (decompForm4 a b u0 u1)
      (RsumL [ RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1],
               Rneg (RprodL [b, b, b, b, Rsub a b]),
               RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
               Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]),
               RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
               Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]),
               RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1],
               Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]),
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1],
               Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]) ]) := by
  -- hP : b⁴·(½(u0+u1) − d) ≈ RsumL [n1, n2, n3]
  have hn1 : Req (Rmul (Rmul (Rmul (Rmul b b) b) b) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u0))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0]) :=
    Req_trans (quart_times_pair b b b b (ofQ (⟨1, 2⟩ : Q) (by decide)) u0)
      (RprodL_perm
        ((((List.Perm.cons b (List.Perm.cons b (List.Perm.cons b
              (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [u0])))).trans
          (List.Perm.cons b (List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, u0])))).trans
          (List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, b, u0]))).trans
          (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, b, b, u0])))
  have hn2 : Req (Rmul (Rmul (Rmul (Rmul b b) b) b) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u1))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1]) :=
    Req_trans (quart_times_pair b b b b (ofQ (⟨1, 2⟩ : Q) (by decide)) u1)
      (RprodL_perm
        ((((List.Perm.cons b (List.Perm.cons b (List.Perm.cons b
              (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [u1])))).trans
          (List.Perm.cons b (List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, u1])))).trans
          (List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, b, u1]))).trans
          (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, b, b, u1])))
  have hPb : Req (Rmul (Rmul (Rmul (Rmul b b) b) b) (Rsub a b)) (RprodL [b, b, b, b, Rsub a b]) :=
    Rmul_eq_RprodL5L b b b b (Rsub a b)
  have hP : Req (Rmul (Rmul (Rmul (Rmul b b) b) b)
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)))
      (RsumL [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0],
              RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1],
              Rneg (RprodL [b, b, b, b, Rsub a b])]) := by
    refine Req_trans (Rmul_sub_distrib (Rmul (Rmul (Rmul b b) b) b)
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)) ?_
    refine Req_trans (Radd_congr ?_ (Rneg_congr hPb)) (Radd_eq_RsumL3 _ _ _)
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide)) u0 u1)) ?_
    refine Req_trans (Rmul_distrib (Rmul (Rmul (Rmul b b) b) b)
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u0) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u1)) ?_
    exact Radd_congr hn1 hn2
  -- hQ3 : b³·(2·(d·(u1−d))) ≈ RsumL [n4, n5]
  have hQ3a : Req (Rmul (Rmul (Rmul b b) b)
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rsub a b) u1)))
      (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1]) :=
    Req_trans (cube_times_triple b b b (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b) u1)
      (RprodL_perm
        (((List.Perm.cons b (List.Perm.cons b
            (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [Rsub a b, u1]))).trans
          (List.Perm.cons b (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [b, Rsub a b, u1]))).trans
          (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [b, b, Rsub a b, u1])))
  have hQ3b : Req (Rmul (Rmul (Rmul b b) b)
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rsub a b))))
      (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]) :=
    Req_trans (cube_times_triple b b b (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b) (Rsub a b))
      (RprodL_perm
        (((List.Perm.cons b (List.Perm.cons b
            (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [Rsub a b, Rsub a b]))).trans
          (List.Perm.cons b (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [b, Rsub a b, Rsub a b]))).trans
          (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [b, b, Rsub a b, Rsub a b])))
  have hQ3 : Req (Rmul (Rmul (Rmul b b) b)
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rsub u1 (Rsub a b)))))
      (RsumL [RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
              Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b])]) := by
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
      (Rmul_sub_distrib (Rsub a b) u1 (Rsub a b)))) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_sub_distrib (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rsub a b) u1)
        (Rmul (Rsub a b) (Rsub a b)))) ?_
    refine Req_trans (Rmul_sub_distrib (Rmul (Rmul b b) b)
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rsub a b) u1))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rsub a b)))) ?_
    exact Req_trans (Radd_congr hQ3a (Rneg_congr hQ3b)) (Radd_eq_RsumL _ _)
  -- hQ2 : b²·((d·d)·(3u1 − 2d)) ≈ RsumL [n6, n7]
  have hQ2a : Req (Rmul (Rmul b b)
        (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) u1)))
      (RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1]) :=
    Req_trans (pair_times_sqpair b b (Rsub a b) (Rsub a b) (ofQ (⟨3, 1⟩ : Q) (by decide)) u1)
      (RprodL_perm
        ((((List.Perm.cons b (List.Perm.cons b (List.Perm.cons (Rsub a b) (List.Perm.swap (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rsub a b) [u1])))).trans (List.Perm.cons b (List.Perm.cons b (List.Perm.swap (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rsub a b) [(Rsub a b), u1])))).trans (List.Perm.cons b (List.Perm.swap (ofQ (⟨3, 1⟩ : Q) (by decide)) b [(Rsub a b), (Rsub a b), u1]))).trans (List.Perm.swap (ofQ (⟨3, 1⟩ : Q) (by decide)) b [b, (Rsub a b), (Rsub a b), u1])))
  have hQ2b : Req (Rmul (Rmul b b)
        (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b))))
      (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]) :=
    Req_trans (pair_times_sqpair b b (Rsub a b) (Rsub a b) (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b))
      (RprodL_perm
        ((((List.Perm.cons b (List.Perm.cons b (List.Perm.cons (Rsub a b) (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b) [(Rsub a b)])))).trans (List.Perm.cons b (List.Perm.cons b (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b) [(Rsub a b), (Rsub a b)])))).trans (List.Perm.cons b (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [(Rsub a b), (Rsub a b), (Rsub a b)]))).trans (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [b, (Rsub a b), (Rsub a b), (Rsub a b)])))
  have hQ2 : Req (Rmul (Rmul b b)
        (Rmul (Rmul (Rsub a b) (Rsub a b))
          (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) u1) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b)))))
      (RsumL [RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
              Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b])]) := by
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_sub_distrib (Rmul (Rsub a b) (Rsub a b))
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) u1) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b)))) ?_
    refine Req_trans (Rmul_sub_distrib (Rmul b b)
      (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) u1))
      (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b)))) ?_
    exact Req_trans (Radd_congr hQ2a (Rneg_congr hQ2b)) (Radd_eq_RsumL _ _)
  -- hQ1 : b·(((d·d)·d)·(2u1 − d)) ≈ RsumL [n8, n9]
  have hQ1a : Req (Rmul b (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) u1)))
      (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1]) :=
    Req_trans (single_times_cubepair b (Rsub a b) (Rsub a b) (Rsub a b) (ofQ (⟨2, 1⟩ : Q) (by decide)) u1)
      (RprodL_perm
        ((((List.Perm.cons b (List.Perm.cons (Rsub a b) (List.Perm.cons (Rsub a b) (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b) [u1])))).trans (List.Perm.cons b (List.Perm.cons (Rsub a b) (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b) [(Rsub a b), u1])))).trans (List.Perm.cons b (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub a b) [(Rsub a b), (Rsub a b), u1]))).trans (List.Perm.swap (ofQ (⟨2, 1⟩ : Q) (by decide)) b [(Rsub a b), (Rsub a b), (Rsub a b), u1])))
  have hQ1b : Req (Rmul b (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)))
      (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]) :=
    Req_trans (Req_symm (Rmul_assoc b (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)))
      (Req_trans (Rmul_congr (Req_symm (Rmul_assoc b (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))) (Req_refl _))
        (Req_trans (Rmul_congr (Rmul_congr (Req_symm (Rmul_assoc b (Rsub a b) (Rsub a b))) (Req_refl _)) (Req_refl _))
          (Rmul_eq_RprodL5L b (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b))))
  have hQ1 : Req (Rmul b (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))
        (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) u1) (Rsub a b))))
      (RsumL [RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1],
              Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])]) := by
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_sub_distrib (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) u1) (Rsub a b))) ?_
    refine Req_trans (Rmul_sub_distrib b
      (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) u1))
      (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b))) ?_
    exact Req_trans (Radd_congr hQ1a (Rneg_congr hQ1b)) (Radd_eq_RsumL _ _)
  -- hQ0 : ½d⁴u1 − (1/5)d⁵ ≈ RsumL [n10, n11]
  have hQ0a : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)) u1))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1]) :=
    Rmul_congr (Req_refl _) (Rmul_eq_RprodL5L (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b) u1)
  have hQ0b : Req (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)) (Rsub a b)))
      (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]) :=
    Rmul_congr (Req_refl _) (Rmul_eq_RprodL5L (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b))
  have hQ0 : Req
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
              (Rmul (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)) u1))
            (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
              (Rmul (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)) (Rsub a b))))
      (RsumL [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1],
              Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])]) :=
    Req_trans (Radd_congr hQ0a (Rneg_congr hQ0b)) (Radd_eq_RsumL _ _)
  -- assemble: decompForm4 = Radd(Radd(Radd(Radd P Q3)Q2)Q1)Q0
  unfold decompForm4
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Radd_congr hP hQ3) hQ2) hQ1) hQ0) ?_
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1], Rneg (RprodL [b, b, b, b, Rsub a b])]
      [RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
       Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b])]))
      (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1], Rneg (RprodL [b, b, b, b, Rsub a b]),
       RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
       Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b])]
      [RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
       Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b])]))
      (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1], Rneg (RprodL [b, b, b, b, Rsub a b]),
       RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
       Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]),
       RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
       Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b])]
      [RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1],
       Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])])) (Req_refl _)) ?_
  exact Req_symm (RsumL_append
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1], Rneg (RprodL [b, b, b, b, Rsub a b]),
     RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
     Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]),
     RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
     Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]),
     RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1],
     Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])]
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1],
     Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])])


/-- **`lhsForm4` expands to its 11 canonical monomials** in the order
    `[n2,n4,n6,n8,n10, n1, n3,n5,n7,n9,n11]` (partA4 gives `n2,n4,n6,n8,n10`; `½b⁴u0 = n1`;
    `−partC4` gives `n3,n5,n7,n9,n11`). -/
theorem lhsForm4_eq_RsumL (a b u0 u1 : Real) :
    Req (lhsForm4 a b u0 u1)
      (RsumL [ RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1],
               RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
               RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
               RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0],
               Rneg (RprodL [b, b, b, b, Rsub a b]),
               Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]),
               Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]),
               Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]),
               Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]) ]) := by
  -- ½b⁴u0 ≈ n1
  have hb4u0 : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul (Rmul b b) b) b) u0))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0]) :=
    Rmul_congr (Req_refl _) (Rmul_eq_RprodL5L b b b b u0)
  -- −partC4 ≈ [n3,n5,n7,n9,n11]
  have hnegC : Req
      (Rneg (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
        (Rmul (Rsub a b)
          (Radd (Radd (Radd (Radd (Rmul (Rmul (Rmul a a) a) a) (Rmul (Rmul (Rmul a a) a) b))
                (Rmul (Rmul (Rmul a a) b) b)) (Rmul (Rmul (Rmul a b) b) b))
            (Rmul (Rmul (Rmul b b) b) b)))))
      (Radd (Radd (Radd (Radd (Rneg (RprodL [b, b, b, b, Rsub a b]))
              (Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b])))
            (Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b])))
          (Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])))
        (Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]))) := by
    refine Req_trans (Rneg_congr (partC4_eq a b)) ?_
    refine Req_trans (Rneg_Radd (Radd (Radd (Radd (RprodL [b, b, b, b, Rsub a b])
          (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]))
          (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]))
          (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]))
      (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])) ?_
    refine Radd_congr ?_ (Req_refl _)
    refine Req_trans (Rneg_Radd (Radd (Radd (RprodL [b, b, b, b, Rsub a b])
          (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]))
          (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]))
      (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])) ?_
    refine Radd_congr ?_ (Req_refl _)
    refine Req_trans (Rneg_Radd (Radd (RprodL [b, b, b, b, Rsub a b])
        (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]))
      (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b])) ?_
    exact Radd_congr (Rneg_Radd (RprodL [b, b, b, b, Rsub a b])
      (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b])) (Req_refl _)
  -- assemble: lhsForm4 = Radd (Radd (½a⁴u1) (½b⁴u0)) (Rneg partC4)
  unfold lhsForm4
  refine Req_trans (Radd_congr (Radd_congr (partA4_eq a b u1) hb4u0) hnegC) ?_
  -- PA = Radd(Radd(Radd(Radd n2 n4) n6) n8) n10 → RsumL[n2,n4,n6,n8,n10]
  have hPA : Req (Radd (Radd (Radd (Radd (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1])
        (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1]))
      (RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1]))
      (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1]))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1]))
      (RsumL [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1],
              RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
              RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
              RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1],
              RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1]]) :=
    Req_trans (Radd_congr (Radd_eq_RsumL4 _ _ _ _) (RsumL_singleton _))
      (Req_symm (RsumL_append
        [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1],
         RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
         RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
         RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1]]
        [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1]]))
  have hNC : Req (Radd (Radd (Radd (Radd (Rneg (RprodL [b, b, b, b, Rsub a b]))
          (Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b])))
        (Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b])))
        (Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])))
      (Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])))
      (RsumL [Rneg (RprodL [b, b, b, b, Rsub a b]),
              Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]),
              Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]),
              Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]),
              Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])]) :=
    Req_trans (Radd_congr (Radd_eq_RsumL4 _ _ _ _) (RsumL_singleton _))
      (Req_symm (RsumL_append
        [Rneg (RprodL [b, b, b, b, Rsub a b]),
         Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]),
         Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]),
         Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])]
        [Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])]))
  refine Req_trans (Radd_congr (Req_trans (Radd_congr hPA (RsumL_singleton _))
    (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1],
       RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
       RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
       RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1]]
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0]]))) hNC) ?_
  exact Req_symm (RsumL_append
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u1],
     RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, u1],
     RprodL [ofQ (⟨3, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, u1],
     RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, Rsub a b, Rsub a b, Rsub a b, u1],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, u1],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, b, u0]]
    [Rneg (RprodL [b, b, b, b, Rsub a b]),
     Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, b, Rsub a b, Rsub a b]),
     Rneg (RprodL [ofQ (⟨2, 1⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b, Rsub a b]),
     Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b, Rsub a b]),
     Rneg (RprodL [ofQ (⟨1, 5⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b, Rsub a b])])

/-- **The keystone identity** `lhsForm4 ≈ decompForm4` — both expand to the same 11 canonical monomials
    (`lhsForm4_eq_RsumL` / `decompForm4_eq_RsumL`), matched by the 11-element permutation
    `[n2,n4,n6,n8,n10,n1,n3,n5,n7,n9,n11] ~ [n1,…,n11]`. -/
theorem decomp_generic4 (a b u0 u1 : Real) :
    Req (lhsForm4 a b u0 u1) (decompForm4 a b u0 u1) := by
  refine Req_trans (lhsForm4_eq_RsumL a b u0 u1)
    (Req_trans (RsumL_perm ?_) (Req_symm (decompForm4_eq_RsumL a b u0 u1)))
  exact (((((((((((((((List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))))))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))))))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))))).trans (List.Perm.cons _ (List.Perm.swap _ _ _))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))).trans (List.Perm.swap _ _ _)

/-- **`sStep4 p ≈ decompForm4`** at the log/reciprocal atoms (`a = ln(p+1)`, `b = ln p`, `u0 = 1/p`,
    `u1 = 1/(p+1)`): `sStep4` matches `lhsForm4` on the nose except the quintic difference
    `(ln(p+1))⁵ − (ln p)⁵`, which `quintic_diff_identity` rewrites to `(a−b)(a⁴+a³b+a²b²+ab³+b⁴)`; then
    `decomp_generic4`. -/
theorem sStep4_decomp (p : Nat) (hp : 1 ≤ p) :
    Req (sStep4 p hp)
      (decompForm4 (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
        (ofQ (⟨1, p⟩ : Q) (by show 0 < p; omega)) (ofQ (⟨1, p + 1⟩ : Q) (by show 0 < p + 1; omega))) := by
  refine Req_trans ?_ (decomp_generic4 (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
    (ofQ (⟨1, p⟩ : Q) (by show 0 < p; omega)) (ofQ (⟨1, p + 1⟩ : Q) (by show 0 < p + 1; omega)))
  unfold sStep4 lhsForm4 lnQuartOver logQuartic logQuintic
  exact Rsub_congr (Req_refl _)
    (Rmul_congr (Req_refl _)
      (Req_symm (quintic_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))


end UOR.Bridge.F1Square.Analysis
