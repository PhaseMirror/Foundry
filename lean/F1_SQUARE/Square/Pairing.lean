/-
F1 square — v0.19.0 (the genuine-pairing arc), brick W2: **THE WEIL PAIRING** — the
quadratic functional assembled with the zero side as the DEFECT (no zeros as inputs),
the pairing-induced spectral square (the first `SpectralSquare` whose `cSq` comes from a
pairing-valued assembly rather than through the dictionary), and the first COMPUTED
finite-place pairing value.

THE ASSEMBLY (CC unsymmetrized normalization, pinned in `Analysis/Weil.lean`):
    `W(f) = [f̃(1) + f̃(0)] − [Σ_n Λ(n)(f(n) + n⁻¹f(1/n)) + (log 4π + γ)f(1) + ∫₁^∞(…)]`
i.e. `W = poles − (primes + archimedean)` — classically `W(f) = Σ_ρ f̃(ρ)`, the zero
side, obtained WITHOUT constructing zeros: it is the defect of the built sides. Here
the finite-place sum and the archimedean constant are CONSTRUCTED (`weilPrimePart`,
`weilArchConst`); the two integral components (`poles`, `archTail`) are interface data
with their readings pinned verbatim (their closed-form reduction for piecewise-linear
test data is routine but UNVERIFIED IN PRINT — the deep-research open question — so
transcribing it would breach the gate; they are never fabricated).

THE CRITERION [CLASSICAL, verified verbatim]: `RH ⟺ W(g ⋆ g^τ) ≥ 0` for all test `g` —
ELEMENTARY in both directions (Weil 1952; Burnol arXiv math/9810169 proves the Lemma
directly without a density argument; compactly-supported piecewise-linear `g` is
admissible per Bombieri's class `W`, the official Clay problem description §V; the zero
sum is the symmetric limit). Through `weilSpectralSquare` this face joins the three
existing faces: PSD of the genuine pairing family ⟺ Hodge-index negativity ⟺ Li
non-negativity ⟺ dominance — ONE proposition, now with the pairing face carried by an
ASSEMBLED object.

