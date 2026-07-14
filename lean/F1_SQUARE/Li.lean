/- ===========================================================================
   ADR-100: Conditional Proof Scaffold
   This is a research program. RH remains open. The F1-square with Hodge index
   is unconstructed. Numerical experiments and admitted bounds are exploratory
   and do not constitute proof or unconditional verification.
   ===========================================================================
   F1 square — the λₙ / Riemann-Hypothesis PROOF BOUNDARY, stated as faithfully as this substrate
   allows (the v0.10.0 milestone: lock the proof boundary before building ζ).

This is the analytic face of the same crux that `Crux.lean` states geometrically. By **Li's criterion**
(Xian-Jin Li, *J. Number Theory* 65 (1997), 325–333), the Riemann Hypothesis is equivalent to the
positivity of the Li coefficients:

    RH  ⟺  λₙ > 0   for all n ≥ 1,        λₙ := Σ_ρ [ 1 − (1 − 1/ρ)ⁿ ]   (paired sum over the
                                          nontrivial zeros ρ of ζ; equivalently the derivative form
                                          λₙ = (1/(n−1)!) dⁿ/dsⁿ[ sⁿ⁻¹ log ξ(s) ]|_{s=1}).

So `∀ n ≥ 1, λₙ > 0` IS RH. (For ζ the criterion is the **strict** `> 0`; the **non-strict** `≥ 0`
form is the general Bombieri–Lagarias multiset criterion — *Complements to Li's Criterion for the
Riemann Hypothesis*, *J. Number Theory* 77 (1999), 274–287 — and is likewise equivalent to RH. We
state both faces.) This module pins that boundary HONESTLY.

  • `Rnonneg x` is the Bishop "x ≥ 0" on our constructive reals; `Pos` (already in `Analysis.Real`) is
    the strict "x > 0". Both are genuine (witnessed by `0`, `1`).
  • `LiPositive lam` is the strict property `∀ n ≥ 1, Pos (lam n)`; `LiNonneg lam` the non-strict
    `∀ n ≥ 1, Rnonneg (lam n)`. `template_liPositive` / `template_liNonneg` PROVE them for a concrete
    (constant) sequence — so the properties are real and satisfiable.
  • THE CRUX is `LiPositive` for the genuine ζ-derived Li sequence (companion §1.5 / T5, analytic face).
    It is OPEN, and here is the faithful reason it is not a corollary of the template:

    FAITHFULNESS CAUTION. The crux is `LiPositive` on the SPECIFIC sequence `λ` of Li coefficients of
    ζ — which is uniquely determined by ζ but is not constructed in this substrate (it needs ζ, the
    explicit formula, and ℂ — not built here). Do NOT:
      (a) define the crux as `∃ lam, LiPositive lam` — witnessed by the constant `1` sequence
          (`template_liPositive`), TRUE, and NOT RH;
      (b) substitute the template, a square, `|·|`, a sum of squares, or any manifestly-positive
          expression for the genuine `λ` (positivity must be a theorem about the ζ-zero sum, not a
          syntactic property of the definition);
      (c) mistake a FINITE check for the theorem: the first ~10⁵ Li coefficients are numerically
          positive (computed to n = 100 000, Feb 2025), so `LiPositiveUpTo lam N` holds for every
          checkable `N` — but `LiPositive lam = ∀ N, LiPositiveUpTo lam N` (`liPositive_iff_all_upTo`),
          and no finite `N` (no `decide` over `n < N`) delivers the universal;
      (d) use a TRUNCATED `λ` (a finite zero-sum) as the object — those truncations can be all-positive
          while the limit's positivity is still exactly RH.
    The equivalence `LiPositive λ ⟺ RH` is itself [CLASSICAL] (Li 1997); and positivity reformulations
    do **not** make RH easier — they relocate, not remove, the difficulty (Conrey–Li, *IMRN* 2000).
    Therefore `LiCrux` below is parameterized by the (unconstructed) genuine sequence; we neither
    construct it, nor assert `LiPositive λ`, nor axiomatize it. If such a `λ` is one day built here and
    `LiPositive λ` proved (axiom-clean, audited), that is RH — a result, not a defect.

  • The substrate the ζ-layer must realize is stated as honest INTERFACES (never asserted for the
    genuine `λ`): `LiDecomposition` (Bombieri–Lagarias `λₙ = λₙ^{arith} + λₙ^{∞}`),
    `ExplicitFormulaTrace` (the Weil explicit formula as a trace; Weil 1952, Connes 1999), and
    `LiAgreesWith` (`computed = classical Li`). Each is shown genuine/inhabited; the real instances
    need ζ and — crucially — do NOT bear on positivity. REALIZATION LEDGER: `LiDecomposition`
    realized non-trivially at `n = 1` (v0.15.3) and `n = 1, 2` (v0.18.0,
    `Analysis.li_decomposition_two_realized`); `ExplicitFormulaTrace` and `LiAgreesWith` realized at
    the built slices (v0.19.0, `Analysis/LiComplete.lean`) — the interfaces are retired exactly as
    far as the built `λ` slices reach, and no further.

  • The Li coefficients are typed as `λ : Nat → ExactBoundedReal` (a stream of certified-enclosure
    reals, `Analysis.ExactBounded`). ζ at integer `s ≥ 2` is built as a *concrete* such object
    (`Analysis.zeta`, `Σ 1/iˢ` with the rigorous tail bound `zetadiff_bound`); the genuine ζ-derived
    `λ` (which needs analytic continuation, the explicit formula, and `log`) is the deferred input the
    interfaces above are stated against — its *values* are not fabricated here.

