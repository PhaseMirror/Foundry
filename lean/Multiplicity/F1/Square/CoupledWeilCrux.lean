/-
F1 square — **the coupled Weil kernel meets the crux faces** (`CoupledWeilCrux.lean`): wiring the
off-diagonal coupled kernel of `CoupledWeilKernel.lean` into the four built pairing/spectral faces
(`weilSpectralSquare`, `weil_psd_iff_hodge`, `spectral_bridge_nonneg`, `weil_strict_iff_crux`). The
capstone `coupledWeil_psd_iff_dominates` located the crux in one dominance inequality
`ArchDominatesPrime`; this file connects that inequality to the crux itself.

THE CHAIN (all genuine, kernel-checked, one-directional or as explicit equivalences — never asserting
the positivity):
  • `coupledWeil_diag_eq` — the coupled kernel's diagonal is the scalar Weil shape `arch n −
    primeGram(n,n)` (the pairing family `W n = coupledWeil(n,n)` feeding `weilSpectralSquare`).
  • `coupledWeil_psd_imp_hodgeNeg` — `WeilPSD (coupledWeil …)` forces Hodge-index negativity of the
    induced spectral square (through the diagonal, `WeilPSD_diag` + `weil_psd_iff_hodge`; Gate B free).
  • `coupledWeil_psd_imp_liNonneg` — hence Li non-negativity, through `spectral_bridge_nonneg`.
  • `archDominatesPrime_imp_liNonneg` — the **composed sufficiency**: the dominance inequality
    `ArchDominatesPrime` ⟹ `LiNonneg` of the induced square. So proving the archimedean form dominates
    the prime Gram yields (non-strict) Li-positivity — the sufficient half of the crux.
  • `coupledWeil_diag_strict_iff_crux` — **the exact face**: STRICT diagonal dominance of the coupled
    kernel (`arch n > primeGram(n,n) ∀n>0`) ⟺ `SpectralCrux` of the induced square (`weil_strict_iff_crux`).

HONEST SCOPE. Every statement is an implication (with the positivity/dominance as an explicit
hypothesis) or an equivalence to the still-open crux — NOTHING asserts `WeilPSD (coupledWeil …)`,
`ArchDominatesPrime`, or the strict dominance holds. `WeilPSD` gives only the non-strict `Rnonneg`
diagonal, so it reaches `LiNonneg` (as `embeds_to_liNonneg` does), NOT the strict crux; the strict
crux needs strict dominance, delivered here only as the ⟺ face, never discharged. This makes precise
that assembling the coupled kernel AND proving its dominance closes the crux — and that the dominance
IS RH (Weil 1952; Bombieri–Lagarias 1999). Crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.CoupledWeilKernel
import Multiplicity.F1Square.Square.Pairing

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- The **induced pairing family** of the coupled kernel: `W n = coupledWeil arch w v M (n,n)` — the
    diagonal, feeding `weilSpectralSquare`. -/
def coupledPairing (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat) : Nat → Real :=
  fun n => coupledWeil arch w v M n n

/-- **The diagonal is the scalar Weil shape**: `coupledWeil arch w v M (n,n) = arch n − primeGram(n,n)`
    — the archimedean value minus the prime Gram's diagonal (`multForm`'s diagonal is `arch`). -/
theorem coupledWeil_diag_eq (arch w : Nat → Real) (v : Nat → Nat → Real) (M n : Nat) :
    coupledWeil arch w v M n n = Rsub (arch n) (primeGram w v M n n) := by
  show Rsub (multForm arch n n) (primeGram w v M n n) = Rsub (arch n) (primeGram w v M n n)
  rw [multForm_diag]

/-- **`WeilPSD` ⟹ Hodge-index negativity** of the induced spectral square: a PSD coupled kernel has
    a nonnegative diagonal (`WeilPSD_diag`, Gate B free), which is exactly `Rnonneg (W n)`. -/
theorem coupledWeil_psd_imp_hodgeNeg (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (h : WeilPSD (coupledWeil arch w v M)) :
    SpectralHodgeNeg (weilSpectralSquare (coupledPairing arch w v M)) :=
  (weil_psd_iff_hodge (coupledPairing arch w v M)).mp (fun n _ => WeilPSD_diag h n)

/-- **`WeilPSD` ⟹ Li non-negativity** of the induced trace data, through the semidefinite bridge
    (`spectral_bridge_nonneg`). PSD gives only the non-strict `Rnonneg` — this reaches `LiNonneg`, not
    the strict crux. -/
theorem coupledWeil_psd_imp_liNonneg (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (h : WeilPSD (coupledWeil arch w v M)) :
    LiNonneg (weilSpectralSquare (coupledPairing arch w v M)).lam :=
  (spectral_bridge_nonneg _).mp (coupledWeil_psd_imp_hodgeNeg arch w v M h)

/-- **★ THE SUFFICIENCY**: the dominance inequality `ArchDominatesPrime` ⟹ `LiNonneg` of the induced
    square — proving the archimedean form dominates the prime Gram on every test yields (non-strict)
    Li-positivity. Composed from `coupledWeil_psd_iff_dominates` and the diagonal read. NOTHING asserts
    the dominance holds (that is RH). -/
theorem archDominatesPrime_imp_liNonneg (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (h : ArchDominatesPrime arch w v M) :
    LiNonneg (weilSpectralSquare (coupledPairing arch w v M)).lam :=
  coupledWeil_psd_imp_liNonneg arch w v M ((coupledWeil_psd_iff_dominates arch w v M).mpr h)

/-- **★ THE EXACT CRUX FACE**: STRICT diagonal dominance of the coupled kernel — `arch n >
    primeGram(n,n)` for all `n > 0`, i.e. `Pos (coupledWeil arch w v M (n,n))` — is EQUIVALENT to
    `SpectralCrux` of the induced square (`weil_strict_iff_crux`). For the genuine data this strict
    dominance is Weil positivity = RH; it is NEVER asserted. -/
theorem coupledWeil_diag_strict_iff_crux (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat) :
    (∀ n, 0 < n → Pos (coupledWeil arch w v M n n))
      ↔ SpectralCrux (weilSpectralSquare (coupledPairing arch w v M)) :=
  weil_strict_iff_crux (coupledPairing arch w v M)

end Multiplicity.UOR.Bridge.F1Square.Square