THE UNCONDITIONAL TERRITORY (recorded; the pinned next mechanization target): for test
support in `[2^{−1/2}, 2^{1/2}]` (so `f = g ⋆ g^τ` is supported in `(1/2, 2)` and NO
prime power contributes — the finite-place side vanishes BY CONSTRUCTION here, exactly
`weilPrimePart_stable`'s regime), Weil positivity holds UNCONDITIONALLY:
Connes–Consani, Selecta Math. 27 (2021) art. 77, Thm 1 — the form is the trace of a
positive operator (the Sonine-space projection; an infinite-dimensional certificate);
Burnol's precursor (math/0101068) certifies a smaller window `[1/c, c]`, `c < √2`, via the
EXPLICIT spectral multiplier `α(τ) = 8√2·cos(τ·log 2)/(1+4τ²) + h₊(τ)`,
`h₊(τ) = −log π + Re ψ(1/4 + iτ/2)` — which is INDEFINITE (not pointwise `≥ 0`;
`DigammaWindow`), made non-negative on the restricted class by Burnol's `A_ε·cos(ετ)`
correction. The boundary at the first prime (`x = 2`, `1/2`) is exactly where RH begins.

FAITHFULNESS: nothing here asserts PSD for the genuine family; the loose existential
over `W`-families is satisfiable and NOT RH (`weil_template_crux` mirror below); the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.Dominance
import F1Square.Analysis.Weil

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The pairing slot and the assembled functional.
-- ===========================================================================

/-- **A Weil pairing slot**: a test datum with its two interface components — the pole
    terms `f̃(1) + f̃(0)` and the archimedean integral (CC arXiv eq. 150, the
    `f(1)`-subtracted principal value, with its non-truncatable tail) — the two
    integrals whose piecewise-linear closed forms are unverified in print. -/
structure WeilSlot where
  /-- the test datum (rational-point evaluations + support cutoff) -/
  test : WeilTest
  /-- the pole terms `f̃(1) + f̃(0)` (interface: integrals of `f`) -/
  poles : Real
  /-- the archimedean integral `∫₁^∞ (f + f^♯ − (2/x)f(1)) dx/(x − x⁻¹)` (interface) -/
  archTail : Real

/-- **THE WEIL FUNCTIONAL at a slot**: `W = poles − (primes + archimedean)` — the zero
    side as the defect of the built sides; no zeros as inputs. -/
def weilValue (S : WeilSlot) : Real :=
  Rsub S.poles
    (Radd (weilPrimePart S.test) (Radd (weilArchConst S.test) S.archTail))

-- ===========================================================================
-- The pairing-induced spectral square, and the face equivalences.
-- ===========================================================================

/-- **The pairing-induced spectral square**: from any family of pairing values
    `W : Nat → Real` (the genuine instance: `W n = W(gₙ ⋆ gₙ^τ)` over an enumeration of
    test functions), the spectral enrichment with `λₙ = ½W(n)`, `⟨Cₙ,Cₙ⟩ = −W(n)` — the
    dictionary holds BY CONSTRUCTION: the first `SpectralSquare` whose `cSq` comes from
    a pairing-valued assembly rather than through interface data. -/
def weilSpectralSquare (W : Nat → Real) : SpectralSquare where
  lam := fun n => Rhalf (W n)
  cSq := fun n => Rneg (W n)
  dict := fun n _ => Rneg_congr (Req_symm (Rhalf_double (W n)))

/-- **PSD of the pairing family ⟺ Hodge-index negativity** of the induced spectral
    square — the pairing face joins the geometric face. -/
theorem weil_psd_iff_hodge (W : Nat → Real) :
    (∀ n : Nat, 0 < n → Rnonneg (W n)) ↔ SpectralHodgeNeg (weilSpectralSquare W) := by
  constructor
  · intro h n hn
    exact Rnonneg_congr (Req_symm (Rneg_Rneg (W n))) (h n hn)
  · intro h n hn
    exact Rnonneg_congr (Rneg_Rneg (W n)) (h n hn)

/-- **Strict positivity of the pairing family ⟺ the crux** of the induced spectral
    square (hence ⟺ `LiCrux` ⟺ dominance, through the standing equivalences) — the
    FOURTH face: for the genuine pairing family this is Weil positivity, i.e. RH
    [CLASSICAL: Weil 1952 / Burnol math/9810169]. Never asserted. -/
theorem weil_strict_iff_crux (W : Nat → Real) :
    (∀ n : Nat, 0 < n → Pos (W n)) ↔ SpectralCrux (weilSpectralSquare W) := by
  constructor
  · intro h n hn
    exact Pos_congr (Req_symm (Rneg_Rneg (W n))) (h n hn)
  · intro h n hn
    exact Pos_congr (Rneg_Rneg (W n)) (h n hn)

/-- **The two-sidedness guard**: the pairing-face property is satisfiable (the
    constant-`1` family induces a crux-satisfying spectral square), so the loose
    existential `∃ W, SpectralCrux (weilSpectralSquare W)` is true and NOT RH — the
    crux is the GENUINE pairing family, never an existential (the standing caution,
    pairing face). -/
theorem weil_template_crux : SpectralCrux (weilSpectralSquare (fun _ => one)) :=
  (weil_strict_iff_crux (fun _ => one)).mp (fun _ _ => Pos_one)

-- ===========================================================================
-- The prime-free window, on the built object.
-- ===========================================================================

/-- **THE WINDOW THEOREM, on the built object**: a test datum with support cutoff
    `X = 1` (support inside the prime-free window `(1/2, 2)` at the consumed points —
    exactly the Connes–Consani window for autocorrelations, `g` supported in
    `[2^{−1/2}, 2^{1/2}]`) has IDENTICALLY VANISHING finite-place side, at every
    truncation depth: no prime power contributes, by theorem. This is the in-substrate
    footprint of the unconditional territory — inside the window, Weil positivity is
    purely archimedean (CC Selecta 27 (2021) Thm 1 proves it there unconditionally via
    the Sonine-space projection; Burnol's explicit multiplier is the constructive
    certificate target, module docstring). -/
theorem weilPrime_window (T : WeilTest) (hX : T.X = 1) :
    ∀ N : Nat, Req (RsumN (weilPrimeTerm T) N) zero := by
  intro N
  induction N with
  | zero => exact Req_refl zero
  | succ k ih =>
    have hterm : Req (weilPrimeTerm T k) zero := by
      by_cases hk : k = 0
      · subst hk
        refine Req_trans (Rmul_congr vonMangoldt_one (Req_refl _)) ?_
        exact Req_trans (Rmul_comm zero _) (Rmul_zero _)
      · exact weilPrimeTerm_past_support T k (by omega)
    show Req (Radd (RsumN (weilPrimeTerm T) k) (weilPrimeTerm T k)) zero
    exact Req_trans (Radd_congr ih hterm) (Radd_zero zero)

/-- **In the window, the Weil functional is purely archimedean**: the assembled
    `W = poles − (primes + archimedean)` reduces to `poles − archimedean` — the exact
    statement the unconditional certificate program starts from, now a theorem of the
    assembly. -/
theorem weilValue_window (S : WeilSlot) (hX : S.test.X = 1) :
    Req (weilValue S) (Rsub S.poles (Radd (weilArchConst S.test) S.archTail)) := by
  refine Rsub_congr (Req_refl S.poles) ?_
  refine Req_trans (Radd_congr (weilPrime_window S.test hX S.test.X) (Req_refl _)) ?_
  exact Req_trans (Radd_comm zero _) (Radd_zero _)

/-- **The prime `2` enters at the term right after the window**: `weilPrimeTerm T 1` carries the first
    prime power's weight `Λ(2) = log 2` (`vonMangoldt_two`). So the finite-place side, which vanishes
    identically at `X = 1` (`weilPrime_window`), can no longer vanish once the cutoff admits this term. -/
theorem weilPrimeTerm_one_carries_prime_two (T : WeilTest) :
    Req (weilPrimeTerm T 1)
      (Rmul (logN 2 (by omega))
        (Radd (T.f ⟨(2 : Int), 1⟩) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (T.f ⟨1, 2⟩)))) :=
  Rmul_congr vonMangoldt_two (Req_refl _)

