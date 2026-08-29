/-
F1 square — **coefficient-congruence of the rational polynomial test** (`QPolyCoefCongr.lean`), the last
brick-6 substrate lemma of the Hausdorff *sufficiency* arc. The polynomial test's pairing depends on its
`ℚ`-coefficients only up to `Qeq`: coefficient vectors that agree rationally give the same `L²` pairing.

  `innerI_qPolyTest_coef_congr` :  `(∀ i, c_i ≈ c'_i)  ⟹  ⟨ψ, qPolyTest c d⟩ = ⟨ψ, qPolyTest c' d⟩`.

Distribute the pairing over the finite sum (`innerI_L2sumN`); each monomial pairing `⟨ψ, c_i·xⁱ⟩` is the
real scalar `ofQ c_i` times `⟨ψ, xⁱ⟩` (`innerI_constMul`), and `ofQ` respects `Qeq`, so the two sums
agree termwise (`RsumN_congr`).

Together with `innerI_qPolyTest_dim_inv` this is the full bridge the convergence brick needs: a
finitely-supported coefficient vector — the Riesz projection `p_N`, whose dimension-independence
(`pVec_dim_inv`, brick 6a) is a *pointwise* `Qeq` — reads as the *same* `L²` functional at any dimension
and under any `Qeq`-equal presentation, so two projections of different degree can be compared at a
common dimension.

HONEST SCOPE. `Qeq`-invariance of the *finite* polynomial test's pairing in its coefficient vector —
pure `L²`-linearity over `ℚ`-coefficient monomials. This is NOT the Riesz convergence / L²-limit (which
additionally needs a supplied Bessel convergence modulus — the next brick), NOT positivity. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.QPolyMember
import Foundations.F1.Square.ConstScale
import Foundations.F1.Square.MomentReconSum

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- A monomial's pairing depends on its coefficient only up to `Qeq`: `q ≈ q' ⟹ ⟨ψ, q·xⁱ⟩ = ⟨ψ, q'·xⁱ⟩`. -/
private theorem innerI_qMono_congr (ψ : L2Test) (q q' : Q) (hq : 0 < q.den) (hq' : 0 < q'.den)
    (i : Nat) (hqq' : Qeq q q') :
    Req (innerI ψ (qMonoTest q hq i)) (innerI ψ (qMonoTest q' hq' i)) := by
  refine Req_trans (innerI_constMul ψ (powTest i) (ofQ q hq) (Qabs_den_pos hq)
    (Qabs_num_nonneg q) (Rle_of_Req (Rabs_ofQ hq))) ?_
  refine Req_trans ?_ (Req_symm (innerI_constMul ψ (powTest i) (ofQ q' hq') (Qabs_den_pos hq')
    (Qabs_num_nonneg q') (Rle_of_Req (Rabs_ofQ hq'))))
  exact Rmul_congr (Req_of_seq_Qeq (fun _ => hqq')) (Req_refl _)

/-- **★ COEFFICIENT-CONGRUENCE**: coefficient vectors that agree rationally give the same polynomial-test
    pairing — `(∀ i, c_i ≈ c'_i) ⟹ ⟨ψ, qPolyTest c d⟩ = ⟨ψ, qPolyTest c' d⟩`. -/
theorem innerI_qPolyTest_coef_congr (ψ : L2Test) (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den)
    (hc' : ∀ i, 0 < (c' i).den) (d : Nat) (hcc' : ∀ i, Qeq (c i) (c' i)) :
    Req (innerI ψ (qPolyTest c hc d)) (innerI ψ (qPolyTest c' hc' d)) := by
  refine Req_trans (innerI_L2sumN ψ (fun i => qMonoTest (c i) (hc i) i) d) ?_
  refine Req_trans ?_ (Req_symm (innerI_L2sumN ψ (fun i => qMonoTest (c' i) (hc' i) i) d))
  exact RsumN_congr d (fun i _ => innerI_qMono_congr ψ (c i) (c' i) (hc i) (hc' i) i (hcc' i))

end Multiplicity.UOR.Bridge.F1Square.Square
