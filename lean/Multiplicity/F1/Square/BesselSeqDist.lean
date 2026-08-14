/-
F1 square — **the Riesz-projection sequence and its L²-distance** (`BesselSeqDist.lean`), the penultimate
brick of the moment-realization sub-arc. The `L²`-limit of a valid moment sequence is realised by the
sequence of its Riesz projections, read as polynomial tests at growing dimension:

  `besselSeq μ m`     :  `qPolyTest (p_m) (m+1)` — the degree-`m` Riesz projection as an `L²` test;
  `besselSeq_dist2I`  :  `d²(besselSeq μ j, besselSeq μ k) = ofQ (qHil (p_j − p_k) (p_j − p_k) D)`
                          at any common dimension `D > j, k`.

Two projections of different degree are compared by bringing both to a common dimension: the per-index
bridge `besselSeq_innerI_bridge` (dimension-invariance `innerI_qPolyTest_dim_inv` past the projection's
support, then coefficient-congruence `innerI_qPolyTest_coef_congr` under the dimension-independence
`pVec_dim_inv`) shows each `besselSeq` pairs like the projection recomputed at `D`; the general
`dist2I_congr` (the squared distance depends only on the `innerI`-functional of its two arguments)
transports the distance to the common dimension, where the distance bridge `qPolyTest_dist2I` reads it
as the rational Hilbert form of the coefficient difference.

Composed with the Bessel-tail identity (`pVec_diff_normSq`, brick 5.5) this is exactly `ofQ(‖p_k‖² −
‖p_j‖²)` for `j ≤ k` — the squared increment the convergence brick bounds by a supplied rational
modulus.

HONEST SCOPE. The realising sequence and the *identity* for its squared `L²`-distance — unconditional,
finite ℚ arithmetic wrapped in `L²`-bilinearity. This is NOT the convergence itself (`L2CauchyU`, which
needs a supplied Bessel modulus) and NOT the limit element / its moments — the final brick. NOT
positivity. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.RieszDimInv
import Multiplicity.F1Square.Square.QPolyDimInv
import Multiplicity.F1Square.Square.QPolyCoefCongr
import Multiplicity.F1Square.Square.QPolyDistBridge

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The Riesz projection as an L² test, and its support.
-- ===========================================================================

