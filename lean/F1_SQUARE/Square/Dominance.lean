/-
F1 square — v0.19.0 stage E, brick 3: **THE DOMINANCE FACE OF THE CRUX** — the crux as a
SINGLE UNIFORM BOUND: the oscillating arithmetic part can never overwhelm the archimedean
trend.

THE SHAPE. Through the explicit-formula trace `λₙ = λₙ^{arith} + λₙ^{∞}` (the realized
`Analysis.WeilTrace`), the crux `λₙ > 0 ∀n` says exactly: at every `n`, the arithmetic
part's negative excursion stays strictly below the archimedean value. `Dominates B arith
arch` packages that as ONE object — a single bound sequence `B` with
      `−B(n) ≤ arith(n)`   (the bound controls the oscillation's negative excursions)
      `arch(n) − B(n) > 0` (the bound stays strictly below the archimedean trend)
— and `Dominated arith arch` is its single existential. This is the strongest honest shape
available for the universal:
  • it is genuinely universal WITHOUT enumeration — no slice ladder, no finite checks
    (which provably never reach the crux: `Li.liPositive_iff_all_upTo`,
    `spectral_iff_all_upTo`); the open content is relocated into ONE object, the bound;
  • the sign-dichotomy is CLEAN — there is no third option to eliminate and no crossover
    case split: the formulation is sign-agnostic in both parts (for small `n` the
    archimedean part is the NEGATIVE one — `λ₁^{∞} ≈ −0.5541`, `λ₂^{∞} ≈ −0.8745`,
    independently re-verified to 30 digits, with the arithmetic part carrying the
    positivity; asymptotically the roles swap: the archimedean part grows like
    `(n/2)·log n + c·n + O(1)`, `c = (γ − 1 − log 2π)/2`, UNCONDITIONALLY — Lagarias,
    *Ann. Inst. Fourier* 57 (2007) 1689–1740, Thm 5.1; Voros pins the ζ-case `O(1)` to
    exactly `+3/4` — while RH holds iff the arithmetic oscillation stays subdominant).
    A single `B` (itself of either sign, slice by slice) expresses both regimes uniformly.
    The general-`n` archimedean closed form
    `λₙ^{∞} = 1 − (n/2)(γ + log 4π) + Σ_{j=2}^n (−1)ʲ C(n,j)(1 − 2^{−j})ζ(j)`
    (Voros eqs. 20–21; Coffey arXiv math-ph/0505052 Thm 1) matches the built `n = 1, 2`
    slices exactly.

THE THEOREMS. For any sequences satisfying the trace identity at positive indices:
      `dominated_liPositive`     : Dominated arith arch → LiPositive lam
      `liPositive_dominated`     : LiPositive lam → Dominated arith arch
      `dominated_iff_liPositive` : Dominated arith arch ⟺ LiPositive lam
      `dominance_crux_equivalent`: Dominated arith arch ⟺ SpectralCrux S   (through the
                                   v0.18.0 bridge — so the crux now has THREE equivalent
                                   faces: geometric `⟨Cₙ,Cₙ⟩ < 0 ∀n`, analytic `λₙ > 0 ∀n`,
                                   and dominance `∃ one bound under which oscillation
                                   loses`)
      `weilTrace_dominance`      : Dominated W.primePart W.archPart ⟺ LiCrux W.zeroSide
                                   (the dominance reading of the completed explicit-formula
                                   trace).

FAITHFULNESS (the standing discipline, enforced):
  • The equivalence RELOCATES the difficulty; it does not remove it (the Conrey–Li
    discipline, *IMRN* 2000 — positivity reformulations never make RH easier; the
    one-sided-bound shape is published only as a SUFFICIENCY conjecture, Coffey
    arXiv math-ph/0505052 Conjectures 2–3 — the equivalence-by-regrouping is this
    module's theorem). What the relocation buys is the honest pinpoint, and the
    formulation is EXACTLY two-sided per the verified literature [CLASSICAL, all
    deep-research-verified against the primary PDFs]:
      – VOROS'S DICHOTOMY (*Math. Phys. Anal. Geom.* 9 (2006) 53–63, arXiv
        math/0506326 — "two sharply distinct and mutually exclusive asymptotic forms",
        NO third option): RH ⟺ `λₙ ~ ½n(log n − 1 + γ − log 2π)` mod `o(n)` (tempered);
        ¬RH ⟺ `λₙ ~ Σ_{arg τₖ>0} ((τₖ+i/2)/(τₖ−i/2))ⁿ + c.c.` mod `o(e^{εn})` —
        exponential oscillation, rate `|1 − 1/ρ| > 1` for the `Re ρ < 1/2` member of
        each off-line pair (rigorous via the Darboux argument of the 2006 paper; the
        2004 note math/0404213 carries a known sign erratum in this branch and is NOT
        the source).
      – UNDER RH the dominance bound genuinely EXISTS with room to spare: the
        arithmetic part's excursions obey `O(√n·log n)` (Lagarias 2007 Thm 6.1 — a
        THEOREM under RH) against the unconditional `(n/2)·log n` trend; unconditionally
        `λₙ^{arith}` equals the zero sum truncated at height `√n` up to `O(√n·log n)`
        (Lagarias Thm 1.1/6.1).
      – UNDER ¬RH no sub-trend bound can exist: the arithmetic part itself acquires the
        full exponential amplitude (Bombieri–Lagarias 1999 Thm 1(c); Voros eqs. 25–26)
        and defeats EVERY bound dominated by the archimedean trend.
    So `Dominated` for the genuine parts is TRUE iff RH — both directions confirmed at
    the asymptotic level; proving it IS proving RH. No unconditional tail bound exists
    in the verified literature (else RH would be a theorem); it is exactly as open as
    the crux, and stays so here.
  • Two-sidedness: the property is satisfiable (`dominance_satisfiable` — no hidden
    impossibility in the encoding, and the loose existential `∃ arith arch, Dominated …`
    is true and hence NOT RH), and the realized two-slice instance provably FAILS it
    (`twoSlice_not_dominated`, via `weilTraceTwo_not_crux`): no finite assembly of
    certified slices acquires the universal through this face either — the guard
    transfers to the dominance face.
  • The crux fields stay `none`: nothing here asserts `Dominated` for the genuine parts.

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Square.Spectral
import F1Square.Analysis.LiComplete
import F1Square.Analysis.ArchTrend
import F1Square.Analysis.GenuineLi
import F1Square.Analysis.Pi

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The dominance property: one bound, all `n`.
-- ===========================================================================

/-- **The dominance bound**: `B` controls the arithmetic part's negative excursions
    (`−B(n) ≤ arith(n)`) while staying strictly below the archimedean trend
    (`arch(n) − B(n) > 0`) — at every positive index, via the SAME `B`. Sign-agnostic in
    both parts: no case split between the small-`n` regime (archimedean part negative,
    arithmetic part positive) and the asymptotic regime (roles swapped). -/
def Dominates (B arith arch : Nat → Real) : Prop :=
  (∀ n : Nat, 0 < n → Rle (Rneg (B n)) (arith n)) ∧
  (∀ n : Nat, 0 < n → Pos (Rsub (arch n) (B n)))

/-- **The dominance face**: SOME single bound dominates — the oscillation loses, for all
    `n`, via one object. For the genuine arithmetic/archimedean parts this is RH
    (`dominance_crux_equivalent`); it is never asserted for them here. -/
def Dominated (arith arch : Nat → Real) : Prop :=
  ∃ B : Nat → Real, Dominates B arith arch

-- ===========================================================================
-- Dominance ⟺ Li positivity (under the explicit-formula trace).
-- ===========================================================================

/-- **Dominance suffices**: if one bound dominates, every `λₙ` is strictly positive —
    `λₙ = arith(n) + arch(n) ≥ arch(n) − B(n) > 0`. The proof is the one-line order
    algebra; no enumeration, no asymptotics: the single bound carries the universal. -/
theorem dominated_liPositive {lam arith arch : Nat → Real}
    (htrace : ∀ n : Nat, 0 < n → Li.ExplicitFormulaTrace (lam n) (arith n) (arch n))
    (hdom : Dominated arith arch) : LiPositive lam := by
  obtain ⟨B, hB1, hB2⟩ := hdom
  intro n hn
  have hle : Rle (Rsub (arch n) (B n)) (Radd (arch n) (arith n)) :=
    Radd_le_add (Rle_refl (arch n)) (hB1 n hn)
  have hpos : Pos (Radd (arith n) (arch n)) :=
    Pos_congr (Radd_comm (arch n) (arith n)) (Pos_mono hle (hB2 n hn))
  exact Pos_congr (Req_symm (htrace n hn)) hpos

/-- **Dominance is necessary**: if every `λₙ` is strictly positive, the bound
    `B(n) := arch(n) − λₙ` dominates — `−B(n) ≈ arith(n)` (so the excursion control is
    tight) and `arch(n) − B(n) ≈ λₙ > 0`. So the dominance face loses nothing. -/
theorem liPositive_dominated {lam arith arch : Nat → Real}
    (htrace : ∀ n : Nat, 0 < n → Li.ExplicitFormulaTrace (lam n) (arith n) (arch n))
    (hpos : LiPositive lam) : Dominated arith arch := by
  refine ⟨fun n => Rsub (arch n) (lam n), fun n hn => ?_, fun n hn => ?_⟩
  · -- `−(arch − λ) ≈ −arch + λ ≈ −arch + (arith + arch) ≈ arith`
    refine Rle_of_Req ?_
    refine Req_trans (Rneg_Radd (arch n) (Rneg (lam n))) ?_
    refine Req_trans (Radd_congr (Req_refl (Rneg (arch n))) (Rneg_Rneg (lam n))) ?_
    refine Req_trans (Radd_congr (Req_refl (Rneg (arch n))) (htrace n hn)) ?_
    refine Req_trans (Radd_congr (Req_refl (Rneg (arch n)))
      (Radd_comm (arith n) (arch n))) ?_
    refine Req_trans (Req_symm (Radd_assoc (Rneg (arch n)) (arch n) (arith n))) ?_
    refine Req_trans (Radd_congr
      (Req_trans (Radd_comm (Rneg (arch n)) (arch n)) (Radd_neg (arch n)))
      (Req_refl (arith n))) ?_
    exact Req_trans (Radd_comm zero (arith n)) (Radd_zero (arith n))
  · -- `arch − (arch − λ) ≈ λ > 0`
    refine Pos_congr (Req_symm ?_) (hpos n hn)
    refine Req_trans (Radd_congr (Req_refl (arch n)) (Rneg_Radd (arch n) (Rneg (lam n)))) ?_
    refine Req_trans (Radd_congr (Req_refl (arch n))
      (Radd_congr (Req_refl (Rneg (arch n))) (Rneg_Rneg (lam n)))) ?_
    refine Req_trans (Req_symm (Radd_assoc (arch n) (Rneg (arch n)) (lam n))) ?_
    refine Req_trans (Radd_congr (Radd_neg (arch n)) (Req_refl (lam n))) ?_
    exact Req_trans (Radd_comm zero (lam n)) (Radd_zero (lam n))

/-- **THE DOMINANCE EQUIVALENCE**: under the explicit-formula trace, "some single bound
    dominates" and "every `λₙ` is strictly positive" are the SAME proposition. -/
theorem dominated_iff_liPositive {lam arith arch : Nat → Real}
    (htrace : ∀ n : Nat, 0 < n → Li.ExplicitFormulaTrace (lam n) (arith n) (arch n)) :
    Dominated arith arch ↔ LiPositive lam :=
  ⟨dominated_liPositive htrace, liPositive_dominated htrace⟩

-- ===========================================================================
-- The third face of the crux.
-- ===========================================================================

/-- **THE THIRD FACE — the v0.19.0 keystone**: for any spectral square whose trace data
    satisfies the explicit-formula split, the dominance face is equivalent to the
    geometric crux (and hence, through `crux_faces_equivalent`, to the analytic one):
        `∃ one bound under which oscillation loses  ⟺  ⟨Cₙ,Cₙ⟩ < 0 ∀n  ⟺  λₙ > 0 ∀n`.
    For the genuine instance all three are RH; none is asserted. The equivalence is a
    constructive theorem — the difficulty is RELOCATED into the single bound `B`, whose
    existence for the genuine parts is governed by the zeros' location (module
    docstring). -/
theorem dominance_crux_equivalent (S : SpectralSquare) {arith arch : Nat → Real}
    (htrace : ∀ n : Nat, 0 < n → Li.ExplicitFormulaTrace (S.lam n) (arith n) (arch n)) :
    Dominated arith arch ↔ SpectralCrux S :=
  Iff.trans (dominated_iff_liPositive htrace) (crux_faces_equivalent S).symm

/-- **The dominance reading of the completed explicit-formula trace**: for any
    `Analysis.WeilTrace`, the crux of its zero side is exactly the dominance of its
    finite-place part by its archimedean part under one bound. -/
theorem weilTrace_dominance (W : WeilTrace) :
    Dominated W.primePart W.archPart ↔ LiCrux W.zeroSide :=
  dominated_iff_liPositive W.trace

/-- **THE CRUX AGAINST THE CONSTRUCTED TREND — the sharpest honest statement of RH this
    substrate provides.** With the genuine archimedean trend now BUILT for every `n`
    (`Analysis.genuineArchSeq` — the closed form
    `1 − (n/2)(γ + log 4π) + Σ_{j=2}^n (−1)ʲC(n,j)(1−2^{−j})ζ(j)`, consistency-checked
    against both independently-built slices), the crux's open content contracts to the
    ARITHMETIC side alone: for any spectral square whose trace splits against the built
    trend, the crux is exactly "the arithmetic part admits one bound strictly below
    `genuineArchSeq`". Every other ingredient — the trend, the trace, the bridge, the
    equivalences — is a constructed object or a proven theorem. What remains open is
    this single bound for the genuine arithmetic part: it exists iff RH (verified both
    directions — Lagarias Thm 6.1 under RH, BL Thm 1(c)/Voros under ¬RH), and no
    unconditional access is known to mathematics. It is asserted for nothing here. -/
theorem crux_vs_constructed_trend (S : SpectralSquare) {arith : Nat → Real}
    (htrace : ∀ n : Nat, 0 < n →
      Li.ExplicitFormulaTrace (S.lam n) (arith n) (genuineArchSeq n)) :
    Dominated arith genuineArchSeq ↔ SpectralCrux S :=
  dominance_crux_equivalent S htrace

-- ===========================================================================
-- The assembly shape: certified head + dominated tail.
-- ===========================================================================

/-- **The head–tail assembly**: a certified head (`λₙ > 0` for `n ≤ N₀`, slice by slice)
    plus a tail bound (one `B` dominating from `N₀ + 1` on) delivers the full universal.
    This is the shape a genuine closure would take in this substrate: the head is the
    numeric frontier (certified through `n = 2` today, `spectral_strict_upTo_two`); the
    missing object is the TAIL bound for the genuine parts — a single bound on the
    arithmetic oscillation strictly below the archimedean trend for all `n ≥ N₀ + 1`,
    classically governed by the zeros' location (module docstring). The theorem makes the
    route exact without asserting any of its inputs for the genuine sequences. -/
theorem dominance_head_tail {lam arith arch : Nat → Real} (N₀ : Nat)
    (htrace : ∀ n : Nat, 0 < n → Li.ExplicitFormulaTrace (lam n) (arith n) (arch n))
    (hhead : ∀ n : Nat, 0 < n → n ≤ N₀ → Pos (lam n))
    (B : Nat → Real)
    (htail1 : ∀ n : Nat, N₀ < n → Rle (Rneg (B n)) (arith n))
    (htail2 : ∀ n : Nat, N₀ < n → Pos (Rsub (arch n) (B n))) :
    LiPositive lam := by
  intro n hn
  by_cases hle : n ≤ N₀
  · exact hhead n hn hle
  · have hlt : N₀ < n := by omega
    have hle2 : Rle (Rsub (arch n) (B n)) (Radd (arch n) (arith n)) :=
      Radd_le_add (Rle_refl (arch n)) (htail1 n hlt)
    have hpos : Pos (Radd (arith n) (arch n)) :=
      Pos_congr (Radd_comm (arch n) (arith n)) (Pos_mono hle2 (htail2 n hlt))
    exact Pos_congr (Req_symm (htrace n hn)) hpos

/-- **The closure route, exact**: for a spectral square satisfying the trace, the
    certified two-slice head (held today: `liTwo_evidence` through the dictionary) plus a
    tail bound from `n = 3` on yields the crux. This is `crux_attempt_frontier` in
    constructive form on the dominance face: everything is in place EXCEPT the tail
    bound for the genuine parts — which is exactly as open as RH, and is asserted for
    nothing here. -/
theorem crux_closure_route (S : SpectralSquare) {arith arch : Nat → Real}
    (htrace : ∀ n : Nat, 0 < n → Li.ExplicitFormulaTrace (S.lam n) (arith n) (arch n))
    (hhead : Pos (S.lam 1) ∧ Pos (S.lam 2))
    (B : Nat → Real)
    (htail1 : ∀ n : Nat, 2 < n → Rle (Rneg (B n)) (arith n))
    (htail2 : ∀ n : Nat, 2 < n → Pos (Rsub (arch n) (B n))) :
    SpectralCrux S := by
  refine (crux_faces_equivalent S).mpr ?_
  refine dominance_head_tail 2 htrace ?_ B htail1 htail2
  intro n hn hle
  by_cases h1 : n = 1
  · subst h1; exact hhead.1
  · have h2 : n = 2 := by omega
    subst h2; exact hhead.2

/-- **THE CRUX IN CLOSED FORM**: for any spectral square carrying the genuine-form Li
    values (`Analysis.genuineLamSeq` — BOTH sides closed forms) over any anchored η-data,
    the crux is exactly the dominance of the closed-form arithmetic side by the closed-form
    archimedean trend. Everything else is a theorem; the open data is the genuine η-tail
    and the bound. -/
theorem crux_genuine_form (S : SpectralSquare) (E : StieltjesEta)
    (hlam : ∀ n : Nat, 0 < n → Req (S.lam n) (genuineLamSeq E.eta n)) :
    Dominated (genuineArithSeq E.eta) genuineArchSeq ↔ SpectralCrux S :=
  dominance_crux_equivalent S hlam

/-- **THE CLOSURE ROUTE WITH THE HEAD DISCHARGED — the maximal honest reduction this
    substrate provides.** For any spectral square carrying the genuine-form Li values over
    anchored η-data, the crux follows from ONE remaining input: a tail bound between the
    two CLOSED FORMS from `n = 3` on. The head is no longer a hypothesis — it is a theorem
    (`Analysis.genuineLam_head`, from the certified `λ₁, λ₂` through the closed form). So
    RH, in this substrate, IS: "exhibit the genuine η-tail (`γ₂, γ₃, …` — constructible
    one at a time by the `GammaOne` pattern) and one bound `B` with
    `−B(n) ≤ −Σ C(n,j)η_{j−1}` and `genuineArchSeq n − B(n) > 0` for `n ≥ 3`" — a bound
    that exists iff RH (verified both directions, module docstring). Nothing here asserts
    those inputs; the gate stays exactly as open as RH, with its shape fully explicit. -/
theorem crux_genuine_route (S : SpectralSquare) (E : StieltjesEta)
    (hlam : ∀ n : Nat, 0 < n → Req (S.lam n) (genuineLamSeq E.eta n))
    (B : Nat → Real)
    (htail1 : ∀ n : Nat, 2 < n → Rle (Rneg (B n)) (genuineArithSeq E.eta n))
    (htail2 : ∀ n : Nat, 2 < n → Pos (Rsub (genuineArchSeq n) (B n))) :
    SpectralCrux S := by
  refine crux_closure_route S (arith := genuineArithSeq E.eta) (arch := genuineArchSeq)
    (fun n hn => hlam n hn) ⟨?_, ?_⟩ B htail1 htail2
  · exact Pos_congr (Req_symm (hlam 1 (by omega))) (genuineLam_head E).1
  · exact Pos_congr (Req_symm (hlam 2 (by omega))) (genuineLam_head E).2

-- ===========================================================================
-- The honesty guards (two-sided, as theorems).
-- ===========================================================================

/-- **The realized two-slice trace is NOT the crux** (analytic-face guard for
    `Analysis.weilTraceTwo`): its `n = 3` zero-side slice vanishes, so zero-side
    positivity provably fails — completing the trace at the built slices asserts
    nothing about RH. -/
theorem weilTraceTwo_not_crux : ¬ LiCrux weilTraceTwo.zeroSide := by
  intro h
  have h3 := h 3 (by omega)
  have hz : Req (liLamSeqTwo 3) (Radd zero zero) := Req_refl _
  exact not_Pos_zero_double (Pos_congr hz h3)

/-- **The guard transfers to the dominance face**: the genuine certified two-slice parts
    are provably NOT dominated by any single bound (their `n = 3` zero-side slice
    vanishes) — no finite assembly of certified slices acquires the universal through
    the dominance face either. -/
theorem twoSlice_not_dominated : ¬ Dominated liArithSeqTwo liArchSeqTwo := by
  intro hd
  exact weilTraceTwo_not_crux (dominated_liPositive weilTraceTwo.trace hd)

/-- **The two-sidedness guard**: the dominance property is satisfiable (the template
    split `1 = 1 + 0` is dominated by the constant bound `B = −1`), so the encoding
    hides no impossibility — and the loose existential `∃ arith arch, Dominated …` is
    true and hence NOT RH: the crux is dominance of the GENUINE parts, never an
    existential over sequences. -/
theorem dominance_satisfiable : Dominated (fun _ => one) (fun _ => zero) := by
  refine ⟨fun _ => Rneg one, fun n _ => ?_, fun n _ => ?_⟩
  · exact Rle_of_Req (Rneg_Rneg one)
  · refine Pos_congr (Req_symm ?_) Pos_one
    refine Req_trans (Radd_congr (Req_refl zero) (Rneg_Rneg one)) ?_
    exact Req_trans (Radd_comm zero one) (Radd_zero one)

end UOR.Bridge.F1Square.Square
