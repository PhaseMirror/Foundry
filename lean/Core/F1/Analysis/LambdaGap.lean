/-
F1 square — the certificate front (workstream 1, the prune substrate): **the λ₂ − λ₁ GAP**,
`2λ₂ − 2λ₁ ≥ 0.113 > 0`, hence `λ₁ ≉ λ₂`.

WHY THIS BRICK. The Gate-A finite-list template (`Square/GateAFiniteList.lean`) reduces the
uniform diagonal identity `gramOf ι D n n ≈ 2λₙ` to a finite hypothesis list around a generating
recurrence. The FIRST candidate class — the order-1 constant recurrence `s(n+1) = s(n)`, i.e.
every embedding whose squared-norm diagonal is eventually periodic of period one — forces
`2λ₂ ≈ 2λ₁` on the λ side of the list. This brick refutes that hypothesis once and for all:
the certified brackets already in stock separate λ₂ from λ₁, so the WHOLE class is pruned for
every rule `ι` and every dimension `D` at once (recorded in `Square/GateAFiniteList.lean`).

THE CANCELLATION TRICK (why no new numerics are needed). Directly upper-bounding λ₁ needs a
LOWER bracket on `log 4π`, which the substrate does not have (only `Rlog4pic_le`). But in the
difference the `log 4π` atoms cancel ALGEBRAICALLY:

    2λ₂ − 2λ₁ = γ − 2γ² − 4γ₁ − log 4π + (3/2)ζ(2),

and every surviving constant enters with the sign whose certified bracket EXISTS:
`γ ≥ 0.577` (`Rgamma_h_ge_577`), `γ² ≤ 0.578²` (`Rgamma_sq_le`), `γ₁ ≤ −0.0677`
(`Rgamma1_le_neg0677`), `log 4π ≤ 2.5316` (`Rlog4pic_le`), `ζ(2) ≥ 1.644` (`zeta2_lower_tight`).
The rearrangement is done in the `RsumL` additive normalizer (`RAddNF`): flatten
`(λ₂ + λ₂) − 2λ₁` to a signed-atom list, cancel the single `(−log4π, −−log4π)` pair with
`RsumL_cancel_anywhere` (no permutation is even needed — the flattening order already
interleaves them correctly), and lower-bound the 13-atom residual by a rounded rational
accumulator at denominator 10⁴:

    residual ≥ 1130/10000 = 0.113   (true value 2(λ₂−λ₁) ≈ 0.1385).

WHAT IS PROVED.
- `lambda_gap_lower` : `2λ₂ − 2λ₁ ≥ 1130/10000` (with `2λ₁ = Rtwolambda1`, the integer-coefficient
  form — no halving anywhere).
- `lambda_gap_pos`   : `Pos (2λ₂ − 2λ₁)`.
- `Rlambda1_ne_Rlambda2` : `¬ (λ₁ ≈ λ₂)` — the first certified SEPARATION of two Li
  coefficients in the substrate (positivity of each was already known; distinctness was not).

HONEST SCOPE. This is a finite, `n ≤ 2` fact about certified constants. It prunes a candidate
class of the Gate-A template; it says NOTHING about the uniform `∀ n` bound (= RH). The crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.RAddNF
import Core.F1.Analysis.LambdaTwo
import Core.F1.Analysis.LambdaThreePos
import Core.F1.Analysis.GammaZeroBracket
import Core.F1.Analysis.GammaOneBracket
import Core.F1.Analysis.ClampOne

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The signed atoms of `(λ₂ + λ₂) − 2λ₁` (names for readability of the lists).
-- ===========================================================================