Pure Lean 4, no Mathlib, no `()`.
-/

import F1Square.Analysis.ExactBounded
import F1Square.Analysis.ROrder

namespace UOR.Bridge.F1Square.Li

open UOR.Bridge.F1Square.Analysis

/-- `1 > 0` (witnessed at index 1: `1/2 < 1`). -/
theorem Pos_one : Pos one := ⟨1, by decide⟩

-- `Rnonneg` (Bishop `x ≥ 0`) and `Rnonneg_zero`/`Rnonneg_one`/`Rnonneg_Radd` are the canonical
-- real-order definitions, now in `Analysis.ROrder` (the v0.11.0 order layer) and used here via `open`.

-- ===========================================================================
-- The Li coefficients as a property, and THE CRUX (analytic face of RH).
-- ===========================================================================

/-- **Li-positivity** (strict, the ζ-specific Li 1997 criterion): `λₙ > 0` for every `n ≥ 1`. For the
    genuine Li sequence of ζ this property IS RH. -/
def LiPositive (lam : Nat → ExactBoundedReal) : Prop := ∀ n : Nat, 0 < n → Pos (lam n)

/-- **Li non-negativity** (the non-strict general Bombieri–Lagarias 1999 multiset form): `λₙ ≥ 0` for
    every `n ≥ 1`; likewise equivalent to RH [CLASSICAL] (Bombieri–Lagarias 1999). -/
def LiNonneg (lam : Nat → ExactBoundedReal) : Prop := ∀ n : Nat, 0 < n → Rnonneg (lam n)

/-- The constant-`1` sequence is Li-positive — so the (strict) PROPERTY is genuine and satisfiable.
    This is the analytic analogue of `Crux.template_hodgeIndex`; it is exactly the witness that makes
    `∃ lam, LiPositive lam` true and hence NOT RH. -/
theorem template_liPositive : LiPositive (fun _ => one) := fun _ _ => Pos_one

/-- The constant-`1` sequence is Li-non-negative (the non-strict face is genuine too). -/
theorem template_liNonneg : LiNonneg (fun _ => one) := fun _ _ => Rnonneg_one

/-- The **checkable finite approximant**: Li-positivity up to index `N`. -/
def LiPositiveUpTo (lam : Nat → ExactBoundedReal) (N : Nat) : Prop :=
  ∀ n : Nat, 0 < n → n ≤ N → Pos (lam n)

/-- Every finite truncation of the template is Li-positive — as the first ~10⁵ true Li coefficients
    are numerically. This is what a finite numerical check establishes. -/
theorem template_liPositiveUpTo (N : Nat) : LiPositiveUpTo (fun _ => one) N :=
  fun _ _ _ => Pos_one

/-- **The finite-check guard**: Li-positivity is exactly the conjunction of ALL its finite
    truncations — and no single finite `N` delivers it. This is the precise sense in which the
    numerical positivity of the first `N` Li coefficients (for every checkable `N`) is *not* a proof
    of RH: the theorem is the universal `∀ N`, which no `decide` reaches. -/
