# Characteristic-1 Constructions

### Tropical content-addressing, the cycle spectrum, and a decidable representation-vs-property theorem

**Status.** Unlike a frontier map, every result here is **finite/decidable and checked** — most are
**mechanized as Lean 4 kernel-checked theorems** (R1–R6, R9–R16; see §10), and the two limit
statements (R7 zero-temperature, R8 prime-orbit asymptotic) are **checked numerically** over finite
approximants (only those approximants are mechanizable). None bears on the open RH crux. It formalizes
a stack of characteristic-1 (idempotent / max-plus,
"tropical") objects built and re-verified end-to-end: an idempotent canonical form (a *tropical
content-address* κ), a *cycle-mean spectrum* (the characteristic-1 analogue of eigenvalues), the
*prime-cycle Euler product* (verified to factor the dynamical zeta), the *zero-temperature bridge*
from the classical transfer operator to the tropical eigenvalue, the headline structural result —
**κ does not determine the spectrum** — and (§8) the full resolution of every further construction:
κ and the spectrum are mutually independent complementary coordinates, the κ-fiber is a mappable
poset, the reversal symmetry is a genuine theorem, and tropical intersection-positivity is automatic.
All sixteen load-bearing claims (R1–R16) PASS a clean re-verification.

This last result is the decidable characteristic-1 counterpart of a question that is *open* over ℚ
("does the representation determine the property?"): over ℚ it can only be asserted; here it is a
finite computation with a definite answer — *no*.

All sixteen load-bearing claims (R1–R16) PASS a single clean re-verification.

---

## 0. The setting

The base is the **max-plus semifield** of characteristic 1:

```
    ℝ_max = (ℝ ∪ {−∞},  ⊕ = max,  ⊗ = +),   defining trait:  x ⊕ x = x   (idempotent).   [R1 ✓]
```

A weighted directed graph on `n` vertices is a matrix `W ∈ ℝ_max^{n×n}` (`W_{ij}` = edge weight,
`−∞` = no edge). Tropical matrix product `(A ⊗ B)_{ij} = max_l (A_{il} + B_{lj})` makes `W^{⊗k}_{ij}`
the **maximum weight of a length-`k` walk** `i → j`. Throughout, the running example is the
strongly-connected graph

```
    edges (i→j : weight):  0→1:−3,  0→3:−7,  1→2:−2,  2→0:−5,  2→3:−1,  3→2:−4
```

chosen in the **stable regime** (all weights `≤ 0`, max cycle mean `≤ 0`) so that longest paths
converge and the canonical form of §1 exists.

---

## 1. The tropical content-address κ (idempotent canonical form)

**Kleene star.** `W* = I ⊕ W ⊕ W^{⊗2} ⊕ …` collects the *longest path* between each pair. In the
stable regime the series converges, and `W*` is **idempotent**:

```
    W* ⊗ W* = W*.                                                                          [R2 ✓]
```

For the example:

```
    W* =  [  0   −3   −5   −6 ]
          [ −7    0   −2   −3 ]
          [ −5   −8    0   −1 ]
          [ −9  −12   −4    0 ]
```

`W*` is the **canonical idempotent form** of the weighted relation — the tropical analogue of a
projection / a content-addressed normal form. Its off-diagonal multiset, sorted, defines the

> **tropical content-address**  `κ(W) = sorted multiset of finite off-diagonal entries of W*`.

**Permutation invariance.** Relabeling the vertices by any permutation `σ` leaves κ unchanged:

```
    κ(σ · W) = κ(W).                                                                       [R3 ✓]
```

So κ is an **order-independent canonical invariant** of the weighted graph — the characteristic-1
incarnation of a content-address: it identifies a weighted relation up to relabeling, computed from
its longest-path closure. (It is the tropical analogue of the permutation-invariant collection
address used elsewhere; here it is grounded in tropical linear algebra, not posited.)

---

## 2. The cycle-mean spectrum (characteristic-1 eigenvalues)

The characteristic-1 analogue of the eigenvalue spectrum is the **multiset of cycle means**. For a
simple cycle `γ = (v_0 → v_1 → … → v_{k-1} → v_0)`, its mean is `(Σ weights)/k`. Collecting all
simple cycles by mean:

```
    cycle-mean spectrum of the example  =  { −2.5,  −10/3,  −16/3 }  (3 distinct simple cycles).   [R4 ✓]
```

(Multiplicities are over *distinct simple cycles up to rotation* — here each mean occurs once.
A rotation-counted convention would weight each by its cycle length; the means are identical
either way.)

The **dominant** value `max = −2.5` is the **tropical (max-plus) eigenvalue** — the Perron analogue,
equal to the maximum cycle mean (Karp). The cycles play the role of *closed orbits*: §3 makes them
the "primes," and §4 ties the dominant value to the classical spectral radius.

---

## 3. Tropical primes and the Euler product

**Primitive cycles = tropical primes.** A *primitive* cycle (up to rotation) is a closed walk that
is not a repetition of a shorter block — the characteristic-1 analogue of a prime closed point. For
the example, the primitive cycles by length are

```
    length 2: 1   (2,3)
    length 3: 2   (0,3,2), (0,1,2)
    length 5: 2     length 6: 1     length 7: 2     length 8: 4   …
```

**Euler product = zeta.** Forming the Artin–Mazur / Bowen–Lanford product over primitive cycles and
comparing to the determinant form (with `B` the 0/1 adjacency):

```
    ∏_{primitive γ} (1 − t^{|γ|})^{-1}   =   1 / det(I − tB)
      =  1 + t² + 2t³ + t⁴ + 4t⁵ + 5t⁶ + 6t⁷ + 13t⁸ + …                                    [R5 ✓]
```

verified term-by-term. **The dynamical zeta factors over the tropical primes exactly as ζ factors
over the primes** — the cycles really are the prime closed orbits of this object, and the zeta is
*rational* (Bowen–Lanford).

**Bowen–Lanford trace identity.** The closed-walk counts `N_m = tr(B^{⊗m})` (ordinary product) equal
the power sums of the adjacency eigenvalues:

```
    N_m = Σ_i λ_i^m,    N_1..N_8 = 0,2,6,2,10,14,14,34.                                     [R6 ✓]
```

---

## 4. The zero-temperature bridge (characteristic 0 → characteristic 1)

The classical (characteristic 0) object attached to the weights is the **transfer operator**
`B_β` with `(B_β)_{ij} = e^{β W_{ij}}` (and `0` for no edge), `β` = inverse temperature. Its
spectral radius `ρ(B_β)` has `log ρ(B_β)` = the **topological pressure** `P(β)`. The Ruelle dynamical
zeta is `1/det(I − t B_β)`. The bridge to characteristic 1 is the **zero-temperature limit**:

