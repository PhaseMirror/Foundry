/-
F1 square — **the pre-Hilbert layer, brick 46** (`MomentGram.lean`): **THE MOMENT SEQUENCES OBEY
A UNIFORM CAUCHY–SCHWARZ** — the cross moment sums are controlled by the two `ℓ²` energies, at
every truncation at once:

    `(Σ_{n<N} ⟨φ, xⁿ⟩·⟨ψ, xⁿ⟩)²  ≤  ‖φ̂‖²·‖ψ̂‖² = momentL2Sq φ · momentL2Sq ψ`

(`crossMomSum_sq_le`), uniformly in `N`. So the bilinear cross-pairing of two moment sequences
never exceeds the geometric bound set by their energies — the `ℓ²` inner-product geometry the
completion axis is about, now realized on genuine moment data.

The proof is the finite Hilbert core meeting brick 45. The moment sequence is literally a
coordinate vector (`momSeq φ n = ⟨φ, xⁿ⟩`), so the layer's sqrt-free finite Cauchy–Schwarz
(`cauchy_schwarz`, via the Lagrange identity) applies verbatim:
`(Σ_{n<N} ⟨φ,xⁿ⟩⟨ψ,xⁿ⟩)² ≤ (Σ_{n<N}⟨φ,xⁿ⟩²)(Σ_{n<N}⟨ψ,xⁿ⟩²)`. Then brick 45's
`momentSqSum φ N ≤ momentL2Sq φ` lifts each factor from the partial energy to the total, and
product monotonicity on nonnegatives closes it. No new limit is constructed — this is a uniform
bound on finite sums, so the `ℓ²` cross geometry is exhibited without a fresh completion.

HONEST SCOPE. A uniform Cauchy–Schwarz for the moment cross-sums of bounded-Lipschitz tests on
`[0,1]`. It is the `ℓ²` geometry of the moment map, not an inner product on a completed function
space, and nothing about the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MomentEnergyDetect
import Multiplicity.F1Square.Square.BandBridge

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The truncated cross moment sum `Σ_{n<N} ⟨φ, xⁿ⟩·⟨ψ, xⁿ⟩` — the finite inner product of the
    two moment sequences. -/
def crossMomSum (φ ψ : L2Test) (N : Nat) : Real := innerN (momSeq φ) (momSeq ψ) N

/-- The diagonal cross sum is the partial energy: `Σ_{n<N} ⟨φ,xⁿ⟩² = momentSqSum φ N`. -/
theorem crossMomSum_diag (φ : L2Test) (N : Nat) :
    Req (crossMomSum φ φ N) (momentSqSum φ N) := Req_refl _

/-- **THE UNIFORM CAUCHY–SCHWARZ FOR MOMENT SEQUENCES**: the squared cross moment sum is bounded
    by the product of the two `ℓ²` energies, at every truncation. -/
theorem crossMomSum_sq_le (φ ψ : L2Test) (N : Nat) :
    Rle (Rmul (crossMomSum φ ψ N) (crossMomSum φ ψ N))
        (Rmul (momentL2Sq φ) (momentL2Sq ψ)) := by
  -- the finite Cauchy–Schwarz on the moment coordinate vectors
  have hcs : Rle (Rmul (crossMomSum φ ψ N) (crossMomSum φ ψ N))
      (Rmul (innerN (momSeq φ) (momSeq φ) N) (innerN (momSeq ψ) (momSeq ψ) N)) :=
    cauchy_schwarz (momSeq φ) (momSeq ψ) N
  -- each diagonal factor is a partial energy, and partial energies sit below the total
  have hφ : Rle (innerN (momSeq φ) (momSeq φ) N) (momentL2Sq φ) := by
    refine Rle_trans (Rle_of_Req (crossMomSum_diag φ N)) (momentSqSum_le_momentL2Sq φ N)
  have hψ : Rle (innerN (momSeq ψ) (momSeq ψ) N) (momentL2Sq ψ) := by
    refine Rle_trans (Rle_of_Req (crossMomSum_diag ψ N)) (momentSqSum_le_momentL2Sq ψ N)
  refine Rle_trans hcs ?_
  refine Rle_trans (Rmul_le_Rmul_right
    (Rnonneg_congr (Req_symm (crossMomSum_diag ψ N))
      (Rnonneg_RsumN N (fun i _ => Rnonneg_Rmul_self (mellinMoment ψ i)))) hφ) ?_
  exact Rmul_le_Rmul_left (momentL2Sq_nonneg φ) hψ

end Multiplicity.UOR.Bridge.F1Square.Square
