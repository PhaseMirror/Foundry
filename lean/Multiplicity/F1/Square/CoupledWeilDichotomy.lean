/-
F1 square — **the coupled Weil dichotomy** (`CoupledWeilDichotomy.lean`): the coupled-kernel analog of
the built `burnol_sonine_dichotomy`, packaging the honest step-4 structure into one statement. For a
coupled kernel whose archimedean multiplier is indefinite (some `arch(k) < 0`, as the genuine Burnol
multiplier is, `α(2) < 0`):

  • it is NOT `WeilPSD` over the whole test space (`coupledWeil_not_psd_of_neg_arch` — the indicator
    `δ_k` breaks dominance), AND
  • it IS `≥ 0` on the Sonine co-support subspace (`coupledWeil_psd_on_sonine_restriction` — where the
    transform-side co-support `PrimeNull` kills the prime and the archimedean complement holds).

This is exactly the doc's step-4 dichotomy at the coupled level: the coupled form is indefinite over all
tests but positive on a strict subspace; carrying that positivity from the co-support subspace to the
WHOLE space is the genuine `f, f̂` transform coupling = step 4 = RH.

HONEST SCOPE. A packaging of two already-honest results; it asserts NO whole-space positivity — the
positive half is on a strict subspace, the negative half is unconditional. Mirrors `burnol_sonine_
dichotomy` (which is the same shape for the diagonal skeleton `multForm`). Crux stays `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.CoupledWeilIndefinite
import Multiplicity.F1.Square.CoupledWeilSonine

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **★ THE COUPLED WEIL DICHOTOMY**: with an indefinite archimedean multiplier (some `arch(k) < 0`),
    the coupled kernel is NOT `WeilPSD` over the whole space, yet IS `≥ 0` on the Sonine co-support
    subspace (`PrimeNull` ∩ archimedean complement). The honest step-4 structure; extending the co-support
    positivity to all tests is RH. -/
theorem coupledWeil_sonine_dichotomy (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (k N₀ : Nat) (hkN₀ : k < N₀) (hw : ∀ m, Rnonneg (w m)) (harch : ¬ Rnonneg (arch k)) :
    (¬ WeilPSD (coupledWeil arch w v M))
    ∧ (∀ (c : Nat → Real) (N : Nat), PrimeNull v M c N →
        (∀ i, i < N → Rnonneg (arch i) ∨ Req (c i) zero) →
        Rnonneg (weilQuad (coupledWeil arch w v M) c N)) :=
  ⟨coupledWeil_not_psd_of_neg_arch arch w v M k N₀ hkN₀ hw harch,
   fun c N hnull hc => coupledWeil_psd_on_sonine_restriction arch w v M c N hnull hc⟩


/-- `¬ Rnonneg burnolAlphaTwo` — the proven `α(2) < 0` (`burnolAlphaTwo_neg`) as a non-nonnegativity. -/
theorem not_Rnonneg_burnolAlphaTwo : ¬ Rnonneg burnolAlphaTwo := fun h =>
  not_Pos_of_Rnonneg_neg (Rnonneg_congr (Req_symm (Rneg_Rneg burnolAlphaTwo)) h) burnolAlphaTwo_neg

/-- **The genuine-data instance**: the coupled kernel on the ACTUAL Burnol multiplier `burnolMult`
    (whose index-1 sample is `α(2) < 0`) is NOT `WeilPSD` — the indefinite-arch obstruction at real
    archimedean data (`burnolMult 1 = burnolAlphaTwo`). -/
theorem coupledWeilBurnol_not_psd (w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (N₀ : Nat) (h1N₀ : 1 < N₀) (hw : ∀ m, Rnonneg (w m)) :
    ¬ WeilPSD (coupledWeil burnolMult w v M) :=
  coupledWeil_not_psd_of_neg_arch burnolMult w v M 1 N₀ h1N₀ hw not_Rnonneg_burnolAlphaTwo

/-- **The genuine-data dichotomy**: the coupled kernel on the actual Burnol multiplier is NOT `WeilPSD`
    over all tests, yet IS `≥ 0` on the Sonine co-support subspace — the honest step-4 dichotomy at real
    archimedean data. -/
theorem coupledWeilBurnol_sonine_dichotomy (w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (N₀ : Nat) (h1N₀ : 1 < N₀) (hw : ∀ m, Rnonneg (w m)) :
    (¬ WeilPSD (coupledWeil burnolMult w v M))
    ∧ (∀ (c : Nat → Real) (N : Nat), PrimeNull v M c N →
        (∀ i, i < N → Rnonneg (burnolMult i) ∨ Req (c i) zero) →
        Rnonneg (weilQuad (coupledWeil burnolMult w v M) c N)) :=
  coupledWeil_sonine_dichotomy burnolMult w v M 1 N₀ h1N₀ hw not_Rnonneg_burnolAlphaTwo

end Multiplicity.UOR.Bridge.F1Square.Square
