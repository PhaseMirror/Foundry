/-
F1 square — constant precision: **`λ₃ < λ₄`** (`λ₄ − λ₃ ≥ 0.035`), extending the certified Li
head to `λ₁ < λ₂ < λ₃ < λ₄` and unlocking the order-3 convex-combination Gate-A prune.

WHY THE DIFFERENCE, NOT THE ENDPOINTS. Bounding `λ₄` from below and `λ₃` from above SEPARATELY
does not work (`0.2185 < 0.2486`): each `ηⱼ` bracket width is then paid TWICE, once in each
endpoint, and at the binomial weights `3..6` that doubling swamps the true gap `0.178`. The
difference pays each width once. The archimedean sides, by contrast, are cheap to bound
separately (cost `≈ 0.008` against a `0.047` margin) because their `ζ` weights are small and the
constant `1` cancels exactly — so ONLY the arithmetic side needs an identity:

    λ₄^{arith} − λ₃^{arith} = −(η₀ + 3η₁ + 3η₂ + η₃)      (`lambda4_arith_split`)

obtained from the `nsmulR` splits `4 = 3+1` (definitional), `6 = 3+3`, `4 = 1+3`, and one
7-atom additive rearrangement whose permutation is built STRUCTURALLY (`List.Perm.swap`/`cons`
/`trans`) — `decide` on `List.Perm` is barred, it pulls `Classical.choice`.

THE LEDGER (exact rationals, rounded outward; every input already in stock).
- `η₀ ≤ −0.577`, `3η₁ ≤ 0.596055` (`γ₁ ≤ −0.0677`), `3η₂ ≤ −0.116907699`
  (`γ·γ₁ ≥ 0.578·(−0.0762)`, `γ₂ ≥ −0.014`), and the TIGHT ceiling
  `η₃ ≤ 0.0462725` (`reta3_le_t`: `γ⁴ ≤ 0.578⁴`, `γ²γ₁ ≤ 0.577²·(−0.0677)`,
  `γ₁² ≤ 0.0762²`, `γγ₂ ≤ 0.577·(−0.003)`, `γ₃ ≤ 1/40` — the stock `reta3_le`'s `0.145303`,
  built on the loose `γ₃ ≤ 1/8`, is far too weak here);
  hence `D := η₀ + 3η₁ + 3η₂ + η₃ ≤ −0.0515832 ≤ −0.051`, i.e.
  `λ₄^{arith} − λ₃^{arith} ≥ 0.051`.
- `arch(4) ≥ −1.024325` (`genuineArchSeq4_ge_t`, the ζ(3) ≤ 1.205 sharpening of the stock
  `−1.066325`, which is too weak by `0.042`), `arch(3) ≤ −1.008445` (`genuineArchSeq3_le`),
  so `arch(4) − arch(3) ≥ −0.01588`.
- **`Rlambda3_lt_Rlambda4 : Pos (λ₄ − λ₃)`** with the certified gap `≥ 0.035`
  (true value `0.178`).

HONEST SCOPE. A finite bracket fact about `n ≤ 4`; it prunes one more Gate-A candidate class
and says nothing about the uniform `∀ n` (= RH). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.LambdaFourUpper
import Core.F1.Analysis.LambdaFivePos
import Core.F1.Analysis.LogDiffBound

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- `nsmulR` splitting.
-- ===========================================================================

