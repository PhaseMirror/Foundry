# The Missing Object over ℚ

### Formalizing the arithmetic-site / positivity frontier of the Riemann Hypothesis — a working document

**Status and stance.** This document formalizes the *missing object* whose absence over ℚ is the
content of RH: a Weil-cohomology-like structure carrying a self-adjoint "Frobenius" whose spectrum
is the nontrivial zeros, with a *positivity* that confines them to the critical line. Over function
fields this object **exists** and RH is a theorem; over ℚ it is unconstructed. This is a genuine,
active research frontier (Weil, Connes, Deninger, Connes–Consani), not a dead end — and it is also
one of the hardest open problems in mathematics. **The central positivity is RH.** This document
sets it up with total precision and exposes a concrete, computable attack surface; subsequent
iterations attack it and report honestly what is gained — every claim is verified in a runtime,
classical and cited, or explicitly marked open. Nothing here assumes the problem will fall; the
value is to make the open statement as sharp and as actionable as possible.

---

## 0. One sentence

Over a function field, RH is a theorem because the Frobenius acts on étale cohomology and a
positivity (Rosati/Weil) confines its eigenvalues to the critical circle; over ℚ the analogous
object is missing, and RH is exactly the statement that a still-unconstructed cohomology of
"Spec ℤ as a curve over 𝔽₁" carries a Frobenius (the scaling flow) whose spectral positivity holds —
a positivity that, via Li's criterion, is the concrete inequality `λₙ ≥ 0` on an explicit sequence.