/-- `−γ²`. -/
private def negSq : Real := Rneg (Rmul Rgamma_h Rgamma_h)
/-- `−2γ₁`. -/
private def negG1 : Real := Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1)
/-- `−log 4π`. -/
private def negL : Real := Rneg Rlog4pic
/-- `(3/4)ζ(2)` (each λ₂ copy carries one; the pair is the `(3/2)ζ(2)` of the gap). -/
private def zT : Real := Rmul (ofQ (⟨3, 4⟩ : Q) (by decide)) (zeta 2 (by decide))
/-- `−2` (from `−2λ₁ = −(2 + γ − log 4π)`). -/
private def negTwo : Real := Rneg (ofQ (⟨2, 1⟩ : Q) (by decide))
/-- `−γ` (same provenance). -/
private def negGam : Real := Rneg Rgamma_h
/-- `−(−log 4π)` — kept UNSIMPLIFIED so it is the syntactic `Rneg negL` that
    `RsumL_cancel_anywhere` cancels against the `negL` inside the first λ₂ copy. -/
private def negNegL : Real := Rneg negL

/-- The λ₂ atom list: `λ₂ = 1 + γ − γ² − 2γ₁ − log4π + (3/4)ζ(2)`. -/
private def lam2L : List Real := [one, Rgamma_h, negSq, negG1, negL, zT]
/-- The residual head (before the cancelled `negL`). -/
private def headL : List Real := [one, Rgamma_h, negSq, negG1]
/-- The residual tail (between the cancelled pair, then the `−2λ₁` remnants). -/
private def restL : List Real := [zT, one, Rgamma_h, negSq, negG1, negL, zT, negTwo, negGam]

-- ===========================================================================
-- Flattening `λ₂` and `−2λ₁` into the canonical additive form.
-- ===========================================================================

/-- `λ₂ ≈ Σ lam2L` — the definition tree, flattened. -/
private theorem lam2_flat : Req Rlambda2 (RsumL lam2L) := by
  show Req (Radd (Radd (Radd (Radd one (Radd Rgamma_h negSq)) negG1) negL) zT) (RsumL lam2L)
  have h3 : Req (Radd one (Radd Rgamma_h negSq)) (RsumL [one, Rgamma_h, negSq]) :=
    Radd_congr (Req_refl one) (Radd_congr (Req_refl Rgamma_h) (RsumL_singleton negSq))
  have h4 : Req (Radd (Radd one (Radd Rgamma_h negSq)) negG1)
      (RsumL [one, Rgamma_h, negSq, negG1]) :=
    Req_trans (Radd_congr h3 (RsumL_singleton negG1))
      (Req_symm (RsumL_append [one, Rgamma_h, negSq] [negG1]))
  have h5 : Req (Radd (Radd (Radd one (Radd Rgamma_h negSq)) negG1) negL)
      (RsumL [one, Rgamma_h, negSq, negG1, negL]) :=
    Req_trans (Radd_congr h4 (RsumL_singleton negL))
      (Req_symm (RsumL_append [one, Rgamma_h, negSq, negG1] [negL]))
  exact Req_trans (Radd_congr h5 (RsumL_singleton zT))
    (Req_symm (RsumL_append [one, Rgamma_h, negSq, negG1, negL] [zT]))

/-- `−2λ₁ = −(2 + γ − log4π) ≈ Σ [−2, −γ, −(−log4π)]` — the last atom deliberately
    NOT collapsed to `log4π`, so the cancellation below is syntactic. -/
private theorem twolam1_neg_flat : Req (Rneg Rtwolambda1) (RsumL [negTwo, negGam, negNegL]) := by
  show Req (Rneg (Radd (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma_h) negL))
      (RsumL [negTwo, negGam, negNegL])
  refine Req_trans (Rneg_Radd (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma_h) negL) ?_
  refine Req_trans (Radd_congr (Rneg_Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma_h)
    (Req_refl (Rneg negL))) ?_
  exact Radd_eq_RsumL3 negTwo negGam negNegL

-- ===========================================================================
-- The rounded rational accumulator (denominator 10⁴, always rounding DOWN).
-- ===========================================================================

/-- One accumulation step: an atom lower bound `q ≤ x`, an accumulator lower bound `r ≤ acc`,
    and a rounded target `t ≤ q + r` give `t ≤ x + acc`. -/
