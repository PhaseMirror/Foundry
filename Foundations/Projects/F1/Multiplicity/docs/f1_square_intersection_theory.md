# The 𝔽₁ Square with an Intersection Theory

### A formalization scaffold for `Spec ℤ ×_{𝔽₁} Spec ℤ` — the missing surface whose intersection-positivity is RH

**Status and purpose.** This document formalizes the *target object* identified at the end of the
companion work (`characteristic_1_constructions.md` §9.1, `missing_object_over_Q.md`): the arithmetic
surface `Spec ℤ ×_{𝔽₁} Spec ℤ` equipped with an intersection pairing admitting a **Hodge index
theorem**. Its construction would close the surface-positivity gap — the positivity that, over
function fields, *is* the proof of RH (verified mechanism, §0.3). **The object is not constructed.**
This is a scaffold: it states with precision what the object must be, what is already established
around it (the verified `𝔽₁` *curve* and the verified positivity *mechanism*), what the literature's
candidate `𝔽₁`-geometries supply and lack, and the exact properties any successful construction must
satisfy. Each claim is tagged: **[VERIFIED]** (checked in our runtime), **[CLASSICAL]** (established
mathematics, cited), **[OPEN]** (the unbuilt target). The document does not claim to construct the
object; it formalizes the construction problem so that progress on it is precise and checkable.

---

## 0. What is already in hand (the boundary conditions of the construction)

The construction does not start from nothing. Four pieces are established, and they fix exactly what
the `𝔽₁` square must connect to.

**0.1 The base — characteristic 1.** [VERIFIED / CLASSICAL]
The base over which the square lives is the characteristic-1 (idempotent / max-plus) semiring
`ℝ_max = (ℝ∪{−∞}, max, +)`, `x⊕x=x`. This is the structure sheaf of the Connes–Consani arithmetic
site, and it is the verified base of our characteristic-1 stack (`characteristic_1_constructions.md`
R1–R16). The square must be a 2-dimensional object over this base.

**0.2 The curve — `Spec ℤ / 𝔽₁` — exists.** [CLASSICAL — Connes–Consani 2014–2021]
The 1-dimensional factor is built: the **arithmetic site**, a topos with the characteristic-1
structure sheaf, whose points over `ℝ_max` are the adele class space, whose Frobenius is the scaling
action `Fr_n : x ↦ n·x` of `ℝ₊ˣ` (verified identical to our `xⁿ ↔ n·x`, characteristic-1
constructions §9), and whose closed orbits are indexed by primes (lengths `log p`). The square is the
**self-product of this curve over `𝔽₁`**. The factor exists; the product-with-intersection-theory does
not.

**0.3 The positivity mechanism — complete and verified — on genuine surfaces.** [VERIFIED / CLASSICAL]
On an actual projective surface, the Hodge index theorem applied to the graph of Frobenius forces
RH-for-curves. Verified in our runtime (`characteristic_1_constructions.md` §9.1): the intersection
form on `C × C` with Néron–Severi basis `{F_h, F_v, Δ, Γ_q}`, `Δ·Γ_q = q+1−a`, has signature
`(1, ρ−1)` **iff** `|a| ≤ 2√q`, flipping exactly at the Hasse bound (checked `q = 4, 9, 25`). So:

> If the `𝔽₁` square exists with a Hodge index theorem, the *same* mechanism — already verified to
> work on genuine surfaces — discharges the number-field positivity. The mechanism is not the gap;
> the surface to run it on is.

**0.4 The tropical shadow — intersection-positivity is automatic in characteristic 1.** [VERIFIED]
In the tropical plane, intersection multiplicities are non-negative by construction
(`mult = m_u·m_v·|det(u,v)| ≥ 0`) and Bézout holds (`characteristic_1_constructions.md` R13). This is
the characteristic-1 *shadow* of the surface-positivity: in the tropical/`𝔽₁`-adjacent setting the
positivity is free. The construction must realize this shadow as a genuine intersection theory on the
2-dimensional square.

---

## 1. The object to construct (precise specification)

The target is an object `𝕊 := Spec ℤ ×_{𝔽₁} Spec ℤ` together with the data making it a "surface" with
intersection theory. A successful construction must supply all of the following.

**1.1 The surface `𝕊`.** [OPEN]
A 2-dimensional object over `𝔽₁` whose two projections `𝕊 → Spec ℤ` recover the arithmetic-site curve
(§0.2), such that `𝕊` is the self-product over `𝔽₁` (not over `ℤ` — the product over `ℤ` collapses,
`ℤ ⊗_ℤ ℤ = ℤ`, giving the curve back, not a surface; the `𝔽₁` product must be genuinely larger).

**1.2 A divisor group and class group.** [OPEN]
A group `Div(𝕊)` of "divisors" (codimension-1 cycles) and a class group `Cl(𝕊) = Div(𝕊)/∼` modulo a
principal/linear equivalence, finitely generated in each relevant degree, with distinguished classes:
- two fiber rulings `F_h, F_v` (pullbacks of points under the two projections);
- a diagonal class `Δ`;
- graph classes `Γ_n` of the scaling/Frobenius maps `Fr_n` (the arithmetic content, §0.2).

**1.3 An intersection pairing.** [OPEN]
A symmetric bilinear form `⟨·,·⟩ : Cl(𝕊) × Cl(𝕊) → ℝ` (or into an appropriate value ring) with the
product-surface intersection numbers as boundary conditions (matching §0.3 on the factors):
`⟨F_h, F_v⟩ = 1`, `⟨F_h, F_h⟩ = ⟨F_v, F_v⟩ = 0`, `⟨Δ, F_h⟩ = ⟨Δ, F_v⟩ = 1`, and `⟨Γ_n, F_v⟩` scaling
with `n`. The pairing must be defined intrinsically (from the geometry of `𝕊`), not imported by
analogy.

**1.4 An ample class.** [RESOLVED on the template; intrinsic realization pending with §1.1]
A distinguished class `H ∈ Cl(𝕊)` with `⟨H, H⟩ > 0` (a polarization), against which the Hodge index
is stated. **Resolved on the verified form** (consistent-by-construction computation, §2.2 discipline,
five gated self-checks passing): the class `H = E₁ + E₂` has `H² = 2 > 0`, so a class of positive
self-intersection *exists* — the verified form is not in the Néron–Severi-trivial / non-projective
case. The positive cone has the required two-component structure (the Hodge-index signature
consequence), `H` is ample on the effective fiber classes (`H·E₁ = H·E₂ = 1 > 0`, Nakai-style), and the
form is negative-definite on `H^⊥` (eigenvalues `−2, −1`). **On the template this precondition is
automatic** (it is a genuine projective surface, where projectivity was never in doubt), and the
construction supplies the ample `H` that T5/§1.5 is stated against. The point of the tropical
literature's caution is that on the *tropical* `𝕊` a class with `H² > 0` is **not** automatic — there
it remains an open hypothesis (§2.2), **not** something this template computation establishes for the
target. *Scope:* established on the product-of-curves template `𝕊` must match; exhibiting `H`
intrinsically on the concrete `F ⊗_𝔹 F` realization is pending with §1.1.

