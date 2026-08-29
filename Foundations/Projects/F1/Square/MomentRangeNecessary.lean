/-
F1 square — **the moment map's range is confined: moments decay** (`MomentRangeNecessary.lean`),
the Hausdorff/surjectivity front (NECESSARY side). The completion transform `E ↦ E.moment` has an
inverse now closed in both directions (injectivity + reconstruction). The remaining question —
*surjectivity onto function space*, i.e. which raw sequences are moment sequences — is a range
characterization. This brick establishes the first NECESSARY condition, hence a genuine obstruction
to surjectivity onto arbitrary sequences:

  `L2Elt_moment_decay` :  `|E.moment n| ≤ √(energy / (2n+1))`   with `energy = 2·selfBnd(E.seq 0)+8`.

So the moments of a completed L² member **decay like `1/√n`**; a sequence that does not decay this
fast is NOT in the range. The proof is sqrt-free at the read level (integral Cauchy–Schwarz
`⟨E.seqⱼ, xⁿ⟩² ≤ ⟨E.seqⱼ,E.seqⱼ⟩·⟨xⁿ,xⁿ⟩ ≤ energy·(1/(2n+1))`, the uniform self-energy bound, and the
Hilbert value `⟨xⁿ,xⁿ⟩ = 1/(2n+1)`), then `Rsqrt` on the rational radicand `energy/(2n+1)`, inherited
through the limit by `Rabs_Rlim_le`.

HONEST SCOPE. A NECESSARY condition on the moment map's range (moments decay) — the transform is NOT
surjective onto arbitrary sequences. This is NOT the full Hausdorff characterization (which raw
sequences ARE moment sequences — the sufficient direction needs the Riesz/Hilbert-system construction),
NOT positivity. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.PairingIUEnergy
import Foundations.F1.Square.HilbertGram
import Foundations.F1.Square.L2ElementSpace

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Local helpers (private) — re-derived from the reconstruction arc's privates.
-- ===========================================================================

/-- Negation reverses `≤` (local copy). -/
private theorem Rneg_le_Rneg {a b : Real} (h : Rle a b) : Rle (Rneg b) (Rneg a) :=
  Rle_of_Rnonneg_Rsub
    (Rnonneg_congr
      (Req_symm (Req_trans (Radd_congr (Req_refl (Rneg a)) (Rneg_Rneg b)) (Radd_comm (Rneg a) b)))
      (Rnonneg_Rsub_of_Rle h))

/-- `(∀ m, |X m| ≤ B) ⟹ |lim X| ≤ B` (local copy). -/
private theorem Rabs_Rlim_le {X : Nat → Real} (hX : RReg X) {B : Real}
    (hb : ∀ m, Rle (Rabs (X m)) B) : Rle (Rabs (Rlim X hX)) B := by
  apply Rabs_le_of_both
  · exact Rlim_le_const hX (fun m => Rle_of_Rabs_le (hb m))
  · exact Rle_trans (Rneg_le_Rneg (const_le_Rlim hX (fun m => Rneg_le_of_Rabs_le (hb m))))
      (Rle_of_Req (Rneg_Rneg B))

/-- `|z|² ≈ z²` (local copy). -/
private theorem abs_sq_loc (z : Real) : Req (Rmul (Rabs z) (Rabs z)) (Rmul z z) :=
  Req_trans (Req_symm (Rabs_Rmul z z)) (Rabs_of_nonneg (Rnonneg_Rmul_self z))

-- ===========================================================================
-- The moment-decay bound.
-- ===========================================================================

/-- **★ THE MOMENTS OF A COMPLETED L² MEMBER DECAY LIKE `1/√n`**: `|E.moment n| ≤ √(energy/(2n+1))`
    with `energy = 2·selfBnd(E.seq 0) + 8`. A NECESSARY condition on the moment map's range — a
    sequence that does not decay this fast is not a moment sequence, so the transform is not
    surjective onto arbitrary sequences. Read-level integral Cauchy–Schwarz + uniform self-energy +
    `⟨xⁿ,xⁿ⟩ = 1/(2n+1)`, `Rsqrt` on the rational radicand, inherited through the limit. -/
