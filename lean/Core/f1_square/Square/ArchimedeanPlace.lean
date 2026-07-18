/-
F1 square — v0.21.0 stage G, brick **the archimedean place**: deepening the `arch(n)` term of the
prime–archimedean coupling — the term whose construction is conquered ground (the head and the
prime-free window) and whose sign outside the window is the open content (§12/§14).

`genuine_crux_arch_coupling` reduced the crux to the sign of `arith(n) + arch(n)`. The `arch(n)`
term is `ArchTrend.genuineArchSeq` (the archimedean Li trend), and the test-function archimedean
term is `Pairing.weilArchConst`. This brick records where that archimedean facet is POSITIVE — the
conquered ground — and where its sign stays open:

- **Conquered at the head** (`coupling_head_positive`): the coupling `arith(n)+arch(n) = λₙ` is
  certified strictly positive at `n = 1, 2` (`genuineLam_head`, from `Rlambda1_pos`/`Rlambda2_pos`).
- **Conquered in the prime-free window** (`coupling_window_archimedean`): inside the Connes–Consani
  window (`X = 1`) the prime side vanishes (`weilPrime_window`), so the Weil functional is purely
  archimedean (`W = poles − archimedean`, `weilValue_window`) — the coupling reduces to the
  archimedean place alone, where CC positivity is unconditional.
- **The window-center certificate** (`archimedean_center_positive`): Burnol's multiplier at the
  window center is positive, `α(0) = 8√2 − logπ + ψ(1/4) > 0` (`burnolAlphaZero_pos`), built on the
  exact `ψ(1/4)` (`psiQuarter_lower`) — the constructive footprint of the unconditional window.

Outside the window the prime side returns and the coupling's sign is the uniform tail bound,
governed by the zeros — the one open content. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `()`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.f1_square.Square.LefschetzCoupling
import Core.f1_square.Square.Pairing
import Core.f1_square.Analysis.BurnolAlpha

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- **THE COUPLING IS CONQUERED AT THE HEAD**: the prime–archimedean coupling `arith(n) + arch(n)`
    is strictly positive at `n = 1, 2` — the certified slices (`genuineLam_head`, from the certified
    `λ₁, λ₂ > 0`). The archimedean trend `genuineArchSeq` is the `arch` summand. -/
theorem coupling_head_positive (E : StieltjesEta) :
    Pos (Radd (genuineArithSeq E.eta 1) (genuineArchSeq 1))
    ∧ Pos (Radd (genuineArithSeq E.eta 2) (genuineArchSeq 2)) :=
  genuineLam_head E

/-- **IN THE PRIME-FREE WINDOW THE COUPLING IS PURELY ARCHIMEDEAN**: with support cutoff `X = 1`
    (the Connes–Consani window) the finite-place side vanishes, so the Weil functional is
    `W = poles − archimedean` — the coupling reduces to the archimedean place alone, the
    unconditional CC territory. -/
theorem coupling_window_archimedean (S : WeilSlot) (hX : S.test.X = 1) :
    Req (weilValue S) (Rsub S.poles (Radd (weilArchConst S.test) S.archTail)) :=
  weilValue_window S hX

/-- **THE WINDOW-CENTER POSITIVITY CERTIFICATE**: Burnol's archimedean multiplier at the center of
    the prime-free window is positive, `α(0) = 8√2 − logπ + ψ(1/4) > 0` — the constructive footprint
    of the unconditional window, built on the exact `ψ(1/4)`. -/
theorem archimedean_center_positive : Pos burnolAlphaZero :=
  burnolAlphaZero_pos

/-- **THE ARCHIMEDEAN PLACE — STATUS** (§12/§14): the coupling is
    conquered at the certified head (`n = 1, 2`) and, in the prime-free window, reduces to the
    archimedean place with a positive center certificate (`α(0) > 0`). Outside the window the prime
    side returns and the coupling's sign is the uniform tail bound governed by the zeros — the open
    content. The crux fields stay `none`. -/
theorem archimedean_place_status (E : StieltjesEta) :
    (Pos (Radd (genuineArithSeq E.eta 1) (genuineArchSeq 1))
      ∧ Pos (Radd (genuineArithSeq E.eta 2) (genuineArchSeq 2)))
    ∧ Pos burnolAlphaZero
    ∧ (∀ S : WeilSlot, S.test.X = 1 →
        Req (weilValue S) (Rsub S.poles (Radd (weilArchConst S.test) S.archTail))) :=
  ⟨coupling_head_positive E, burnolAlphaZero_pos, fun S hX => weilValue_window S hX⟩

end UOR.Bridge.F1Square.Square
