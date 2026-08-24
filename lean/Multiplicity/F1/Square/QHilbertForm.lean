/-
F1 square — **the rational Hilbert form ↔ `innerI` bridge** (`QHilbertForm.lean`).

For two rational coefficient vectors `c, c' : Nat → Q` the **rational Hilbert form** is the exact
`ℚ`-value

    `qHil c c' d = Σ_{i,j<d} c_i · c'_j / (i+j+1)`,

the double contraction of `c, c'` against the Hilbert matrix, read off the `List`-indexed rational
sum `qsumL` with no denominator clearing. This file welds it to the *analytic* side: the `L²` inner
product of the two rational polynomial tests `qPolyTest c`, `qPolyTest c'` is exactly the embedded
rational Hilbert form,

    `⟨qPolyTest c, qPolyTest c'⟩ ≈ ofQ (qHil c c' d)`   (`innerI_qPolyTest_qPolyTest`).

The proof distributes the pairing over the outer polynomial (`innerI_L2sumN`), pulls each rational
coefficient `c'_j` through with `innerI_constMul`, reads the residual monomial pairing as the moment
`⟨qPolyTest c, xʲ⟩ = ofQ (Σ_{i<d} c_i/(i+j+1))` (`mellinMoment_qPolyTest`), multiplies the two
embedded rationals (`Rmul_ofQ_ofQ`), and collapses the finite real sum of `ofQ`-terms to one `qsumL`
(`RsumN_ofQ_qsumL_range`).

HONEST SCOPE. This is the identity of the rational Hilbert form with the `L²` inner product of
rational polynomials — the FOUNDATION for the constructive moment-problem sufficiency arc (building
an `L²` element from a valid moment sequence via orthogonal polynomials / Hausdorff sufficiency). It
is NOT positivity (definiteness/PSD of the form), and NOT the moment-problem result itself. Step 4 is
RH; crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.QPolyMember
import Multiplicity.F1.Square.MomentReconSum

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- 1. The rational Hilbert form and its positive denominator.
-- ===========================================================================

/-- **The rational Hilbert form** `Σ_{i,j<d} c_i · c'_j / (i+j+1)` — the double contraction of the two
    rational coefficient vectors against the Hilbert matrix, an exact `ℚ`-value with no clearing. -/
def qHil (c c' : Nat → Q) (d : Nat) : Q :=
  qsumL (fun j => mul (c' j)
      (qsumL (fun i => mul (c i) (⟨1, i + j + 1⟩ : Q)) (List.range d)))
    (List.range d)

/-- The rational Hilbert form has a positive denominator, so it may be embedded via `ofQ`. -/
theorem qHil_den_pos (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hc' : ∀ i, 0 < (c' i).den)
    (d : Nat) : 0 < (qHil c c' d).den :=
  qsumL_den _
    (fun j => Qmul_den_pos (hc' j)
      (qsumL_den _ (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + j))) (List.range d)))
    (List.range d)

-- ===========================================================================
-- 2. ★ THE BRIDGE: the L² inner product of rational polynomials is the rational Hilbert form.
-- ===========================================================================

/-- **★ THE BRIDGE**: the `L²` inner product of the two rational polynomial tests is the embedded
    rational Hilbert form, `⟨qPolyTest c, qPolyTest c'⟩ ≈ ofQ (qHil c c')`. Distribute the pairing over
    the outer polynomial (`innerI_L2sumN`); pull each coefficient `c'_j` out (`innerI_constMul`); the
    residual monomial pairing is the moment `ofQ (Σ_{i<d} c_i/(i+j+1))` (`mellinMoment_qPolyTest`);
    multiply the embedded rationals (`Rmul_ofQ_ofQ`) and collapse the real sum to one `qsumL`
    (`RsumN_ofQ_qsumL_range`). -/
theorem innerI_qPolyTest_qPolyTest (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den)
    (hc' : ∀ i, 0 < (c' i).den) (d : Nat) :
    Req (innerI (qPolyTest c hc d) (qPolyTest c' hc' d))
      (ofQ (qHil c c' d) (qHil_den_pos c c' hc hc' d)) := by
  -- each outer term: `⟨qPolyTest c, c'_j·xʲ⟩ ≈ ofQ (c'_j · Σ_{i<d} c_i/(i+j+1))`.
  have hterm : ∀ j, Req (innerI (qPolyTest c hc d) (qMonoTest (c' j) (hc' j) j))
      (ofQ (mul (c' j) (qsumL (fun i => mul (c i) (⟨1, i + j + 1⟩ : Q)) (List.range d)))
        (Qmul_den_pos (hc' j)
          (qsumL_den _ (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + j))) (List.range d)))) := by
    intro j
    refine Req_trans (innerI_constMul (qPolyTest c hc d) (powTest j) (ofQ (c' j) (hc' j))
      (Qabs_den_pos (hc' j)) (Qabs_num_nonneg (c' j)) (Rle_of_Req (Rabs_ofQ (hc' j)))) ?_
    refine Req_trans (Rmul_congr (Req_refl (ofQ (c' j) (hc' j)))
      (mellinMoment_qPolyTest c hc d j)) ?_
    exact Rmul_ofQ_ofQ (hc' j)
      (qsumL_den _ (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + j))) (List.range d))
  -- distribute over the outer polynomial, apply the term identity, collapse the real sum.
  refine Req_trans (innerI_L2sumN (qPolyTest c hc d) (fun j => qMonoTest (c' j) (hc' j) j) d) ?_
  refine Req_trans (RsumN_congr d (fun j _ => hterm j)) ?_
  exact RsumN_ofQ_qsumL_range
    (fun j => mul (c' j) (qsumL (fun i => mul (c i) (⟨1, i + j + 1⟩ : Q)) (List.range d)))
    (fun j => Qmul_den_pos (hc' j)
      (qsumL_den _ (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + j))) (List.range d))) d

end Multiplicity.UOR.Bridge.F1Square.Square