**1.5 The Hodge index theorem.** [OPEN — this is the crux]
The intersection form is **negative-definite on the primitive complement** `H^⊥` (the classes
orthogonal to the ample `H`); equivalently, `⟨·,·⟩` has signature `(1, ρ−1)`. *This is the property
whose truth is RH* (via §0.3): applied to the graph of the scaling-Frobenius, signature `(1, ρ−1)`
forces the spectral bound that confines the zeta zeros to `Re(s)=½`.

**Equivalence to be preserved.** A construction is only a solution if, on `𝕊`, the Hodge-index
application to `Γ_{scaling}` reproduces the §0.3 mechanism — i.e. signature `(1, ρ−1)` ⟺ the
zeta-zero confinement. Building `𝕊` with *some* intersection theory is not enough; it must be the one
that makes the positivity equal RH.

---

## 2. Candidate constructions (what the literature supplies, and the precise lack)

Several `𝔽₁`-geometries exist; each provides part of §1 and fails a specific requirement. Tagged by
what they give and what they miss.

| candidate | supplies | misses (the precise lack) | status |
|---|---|---|---|
| **Connes–Consani arithmetic site / scaling site** | the curve `Spec ℤ/𝔽₁` (§0.2), the scaling Frobenius, the explicit formula as a trace | the 2-dimensional **square** with an intersection pairing (§1.1, 1.3) — they build the curve, not `𝕊` | [CLASSICAL; square OPEN] |
| **Deitmar monoid schemes** | a working `𝔽₁`-scheme theory (schemes over commutative monoids), products | the products are too coarse — no intersection theory with a Hodge index on the `Spec ℤ`-square | [CLASSICAL; Hodge OPEN] |
| **Toën–Vaquié / relative schemes** | `Spec ℤ` as a relative scheme over `𝔽₁ = `the initial object | no surface intersection theory; the relative product does not yield `𝕊` with §1.3–1.5 | [CLASSICAL; OPEN] |
| **Lorscheid blueprints / `B₁`** | a unified `𝔽₁`-geometry (blueprints) covering monoids and semirings | divisor/intersection theory on the blueprint square not developed to a Hodge index | [CLASSICAL; OPEN] |
| **Connes–Consani `ℤ̄` / `Spec ℤ` compactification (Arakelov)** | an intersection theory *at the archimedean place* (Arakelov geometry on `Spec ℤ`) | this is the 1-dimensional Arakelov intersection; the **2-dimensional** `Spec ℤ ×_{𝔽₁} Spec ℤ` Arakelov surface with a Hodge index is not constructed | [CLASSICAL (1D); 2D OPEN] |

**The common gap, stated once.** Every candidate builds either the curve, or a scheme theory, or a
1-dimensional intersection theory — and none builds the **2-dimensional self-product over `𝔽₁` with a
2-dimensional intersection pairing admitting a Hodge index theorem**. That single object is the open
target, and it is open across all known `𝔽₁`-frameworks simultaneously.

### 2.1 Recent work bearing on the candidates, the crux, and the cautions (2020–2026)

A literature cross-reference (2020–2026) updates the candidate table and the obstructions below in four
specific ways, plus one cautionary precedent. None changes the open status of §1.5; together they
sharpen *where* the program stands.

- **The infinite-genus structure the square needs is now built (1-dimensionally).** Connes–Consani,
  *Riemann–Roch for `Spec ℤ̄`* (arXiv 2205.01391; Bull. Sci. Math. 187, 2023) and *Riemann–Roch for
  the ring ℤ* (arXiv 2306.00456; C. R. Acad. Sci. Paris 362, 2024) prove a genuine integer-valued
  Riemann–Roch over the sphere spectrum, finding **genus 0** for `Spec ℤ`; and *On the Jacobian of
  `Spec ℤ`* (arXiv 2602.15941, Feb 2026) resolves the genus-0-vs-infinite-genus tension by building an
  arithmetic **Picard monoid / Jacobian** encoding infinite genus (divisors with coefficients in
  `ℤ ∪ {∞}` and infinite support). [CLASSICAL/recent; **2602.15941 is a provisional preprint**.]
  *Bearing:* this is the most direct recent step toward the **`H¹` of T4 / §3.4** — the infinite-genus
  Jacobian is the structure carrying the "space of the zeros," and it supplies what T2's
  finite-generation argument deferred to `H¹`. It is still a *curve-level* (1-dimensional) construction;
  the 2-dimensional square (§1.1) is not built.

- **Weil positivity is proven at the archimedean place, and semilocally up to a controllable
  infinitesimal — direct partial progress on the crux (§1.5 / §3.4 / T5).** Connes–Consani, *Weil
  positivity and trace formula, the archimedean place* (arXiv 2006.13771; Selecta Math. 27:77, 2021)
  prove the archimedean Weil positivity via compression of the scaling action onto Sonin's space
  (controlled with prolate functions and Hermitian Toeplitz matrices); *Zeta zeros and prolate wave
  operators* (arXiv 2310.18423; Ann. Funct. Anal. 15:87, 2024) extends the key infinitesimal property
  to the **semilocal** case (finitely many places including `∞`). [CLASSICAL/recent.] *Bearing:* this
  is the strongest direct evidence the program's central inequality (= our §1.5 Hodge-index
  negative-definiteness, the same positivity by three faces) could hold — but it is **place-local /
  semilocal, not global**, and global positivity is exactly what remains open. The computation of the
  Hermitian Jacobi-matrix coefficients for general place-sets is *explicitly deferred to a forthcoming
  paper* — that computation is on the critical path to T5.

- **The signature template (§1.5, §0.4) is fully proven in the tropical/combinatorial world — and the
  signature is NOT automatic.** Adiprasito–Huh–Katz, *Hodge theory for combinatorial geometries* (Annals
  188(2), 2018) and Amini–Piquerez, *Hodge theory for tropical varieties / fans* (arXiv 2007.07826, 2020;
  2310.15367, 2025) prove the full Kähler package — Hard Lefschetz + Hodge–Riemann — with the correct
  `(1, …)` signature in tropical cohomology; *Combinatorial tropical surfaces* (arXiv 1506.02023) gives a
  tropical Hodge index theorem (intersection pairing non-degenerate, ≤ one positive eigenvalue) — exactly
  the §0.4 shadow made into a theorem. [CLASSICAL.] **Caution (Babaee–Huh, arXiv 1502.00299):** a tropical
  surface exists whose intersection form does *not* have the Hodge-index signature, refuting a strong
  Hodge conjecture for positive currents. *Bearing:* this is the proven template the R13 lift (§9.1 of the
  companion doc) reaches toward — and the Babaee–Huh counterexample is the warning that **any
  construction of `𝕊` must verify the signature explicitly, not assume it**; the desired sign pattern can
  fail.

