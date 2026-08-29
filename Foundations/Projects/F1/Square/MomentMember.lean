/-
F1 square — **the pre-Hilbert layer, brick 44** (`MomentMember.lean`): **THE COMPLETED MEMBER
*IS* THE MOMENT SEQUENCE** — the identification brick 43 deliberately did not claim.

Brick 43 realized the completion axis's interface on genuine `ℓ²` data: the quadratically
rescaled moment cuts satisfy `SqCauchyU`, so brick 17 constructs a limit member
`limMemberU (momIdx φ)` and proves the cuts converge to it in `d²` at every truncation. But a
constructed limit is only as good as its identification, and here it is exact:

    `limMemberU (momIdx φ) _ i  ≈  ⟨φ, xⁱ⟩`   (`limMemberU_momIdx`),

so the completed object is `momSeq φ` on the nose — the very sequence the skeleton's
unconditional positivity consumes (`weil_psd_on_cosupport`). Strong convergence therefore
reads directly on the moment sequence: `d²(momIdx φ j, momSeq φ) ≤ N·(2/(j+1))²` at every
truncation (`momIdx_converges_to_momSeq`).

The identification is where brick 38's SHARP decay earns its keep a second time. The limit
value is evaluated at a *uniform* linear rate (`Rlim_eval_real_rate`), which needs
`|momIdx φ j i − ⟨φ,xⁱ⟩| ≤ C/(j+1)` for EVERY `j`, not merely eventually. Below the cut the
difference is literally zero; above it the difference is the moment itself, and there the cut
condition `c(j+1)² ≤ i` forces `j+1 ≤ i`, so the decay bound `|⟨φ,xⁱ⟩| ≤ M/(i+1)` is already
`≤ C/(j+1)`. A merely bounded moment sequence would leave only an eventual bound, which the
uniform-rate evaluator cannot use.

HONEST SCOPE. The completed member of the moment cuts, identified. Still the compact `[0,1]`
moment map of a bounded-Lipschitz test — not the `L²` function-space completion, and nothing
about the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MomentCompletion
import Foundations.F1.Square.BandBridge

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The rescale dominates the test's own bound numerator: `M.num ≤ momScale φ`. -/
theorem momScale_ge_num (φ : L2Test) : φ.M.num ≤ (momScale φ : Int) := by
  have hself : ((φ.M.num.natAbs : Int)) * ((φ.M.num.natAbs : Int)) = φ.M.num * φ.M.num :=
    Int.natAbs_mul_self' φ.M.num
  have hc : (momScale φ : Int) = 2 * (φ.M.num * φ.M.num) + 1 := by
    show ((2 * φ.M.num.natAbs * φ.M.num.natAbs + 1 : Nat) : Int) = _
    push_cast
    rw [← hself]
    ring_uor
  have hnn : (0 : Int) ≤ φ.M.num := φ.hMn
  by_cases hz : φ.M.num = 0
  · omega
  · have h1 : φ.M.num * 1 ≤ φ.M.num * φ.M.num :=
      Int.mul_le_mul_of_nonneg_left (by omega) hnn
    omega

/-- Above the quadratic cut the index dominates the rescale parameter: `c(j+1)² ≤ i` forces
    `j + 1 ≤ i`. -/
theorem cut_index_le (φ : L2Test) {i j : Nat}
    (h : ¬ i < momScale φ * ((j + 1) * (j + 1))) : j + 1 ≤ i := by
  have hle : momScale φ * ((j + 1) * (j + 1)) ≤ i := Nat.not_lt.mp h
  have h1 : (j + 1) * (j + 1) ≤ momScale φ * ((j + 1) * (j + 1)) :=
    Nat.le_mul_of_pos_left _ (Nat.succ_pos _)
  have h2 : j + 1 ≤ (j + 1) * (j + 1) := Nat.le_mul_of_pos_right _ (Nat.succ_pos j)
  omega