private theorem accum {q r t : Q} (hq : 0 < q.den) (hr : 0 < r.den) (ht : 0 < t.den)
    {x acc : Real} (hx : Rle (ofQ q hq) x) (hacc : Rle (ofQ r hr) acc)
    (hqt : Qle t (add q r)) : Rle (ofQ t ht) (Radd x acc) :=
  Rle_trans (Rle_ofQ_ofQ ht (add_den_pos hq hr) hqt)
    (Rle_trans (Rle_ofQ_add_Radd hq hr) (Radd_le_add hx hacc))

/-- **The certified gap**: `(λ₂ + λ₂) − 2λ₁ ≥ 1130/10000 = 0.113` — assembled entirely from
    brackets already in stock; the bracket-less `log 4π` lower never enters (it cancels). -/
theorem lambda_gap_lower :
    Rle (ofQ (⟨1130, 10000⟩ : Q) (by decide)) (Rsub (Radd Rlambda2 Rlambda2) Rtwolambda1) := by
  -- ---- flatten the whole difference to one signed-atom list
  have hDD : Req (Radd Rlambda2 Rlambda2) (RsumL (lam2L ++ lam2L)) :=
    Req_trans (Radd_congr lam2_flat lam2_flat) (Req_symm (RsumL_append lam2L lam2L))
  have hD : Req (Rsub (Radd Rlambda2 Rlambda2) Rtwolambda1)
      (RsumL ((lam2L ++ lam2L) ++ [negTwo, negGam, negNegL])) :=
    Req_trans (Radd_congr hDD twolam1_neg_flat)
      (Req_symm (RsumL_append (lam2L ++ lam2L) [negTwo, negGam, negNegL]))
  -- ---- cancel the single (−log4π, −−log4π) pair; the residual has ONE −log4π left.
  -- The list reshaping is done at the LIST level and moved into the goal by `rw` — NEVER by
  -- `Req`-level defeq between differently-associated `RsumL` arguments. Each `rfl` below is
  -- ALIGNED (one `++`-spelling against the common cons literal), so element comparisons stay
  -- syntactic; comparing the two `++`-spellings directly would transiently unify DIFFERENT
  -- `Real` atoms and descend into the Bishop `.seq` towers (exponential whnf, observed OOM).
  have hA1 : (lam2L ++ lam2L) ++ [negTwo, negGam, negNegL]
      = [one, Rgamma_h, negSq, negG1, negL, zT, one, Rgamma_h, negSq, negG1, negL, zT,
         negTwo, negGam, negNegL] := rfl
  have hB1 : headL ++ negL :: (restL ++ Rneg negL :: [])
      = [one, Rgamma_h, negSq, negG1, negL, zT, one, Rgamma_h, negSq, negG1, negL, zT,
         negTwo, negGam, negNegL] := rfl
  have hA2 : headL ++ restL
      = [one, Rgamma_h, negSq, negG1, zT, one, Rgamma_h, negSq, negG1, negL, zT,
         negTwo, negGam] := rfl
  have hB2 : headL ++ (restL ++ [])
      = [one, Rgamma_h, negSq, negG1, zT, one, Rgamma_h, negSq, negG1, negL, zT,
         negTwo, negGam] := rfl
  have hcanc : Req (RsumL ((lam2L ++ lam2L) ++ [negTwo, negGam, negNegL]))
      (RsumL (headL ++ restL)) := by
    rw [hA1.trans hB1.symm, hA2.trans hB2.symm]
    exact RsumL_cancel_anywhere negL headL restL []
  have hsplit : Req (RsumL (headL ++ restL)) (Radd (RsumL headL) (RsumL restL)) :=
    RsumL_append headL restL
  -- ---- per-atom lower bounds (all stock)
  have hbOne : Rle (ofQ (⟨1, 1⟩ : Q) (by decide)) one := Rle_of_Req (Req_refl one)
  have hbSq : Rle (ofQ (neg (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))) (by decide)) negSq :=
    Rneg_ofQ_le (by decide) Rgamma_sq_le
  have h2g1 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1)
      (ofQ (mul (⟨2, 1⟩ : Q) (⟨-677, 10000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_le_neg0677)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have hbG1 : Rle (ofQ (neg (mul (⟨2, 1⟩ : Q) (⟨-677, 10000⟩ : Q))) (by decide)) negG1 :=
    Rneg_ofQ_le (by decide) h2g1
  have hbL : Rle (ofQ (neg (⟨25316, 10000⟩ : Q)) (by decide)) negL :=
    Rneg_ofQ_le (by decide) Rlog4pic_le
  have hbZ : Rle (ofQ (mul (⟨3, 4⟩ : Q) (⟨1644, 1000⟩ : Q)) (by decide)) zT :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_lower_tight)
  have hbTwo : Rle (ofQ (neg (⟨2, 1⟩ : Q)) (by decide)) negTwo :=
    Rneg_ofQ_le (by decide) (Rle_refl (ofQ (⟨2, 1⟩ : Q) (by decide)))
  have hbNGam : Rle (ofQ (neg (⟨578, 1000⟩ : Q)) (by decide)) negGam :=
    Rneg_ofQ_le (by decide) Rgamma_h_le_578
  -- ---- accumulate the tail `restL`, right to left, rounding down at 10⁴
  have s0 : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) (RsumL []) := Rle_of_Req (Req_refl zero)
  have s1 : Rle (ofQ (⟨-5780, 10000⟩ : Q) (by decide)) (RsumL [negGam]) :=
    accum (by decide) (by decide) (by decide) hbNGam s0 (by decide)
  have s2 : Rle (ofQ (⟨-25780, 10000⟩ : Q) (by decide)) (RsumL [negTwo, negGam]) :=
    accum (by decide) (by decide) (by decide) hbTwo s1 (by decide)
  have s3 : Rle (ofQ (⟨-13450, 10000⟩ : Q) (by decide)) (RsumL [zT, negTwo, negGam]) :=
    accum (by decide) (by decide) (by decide) hbZ s2 (by decide)
  have s4 : Rle (ofQ (⟨-38766, 10000⟩ : Q) (by decide)) (RsumL [negL, zT, negTwo, negGam]) :=
    accum (by decide) (by decide) (by decide) hbL s3 (by decide)
  have s5 : Rle (ofQ (⟨-37412, 10000⟩ : Q) (by decide))
      (RsumL [negG1, negL, zT, negTwo, negGam]) :=
    accum (by decide) (by decide) (by decide) hbG1 s4 (by decide)
  have s6 : Rle (ofQ (⟨-40753, 10000⟩ : Q) (by decide))
      (RsumL [negSq, negG1, negL, zT, negTwo, negGam]) :=
    accum (by decide) (by decide) (by decide) hbSq s5 (by decide)
  have s7 : Rle (ofQ (⟨-34983, 10000⟩ : Q) (by decide))
      (RsumL [Rgamma_h, negSq, negG1, negL, zT, negTwo, negGam]) :=
    accum (by decide) (by decide) (by decide) Rgamma_h_ge_577 s6 (by decide)
  have s8 : Rle (ofQ (⟨-24983, 10000⟩ : Q) (by decide))
      (RsumL [one, Rgamma_h, negSq, negG1, negL, zT, negTwo, negGam]) :=
    accum (by decide) (by decide) (by decide) hbOne s7 (by decide)
  have s9 : Rle (ofQ (⟨-12653, 10000⟩ : Q) (by decide)) (RsumL restL) :=
    accum (by decide) (by decide) (by decide) hbZ s8 (by decide)
  -- ---- accumulate the head `headL`
  have u1 : Rle (ofQ (⟨1354, 10000⟩ : Q) (by decide)) (RsumL [negG1]) :=
    accum (by decide) (by decide) (by decide) hbG1 s0 (by decide)
  have u2 : Rle (ofQ (⟨-1987, 10000⟩ : Q) (by decide)) (RsumL [negSq, negG1]) :=
    accum (by decide) (by decide) (by decide) hbSq u1 (by decide)
  have u3 : Rle (ofQ (⟨3783, 10000⟩ : Q) (by decide)) (RsumL [Rgamma_h, negSq, negG1]) :=
    accum (by decide) (by decide) (by decide) Rgamma_h_ge_577 u2 (by decide)
  have u4 : Rle (ofQ (⟨13783, 10000⟩ : Q) (by decide)) (RsumL headL) :=
    accum (by decide) (by decide) (by decide) hbOne u3 (by decide)
  -- ---- combine and transport back through the flattening
  have hAB : Rle (ofQ (⟨1130, 10000⟩ : Q) (by decide)) (Radd (RsumL headL) (RsumL restL)) :=
    accum (by decide) (by decide) (by decide) u4 s9 (by decide)
  exact Rle_trans hAB (Rle_of_Req (Req_symm (Req_trans hD (Req_trans hcanc hsplit))))

