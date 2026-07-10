/-
F1 square — v0.21.0 stage G, brick **Atlas–crux synthesis**: the discovery program's insights
connected to the RH crux, localizing exactly what closing the crux *in the UOR Atlas* requires.

This gathers the Atlas→RH connections into one statement. The point: of all the Atlas's structure,
almost everything is FORCED or CONQUERED — the one genuinely open thing is the sign of the
prime–archimedean coupling for `n ≥ 3`, governed by the archimedean place (conquered in the
prime-free window, open beyond it).

`atlas_crux_localization` bundles, for the genuine square:
- **the Atlas forces the prime side** — its addressing prime `5` is the Frobenius orbit shift and the
  explicit-formula weight `Λ(5) = log 5` (`atlas_shift_eq_weight`);
- **the crux IS the coupling sign** — `crux ⟺ ∀n>0, arith(n)+arch(n) > 0`
  (`genuine_crux_arch_coupling`), the Lefschetz/`ff_hodge_iff_hasse` shape;
- **conquered at the head and the window** — the coupling is `> 0` at `n=1` (`coupling_head_positive`)
  and the archimedean window-center certificate `α(0) > 0` holds (`archimedean_center_positive`);
- **no shortcut** — the atlas spectral form is indefinite (`atlasM_indefinite`), and the crux closes
  ONLY on a genuine witness (`strictRealizes_closes_crux`), the gate poised but honest.

So closing the crux in the Atlas is localized to ONE proposition: the coupling sign for `n ≥ 3`,
governed by the zeros via the archimedean place. The crux fields stay `none` until that lands —
whether from established or novel mathematics, the gate (not ambition) decides.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.ArchimedeanPlace
import F1Square.Square.AtlasRHConnection

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **THE ATLAS–CRUX LOCALIZATION.** Everything the Atlas contributes to the crux, in one place: the
    prime side is forced (addressing ↔ orbit ↔ `Λ`), the crux is the prime–archimedean coupling
    sign, that sign is conquered at the head and at the window center, there is no shortcut (the
    spectral form is indefinite), and the gate closes only on a genuine witness. Closing the crux in
    the Atlas reduces to the coupling sign for `n ≥ 3` — the archimedean place's domination of the
    prime fluctuation, governed by the zeros. The crux fields stay `none`. -/
theorem atlas_crux_localization (E : StieltjesEta) :
    Req (orbitShift 5 (by omega) 1) (vonMangoldt 5)
    ∧ (SpectralCrux (genuineSpectralSquare E) ↔
        ∀ n, 0 < n → Pos (Radd (genuineArithSeq E.eta n) (genuineArchSeq n)))
    ∧ Pos (Radd (genuineArithSeq E.eta 1) (genuineArchSeq 1))
    ∧ Pos burnolAlphaZero
    ∧ ¬ WeilPSD atlasM
    ∧ (∀ (E' : StieltjesEta) (ι : AtlasRule) (D : Nat),
        StrictRealizes E' ι D → SpectralCrux (genuineSpectralSquare E')) :=
  ⟨atlas_shift_eq_weight,
   genuine_crux_arch_coupling E,
   (coupling_head_positive E).1,
   archimedean_center_positive,
   atlasM_indefinite,
   strictRealizes_closes_crux⟩

end UOR.Bridge.F1Square.Square