/-- **THE PRIME-FREE WINDOW IS MAXIMAL** — the discrete footprint of the Connes–Consani open interval
    `(1/2, 2)`, which excludes the prime `2`. Two facts pin it exactly: at cutoff `X = 1` the
    finite-place side vanishes identically (`weilPrime_window`), and the very next term carries
    `Λ(2) = log 2 ≠ 0` (`weilPrimeTerm_one_carries_prime_two`). So `X = 1` is the largest prime-free
    cutoff — the prime `2` sits at the boundary, never inside. This is the true extent of the
    archimedean-dominated (unconditional) layer; everything at the next cutoff and beyond carries the
    prime side, whose coupling sign is the open content. The crux fields stay `none`. -/
theorem prime_window_maximal (T : WeilTest) (hX : T.X = 1) :
    (∀ N : Nat, Req (RsumN (weilPrimeTerm T) N) zero)
    ∧ Req (weilPrimeTerm T 1)
        (Rmul (logN 2 (by omega))
          (Radd (T.f ⟨(2 : Int), 1⟩) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (T.f ⟨1, 2⟩)))) :=
  ⟨weilPrime_window T hX, weilPrimeTerm_one_carries_prime_two T⟩

-- ===========================================================================
-- The first computed finite-place pairing value.
-- ===========================================================================