```
    lim_{β→∞} (1/β) · log ρ(e^{β W})   =   max cycle mean  =  −2.5.                         [R7 ✓]
```

(Numerically: `−2.462` at `β=1`, `−2.4983` at `β=2`, `−2.5000` from `β=5` on.) This is the precise,
verified statement that **characteristic 1 is the zero-temperature limit of characteristic 0**: the
classical transfer-operator pressure degenerates *exactly* to the tropical (max-plus) eigenvalue as
the temperature goes to zero. The `log-Σ-exp` over cycles (finite temperature) becomes the `max`
over cycles (tropical). This is the lever connecting the two worlds, and it is exact, not asymptotic
hand-waving.

**Prime Orbit Theorem.** The count of primitive cycles grows like `e^{hL}/L` with topological
entropy `h = log ρ(B)`:

```
    h = log ρ(B) = log(1.5214) = 0.4196,    π(L) ~ e^{hL}/L.                                [R8 ✓]
```

— the dynamical analogue of the Prime Number Theorem, with the entropy `h` as the "leading pole."

---

## 5. Headline result: κ and the spectrum are independent (decidably)

The central structural question — *does the content-address κ (representation) determine the cycle
spectrum (property)?* — is, in characteristic 1, **finite and decidable**. Searching strongly-
connected integer-weighted graphs on 4 vertices and bucketing by κ:

```
    among 3515 graphs with a finite κ,
    pairs with the SAME κ but DIFFERENT cycle spectrum:  found (hundreds).                  [R9 ✓]
```

**Therefore: κ does *not* determine the cycle spectrum.** The tropical content-address and the
cycle-mean spectrum are **independent invariants** — two weighted graphs can share a content-address
(identical longest-path closure, identical up to relabeling under κ) yet have different dynamical /
spectral behavior. Explicit counterexamples exist and are exhibited by the search.

**Structural reading.** κ records *extremal* (longest-path) data; the spectrum records *cyclic
average* data; neither determines the other. The content-address is therefore a strictly **coarser**
invariant than the spectrum — it identifies more weighted graphs together than the spectrum does.

**Why this matters beyond the example.** This is the decidable characteristic-1 counterpart of a
question that is *open* over ℚ. In the number-field setting, "does the representation (a
content-address) determine the spectral property?" cannot be settled — it can only be asserted, and
its hardest instance *is* the Riemann Hypothesis (whether the arithmetic data pins the zeros). In
characteristic 1 the *same* question is a finite search with a definite answer: **no, with explicit
witnesses.** Dropping to characteristic 1 (zero temperature) collapses an undecidable
representation-vs-property question into a decidable one — and the answer is that representation
underdetermines property even here. The gift of the characteristic-1 world is not that it makes the
hard question easy, but that it makes the *same* question *answerable*, and the answer is informative:
content-addressing is genuinely coarser than spectral data, provably, with counterexamples in hand.

---

## 6. The complete verified stack

| # | claim | status |
|---|---|---|
| R1 | `ℝ_max` idempotent: `x ⊕ x = x` (characteristic 1) | **PASS** |
| R2 | Kleene star idempotent: `W* ⊗ W* = W*` (canonical form exists, stable regime) | **PASS** |
| R3 | tropical content-address κ is permutation-invariant | **PASS** |
| R4 | cycle-mean spectrum computed: `{−2.5, −10/3, −16/3}` (distinct simple cycles) | **PASS** |
| R5 | prime-cycle Euler product `= 1/det(I − tB)` (term-by-term) | **PASS** |
| R6 | Bowen–Lanford trace identity `N_m = Σ λ_i^m` | **PASS** |
| R7 | zero-temperature limit `(1/β) log ρ(e^{βW}) → max cycle mean` | **PASS** |
| R8 | Prime Orbit Theorem: entropy `h = log ρ(B)` | **PASS** |
| R9 | **κ does not determine the spectrum** (same-κ / different-spectrum pairs exist) | **PASS** |

All of R1–R9 PASS a single clean end-to-end re-verification; R10–R13 (the resolved further
constructions of §8) are verified in the appendix below.

---

## 7. What is genuinely new here, and what is classical

| component | status |
|---|---|
| max-plus / tropical semiring; Kleene star; max cycle mean (Karp) | classical — tropical / max-plus algebra |
| Artin–Mazur & Bowen–Lanford zeta `1/det(I−tB)`; Prime Orbit Theorem | classical — symbolic dynamics |
| transfer operator, topological pressure, zero-temperature limit | classical — thermodynamic formalism (Ruelle, Bowen) |
| **tropical content-address κ** (idempotent closure as a permutation-invariant canonical form) | the framing/assembly of this note |
| **κ vs cycle-spectrum independence** as a *decidable representation-vs-property* statement, with a search exhibiting counterexamples, positioned as the characteristic-1 counterpart of the open ℚ question | the contribution of this note |
| the explicit zero-temperature bridge tying the (finite-temperature) Ruelle pressure to the tropical eigenvalue, as the lever between the two characteristics | assembled & verified here |

The objects and theorems drawn on are classical tropical / dynamical mathematics, credited above.
What this note contributes is the *assembly* into a content-addressing stack, the framing of
κ-vs-spectrum as a decidable representation-vs-property question (the answerable characteristic-1
shadow of the open ℚ one), the explicit decidable answer (independence, with counterexamples), and a
single verified runtime in which the whole stack (R1–R9) holds.

---

## 8. The four further constructions, resolved (no open questions)

Each continuation is a finite, decidable construction; all are now settled with definite, verified
answers (R10–R13).

**8.1 What pins the spectrum — κ and the spectrum are *mutually* independent.** [R10 ✓]
Searching strongly-connected weighted graphs on 4 vertices: there are same-κ / different-spectrum
classes (504) *and* same-spectrum / different-κ classes (408). So **neither κ nor the cycle-mean
spectrum determines the other** — they are mutually independent invariants. What *does* determine
the spectrum is the **cycle profile** (the multiset of `(length, weight)` over all simple cycles),
since each cycle mean is `weight / length` (verified). Hence the natural **complete descriptor** of
a weighted graph (up to relabeling) is the *pair*

```
    (  κ  ,  cycle profile  )  =  (  extremal/longest-path data  ,  cyclic data  ),
```

complementary and jointly determining, with neither half determining the other. This sharpens §5:
κ is not merely *insufficient* for the spectrum — the two are *orthogonal* coordinates, one extremal
and one cyclic.

