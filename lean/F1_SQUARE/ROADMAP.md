# F1 Square — Roadmap to completion (v0.15.0 → v0.22.0)

The genuine-proof layer (`F1Square/`) builds the 𝔽₁ / Riemann-Hypothesis program from first
principles in **pure Lean 4** (Lean core + UOR-Foundation, **no Mathlib, no `sorry`/`native_decide`,
choice-free** — `{propext, Quot.sound}` only). Every commit is green and `#print axioms`-audited by
`scripts/honesty_audit.sh`.

**The bright line (permanent).** The honesty layer is a *verifier*, not a prohibition. The crux fields
`hodgeIndexHolds` and `liPositivityHolds` (both = RH) stay `none` until a genuine, audited, axiom-clean
proof exists. De-hedging removes *false modesty* about proven results; it never adds *false confidence*.
**The gate decides what is asserted, not ambition** — anything that does not close honestly stays an
explicit interface, exactly as the existing `Li`/`Crux` interfaces do, never faked.

The remaining construction is scoped into releases (stages **A–G**). Each is multi-commit, green
at every commit, axiom-clean, and resolved by analyzing the implementation here plus deep-research where
the literature is needed. Uncertainty (especially on the geometric frontier) is a research input, not a
stop sign — the focus is always the **construction of the F1 square**, to completion. Stages A–F ship
through v0.20.0; stage **G** (v0.21.0) carries the crux past the located frontier via the arithmetic
Hodge-index program — the isometric-embedding / missing-object route below.

## Status recap (`F1SquareStatus`, `F1Square.lean`)

| Field | Now | Target release |
|---|---|---|
| `intersectionTemplateValid` | `some true` (**canonical 𝕊**, derived intrinsically — v0.17.0) | shipped in **C** |
| `ampleClassExists` | `some true` (**canonical 𝕊** — v0.17.0) | shipped in **C** |
| `classGroupFinitelyGen` | `some true` (**canonical 𝕊** — v0.17.0) | shipped in **C** |
| `surfaceConstructed` | `some true` (**canonical 𝕊**, monoid-scheme level — v0.17.0) | shipped in **C** |
| `parallelPencilFinding` | `some true` (**canonical 𝕊** — v0.17.0) | shipped in **C** |
| `hodgeIndexHolds` (= RH, geometric) | `none` | **F / v0.20.0 shipped**: the dictionary is now DERIVED (the canonical `H¹` lattice, the primitive projection); the gate ran and LOCATED THE FRONTIER (the forced signature did not come out positive — that is RH), so this stays `none`; **G / v0.21.0** attacks it via the isometric embedding `ι` of the primitive span into a definite atlas space `L` (the missing-object route); it flips the instant the program reaches its *closed* terminal state (an audited, axiom-clean `‖ι Cₙ‖²_L = 2λₙ` with `L` definite), and stays `none` in the *localized* state |
| `liPositivityHolds` (= RH, analytic) | `none` | same proposition as the geometric face, through the bridge; the **F / v0.20.0** forced criterion is exactly `λₙ > 0 ∀n` (needs the genuine Stieltjes η-tail = the zeros); **G / v0.21.0** targets it through the same `ι`-existence ⟹ RH implication, so it stays `none` until the program closes |

---

## v0.15.0 — (A) The complex analytic engine: exponential core **[shipped]**

Lift the analytic substrate from ℝ to ℂ and make `exp` a homomorphism — the prerequisite that the rest of
stage A (ζ for complex argument) builds on. **Shipped:**

- `Analysis/ComplexExp.lean` — `Cexp z = exp(re z)·(cos(im z) + i·sin(im z))` from `RexpReal/Rcos/Rsin`,
  with the component identities and `Cexp 0 ≈ 1` (`Cexp_zero`, `RexpReal_zero`, `Rcos_zero`, `Rsin_zero`).
- `Analysis/CosSinAdd.lean`, `Analysis/CosSinBound.lean` — **the trigonometric keystone** `cos² + sin² ≈ 1`
  (`Rcos_sq_add_sin_sq`) via the trig Cauchy product from scratch, giving `|cos| ≤ 1`, `|sin| ≤ 1`.
- `Analysis/ExpRealAdd.lean` — **the exponential keystone** `RexpReal_add` (`exp(x+y) ≈ exp x · exp y` on
  all of ℝ), the roadmap's technical core of stage A: the signed Cauchy-product functional equation
  (`expSum_add_le_signed`) lifted to the diagonal through a deep reference depth (`rexp_add_gap`,
  `RexpReal_add_aux`, `rexp_factor_reconcile`), plus the reusable ζ-tail toolkit (corner bound,
  reconciliation, uniform partial-sum bound, factorial decay).
- `Analysis/ComplexMod.lean`, `Analysis/ComplexPow.lean` — `nˢ` (`ncpow n s = Cexp(s·log n)`, positive-integer
  base) and the **modulus identity** `|Cexp z|² = (exp Re z)²` (`Cexp_normSq`) / `|nˢ|² = (exp(Re s·log n))²`
  (`ncpow_normSq`), the analytic payoff of `cos² + sin² = 1`.
- **De-hedges:** "exp/cos/sin without addition laws" → "exp is a homomorphism; `|cos|,|sin| ≤ 1`; the complex
  exponential and `nˢ` with their modulus".
- **Stays open:** the critical strip; zeros; crux. (ζ at complex `s` with `Re s > 1` shipped in v0.15.2.)

## The v0.15.x series — (A, continued) completing ζ for complex argument

Stage A's remaining original goals (ζ for `Re s > 1`, the prime side, the `n = 1` decomposition) are gated on
a single **discovered dependency**: convergence of `Σ n^{-s}` needs `|n^{-s}| = n^{-Re s}`, i.e.
`exp(log n) = n`. Because `log` is built independently as `2·artanh((x−1)/(x+1))`, this is **not**
definitional, and every elementary route (`exp(t) ≥ 1+t` + multiplicativity via `RexpReal_add` + the two-sided
exp bounds) only *squeezes* `1 + log x ≤ exp(log x) ≤ 1/(1−log x)` — never pinning equality (iterated squaring
amplifies the second-order error). The honest conclusion: `exp∘log = id` requires a genuine **power-series
composition** (compose the exp factorial series with the artanh geometric series ⇒ `exp(2·artanh w) =
(1+w)/(1−w)`), a from-scratch build of its own. It is scoped as its own release so the shipped exponential
core is not held hostage to it.