/-- `nsmulR 6 x ≈ nsmulR 3 x + nsmulR 3 x` — both flatten to the same 6-element list. -/
theorem nsmulR6_split (x : Real) : Req (nsmulR 6 x) (Radd (nsmulR 3 x) (nsmulR 3 x)) := by
  have hL : Req (nsmulR 6 x) (RsumL [x, x, x, x, x, x]) := by
    show Req (Radd (Radd (Radd (Radd (Radd x x) x) x) x) x) _
    refine Req_trans (Radd_congr (Radd_eq_RsumL5 x x x x x) (RsumL_singleton x)) ?_
    exact Req_symm (RsumL_append [x, x, x, x, x] [x])
  have hR : Req (Radd (nsmulR 3 x) (nsmulR 3 x)) (RsumL [x, x, x, x, x, x]) := by
    show Req (Radd (Radd (Radd x x) x) (Radd (Radd x x) x)) _
    refine Req_trans (Radd_congr (Radd_eq_RsumL3 x x x) (Radd_eq_RsumL3 x x x)) ?_
    exact Req_symm (RsumL_append [x, x, x] [x, x, x])
  exact Req_trans hL (Req_symm hR)

/-- `nsmulR 4 x ≈ x + nsmulR 3 x` — both flatten to the same 4-element list. -/
theorem nsmulR4_split_left (x : Real) : Req (nsmulR 4 x) (Radd x (nsmulR 3 x)) := by
  have hL : Req (nsmulR 4 x) (RsumL [x, x, x, x]) := by
    show Req (Radd (Radd (Radd x x) x) x) _
    exact Radd_eq_RsumL4 x x x x
  have hR : Req (Radd x (nsmulR 3 x)) (RsumL [x, x, x, x]) := by
    show Req (Radd x (Radd (Radd x x) x)) _
    refine Req_trans (Radd_congr (RsumL_singleton x) (Radd_eq_RsumL3 x x x)) ?_
    exact Req_symm (RsumL_append [x] [x, x, x])
  exact Req_trans hL (Req_symm hR)

-- ===========================================================================
-- The arithmetic difference identity.
-- ===========================================================================

/-- The difference expression `D = η₀ + 3η₁ + 3η₂ + η₃`. -/
def etaGap43 : Real :=
  Radd (Radd (Radd Reta0 (nsmulR 3 Reta1)) (nsmulR 3 Reta2)) Reta3

/-- The three tripled summands, named so the rearrangement stays readable. -/
private def A3e0 : Real := nsmulR 3 Reta0
private def B3e1 : Real := nsmulR 3 Reta1
private def C3e2 : Real := nsmulR 3 Reta2

/-- **THE ARITHMETIC DIFFERENCE IDENTITY**: `λ₄^{arith} ≈ λ₃^{arith} − D`. The `nsmulR` splits
    reduce it to a 7-atom rearrangement, closed by a structurally-built permutation. -/