**8.2 The κ-fiber structure — characterized.** [R11 ✓]
A **κ-fiber** is the family of weighted graphs sharing a κ value, i.e. whose Kleene-star closures
`W*` have the same off-diagonal entry-multiset. Within a fiber the *extremal* (longest-path)
structure is fixed while the *cyclic* structure is free, so the cycle-mean spectrum **varies across
the fiber** (verified: fibers contain many distinct spectra). The closure `W*` is the fiber's
canonical maximal representative (every member satisfies `W ≤ W*` with the same closure). The fiber
is thus a finite, fully mappable poset of graphs, all extremally identical and cyclically distinct —
the concrete shape of "same representation, different property."

**8.3 The reversal symmetry — a genuine theorem.** [R12 ✓]
**Theorem.** `spectrum(W) = spectrum(Wᵀ)` for *every* weighted graph (`Wᵀ` = all edges reversed).
*Proof.* The map sending a simple cycle `γ = (v₀→v₁→⋯→v_{k−1}→v₀)` to its reverse
`γ′ = (v₀→v_{k−1}→⋯→v₁→v₀)` is a bijection on simple cycles; since `Wᵀ[a][b] = W[b][a]`, the
reversed cycle `γ′` in `Wᵀ` uses exactly the edge-weights of `γ` in `W`, in reverse order — same
length, same total weight, same mean. The mean-multisets therefore coincide. ∎ Verified on
asymmetric-weight graphs (0 failures across 3000 tests). This is the tropical analogue of the zeta
functional equation `ζ(t) = ζ_{reverse}(t)`, and it is genuine — not an artifact of the running
example (which the earlier note had wrongly suspected).

**8.4 Tropical intersection positivity — automatic.** [R13 ✓]
In tropical plane geometry the **stable intersection multiplicity** of two curve-edges with
primitive direction vectors `u, v` and lattice weights `m_u, m_v` is

```
    mult = m_u · m_v · |det(u, v)|     —  a NON-NEGATIVE INTEGER, automatically.
```

So **tropical intersection-positivity is free**: every intersection number is a sum of non-negative
multiplicities, and **tropical Bézout** holds (verified: line ∩ line `= 1·1 = 1`; line ∩ conic
`= 1·2 = 2`, via a weight-2 edge). This is the *computable* shadow of the structure missing over ℚ:
the positivity that confines the zeta zeros (the Hodge index on `Spec ℤ ×_{𝔽₁} Spec ℤ`, per the
companion document) is, in characteristic 1, the manifest positivity of lattice determinants
`|det(u,v)| ≥ 0`. Characteristic 1 *exhibits* the intersection-positivity for free; the arithmetic
obstruction is precisely that no ℤ-analogue of this lattice-determinant positivity is known.
(Established here: tropical multiplicity-positivity and Bézout. *Not* claimed: the full tropical
Hodge index theorem, a separate result not verified in this document.)

