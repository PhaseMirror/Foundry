/-
F1 square — **the pre-Hilbert layer, brick 53** (`CoSupportPairing.lean`): **DEEP CO-SUPPORT IS
NEARLY ORTHOGONAL TO EVERYTHING** — brick 42's diagonal rate, generalized to the bilinear
pairing:

    `φ ∈ HatVanishes · K   ⟹   |⟪φ, ψ⟫|  ≤  2·M_φ·M_ψ/(K+1)`   for EVERY `ψ`
      (`crossMomL2_abs_le_of_hatVanishes`).

Brick 42 said a depth-`K` member carries little moment *energy* — `‖φ̂‖² ≤ 2M_φ²/(K+1)` — which
is the case `ψ = φ`. This says the same member is nearly orthogonal to the whole space, at the
same rate, with a bound linear in each test's own `M`. Taking `ψ` to range over the constructed
members, the deep levels of the filtration are not merely thin, they are nearly perpendicular to
everything the layer can pair them against.

The proof is the co-support condition eating the head of the series. Below `K` the `φ`-moments
vanish, so every cross partial sum is *literally* a window from the cut `K`
(`crossMomSum_zero_below`, `crossMomSum_eq_window`), and brick 49's window bound —
Cauchy–Schwarz against the two tails, whose product is the exact square of the rational
`2M_φM_ψ/(K+1)` — applies uniformly in the window length. The limit then inherits the bound from
both sides exactly as in brick 50.

HONEST SCOPE. A rate for the `ℓ²` moment pairing of bounded-Lipschitz tests on `[0,1]` in terms
of one side's co-support depth. Nothing here touches the Weil form, and it says nothing about
whether a nonzero test can have all moments vanish (determinacy, still untouched). Step 4 is RH.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MomentPairingLaws
import Multiplicity.F1Square.Square.CoSupportWeld

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- Below the co-support depth every cross term vanishes, so the head of the series is zero. -/
theorem crossMomSum_zero_below (φ ψ : L2Test) (K : Nat)
    (h : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) (N : Nat) (hN : N ≤ K) :
    Req (crossMomSum φ ψ N) zero :=
  RsumN_zero N (fun n hn =>
    Req_trans (Rmul_congr (h n (Nat.lt_of_lt_of_le hn hN)) (Req_refl _))
      (Req_trans (Rmul_comm zero (momSeq ψ n)) (Rmul_zero (momSeq ψ n))))

/-- Past the depth, a cross partial sum IS the window from the cut `K`. -/
theorem crossMomSum_eq_window (φ ψ : L2Test) (K : Nat)
    (h : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) (d : Nat) :
    Req (crossMomSum φ ψ (K + d)) (crossWindow φ ψ K d) :=
  Req_trans (crossMomSum_split φ ψ K d)
    (Req_trans (Radd_congr (crossMomSum_zero_below φ ψ K h K (Nat.le_refl K)) (Req_refl _))
      (Req_trans (Radd_comm zero (crossWindow φ ψ K d)) (Radd_zero _)))

/-- **Every cross partial sum obeys the depth-`K` window bound.** -/
theorem crossMomSum_abs_le_of_moments (φ ψ : L2Test) (K : Nat)
    (h : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) (N : Nat) :
    Rle (Rabs (crossMomSum φ ψ N)) (ofQ (crossBound φ ψ K) (crossBound_den φ ψ K)) := by
  rcases Nat.le_total N K with hNK | hKN
  · refine Rle_trans (Rle_of_Req (Rabs_congr (crossMomSum_zero_below φ ψ K h N hNK))) ?_
    refine Rle_trans (Rle_of_Req Rabs_zero) ?_
    exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (crossBound_den φ ψ K) (crossBound_num φ ψ K))
  · obtain ⟨d, hd⟩ := Nat.le.dest hKN
    rw [← hd]
    refine Rle_trans (Rle_of_Req (Rabs_congr (crossMomSum_eq_window φ ψ K h d))) ?_
    exact crossWindow_abs_le φ ψ K d

/-- **DEEP CO-SUPPORT IS NEARLY ORTHOGONAL TO EVERYTHING**: `|⟪φ, ψ⟫| ≤ 2·M_φ·M_ψ/(K+1)` for
    every `ψ`, whenever `φ`'s first `K` moments vanish. -/
theorem crossMomL2_abs_le_of_moments (φ ψ : L2Test) (K : Nat)
    (h : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) :
    Rle (Rabs (crossMomL2 φ ψ)) (ofQ (crossBound φ ψ K) (crossBound_den φ ψ K)) := by
  refine Rabs_le_of_both ?_ ?_
  · exact Rlim_le_ofQ (crossIdx_RReg φ ψ) (crossBound_den φ ψ K)
      (fun k => Rle_of_Rabs_le
        (crossMomSum_abs_le_of_moments φ ψ K h (crossScale φ ψ * (k + 1))))
  · have hlow : Rle (Rneg (ofQ (crossBound φ ψ K) (crossBound_den φ ψ K))) (crossMomL2 φ ψ) := by
      refine const_le_Rlim (crossIdx_RReg φ ψ) (fun k => ?_)
      refine Rle_trans (Rle_Rneg (Rle_of_Rabs_le
        (Rle_trans (Rle_of_Req (Rabs_Rneg _))
          (crossMomSum_abs_le_of_moments φ ψ K h (crossScale φ ψ * (k + 1)))))) ?_
      exact Rle_of_Req (Rneg_neg _)
    refine Rle_trans (Rle_Rneg hlow) ?_
    exact Rle_of_Req (Rneg_neg _)

/-- **THE SAME BOUND, READ OFF THE CO-SUPPORT CONDITION.** -/
theorem crossMomL2_abs_le_of_hatVanishes (φ ψ : L2Test) (K : Nat) (hsupp : UnitSupported φ)
    (hK : HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) :
    Rle (Rabs (crossMomL2 φ ψ)) (ofQ (crossBound φ ψ K) (crossBound_den φ ψ K)) :=
  crossMomL2_abs_le_of_moments φ ψ K ((hatVanishes_iff_orthogonal φ K hsupp).mp hK)

/-- The `K = 3` member is nearly orthogonal to every test, at rate `1/4`. -/
theorem deep3_crossMomL2_abs_le (ψ : L2Test) :
    Rle (Rabs (crossMomL2 deep3 ψ)) (ofQ (crossBound deep3 ψ 3) (crossBound_den deep3 ψ 3)) :=
  crossMomL2_abs_le_of_hatVanishes deep3 ψ 3 deep3_supp deep3_hatVanishes

end Multiplicity.UOR.Bridge.F1Square.Square