theorem lambda4_arith_split :
    Req Rlambda4_arith (Radd Rlambda3_arith (Rneg etaGap43)) := by
  -- the two trees, with the `nsmulR` chunks split
  have hT4 : Req
      (Radd (Radd (Radd (Radd zero (nsmulR 4 Reta0)) (nsmulR 6 Reta1)) (nsmulR 4 Reta2))
        (nsmulR 1 Reta3))
      (RsumL [A3e0, Reta0, B3e1, B3e1, Reta2, C3e2, Reta3]) := by
    have hsplit : Req
        (Radd (Radd (Radd (Radd zero (nsmulR 4 Reta0)) (nsmulR 6 Reta1)) (nsmulR 4 Reta2))
          (nsmulR 1 Reta3))
        (Radd (Radd (Radd (Radd A3e0 Reta0) (Radd B3e1 B3e1)) (Radd Reta2 C3e2)) Reta3) := by
      refine Radd_congr (Radd_congr (Radd_congr ?_ (nsmulR6_split Reta1))
        (nsmulR4_split_left Reta2)) (Req_refl Reta3)
      exact Req_trans (Radd_comm zero (nsmulR 4 Reta0)) (Radd_zero (nsmulR 4 Reta0))
    refine Req_trans hsplit ?_
    refine Req_trans (Radd_congr (Radd_congr (Radd_congr
      (Radd_eq_RsumL A3e0 Reta0) (Radd_eq_RsumL B3e1 B3e1)) (Radd_eq_RsumL Reta2 C3e2))
      (RsumL_singleton Reta3)) ?_
    refine Req_trans (Radd_congr (Radd_congr
      (Req_symm (RsumL_append [A3e0, Reta0] [B3e1, B3e1])) (Req_refl _)) (Req_refl _)) ?_
    refine Req_trans (Radd_congr
      (Req_symm (RsumL_append [A3e0, Reta0, B3e1, B3e1] [Reta2, C3e2])) (Req_refl _)) ?_
    exact Req_symm (RsumL_append [A3e0, Reta0, B3e1, B3e1, Reta2, C3e2] [Reta3])
  have hT3D : Req
      (Radd (Radd (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1)) (nsmulR 1 Reta2))
        etaGap43)
      (RsumL [A3e0, B3e1, Reta2, Reta0, B3e1, C3e2, Reta3]) := by
    have hdrop : Req
        (Radd (Radd (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1)) (nsmulR 1 Reta2))
          etaGap43)
        (Radd (Radd (Radd A3e0 B3e1) Reta2) (Radd (Radd (Radd Reta0 B3e1) C3e2) Reta3)) := by
      refine Radd_congr (Radd_congr (Radd_congr ?_ (Req_refl B3e1)) (Req_refl Reta2))
        (Req_refl _)
      exact Req_trans (Radd_comm zero A3e0) (Radd_zero A3e0)
    refine Req_trans hdrop ?_
    refine Req_trans (Radd_congr (Radd_eq_RsumL3 A3e0 B3e1 Reta2)
      (Radd_eq_RsumL4 Reta0 B3e1 C3e2 Reta3)) ?_
    exact Req_symm (RsumL_append [A3e0, B3e1, Reta2] [Reta0, B3e1, C3e2, Reta3])
  -- the 7-atom permutation, built structurally (no `decide` on `List.Perm`)
  have hperm : Req (RsumL [A3e0, Reta0, B3e1, B3e1, Reta2, C3e2, Reta3])
      (RsumL [A3e0, B3e1, Reta2, Reta0, B3e1, C3e2, Reta3]) := by
    refine RsumL_perm (List.Perm.cons A3e0 ?_)
    refine List.Perm.trans (List.Perm.swap B3e1 Reta0 [B3e1, Reta2, C3e2, Reta3]) ?_
    refine List.Perm.cons B3e1 ?_
    refine List.Perm.trans
      (List.Perm.cons Reta0 (List.Perm.swap Reta2 B3e1 [C3e2, Reta3])) ?_
    exact List.Perm.swap Reta2 Reta0 [B3e1, C3e2, Reta3]
  have hcore : Req
      (Radd (Radd (Radd (Radd zero (nsmulR 4 Reta0)) (nsmulR 6 Reta1)) (nsmulR 4 Reta2))
        (nsmulR 1 Reta3))
      (Radd (Radd (Radd (Radd zero (nsmulR 3 Reta0)) (nsmulR 3 Reta1)) (nsmulR 1 Reta2))
        etaGap43) :=
    Req_trans hT4 (Req_trans hperm (Req_symm hT3D))
  show Req (Rneg _) _
  exact Req_trans (Rneg_congr hcore) (Rneg_Radd _ etaGap43)

-- ===========================================================================
-- The tight `η₃` ceiling and the `D` ceiling.
-- ===========================================================================

set_option maxRecDepth 8192 in
/-- **`η₃ ≤ 46273/10⁶`** — the TIGHT ceiling (`γ₃ ≤ 1/40`, `γ₂ ≤ −3/1000`), vs the stock
    `reta3_le`'s `145303/10⁶` which rests on the loose `γ₃ ≤ 1/8`. -/
