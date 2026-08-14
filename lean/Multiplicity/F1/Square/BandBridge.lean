/-
F1 square — **the pre-Hilbert layer, brick 29** (`BandBridge.lean`): **THE BAND BRIDGE** —
the moment map carries the transform-side co-support condition into the discrete skeleton's
band condition, and the skeleton's UNCONDITIONAL complement-positivity fires on genuine
transform data.

The carrier is the moment map `momSeq φ = (mellinMoment φ n)ₙ` — a discrete-side coefficient
family built from a constructed test. Along it the two bands are RELATED:

- `momSeq_fourier` — the indicator-Fourier coefficient of the moment sequence IS the monomial
  pairing: `⟨momSeq φ, δₖ⟩_N ≈ ⟨φ, xᵏ⟩`. The indicator directions on the skeleton side
  correspond to the monomial directions on the test side, coefficient by coefficient.
- `momSeq_band_vanishes` — for a `[0,1]`-supported test, `HatVanishes φ K` pushes forward to
  the skeleton's condition: the first `K` coordinates of `momSeq φ` vanish (brick 28's weld).
- `momSeq_bandProj_fixed` — a `K = 2` co-support test's moment sequence is FIXED by the
  skeleton's band projection: it already lives in the Sonine complement (the negative-band
  index `1` is inside `{0, 1}`).
- **`weil_psd_on_cosupport`** — the capstone: for a `[0,1]`-supported test with
  `HatVanishes φ 2`, the discrete Weil multiplier form is nonnegative ON ITS MOMENT SEQUENCE
  at every truncation — `burnol_pairing_psd_on_sonine` with the band hypothesis discharged by
  the constructed transform's vanishing. The skeleton's unconditional positivity, realized for
  the first time on `f, f̂` data rather than an abstract coefficient family.

HONEST SCOPE. The bridge runs through the moment map at the discrete Burnol skeleton's
single-index band; the positivity delivered is the skeleton's DIAGONAL multiplier form on
moment data — not the Weil functional on the test space, and not positivity beyond the
complement (that is step 4 and is RH). The `K = 2` instance is currently inhabited by the
zero test only (`hatVanishes_zeroL2`); a NONZERO `K = 2` member needs the quartic engine
(banked). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CoSupportWeld
import Multiplicity.F1Square.Square.Parseval
import Multiplicity.F1Square.Square.SonineProjection

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The moment map**: a test's integer-moment sequence, as a discrete-side coefficient
    family — the object that carries `f, f̂` data into the skeleton. -/
def momSeq (φ : L2Test) : Nat → Real := fun n => mellinMoment φ n

/-- **The two bands correspond along the moment map**: the indicator-Fourier coefficient of
    the moment sequence is the monomial pairing — `⟨momSeq φ, δₖ⟩_N ≈ ⟨φ, xᵏ⟩`. -/
theorem momSeq_fourier (φ : L2Test) {k N : Nat} (hk : k < N) :
    Req (fourierC (momSeq φ) indic N k) (innerI φ (powTest k)) :=
  fourierC_indic (momSeq φ) hk

/-- **The co-support condition pushes forward to the skeleton's band condition**: for a
    `[0,1]`-supported test, `HatVanishes φ K` gives vanishing of the first `K` coordinates of
    the moment sequence. -/
theorem momSeq_band_vanishes (φ : L2Test) (hsupp : UnitSupported φ) (K : Nat)
    (h : HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) :
    ∀ i, i < K → Req (momSeq φ i) zero :=
  fun i hi => Req_trans (Req_symm (mellinHat_compact φ i hsupp)) (h i hi)

/-- **A `K = 2` co-support test's moment sequence is fixed by the band projection**: it
    already lives in the Sonine complement — the skeleton's `bandProj` acts as the identity
    on it. -/
theorem momSeq_bandProj_fixed (φ : L2Test) (hsupp : UnitSupported φ)
    (h : HatVanishes φ 2 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) :
    ∀ i, Req (bandProj (momSeq φ) i) (momSeq φ i) := by
  intro i
  by_cases h1 : i = 1
  · subst h1
    show Req zero (momSeq φ 1)
    exact Req_symm (momSeq_band_vanishes φ hsupp 2 h 1 (by decide))
  · show Req (if i = 1 then zero else momSeq φ i) (momSeq φ i)
    rw [if_neg h1]
    exact Req_refl _

/-- **THE SKELETON'S UNCONDITIONAL POSITIVITY, REALIZED ON `f, f̂` DATA**: for a
    `[0,1]`-supported test whose constructed transform vanishes at the integer points `0, 1`,
    the discrete Weil multiplier form is nonnegative on its moment sequence at every
    truncation — the band hypothesis of `burnol_pairing_psd_on_sonine` is discharged by the
    transform's vanishing, not assumed of an abstract coefficient family. No RH. -/
theorem weil_psd_on_cosupport (φ : L2Test) (hsupp : UnitSupported φ)
    (h : HatVanishes φ 2 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)) (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (momSeq φ) N) :=
  burnol_pairing_psd_on_sonine (momSeq φ) N
    (momSeq_band_vanishes φ hsupp 2 h 1 (by decide))

/-- The instance at the zero member (`hatVanishes_zeroL2` at `K = 2`) — the bridge is
    inhabited; a NONZERO `K = 2` member is the banked quartic construction. -/
theorem weil_psd_cosupport_instance (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (momSeq zeroL2) N) :=
  weil_psd_on_cosupport zeroL2 zeroL2_supp (hatVanishes_zeroL2 2) N

end Multiplicity.UOR.Bridge.F1Square.Square
