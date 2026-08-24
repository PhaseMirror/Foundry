/-
F1 square — **the pre-Hilbert layer, brick 45** (`MomentEnergyDetect.lean`): **THE ENERGY
DETECTS THE MOMENTS** — the "from the limit" companion to brick 42, supplying the direction the
completion layer previously lacked:

    `⟨φ, xⁿ⟩²  ≤  ‖φ̂‖² = momentL2Sq φ`   for every `n`   (`mellinMoment_sq_le_momentL2Sq`),

so **any moment that is apart from zero forces the energy apart from zero**
(`momentL2Sq_pos_of_moment`). Brick 42 bounded the energy from ABOVE by a co-support depth;
this brick bounds it from BELOW by every single squared moment, and the two directions together
say the energy sees exactly the moment data.

The enabling lemma is that a partial energy sits below the total: `momentSqSum φ N ≤ momentL2Sq φ`
(`momentSqSum_le_momentL2Sq`). This is the `X k ≤ lim X` direction — available because the
rescaled partial sums are monotone, so `term_le_Rlim` applies; a `≤ Rlim` from a fixed term was
the one comparison the completion axis did not yet have (`Rlim_le_ofQ` and friends only bound the
limit from above). Every partial sum then reaches the limit through the rescaled index
(`N ≤ momScale·(N+1)`, monotonicity), and a single squared moment reaches it through
`⟨φ,xⁿ⟩² ≤ momentSqSum φ (n+1)` (the tail of the sum is nonnegative).

The capstone realizes it: the constructed `K = 3` member `deep3` has third moment `−1/2520`,
apart from zero, so `Pos (momentL2Sq deep3)` — a certified NONZERO moment energy, consistent
with `deep3` being a genuinely nonzero test that is NOT full-co-support.

HONEST SCOPE. A lower bound on the `ℓ²` moment energy of a bounded-Lipschitz test by its
individual squared moments — still the compact `[0,1]` moment map, nothing about the Weil form.
It does not settle determinacy (whether a nonzero test can have ALL moments zero — that would
need `momentL2Sq φ = 0 → φ = 0`, i.e. a moment-problem uniqueness this does not provide). Step 4
is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MomentNorm
import Multiplicity.F1.Square.CoSupportStrict

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **A partial energy sits below the total**: `Σ_{n<N} ⟨φ, xⁿ⟩² ≤ momentL2Sq φ`. The rescaled
    partial sums are monotone, so `term_le_Rlim` places each below the limit; the plain partial
    sum `momentSqSum φ N` reaches its rescaled read `momentSqIdx φ N` because
    `N ≤ momScale·(N+1)`. -/
theorem momentSqSum_le_momentL2Sq (φ : L2Test) (N : Nat) :
    Rle (momentSqSum φ N) (momentL2Sq φ) := by
  have hidx : Rle (momentSqIdx φ N) (momentL2Sq φ) :=
    term_le_Rlim (momentSqIdx_RReg φ) (fun i j h => momentSqIdx_mono φ h) N
  -- `momentSqSum φ N ≤ momentSqSum φ (momScale·(N+1)) = momentSqIdx φ N`
  have hle : N ≤ momScale φ * (N + 1) := by
    have h1 : N + 1 ≤ momScale φ * (N + 1) := Nat.le_mul_of_pos_left _ (Nat.succ_pos _)
    omega
  obtain ⟨d, hd⟩ := Nat.le.dest hle
  have hstep : Rle (momentSqSum φ N) (momentSqIdx φ N) := by
    show Rle (momentSqSum φ N) (momentSqSum φ (momScale φ * (N + 1)))
    rw [← hd]
    exact momentSqSum_mono φ N d
  exact Rle_trans hstep hidx

/-- **THE ENERGY DOMINATES EVERY SQUARED MOMENT**: `⟨φ, xⁿ⟩² ≤ momentL2Sq φ`. -/
theorem mellinMoment_sq_le_momentL2Sq (φ : L2Test) (n : Nat) :
    Rle (Rmul (mellinMoment φ n) (mellinMoment φ n)) (momentL2Sq φ) := by
  -- `⟨φ,xⁿ⟩²` is the last term of `momentSqSum φ (n+1) = momentSqSum φ n + ⟨φ,xⁿ⟩²`.
  have hterm : Rle (Rmul (mellinMoment φ n) (mellinMoment φ n)) (momentSqSum φ (n + 1)) :=
    Rle_self_Radd_left (Rnonneg_RsumN n
      (fun i _ => Rnonneg_Rmul_self (mellinMoment φ i)))
  exact Rle_trans hterm (momentSqSum_le_momentL2Sq φ (n + 1))

/-- **THE ENERGY DETECTS THE MOMENTS**: a squared moment apart from zero forces the energy apart
    from zero. -/
theorem momentL2Sq_pos_of_moment (φ : L2Test) (n : Nat)
    (h : Pos (Rmul (mellinMoment φ n) (mellinMoment φ n))) : Pos (momentL2Sq φ) :=
  Pos_mono (mellinMoment_sq_le_momentL2Sq φ n) h

-- ===========================================================================
-- The capstone: a constructed member's certified nonzero moment energy.
-- ===========================================================================

/-- `deep3`'s third squared moment is the positive rational `1/6350400 = (1/2520)²`. -/
theorem deep3_moment_three_sq_pos :
    Pos (Rmul (mellinMoment deep3 (3)) (mellinMoment deep3 (3))) := by
  have hval : Req (Rmul (mellinMoment deep3 3) (mellinMoment deep3 3))
      (ofQ (⟨1, 6350400⟩ : Q) (by decide)) := by
    refine Req_trans (Rmul_congr deep3_moment_three deep3_moment_three) ?_
    refine Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) ?_
    exact ofQ_congr (by decide) (by decide) (by decide)
  exact Pos_congr (Req_symm hval)
    (Pos_of_Rle_ofQ (c := (⟨1, 6350400⟩ : Q)) (by decide) (by decide) (Rle_refl _))

/-- **CERTIFIED NONZERO MOMENT ENERGY**: `Pos (momentL2Sq deep3)` — the `K = 3` member carries
    strictly positive `ℓ²` moment energy, as a genuinely nonzero, not-full-co-support test must. -/
theorem momentL2Sq_deep3_pos : Pos (momentL2Sq deep3) :=
  momentL2Sq_pos_of_moment deep3 3 deep3_moment_three_sq_pos

end Multiplicity.UOR.Bridge.F1Square.Square