theorem reta3_le_t : Rle Reta3 (ofQ (⟨46273, 1000000⟩ : Q) (by decide)) := by
  unfold Reta3
  have h1 : Rle (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
      (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1))
      (ofQ (mul (⟨4, 1⟩ : Q)
        (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨-677, 10000⟩ : Q))) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_sq_gamma1_le)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have h2 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma1))
      (ofQ (mul (⟨2, 1⟩ : Q) (mul (⟨762, 10000⟩ : Q) (⟨762, 10000⟩ : Q))) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_sq_le)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have h3 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma2))
      (ofQ (mul (⟨2, 1⟩ : Q) (mul (⟨577, 1000⟩ : Q) (⟨-3, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma2_le_t)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have h4 : Rle (Rmul (ofQ (⟨2, 3⟩ : Q) (by decide)) Rgamma3)
      (ofQ (mul (⟨2, 3⟩ : Q) (⟨1, 40⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma3_le_1_40)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have s1 : Rle (Radd (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)))
      (ofQ (add (mul (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q))
          (⟨578, 1000⟩ : Q))
        (mul (⟨4, 1⟩ : Q)
          (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨-677, 10000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add Rgamma_pow4_le h1) (Radd_Rle_ofQ_add (by decide) (by decide))
  have s2 : Rle (Radd (Radd (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma1)))
      (ofQ (add (add (mul (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q))
          (⟨578, 1000⟩ : Q))
        (mul (⟨4, 1⟩ : Q)
          (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨-677, 10000⟩ : Q))))
        (mul (⟨2, 1⟩ : Q) (mul (⟨762, 10000⟩ : Q) (⟨762, 10000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add s1 h2) (Radd_Rle_ofQ_add (by decide) (by decide))
  have s3 : Rle (Radd (Radd (Radd (Rmul (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h) Rgamma_h)
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma1)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma1 Rgamma1)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma2)))
      (ofQ (add (add (add (mul (mul (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))
          (⟨578, 1000⟩ : Q)) (⟨578, 1000⟩ : Q))
        (mul (⟨4, 1⟩ : Q)
          (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨-677, 10000⟩ : Q))))
        (mul (⟨2, 1⟩ : Q) (mul (⟨762, 10000⟩ : Q) (⟨762, 10000⟩ : Q))))
        (mul (⟨2, 1⟩ : Q) (mul (⟨577, 1000⟩ : Q) (⟨-3, 1000⟩ : Q)))) (by decide)) :=
    Rle_trans (Radd_le_add s2 h3) (Radd_Rle_ofQ_add (by decide) (by decide))
  refine Rle_trans (Rle_trans (Radd_le_add s3 h4)
    (Radd_Rle_ofQ_add (by decide) (by decide))) ?_
  exact Rle_ofQ_ofQ (by decide) (by decide) (by decide)

/-- `3η₁ ≤ 596055/10⁶`. -/
private theorem eta1_triple_le_t :
    Rle (nsmulR 3 Reta1) (ofQ (⟨596055, 1000000⟩ : Q) (by decide)) := by
  have hd : Rle (Radd Reta1 Reta1)
      (ofQ (add (⟨198685, 1000000⟩ : Q) (⟨198685, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add reta1_le4 reta1_le4) (Radd_Rle_ofQ_add (by decide) (by decide))
  have ht : Rle (Radd (Radd Reta1 Reta1) Reta1)
      (ofQ (add (add (⟨198685, 1000000⟩ : Q) (⟨198685, 1000000⟩ : Q))
        (⟨198685, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add hd reta1_le4) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans ht (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

/-- `η₂ ≤ −38969233/10⁹`, tripled: `3η₂ ≤ −116907699/10⁹`. -/
private theorem eta2_triple_le_t :
    Rle (nsmulR 3 Reta2) (ofQ (⟨-116907699, 1000000000⟩ : Q) (by decide)) := by
  have hA : Rle (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h))
      (ofQ (neg (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)))
        (by decide)) :=
    Rle_trans (Rneg_le Rgamma_cube_ge)
      (Rle_of_Req (Rneg_ofQ (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q))
        (by decide)))
  have hBlo : Rle (ofQ (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)))
        (by decide)) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1)) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma_gamma1_ge)
  have hnegB : Rle (Rneg (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1)))
      (ofQ (neg (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)))) (by decide)) :=
    Rle_trans (Rneg_le hBlo)
      (Rle_of_Req (Rneg_ofQ (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)))
        (by decide)))
  have hClo : Rle (ofQ (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q)) (by decide))
      (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) Rgamma2) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma2_ge_neg0014)
  have hnegC : Rle (Rneg (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) Rgamma2))
      (ofQ (neg (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q))) (by decide)) :=
    Rle_trans (Rneg_le hClo)
      (Rle_of_Req (Rneg_ofQ (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q)) (by decide)))
  have hAB : Rle (Radd (Rneg (Rmul (Rmul Rgamma_h Rgamma_h) Rgamma_h))
      (Rneg (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul Rgamma_h Rgamma1))))
      (ofQ (add (neg (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)))
        (neg (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q))))) (by decide)) :=
    Rle_trans (Radd_le_add hA hnegB) (Radd_Rle_ofQ_add (by decide) (by decide))
  have he : Rle Reta2 (ofQ (⟨-38969233, 1000000000⟩ : Q) (by decide)) := by
    have hsum : Rle Reta2
        (ofQ (add (add (neg (mul (mul (⟨577, 1000⟩ : Q) (⟨577, 1000⟩ : Q)) (⟨577, 1000⟩ : Q)))
          (neg (mul (⟨3, 1⟩ : Q) (mul (⟨578, 1000⟩ : Q) (⟨-762, 10000⟩ : Q)))))
          (neg (mul (⟨3, 2⟩ : Q) (⟨-14, 1000⟩ : Q)))) (by decide)) :=
      Rle_trans (Radd_le_add hAB hnegC) (Radd_Rle_ofQ_add (by decide) (by decide))
    exact Rle_trans hsum (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have hd : Rle (Radd Reta2 Reta2)
      (ofQ (add (⟨-38969233, 1000000000⟩ : Q) (⟨-38969233, 1000000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add he he) (Radd_Rle_ofQ_add (by decide) (by decide))
  have ht : Rle (Radd (Radd Reta2 Reta2) Reta2)
      (ofQ (add (add (⟨-38969233, 1000000000⟩ : Q) (⟨-38969233, 1000000000⟩ : Q))
        (⟨-38969233, 1000000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add hd he) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans ht (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

set_option maxRecDepth 8192 in
/-- **`D = η₀ + 3η₁ + 3η₂ + η₃ ≤ −51/1000`** (exact value `≤ −0.0515832`). -/
theorem etaGap43_le : Rle etaGap43 (ofQ (⟨-51, 1000⟩ : Q) (by decide)) := by
  unfold etaGap43
  have h0 : Rle Reta0 (ofQ (neg (⟨577, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rneg_le Rgamma_h_ge_577)
      (Rle_of_Req (Rneg_ofQ (⟨577, 1000⟩ : Q) (by decide)))
  have s1 : Rle (Radd Reta0 (nsmulR 3 Reta1))
      (ofQ (add (neg (⟨577, 1000⟩ : Q)) (⟨596055, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add h0 eta1_triple_le_t) (Radd_Rle_ofQ_add (by decide) (by decide))
  have s2 : Rle (Radd (Radd Reta0 (nsmulR 3 Reta1)) (nsmulR 3 Reta2))
      (ofQ (add (add (neg (⟨577, 1000⟩ : Q)) (⟨596055, 1000000⟩ : Q))
        (⟨-116907699, 1000000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add s1 eta2_triple_le_t) (Radd_Rle_ofQ_add (by decide) (by decide))
  have s3 : Rle (Radd (Radd (Radd Reta0 (nsmulR 3 Reta1)) (nsmulR 3 Reta2)) Reta3)
      (ofQ (add (add (add (neg (⟨577, 1000⟩ : Q)) (⟨596055, 1000000⟩ : Q))
        (⟨-116907699, 1000000000⟩ : Q)) (⟨46273, 1000000⟩ : Q)) (by decide)) :=
    Rle_trans (Radd_le_add s2 reta3_le_t) (Radd_Rle_ofQ_add (by decide) (by decide))
  exact Rle_trans s3 (Rle_ofQ_ofQ (by decide) (by decide) (by decide))

-- ===========================================================================
-- The tight `arch(4)` lower bound (the ζ(3) ≤ 1.205 sharpening).
-- ===========================================================================

/-- `1 − 2(γ + log4π) ≥ −5.2192`. -/
private theorem arch4_head_ge :
    Rle (ofQ (⟨-521920, 100000⟩ : Q) (by decide))
      (Rsub one (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic)))) := by
  have hg : Rle (Radd Rgamma_h Rlog4pic) (ofQ (⟨310960, 100000⟩ : Q) (by decide)) := by
    have h : Rle (Radd Rgamma_h Rlog4pic)
        (ofQ (add (⟨578, 1000⟩ : Q) (⟨25316, 10000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add Rgamma_h_le_578 Rlog4pic_le)
        (Radd_Rle_ofQ_add (by decide) (by decide))
    exact Rle_trans h (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have h4 : Rle (nsmulR 4 (Radd Rgamma_h Rlog4pic))
      (ofQ (⟨1243840, 100000⟩ : Q) (by decide)) := by
    have hd : Rle (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))
        (ofQ (add (⟨310960, 100000⟩ : Q) (⟨310960, 100000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add hg hg) (Radd_Rle_ofQ_add (by decide) (by decide))
    have h3 : Rle (Radd (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))
        (Radd Rgamma_h Rlog4pic))
        (ofQ (add (add (⟨310960, 100000⟩ : Q) (⟨310960, 100000⟩ : Q))
          (⟨310960, 100000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add hd hg) (Radd_Rle_ofQ_add (by decide) (by decide))
    have hq : Rle (Radd (Radd (Radd (Radd Rgamma_h Rlog4pic) (Radd Rgamma_h Rlog4pic))
        (Radd Rgamma_h Rlog4pic)) (Radd Rgamma_h Rlog4pic))
        (ofQ (add (add (add (⟨310960, 100000⟩ : Q) (⟨310960, 100000⟩ : Q))
          (⟨310960, 100000⟩ : Q)) (⟨310960, 100000⟩ : Q)) (by decide)) :=
      Rle_trans (Radd_le_add h3 hg) (Radd_Rle_ofQ_add (by decide) (by decide))
    exact Rle_trans hq (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
  have hH : Rle (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic)))
      (ofQ (⟨621920, 100000⟩ : Q) (by decide)) := by
    refine Rle_trans (Rhalf_le_Rhalf h4) ?_
    refine Rle_trans (Rle_of_Req (Rhalf_ofQ (⟨1243840, 100000⟩ : Q) (by decide))) ?_
    exact Rle_ofQ_ofQ (Qmul_den_pos (by decide) (by decide)) (by decide) (by decide)
  have hneg : Rle (ofQ (neg (⟨621920, 100000⟩ : Q)) (by decide))
      (Rneg (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic)))) := Rneg_ofQ_le (by decide) hH
  have hone : Rle (ofQ (⟨1, 1⟩ : Q) (by decide)) one := Rle_of_Req (Req_refl one)
  have hsum : Rle (ofQ (add (⟨1, 1⟩ : Q) (neg (⟨621920, 100000⟩ : Q))) (by decide))
      (Rsub one (Rhalf (nsmulR 4 (Radd Rgamma_h Rlog4pic)))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hone hneg)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hsum

/-- `−(7/2)ζ(3) ≥ −3.5·1.205` (the `j = 3` term of `arch(4)`, with `ζ(3) ≤ 1.205`). -/
private theorem arch4_t3_ge :
    Rle (ofQ (neg (mul (⟨28, 8⟩ : Q) (⟨1205, 1000⟩ : Q))) (by decide))
      (genArchTerm 4 3 (by omega)) := by
  have hhi : Rle (Rmul (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))
      (ofQ (mul (⟨28, 8⟩ : Q) (⟨1205, 1000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta3_le_1205)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have hconv : Req (genArchTerm 4 3 (by omega))
      (Rneg (Rmul (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))) :=
    Req_trans (Rmul_congr (Req_symm (Rneg_ofQ (⟨28, 8⟩ : Q) (by decide)))
        (Req_refl (zeta 3 (by decide))))
      (Rmul_neg_left (ofQ (⟨28, 8⟩ : Q) (by decide)) (zeta 3 (by decide)))
  exact Rle_trans (Rneg_ofQ_le (by decide) hhi) (Rle_of_Req (Req_symm hconv))

set_option maxRecDepth 8192 in
/-- **`arch(4) ≥ −1024325/10⁶`** — the `ζ(3) ≤ 1.205` sharpening of the stock `archLoR4_le`
    (`−1.066325`), which is too weak for the gap by `0.042`. -/
theorem genuineArchSeq4_ge_t :
    Rle (ofQ (⟨-1024325, 1000000⟩ : Q) (by decide)) (genuineArchSeq 4) := by
  have hz : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) zero := Rle_of_Req (Req_refl zero)
  have h1 : Rle (ofQ (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1644, 1000⟩ : Q))) (by decide))
      (Radd zero (genArchTerm 4 2 (by omega))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add hz archTerm4_2_ge)
  have h2 : Rle (ofQ (add (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
        (neg (mul (⟨28, 8⟩ : Q) (⟨1205, 1000⟩ : Q)))) (by decide))
      (Radd (Radd zero (genArchTerm 4 2 (by omega))) (genArchTerm 4 3 (by omega))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add h1 arch4_t3_ge)
  have h3 : Rle (ofQ (add (add (add (⟨0, 1⟩ : Q) (mul (⟨18, 4⟩ : Q) (⟨1644, 1000⟩ : Q)))
        (neg (mul (⟨28, 8⟩ : Q) (⟨1205, 1000⟩ : Q))))
        (mul (⟨15, 16⟩ : Q) (⟨1082, 1000⟩ : Q))) (by decide))
      (genArchTail 4 4) := by
    show Rle _ (Radd (Radd (Radd zero (genArchTerm 4 2 (by omega)))
      (genArchTerm 4 3 (by omega))) (genArchTerm 4 4 (by omega)))
    exact Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide))
      (Radd_le_add h2 archTerm4_4_ge)
  have htail : Rle (ofQ (⟨4194875, 1000000⟩ : Q) (by decide)) (genArchTail 4 4) :=
    Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) h3
  have hsum : Rle (ofQ (add (⟨-521920, 100000⟩ : Q) (⟨4194875, 1000000⟩ : Q)) (by decide))
      (genuineArchSeq 4) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide))
      (Radd_le_add arch4_head_ge htail)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hsum

-- ===========================================================================
-- The gap.
-- ===========================================================================

/-- `(a+b)+(c+d) ≈ (a+c)+(b+d)` — the abelian rearrangement (the `Square.Radd_rearrange4`
    of `WeilPSD.lean`, re-proved here so the Analysis layer does not depend on `Square`). -/
theorem Radd_rearrange4_an (a b c d : Real) :
    Req (Radd (Radd a b) (Radd c d)) (Radd (Radd a c) (Radd b d)) := by
  refine Req_trans (Radd_assoc a b (Radd c d)) ?_
  refine Req_trans (Radd_congr (Req_refl a) (Req_symm (Radd_assoc b c d))) ?_
  refine Req_trans (Radd_congr (Req_refl a) (Radd_congr (Radd_comm b c) (Req_refl d))) ?_
  refine Req_trans (Radd_congr (Req_refl a) (Radd_assoc c b d)) ?_
  exact Req_symm (Radd_assoc a c (Radd b d))

set_option maxRecDepth 8192 in
/-- **`λ₄ − λ₃ ≥ 35/1000`** — the certified gap (true value `≈ 0.178`). -/
theorem lambda43_gap_lower :
    Rle (ofQ (⟨35, 1000⟩ : Q) (by decide)) (Rsub Rlambda4 Rlambda3) := by
  -- split the difference into arithmetic and archimedean parts
  have hsplit : Req (Rsub Rlambda4 Rlambda3)
      (Radd (Rsub Rlambda4_arith Rlambda3_arith) (Rsub (genuineArchSeq 4) (genuineArchSeq 3))) := by
    show Req (Radd (Radd Rlambda4_arith (genuineArchSeq 4))
      (Rneg (Radd Rlambda3_arith (genuineArchSeq 3)))) _
    refine Req_trans (Radd_congr (Req_refl _)
      (Rneg_Radd Rlambda3_arith (genuineArchSeq 3))) ?_
    exact Radd_rearrange4_an Rlambda4_arith (genuineArchSeq 4)
      (Rneg Rlambda3_arith) (Rneg (genuineArchSeq 3))
  -- arithmetic part: ≥ 51/1000
  have harith : Rle (ofQ (⟨51, 1000⟩ : Q) (by decide))
      (Rsub Rlambda4_arith Rlambda3_arith) := by
    have hid : Req (Rsub Rlambda4_arith Rlambda3_arith) (Rneg etaGap43) :=
      Req_trans (Radd_congr lambda4_arith_split (Req_refl (Rneg Rlambda3_arith)))
        (Rsub_Radd_cancel_left Rlambda3_arith (Rneg etaGap43))
    refine Rle_trans ?_ (Rle_of_Req (Req_symm hid))
    refine Rle_trans (Rle_of_Req ?_) (Rneg_ofQ_le (by decide) etaGap43_le)
    exact Req_symm (ofQ_congr (by decide) (by decide) (by decide))
  -- archimedean part: ≥ −15880/10⁶
  have harch : Rle (ofQ (⟨-15880, 1000000⟩ : Q) (by decide))
      (Rsub (genuineArchSeq 4) (genuineArchSeq 3)) := by
    have hn : Rle (ofQ (neg (⟨-1008445, 1000000⟩ : Q)) (by decide))
        (Rneg (genuineArchSeq 3)) := Rneg_ofQ_le (by decide) genuineArchSeq3_le
    have hsum : Rle (ofQ (add (⟨-1024325, 1000000⟩ : Q) (neg (⟨-1008445, 1000000⟩ : Q)))
        (by decide)) (Rsub (genuineArchSeq 4) (genuineArchSeq 3)) :=
      Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide))
        (Radd_le_add genuineArchSeq4_ge_t hn)
    exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide)) hsum
  have htot : Rle (ofQ (add (⟨51, 1000⟩ : Q) (⟨-15880, 1000000⟩ : Q)) (by decide))
      (Radd (Rsub Rlambda4_arith Rlambda3_arith)
        (Rsub (genuineArchSeq 4) (genuineArchSeq 3))) :=
    Rle_trans (Rle_ofQ_add_Radd (by decide) (by decide)) (Radd_le_add harith harch)
  exact Rle_trans (Rle_ofQ_ofQ (by decide) (by decide) (by decide))
    (Rle_trans htot (Rle_of_Req (Req_symm hsplit)))

/-- **`λ₃ < λ₄`** — the certified Li head is strictly increasing through `n = 4`:
    `λ₁ < λ₂ < λ₃ < λ₄`. This is exactly the input the order-3 convex-combination Gate-A
    prune consumes. -/
theorem Rlambda3_lt_Rlambda4 : Pos (Rsub Rlambda4 Rlambda3) :=
  Pos_of_Rle_ofQ (by decide) (by decide) lambda43_gap_lower

end UOR.Bridge.F1Square.Analysis