/-- `b ≈ 0 ⟹ a·b ≈ 0`. -/
private theorem Qmul_zero_of_right {a b : Q} (hb : Qeq b (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have hbn : b.num = 0 := by simp only [Qeq] at hb; push_cast at hb; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [hbn]; push_cast; ring_uor

/-- The Riesz projection vanishes strictly above its degree (it is a combination of `gsFam_k`, `k ≤ N`,
    each supported on `[0,k]`). -/
private theorem pVec_support (μ : Nat → Q) (d N idx : Nat) (hidx : N < idx) :
    Qeq (pVec μ d gsFam N idx) (⟨0, 1⟩ : Q) := by
  show Qeq (qsumL (fun k => mul (aCoef μ d gsFam k) (gsFam k idx)) (List.range (N + 1))) (⟨0, 1⟩ : Q)
  refine qsumL_zero_mem (List.range (N + 1)) (fun k hk => ?_)
  have hkN : k ≤ N := by have := List.mem_range.mp hk; omega
  exact Qmul_zero_of_right (gsFam_support k idx (by omega))

/-- **The degree-`m` Riesz projection as an `L²` test** `Σ_{k≤m} aCoef_k·q_k`, at its minimal
    dimension `m+1`. -/
def besselSeq (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (m : Nat) : L2Test :=
  qPolyTest (pVec μ (m + 1) gsFam m) (pVec_den μ (m + 1) gsFam gsFam_den hμ m) (m + 1)

/-- **The per-index bridge**: `besselSeq μ m` pairs like the projection recomputed at any common
    dimension `D > m` — dimension-invariance past the support, then coefficient-congruence under the
    projection's dimension-independence. -/
theorem besselSeq_innerI_bridge (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (m D : Nat) (hmD : m < D)
    (χ : L2Test) :
    Req (innerI χ (besselSeq μ hμ m))
      (innerI χ (qPolyTest (pVec μ D gsFam m) (pVec_den μ D gsFam gsFam_den hμ m) D)) := by
  -- bring `besselSeq` (dimension m+1) up to dimension D, same coefficients
  refine Req_trans (Req_symm (innerI_qPolyTest_dim_inv χ (pVec μ (m + 1) gsFam m)
    (pVec_den μ (m + 1) gsFam gsFam_den hμ m) (m + 1)
    (fun i hi => pVec_support μ (m + 1) m i (by omega)) D hmD)) ?_
  -- swap the coefficient presentation to the one recomputed at D
  exact innerI_qPolyTest_coef_congr χ (pVec μ (m + 1) gsFam m) (pVec μ D gsFam m)
    (pVec_den μ (m + 1) gsFam gsFam_den hμ m) (pVec_den μ D gsFam gsFam_den hμ m) D
    (fun i => pVec_dim_inv μ hμ m (m + 1) D (Nat.lt_succ_self m) hmD i)

-- ===========================================================================
-- The squared L²-distance depends only on the innerI-functional of its arguments.
-- ===========================================================================

/-- If two tests pair identically against every test, they may be swapped in a pairing. -/
private theorem innerI_swap {X Y X' Y' : L2Test}
    (hX : ∀ χ, Req (innerI χ X) (innerI χ X')) (hY : ∀ χ, Req (innerI χ Y) (innerI χ Y')) :
    Req (innerI X Y) (innerI X' Y') :=
  Req_trans (hY X) (Req_trans (innerI_symm X Y')
    (Req_trans (hX Y') (innerI_symm Y' X')))

/-- The squared-distance four-term expansion: `d²(A,B) = (⟨A,A⟩−⟨A,B⟩) − (⟨B,A⟩−⟨B,B⟩)`. -/
private theorem dist2I_expand (A B : L2Test) :
    Req (dist2I A B)
      (Rsub (Rsub (innerI A A) (innerI A B)) (Rsub (innerI B A) (innerI B B))) :=
  Req_trans (innerI_sub_left A B (L2Test.sub A B))
    (Rsub_congr (innerI_sub_right A A B) (innerI_sub_right B A B))

/-- **★ THE DISTANCE DEPENDS ONLY ON THE `innerI`-FUNCTIONAL**: if `A,B` pair like `A',B'` against every
    test, their squared distances agree. -/
theorem dist2I_congr {A A' B B' : L2Test}
    (hA : ∀ χ, Req (innerI χ A) (innerI χ A')) (hB : ∀ χ, Req (innerI χ B) (innerI χ B')) :
    Req (dist2I A B) (dist2I A' B') :=
  Req_trans (dist2I_expand A B)
    (Req_trans
      (Rsub_congr (Rsub_congr (innerI_swap hA hA) (innerI_swap hA hB))
        (Rsub_congr (innerI_swap hB hA) (innerI_swap hB hB)))
      (Req_symm (dist2I_expand A' B')))

-- ===========================================================================
-- ★ The L²-distance of two Riesz projections.
-- ===========================================================================

/-- **★ THE SEQUENCE'S SQUARED DISTANCE**: at any common dimension `D > j, k`,
    `d²(besselSeq μ j, besselSeq μ k) = ofQ (qHil (p_j − p_k) (p_j − p_k) D)`. -/
theorem besselSeq_dist2I (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (j k D : Nat)
    (hjD : j < D) (hkD : k < D) :
    Req (dist2I (besselSeq μ hμ j) (besselSeq μ hμ k))
      (ofQ (qHil (fun i => Qsub (pVec μ D gsFam j i) (pVec μ D gsFam k i))
                 (fun i => Qsub (pVec μ D gsFam j i) (pVec μ D gsFam k i)) D)
        (qHil_den_pos _ _
          (fun i => add_den_pos (pVec_den μ D gsFam gsFam_den hμ j i)
            (neg_den_pos (pVec_den μ D gsFam gsFam_den hμ k i)))
          (fun i => add_den_pos (pVec_den μ D gsFam gsFam_den hμ j i)
            (neg_den_pos (pVec_den μ D gsFam gsFam_den hμ k i))) D)) := by
  refine Req_trans (dist2I_congr (A := besselSeq μ hμ j) (B := besselSeq μ hμ k)
    (besselSeq_innerI_bridge μ hμ j D hjD) (besselSeq_innerI_bridge μ hμ k D hkD)) ?_
  exact qPolyTest_dist2I (pVec μ D gsFam j) (pVec μ D gsFam k)
    (pVec_den μ D gsFam gsFam_den hμ j) (pVec_den μ D gsFam gsFam_den hμ k) D

end Multiplicity.UOR.Bridge.F1Square.Square
