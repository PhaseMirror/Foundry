/-
F1 square — v0.19.0 (the genuine-pairing arc), brick W1: **THE WEIL FUNCTIONAL'S
CONSTRUCTED COMPONENTS** — the finite-place side and the archimedean constant, assembled
from built objects on an explicit constructive test class. No zeros as inputs.

THE NORMALIZATION (pinned; deep-research-verified verbatim against the primary PDFs —
99 agents, 21 claims 3-0). We use the UNSYMMETRIZED Connes–Consani printing (arXiv
2006.13771 Appendix B; published Selecta Math. 27 (2021) art. 77 — equation numbers
differ by one between editions, we cite the arXiv numbering):
  • the explicit formula:  `Σ_ρ f̃(ρ) = f̃(1) + f̃(0) − Σ_v W_v(f)`,  `f̃(s) = ∫₀^∞ f(x)x^{s−1}dx`;
  • the finite places (eq. 149):  `W_p(f) = (log p)·Σ_{m≥1} (f(pᵐ) + f^♯(pᵐ))`,
    `f^♯(x) = x⁻¹·f(x⁻¹)`  —  summed over primes:  `Σ_n Λ(n)·(f(n) + n⁻¹·f(1/n))`,
    RATIONAL weights (the `p^{−m/2}` weights belong to the shifted/symmetric Burnol
    normalization, math/0101068 Thm 2.1 — a different, verified printing; MIXING THEM is
    the convention trap, as is the involution `ǧ(x) = conj g(1/x)` under `dx/x` vs
    `x⁻¹·conj g(1/x)` under `dx`, and the archimedean constant `log 4π + γ` here vs
    `log 2π + γ` there);
  • the archimedean place (eq. 150):
    `W_ℝ(f) = (log 4π + γ)·f(1) + ∫₁^∞ (f(x) + f^♯(x) − (2/x)f(1)) dx/(x − x⁻¹)`
    — a principal value tamed by the `f(1)`-subtraction; for `supp f ⊂ [1/X, X]` the
    `f`-part of the integral ranges over `[1, X]` only, but when `f(1) ≠ 0` the
    subtracted tail extends past `X` with an elementary closed form — NOT truncatable
    at the support edge (the verified caveat).

WHAT IS CONSTRUCTED HERE (no hedge): on a test datum `f : ℚ → Real` with support cutoff
`X` (the evaluations the components consume are at rational points only — exactly right
for piecewise-linear test functions with rational breakpoints, which are ADMISSIBLE to
Weil's criterion directly: Bombieri's class `W` (the official Clay problem description,
§V) requires only piecewise-`C¹` with averaged jumps and `O(x^δ)/O(x^{−1−δ})` decay):
  • `weilPrimePart` — THE WHOLE FINITE-PLACE SIDE: the finite sum
    `Σ_{n≤X} Λ(n)·(f(n) + n⁻¹·f(1/n))` (finite because `supp f ⊂ [1/X, X]`;
    `weilPrimePart_stable` proves the sum is constant past the cutoff — the same
    discipline as `primeSide_stable`);
  • `weilArchConst` — the archimedean constant term `(log 4π + γ)·f(1)`: both factors
    built (`Rlog4pic` v0.14.0, `Rgamma_h` v0.14.0).
WHAT REMAINS INTERFACE (the faithful boundary): the archimedean INTEGRAL and the pole
terms `f̃(1) + f̃(0)` are integrals of `f`; for piecewise-polynomial `f` with rational
breakpoints their reduction to closed forms (rational combinations of logarithms) is
ROUTINE BUT UNVERIFIED IN PRINT (the deep-research open question) — transcribing an
unverified reduction would breach the gate, so they enter the pairing as interface data
(`Square/Pairing.lean`), never fabricated.