/-- **`Pos (2λ₂ − 2λ₁)`** — the gap is strictly positive. -/
theorem lambda_gap_pos : Pos (Rsub (Radd Rlambda2 Rlambda2) Rtwolambda1) :=
  Pos_of_Rle_ofQ (by decide) (by decide) lambda_gap_lower

/-- **`λ₂ ≥ 797/10000 = 0.0797`** (true value `0.0923457`) — the named lower bracket, from the
    same atom bounds as the gap (`1 + 0.577 − 0.334084 + 0.1354 − 2.5316 + 1.233 = 0.079716`).
    Consumed by the order-1 Gate-A class kill (`Square/GateAFiniteList.lean`). -/
theorem Rlambda2_ge : Rle (ofQ (⟨797, 10000⟩ : Q) (by decide)) Rlambda2 := by
  have hbOne : Rle (ofQ (⟨1, 1⟩ : Q) (by decide)) one := Rle_of_Req (Req_refl one)
  have hbSq : Rle (ofQ (neg (mul (⟨578, 1000⟩ : Q) (⟨578, 1000⟩ : Q))) (by decide)) negSq :=
    Rneg_ofQ_le (by decide) Rgamma_sq_le
  have h2g1 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) Rgamma1)
      (ofQ (mul (⟨2, 1⟩ : Q) (⟨-677, 10000⟩ : Q)) (by decide)) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) Rgamma1_le_neg0677)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (by decide)))
  have hbG1 : Rle (ofQ (neg (mul (⟨2, 1⟩ : Q) (⟨-677, 10000⟩ : Q))) (by decide)) negG1 :=
    Rneg_ofQ_le (by decide) h2g1
  have hbL : Rle (ofQ (neg (⟨25316, 10000⟩ : Q)) (by decide)) negL :=
    Rneg_ofQ_le (by decide) Rlog4pic_le
  have hbZ : Rle (ofQ (mul (⟨3, 4⟩ : Q) (⟨1644, 1000⟩ : Q)) (by decide)) zT :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (by decide))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) zeta2_lower_tight)
  have s0 : Rle (ofQ (⟨0, 1⟩ : Q) (by decide)) (RsumL []) := Rle_of_Req (Req_refl zero)
  have v1 : Rle (ofQ (⟨12330, 10000⟩ : Q) (by decide)) (RsumL [zT]) :=
    accum (by decide) (by decide) (by decide) hbZ s0 (by decide)
  have v2 : Rle (ofQ (⟨-12986, 10000⟩ : Q) (by decide)) (RsumL [negL, zT]) :=
    accum (by decide) (by decide) (by decide) hbL v1 (by decide)
  have v3 : Rle (ofQ (⟨-11632, 10000⟩ : Q) (by decide)) (RsumL [negG1, negL, zT]) :=
    accum (by decide) (by decide) (by decide) hbG1 v2 (by decide)
  have v4 : Rle (ofQ (⟨-14973, 10000⟩ : Q) (by decide)) (RsumL [negSq, negG1, negL, zT]) :=
    accum (by decide) (by decide) (by decide) hbSq v3 (by decide)
  have v5 : Rle (ofQ (⟨-9203, 10000⟩ : Q) (by decide))
      (RsumL [Rgamma_h, negSq, negG1, negL, zT]) :=
    accum (by decide) (by decide) (by decide) Rgamma_h_ge_577 v4 (by decide)
  have v6 : Rle (ofQ (⟨797, 10000⟩ : Q) (by decide)) (RsumL lam2L) :=
    accum (by decide) (by decide) (by decide) hbOne v5 (by decide)
  exact Rle_trans v6 (Rle_of_Req (Req_symm lam2_flat))

