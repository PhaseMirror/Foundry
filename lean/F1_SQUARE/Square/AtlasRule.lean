/-
F1 square — v0.21.0 stage G, brick **G0a (the atlas rule + the §6 relocation)**: the typed,
zero-free embedding rule, Gate B free, the growth pre-filter, and the recorded negative result —
the Cayley candidate is a relocation — made formal at the match level.

ROADMAP §6 (the recorded negative result and the rule it establishes) and §7/§8 (Stage G0a). The
missing object needs a rule `Cₙ ↦ vector` that is **atlas-intrinsic and zero-free** (§6: "any `ι`
built from the zeros is a relocation"). This brick:

- Encodes the no-smuggling rule at the TYPE level: an `AtlasRule := ℕ → ℕ → Real` takes no zero
  (`Complex` zero / `StieltjesEta`) as input. Gate B is free for every such rule
  (`atlasRule_gateB = WeilPSD_gramOf`).
- States the **growth pre-filter** (`atlasRule_growth_filter`): realizing the genuine diagonal
  forces `gramOf ι D n n ≈ 2λₙ`, so a rule whose squared-norm diagonal does not reproduce the Li
  growth `2λₙ ~ n log n` (Voros/Lagarias) is rejected before any definiteness question.
- Makes §6 FORMAL at the embedding-match level. The Cayley candidate `ι Cₙ = (1 − wₚⁿ)`,
  `wₚ = 1 − 1/ρ`, has per-zero squared modulus governed by `|ρ−1|²/|ρ|²` (`ZeroGeometry`), so its
  Gate-A match at a zero ρ is exactly `|ρ−1|² = |ρ|²`, which `cayleyRatio_match_iff_onLine` proves
  is `Re ρ = ½`. Hence **`cayley_relocation`**: the zero-built candidate matches at EVERY zero iff
  every zero is on the critical line — i.e. its Gate A IS RH. The candidate built from the zeros
  relocates RH into Gate A (§4.1); it is not a proof. This is the formal §6 result.

The reusable nugget `Rdouble_inj` (`2x ≈ 2y ⟹ x ≈ y`, via `Rhalf`) closes the forward direction.

HONEST SCOPE. Nothing asserts an atlas rule that realizes the diagonal exists (that is RH). §6's
content is a NEGATIVE result: the obvious zero-built rule is circular. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.WeilPSD
import F1Square.Analysis.ZeroGeometry

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The atlas rule (zero-free by type) and Gate B (free).
-- ===========================================================================

/-- An **atlas-intrinsic embedding rule** `Cₙ ↦ ℝ^D`: a plain `ℕ → ℕ → Real`, taking NO zero (no
    `Complex` zero, no `StieltjesEta`) as input — the §6 no-smuggling rule at the type level. -/
abbrev AtlasRule := Nat → Nat → Real

/-- **Gate B is free for every atlas rule**: its embedding Gram into `ℝ^D` is `WeilPSD` (§4.1 — the
    difficulty is not in Gate B). -/
theorem atlasRule_gateB (ι : AtlasRule) (D : Nat) : WeilPSD (gramOf ι D) :=
  WeilPSD_gramOf ι D

/-- **THE GROWTH PRE-FILTER** (necessary condition): if an atlas rule realizes the genuine
    diagonal, its squared-norm diagonal must EQUAL `2λₙ` for every `n`. A rule whose `gramOf ι D n n`
    does not reproduce the Li growth `2λₙ ~ n log n` (Voros/Lagarias) cannot realize the diagonal
    and is rejected before any definiteness question. -/
theorem atlasRule_growth_filter (E : StieltjesEta) (ι : AtlasRule) (D : Nat)
    (h : RealizesDiag (genuineSpectralSquare E) ι D) :
    ∀ n, 0 < n → Req (gramOf ι D n n)
      (Radd (genuineLamSeq E.eta n) (genuineLamSeq E.eta n)) :=
  (realizesDiag_genuine_iff E ι D).mp h

-- ===========================================================================
-- The reusable halving nugget.
-- ===========================================================================

/-- **`2x ≈ 2y ⟹ x ≈ y`** — halving via `Rhalf` (`Rhalf_Radd` + `Rhalf_double`). -/
theorem Rdouble_inj {x y : Real} (h : Req (Radd x x) (Radd y y)) : Req x y := by
  have hx : Req (Rhalf (Radd x x)) x := Req_trans (Rhalf_Radd x x) (Rhalf_double x)
  have hy : Req (Rhalf (Radd y y)) y := Req_trans (Rhalf_Radd y y) (Rhalf_double y)
  exact Req_trans (Req_symm hx) (Req_trans (Rhalf_congr h) hy)

-- ===========================================================================
-- §6: the Cayley candidate is a relocation (now formal at the match level).
-- ===========================================================================

/-- **The Cayley per-zero match `|ρ−1|² = |ρ|²` is exactly `Re ρ = ½`** (`OnCriticalLine`). Forward:
    the match makes `liRatio_diff_eq`'s `1 − 2·Re ρ` vanish, so `Re ρ = ½` (via `Rdouble_inj`).
    Backward: `liRatio_on_line`. -/
theorem cayleyRatio_match_iff_onLine (z : Complex) :
    Req (csubOneNormSq z) (cnormSq z) ↔ OnCriticalLine z := by
  constructor
  · intro hmatch
    have hz : Req (Rsub (csubOneNormSq z) (cnormSq z)) zero :=
      Req_trans (Rsub_congr hmatch (Req_refl _)) (Radd_neg (cnormSq z))
    have h0 : Req (Rsub one (Radd z.re z.re)) zero :=
      Req_trans (Req_symm (liRatio_diff_eq z)) hz
    have h1 : Req (Radd z.re z.re) one := Req_symm (Req_of_Rsub_zero h0)
    exact Rdouble_inj (Req_trans h1 (Req_symm half_add_half))
  · intro hline
    exact liRatio_on_line z hline

/-- **§6, FORMAL — the Cayley candidate is a relocation.** A candidate built from the zeros
    (`ι Cₙ = 1 − (1−1/ρ)ⁿ`, squared modulus governed by `|ρ−1|²/|ρ|²`) matches the on-line value
    at EVERY zero iff every zero is on the critical line — i.e. its Gate-A match is exactly RH.
    Building `ι` from the zeros relocates RH into Gate A; it is not a proof. This is why the §6
    rule forbids any reference to `wₚ, rₚ, θₚ`. -/
theorem cayley_relocation (isZero : Complex → Prop) :
    (∀ z, isZero z → Req (csubOneNormSq z) (cnormSq z)) ↔ AllZerosOnLine isZero := by
  constructor
  · intro h z hz; exact (cayleyRatio_match_iff_onLine z).mp (h z hz)
  · intro h z hz; exact (cayleyRatio_match_iff_onLine z).mpr (h z hz)

end UOR.Bridge.F1Square.Square
