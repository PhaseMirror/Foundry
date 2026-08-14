/-
F1 square — v0.21.0 stage G, brick **Atlas → RH connection**: feeding the Atlas-discovery facets
back into the F1 RH research program.

As the Atlas exploration discovers structure, this brick connects it to the RH program already in
the repo. Three live connection points:

  (1) **Addressing → geometry → analysis.** The Atlas addressing tower's chain primes (§5) are the
      Frobenius orbit's shift lengths (`Cohomology.orbitShift`), which are the explicit-formula
      weights `Λ(p) = log p` (`Analysis.vonMangoldt`). One prime, three faces of the same datum:
      `orbitShift p 1 ≈ Λ(p)`.
  (2) **Spectral negative direction → the crux.** The Atlas's forced `−1` reflection (dim `14 = dim
      G₂`) makes the spectral form indefinite (`atlasM_indefinite`) — the indefinite/negative
      direction the Hodge-index crux concerns.
  (3) **The gate is live and honest.** The crux gate closes on a genuine witness
      (`strictRealizes_closes_crux`), so these connections feed a gate that would flip given the
      missing positive-definite structure — and stays `none` until it lands.

So the Atlas is not a parallel curiosity: its addressing IS the explicit-formula prime side, its
spectral signature IS the crux's negative direction, and the bridge between them is exactly where RH
sits. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.GateSanity
import Multiplicity.F1Square.Square.AtlasAddressing
import Multiplicity.F1Square.Square.Cohomology

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The Frobenius orbit's shift length at `k = 1` is `log p` (one Frobenius step = one period). -/
theorem orbitShift_one (p : Nat) (hp : 1 ≤ p) : Req (orbitShift p hp 1) (logN p hp) :=
  Radd_zero (logN p hp)

/-- **Addressing → geometry → analysis** (the cross-facet identity): the Atlas chain prime `5`
    appears in the addressing tower (`AtlasAddressing`), as a Frobenius orbit shift length
    (`orbitShift`), and as the explicit-formula weight `Λ(5) = log 5` (`vonMangoldt`) — and these
    three are the SAME constructive real: `orbitShift 5 1 ≈ Λ(5)`. -/
theorem atlas_shift_eq_weight : Req (orbitShift 5 (by omega) 1) (vonMangoldt 5) :=
  Req_trans (orbitShift_one 5 (by omega)) (Req_symm atlasPrime_five_vonMangoldt)

/-- **THE ATLAS FEEDS THE RH PROGRAM** at three connected points: (1) the addressing prime skeleton
    realizes the explicit-formula weight through the Frobenius orbit; (2) the forced `−1` reflection
    is the crux's indefinite Hodge direction (`atlasM_indefinite`); (3) the crux gate closes on a
    genuine witness (`strictRealizes_closes_crux`) — the connection is live, and honestly gated, so
    the crux fields stay `none` until the positive-definite witness lands. -/
theorem atlas_feeds_rh :
    Req (orbitShift 5 (by omega) 1) (vonMangoldt 5)
    ∧ ¬ WeilPSD atlasM
    ∧ (∀ (E : StieltjesEta) (ι : AtlasRule) (D : Nat),
        StrictRealizes E ι D → SpectralCrux (genuineSpectralSquare E)) :=
  ⟨atlas_shift_eq_weight, atlasM_indefinite, strictRealizes_closes_crux⟩

end Multiplicity.UOR.Bridge.F1Square.Square