theorem liPositive_iff_all_upTo (lam : Nat → ExactBoundedReal) :
    LiPositive lam ↔ ∀ N, LiPositiveUpTo lam N := by
  constructor
  · intro h _ n hn _; exact h n hn
  · intro h n hn; exact h n n hn (Nat.le_refl n)

/-- **THE CRUX (analytic face).** `LiCrux lam` is `LiPositive lam`; the Riemann Hypothesis is
    `LiCrux λ` for the unconstructed genuine Li sequence `λ` of ζ. OPEN: no such `λ` is constructed
    and `LiPositive λ` is neither proved nor axiomatized here. `template_liPositive` shows the
    property is genuine; the crux is the SAME property on a DIFFERENT, unbuilt sequence — that
    specificity is the open content, identical in spirit to `Crux.CruxFor 𝕊`. -/
def LiCrux (lam : Nat → ExactBoundedReal) : Prop := LiPositive lam

-- ===========================================================================
-- The ζ-layer substrate as honest INTERFACES (statable now; realizable once ζ is built; none bears
-- on positivity). Each is a genuine, inhabited predicate — never asserted for the real Li sequence.
-- ===========================================================================

/-- The **Bombieri–Lagarias decomposition** interface (1999): `λₙ = λₙ^{arith} + λₙ^{∞}` (an
    arithmetic/prime-power part `−Σ Λ(m)·wₙ(m)` plus an archimedean/gamma part), pointwise up to `≈`.
    The pieces have mixed signs (see `Rnonneg_Radd`); this interface fixes only their *sum*. -/
def LiDecomposition (lam arith arch : Nat → ExactBoundedReal) : Prop :=
  ∀ n : Nat, Req (lam n) (Radd (arith n) (arch n))

/-- The decomposition predicate is genuine (inhabited by the trivial split `λ = λ + 0`). The real
    arithmetic/archimedean pieces require ζ and the explicit formula. -/
theorem liDecomposition_genuine (lam : Nat → ExactBoundedReal) :
    LiDecomposition lam lam (fun _ => zero) := fun n => Req_symm (Radd_zero (lam n))

/-- The **Weil explicit formula as a trace** interface (Weil 1952; Connes, *Selecta Math.* 5 (1999),
    29–106): the zeros-side equals a prime-side (`Σ_p Σ_k log p · h(k log p)`) plus an archimedean-side
    (the `Γ′/Γ` place at `∞`). -/
def ExplicitFormulaTrace (zeroSide primeSide archSide : Real) : Prop :=
  Req zeroSide (Radd primeSide archSide)

/-- The explicit-formula-trace predicate is genuine (inhabited). The real instance — with the actual
    prime and archimedean distributions — is the classical Weil explicit formula, statable here and
    realizable once ζ is built; it does NOT bear on positivity. REALIZED (v0.19.0): the trivial
    inhabitant below is retired by `Analysis.explicitFormulaTrace_one_realized` /
    `Analysis.explicitFormulaTrace_two_realized` (the zero side `λ₁`/`λ₂` at the Bombieri–Lagarias
    slices, all three sides built) and the `Analysis.WeilTrace` ladder (`Analysis/LiComplete.lean`). -/
theorem explicitFormulaTrace_genuine (z : Real) : ExplicitFormulaTrace z z zero :=
  Req_symm (Radd_zero z)

/-- The **`computed = classical Li`** interface: a computed Li sequence agrees (up to `≈`) with the
    classical Li coefficients. This is the milestone that retires analytic debt (making `λₙ` a
    certified-computable object tied to the classical definition); it is independent of positivity. -/
def LiAgreesWith (computed classical : Nat → ExactBoundedReal) : Prop :=
  ∀ n : Nat, Req (computed n) (classical n)

/-- The agreement predicate is genuine (reflexive). REALIZED non-reflexively (v0.19.0):
    `Analysis.liAgreesWith_two_realized` — the direct certified builds agree with the
    Bombieri–Lagarias closed-form assemblies at the built slices (`Analysis/LiComplete.lean`). -/
theorem liAgreesWith_genuine (lam : Nat → ExactBoundedReal) : LiAgreesWith lam lam := fun n => Req_refl (lam n)

end UOR.Bridge.F1Square.Li