theorem L2Elt_moment_decay (E : L2Elt) (n : Nat) :
    Rle (Rabs (E.moment n))
        (Rsqrt (⟨2 * ((selfBnd (E.seq 0) : Nat) : Int) + 8, 2 * n + 1⟩ : Q)
          (Nat.succ_pos (2 * n)) (by simp only [Qle]; push_cast; omega)) := by
  have hrqd : 0 < (⟨2 * ((selfBnd (E.seq 0) : Nat) : Int) + 8, 2 * n + 1⟩ : Q).den :=
    Nat.succ_pos (2 * n)
  have hrqn : Qle (⟨0, 1⟩ : Q) (⟨2 * ((selfBnd (E.seq 0) : Nat) : Int) + 8, 2 * n + 1⟩ : Q) := by
    simp only [Qle]; push_cast; omega
  -- `E.moment n = pairingIU E.seq (xⁿ)`; every read is `≤ √(energy/(2n+1))`.
  refine Rabs_Rlim_le (pairingIU_RReg E.cauchy (powTest n)) (fun m => ?_)
  refine Rle_of_Rsq_le (Rnonneg_Rabs _) (Rsqrt_nonneg _ hrqd hrqn) ?_
  -- `|⟨E.seqⱼ, xⁿ⟩|² = ⟨E.seqⱼ,xⁿ⟩² ≤ ⟨E.seqⱼ,E.seqⱼ⟩·⟨xⁿ,xⁿ⟩ ≤ energy·(1/(2n+1)) = rq = (√rq)²`.
  refine Rle_trans (Rle_of_Req (abs_sq_loc _)) ?_
  refine Rle_trans (innerI_cauchy_schwarz (E.seq (selfBnd (powTest n) * (m + 1))) (powTest n)) ?_
  refine Rle_trans (Rmul_le_Rmul_both (innerI_self_nonneg _)
    (Rnonneg_ofQ (Nat.succ_pos (n + n)) (by show (0 : Int) ≤ 1; decide))
    (innerI_self_le_uniform E.seq E.cauchy (selfBnd (powTest n) * (m + 1)))
    (Rle_of_Req (innerI_powTest_hilbert n n))) ?_
  -- `ofQ energy · ofQ (1/(2n+1)) = ofQ rq`, and `rq = (√rq)²`.
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ Nat.one_pos (Nat.succ_pos (n + n)))) ?_
  refine Rle_trans
    (Rle_of_Req (ofQ_congr (Qmul_den_pos Nat.one_pos (Nat.succ_pos (n + n))) hrqd ?_))
    (Rle_of_Req (Req_symm (Rsqrt_sq _ hrqd hrqn)))
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **★ THE MOMENT FUNCTIONAL IS L²-BOUNDED**: `|E.pairing ψ| ≤ √(energy·selfBnd ψ)` with
    `energy = 2·selfBnd(E.seq 0)+8`, for **every** test `ψ`. The extended pairing is a bounded linear
    functional — the *characterizing* necessary condition (by Riesz, an L²-bounded moment functional is
    exactly one representable by an L² element), so the moment transform's range is confined to
    L²-bounded functionals, not arbitrary sequences. Same read-level integral Cauchy–Schwarz + uniform
    self-energy + `⟨ψ,ψ⟩ ≤ selfBnd ψ`, `Rsqrt` on the rational radicand, inherited through the limit. -/
theorem L2Elt_pairing_bounded (E : L2Elt) (ψ : L2Test) :
    Rle (Rabs (E.pairing ψ))
        (Rsqrt (⟨(2 * ((selfBnd (E.seq 0) : Nat) : Int) + 8) * ((selfBnd ψ : Nat) : Int), 1⟩ : Q)
          Nat.one_pos
          (by have h : (0 : Int) ≤ (2 * ((selfBnd (E.seq 0) : Nat) : Int) + 8)
                  * ((selfBnd ψ : Nat) : Int) := Int.mul_nonneg (by omega) (Int.ofNat_nonneg _)
              simp only [Qle]; push_cast; omega)) := by
  have hrqd : 0 < (⟨(2 * ((selfBnd (E.seq 0) : Nat) : Int) + 8) * ((selfBnd ψ : Nat) : Int), 1⟩ : Q).den :=
    Nat.one_pos
  have hrqn : Qle (⟨0, 1⟩ : Q)
      (⟨(2 * ((selfBnd (E.seq 0) : Nat) : Int) + 8) * ((selfBnd ψ : Nat) : Int), 1⟩ : Q) := by
    have h : (0 : Int) ≤ (2 * ((selfBnd (E.seq 0) : Nat) : Int) + 8) * ((selfBnd ψ : Nat) : Int) :=
      Int.mul_nonneg (by omega) (Int.ofNat_nonneg _)
    simp only [Qle]; push_cast; omega
  refine Rabs_Rlim_le (pairingIU_RReg E.cauchy ψ) (fun m => ?_)
  refine Rle_of_Rsq_le (Rnonneg_Rabs _) (Rsqrt_nonneg _ hrqd hrqn) ?_
  refine Rle_trans (Rle_of_Req (abs_sq_loc _)) ?_
  refine Rle_trans (innerI_cauchy_schwarz (E.seq (selfBnd ψ * (m + 1))) ψ) ?_
  refine Rle_trans (Rmul_le_Rmul_both (innerI_self_nonneg _)
    (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg _))
    (innerI_self_le_uniform E.seq E.cauchy (selfBnd ψ * (m + 1)))
    (innerI_self_le_selfBnd ψ)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ Nat.one_pos Nat.one_pos)) ?_
  exact Rle_of_Req (Req_symm (Rsqrt_sq _ hrqd hrqn))

end Multiplicity.UOR.Bridge.F1Square.Square
