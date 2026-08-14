/-
F1 square — **the pre-Hilbert layer, brick 28** (`CoSupportWeld.lean`): **THE WELD** — the
transform-side co-support condition IS an orthogonality condition: for compact tests,

    `HatVanishes φ K  ⟺  φ ⊥ xⁿ for all n < K`   (`hatVanishes_iff_orthogonal`).

This is the `f, f̂` pair statement in its first genuine form. The pair is bundled
(`MellinPair`: a test with its all-order decay data, `MellinPair.hat` its transform), and the
co-support condition on the transform side is proven EQUIVALENT to vanishing of the L²
pairings against the monomial band directions `powTest n` — the function-space mirror of the
skeleton's `c(i) = 0` on the band (which was vanishing against the indicator directions,
`bandProj`). Orthogonality extends over the band's span (`orthogonal_band_add`, by the
pairing's bilinearity), so the condition is against the SUBSPACE the directions span, not
just the directions.

Realized instance: `cubePair` (the brick-27 cubic bump as a pair), with
`cubePair_orthogonal` — a genuine nonzero test orthogonal to the `K = 1` band whose
transform accordingly vanishes there.

HONEST SCOPE. The weld is for `[0,1]`-supported tests, and the band is the MONOMIAL band
`{xⁿ : n < K}` — not yet the skeleton's indicator band (the two bands' relation is the
remaining welding step toward `bandProj`), no continuous parameter, no inversion. Positivity
of the Weil form on the orthogonal complement is step 4 and is RH. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CubicMember

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The pair object.
-- ===========================================================================

/-- **The `f, f̂` pair**: a test bundled with the decay data under which every integer point
    of its transform exists. -/
structure MellinPair where
  φ : L2Test
  C : Q
  hCd : 0 < C.den
  hCn : 0 ≤ C.num
  hall : AllDecay φ C hCd

/-- The pair's transform at the integer point `n`. -/
def MellinPair.hat (P : MellinPair) (n : Nat) : Real :=
  mellinHat P.φ n P.hCd P.hCn (P.hall n)

/-- A `[0,1]`-supported test as a pair (decay constant `0`). -/
def MellinPair.ofSupp (φ : L2Test) (hsupp : UnitSupported φ) : MellinPair where
  φ := φ
  C := ⟨0, 1⟩
  hCd := by decide
  hCn := by show (0 : Int) ≤ 0; decide
  hall := allDecay_of_supp φ hsupp

/-- **A compact pair's transform is its L² pairing against the monomial directions**:
    `f̂(n) ≈ ⟨φ, xⁿ⟩` — the pair-level restatement of `mellinHat_compact`. -/
theorem mellinPair_hat_compact (φ : L2Test) (hsupp : UnitSupported φ) (n : Nat) :
    Req ((MellinPair.ofSupp φ hsupp).hat n) (innerI φ (powTest n)) :=
  mellinHat_compact φ n hsupp

-- ===========================================================================
-- The weld: co-support ⟺ orthogonality to the band.
-- ===========================================================================

/-- **THE WELD**: for a `[0,1]`-supported test, the transform-side co-support condition is
    EQUIVALENT to L²-orthogonality against the monomial band — `f̂` vanishes below `K` iff
    `⟨φ, xⁿ⟩ ≈ 0` for every `n < K`. The genuine `f, f̂` coupling in its first form: the
    function-space mirror of the skeleton's band condition. -/
theorem hatVanishes_iff_orthogonal (φ : L2Test) (K : Nat) (hsupp : UnitSupported φ) :
    HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp)
    ↔ ∀ n : Nat, n < K → Req (innerI φ (powTest n)) zero := by
  constructor
  · intro h n hn
    exact Req_trans (Req_symm (mellinHat_compact φ n hsupp)) (h n hn)
  · intro h
    exact hatVanishes_of_moments φ K hsupp h

/-- **Orthogonality extends over the band's span**: `φ ⊥ ψ₁` and `φ ⊥ ψ₂` give
    `φ ⊥ (ψ₁ + ψ₂)` — the pairing's bilinearity makes the condition a statement about the
    SUBSPACE the band directions span. -/
theorem orthogonal_band_add (φ ψ₁ ψ₂ : L2Test)
    (h₁ : Req (innerI φ ψ₁) zero) (h₂ : Req (innerI φ ψ₂) zero) :
    Req (innerI φ (L2Test.add ψ₁ ψ₂)) zero :=
  Req_trans (innerI_add_right φ ψ₁ ψ₂)
    (Req_trans (Radd_congr h₁ h₂) (Radd_zero zero))

-- ===========================================================================
-- The realized instance.
-- ===========================================================================

/-- The brick-27 cubic bump as a genuine `f, f̂` pair. -/
def cubePair : MellinPair := MellinPair.ofSupp cubeBump cubeBump_supp

/-- **The realized weld instance**: the cubic bump — a certified NONZERO test
    (`cubeBump_apart`) — is orthogonal to the `K = 1` monomial band, and its transform
    accordingly vanishes there (`cubeBump_hatVanishes`). -/
theorem cubePair_orthogonal : ∀ n : Nat, n < 1 → Req (innerI cubeBump (powTest n)) zero :=
  (hatVanishes_iff_orthogonal cubeBump 1 cubeBump_supp).mp cubeBump_hatVanishes

end Multiplicity.UOR.Bridge.F1Square.Square