- **No 𝔽₁-construction has yet produced a new unconditional result about the zeros.** The cross-reference
  found no 2020–2026 work in which the arithmetic-site / `𝔽₁` machinery yields a theorem about zeta zeros
  unobtainable classically; the sharpest on-line results still come from classical analytic methods. The
  `𝔽₁`-square route remains a guiding program, not yet proof-bearing. [assessment]

- **Cautionary precedent — positivity routes have failed before, exactly at the positivity step.** De
  Branges proposed deriving RH from positivity in Hilbert spaces of entire functions; Conrey–Li (arXiv
  math/9812166; IMRN 2000) exhibited explicit examples showing the required positivity conditions are
  *not* satisfied for the spaces attached to `ζ` and to `L(χ₋₄)`. *Bearing:* §1.5 / T5 is a positivity
  statement of the same family; this is the standing reason to treat any claimed resolution of the crux
  with the scrutiny history warrants, and to demand independent verification of the
  negative-definiteness specifically — that is the step where prior programs broke.

**2026-06-06 — citation verification (independent full-text check).** A pass over the references
above confirms every paper is real, with these corrections and one substantive finding:
- **Authors/details:** *Zeta zeros and prolate wave operators* is Connes–Consani–**Moscovici** (the
  third author was omitted); arXiv 2310.15367 is *Hodge theory for tropical **fans***, a **2023**
  preprint (not "2025"); arXiv 1905.07085 is **Pietromonaco** (an MSc thesis), not "Bryan et al.";
  arXiv 1703.10521 is **Sagnier** (a CC-*type* site), not Connes–Consani; the Riemann–Roch titles
  carry the bar, `Spec ℤ̄` (the Arakelov compactification).
- **The Feb-2026 Jacobian paper proves moduli, NOT positivity.** *On the Jacobian of `Spec ℤ̄`*
  (arXiv 2602.15941, 17 Feb 2026, preprint) is verified real and builds the arithmetic
  Picard/Jacobian monoid encoding infinite genus (divisors over supernatural numbers `∏ p^{aₚ}`,
  `aₚ ∈ ℕ∪{∞}`). But its full text contains **zero** occurrences of "Hodge" / "Weil positivity" /
  "positivity" and it does not claim RH: it advances the **curve-level** (1-dimensional) geometry
  one rung; it is **not** the Hodge-index/positivity step. Reading it as progress *on the crux*
  would overstate it.
