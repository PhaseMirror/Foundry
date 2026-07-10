/-
F1 square — **the Voros off-line branch: modulus growth, constructively** (track 2). The witness term
of an off-line zero has a squared modulus that STRICTLY GROWS with `n` — the constructive seed of
Voros's exponential regime. The step from this growth to a NEGATIVE Li coefficient is the classical
phase/saddle-point analysis, which is not formalized (and is honestly delimited here).

`offLine_left_not_inClosedDisk` (`Reflection.lean`) already proves a left-of-line zero leaves the
closed Cayley disk: its factor `w = 1−1/ρ` has `|w|² > 1`. THIS FILE pushes that one step further into
the dynamics: when `|w|² > 1`, the squared modulus of the witness term `wⁿ` is strictly increasing,
`|wⁿ⁺¹|² − |wⁿ|² = |wⁿ|²·(|w|²−1) > 0` (`offLine_term_grows`), via the Atlas composition norm power
law `cnormSq_npow`. So the off-line term's magnitude blows up monotonically.

WHAT THIS IS AND IS NOT. This is the term-level modulus growth (Voros's exponential seed), proven. It
is NOT the negativity of `λₙ`: that needs the PHASE of `wⁿ` (when `Re(wⁿ) > 1`) and the dominance of
the growing term over the SUM — Voros's saddle-point — which is the irreducible classical content
carried as the `LiBridge.dichotomy` interface (`BLPipeline.lean`). Crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.RHWitness
import F1Square.Analysis.Reflection
import F1Square.Li

namespace UOR.Bridge.F1Square.Analysis

open UOR.Bridge.F1Square.Li (Pos_one)

/-- Powers of a positive real are positive. -/
theorem Pos_Rnpow {x : Real} (hx : Pos x) : ∀ n, Pos (Rnpow x n)
  | 0 => Pos_one
  | (n + 1) => Pos_Rmul hx (Pos_Rnpow hx n)

/-- `x − 1 > 0 ⟹ x > 0` (a real exceeding `1` is positive). -/
theorem Pos_of_Pos_Rsub_one {x : Real} (h : Pos (Rsub x one)) : Pos x :=
  Pos_mono (Rle_of_Rnonneg_Rsub (Rnonneg_of_Pos h)) Pos_one

/-- `x·p − p ≈ p·(x − 1)` (factor a step of the power difference). -/
private theorem step_factor (x p : Real) :
    Req (Rsub (Rmul x p) p) (Rmul p (Rsub x one)) :=
  Req_trans (Rsub_congr (Rmul_comm x p) (Req_symm (Rmul_one p)))
    (Req_symm (Rmul_sub_distrib p x one))

/-- **OFF-LINE ⟹ THE WITNESS TERM'S SQUARED MODULUS STRICTLY GROWS**: if the Cayley factor `w` has
    `|w|² > 1` (its zero off the line, `offLine_left_not_inClosedDisk`), then `|wⁿ|²` is strictly
    increasing in `n` — `|wⁿ⁺¹|² − |wⁿ|² = |wⁿ|²·(|w|²−1) > 0`, via the composition-norm power law
    `cnormSq_npow`. The constructive modulus-growth seed of the Voros off-line branch; the step from
    growth to a negative coefficient (the phase/saddle-point) stays the classical interface. -/
theorem offLine_term_grows {w : Complex} (hw : Pos (Rsub (cnormSq w) one)) (n : Nat) :
    Pos (Rsub (cnormSq (Cnpow w (n + 1))) (cnormSq (Cnpow w n))) := by
  have key : Req (Rsub (cnormSq (Cnpow w (n + 1))) (cnormSq (Cnpow w n)))
      (Rmul (Rnpow (cnormSq w) n) (Rsub (cnormSq w) one)) :=
    Req_trans (Rsub_congr (cnormSq_npow w (n + 1)) (cnormSq_npow w n))
      (step_factor (cnormSq w) (Rnpow (cnormSq w) n))
  exact Pos_congr (Req_symm key)
    (Pos_Rmul (Pos_Rnpow (Pos_of_Pos_Rsub_one hw) n) hw)

/-- **ON-LINE/IN-DISK ⟹ THE WITNESS TERM IS TEMPERED**: if `|w|² ≤ 1` (the zero on or right of the
    line), the term `1 − Re(wⁿ)` is bounded above by `2` — because `Re(wⁿ)² ≤ |wⁿ|² ≤ 1` forces
    `Re(wⁿ) ≥ −1` (the no-`sqrt` squared comparison again), so `1 − Re(wⁿ) ≤ 1 + 1`. With
    `witnessTerm_nonneg` this pins the term to `[0, 2]` — Voros's TEMPERED regime, at the term level. -/
theorem witnessTerm_tempered {w : Complex} (h : Rle (cnormSq w) one) (n : Nat) :
    Rle (Rsub one (Cnpow w n).re) (Radd one one) := by
  have h1 : Rle (Rmul (Rneg (Cnpow w n).re) (Rneg (Cnpow w n).re)) (cnormSq (Cnpow w n)) := by
    show Rle (Rmul (Rneg (Cnpow w n).re) (Rneg (Cnpow w n).re))
      (Radd (Rmul (Cnpow w n).re (Cnpow w n).re) (Rmul (Cnpow w n).im (Cnpow w n).im))
    exact Rle_trans (Rle_of_Req (Rneg_sq (Cnpow w n).re))
      (Rle_self_Radd_right (Rnonneg_Rmul_self (Cnpow w n).im))
  have h2 : Rle (Rmul (Rneg (Cnpow w n).re) (Rneg (Cnpow w n).re)) (Rmul one one) :=
    Rle_trans h1 (Rle_trans (cnormSq_Cnpow_le_one h n) (Rle_of_Req (Req_symm (Rmul_one one))))
  have hre : Rle (Rneg (Cnpow w n).re) one := Rle_of_Rmul_self_le Rnonneg_one h2
  show Rle (Radd one (Rneg (Cnpow w n).re)) (Radd one one)
  exact Radd_le_add (Rle_refl one) hre

/-- **VOROS'S DICHOTOMY, AT THE TERM LEVEL** (extrapolated from the Atlas composition norm): for any
    Cayley factor `w`, EITHER `|w|² ≤ 1` (zero on/right of the line) and the witness term is TEMPERED,
    bounded in `[0, 2]` (`witnessTerm_nonneg` + `witnessTerm_tempered`); OR `|w|² > 1` (zero off the
    line) and the term's squared modulus GROWS strictly (`offLine_term_grows`) — the exponential seed.
    The tempered/exponential alternative of Voros, mechanized per term. The remaining step — that the
    exponential branch forces the SUM `λₙ < 0` (phase + saddle-point) — is the classical content
    (`LiBridge.dichotomy`), not formalized; crux fields stay `none`. -/
theorem voros_term_dichotomy {w : Complex} (n : Nat) :
    (Rle (cnormSq w) one →
        Rnonneg (Rsub one (Cnpow w n).re)
        ∧ Rle (Rsub one (Cnpow w n).re) (Radd one one))
    ∧ (Pos (Rsub (cnormSq w) one) →
        Pos (Rsub (cnormSq (Cnpow w (n + 1))) (cnormSq (Cnpow w n)))) :=
  ⟨fun h => ⟨witnessTerm_nonneg h n, witnessTerm_tempered h n⟩,
   fun hw => offLine_term_grows hw n⟩

end UOR.Bridge.F1Square.Analysis