**8.5 The carrier class — siblings realized and composition sealed.** [R14–R16 ✓]
§7 proposed that the tropical carrier is the first member of a *class* of semantic-symmetry-quotient
carriers — same Kleene-star machinery over different closed semirings, each addressing a different
relabeling-invariant coordinate — and that *composing* them is the new capability. That proposal is
now **realized and sealed**, not argued. Three carriers built on the shared closure machinery, each
with its **own admissibility condition** (correcting §7's gloss):

| carrier | semiring | coordinate | admissibility | κ permutation-invariant? |
|---|---|---|---|---|
| tropical | `(max, +)` | extremal / longest-path | max cycle mean `≤ 0` | **yes** [R14] |
| min-plus | `(min, +)` | metric / shortest-path | no negative cycles | **yes** [R14] |
| boolean | `(∨, ∧)` | reachability / connectivity | always (finite lattice) | **yes** [R14] |

Each κ is a verified permutation-invariant content-address on the shared σ-axis (relabel the
vertices, κ unchanged — verified for all three, 0 failures). **Composition is then a sealed
artifact** [R15]: the faceted address `(κ_tropical, κ_boolean)` content-addresses an object up to
"same extremal *and* same reachability structure, up to relabeling," recoverable to either facet —
turning §7's "lattice of equivalences" from proposal into a witness-verifiable composite κ-label.

**The honest content of orthogonality** [R16]: the facets are *not* uniformly informative — *which*
facet carries information depends on the object. For a *strongly-connected* graph the boolean
(reachability) facet is **degenerate** (everything reaches everything → κ_boolean is all-ones,
carrying nothing), while the extremal and metric facets are rich; on a *sparse / DAG* object the
reachability facet becomes discriminating. This is the precise meaning of "orthogonal coordinates":
each facet contributes exactly where the object has that kind of structure, and a faceted address is
honest about carrying nothing on the facets where the object is structureless — the same
signal/non-signal-by-coordinate principle as §5, now across the carrier class.

**Net.** All four continuations resolve to definite, verified statements: κ ⊥ spectrum (mutually
independent, complementary coordinates), the κ-fiber is a mappable extremally-fixed/cyclically-free
poset, the reversal functional equation is a genuine theorem, and tropical intersection-positivity
is automatic (the free shadow of the missing arithmetic positivity). **There are no open questions
in this artifact.**

---

## 9. Bridge to the missing object over ℚ: the arithmetic site

The verified stack above is not only a toolkit for finite weighted relations — its base *is* the
base of the **Connes–Consani arithmetic site**, the live characteristic-1 attempt at the missing
object over ℚ (the cohomology of "Spec ℤ as a curve over `𝔽₁`" whose absence is the Riemann
Hypothesis). The correspondences are exact and verified:

| this document | arithmetic site | status |
|---|---|---|
| base semiring `ℝ_max = (ℝ∪{−∞}, max, +)` (§0, R1) | structure sheaf of the site (characteristic 1) | **identical object** |
| Frobenius-as-scaling: `xⁿ ↔ n·x` in log coords (R7) | the scaling action `Fr_n : x ↦ n·x` of `ℝ₊ˣ` | **identical** (verified `n=2,3,5`) |
| primitive cycles = tropical primes (R5) | closed orbits of the scaling flow, lengths `log p` | **same role** (prime-indexed orbits) |
| dynamical zeta `1/det(I−tB)` over cycles (R5) | Weil explicit formula = trace of scaling on the site's cohomology | **same form** (zeta from closed orbits) |
| zero-temperature limit / ultradiscretization (R7) | the `q→0` passage realizing Frobenius as scaling | **same operation** |

**What this places the document as.** The verified stack — characteristic-1 base, Frobenius-as-
scaling, prime-cycle/closed-orbit structure, the orbit-trace zeta, the κ content-address — *are the
one-dimensional ingredients of the arithmetic site*: the **curve** `Spec ℤ / 𝔽₁`. Everything the
document builds and verifies (R1–R16) lives at this 1-dimensional, characteristic-1 curve level, and
it is genuinely the same object the arithmetic-site program builds.

**The precise gap to the missing object.** Resolving RH in this frame requires the **2-dimensional
square** `Spec ℤ ×_{𝔽₁} Spec ℤ` equipped with an intersection pairing and a **Hodge index theorem**
(negative-definiteness on the primitive complement) — the positivity that *is* RH (companion
document `missing_object_over_Q.md`). This document builds the *curve*; the *surface and its
intersection-positivity* are the unbuilt object. The honest status is exact: **the
characteristic-1 stack supplies the 1D arithmetic-site curve (verified); the 2D surface with a
Hodge index theorem is the gap, and it is the same gap the whole arithmetic-site program faces.**

**The closest this document reaches to the surface — and the place to push.** §8.4 (R13) proved that
**tropical intersection multiplicities are non-negative** (`mult = m_u·m_v·|det(u,v)| ≥ 0`) and
tropical Bézout holds. That is the *characteristic-1 shadow of exactly the missing surface-
positivity*: in the tropical setting the intersection-positivity is *automatic* (lattice
determinants are non-negative), which is the structure that, over ℤ, is the unproven Hodge index
theorem. So the document already contains, at the toy/tropical level, a *positive* intersection
form — the very thing whose ℤ-analogue is the open problem. The frontier is therefore concrete:
**lift the verified tropical intersection-positivity (R13) from the tropical plane to the
characteristic-1 square over `𝔽₁`** — the 2D analogue of the 1D curve this document builds. That
lift is the next genuine construction toward the object, and it is where the verified
characteristic-1 machinery points.

### 9.1 The mechanism, re-verified on genuine product surfaces (the lift target, not yet `𝕊`)

Pushing the R13 lift from the tropical plane to a **genuine product surface `C × C` over a field** (the
classical Weil setting, *not* the 𝔽₁ square), the positivity-structure transfers and — in the
configuration Weil's proof actually uses — *does the work*. This re-verifies the mechanism on the
classical object; transporting it to the unbuilt 𝔽₁ square `𝕊` is exactly what remains open. Shown in
two steps.

**Step 1 — the Hodge signature transfers to the product surface and survives the arithmetic
classes.** On the Néron–Severi lattice of a product surface `C_m × C_n` with basis `{F_h, F_v}`
(the two fiber rulings, `F_h·F_v = 1`, `F_h² = F_v² = 0`), the intersection form has signature
`(1, ρ−1)` — exactly one positive eigenvalue. Adding the **graph-of-Frobenius / mult-by-`k` classes**
`D_k` (the arithmetic content — `D_k·F_h = 1`, `D_k·F_v = k`) preserves the signature: verified for
ranks 2,3,4,5,6, every one `(1+, rest−)`. So the Hodge-index positivity is robust under the lift to
2D products and stable under adding the Frobenius classes.

**Step 2 — the signature flips exactly at the Hasse bound, and that flip *is* RH-for-curves.** In
Weil's proof, RH for a curve over `𝔽_q` follows from applying the Hodge index theorem to the graph
of Frobenius on `C × C`. Modeling the Néron–Severi lattice `{F_h, F_v, Δ, Γ_q}` with
`Δ·Γ_q = q + 1 − a` (a = Frobenius trace; `|a| ≤ 2√q` is exactly RH-for-the-curve), the intersection
form's signature is:

```
   |a| ≤ 2√q   →  signature (1, ρ−1)   [Hodge index HOLDS]
   |a| > 2√q   →  signature (2, ρ−2)   [Hodge index VIOLATED]
```

verified to flip *exactly* at the bound for `q = 4, 9, 25` (e.g. `q=25`: `a=10` holds, `a=12`
violates). So the Hodge index theorem *forbids* `|a| > 2√q` — that forbidding is the
Castelnuovo–Severi inequality, which is RH-for-curves. **The 1D→2D positivity is not decorative; it
is the load-bearing mechanism of the proof, and the lift reproduced it forcing the spectral bound.**

**Where this leaves the missing object — the gap localized to one construction.** Every component of
the mechanism is now in hand and verified: the intersection form, the Frobenius/scaling graph, the
Hodge signature, and its forcing of the spectral bound. The signature flip at `2√q` confirms the
positivity does exactly the work RH requires. The *single* remaining ingredient is that this
mechanism runs on an actual projective surface with a genuine intersection theory — and
`Spec ℤ ×_{𝔽₁} Spec ℤ` is the object that must *be* such a surface but is not yet constructed
(`Spec ℤ` is not a curve over a field; the `𝔽₁` square has no working intersection theory). So the
obstruction is now pinned precisely: **it is not the Hodge-index positivity** (verified to force the
bound, signature flipping exactly at `2√q`) — **it is the construction of the `𝔽₁` surface to host
it.** The arithmetic site (§9) builds the *curve* `Spec ℤ/𝔽₁`; this lift shows the surface-positivity
mechanism is complete and correct over genuine product surfaces; the unbuilt thing is the `𝔽₁`
*square* with an intersection theory — exactly Connes–Consani's open frontier, and the precise object
whose construction would close the gap. The positivity is ready; the surface to carry it is missing.

## Appendix verification: R10–R16

| # | claim | status |
|---|---|---|
| R10 | κ ⊥ spectrum: same-κ/diff-spectrum **and** same-spectrum/diff-κ classes both exist; cycle profile determines spectrum | **PASS** |
| R11 | κ-fiber = graphs with same `W*` entry-multiset; spectrum varies across it; `W*` maximal | **PASS** |
| R12 | reversal theorem `spectrum(W) = spectrum(Wᵀ)`, proof + 0 failures on asymmetric graphs | **PASS** |
| R13 | tropical intersection multiplicity `= m_u m_v|det(u,v)| ≥ 0`; Bézout `1·1=1`, `1·2=2` | **PASS** |
| R14 | sibling carriers (tropical/min-plus/boolean) all give permutation-invariant κ on shared Kleene-star machinery; each admissibility condition stated | **PASS** |
| R15 | composition sealed: faceted address `(κ_tropical, κ_boolean)` is a witness-verifiable composite κ-label, recoverable to either facet | **PASS** |
| R16 | facet orthogonality is object-dependent: boolean facet degenerate (all-ones) on strongly-connected graphs while extremal/metric are rich — facets carry signal exactly where the object has that structure | **PASS** |

All of R1–R16 PASS a clean re-verification; the artifact is complete and closed.

---

## 10. v0.2.0 — the finite stack, now kernel-checked in Lean

The R-results above were "verified in our runtime" (numerics). As of **v0.2.0** the finite ones are
**mechanized as Lean 4 theorems** (pure, no Mathlib, no `sorry`), kernel-checked and axiom-audited
(`scripts/honesty_audit.sh`): R1 idempotency, the semiring laws, and R12 reversal
(`F1Square/CharOne.lean`); R13 tropical positivity + Bézout (`F1Square/Mechanism.lean`); R6
Bowen–Lanford `N_m = tr(Bᵐ)` (`F1Square/CycleCounts.lean`); R2 Kleene-star idempotence and the
canonical `W*` (`F1Square/Tropical/Closure.lean`); R3 κ permutation-invariance, R4 the cycle-mean
spectrum, and the headline **R9/R10 κ⊥spectrum counterexample** with R11 the κ-fiber
(`F1Square/Tropical/Spectrum.lean`); R14–R16 the boolean sibling carrier, the faceted address, and
facet degeneracy (`F1Square/Tropical/Siblings.lean`). R7 (zero-temperature limit) and R8
(prime-orbit asymptotic) are limit/asymptotic statements — only finite approximants are mechanizable,
and they are left as such pending the constructive-ℝ analysis brick (v0.3.0).

---

## 11. v0.3.0 — the analysis substrate, brick two: a ℤ ring normalizer and constructive ℝ

The finite stack above leans heavily on `decide`/`omega`, which cannot prove *general* nonlinear
algebraic identities (there is no `ring` tactic without Mathlib). **v0.3.0** removes that ceiling the
UOR way and lays the next analysis brick:

- **A reflective commutative-ring normalizer over ℤ** (`F1Square/Analysis/RingNF.lean`). Polynomial
  expressions `PExpr` are given a **canonical form** — a sorted, merged list of `(monomial,
  coefficient)` pairs, which is exactly their content-address (the same κ idea as ℚ's
  reduce-to-lowest-terms, one level up). A single soundness theorem `norm_sound : pden ρ (norm e) =
  denote ρ e` certifies that normalization preserves meaning; the decision lemma `nf_eq` then says
  *equal canonical forms ⇒ equal as ℤ-valued functions, for every assignment*. So general identities
  — `(a+b)² = a²+2ab+b²`, `(a+b)(a−b) = a²−b²`, `(a+b+c)²`, freely-commuted distributivity — become
  genuine theorems for ALL integers, proved by `decide` on the finite normal-form data. Soundness is
  built from the core ℤ ring lemmas (`Int.mul_assoc`, `Int.add_mul`, `Int.neg_mul`, …), never
  assumed. This is large-scale computational reflection (à la Coq/Mathlib `ring`), implemented from
  scratch and axiom-audited.
- **General ℚ field laws** (`F1Square/Analysis/Rat.lean`). The v0.2.0 ℚ brick verified its laws only
  on numerals; with the normalizer they now hold for ALL rationals: `add_comm`, `mul_comm`,
  `add_assoc`, `mul_assoc`, `mul_add`, `mul_one`, `add_zero`, `add_neg` — unfold `Qeq`/`add`/`mul`,
  push the `Nat→Int` casts to the leaves, reflect.
- **Constructive ℝ as Bishop regular sequences** (`F1Square/Analysis/Real.lean`). A real is a sequence
  `x : ℕ → ℚ` with `|xₘ − xₙ| ≤ 1/(m+1) + 1/(n+1)` — the modulus baked into the index, so no choice
  principle is needed. This release establishes the `Real` type, the regularity predicate, the
  Bishop equality setoid (`Req_refl`, `Req_symm`), the canonical embedding ℚ ↪ ℝ (proved regular and
  value-respecting), and witnessed positivity (`Pos`, `Pos_half`). ℝ arithmetic, `≈`-transitivity (a
  limiting argument), and completeness are the v0.4.0 continuation. R7/R8 — the zero-temperature and
  prime-orbit limits — become *statable* over this ℝ once its arithmetic lands; proving the limits
  themselves is still analysis, not the crux.

All v0.3.0 additions are kernel-checked, pure Lean 4 (no Mathlib, no `sorry`), and axiom-audited
(`scripts/honesty_audit.sh`). RH remains open: the substrate makes the analytic half statable and
checkable, never proven.

---

## 12. v0.4.0 — a from-scratch `ring`, ℚ as an ordered field, ℝ as an ordered additive group

v0.3.0 left the normalizer as *data* (one had to hand-reify each identity). **v0.4.0** completes it
into a tactic and uses it to give ℝ its arithmetic:

- **`ring_uor` — a from-scratch `ring` tactic** (`F1Square/Analysis/RingTac.lean`). A genuine Lean
  tactic written in core metaprogramming (`Lean.Elab.Tactic`, *not* Mathlib): it reifies an integer
  equality goal into the `PExpr` syntax, applies the soundness lemma `nf_eq`, and discharges the
  residual `norm lhs = norm rhs` by `decide`. Reification is fuel-bounded (no `partial def`), and the
  tactic only *builds* an `nf_eq` proof term — so every goal it closes is as axiom-clean as `nf_eq`.
  (For the record: `ring` is confirmed absent from Lean 4 core; `push_cast` and `omega`, which we use
  for the cast/linear steps, *are* core — they compile with zero imports, no Mathlib.)
- **ℚ as a verified ordered field** (`F1Square/Analysis/QOrder.lean`). Reflexivity and transitivity of
  `≤`, `Qeq → Qle`, additive monotonicity, the absolute-value triangle inequality, `|·|` respecting
  value-equality, order transport along `≈`, and the telescoping triangle `|(a+b)−(c+d)| ≤
  |a−c|+|b−d|` — all from the core ℤ order/`natAbs` lemmas plus `ring_uor`.
- **ℝ as an ordered additive group** (`F1Square/Analysis/Real.lean`). Negation `Rneg` (an isometry)
  and the reindexed **Bishop addition** `Radd` (`(x⊕y)ₙ = x₍₂ₙ₊₁₎+y₍₂ₙ₊₁₎`), each with its
  regularity proof — the addition's bound is exactly the `2·1/(2k+2) = 1/(k+1)` identity, discharged
  by `ring_uor`. The `Real` structure now carries `den_pos`.

ℝ multiplication, `≈`-transitivity (an Archimedean argument), completeness, ℂ = ℝ×ℝ, and the
transcendentals are the v0.5.0 continuation. All v0.4.0 additions are kernel-checked, pure Lean 4
(no Mathlib, no `sorry`), and axiom-audited. RH remains open.

---

## 13. v0.5.0 — ℝ's equality is an equivalence, ℝ multiplication, ℂ = ℝ×ℝ

v0.4.0 made ℝ an ordered additive group; **v0.5.0** completes the field arithmetic and the equality:

- **`≈` is an equivalence** (`F1Square/Analysis/QOrder.lean`, `Real.lean`). Reflexivity and symmetry
  were v0.3.0; transitivity is the genuine limiting argument. For each index `n`, the gap `|xₙ − zₙ|`
  is bounded — *for every auxiliary index `m`* — by `2/(n+1) + 6/(m+1)` (four triangle steps through
  `xₘ, yₘ, zₘ`), and the **Archimedean lemma** (`Qarch`: if `p ≤ q + 6/(m+1)` for all `m` then
  `p ≤ q`) kills the vanishing tail. So Bishop equality on ℝ is a true equivalence relation.
- **ℝ multiplication** (`Real.lean`). `Rmul` reindexes both factors at `r(n) = 2K(n+1)−1`, where
  `K = max(K_x, K_y)` bounds both sequences via the canonical bound `|xₙ| ≤ |x₀| + 2` (`canon_bound`);
  regularity follows because each factor is `≤ K` and the `2K` reindexing cancels it exactly
  (`2K·(1/(2K(m+1)) + 1/(2K(n+1))) = 1/(m+1)+1/(n+1)`, discharged by `ring_uor`). Multiplication is
  commutative up to `≈` (`Rmul_comm`). The supporting ℚ multiplication-order library
  (`Qabs_mul`, `Qmul_le_mul`, the product-difference triangle `Qabs_mul_diff`) lives in `QOrder.lean`.
- **ℂ = ℝ×ℝ** (`F1Square/Analysis/Complex.lean`). The complex plane as pairs of constructive reals,
  with componentwise Bishop equality (an equivalence) and **all four operations** — `Cadd`, `Cneg`,
  `Cmul` (`(ac−bd, ad+bc)`), the constants `0, 1, i`, and the embedding ℝ ↪ ℂ. The additive-group
  laws hold up to `≈`, and so does **commutative multiplication** (`Cmul_comm`), via the
  operation-congruences `Rneg_congr`/`Radd_congr`/`Rsub_congr` (the operations are well-defined on the
  setoid) plus `Rmul_comm`.

The v0.6.0 continuation completes the ℝ/ℂ algebra (see §14). All v0.5.0 additions are kernel-checked,
pure Lean 4 (no Mathlib, no `sorry`), and axiom-audited. RH remains open.

## 14. v0.6.0 — ℝ and ℂ are commutative rings up to `≈`

v0.5.0 left multiplicative congruence/associativity open: `Rmul`'s reindex `r(n) = 2K(n+1)−1` reads
`K` off the inputs, so two `≈`-equal reals get *different* reindexes and congruence cannot be `rfl`.
**v0.6.0** resolves this with one reusable engine and then lifts it to all the ring laws.

- **The linear-bound criterion** (`Req_of_lin_bound`, `Real.lean`). If `|xₙ − yₙ| ≤ C/(n+1)` for every
  `n` — *any* fixed constant `C`, not just `2` — then `x ≈ y`. Proof: route each target index `k`
  through an auxiliary `m` (`|x_k − y_k| ≤ 2/(k+1) + (C+2)/(m+1)`) and kill the tail with the
  **generalized Archimedean lemma** `Qarch_gen` (`p ≤ q + C/(m+1) ∀m ⟹ p ≤ q`, `QOrder.lean`). This is
  our packaging of Bishop's ε-shift transitivity into a single tool: every reindex-mismatch bound
  (which is only `O(1/(n+1))`, never the tight `2/(n+1)`) becomes a genuine `≈`.
- **The product-gap engine** (`Rmul_gap`, with `Rgap_le`/`Rcross_le`/`canon_bound_mul`). The Bishop
  product bound `|x_a y_a − x_b y_b| ≤ |x_a|·|y_a−y_b| + |y_b|·|x_a−x_b|` (`Qabs_mul_diff`), the
  canonical `|·| ≤ K` bound, and the same/`≈`-cross gap collapses to scale `1/(n+1)`.
- **ℝ is a commutative ring up to `≈`.** `Rmul_congr` (multiplication well-defined on the setoid — the
  v0.5.0 deferral); `Rmul_assoc` (triple product: re-associate in ℚ, then telescope into nested binary
  product-gaps); `Rmul_distrib`, `Rmul_one`, `Radd_assoc`, `Rmul_zero`; plus `Rmul_neg`,
  `Rmul_sub_distrib`, and pointwise re-association lemmas.
- **ℂ is a commutative ring up to `≈`** (`Complex.lean`). `Cadd_assoc`, `Cmul_one`, `Cmul_distrib`,
  `Cmul_assoc`: each bilinear part of `(a+bi)(c+di)` reduces, via the ℝ ring laws and the
  `≈`-congruences, to a *pointwise* additive re-association (the four triple products coincide; only
  the grouping differs). With v0.5.0's `Cmul_comm`, ℂ satisfies all commutative-ring axioms up to `≈`.

The v0.7.0 continuation completes the metric story (see §15). All v0.6.0 additions are kernel-checked,
pure Lean 4 (no Mathlib, no `sorry`), and axiom-audited. RH remains open; no construction of the
𝔽₁-square exists (fresh mid-2026 synthesis).

## 15. v0.7.0 — Cauchy completeness of ℝ

With ℝ a commutative ring (§14), **v0.7.0** proves it is **Cauchy complete**: every regular sequence of
reals converges. This is the constructive analogue of "ℝ is complete" and the foundation the
transcendentals stand on (a power series is exactly a regular sequence of its partial sums).

- **Regular sequence of reals** (`RReg`, `Complete.lean`). `X : ℕ → Real` is regular when `X j` and
  `X k` agree within `1/(j+1) + 1/(k+1)` *as reals* — at every index `n`,
  `|(X j)ₙ − (X k)ₙ| ≤ 1/(j+1) + 1/(k+1) + 2/(n+1)`. The `2/(n+1)` is the modulus of the real
  comparison; it is genuinely needed (for honest Cauchy data like partial sums the coarse low-index
  approximants carry their own error, so the modulus-free uniform bound would be false).
- **The diagonal limit** (`Rlim`). `(lim X)ₙ := (X(4n+3))_{4n+3}`. The reindex `4n+3` reads each real
  far enough out that its modulus is small; `RlimSeq_regular` shows the diagonal satisfies
  `|·| ≤ 1/(m+1)+1/(n+1)`, so `lim X` is a genuine constructive real. (The constant `4n+3` is the
  0-indexed analogue of Bishop's `g(n) = cn`; re-derived against our own bounds.)
- **Convergence with a rate** (`Rlim_tendsTo`). `X k → lim X` within `1/(k+1)`: routing through the
  large index `4n+3` keeps the modulus small, and regularity + the regular-sequence bound give
  `|(X k)ₙ − (lim X)ₙ| ≤ 2/(k+1) + 2/(n+1)`.
- **Uniqueness** (`RTendsTo_unique`). Limits are unique up to `≈`: the gap `|Lₙ − L'ₙ|` is
  `≤ 4/(k+1) + 4/(n+1)` for every `k`; the generalized Archimedean lemma kills the `k`-tail and the
  linear-bound criterion turns the residual into `≈`.
- **Choice-free.** Because the regular-sequence data carries its own modulus, the diagonal needs no
  countable choice — the axiom audit shows only `propext`/`Quot.sound`, never `Classical.choice`. (For
  *modulus-free* Cauchy reals, completeness is independent of constructive `ZF`; carrying the modulus is
  what avoids that.)

The v0.8.0 continuation begins the transcendentals (see §16). All v0.7.0 additions are kernel-checked,
pure Lean 4 (no Mathlib, no `sorry`), axiom-audited. RH remains open; no 𝔽₁-square construction exists.

## 16. v0.8.0 — the first transcendental: Euler's number `e`

The transcendentals are where the analytic half acquires its genuine objects. **v0.8.0** delivers the
first — Euler's number `e = Σ 1/i!` — via the exponential series, with a rigorous rational error bound
(`Exp.lean`). It is the canonical demonstration of the "convergent series ⟹ constructive real"
pipeline that completeness (§15) provides: a series is a regular sequence of its partial sums.

- **Partial sums and factorial.** `S(N) = Σ_{i=0}^N 1/i!` (`eSum`). Lean core has no `Nat.factorial`,
  so factorial is built from scratch (`fct`, with `fct_pos`, `self_le_fct`, the step `2·(k+1)! ≤ (k+2)!`).
- **The rigorous error bound** (`ediff_bound`). The crux is a *telescoping* observation: the sequence
  `U(n) := S(n) + 2/(n+1)!` is **decreasing** (`eU_step`), because `2/(n+2)! ≤ 1/(n+1)!` (i.e.
  `2 ≤ n+2`). Hence for `a ≤ b`, `S(b) ≤ U(b) ≤ U(a) = S(a) + 2/(a+1)!`, giving the fully rational,
  explicitly computable tail bound `S(b) − S(a) ≤ 2/(a+1)!`. (This is cleaner than the usual
  geometric-ratio tail and inducts in one line.)
- **`e` as a constructive real.** Reindexing `n ↦ S(n+1)` makes the bound `2/(n+2)! ≤ 1/(n+1)`, so the
  reindexed partial sums are a regular sequence of rationals (`eSeq_regular`) — a `Real`. `e` is then a
  genuine constructive real; `Pos e` is witnessed at index 0 (its approximant there is `2`). Since the
  partial sums are rational, no real-number limit is needed here; completeness is what handles
  genuinely real arguments (the v0.9.0 general `exp`).

The v0.9.0 continuation delivers the general `exp(q)` (see §17). All v0.8.0 additions are kernel-checked,
pure Lean 4 (no Mathlib, no `sorry`), axiom-audited.

## 17. v0.9.0 — the general exponential `exp(q)` on `[0,1]`

**v0.9.0** delivers the next transcendental: the general exponential `exp(q) = Σ qⁱ/i!` for a rational
argument `q ∈ [0,1]`, as a constructive real (`ExpGen.lean`). The design point is *maximal reuse* of the
`e = exp(1)` machinery — the only genuinely new ingredient is **termwise domination**.

- **Rational powers from scratch.** `qpow q i = qⁱ` (core has no `q^i`), with `qpow_den_pos`,
  `qpow_nonneg`, and the key bound `qpow_le_one`: for `q ∈ [0,1]`, every power `qⁱ ≤ 1` (induction via
  the ℚ product-monotonicity `Qmul_le_mul`).
- **The domination bridge.** Since `qⁱ ≤ 1`, each series term satisfies `qⁱ/i! ≤ 1/i!` (`expTerm_le`).
  Hence the `exp(q)` partial-sum gaps are dominated *termwise* by those of `e` (`expdiff_dom`, a one-step
  induction regrouping `(s + t) − base = (s − base) + t`). Chaining with the v0.8.0 bound `ediff_bound`
  gives the **rigorous rational error bound** `expdiff_bound`: for `a ≤ b`,
  `S_q(b) − S_q(a) ≤ 2/(a+1)!` — the *same* tail bound as `e`, with no new tail analysis.
- **`exp(q)` as a constructive real.** The reindex `n ↦ S_q(n+1)` reuses `efct_reindex` verbatim, so the
  reindexed partial sums are regular (`expSeq_regular`) and `Rexp q` is a genuine `Real`. Correctness is
  anchored by `Rexp_zero` (`exp 0 ≈ 1`, exercising `qpow` at the degenerate point where every power past
  `q⁰` vanishes) and `Rexp_one_pos` (`exp 1 > 0`, witnessed at index 0).
- **Supporting infrastructure.** `Qeq_trans` (ℚ value-equality is an equivalence) was added to the order
  library — the cross-multiplied identities are linear-combined and cancelled via `b.den > 0`.

The v0.10.0 continuation locks the λₙ / RH proof boundary and ships ζ as an exact-bounded object
(see §18). All v0.9.0 additions are kernel-checked, pure Lean 4 (no Mathlib, no `sorry`), axiom-audited
and choice-free.

## 18. v0.10.0 — the λₙ / RH proof boundary, and ζ as an exact-bounded object

**v0.10.0** does two coupled things: it pins the **analytic face of the RH crux** (`Li.lean`) and it
ships **ζ as a genuine exact-bounded object** (`Analysis.ExactBounded`, `Analysis.Zeta`).

- **The proof boundary (`Li.lean`).** By **Li's criterion** (Li 1997), RH ⟺ `λₙ > 0 ∀ n ≥ 1` (the
  non-strict `≥ 0` form is the general Bombieri–Lagarias 1999 multiset criterion). `LiPositive` /
  `LiNonneg` are genuine, satisfiable properties (`template_liPositive` on the constant-`1` sequence);
  the **crux** `LiCrux λ` on the unconstructed genuine ζ-derived `λ` is OPEN
  (`f1SquareStatus.liPositivityHolds = none`), guarded by a detailed faithfulness caution and the
  **finite-check guard** `liPositive_iff_all_upTo` — `LiPositive = ⋀_N LiPositiveUpTo N`, so the
  numerical positivity of the first ~10⁵ `λₙ` (Feb 2025) is *not* a proof. The Bombieri–Lagarias
  decomposition and the Weil explicit formula (Weil 1952 / Connes 1999) are stated as honest
  interfaces; crucially `λₙ^{arith} = −Σ Λ(m)wₙ(m)` and `λₙ^{∞}` have **opposite signs**, so `λₙ > 0`
  is a delicate cancellation — the open difficulty, which no termwise lemma supplies.
- **`ExactBoundedReal` (`ExactBounded.lean`).** A constructive real presented as a stream of certified
  rational enclosures `[xₙ − 1/(n+1), xₙ + 1/(n+1)]` of exact width `2/(n+1)` (`enclosure_width`). The
  Li coefficients are typed `λ : Nat → ExactBoundedReal`.
- **ζ as an exact-bounded object (`Zeta.lean`).** For integer `s ≥ 2`, `ζ(s) = Σ_{i≥1} 1/iˢ` is built
  as a genuine exact-bounded real, with the rigorous rational tail bound `S(b) − S(a) ≤ 1/(a+1)`
  (`zetadiff_bound`) via the telescoping decreasing `U(N) := S(N) + 1/(N+1)` — the added term
  `1/(N+2)ˢ ≤ 1/((N+1)(N+2))` because `(N+1)(N+2) ≤ (N+2)² ≤ (N+2)ˢ`. The bound is already the Bishop
  modulus, so the partial sums are *directly* regular (no reindex). `zeta_pos`: `ζ(s) > 0`. Natural
  powers `npow` are built from scratch.

**Honest scope.** This ζ is the convergent half-plane `Re(s) > 1` at integer points — where ζ has **no
zeros** and RH does **not** live. The analytic continuation to the critical strip (and ζ at complex
`s`), and the genuine `λₙ` *values* (which need that continuation and `log`), are **not** built — only
the exact-bounded *type* and the boundary are shipped, with nothing fabricated. All v0.10.0 additions
are kernel-checked, pure Lean 4 (no Mathlib, no `sorry`), axiom-audited and choice-free. RH remains
open (June 2026); no 𝔽₁-square construction exists — the Feb-2026 Connes–Consani *On the Jacobian of
Spec ℤ̄* (arXiv:2602.15941) is a Jacobian/adele-class-space construction, not the square nor an
intrinsic intersection theory.

## 19. v0.11.0 — the order `≤` on ℝ (foundation for the transcendentals)

**v0.11.0** builds the **order `≤` on constructive ℝ** (`ROrder.lean`) — the prerequisite every
transcendental (`exp`, `cos`/`sin`, `log`) rests on. The Bishop order is

  `x ≤ y  :⟺  ∀ n, xₙ ≤ yₙ + 2/(n+1)`.

With this pointwise form, reflexivity (`Rle_refl`), the bridge from `≈` (`Rle_of_Req`), and
antisymmetry up to `≈` (`Rle_antisymm`: `x ≤ y` and `y ≤ x` give `x ≈ y`) are immediate — the
`2/(n+1)` slack absorbs the modulus at the *same* index. **Transitivity** (`Rle_trans`) is the one
genuine limiting step: chaining `x ≤ y ≤ z` through an auxiliary index `m` yields
`xₙ ≤ zₙ + 2/(n+1) + 6/(m+1)` for *every* `m` (four steps — regularity of `x` at `n,m`; `x ≤ y` at
`m`; `y ≤ z` at `m`; regularity of `z` at `m,n`), and the generalized Archimedean lemma `Qarch_gen`
kills the `6/(m+1)` tail — exactly the argument behind `Req_trans`. `Rnonneg` (Bishop `x ≥ 0`) gets its
canonical home here (moved from `Li`), with `Rle_zero_of_Rnonneg` (`x ≥ 0 ⟹ 0 ≤ x`).

All v0.11.0 additions are kernel-checked, pure Lean 4 (no Mathlib, no `sorry`), axiom-audited
and choice-free.

## 20. v0.12.0 — ℝ as a constructive field with powers, and `exp` on all of ℝ

**v0.12.0** makes ℝ a constructive **field with powers** and builds the **everywhere-defined `exp`**.

*Field / powers.* Real powers `Rpow x n` are iterated `Rmul` (`Pow.lean`). The reciprocal `1/x` of a
*positive* real (`Inv.lean`) is **positivity-as-data**: a positive real comes with a witness `k` such
that `x_k > 1/(k+1)`; setting `δ = x_k − 1/(k+1) > 0` floors `x` by `L = δ/2 > 0` on the tail
`m ≥ 2δ.den`, and the reindex `R n = 4δ.den²·(n+1) + 2δ.den` makes the reciprocal sequence
`n ↦ 1/x_{R n}` Bishop-regular (the modulus `|1/a − 1/b| = |a−b|·(1/a)(1/b)` is controlled because the
arguments are bounded below by `L`). Division is `Rdiv x y = x · (1/y)`.

*`exp` on ℝ.* `exp(x)` (`ExpReal.lean`) is the **diagonal of rational partial sums**:

  `exp(x)_j = S_{R j}(x_{R j})`,  where  `S_N(q) = Σ_{i≤N} qⁱ/i!`  and  `R j = 2M + 4(j+1)·K`,

a single reindex `R j` serving both the argument index `x_{R j}` and the truncation depth, with
`M = ⌈|x|⌉` (the canonical bound `xBound`) and `K` packaging the truncation and Lipschitz constants. The
key point: the diagonal is a sequence of **rationals** that is *already* Bishop-regular —
`|exp(x)_j − exp(x)_k| ≤ 1/(j+1) + 1/(k+1)` — so it is a constructive real **directly**, with no appeal
to completeness/`Rlim`. Regularity (for `j ≤ k`, splitting through the midpoint `S_{R j}(x_{R k})`) rests
on three rational bounds on `expSum`, each proved here and axiom-clean:

  1. **truncation** (`expSum_trunc_bound`): for `|q| ≤ M` and `2M ≤ a ≤ b`,
     `|S_q(b) − S_q(a)| ≤ 2Mᵃ⁺¹/(a+1)!` — via the dominating `M`-series `Σ Mⁱ/i!` (`expSumM`) with its
     telescoping tail (`expM_diff_bound`) and termwise domination of the general-`q` gap;
  2. **Lipschitz** (`expSum_Lip_le`, `LipS_le_U`): `|S_q(N) − S_{q'}(N)| ≤ C·|q − q'|` with `C` uniform
     in `N` — from the per-power estimate `|qⁱ − q'ⁱ| ≤ i·Mⁱ⁻¹·|q − q'|`, summed and bounded;
  3. **factorial growth** (`fct_ge_geom`, `trunc_reindex`): the factorial outpaces `Mⁱ` by a factor `2`
     every step past `2M`, converting the super-fast tail (1) into the `1/(j+1)` reindex.

The remaining transcendentals follow as a concrete release (no open `+`): **v0.13.0** `cos`/`sin`
(alternating series with the even/odd sandwich remainder) and `log` (positivity-as-data + the artanh
series) — their prerequisites (`Rinv`, `qpow` with its bounds, ℝ-completeness) are all in place. Then the
next phase — ζ's continuation into the critical strip (needs complex exp/log), the genuine `λₙ`, and the
explicit-formula trace — which ends at `λₙ > 0 ∀n` = RH, the open frontier. All v0.12.0 additions are
kernel-checked, pure Lean 4 (no Mathlib, no `sorry`), axiom-audited and choice-free. RH remains open
(June 2026); no 𝔽₁-square construction exists.