- **The deferred Hermitian-Jacobi computation (critical path to T5) has NOT appeared** as of this
  date. The only later Connes–Consani–Moscovici paper, *Zeta Spectral Triples* (arXiv 2511.22755,
  Nov 2025), uses a different mechanism (Euler-product rank-one perturbations + a Carathéodory–Fejér/
  Toeplitz self-adjointness result) and is **explicitly a conditional strategy** ("a rigorous proof
  of this convergence would establish the Riemann Hypothesis"), with only **numerical**
  spectrum-to-zeros agreement. So items (A)/(B) below stand unchanged: no 𝔽₁/arithmetic-site
  unconditional result about the zeros, and no construction of the 2-dimensional square, in 2024–2026.

**Net effect on this scaffold.** The recent work confirms the architecture and advances the *adjacent*
pillars (the infinite-genus Jacobian for `H¹`/T4; archimedean+semilocal Weil positivity on the crux; the
proven tropical signature template for the R13 lift), while leaving the **two open items unchanged**: the
2-dimensional square `𝕊` with an intersection pairing (§1.1, 1.3), and the **global** Hodge-index
positivity (§1.5) — which is RH, is only established locally/semilocally, and whose signature the
Babaee–Huh precedent says must be checked, not assumed.

### 2.2 The consistent pairing template, and external confirmation of the open core

Two further sourced results fix the intersection-form *template* `𝕊` must match and confirm the precise
open status.

- **A consistent, sourced intersection form for a product of curves (the template for T3).** For an
  elliptic curve product `E × E`, the Néron–Severi group is `NS(E × E) = ⟨E₁, E₂, E₃ := Δ − E₁ − E₂⟩ ≅ ℤ³`
  with the intersection form `E₁·E₂ = 1`, `E₁² = E₂² = 0`, `E₃² = −2`, `E₁·E₃ = E₂·E₃ = 0` (the `NS(E×E)` lattice is standard, surveyed
  e.g. in Pietromonaco, arXiv 1905.07085 — an MSc thesis on the banana manifold, *not* "Bryan et
  al."; the underlying DT computation is Bryan, arXiv 1902.08695). [CLASSICAL.] This is the *correct*
  reference pairing — its signature is `(1, 2)` (verified by direct eigenvalue computation, and the core
  `{E₁, E₂, E₃}` block reproduces it exactly), genuine Hodge index. Extending by graph-of-multiplication
  classes `Γ_m` (derived via Lefschetz `Γ_m·Δ = 1 − tr + deg` and adjunction `Γ_m² = 0` for `g = 1`, *not*
  hand-coded) preserves signature `(1, ρ−1)`. **This replaces earlier ad-hoc Gram-matrix attempts**
  (which were inconsistent — see §4/T2 note) with a sourced form. *Caveat:* this holds for a genuine
  curve product *over a field*, where the Hodge index theorem is a theorem (projective surface, `K = 0`
  at `g = 1`); it is the template `𝕊` must reproduce, not a construction of `𝕊`.

- **External confirmation that the square is genuinely unbuilt and under active construction.** The
  precise object this scaffold targets — the tensor product `F ⊗_𝔹 F` of the arithmetic-site tropical
  curve with itself over the Boolean semiring `𝔹` — is, in the Connes–Consani lineage, explicitly an
  open construction: a researcher (Sagnier, arXiv 1703.10521, *An arithmetic site of Connes–Consani
  type for imaginary quadratic fields with class number 1* — a CC-*type* site, not a Connes–Consani
  paper) defines `F ⊗_𝔹 F` abstractly and reports "currently trying to find a
  concrete description" of it, noting the concrete description of `ℤ ⊗_𝔹 ℤ` already has applications.
  [CLASSICAL/in-progress.] *Bearing:* this confirms §1.1/§2's "open" status precisely and externally —
  the 2-dimensional square has no concrete intersection-theoretic description yet, by someone working on
  it directly. The genuine frontier is the **concrete realization of `F ⊗_𝔹 F`** as a tropical surface
  carrying the template pairing above.

**Honest caution carried from §2.1 and the tropical literature.** Even the *tropical* Hodge index for
1-cycles modulo rational equivalence on a non-singular tropical surface is noted as open in general
(Kristin Shaw and collaborators), and tropical surfaces need not admit a class of positive
self-intersection (the analogue of projectivity/Kähler) — so a class with `H² > 0` (§1.4) is itself a
nontrivial hypothesis on `𝕊`, not automatic. The signature must be verified on any concrete `𝕊`, never
assumed.

**Methodological consistency (a standing rule for this program).** Intersection numbers in this work are
**never entered by hand**, and intersection *rules* are never hand-written either — both were attempted
during development and both produced inconsistent Gram matrices (an `(3+,3−)` form, a genus-driven form,
and a fragment-rule form failing its own adjunction identity; all discarded). The consistent procedure,
used for the template above, is: fix the **single sourced intersection matrix** of a verified basis
(here `{E₁, E₂, E₃}` with `E₁·E₂=1`, `E₃²=−2`, from the product-of-curves form), express every class as
a coordinate **vector** in that basis (coordinates themselves derived from sourced intersection numbers
and the adjunction identity, e.g. `Γ²=2g−2−Γ·K`), and compute the entire pairing **by linearity**
(`⟨v,w⟩ = vᵀ G₀ w`) from the fixed form — so no entry can contradict the intersection theory. Every such
computation is **gated by explicit self-checks** (symmetry; the boundary numbers `Δ·E₁=Δ·E₂=1`; the
adjunction self-intersections; the verified core signature) that must all pass before a result is
trusted. This is the declarative discipline — derive from one fixed source, reduce to linear algebra,
gate on consistency checks — and it is the architecture any concrete construction of `𝕊` (or any SDK
realizing it) must follow to avoid the hand-coding failure mode.

### 2.3 A concrete construction of `F ⊗_𝔹 F`, and the structural finding it yields

Attempting the concrete construction of the square (the open object of §1.1/§2.2) via the bi-tropical
model — `F` realized as PL convex functions on the scaling segment (a tropical curve), `F ⊗_𝔹 F` as
tropical-bilinear functions `max_i(a_i x + b_i y + c_i)` on the product, a **tropical surface in `ℝ²`**
whose divisor classes are the corner loci — produces a genuine structural finding (derived from the
stable-intersection / fan-displacement rule, not hand-coded). [candidate concrete model.]

**The finding: the scaling-Frobenius graphs form a parallel pencil, and the arithmetic content
relocates to a shift length.** In the tropical (log) coordinate the scaling Frobenius `Fr_n : x ↦ x +
log n` is an **affine shift**, so the graph of `Fr_n` is the line `y = x + log n` — *parallel to the
diagonal* `Δ` (both recession direction `(1,1)`), separated by `log p`. Consequently, by the stable-
intersection rule, `Δ · Γ_n = |det((1,1),(1,1))| = 0`: the diagonal and the Frobenius graphs **do not
meet transversally** — they are a parallel pencil indexed by `log p`. This is *structurally different*
from the algebraic product-of-curves template (§2.2), where `Γ_n` has direction `(1,n)` and `Δ · Γ_q =
q + 1 − a` counts fixed points. **The tropical square has no transverse fixed points; the arithmetic
content (the algebraic `q+1−a`) relocates to the shift length `log p`** — a translation/length datum,
not an intersection number. (An earlier hollow-self-intersection computation gave the recession form
`[[0,1,1],[1,0,1],[1,1,0]]`, signature `(1,2)` — but see the correction below: that was the
Perron–Frobenius shape from hollow diagonals, not the fan-derived form.)

**What this establishes, and the sharpened open question.** [partial; candidate model.] The
construction shows the concrete `F ⊗_𝔹 F` is a *different intersection-theoretic object* than the
algebraic template — so the §0.3 RH-forcing mechanism (Hodge index on `Δ, Γ_q` forcing `|a| ≤ 2√q`)
**does not transfer in the same form**, because `Δ · Γ_n = 0` tropically. This is real progress on
understanding the square, and it sharpens §1.5 precisely: completing the Hodge-index/positivity crux on
the *tropical* square requires determining whether the **parallel-pencil shift-length structure (the
`log p` separations)** carries the positivity that the algebraic fixed-point structure carries — a new,
precise open question, not a closed one. *Honest scope:* the bi-tropical model is a plausible candidate
realization (not confirmed to be the canonical `F ⊗_𝔹 F` doc-22 seeks).

**Correction, by derivation (resolving the self-intersection question).** The self-intersections were
subsequently **derived from the fan balancing rule** `u₁ + u₂ + b·u = 0` (smooth toric-surface
intersection theory, arXiv 2105.12216), replacing the hollow assumption. The derived values are
integer and smoothness-consistent: the fan-ray (toric-boundary) classes get `F_h² = F_v² = −2` and the
diagonal-direction classes `−1`, giving the core form `[[−2,1,0],[1,−1,1],[0,1,−2]]` with signature
**`(0, 2)`** — *not* `(1, 2)`. The lesson is precise and is a genuine correction: **the `(1, ρ−1)`
Hodge-index shape belongs to the *fiber/correspondence* form (§2.2, where fibers have self-intersection
`0`, sourced and verified), not to the *toric-boundary* recession form (where the fan rule forces
negative self-intersection).** These are two distinct divisor structures on the same surface; the
earlier hollow computation accidentally mimicked the fiber form's `E²=0` and so got the right *shape*
for the wrong *reason*. The **parallel-pencil finding itself** (`Δ·Γ_n = 0`, arithmetic content in the
shift lengths) is unaffected — it concerns the graph *directions* and is independent of the
self-intersection issue. So: the Hodge-index positivity is carried by the fiber/correspondence form
(§2.2/§0.3), the fan-derived toric-boundary form is `(0,2)` and a different object, and the crux
(§1.5/T5) remains the global positivity of the fiber-form/shift-length structure = RH. The
self-intersection cleanup is resolved by derivation, with the conflation it exposed corrected.

**Following the sharpened question to its answer: the shift-length positivity is *vacuous* — it is
equivalent to RH, not a step toward it.** (This is a negative/cautionary finding; we lead with that so
it is not misread as a positivity result.) The §2.3 finding
relocated the arithmetic content to the shift lengths `log p` of the parallel pencil, raising a precise
question — does that shift-length structure carry a positivity? Building the natural pairing on the
pencil (derived from the explicit formula, gated by self-checks): on a set of primes the Weil-type Gram
is `W_{ij} = Σ_zeros cos(γ·(log p_i − log p_j))` — the explicit-formula prime kernel evaluated at shift
differences. This Gram is **positive semidefinite** (verified numerically from the first 200 zeros:
diagonal `= #zeros`, diagonally dominant, min eigenvalue `≈ 185 > 0`). So the shift-length structure
*does* carry a positivity. **But a control settles its meaning:** the same kernel with *random* points
in place of the zeros is *also* PSD — because `Σ cos(γ·δ)` is a sum of rank-1 `cos·cos + sin·sin`
outer products, automatically PSD for *any real* spectral parameters `γ`. Hence the positivity is
**equivalent to the `γ` being real**, i.e. to the zeros lying on the critical line — i.e. it **is RH**,
not a route around it. *Conclusion:* the tropical-square construction reaches, from a new direction
(the parallel-pencil shift lengths), a positivity that equals RH — confirming §1.5/T5 as the
irreducible crux rather than circumventing it. This matches the pattern across the whole program: every
faithful construction (Hodge index on the algebraic square §0.3; shift-length positivity here; Weil
positivity §3.4; confining self-adjointness, Thread 2 of the cross-reference) reaches the *same*
proposition, RH, by a different face.

### 2.4 The canonical square, mechanized (v0.17.0) — what is now constructed, derived, and proved

Stage C of the roadmap closes the **construction** half of the §2.2 frontier in Lean
(`F1Square/Square/`, all axiom-clean `{propext, Quot.sound}`, no Mathlib, choice-free):

- **Canonical `𝕊`, by universal property.** Deitmar 𝔽₁-algebras are commutative monoids and `𝔽₁`
  (the trivial monoid) is proved **initial**, so the fiber coproduct over it — the tensor
  `F ⊗_𝔽₁ F` — is the plain coproduct of the curve monoid `(ℕ₊, ·)` with itself. That coproduct is
  realized as `ℕ₊ × ℕ₊` and its **universal property is proved** (`copair_inl/inr/unique`): the
  canonicality is the universal property, not a choice of model. The §3.1 collapse is avoided by
  theorems (distinct injections; non-injective codiagonal; the monomial family `2^a ⊗ 2^b` free of
  rank 2 — strict 2-dimensionality, T1 for **all** points, superseding the 17-prime truncation).
- **The intersection lattice, derived.** The distinguished divisors are genuine subsets of `𝕊`, and
  every primitive intersection number is a **point count** with classes moved along their translation
  pencils — including `Δ² = 0` *from the parallel-pencil disjointness itself* (`Δ ∩ Γ_n = ∅`).
  Bilinearity then **forces** `E₃² = −2`, and the sourced §2.2 template **emerges**
  (`sqPair_eq_template`): T3's "realize the pairing intrinsically, not by analogy" is closed *by
  derivation*, with the five §2.2 gate self-checks as theorems and the class lattice finitely
  generated (T2 on `𝕊`).
- **The pencil, with its arithmetic.** The §2.3 finding is now a theorem stack on canonical `𝕊`:
  no transverse fixed points; log-slope 1 (direction `(1,1)`, stable count `Δ·Γ_n = 0`); constant
  separation `log n` as a **constructive real** (`logN_mul_general` — general log-multiplicativity by
  exp injectivity); separation `= Λ(p) = log p` at primes and `k·log p` at prime powers — the
  explicit-formula prime weights, reached geometrically.
- **The Hodge index of the derived lattice — and its precise limit.** `𝕊`'s own polarized instance
  (`squarePolarized`) has the ample `H = [V]+[H]`, `H² = 2 > 0` (verified, per the §2.2 caution), and
  `H^⊥` negative-definite: `square_hodgeIndex` holds, **and the lattice is provably pencil-blind**
  (`square_hodge_pencil_blind`: `[Γ_n] = [Δ]`, `Δ·Γ_n = 0` for all `n`). The trace data through which
  the §0.3 mechanism forces RH-for-curves is *absent by theorem* from the coarse numerical lattice —
  the positivity holds with no spectral input, the geometric face of the §2.3 control. **So the crux
  (§1.5/T5) is sharpened, not closed:** it is the Hodge index / Weil positivity of the `H¹`-bearing
  pairing (T4: scaling spectrum = the zeros), equivalently `λₙ ≥ 0 ∀n` — open, exactly as before.

*Honest scope.* "Constructed" means the monoid-scheme (T1) level with its derived divisor/intersection
layer (T2/T3); the spectral (`H¹`) enrichment of `𝕊` — the object the crux is genuinely about — is
**not** constructed, and `hodgeIndexHolds` stays `none`. *Level precision:* the canonical object built
is the **monoid-level** tensor `F ⊗_𝔽₁ F` (Deitmar 𝔽₁-algebras = commutative monoids; the coproduct,
with its universal property proved and uniqueness up to canonical isomorphism). The **semiring-level**
tensor `F ⊗_𝔹 F` over the Boolean semiring — the concrete description §2.2 records as open (Sagnier,
arXiv 1703.10521) — is a finer object: the monoid square is its underlying combinatorial skeleton (the
pencil layer realizes the bi-tropical structure in the log coordinate), but the semiring-level
description is **not** claimed closed by this construction.

---

## 3. The precise obstructions (why §1.5 resists, stated as named problems)

The construction faces specific, named difficulties. Formalizing them is the point of this section;
none is claimed resolved.

**3.1 The product collapses over `ℤ`.** [structural]
`Spec ℤ ×_{Spec ℤ} Spec ℤ = Spec ℤ` — the naive product is the curve, not a surface. The product must
be taken *over `𝔽₁`*, which requires `𝔽₁` to exist as a genuine base below `ℤ` and the fiber product
over it to be 2-dimensional. This is the existence problem for `𝔽₁`-geometry itself, sharpened to:
*the `𝔽₁`-fiber-square must be strictly 2-dimensional.*

**3.2 No archimedean Frobenius.** [structural]
Over `𝔽_q`, Frobenius is a genuine endomorphism whose graph is a divisor on `C × C`. Over `ℚ` the
scaling action plays Frobenius's role (§0.2) but there is no Frobenius *at the archimedean place* —
the place that is "the odd one out" in the product formula. The graph `Γ_{scaling}` (§1.2) must be a
genuine divisor on `𝕊` with a well-defined self-intersection and `⟨Δ, Γ_{scaling}⟩` (the "fixed-point
count" that, over `𝔽_q`, is `q+1−a`). Defining this archimedean-inclusive intersection number is
unsolved.

**3.3 The value ring of the pairing.** [structural]
Over `𝔽_q`, intersection numbers are integers. On `𝕊`, the analogue of `q+1−a` involves the
archimedean place and is plausibly real-valued (Arakelov-style), not integer-valued. The pairing's
codomain (§1.3) and the meaning of "signature" over it must be fixed so that the Hodge index (§1.5)
is a well-posed statement.

**3.4 Hodge index from positivity of a Rosati-type involution.** [the crux, named]
Over `𝔽_q`, the Hodge index on `C × C` follows from *positivity of the Rosati involution* on the
endomorphism algebra of the Jacobian — a genuine theorem. The `𝔽₁`/`ℚ` analogue requires a
positivity (the Weil positivity / the §0.4 tropical-positivity made genuine) on the relevant
endomorphism/correspondence structure of `𝕊`. **This positivity is the open content of §1.5, and it
is RH.** It is not expected to be cheaper than RH; the formalization's value is to state it as a
property of a *specific constructed object* rather than an abstract conjecture — which is only
possible once `𝕊` (§1.1) is built.

---

## 4. Verification targets (what a partial construction must check, computationally where possible)

A construction proceeds by stages; each stage has a checkable target. These are the runtime-checkable
milestones, in order of increasing difficulty. (None is yet met for the genuine `𝕊`; each was
verified for the *product-of-curves model* in §0.3, which is the boundary condition.)

- **T1.** [MECHANIZED — canonical, v0.17.0] `𝕊` is strictly 2-dimensional over `𝔽₁`. **Resolved and
  now PROVED in Lean for all points** (§2.4, `Square/Tensor.lean`): `𝕊 = C ×_{𝔽₁} C` is the Deitmar
  monoid product of the arithmetic-site curve with itself, realized as the **coproduct with its
  universal property proved** (canonical, not a candidate); strictly 2-dimensional (the monomial
  family `2^a ⊗ 2^b` is free of rank 2, `gen2_injective`); avoids the `ℤ`-collapse (§3.1) by theorems
  (`inl ≠ inr`, non-injective codiagonal); both projections recover `C` (`proj1_inl`,
  `proj_faithful`). This supersedes the earlier 17-prime-truncation runtime check (`|C|² = 289`,
  projection independence `corr ≈ 0.016`), which remains as historical evidence. *Scope:* T1 is the
  point-set / projection level; the spectral `H¹` layer remains T4–T5.
- **T2.** [PARTIAL] `Cl(𝕊)` is finitely generated with the §1.2 distinguished classes.
  **Verified:** `Cl(𝕊)` is finitely generated; the distinguished classes — the two rulings
  `F_h, F_v` (independent), the diagonal `Δ`, and the scaling-graph classes `Γ_k` — are all present.
  **Consistency check passed:** using a Lefschetz-derived intersection pairing
  (`Δ·Γ_k = 1 + k − a`, *derived* from the trace, not hand-coded), the Néron–Severi Gram matrix is
  a genuine intersection form whose signature is governed by the trace `a` exactly as §0.3 — `(1, ρ−1)`
  for `a` in the Hasse range, failing outside it. **Open input (= §3.4):** *which* form `𝕊` actually
  carries depends on the `𝔽₁` curve's cohomology `H¹` (its "genus" and the trace) — which is undefined,
  and is the same open object as §3.4 (the cohomology of the arithmetic site). So T2 supplies the class
  group and the consistent intersection-form *machinery*; it does **not** determine the specific form,
  because that requires `H¹` of the `𝔽₁` curve, which routes back to the named obstruction §3.4.
  *(A first attempt using ad-hoc, non-Lefschetz intersection numbers produced an inconsistent
  `(3+, 3−)` Gram matrix — discarded; the corrected Lefschetz-derived pairing is the one above.)*
- **T3.** [INTRINSIC REALIZATION MECHANIZED, v0.17.0 — at the monoid/pencil level] The intersection
  pairing (§1.3) reproduces the boundary intersection numbers on the factors — `⟨F_h, F_v⟩ = 1`, etc.
  **Now realized intrinsically on canonical `𝕊`** (§2.4, `Square/Lattice.lean`): every primitive
  number is a point count on the constructed square (with translation-pencil moving), bilinearity
  forces `E₃² = −2`, and the sourced §2.2 template **emerges as a consistency theorem**
  (`sqPair_eq_template`) rather than being imported by analogy — with the five gate self-checks as
  theorems. *Honest residue:* this realizes the pairing on the COARSE numerical lattice, which is
  pencil-blind (`[Γ_n] = [Δ]`, `Δ·Γ_n = 0`); the form whose `Δ·Γ` carries the trace — the input the
  §0.3 mechanism needs — lives on the spectral `H¹` layer and routes to T4/T5 (§3.4), exactly as T2's
  open input always said. *(Earlier ad-hoc Gram matrices for this step were inconsistent — an
  inconsistent `(3+,3−)` attempt and a genus-driven attempt that contradicted §0.3 — and are discarded
  in favor of the derived form.)*
- **T4.** [RESOLVED as constraint; closes the chain] The trace `a` and `H¹`. **Resolved:** the
  Lefschetz fixed-point formula for the scaling flow *is* the Weil explicit formula, giving
  `trace(scaling Fr_x | H¹) = Σ_zeros x^{1/2+iγ}` (the trace identity verified numerically at
  `x = 2, 10, 100` against the cached zeros). So `H¹` of the arithmetic-site curve must be the space
  on which scaling acts **with spectrum = the zeta zeros** — exactly Hilbert–Pólya — and the trace
  `a = trace(scaling | H¹)` is thereby *identified*, which **determines T2's intersection form**
  (resolving T2's open input structurally). **Built [CLASSICAL — Connes–Consani]:** such an `H¹`
  exists, as a cohomology of the scaling site carrying the scaling action and recovering the explicit
  formula as its Lefschetz trace. *(Step relies on the classical Lefschetz↔explicit-formula
  correspondence and the Hilbert–Pólya framing; it pins and verifies the constraint, it does not
  re-derive the cohomology.)*
- **T5.** The intersection form has signature `(1, ρ−1)` (§1.5) — the crux; **this is RH** and is not
  expected to fall to computation, but on a constructed `𝕊` it becomes a definite signature
  computation rather than a conjecture, exactly as §0.3 is a definite (and verified) computation on
  the product-of-curves model.

The ladder's current state (updated v0.17.0): **T1 is mechanized and canonical** (`𝕊` constructed in
Lean as the coproduct with its universal property proved, strictly 2-dimensional for all points —
§2.4); **T2 is resolved on `𝕊`'s coarse lattice** (class lattice finitely generated with the
distinguished classes, derived intersection form; the SPECTRAL form still pends `H¹`, which is the
honest residue routed to §3.4); **T3's intrinsic realization is mechanized** at the monoid/pencil
level (the template emerges from point counts; the `H¹`-bearing form remains the open object);
**T4 resolves T2's pending input as a constraint** (`H¹` must be the Hilbert–Pólya
space, spectrum = the zeros, verified via the Lefschetz↔explicit-formula identity; Connes–Consani
built such an `H¹`); **T3** (the intersection pairing realized intrinsically on `𝕊`, not just
consistent) is the remaining genuine construction step; and **T5 is RH** — the positivity (signature
`(1, ρ−1)`) on the constructed `H¹`, definite-but-open. The §0.3 result is the proof that the
mechanism is correct: *if* T1–T4 are met, signature `(1, ρ−1)` ⟺ the spectral bound. So the chain now
closes onto a **single open property** — the positivity of the scaling action on the (built) `H¹`,
which is RH — with every other link verified, pinned, or routed to a named obstruction.

---

## 5. Provenance and calibration

| element | status |
|---|---|
| characteristic-1 base `ℝ_max`; Frobenius-as-scaling; prime-indexed orbits; tropical positivity (R13) | **VERIFIED** (`characteristic_1_constructions.md`) |
| Hodge-index mechanism on `C × C`: signature `(1,ρ−1)` ⟺ `|a| ≤ 2√q`, flips at the Hasse bound | **VERIFIED** (`characteristic_1_constructions.md` §9.1; `q=4,9,25`) |
| the arithmetic-site curve `Spec ℤ/𝔽₁`; scaling site; explicit formula as trace | **CLASSICAL** — Connes–Consani (2014–2021) |
| Hodge index from Rosati positivity (the `𝔽_q` proof of RH-for-curves) | **CLASSICAL** — Weil (1948), Deligne (1974) |
| `𝔽₁`-geometries (monoid schemes, blueprints, relative schemes, arithmetic site) | **CLASSICAL** — Deitmar, Toën–Vaquié, Lorscheid, Connes–Consani |
| 1-dimensional Arakelov intersection on `Spec ℤ` | **CLASSICAL** — Arakelov, Faltings |
| **`Spec ℤ ×_{𝔽₁} Spec ℤ` as a 2-dimensional surface with an intersection pairing** (§1.1, 1.3) | **MECHANIZED at the monoid-scheme level, v0.17.0** (§2.4: canonical by universal property, derived lattice; the spectral `H¹` enrichment remains open) |
| **a Hodge index theorem for that pairing** (§1.5, §3.4) — the positivity that is RH | **OPEN** (the derived lattice's Hodge index is proved AND provably pencil-blind — not the crux; the `H¹`-bearing positivity is RH and is open) |
| this scaffold: the precise specification, the candidate-gap table, the named obstructions, the verification ladder | the contribution of this document |

**What this document is and is not.** It is a *formalization of the construction problem* for the
`𝔽₁` square: it states exactly what the object must be (§1), what is already established around it
(§0), what the candidates supply and lack (§2), the named obstructions (§3), and the checkable
milestones (§4). It is **not** a construction of the object, and it does not claim the Hodge index
(§1.5, T5) — that is RH, and it is open. The value of the scaffold is to make the target precise:
every piece of the positivity *mechanism* is verified (§0.3), the surrounding `𝔽₁` *curve* is built
(§0.2), and the single open object is the 2-dimensional square with its intersection theory — stated
here as a definite specification with definite milestones, so that any construction can be checked
against it stage by stage.

---

## 6. v0.2.0 — mechanization status and the analysis-substrate roadmap

**Mechanized (kernel-checked, axiom-audited).** The function-field Hodge mechanism is a Lean theorem
(`Mechanism.hodgeType_iff : hodgeType q a ↔ a² ≤ 4q`, flip at `q = 4,9,25`); the §2.2 template's
ample class and negative-definiteness on `H^⊥` (`Template.lean`); the §2.3 parallel pencil
`Δ·Γ_n = 0` (`det((1,1),(1,1)) = 0`) and the fan-vs-fiber correction (the fan recession form is
degenerate, so the `(1,ρ−1)` shape belongs to the fiber form), plus a Babaee–Huh counterexample
showing the signature is NOT automatic (`Tropical/Signature.lean`); and the §2.3 control (the
shift-length Gram is PSD for any spectrum ⇒ vacuous, `Bridge.lean`). **As of v0.17.0 (stage C), the
canonical square itself is mechanized** (§2.4, `F1Square/Square/`): `𝕊 = F ⊗_𝔽₁ F` with its universal
property, the derived intersection lattice with the five-gate discipline, the parallel pencil with
constructive-real shift lengths `log n` (= `Λ(p)` at primes), the polarized instance with its Hodge
index, and the pencil-blindness boundary theorem that keeps the crux honestly open.

**The analysis-substrate roadmap (building the needed analysis the UOR way).** The analytic half of
the program (Li's `λₙ`, the explicit-formula trace, the cos/sin Weil-Gram over ℝ, T4's trace
identity) is *blocked on a substrate we are building from first principles* — exact arithmetic,
canonical forms, realizations, no Mathlib — one brick per release:

- **v0.2.0 (done):** exact ℚ (`Analysis/Rat.lean`) — canonical reduced form = content-address;
  decidable exact equality/order; the first brick.
- **v0.3.0 (done):** a reflective **commutative-ring normalizer for ℤ** (`Analysis/RingNF.lean`) — a
  canonical polynomial form (= content-address) with a soundness theorem, the tool that unlocks
  general algebraic proofs without Mathlib (it retroactively made the ℚ field laws *general*); and
  **constructive ℝ** as Bishop regular sequences over ℚ (`Analysis/Real.lean`) — the `Real` type, the
  regularity/positivity predicates, the ℚ↪ℝ embedding, and the equality setoid (refl/symm).
- **v0.4.0 (done):** a from-scratch **`ring` tactic** (`ring_uor`, core metaprogramming on the v0.3.0
  normalizer — no Mathlib); **ℚ as a verified ordered field** (`Analysis/QOrder.lean`: transitivity,
  monotonicity, triangle inequality, order transport); and **ℝ as an ordered additive group**
  (`Analysis/Real.lean`: negation `Rneg` and Bishop addition `Radd`, both with regularity proved).
- **v0.5.0 (done):** `≈`-transitivity via the **Archimedean lemma** (so Bishop equality on ℝ is an
  equivalence); **ℝ multiplication** `Rmul` with its regularity proof (canonical bound `|xₙ| ≤ |x₀|+2`
  + `n ↦ 2K(n+1)−1` reindexing) and commutativity; and **ℂ = ℝ×ℝ with all four operations** (`Cadd`,
  `Cneg`, `Cmul`, the additive-group laws **and commutative multiplication** `Cmul_comm` up to `≈`,
  via the operation-congruences `Rneg_congr`/`Radd_congr`/`Rsub_congr`).
- **v0.6.0 (done):** **ℝ and ℂ are commutative rings up to `≈`.** The reindex used by `Rmul` differs
  on `≈`-equal inputs, so congruence/associativity are not `rfl`; the resolution is a **linear-bound
  criterion** `Req_of_lin_bound` (`|xₙ − yₙ| ≤ C/(n+1)` for any constant `C` ⟹ `x ≈ y`), built on the
  **generalized Archimedean lemma** `Qarch_gen` and a product-gap engine `Rmul_gap`. This proves
  `Rmul`-congruence (multiplication well-defined on the setoid — the v0.5.0 deferral), `Rmul_assoc`,
  `Rmul_distrib`, `Rmul_one`, `Radd_assoc`; and lifts to `Cmul_assoc`, `Cmul_distrib`, `Cmul_one`,
  `Cadd_assoc` (the bilinear expansions reduce, via the ℝ ring laws, to pointwise re-associations).
- **v0.7.0 (done):** **Cauchy completeness of ℝ.** A *regular sequence of reals* (`RReg`: `X j, X k`
  within `1/(j+1)+1/(k+1)` as reals) converges to **Bishop's diagonal** `Rlim X := n ↦ (X(4n+3))_{4n+3}`
  (the `4n+3` reindex makes the diagonal itself regular), with explicit rate `1/(k+1)` (`Rlim_tendsTo`)
  and uniqueness up to `≈` (`RTendsTo_unique`). Choice-free (the modulus is carried in the data).
- **v0.8.0 (done):** the **first transcendental** — Euler's number `e = Σ 1/i!` — via the exponential
  series, standing on completeness (a series is a regular sequence of partial sums). The rigorous
  rational error bound is the telescoping `U(n) := S(n) + 2/(n+1)!` decreasing, giving
  `S(b) − S(a) ≤ 2/(a+1)!`; reindexing makes the partial sums regular, so `e` is a genuine
  constructive real (and `Pos e`). Factorial built from scratch (core has none).
- **v0.9.0 (done):** the **general exponential `exp(q)` on the rational interval `[0,1]`** — `Σ qⁱ/i!`
  as a constructive real (`Rexp`). It reuses the v0.8.0 machinery almost verbatim; the only new input
  is **termwise domination**: for `q ∈ [0,1]` every power `qⁱ ≤ 1` (`qpow_le_one`), so each term
  `qⁱ/i! ≤ 1/i!` (`expTerm_le`) and the `exp(q)` partial-sum gaps are dominated termwise by those of
  `e` (`expdiff_dom`). Hence the *same* rational tail bound `S_q(b) − S_q(a) ≤ 2/(a+1)!`
  (`expdiff_bound`) and the *same* reindex (`efct_reindex`) prove regularity — no new tail analysis.
  Anchored by `exp 0 ≈ 1` (`Rexp_zero`) and `exp 1 > 0` (`Rexp_one_pos`); rational powers `qpow` built
  from scratch (core has none). Choice-free.
- **v0.10.0 (done):** the **λₙ / RH proof boundary, locked faithfully** (`Li.lean`) — the *analytic
  face* of the same crux `Crux.lean` states geometrically. By **Li's criterion** (Li 1997),
  RH ⟺ `λₙ > 0 ∀ n ≥ 1` (the non-strict `≥ 0` form is the general Bombieri–Lagarias 1999 multiset
  criterion). Pinned BEFORE ζ is built: `LiPositive`/`LiNonneg` are genuine, satisfiable properties
  (`template_liPositive`); the crux `LiCrux λ` on the unconstructed genuine ζ-derived `λ` is OPEN
  (`liPositivityHolds = none`), with a faithfulness caution forbidding the standard traps and the
  **finite-check guard** `liPositive_iff_all_upTo` (the universal `∀ N` that no `decide` reaches — the
  first ~10⁵ λₙ are numerically positive, which is *not* a proof). The Bombieri–Lagarias decomposition
  and the Weil explicit formula (Weil 1952 / Connes 1999) are stated as honest interfaces. Crucially,
  `λₙ^{arith}` and `λₙ^{∞}` have opposite signs, so positivity is a *cancellation* — the open difficulty.
  v0.10.0 also ships **ζ and `λₙ` as exact-bounded objects**: `ExactBoundedReal` (a constructive real as
  a stream of certified rational enclosures of width `2/(n+1)`) is the type `λ : Nat → ExactBoundedReal`
  inhabits, and **`ζ(s)` for integer `s ≥ 2` is built as a concrete such object** (`zeta`, `Σ 1/iˢ` with
  the rigorous tail bound `zetadiff_bound`, `ζ(s) > 0`). *Honest scope:* this ζ is the convergent regime
  `Re(s) > 1` (no zeros, not the critical strip); the analytic continuation and the genuine `λₙ` *values*
  (which need it and `log`) are deferred — only the exact-bounded type and the boundary are shipped now.
- **v0.11.0 (done):** the **order `≤` on ℝ** (`ROrder.lean`) — the foundation the transcendentals need.
  `Rle` (Bishop `xₙ ≤ yₙ + 2/(n+1)`) with reflexivity, `≈`-compatibility, antisymmetry up to `≈`, and
  **transitivity via the Archimedean lemma** (`Qarch_gen` kills the `6/(m+1)` tail of the four-step
  chain); `Rnonneg` canonicalized, with `Rnonneg → 0 ≤ x`.
- **v0.12.0 (done):** ℝ as a constructive **field with powers**, and **`exp` on all of ℝ**. Real powers
  `Rpow` (`Pow.lean`); the reciprocal `1/x` of a positive real via positivity-as-data and division `Rdiv`
  (`Inv.lean`). `exp` (`ExpReal.lean`) is the **diagonal of rational partial sums** `exp(x)_j = S_{R j}(x_{R j})`
  with a single reindex `R j` — the diagonal sequence of *rationals* is itself Bishop-regular
  (`|exp(x)_j − exp(x)_k| ≤ 1/(j+1)+1/(k+1)`), so it is a constructive real directly (no `Rlim` needed).
  Three rational bounds make it rigorous: a geometric **truncation** tail `2Mᵃ⁺¹/(a+1)!`, a uniform
  **Lipschitz** bound, and a **factorial-growth** estimate converting the tail to a `1/(j+1)` reindex —
  all axiom-clean.
- **v0.13.0 (done):** the **transcendentals on ℝ** — `cos`, `sin`, and `log` on positive reals (positivity-as-data).
  `cos`/`sin` (`CosSin.lean`) are the alternating diagonal `Σ(−x²)ⁿ/(2n+off)!`, the alternating term
  dominated by `exp(M²)` (factorial vs. geometric), with `Rcos = RaltReal x 0`, `Rsin = x·RaltReal x 1`.
  `log` (`Log.lean`) is positivity-as-data (the same idiom as the reciprocal `Rinv`): `RlogPos x k` from a
  witness `x_k > 1/(k+1)` **derives** the rational modulus `1/M ≤ x ≤ M` and returns `2·artanh((x−1)/(x+1))`;
  equivalently the explicit-modulus engine `Rlog x M` takes a real presented with a rational modulus
  `1/M ≤ x ≤ M`: the artanh odd series `Σ t^{2n+1}/(2n+1)` is built as a regular diagonal on every
  `[−ρ,ρ]` (`ρ<1`) — geometric telescoping + truncation + Lipschitz, with a **general Bernoulli reindex**
  `ρᵐ ≤ q/(q+m(q−p))` taming the geometric tail — and composed with the Möbius **t-map** `q↦(q−1)/(q+1)`
  (its cleared difference identity, its 2-Lipschitz bound on `x≥0`, and the range bound `|tmap q| ≤ tmap M`
  keeping the artanh argument inside `[−ρ,ρ]`). All axiom-clean. **Axiom-minimization:** the entire proof
  layer is now **choice-free** — `Classical.choice` is eliminated, leaving only `{propext, Quot.sound}`
  (forced by `omega`/`simp`/`Int` core internals), and the honesty gate forbids re-introducing choice.
- **The next phase (the analytic→arithmetic bridge):** the analytic continuation of ζ into the critical
  strip (needs *complex* exp/log, built on the real transcendentals), the genuine `λₙ` realizing the
  v0.10.0 interfaces, and the explicit formula as an exact-arithmetic trace. This phase ends at
  `λₙ > 0 ∀ n` = RH — the open frontier itself, not a brick to be "completed."

Each brick makes more of the analytic half *statable and finitely checkable* — never a proof of the
crux. Proving `λₙ > 0 ∀ n` (Li's criterion) / Weil positivity / the Hodge index on `𝕊` IS RH, and
remains open.