/-- `0` is not strictly positive (the `Pos` witness inequality `1/(n+1) < 0` is absurd). -/
theorem not_Pos_zero : ¬ Pos zero := by
  intro ⟨n, hn⟩
  simp only [Qlt, Qbound, zero_seq] at hn
  omega

/-- **The order clash**: a real cannot be strictly positive while its negation is non-negative
    (seq-level: `Pos` gives an approximant above `Qbound n`, `Rnonneg (−z)` pins it below). -/
theorem not_Pos_of_Rnonneg_Rneg {z : Real} (hn : Rnonneg (Rneg z)) : ¬ Pos z := by
  intro ⟨n, hlt⟩
  have h : Qle (neg (Qbound n)) (neg (z.seq n)) := hn n
  simp only [Qle, Qlt, Qbound, neg] at h hlt
  push_cast at h hlt
  have hneg : -(z.seq n).num * ((n : Int) + 1) = -((z.seq n).num * ((n : Int) + 1)) :=
    Int.neg_mul _ _
  rw [hneg] at h
  omega

/-- `λ₁ + λ₁ ≈ 2λ₁` — the doubled first coefficient meets its integer-coefficient form. -/
theorem Rlambda1_double_eq : Req (Radd Rlambda1 Rlambda1) Rtwolambda1 :=
  Req_trans (Req_symm (Rhalf_Radd Rtwolambda1 Rtwolambda1)) (Rhalf_add_self Rtwolambda1)