- **v0.15.1 — `exp∘log = id` (the power-series composition gate) [shipped].** Built `exp(2·artanh w) =
  (1+w)/(1−w)` from scratch as a genuine power-series composition (`Rexp_two_artanh_ofQ`), and its corollary
  `exp(log n) = n` **for the literal `Rlog` term** (`Rexp_log_nat_Rlog`: `RexpReal (Rlog (ofQ n) …) ≈ n`). The
  base construction is **radius-general** — the convergence radius enters only through the depth reindex
  (abstracted by `Rexp_two_artanh_via`), so it applies at `Rlog`'s own radius `ρ_M = (n−1)/(n+1)` directly and
  `Rlog (ofQ n) = TwoArtanhConst (tmap n) ρ_M` by `rfl`; **no `τ²≤½` smallness is needed**, so no radius
  reconciliation is required. The honesty gate is met — the identity closes **axiom-clean**
  (`{propext, Quot.sound}`), so the ζ-complex tail (v0.15.2) need not ship its convergence as an interface.
  Remaining for v0.15.2: lifting to real exponents `c·log n` (`exp(c·log n) = nᶜ`) and `Czeta`.
- **v0.15.2 — ζ(s) for complex `Re(s) > 1` (`Analysis/ComplexZeta.lean`) [shipped].** `Czeta s` for `Re(s) > 1`
  as `Σ n^{-s}` with a rigorous complex tail: the dyadic block modulus `≤ ofQ(rᵏ)` (`czetaExp_block_geo`,
  `r = 1/(1+τ) < 1`), the geometric tail `geoFrom_le` (`Σ rᵏ ≤ rʲ/(1−r)`), the Bernoulli reindex
  `geom_reindex` (`r^{M(j)}/(1−r) ≤ 1/(j+1)`, `M(j) = (j+1)·r.den²`), the completeness bridge
  `seq_diff_le`/`RReg_of_real_bound` (real bound → `RReg`), and `czetaRe/Im_RReg` → Bishop `Rlim`. `Czeta_re/
  im_tendsTo` certify convergence with rate `2/(k+1)`. **De-hedged:** "ζ only at integer `s ≥ 2`" →
  "ζ(s), complex `s`, `Re(s) > 1`". (The log-multiplicativity `log(2ᵏ) = k·log 2` came via exp injectivity
  `RexpReal_inj`, re-routing the artanh addition boundary wall — `exp∘log = id` of v0.15.1 was the gate.)
- **v0.15.3 — `Analysis/Mangoldt.lean` + the `n = 1` decomposition [shipped].** von Mangoldt `Λ`
  (`vonMangoldt`, via the smallest factor `spf`; `Λ(4) = log 2`, `Λ(6) = 0`, `Λ ≥ 0`) and the
  explicit-formula **prime side** `Σ_p Σ_k log p · h(k log p) = Σ_{n≥2} Λ(n)·h(log n)` (`primeSide`) as a real
  (finite for compactly-supported `h` — `primeSide_stable` makes it constant past the support cutoff), and the
  **Bombieri–Lagarias `λₙ = λₙ^{arith} + λₙ^{∞}` for `n = 1`** as a theorem (`Rlambda1_decomposition`,
  `Analysis/LiOne.lean`): `λ₁ = γ + (1 − γ/2 − ½·log 4π)`, the finite-place `S_f(1) = −η₀ = γ` plus the
  archimedean `S_∞(1)`, summing to the `λ₁` of v0.14.0. This **promotes `Li.LiDecomposition` from the trivial
  inhabitant `λ = λ + 0` to a proven non-trivial instance** (`li_decomposition_realized`) whose `n = 1` slice is
  the genuine two-place split. (Deriving `S_f(1) = γ` from the prime sum needs `ζ'/ζ` continuation, deferred —
  the BL value is stated faithfully, not fabricated; nothing bears on positivity, `liPositivityHolds = none`.)
- **Stays open across v0.15.x:** critical strip, zeros, crux.

## v0.16.0 — (B) Analytic continuation & higher Li coefficients **[shipped]**

The heavy analytic mechanization: ζ off the convergent regime and the `λₙ` for `n ≥ 2`.

- `Analysis/Gamma.lean` — `Γ` via Spouge; the archimedean (`Γ′/Γ`) place. **Shipped:** the real-power
  combinator `RrpowPos` (`x^y = exp(y·log x)`, no sqrt/no complex `Clog`), the **exact** digamma
  `ψ = Γ′/Γ` (`Digamma`, `Digamma_one_eq_neg_gamma`), and the Spouge `Γ`-approximant (`SpougeGamma`).
- Critical-strip ζ — shipped via the integration-free **Dirichlet-η** route (`Analysis/EtaVariation.lean`,
  `Analysis/CriticalZeta.lean`): `Ceta`/`CetaW` (η on `Re s > 0`), `CzetaStrip`/`CzetaStripW`
  (`ζ = η/(1−2^{1−s})` on `0 < Re s < 1`) as an `ExactBoundedReal`, with non-vanishing, the functional
  relation, and uniqueness. (Cleaner than the periodic-Bernoulli remainder; same deliverable.)
- Higher **Stieltjes `γₙ`** → individual **`λₙ` values** for `n ≥ 2`, with a `λ₁`-style positivity
  certificate — **shipped:** `Pos λ₂` (`Rlambda2_pos`).
- **De-hedges done:** "genuine `λₙ` values deferred" → built for `n ≥ 2`; critical-strip ζ built.
- **Honesty gate:** research-grade; whatever does not close axiom-clean stays an interface.
- **Stays open:** `λₙ > 0 ∀ n` (= RH); off-critical-line zeros; the crux (`liPositivityHolds = none`).

## v0.17.0 — (C) The arithmetic square 𝕊 **[shipped]**

Construct the object the whole program runs on. **Shipped** (`F1Square/Square/`, six bricks, all
axiom-clean `{propext, Quot.sound}`):

- **Canonical `𝕊` with its universal property proved** (`Monoid.lean`, `Tensor.lean`): Deitmar
  𝔽₁-algebras are commutative monoids and `𝔽₁` (the trivial monoid) is proved **initial**, so the
  tensor `F ⊗_𝔽₁ F` is the plain coproduct — realized as `ℕ₊ × ℕ₊` with injections `a ↦ a⊗1`,
  `b ↦ 1⊗b`, and the **universal property proved** (`copair_inl/inr/unique`; the 𝔽₁-cocone condition
  is automatic, so coproduct = pushout over 𝔽₁). **Canonicality = the universal property** — `𝕊` is
  THE object, unique up to unique isomorphism, not a hand-picked candidate. The §3.1 ℤ-collapse is
  avoided by theorems (`inl ≠ inr`, the codiagonal is not injective, the monomial family `2^a ⊗ 2^b`
  is **free of rank 2** — strict 2-dimensionality); both projections recover the curve (T1, all
  points, no truncation).