THE CRITERION this feeds (stated at the pairing level): `RH ⟺ W(g ⋆ g^τ) ≥ 0` for all
test `g` — ELEMENTARY in both directions (Weil 1952; Burnol arXiv math/9810169 proves
the Lemma directly, "rather than applying a suitable density argument"; the C.R. note
math/0101068: "il est élémentaire que l'Hypothèse de Riemann équivaut à: Z(k) ≥ 0").

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.Mangoldt
import Foundations.F1.Analysis.LambdaOne
import Foundations.F1.Analysis.RSum

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **A Weil test datum**: the rational-point evaluations of a test function
    (classically `f = g ⋆ g^τ`, piecewise-linear with rational breakpoints — admissible
    per Bombieri's class `W`), with the support cutoff `X` (`f` vanishes at the rational
    points `n` and `1/n` for `n > X` — exactly the evaluations the finite-place side
    consumes). -/
structure WeilTest where
  /-- the test function's rational-point evaluations -/
  f : Q → Real
  /-- the support cutoff: `supp f ⊆ [1/X, X]` -/
  X : Nat
  /-- the cutoff is positive -/
  hX : 1 ≤ X
  /-- vanishing above the support: `f(n) ≈ 0` for `n > X` -/
  supp_high : ∀ n : Nat, X < n → Req (f ⟨(n : Int), 1⟩) zero
  /-- vanishing below the support: `f(1/n) ≈ 0` for `n > X` -/
  supp_low : ∀ n : Nat, X < n → Req (f ⟨1, n⟩) zero

/-- The `n+1`-st finite-place term: `Λ(n+1)·(f(n+1) + (n+1)⁻¹·f(1/(n+1)))` — the
    unsymmetrized CC weights (rational, no square roots). -/
def weilPrimeTerm (T : WeilTest) (n : Nat) : Real :=
  Rmul (vonMangoldt (n + 1))
    (Radd (T.f ⟨((n + 1 : Nat) : Int), 1⟩)
      (Rmul (ofQ ⟨1, n + 1⟩ (Nat.succ_pos n)) (T.f ⟨1, n + 1⟩)))

/-- **THE FINITE-PLACE SIDE OF THE WEIL FUNCTIONAL, constructed**:
    `Σ_{n≤X} Λ(n)·(f(n) + n⁻¹·f(1/n))` — a finite sum of built objects (the von Mangoldt
    weights of v0.15.3 on the test datum's rational evaluations). -/
def weilPrimePart (T : WeilTest) : Real := RsumN (weilPrimeTerm T) T.X

/-- Terms beyond the support cutoff vanish: `weilPrimeTerm T n ≈ 0` for `n + 1 > X`. -/
theorem weilPrimeTerm_past_support (T : WeilTest) (n : Nat) (hn : T.X < n + 1) :
    Req (weilPrimeTerm T n) zero := by
  refine Req_trans (Rmul_congr (Req_refl (vonMangoldt (n + 1)))
    (Req_trans (Radd_congr (T.supp_high (n + 1) hn)
      (Req_trans (Rmul_congr (Req_refl _) (T.supp_low (n + 1) hn)) (Rmul_zero _)))
      (Radd_zero zero))) ?_
  exact Rmul_zero (vonMangoldt (n + 1))

/-- **Stability past the cutoff** (the `primeSide_stable` discipline): extending the
    finite-place sum beyond `X` does not change it — the sum IS the whole prime side. -/
theorem weilPrimePart_stable (T : WeilTest) :
    ∀ d : Nat, Req (RsumN (weilPrimeTerm T) (T.X + d)) (weilPrimePart T) := by
  intro d
  induction d with
  | zero => exact Req_refl _
  | succ k ih =>
    show Req (Radd (RsumN (weilPrimeTerm T) (T.X + k)) (weilPrimeTerm T (T.X + k))) _
    refine Req_trans (Radd_congr ih (weilPrimeTerm_past_support T (T.X + k) (by omega))) ?_
    exact Radd_zero (weilPrimePart T)

/-- **The archimedean constant term, constructed**: `(log 4π + γ)·f(1)` — the constant
    part of the CC archimedean place `W_ℝ` (arXiv eq. 150), both factors built. -/
def weilArchConst (T : WeilTest) : Real :=
  Rmul (Radd Rlog4pic Rgamma_h) (T.f ⟨1, 1⟩)

end Multiplicity.UOR.Bridge.F1Square.Analysis