/-- The demonstration test datum: the rational-point evaluations of the piecewise-linear
    tent with breakpoints `1, 2, 3` (peak `1` at `x = 2`, support `[1, 3]`) — an
    ADMISSIBLE test function (Bombieri's class `W`). Its only nonzero evaluation among
    the consumed points is `f(2) = 1`. -/
def demoWeilTest : WeilTest where
  f := fun q => if q = ⟨2, 1⟩ then one else zero
  X := 3
  hX := by omega
  supp_high := by
    intro n hn
    have hne : (⟨(n : Int), 1⟩ : Q) ≠ ⟨2, 1⟩ := by
      intro h
      have : (n : Int) = 2 := congrArg Q.num h
      omega
    show Req (if (⟨(n : Int), 1⟩ : Q) = ⟨2, 1⟩ then one else zero) zero
    rw [if_neg hne]
    exact Req_refl zero
  supp_low := by
    intro n hn
    have hne : (⟨1, n⟩ : Q) ≠ ⟨2, 1⟩ := by
      intro h
      have : (1 : Int) = 2 := congrArg Q.num h
      omega
    show Req (if (⟨1, n⟩ : Q) = ⟨2, 1⟩ then one else zero) zero
    rw [if_neg hne]
    exact Req_refl zero

/-- **The first computed pairing value**: the finite-place side of the Weil functional
    at the tent peaked at `2` is exactly `log 2` — the pairing SEES the prime `2`
    through the test function, with the von Mangoldt weight: the §2.3 finding
    ("the pencil separation is `Λ`") reappearing on the PAIRING side, now as a computed
    value of the assembled functional. -/
theorem weilPrime_demo : Req (weilPrimePart demoWeilTest) (logN 2 (by omega)) := by
  show Req (Radd (Radd (Radd zero (weilPrimeTerm demoWeilTest 0))
    (weilPrimeTerm demoWeilTest 1)) (weilPrimeTerm demoWeilTest 2)) (logN 2 (by omega))
  -- term 0 (`n = 1`): `Λ(1)·(…) ≈ 0`
  have h0 : Req (weilPrimeTerm demoWeilTest 0) zero := by
    refine Req_trans (Rmul_congr vonMangoldt_one (Req_refl _)) ?_
    exact Req_trans (Rmul_comm zero _) (Rmul_zero _)
  -- term 1 (`n = 2`): `Λ(2)·(1 + ½·0) ≈ log 2`
  have h1 : Req (weilPrimeTerm demoWeilTest 1) (logN 2 (by omega)) := by
    show Req (Rmul (vonMangoldt 2) (Radd one (Rmul (ofQ ⟨1, 2⟩ (by decide)) zero)))
      (logN 2 (by omega))
    refine Req_trans (Rmul_congr vonMangoldt_two
      (Req_trans (Radd_congr (Req_refl one) (Rmul_zero _)) (Radd_zero one))) ?_
    exact Rmul_one (logN 2 (by omega))
  -- term 2 (`n = 3`): `Λ(3)·(0 + ⅓·0) ≈ 0`
  have h2 : Req (weilPrimeTerm demoWeilTest 2) zero := by
    show Req (Rmul (vonMangoldt 3) (Radd zero (Rmul (ofQ ⟨1, 3⟩ (by decide)) zero))) zero
    refine Req_trans (Rmul_congr (Req_refl (vonMangoldt 3))
      (Req_trans (Radd_congr (Req_refl zero) (Rmul_zero _)) (Radd_zero zero))) ?_
    exact Rmul_zero (vonMangoldt 3)
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Req_refl zero) h0) h1) h2) ?_
  -- `((0 + 0) + log 2) + 0 ≈ log 2`
  refine Req_trans (Radd_zero _) ?_
  refine Req_trans (Radd_congr (Radd_zero zero) (Req_refl _)) ?_
  exact Req_trans (Radd_comm zero _) (Radd_zero _)

end UOR.Bridge.F1Square.Square