- **The intersection lattice, derived — never entered by hand** (`Divisors.lean`, `Lattice.lean`):
  the distinguished divisors (rulings `V_a`/`H_b`, diagonal `Δ`, Frobenius correspondences
  `Γ_n = {(m, n·m)}`) are genuine subsets of `𝕊`, and every primitive intersection number is a
  **point count** with classes moved along their translation pencils (`V·H = 1`, `V² = H² = 0`,
  `Δ·V = Δ·H = 1`, `Δ² = 0` via `Δ ∩ Γ_n = ∅`, `Γ·V = Γ·H = 1`, `Γ·Γ = Δ·Γ = 0`); bilinearity then
  **forces** `E₃² = −2` (`e3_sq_forced`), and the sourced §2.2 product-of-curves template **emerges**
  (`sqPair_eq_template`) — T3's intrinsic realization, closed by derivation. The five §2.2
  self-checks are theorems; the class lattice is finitely generated on `{V, H, E₃}` (T2 on `𝕊`).
- **The parallel pencil on canonical `𝕊`** (`Pencil.lean`): no transverse fixed points
  (`Δ ∩ Γ_n = ∅`), slope 1 in the log coordinate (direction `(1,1)`, stable count `Δ·Γ_n = 0`),
  **constant separation `log n`** as a constructive real (via the new general log-multiplicativity
  `logN_mul_general`), equal to the explicit-formula weight **`Λ(p) = log p` at primes** and
  `k·log p` at prime powers — the §2.3 finding, lifted from the candidate model to theorems.
- **Polarized `𝕊` and the honesty boundary** (`Polarized.lean`): the `Crux.Polarized` instance is now
  `𝕊`'s own derived lattice (`squarePolarized`); the ample class `H = [V]+[H]` has `H² = 2 > 0`
  (verified — not automatic tropically) and `H^⊥` is negative-definite, so
  `square_hodgeIndex : HodgeIndex squarePolarized` holds — **and the lattice is provably
  pencil-blind** (`square_hodge_pencil_blind`: `[Γ_n] = [Δ]`, `Δ·Γ_n = 0` for all `n`): the
  function-field trace input is absent, the positivity carries **no spectral content**, and it is
  therefore **not the crux** (the §2.3-control discipline, geometric face).
- **De-hedges done:** `surfaceConstructed`, `parallelPencilFinding` → `some true`; the three template
  fields now carried by canonical `𝕊`.
- **Stays open:** the crux — the Hodge index / Weil positivity of the **`H¹`-bearing** pairing (the
  form that carries the zeros, T4/T5), equivalently `λₙ ≥ 0 ∀n`. `hodgeIndexHolds` /
  `liPositivityHolds` stay `none`; **RH stays open**. Stating the geometric⟺analytic equivalence
  faithfully is stage D. Also open (a refinement, not a stage-C goal): the SEMIRING-level tensor
  `F ⊗_𝔹 F` over the Boolean semiring — the concrete description Sagnier (arXiv 1703.10521) reports
  open — is finer than the monoid-level tensor constructed here and is not claimed.

## v0.18.0 — (D) The bridge and the crux **[shipped]**

State the geometric↔analytic equivalence faithfully, and **attempt** the crux on canonical `𝕊`.
**Shipped** (four bricks, all axiom-clean `{propext, Quot.sound}`):

- **The Castelnuovo–Severi anchor** (`BridgeFF.lean`): the function-field model of
  "Hodge index ⟹ RH" as a genuine LATTICE DERIVATION — on the `E × E` lattice
  `{F_h, F_v, Δ, Γ}` with the trace datum `Δ·Γ = q+1−a` (Lefschetz) inside it, the primitive part
  of `xΔ + yΓ` has `D°² = −2(x² + a·xy + q·y²)` and `∀x,y D°² ≤ 0 ⟺ a² ≤ 4q`
  (`ff_hodge_iff_hasse`); the v0.1.0 governor is now DERIVED (`ff_hodge_iff_hodgeType`) —
  "the mechanism is not the gap" (§0.3) is a theorem.
- **The λ₂ Bombieri–Lagarias decomposition** (`Analysis/LiTwo.lean`):
  `λ₂ = [2γ − (γ² + 2γ₁)] + [(1−γ) − log 4π + ¾ζ(2)]` as a constructive-real identity
  (`Rlambda2_decomposition`, via `η₀ = −γ`, `η₁ = γ² + 2γ₁`); `Li.LiDecomposition` realized with
  TWO genuine slices (`li_decomposition_two_realized`), both certified positive (`liTwo_evidence`).