/-- The moment bound at index `i`, read against the rescale rate at index `j`, above the cut. -/
private theorem moment_rate_cross (φ : L2Test) {i j : Nat} (hij : j + 1 ≤ i) :
    Qle (mul φ.M (⟨1, i + 1⟩ : Q)) (⟨(momScale φ : Int), j + 1⟩ : Q) := by
  show φ.M.num * 1 * ((j + 1 : Nat) : Int)
      ≤ (momScale φ : Int) * ((φ.M.den * (i + 1) : Nat) : Int)
  push_cast
  have hij' : ((j : Int) + 1) ≤ ((i : Int) + 1) := by omega
  have hnum : (0 : Int) ≤ φ.M.num := φ.hMn
  have hc : φ.M.num ≤ (momScale φ : Int) := momScale_ge_num φ
  have hcnn : (0 : Int) ≤ (momScale φ : Int) := Int.ofNat_nonneg _
  have hd : (1 : Int) ≤ (φ.M.den : Int) := by have := φ.hMd; omega
  have s1 : φ.M.num * ((j : Int) + 1) ≤ φ.M.num * ((i : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_left hij' hnum
  have s2 : φ.M.num * ((i : Int) + 1) ≤ (momScale φ : Int) * ((i : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right hc (by omega)
  have sin : (1 : Int) * ((i : Int) + 1) ≤ (φ.M.den : Int) * ((i : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right hd (by omega)
  have ein : (1 : Int) * ((i : Int) + 1) = ((i : Int) + 1) := by ring_uor
  have s3 : (momScale φ : Int) * ((i : Int) + 1)
      ≤ (momScale φ : Int) * ((φ.M.den : Int) * ((i : Int) + 1)) :=
    Int.mul_le_mul_of_nonneg_left (by omega) hcnn
  have e2 : φ.M.num * 1 * ((j : Int) + 1) = φ.M.num * ((j : Int) + 1) := by ring_uor
  omega

/-- **THE COMPLETED MEMBER IS THE MOMENT SEQUENCE**: coordinate `i` of the truncation-uniform
    limit member of the moment cuts is `⟨φ, xⁱ⟩`. -/
theorem limMemberU_momIdx (φ : L2Test) (i : Nat) :
    Req (limMemberU (momIdx φ) (momIdx_sqCauchyU φ) i) (mellinMoment φ i) := by
  show Req (Rlim (fun j => innerN (momIdx φ j) (indic i) (i + 1))
      (pairing_RReg (sqCauchy_pairing (momIdx_sqCauchyU φ (i + 1)) i))) (mellinMoment φ i)
  refine Rlim_eval_real_rate _ (mellinMoment φ i) (C := momScale φ) (fun j => ?_)
  have hcoord : Req (innerN (momIdx φ j) (indic i) (i + 1)) (momIdx φ j i) :=
    fourierC_indic (momIdx φ j) (Nat.lt_succ_self i)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr hcoord (Req_refl _)))) ?_
  by_cases hcut : i < momScale φ * ((j + 1) * (j + 1))
  · have hval : Req (momIdx φ j i) (mellinMoment φ i) := by
      show Req (if i < momScale φ * ((j + 1) * (j + 1)) then mellinMoment φ i else zero)
        (mellinMoment φ i)
      rw [if_pos hcut]
      exact Req_refl _
    refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
      (Rsub_congr hval (Req_refl _)) (Radd_neg (mellinMoment φ i))))) ?_
    refine Rle_trans (Rle_of_Req Rabs_zero) ?_
    exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (Nat.succ_pos j) (Int.ofNat_nonneg _))
  · have hval : Req (momIdx φ j i) zero := by
      show Req (if i < momScale φ * ((j + 1) * (j + 1)) then mellinMoment φ i else zero) zero
      rw [if_neg hcut]
      exact Req_refl _
    refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr hval (Req_refl _)))) ?_
    refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans (Radd_comm zero _)
      (Radd_zero (Rneg (mellinMoment φ i)))))) ?_
    refine Rle_trans (Rle_of_Req (Rabs_Rneg (mellinMoment φ i))) ?_
    refine Rle_trans (mellinMoment_abs_le φ i) ?_
    exact Rle_ofQ_ofQ _ (Nat.succ_pos j) (moment_rate_cross φ (cut_index_le φ hcut))

/-- **STRONG CONVERGENCE, ON THE MOMENT SEQUENCE ITSELF**: the rescaled moment cuts converge
    to `momSeq φ` in the squared distance at every truncation. -/
theorem momIdx_converges_to_momSeq (φ : L2Test) (N j : Nat) :
    Rle (dist2 (momIdx φ j) (momSeq φ) N)
      (ofQ (mul (⟨(N : Int), 1⟩ : Q) (mul (⟨2, j + 1⟩ : Q) (⟨2, j + 1⟩ : Q)))
        (Qmul_den_pos Nat.one_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)))) := by
  refine Rle_trans (Rle_of_Req (innerN_congr N
    (fun i _ => Rsub_congr (Req_refl _) (Req_symm (limMemberU_momIdx φ i)))
    (fun i _ => Rsub_congr (Req_refl _) (Req_symm (limMemberU_momIdx φ i))))) ?_
  exact momIdx_completes φ N j

end Multiplicity.UOR.Bridge.F1Square.Square