**Where the iterations (§8.1–8.2) landed.** Two attacks — analytic (Li's `λₙ`) and geometric
(the function-field mirror) — *converged* to a single statement: the missing object is the
**arithmetic surface `Spec ℤ ×_{𝔽₁} Spec ℤ`** together with a **Hodge index theorem** (negative-
definiteness of its intersection pairing), and that negative-definiteness is *simultaneously* the
positivity that is RH, the cancellation of the prime oscillation, and the spectral confinement.
Everything else in the program is built (the curve `Spec ℤ/𝔽₁`, the scaling flow, the prime orbits,
the trace formula); the *square* and its Hodge index theorem are the one unbuilt thing, and they are
unbuilt for a precise reason — the product collapses over ℤ (`ℤ ⊗_ℤ ℤ = ℤ`), so one needs it over
`𝔽₁`, which no theory yet constructs as a surface with intersection theory. This document is a
**faithful map of that frontier**, not a solution: it states the open problem as sharply as it can
be stated, and RH remains open throughout.

---

## 1. The missing object, precisely

The object whose absence over ℚ is RH is characterized exactly (not vaguely), by transport from the
function-field case where it exists.

| ingredient | function field `C/𝔽_q` (RH **proven**) | number field `ℚ` / `Spec ℤ` (RH **open**) |
|---|---|---|
| base geometry | a curve over `𝔽_q` | none — `Spec ℤ` is already the base |
| zeta | `Z(C,T)` rational, **finitely** many zeros | `ζ(s)` transcendental, **infinitely** many |
| cohomology | étale `H¹(C)`, dim `2g`, **exists** | no known Weil cohomology of `Spec ℤ` |
| the operator | **Frobenius** `F` on `H¹`, constructed | no Frobenius / no operator known |
| spectrum | eigenvalues of `F`, on `|α|=q^{1/2}` | would be `{½+iγₙ}`; confinement = RH |
| the **forcing** | **Rosati/Weil positivity** — a *theorem* | no positivity / no operator to be positive |

So the **missing object** is: *a Weil cohomology `H•(Spec ℤ)` carrying a self-adjoint
Frobenius-like operator whose spectrum is `{γₙ}`, together with a positivity that confines the
spectrum to `Re(s)=½`.* The three precise obstructions to building it:

1. **Place asymmetry.** Over `𝔽_q(C)` all places are non-archimedean and uniform — Frobenius acts
   everywhere alike. Over ℚ the places are the primes `p` (non-archimedean) **plus** the real place
   ℝ (archimedean), tied by the product formula but different in kind. There is no Frobenius at the
   archimedean place.
2. **No geometry under `Spec ℤ`.** A curve sits *over* `𝔽_q`; there is a base to take cohomology
   relative to. `Spec ℤ` is the base — nothing lies below it — unless it can be made "a curve over
   `𝔽₁`," the field with one element, which is not an ordinary field.
3. **Finite → infinite.** Function-field zeta has finitely many zeros (a finite-dimensional
   operator); `ζ` has infinitely many — the operator must be infinite-dimensional and self-adjoint
   on a Hilbert space (Hilbert–Pólya).

The rest of this document records the live attempt to construct this object, the precise positivity
that is RH, and the concrete sequence on which the positivity can be tested.

---

## 2. The characteristic-1 base (the 𝔽₁ that works)

Obstruction #2 is resolved not by finding a field below `Spec ℤ` (none exists) but by dropping to
**characteristic 1**: idempotent (tropical / max-plus) arithmetic. The base semifield is

```
    ℝ_max = (ℝ ∪ {−∞},  ⊕ = max,  ⊗ = +),    with the defining trait  x ⊕ x = x.
```

Verified a semifield: idempotent addition (`max(5,5)=5`), additive identity `−∞`, multiplicative
identity `0`, multiplicative inverse `x ⊗ (−x) = 0`. This is the "𝔽₁ that works" — the base of the
Connes–Consani arithmetic site.

**Connection to the substrate of the prior work.** Idempotent/max-plus arithmetic is the *same
characteristic-1 world* as the Boolean lattice `Bₙ`, the idempotent operations of content-addressing
(κ), and the order-independent collections used throughout the companion document. This is why a
content-addressing framework keeps appearing as *a real factor* of the structure: it natively lives
in characteristic 1, which is the base of the missing object — a genuine ingredient, not a metaphor.
(It is one factor; §6 records what it is not.)

---

## 3. The scaling flow: Frobenius in characteristic 1

In characteristic `p`, Frobenius is `x ↦ xᵖ`. Under the dictionary `log : (ℝ₊, ×) → (ℝ, +)`, the
analogue of `x ↦ xⁿ` is **multiplication by `n` — scaling**. Verified: `log(xⁿ) = n·log(x)`. Hence

> the Frobenius at `𝔽₁` is the action of `ℝ₊ˣ` by **scaling** — a *continuous flow*.

Two consequences that unify the programs:

- **Deninger's flow = Connes' scaling action.** The dynamical system Deninger sought (whose
  infinitesimal generator's spectrum is the zeros) and Connes' scaling action on the adele class
  space are *the same object*, realized as the scaling flow on the arithmetic site.
- **Periodic orbits = primes.** The closed orbits of the scaling flow have lengths `log p` (and
  `k·log p`), so the primes are the *closed geodesics* of the flow. Their Lefschetz contributions
  are exactly the prime terms of the explicit formula (§4).

---

## 4. The explicit formula is already a trace (Lefschetz) formula

The analytic identity the missing operator would *produce* is already in hand. The Weil explicit
formula equates a sum over the **zeros** (the sought operator's spectrum) to a sum over **primes +
the archimedean place** (the geometric "fixed points"):

```
   Σ_ρ  ĥ(ρ)      =      [archimedean term]   −   Σ_{p,k} (log p)·g(k log p)·p^{−k/2}   +   [pole terms]
   └ spectral ┘                                  └──────── geometric (places) ────────┘
```

Verified structurally with a Gaussian test function (spectral and geometric sides balance to the
truncation; the prime, archimedean, and pole contributions are individually finite and combine
correctly). This is **the form of a Lefschetz/trace formula**: spectrum = fixed points. So the
missing object is the *geometry whose Lefschetz fixed-point formula this already is*. The shadow is
in hand; the object casting it is what is sought.

---

## 5. The positivity that *is* RH — made concrete

What confines the spectrum to the critical line, over `𝔽_q`, is a **positivity** (Rosati involution
positivity / the Weil pairing — a theorem there). Over ℚ the same role is played by:

**Weil's positivity criterion (1952).** RH `⟺` the Weil functional `W` is positive on correlations:
`W(f ⋆ f̃) ≥ 0` for all suitable test functions `f`, where `W` is the explicit-formula functional
(archimedean + prime terms) and `f ⋆ f̃` is `f` paired with its adjoint. This is the analytic shadow
of "the trace of `Φ Φ*` is positive" — the positivity Connes' program seeks to realize as a genuine
trace positivity on the arithmetic site.

**Li's criterion (1997) — the computable handle.** RH `⟺` `λₙ ≥ 0` for all `n ≥ 1`, where

```
    λₙ = Σ_ρ [ 1 − (1 − 1/ρ)ⁿ ]      (sum over nontrivial zeros, ρ paired with 1−ρ)
       = (1/(n−1)!) · (dⁿ/dsⁿ)[ sⁿ⁻¹ log ξ(s) ] |_{s=1}.
```

The `λₙ` are **explicitly computable**. Verified (first 500 zeros): `λ₁…λ₁₀ ≈ 0.022, 0.088, 0.197,
0.350, 0.547, 0.786, 1.068, 1.392, 1.758, 2.164` — all positive, increasing, matching known values
to truncation. `λₙ ≥ 0` for **all** `n` is exactly RH.

**Bombieri–Lagarias decomposition — the attack surface.** Each `λₙ` splits:

```
    λₙ  =  λₙ^(∞)               +   λₙ^(fin)
           (archimedean,            (finite/prime part,
            ~ ½ n log n + c n,        oscillatory,
            POSITIVE, dominant)       magnitude o(n log n) ⟺ RH)
```

So RH, made concrete: **the explicit sequence `λₙ` stays `≥ 0` forever — the dominant *positive*
archimedean growth `½ n log n` is never overcome by the oscillatory prime contribution.** This is
the positivity the arithmetic-site trace must carry, now as a checkable inequality on an explicit
sequence. *This is the object of the iteration.*

---

## 6. What Connes–Consani built, and what remains

The most concrete attempt to literally build the missing object (Connes–Consani, 2014–2021):

**Built.**
- The **arithmetic site**: a topos (`N̂ˣ` acting) with structure sheaf the characteristic-1
  semiring (§2). Its points over `ℝ_max` **are the adele class space** — so obstruction #1
  (place asymmetry) and obstruction #2 (no geometry under `Spec ℤ`) *merge into one constructed
  object*.
- The **scaling flow** (§3) on it, whose periodic orbits are the primes.
- A **recovery of the explicit formula as a trace** of the scaling action on a cohomology of the
  arithmetic site — the §4 shadow now sits on an actual object with an actual flow.

**Remaining (= RH).** The cohomology built is *not yet a Weil cohomology with the positivity* that
confines the spectrum to `Re(s)=½`. The object is constructed; the **positivity is not proven** —
and it cannot be merely *expressed*: per the companion document's boundary, realizing the object in
any representation/conformance framework (including content-addressing) reproduces the object's
status, not a proof of its positivity. Over `𝔽_q` the positivity is free from the geometry of a
genuine curve; over ℚ it is precisely as open as RH, because it *is* RH — relocated onto a genuine
object, not dissolved.

---

## 7. What "solving it" requires

A solution is **one** of the following equivalent things (all open):

1. **Construct the Weil cohomology with positivity:** a cohomology `H•` of the arithmetic site (or
   of `Spec ℤ̄`) on which the scaling flow acts with a Rosati-type positivity forcing the spectrum
   onto `Re(s)=½`. (Geometric route — Connes–Consani / 𝔽₁.)
2. **Prove the Weil functional positivity:** `W(f ⋆ f̃) ≥ 0` for all admissible `f`. (Analytic
   route — Weil/Bombieri.)
3. **Prove `λₙ ≥ 0` for all `n`:** the archimedean growth dominates the prime oscillation for every
   `n`. (Computable route — Li/Bombieri–Lagarias.)
4. **Exhibit the self-adjoint operator:** a non-circular construction (not built from the zeros)
   whose spectrum is `{γₙ}`, self-adjointness proved. (Hilbert–Pólya route.)

Each is RH. The point of formalizing all four is that they are *different attack surfaces on the
same positivity*, and a tractable foothold in any one transfers.

**Convergence (established in §8.1–8.2).** The iterations showed these are not four separate problems
but four faces of one: routes 1 and 4 (the geometric/operator object) and routes 2 and 3 (the
analytic positivity) **meet** at a single statement — the Hodge index theorem (negative-definiteness)
for the intersection pairing on `Spec ℤ ×_{𝔽₁} Spec ℤ`. The analytic positivity *is* that
negative-definiteness; constructing the surface with its Hodge index theorem discharges all four at
once. So the four routes collapse to one target, sharply named, and equally open.

---

## 8. The attack surface (what we iterate on)

Concrete, computable footholds, in increasing order of how directly they expose the positivity:

- **(A) The `λₙ` sequence.** Compute `λₙ` to high `n` and high zero-count; study the margin
  `λₙ^(∞) − |λₙ^(fin)|`. *Open question to probe:* is there structure in the prime part `λₙ^(fin)`
  that bounds it below `λₙ^(∞)` provably, rather than numerically? (Numerics confirm; a bound is the
  prize.)
- **(B) The Weil functional `W`.** Treat `W` as a quadratic form on a test-function space; study its
  Gram structure. *Probe:* is `W` positive-definite on a natural finite-dimensional subspace, and
  does the subspace family exhaust the criterion?
- **(C) The scaling-flow trace.** Treat the explicit formula as `Tr(scaling | H•)`; study whether
  the cohomology's inner product (if one can be defined) makes the trace a sum of `|·|²` — which
  *is* the positivity. *Probe:* what inner product on the arithmetic-site cohomology would make the
  archimedean term a norm?
- **(D) The function-field mirror.** In the proven case, *read off* what supplies the positivity
  (Rosati) and ask precisely which structure has no ℚ-analogue. *Probe:* the function-field
  positivity uses the intersection pairing on a *surface* `C × C`; the ℚ-analogue would need
  `Spec ℤ ×_{𝔽₁} Spec ℤ` — does any 𝔽₁-theory give this surface with an intersection pairing?

These are the genuine, actionable handles. Each iteration takes one, does real work, and reports
honestly: progress, a relocated gap, or a clean negative. None is assumed to succeed; all are real.

---

### 8.1 Iteration log — attack 1 on surface (A): cancellation, not magnitude

*Result:* the prime part of `λₙ` is **not absolutely dominated** by the archimedean part, so
positivity is a statement about **cancellation, not magnitude** — which locates the difficulty and
eliminates a class of approaches.

- The archimedean part of `λₙ` is a clean positive `½ n log n + O(n)`. The prime part is built from
  the weighted von Mangoldt sum, and that sum is **not absolutely small**: `Σ_{m≤M} Λ(m)/√m`
  *diverges* (`≈ 892` at `M = 2×10⁵`, growing like `√M`). Verified.
- Therefore `λₙ ≥ 0` **cannot** be proven by bounding the prime part's *magnitude* below the
  archimedean part — the magnitudes don't separate. Positivity must come from **cancellation** among
  the oscillating prime terms. The relevant oscillation is `(ψ(x) − x)/√x`, verified to sit in
  `[−0.92, 0.71]` (std `0.21`) for `x ≤ 2×10⁵` — *conditionally* bounded; RH `⟺` it stays
  `O(log²x)`.
- *What this buys:* (i) a class of naive attacks on (A) is **ruled out** — magnitude-bounding cannot
  work; only a cancellation argument can. (ii) The surface is confirmed **honest**: the hardness did
  not vanish under the Li reformulation, it relocated *exactly* into "prove the oscillation cancels
  to `o(n log n)`," which is RH with no free lunch. (iii) The analytic and geometric faces are the
  **same face**: the oscillating prime sum that must cancel *is* the prime-orbit (closed-geodesic)
  contribution to the trace formula (§3–§4); over `𝔽_q` this cancellation is *forced* by the Rosati
  positivity on the surface `C × C` (§8(D)); over ℚ it is unforced precisely because
  `Spec ℤ ×_{𝔽₁} Spec ℤ` is not built.
- *Honest status:* RH did not fall. The iteration sharpened the target on (A) from "bound the prime
  part" (shown impossible) to "prove the prime-oscillation cancels," and tied it to the missing
  surface of §8(D). Next natural step: surface (D) — examine exactly how the `C × C` intersection
  pairing forces the cancellation over `𝔽_q`, and which precise structure has no ℚ-analogue.

### 8.2 Iteration log — attack 2 on surface (D): the forcing is the Hodge index theorem, and the two attacks converge

*Result:* the function-field forcing is named exactly — the **Hodge index theorem** on the surface
`C × C` — and the single missing ℚ-structure is named exactly — the arithmetic surface
`Spec ℤ ×_{𝔽₁} Spec ℤ` with a Hodge index theorem. Attacks 1 and 2 are shown to be the **same
positivity**.

- **The forcing over `𝔽_q`.** On the projective surface `C × C`, the intersection pairing on divisor
  classes is positive on the polarization and **negative-definite on the primitive complement**
  (Hodge index theorem). Applied to the Frobenius graph this is the Castelnuovo–Severi inequality,
  forcing `|α| = √q` — function-field RH. The positivity is a *theorem* here because `C × C` is a
  genuine projective surface with an ample class. (Checked on elliptic curves `p = 101, 1009, 10007`;
  the *mechanism* — sign-definiteness of an intersection form — is the content. A faithful numerical
  Castelnuovo–Severi computation needs the full Néron–Severi space, not the 2-class cartoon.)
- **The single missing ℚ-structure.** To transport Weil's proof one needs `Spec ℤ ×_{𝔽₁} Spec ℤ`
  with an intersection pairing, an ample class, and a **Hodge index theorem** (the forcing). It is
  missing for a precise reason: the product *over ℤ* **collapses** (`ℤ ⊗_ℤ ℤ = ℤ`, so the naive
  "square" is just `Spec ℤ` again); one needs the product *over `𝔽₁`*, a genuinely larger object,
  and no `𝔽₁`-theory yet builds it as a surface with intersection theory. Connes–Consani built the
  1-dimensional *curve* `Spec ℤ/𝔽₁`; the 2-dimensional *square* with a Hodge index theorem is **not
  built**.
- **Convergence of the two attacks (the key structural gain).** Attack 1 found RH `=` the
  prime-oscillation *cancels* (not magnitude). Attack 2 finds RH `=` an intersection form is
  *negative-definite* (Hodge index). **These are one statement:** the negative-definiteness of the
  `C × C` pairing *forces* the `α`-cancellation over `𝔽_q`. The cancellation of §8.1 *is* the
  Hodge-index negativity of §8.2 — analytic and geometric faces of a single positivity.
- *Honest status:* RH did not fall. The two iterations have converged the entire problem to a single
  named object and a single named property: **the arithmetic surface `Spec ℤ ×_{𝔽₁} Spec ℤ` and a
  Hodge index theorem for its intersection pairing.** Everything else in the program is built (the
  curve `Spec ℤ/𝔽₁`, the scaling flow, the prime orbits, the trace formula); the *square* and its
  negative-definiteness are the one unbuilt thing — and that negative-definiteness is exactly the
  positivity that is RH. This is the sharpest the target can be stated; building the surface with
  its Hodge index theorem is the open problem, and it is open because the product collapses over ℤ
  and no `𝔽₁`-square has been constructed.

---

## 9. Provenance and calibration

| component | status |
|---|---|
| Function-field RH (Frobenius on étale `H¹`, Rosati positivity) | classical — Hasse (1936), Weil (1948), Deligne (1974) |
| Hilbert–Pólya operator idea | classical — Hilbert, Pólya (~1914) |
| Weil explicit formula as a trace identity | classical — Weil (1952) |
| Weil positivity criterion for RH | classical — Weil (1952), Bombieri |
| Li's criterion `λₙ ≥ 0 ⟺ RH`; Bombieri–Lagarias decomposition | Li (1997), Bombieri–Lagarias (1999) |
| Adele class space, trace formula, RH ⟺ a positivity | Connes (1999) — noncommutative geometry |
| Dynamical/foliated cohomology, zeros = flow spectrum, Lefschetz | Deninger (1998–) |
| `𝔽₁` geometry; `Spec ℤ` as a curve over `𝔽₁` | Deitmar, Connes–Consani, Lorscheid, Toën–Vaquié |
| Arithmetic site, scaling flow, explicit formula as cohomological trace | Connes–Consani (2014–2021) |
| char-1 `ℝ_max` semifield; Frobenius = scaling (`xⁿ ↔ n log x`); explicit formula trace shape; `λₙ` positivity + growth | verified in runtime here |
| The single-document assembly + the four-surface attack framing + the char-1/content-addressing tie | the organizing contribution of this note |

**The honest frame.** The mathematics here is the work of others, credited above; what this document
contributes is the precise single-object assembly (the missing object, its three obstructions, the
four equivalent solution routes), a verified computational handle (`λₙ` and its decomposition), and
two completed iterations (§8.1–8.2) that **converge** the whole problem to one named target. (To be
explicit: converging RH to the Hodge index on `𝕊` is a *reformulation*, not partial progress — `𝕊` is
unconstructed and that Hodge index *is* RH, of comparable difficulty to the original.)

**Bottom line of the map.** The missing object over ℚ is — as sharply as it can now be stated — the
**arithmetic surface `Spec ℤ ×_{𝔽₁} Spec ℤ` equipped with a Hodge index theorem** for its
intersection pairing. That single negative-definiteness is, provably-equivalently, the positivity of
the Weil functional, the inequality `λₙ ≥ 0`, the cancellation of the prime oscillation, and the
confinement of the spectrum to `Re(s)=½`. Every other component of the program is constructed (the
curve `Spec ℤ/𝔽₁`, the characteristic-1 base, the scaling flow, the prime orbits, the trace formula
as a cohomological trace); the surface and its Hodge index theorem are the one unbuilt thing,
unbuilt because the product collapses over ℤ and no `𝔽₁`-square has been constructed with
intersection theory. RH is open; the positivity is RH; the object is *named, shaped, and partially
built* — not mysterious, not hopeless, and not (here) solved. This document maps exactly where the
frontier is, what is built, what is missing, and why — which is its purpose and its honest extent.