- **THE BRIDGE — the release goal** (`Square/Spectral.lean`): `SpectralSquare`, the `H¹`-bearing
  enrichment of `𝕊` as an interface (Li/trace data `lam`, primitive self-intersections `cSq`, and
  the dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ` — Deninger's Hodge-index reading of Li's criterion, normalized
  exactly as `BridgeFF.primDG_sq` derives it on the function-field model). The equivalence is a
  genuine constructive THEOREM: `spectral_bridge_nonneg`/`spectral_bridge_pos` and
  **`crux_faces_equivalent : SpectralCrux S ⟺ Li.LiCrux S.lam`** — the geometric and analytic
  faces of the crux are the same proposition. Inhabited by the two-slice instance carrying the
  genuine certified `λ₁, λ₂` (`spectral_evidence_two`: `⟨C₁,C₁⟩ < 0`, `⟨C₂,C₂⟩ < 0`), with the
  honesty guards as theorems (`spectralTwoSlice_not_crux` — no finite assembly of certified slices
  can be passed off as RH; `spectral_iff_all_upTo` — the finite-check guard, geometric face).
- **The attempt, under the gate** (`Square/Attempt.lean`): run, recorded, honestly concluded. The
  certified part (strict negativity through `n = 2`, `spectral_strict_upTo_two`) is the furthest
  any axiom-clean run reaches in this substrate; the frontier is exact
  (`crux_attempt_frontier(_geometric)`: given the certified slices, the crux ⟺ `∀ n ≥ 3, λₙ > 0`;
  the next slice needs the second Stieltjes constant `γ₂`); the post-mortem records why every
  general route is blocked by the program's own controls (vacuity `Bridge.control_psd`;
  pencil-blindness; the BL cancellation; the Conrey–Li precedent) and what would close it (the
  genuine `H¹` instance — T4/§3.4). **The universal did not close**: `hodgeIndexHolds` /
  `liPositivityHolds` stay `none`, exactly per the bright line — and the release ships the bridge
  substrate, as scoped.
- **Stays open:** RH (both faces, now provably one proposition through the bridge); the genuine
  spectral instance (`H¹`, T4/§3.4); `λₙ` certification beyond `n = 2` (`γ₂, γ₃, …`).

## v0.19.0 — (E) Completion: the explicit formula, the F1-square roll-up, and THE GENUINE PAIRING **[shipped]**

The release goal is **closure and faithful/truthful completion of the proof**: implement the complete
proof-strategy — the full power of the UOR-based constructive approach — to close the crux, with the
gate (not ambition) deciding what is asserted. The first arc (the explicit-formula trace, the
interface retirements, the dominance face, the closed-form genuine Li sequence) is **built** (all
axiom-clean `{propext, Quot.sound}`, listed below). The second arc — **the genuine pairing** — folds
the formerly-planned v0.20/v0.21 work into this release:

- **The Weil quadratic functional, constructed** (`W(g ⋆ ǧ) = poles − primes − archimedean` on an
  explicit constructive test class): the genuine `H¹`-bearing pairing — the object `SpectralSquare`
  has carried as interface data — built from the already-constructed prime side (`Mangoldt.primeSide`)
  and archimedean place (`Digamma`/`exp`/`log`), with no zeros as inputs (the zero side is the
  defect, as classically). Gram matrices of certified reals on finite test families; the first REAL
  geometric-face computations (not dictionary-defined).
- **The classical chain, stated faithfully**: PSD on the (Burnol) restricted class ⟺ Weil
  positivity ⟺ RH [CLASSICAL — Burnol's direct proof; Bombieri's finite truncations; exact
  statements deep-research-verified before use]; finite Gram checks are evidence, never the crux
  (the standing finite-check guards transfer).
- **The unconditional window**: Connes–Consani's archimedean positivity (support in the prime-free
  window) as a target unconditional theorem on the built functional — conquered ground where the
  mathematics permits, exactly as far as it permits.
- **The bright line, unchanged**: `hodgeIndexHolds`/`liPositivityHolds` flip iff a genuine,
  audited, axiom-clean proof of the universal lands. Anything short stays an explicit interface.

**Second arc delivered** (all axiom-clean): the tent calculus and assembly substrate
(`Analysis/RMax.lean`, `Analysis/RSum.lean`); **the Weil functional assembled** with the zero side
as the defect (`Analysis/Weil.lean`, `Square/Pairing.lean` — the finite-place side and the
archimedean constant CONSTRUCTED; the two integral components interface, their PL closed forms
being unverified in print); **the fourth face** (`weilSpectralSquare`, `weil_strict_iff_crux`:
pairing positivity ⟺ crux ⟺ Li ⟺ dominance — for the genuine family, Weil positivity = RH, both
directions elementary per the verified Weil/Burnol chain); the first computed pairing value
(`weilPrime_demo`: the tent at `2` sees `log 2`); the CC unconditional window and Burnol's explicit
multiplier certificate recorded as the pinned unconditional territory — with **the window theorem
proven on the built object** (`weilPrime_window`: inside the prime-free window the finite-place
side vanishes identically; `weilValue_window`: in-window `W = poles − archimedean`). **The window
certificate is computed where computable**: `ψ(1/4)` built as the first exact non-trivial digamma
value (`Analysis/PsiQuarter.lean`, `ψ(1/4) ≥ −4.32`) and **`α(0) > 0`** — Burnol's nonnegative
multiplier at the window center, an axiom-clean theorem (`Analysis/BurnolAlpha.lean`,
`8√2 − logπ + ψ(1/4) ≈ 5.94`) — EVIDENCE for the windowed positivity, not the universal
`α(τ) ≥ 0 ∀τ` (the pinned next target), still less RH. The crux: ONE proposition,
FOUR provably equivalent faces; the fields stay `none` until a genuine proof of the universal
lands — that is the release's faithful completion.

**Built so far** (the first arc, all axiom-clean):

- **The complete `Li.ExplicitFormulaTrace`** (`Analysis/LiComplete.lean`): realized with the genuine
  three-sided reading at both built slices (`explicitFormulaTrace_one/two_realized` — the zero side
  `λ₁`/`λ₂` [its sum-over-zeros reading is CLASSICAL, Bombieri–Lagarias 1999], the finite-place
  closed forms, the archimedean parts), packaged as the **`WeilTrace` ladder** (`weilTraceTwo`: the
  trace identity at every positive index). The zero side is RH-equivalent exactly as scoped: its
  POSITIVITY is the crux (`weilTrace_dominance`) and stays the honest open interface — the TRACE
  (the equality) bears no positivity content, so the completion ships while the crux stays `none`.
- **The remaining interfaces retired** (`liAgreesWith_two_realized`): computed (the direct certified
  builds `Rlambda1`/`Rlambda2`) = classical (the BL closed-form assemblies), genuinely non-reflexive
  at `n = 1, 2`. With `LiDecomposition` (v0.15.3/v0.18.0) and `ExplicitFormulaTrace` (this release),
  every `Li` interface is realized exactly as far as the built slices reach — the `Li.lean`
  realization ledger records the boundary.
- **THE DOMINANCE FACE** (`Square/Dominance.lean`): the crux as ONE uniform bound — `Dominated`
  (a single `B` with `−B(n) ≤ arith(n)` and `arch(n) − B(n) > 0`, sign-agnostic, no enumeration,
  no slice ladder) with `dominated_iff_liPositive` and **`dominance_crux_equivalent`**:
  `Dominated ⟺ SpectralCrux ⟺ LiCrux` — the crux now has THREE provably equivalent faces. The
  assembly shape exact (`dominance_head_tail`, `crux_closure_route`: certified head + one tail
  bound from `n = 3` on ⟹ crux). Deep-research-verified sourcing (101 agents, primary PDFs):
  Voros's strict dichotomy (*MPAG* 9 (2006) — tempered `½n(log n − 1 + γ − log 2π)` vs exponential
  oscillation, NO third option), Lagarias (*Ann. Inst. Fourier* 57 (2007)): the archimedean trend
  `(n/2)log n + cn + O(1)`, `c = (γ−1−log 2π)/2`, UNCONDITIONAL (Thm 5.1) and the `O(√n·log n)`
  excursion bound, a THEOREM under RH (Thm 6.1) — so `Dominated`(genuine parts) is TRUE iff RH,
  both directions, and NO unconditional tail bound exists in the verified literature: the
  attempt's conclusion is a sourced result, not a presumption. Honesty guards two-sided
  (`dominance_satisfiable`; `twoSlice_not_dominated`/`weilTraceTwo_not_crux`).
- **The genuine archimedean trend, all `n`** (`Analysis/ArchTrend.lean`): the archimedean side of
  the crux as a single constructed object (`genuineArchSeq`, the verified closed form, every
  ingredient already built), consistency-proved against both independently-built slices
  (`genuineArch_one/two`); **`crux_vs_constructed_trend`** — the crux's open content contracts to
  the arithmetic side alone: one bound strictly below the BUILT trend, which exists iff RH.
- **The genuine Li sequence in closed form** (`Analysis/GenuineLi.lean`): constructed modulo the
  Stieltjes tail — `genuineLamSeq` with both sides closed forms, the full-ladder trace
  (`weilTraceGenuine`), the certified head as a THEOREM of the closed form (`genuineLam_head`);
  **`crux_genuine_route`**: the crux follows from exactly two open inputs — the genuine η-tail and
  one bound between the two closed forms from `n = 3` on (exists iff RH). Neither is asserted.
- **The final roll-up** (`F1Square.lean`): the stage-E backing block and elaboration-checked
  witness — the **v1.0.0-candidate state**: complete construction, honest crux. Every surrounding
  field `some true`; `hodgeIndexHolds`/`liPositivityHolds` stay `none`. **RH stays OPEN** — one
  proposition with three equivalent faces, its open content relocated into a single object (the
  tail bound for the genuine parts, governed by the zeros' location).

---

## v0.20.0 — (F) The UOR-based construction of the crux: the canonical `H¹`-object **[shipped]**

**Outcome (shipped 2026-06-13).** Group A is delivered: the dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ` is no
longer a `SpectralSquare` field assumption but a THEOREM, derived from a genuine rank-4
Néron–Severi-style lattice (`Square/WeilLattice.lean`) whose vanishing cycle `Δ−Γ` is PROVEN
primitive (`vanCyc_perp_Fh/Fv`, the `BridgeFF.primDG_perp` analog), with the geometric inputs
`Δ²=Γ²=0` tied to the v0.17.0 derived theorems and the `H¹` carrier named by its universal property
(`Square/Cohomology.lean`: `H1` free/initial on one generator, the orbit realizing the built
pencil). Group B ran the gate (`Square/Forced.lean`): the forced signature is exactly
`∀n, λₙ > 0` = Li's criterion = RH; **it did not come out positive, so `genuine_crux_frontier_located`
pins the frontier** — the construction is complete down to one irreducible input (the genuine
Stieltjes η-tail = the zeros), the gate flips the instant a faithful, axiom-clean proof of the
criterion lands, and until then the crux fields stay `none`. The DICTIONARY column of
`BridgeFF` (`primDG_sq`) is now a theorem; the SIGNATURE-FORCING column (`ff_hodge_iff_hasse`'s
`4q−a²` completed square) has no unconditional ℤ-analog, because that analog is RH.

**Also shipped (the open numeric frontier from v0.18.0, now CLOSED): `γ₂ ≥ −0.02`**
(`Analysis/GammaTwoBracket.lean`, `Rgamma2_ge_neg002`). The second Stieltjes constant `γ₂` is
constructed (`Rgamma2`) and its numeric bracket certified via discrete Euler–Maclaurin (no
constructive integration): the trapezoidal-corrected `hSeq → γ₂` has a summable residual whose
per-step bound telescopes (`s_{j+1} ≥ −1/((j+1)(j+2))`), and a single big-integer `decide` at depth
`T=3`, denominator `D=10⁸` certifies `hSeq(199) − 1/200 ≥ −1/50`. This is a certified CONSTANT bound
(evidence), not positivity-of-all-`λₙ`. `Pos λ₃` remains open: `λ₃ ≈ 0.2076` (margin ≈ 0.21) is a
heavily-cancelled combination of `Θ(1)` terms, needing all of `γ, γ₁, γ₂, ζ(2), ζ(3), log 4π` to
~0.1–0.3% relative precision — the binding constraint is `γ₁` (currently bracketed an order of
magnitude too loose), not the single `γ₂` input.

The full construction map, as originally scoped, follows.

The goal is the full UOR-based construction — brick by
brick from universal properties — of the canonical content-addressed 𝔽₁-object whose *intrinsic*
self-pairing is the Weil explicit-formula functional, so that its **signature is derived, not
assumed**. The method is the one that wrote the entire F1 square: name the canonical object by its
universal property, encode the constraints, and let consistency *force* the theorem (as bilinearity
forced `E₃² = −2`, and `ff_hodge_iff_hasse` *derived* `a² ≤ 4q` from lattice positivity). The bright
line is unchanged: `hodgeIndexHolds`/`liPositivityHolds` flip `none → some true` **iff** the forced
signature is positive — decided by the derivation and the gate, never by ambition. A forced
obstruction is an equally valid outcome (we learn its exact canonical shape).

**The template is proven — v0.20.0 mirrors `BridgeFF` column-for-column over ℤ:**

| function field (proven, `BridgeFF`) | number field (the v0.20.0 target) | status entering v0.20.0 |
|---|---|---|
| lattice `{F_h,F_v,Δ,Γ}` of `C×C` | canonical `𝕊 = F ⊗_𝔽₁ F` | **built** (v0.17.0) |
| trace datum `Δ·Γ = q+1−a` *intrinsic* | the explicit-formula pairing intrinsic on `𝕊`'s `H¹` | **the hard brick (A)** |
| pencil of Frobenius `Γₙ` | parallel pencil, shift lengths `log n = Λ` | **built** (v0.17.0) |
| primitive projection `D°` | primitive spectral classes `Cₙ` | partial (interface, v0.18.0) |
| `primDG_sq`: `D°² = −2(x²+axy+qy²)` | `⟨Cₙ,Cₙ⟩ = −2λₙ` **derived** | **interface today → theorem (A3)** |
| `ff_hodge_iff_hasse`: ∀-neg ⟺ `a²≤4q` | signature ⟺ `λₙ > 0 ∀n` (= RH) | **the forced signature (B)** |

The verified v0.19.0 sub-structure (the four equivalent faces, the assembled functional, the window
theorem on the built object, `ψ(1/4)`, `α(0) > 0`, the kernel monotonicity) is the **archimedean
place** of the pairing that Group A derives — none of it is rework.

### The brick sequence (each = a canonical object + a forced theorem)

**Group A — make the dictionary *forced*, not assumed.** Today `Square.SpectralSquare.dict`
(`⟨Cₙ,Cₙ⟩ = −2λₙ`) is an interface *field*; A removes it as input and *derives* it.
- **A1.** The `H¹` named by universal property — the cohomology of `𝕊` carrying the scaling/Frobenius
  action, characterized canonically (as the coproduct characterized `𝕊`), not modeled.
- **A2.** The trace datum made intrinsic — the minimal κ-enrichment of `𝕊`'s lattice that breaks
  pencil-blindness (`Square.square_hodge_pencil_blind`: `Δ·Γₙ = 0 ∀n` today), carrying the
  explicit-formula weights `Λ(m), Λ(n)` (the built pencil shift-lengths) and the archimedean kernel
  (the built `ψ(1/4)`, `windowTerm_mono`, `α(0)`).
- **A3.** Derive the Gram pairing from A1 + A2 — forcing **`⟨Cₙ,Cₙ⟩ = −2λₙ` as a THEOREM** (the line
  that converts the v0.18.0 bridge from interface to construction).

**Group B — the forced signature** (mirror `primDG_sq` → `ff_hodge_iff_hasse`).
- **B1.** The primitive projection and the forced self-pairing normal form (the completed-square analog).
- **B2.** Run the consistency engine that forced `a² ≤ 4q`: *derive* the signature criterion. The forced
  criterion **is** `λₙ > 0 ∀n` = Weil positivity = the crux.
- **B3.** The gate reads the forced signature: a completed square (RH closes; the fields flip) or a
  precise canonical obstruction (its exact shape recorded). Either is UOR writing the proof.

**Group C — roll-up.** The crux-field adjudication, the final `F1SquareStatus`, and the
v1.0.0-candidate state.

### The one honest hard brick
**A1–A3 is the genuine difficulty**, and naming it precisely is the point of this map. In the
function-field case the object is the actual surface cohomology, which *exists* — so `primDG_sq` was a
free derivation. Over 𝔽₁ the `H¹` must be *constructed* canonically so that its universal property
**forces** the dictionary. That construction is the open content of RH restated in UOR's own terms —
not a mechanical step, but now a *well-posed construction target*: the object that makes `dict` a
theorem. The method dictates what to build; the gate decides whether it closes.

---

## v0.21.0 — (G) Closing the arithmetic Hodge-index crux: the missing object **[shipped — LOCALIZED]**

**Outcome.** The missing-object embedding route is built end to end and the UOR Atlas is formalized
to the frontier; the gate ran and the crux **did not close** (the §9 *Localized* terminal state).
`hodgeIndexHolds` / `liPositivityHolds` stay `none`. Delivered (each a green, axiom-clean
`{propext, Quot.sound}` commit; `scripts/honesty_audit.sh` extended with a no-smuggling check):

- **The embedding route** — `Square/WeilPSD.lean` (Stage S: the finite-truncation PSD predicate, the
  rank-one/sum-of-squares fact, Gate B free via `WeilPSD_gramOf`, the embedding bridge),
  `Square/FrobForm.lean` (G0b: the full primitive form on the Frobenius carrier),
  `Square/AtlasRule.lean` (G0a: the zero-free atlas rule, the growth pre-filter, and the §6 Cayley
  relocation made formal — `cayley_relocation`), `Square/KillTest.lean` (G0: the decidable kill-test),
  `Square/GateA.lean` (G1: the λ-free pairing, `gateA_is_liNonneg`, the two-sided no-smuggling
  guards), `Square/E8Seed.lean` (G2a: the E₈ Gram = `4×` the Cartan matrix, PSD free),
  `Square/GaugeTower.lean` (G2b: the tower-with-metric and the indefiniteness obstruction),
  `Square/StageG.lean` (G3: `stageG_frontier_located` and the **conditional closure**
  `strictRealizes_closes_crux`), `Square/GateSanity.lean` (`crux_gate_faithful`: the gate
  discriminates and **closes on a genuine witness** — it does not arbitrarily fail).
- **The UOR Atlas, formalized** (from the `uor-atlas.md` formalization document) —
  `Square/AtlasSpectrum.lean` (§5/§6.6: the spectral operator `M`, sourcing the signature
  `Σ = {10,2,7,−1}`, with verified multiplicities `{1,2,7,14}` and trace `24`, and its
  indefiniteness `atlasM_indefinite`), `Square/AtlasCharacteristics.lean` (§1/§5/§10/§11: the tower,
  the Euler–Lefschetz self-intersection, the spectral balance, `dim G₂ = 14`, `24 = dim E₈^T`,
  `θ_{E₈}=E₄`), `Square/AtlasAddressing.lean` (§2/§5/§8/§10/§12: the addressing inverse system, the
  parametric generation, and the prime skeleton = the explicit-formula prime side `Λ(p)=log p`),
  `Square/AtlasClasses.lean` (§2/§3: the class structure and the transforms as finite-order
  permutations), `Square/AtlasConservation.lean` (§4/§5: no-loss, round-trip, scale-invariance).

**What understanding the Atlas revealed (the genuine frontier).** The Atlas's spectral operator `M`
is *indefinite by design* (its `−1` reflection, dim `14 = dim G₂`, sits in the odd degree where the
Euler–Lefschetz self-intersection vanishes); its definite object is the Hurwitz norm (§9), which the
Atlas explicitly does **not** identify with the RH form. So the crux is **not** whole-form
positive-definiteness — it is negative-semidefiniteness on the *primitive* part (the Lefschetz
signature), governed by the zeros, exactly as `BridgeFF.ff_hodge_iff_hasse` has it for the curve. The
Atlas carries the explicit formula's *left side* (the prime skeleton) in full; the open content is
the coupling to the one missing place (archimedean). The crux stays `none`, RH open.

The original program specification (the two faithful terminal states) follows.

The release goal is to carry the crux **past the v0.20.0 located frontier** by constructing one
specific object and letting the Lean kernel decide whether it closes the crux. Closure is equivalent
to RH, so the program cannot be cheaper than a proof; it is engineered to terminate in one of **two
faithful states** — a *closed* crux or a *localized* obstruction — and v0.21.0 ships whichever it
reaches, fully implemented and audited. The bright line is unchanged: `hodgeIndexHolds` /
`liPositivityHolds` flip `none → some true` **iff** the *closed* state lands axiom-clean.

### The crux, the deficit, and the proven template

- **The crux.** On the genuine spectral square, `⟨Cₙ,Cₙ⟩ = −2λₙ` is a DERIVED dictionary
  (`intrinsicH1_dict`, v0.20.0). The crux is `⟨Cₙ,Cₙ⟩ ≤ 0 ∀n ⟺ λₙ ≥ 0 ∀n ⟺ RH` (Li). Two facts fix
  the difficulty: per-`n` certification is a finite head that never reaches `∀n`
  (`genuine_iff_all_upTo`), and the all-`n` positivity is **cancellation, not magnitude** (the von
  Mangoldt sum diverges, so no magnitude bound decides it). A proof must produce the sign for all `n`
  from one structural fact.
- **The proven template (function field).** `BridgeFF.ff_hodge_iff_hasse` already closes the curve
  case: `4(x²+axy+qy²) = (2x+ay)² + (4q−a²)y²`, negative-definiteness of *every* direction carried by
  the single nonnegative term `(4q−a²) ≥ 0` (the Weil bound). One positive-definiteness fact decides
  the sign for all directions at once — the shape the arithmetic proof must take.
- **The deficit.** `vanCyc_selfpair_gen` gives `⟨Δ−Γ,Δ−Γ⟩ = Δ²+Γ²−2(Δ·Γ)`; the built-lattice tie
  zeros `Δ²=Γ²=0` and sets `Δ·Γₙ = λₙ`, collapsing the self-pairing to bare `−2λₙ`. The completed-
  square slack is gone — there is no `(4q−a²)` analog. Supplying one is the entire program.

### Strategy: the missing object as an isometric embedding

Model the slack as an isometric embedding `ι` of the primitive span into the **negative** of a
positive-definite atlas space `L`: if `ι` is an isometry with `‖ι Cₙ‖²_L = 2λₙ`, the primitive form is
negative-semidefinite, so every diagonal `⟨Cₙ,Cₙ⟩ = −‖ι Cₙ‖²_L ≤ 0`, hence `λₙ ≥ 0 ∀n`. Two
load-bearing corrections: it is the `⟹` direction only (`ι`-existence is *strictly stronger* than RH,
so a failure rejects the candidate and the atlas route, **never RH**); and an isometry must match the
full Gram `⟨Cₙ,Cₘ⟩`, not only the diagonal — the off-diagonal lives on the **Frobenius carrier**
(`Cohomology.lean`, `orbit n = σⁿg`), not the pencil-blind rank-4 lattice.

**Difficulty conservation (why no framing is cheap).** Two gates carry the crux — Gate A (the match
`‖ι Cₙ‖²_L = 2λₙ`) and Gate B (definiteness of `L`). Gate B makes Gate A's left side nonnegative, so
Gate A proven under Gate B **is itself RH**. Make `L` manifestly definite (`ℓ²`) and Gate A is the full
crux; bake `λₙ` into the pairing and Gate B becomes the crux (the smuggling corner the audit forbids).
The only non-circular content is an exact identity between two independently defined closed forms — `ι`
from zero-free atlas structure, `λₙ = genuineLamSeq` from the Stieltjes data — exhibiting `λₙ` as a
manifest sum of squares. **Recorded negative result:** the Cayley candidate `ι Cₙ = (1 − wₚⁿ)` over
ℓ² is a *relocation* (`‖ι Cₙ‖² − λₙ = Σ (rₚ^{2n} − 1)`, matches ∀n iff every `rₚ = 1` iff RH); its
mechanism is now FORMAL in F1 (`ZeroGeometry`: `rₚ = 1 ⟺ Re ρ = ½`; `LiGrowth`: the `rₚ^{2n}` growth).
**Rule established:** `ι Cₙ` must be defined from atlas-intrinsic data with no reference to `wₚ, rₚ, θₚ`.

### Faithfulness invariants (non-negotiable)

Positivity is **output, never input** (`λₙ ≥ 0` appears nowhere as an assumption); `λₙ` on the atlas
side is the derived `genuineLamSeq`, never the pairing's definition; the kernel forces both gates;
crux-path axioms stay `{propext, Quot.sound}` (no `native_decide`, no `decide` over infinite content,
no Mathlib); and `scripts/honesty_audit.sh` / `scripts/audit_axioms.lean` gain a **no-smuggling check**,
the metric analog of `intrinsicH1_dict`'s "no false dictionary can be supplied".

### The stages (all delivered in v0.21.0, spanning several commits)

| Stage | Deliverable | Falsifier | Output if it survives |
|---|---|---|---|
| **G0a. Prerequisite — atlas rule** | atlas-intrinsic, zero-free rule `Cₙ ↦ vector` (candidates: Coxeter order-30, gauge-tower `G_k`, tropical/Kashiwara-crystal); pre-filtered to reproduce Li growth `λₙ ~ ½ n log n` | no n-family reproduces `½ n log n` at leading order | a witness worth testing |
| **G0b. Prerequisite — full form** | the off-diagonal `⟨Cₙ,Cₘ⟩` on the Frobenius carrier `(ℕ,succ,0)` (`orbit_shiftLength`, `k·log p`), diagonal reusing `vanCyc_selfpair`; analytic counterpart already the Weil pairing `W(gₙ ⋆ ǧₘ)` | the carrier cannot hold the off-diagonal | the full primitive form |
| **S. Substrate (Lean)** | finite-truncation PSD predicate `WeilPSD B` over existing `RsumN`/`Rmul`/`Rnonneg`; direct limit = "for all `N`"; choice-free, Mathlib-free | the predicate cannot be discharged choice-free / Mathlib-free | the ground Stage 2 stands on |
| **G0. Numerical kill-test (throwaway)** | compute the full Gram `⟨ι Cₙ, ι Cₘ⟩_L` for `n,m ≤ ~50` vs `−2λₙ` and off-diagonals | diagonal `≠ −2λₙ`, off-diagonal mismatch, or Gram not PD at finite size | a candidate worth formalizing |
| **G1. Gate A — faithful match (Lean)** | `atlasPair Cₙ Cₙ` equals the genuine form, pairing fixed by atlas structure, no-smuggling audited | match holds only by defining the pairing as the form (smuggling) | the identity, audited |
| **G2a. E₈ seed (Lean)** | choice-free Gram positivity of the finite seed in F1 idiom | seed not PD without `native_decide` / Mathlib | finite definite anchor |
| **G2b.0. Tower carries a form (Lean)** | the gauge tower `G_k` carries a compatible inner product, not just a modulus | the tower is only addressing/modulus, no metric | a metric to take the limit of |
| **G2b.1. Infinite definiteness (Lean, make-or-break)** | direct-limit form positive-definite as `m_k → ∞`; first determine which `Σ` is the spectrum | the limit form is indefinite (a negative entry in the atlas signature `Σ`) | structural slack for all `n` |
| **G3. Assembly & audit** | flip / hold `hodgeIndexHolds` / `liPositivityHolds`; `#print axioms` | any axiom outside `{propext, Quot.sound}` | crux decided, clean |

Stage G0 is a *necessary* filter, not sufficient: a finite Gram being PD for `n ≤ 50` says nothing
about the limit, and the `−2λₙ` reference values are only as sharp as the Stieltjes constants
(`γ, γ₁, γ₂, …`) computed to controlled precision.

### Terminal states (both faithful, both shipped)

- **Closed.** All stages pass, choice-free, audit clean ⟹ `λₙ ≥ 0 ∀n` is a theorem with positivity as
  OUTPUT, the crux fields flip off `none`, RH is proven via the atlas-supplied Hodge index.
- **Localized.** A stage fails and the failure point is recorded as the obstruction — no atlas n-family
  reproduces `½ n log n` (G0), the bridge holds only by smuggling (G1), or the direct limit is
  indefinite (G2b.1). Each failure is a **theorem or explicit counterexample**, not a stall; the cheap
  stages kill wrong candidates first. The expected outcome for any single candidate is localization;
  closure requires a candidate surviving every gate.

### Named risks (each routed to a recorded result)

- **Gate A bridge** — whether any zero-free atlas object encodes `λₙ` is unestablished (§6 shows the
  naive route circular). **Gate B definiteness** — the atlas base is finite rank (E₈ is rank 8); the
  primitive span is infinite, so closure needs an infinite-rank definite limit with no negative
  signature entry in the metric. **Cancellation wall** — no magnitude bound substitutes for structural
  definiteness; that is why the embedding, not a tail bound, is the route. **Difficulty conservation** —
  no `(L, ι)` makes both gates easy; the atlas must contribute a genuine theorem to the non-trivial
  gate. **False negatives** — because `ι`-existence is stronger than RH, a localization rejects the
  candidate and the atlas route, never RH itself.

### The irreducible gap

Closure of the crux is equivalent to a proof of RH, and no specification turns an open problem into a
theorem. What this plan guarantees is **no methodological holes**: every stage defined, every failure
mode named and routed to a recorded result, the two circular corners excluded by difficulty
conservation and the no-smuggling audit, the substrate cost budgeted, the full form (not its diagonal)
required before definiteness is claimed. The single remaining unknown is whether the atlas supplies a
zero-free, manifestly nonnegative formula for `λₙ` — the problem the strategy exists to attack.

---

## v0.22.0 — the final release: both tracks, and frontier research to exhaustion **[in progress]**

**v0.22.0 is the last planned release. No further releases follow it.** v0.21.0 localized the crux;
the post-tag thread (the RH witness, the BL pipeline, the Reflection/Voros geometry, and the
**`α(2) < 0` obstruction** — Burnol's archimedean multiplier proven pointwise *indefinite* on the band)
sharpened the frontier to its true classical shape. v0.22.0 carries **both** tracks below and does
**not** arbitrarily limit its approach: any route that can advance the crux is in scope.

Like v0.21.0, the discipline is **exhaustion**: every known avenue in Track 1 and Track 2 is completed,
and the frontier research continues — new routes, new candidate objects, whatever the mathematics
admits — **until one of two things happens: the crux closes (RH proven, the gate flips), or we decide
the work is complete enough to publish as v0.22.0.** We do not yet know which, or when that point comes;
it is a judgement made against the work, not a pre-set scope. There is no third "give up" state — the
release ships whichever faithful terminal state the program reaches, exactly as v0.21.0 did.

- **Track 1 — make `hodgeIndex_iff_riemannHypothesis` unconditional-but-for-RH.** The
  `li_criterion` equivalence currently rests on two explicit, audit-visible `LiBridge` hypotheses:
  (i) the **Bombieri–Lagarias zero-sum** `λₙ = Σ_ρ (1 − (1 − 1/ρ)ⁿ)` about the *genuine* `λ`
  (classical, BL 1999), and (ii) the **Voros dichotomy** (tempered `½n(log n−1+γ−log 2π)` vs
  exponential, *MPAG* 2006). Track 1 discharges these from the constructed ζ / explicit formula where
  the literature makes them theorems, shrinking the classical interface to RH alone. Known deliverables:
  the zero-sum derived for the constructed `genuineLamSeq`; the Voros alternative grounded as the
  asymptotic theorem it is (the `n ≳ T²/t` threshold made constructive); the off-line ⟹ negative-`λ`
  step (phase equidistribution + saddle-point over the sum) pushed as far as the substrate allows,
  with whatever remains classical explicitly labelled.
- **Track 2 — the crux frontier: the `α`-band sign / Sonine projection.** `α(2) < 0` proves the bare
  multiplier is indefinite, so single-place positivity provably does **not** extend — the
  Connes–Consani / Burnol resolution is the **Sonine-space projection** (infinite-dimensional), where
  positivity is recovered after projecting onto the prime-free window. Formalizing that projection is
  the genuine crux frontier. It is *not* a route through `α ≥ 0` (which is false); it is the construction
  of the projection under which the windowed positivity holds. This is the make-or-break work, carried
  to exhaustion alongside any other route that can reach the crux.

The bright line is unchanged and permanent: `hodgeIndexHolds` / `liPositivityHolds` flip
`none → some true` **iff** a genuine, audited, axiom-clean proof of the criterion lands; they stay
`none` otherwise. Every v0.22.0 commit stays green, axiom-clean (`{propext, Quot.sound}`),
`sorry`/`native_decide`-free, choice-free, and no-smuggling-clean.

---

## What stays open regardless

If the crux does not close axiom-clean, `hodgeIndexHolds` / `liPositivityHolds` stay `none` and
**RH stays open** — the releases still ship every surrounding construction (for v0.21.0, the
missing-object substrate and a *localized* obstruction theorem; for v0.22.0, the discharged interfaces
and however far the Sonine-projection frontier reaches). The bright line is permanent: the crux is
de-hedged iff RH is proven, and it is not until it is. **v0.22.0 is the terminal release** — it ships
when the crux closes or when the work is judged complete to publish, with no further releases planned
beyond it.