/-- **`Pos (2λ₂ − (λ₁ + λ₁))`** — the gap against the doubled `λ₁` directly. -/
theorem lambda_gap_pos_double : Pos (Rsub (Radd Rlambda2 Rlambda2) (Radd Rlambda1 Rlambda1)) :=
  Pos_congr (Radd_congr (Req_refl (Radd Rlambda2 Rlambda2))
    (Rneg_congr (Req_symm Rlambda1_double_eq))) lambda_gap_pos

/-- **`λ₁ ≉ λ₂` — the first certified separation of two Li coefficients.** If `λ₁ ≈ λ₂` then
    `λ₂ + λ₂ ≈ λ₁ + λ₁ ≈ 2λ₁` (`Rhalf` algebra), so the gap `2λ₂ − 2λ₁ ≈ 0`, contradicting
    `lambda_gap_pos`. -/
theorem Rlambda1_ne_Rlambda2 : ¬ Req Rlambda1 Rlambda2 := by
  intro h
  have hdd : Req (Radd Rlambda2 Rlambda2) Rtwolambda1 :=
    Req_trans (Radd_congr (Req_symm h) (Req_symm h))
      (Req_trans (Req_symm (Rhalf_Radd Rtwolambda1 Rtwolambda1)) (Rhalf_add_self Rtwolambda1))
  have hz : Req (Rsub (Radd Rlambda2 Rlambda2) Rtwolambda1) zero :=
    Req_trans (Radd_congr hdd (Req_refl (Rneg Rtwolambda1))) (Radd_neg Rtwolambda1)
  exact not_Pos_zero (Pos_congr hz lambda_gap_pos)

end UOR.Bridge.F1Square.Analysis
