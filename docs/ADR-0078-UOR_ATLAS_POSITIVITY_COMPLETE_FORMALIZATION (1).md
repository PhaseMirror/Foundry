# UOR Atlas Positivity Closure
## Audited Complete Formalization Specification for the F1 RH Frontier

**Repository frontier:** `UOR-Foundation/F1`

**Atlas foundation:** the UOR Atlas semantic source compiled by LexLean.

**Purpose:** specify the exact formal development required to connect the LexLean UOR Atlas to the current genuine F1 normalized-autocorrelation / Weil / Li chain without hidden hypotheses, false positivity substitutions, or historical surrogate forms.

This document supersedes the earlier `UOR_ATLAS_POSITIVITY_COMPLETE_FORMALIZATION.md`.

---

# 0. Audit verdict

The previous draft contained several genuine gaps and one central inconsistency with facts already proved in F1.

The corrected verdict is:

```text
The existing F1 development has already localized RH positivity to the
prime--Archimedean dominance problem.

The ordinary Sonine/complement projection does NOT by itself make the
full coupled Weil form positive.

Therefore the missing theorem is not generic Hilbert-space positivity.
It is an Atlas-derived dominance theorem for the genuine coupled operator.
```

This is not a matter of prose interpretation. F1 has already kernel-checked the relevant negative result.

At commit `f93ae4618e0e909d2beb3c1f6b2412b3d08111f2`, the project records:

```text
coupled Weil on the Sonine complement
  = nonnegative Archimedean energy
    - nonnegative prime energy

and

coupled positivity
  iff
prime energy is dominated by Archimedean energy.
```

At commit `56e2359bce575c16b0b2c99e96c94ade923a40e4`, F1 proves that the finite Atlas spectral form itself is a difference of two PSD forms and is indefinite. That commit explicitly does **not** prove `ArchDominatesPrime`.

At commit `903532497de31914475e3783d9bf70933696330b`, F1 localizes the crux to the sign of the prime--Archimedean coupling.

At commit `db977677d2395a7fc811def10930af960b317c4c`, F1 obtains the explicit-formula shape

```text
2 * lambda_n = arch_n - prime_n
```

under its explicit diagonal-match seam.

At current frontier commit `4778d9e4a5b83e9aa02607189153dafcc13d5fb2`, F1 replaces earlier surrogate connections with the genuine normalized point-value Weil chain and states honestly that:

```text
1. poles / archTail are still interface values in that chain;
2. the explicit-formula identification hid is not proved there;
3. positivity of the genuine Weil value remains open.
```

Therefore the earlier draft's statement

```text
Weil value = ordinary Sonine residual norm-square
```

cannot be used as an assumed architecture. It is stronger than what the present formalization supports and conflicts with the already-proved signed-complement result unless a **new Atlas coupling theorem** supplies exactly the missing dominance/factorization.

The revised formalization has no such hidden step.

---

# 1. Exact closure target

The target is the current genuine F1 scalar Weil functional on the normalized autocorrelation test.

For an admissible current F1 context `C : NormCtx`, let

```text
g_C = C.g
h_C = autocorrelation(g_C)
f_C(q) = q^(-1/2) * h_C(q)
```

where `f_C` is exactly the current `normAutocorrTest C`.

The genuine Weil value has the sign convention already used by F1:

```text
W_C
=
pole_C
-
(
  prime_C
  +
  arch_const
  +
  arch_tail_C
).
```

The first closure task is to remove the free Archimedean interface values and obtain a closed term

```lean
closedWeilValue : NormCtx -> Real
```

with no arbitrary `poles : Real` and no arbitrary `archTail : Real`.

The positivity theorem is then:

```lean
theorem atlas_positivity
    (C : NormCtx) :
    Rnonneg (closedWeilValue C)
```

but this theorem is **not** the load-bearing statement.

The load-bearing statement is the operator dominance theorem:

```text
PrimeOp_C <= ArchOp_C
```

on the exact F1 analytic subspace represented by admissible normalized autocorrelations.

Equivalently, for every admissible `g`,

```text
<g, PrimeOp_C g> <= <g, ArchOp_C g>.
```

The scalar readback theorem must prove

```text
closedWeilValue C
=
<g_C, (ArchOp_C - PrimeOp_C) g_C>.
```

Then Atlas Positivity is immediate from the operator order.

This is the corrected formal form of the crux.

---

# 2. What counts as a complete formalization

The development is complete only if all of the following are true.

1. Every object in the positivity chain is a definition or an already-imported proved object.
2. No structure field is used to smuggle the desired sign.
3. No theorem takes `ArchDominatesPrime`, Weil positivity, Li positivity, RH, zero-line data, or a square-realization identity as a hypothesis.
4. The current normalized F1 prime side is used; the removed `vFrom` / `primeGram` surrogate bridge is not silently restored.
5. The current Atlas `Place` layer is used according to its actual strength: ring-parametric localization and self-duality, not an unproved identification with completed R or Q_p.
6. The bridge between Atlas rational/place data and F1's custom constructive Q/Real analytic layer is formalized explicitly.
7. The Archimedean pieces are constructed, with convergence/specification theorems, rather than passed as arbitrary `Real` inputs.
8. The current explicit-formula seam is discharged by a theorem, not renamed.
9. The final positivity theorem depends on an Atlas-derived operator dominance theorem whose proof cone contains no zeta zeros or RH equivalent.
10. The final RH theorem contains no hypotheses.

If item 9 cannot be proved from the available Atlas/F1 declarations, then the hypothesis that only mechanical assembly remains is false. The implementation must stop there rather than inventing a positive form.

---

# 3. Source pinning and authority

The LexLean F1 project must pin:

```text
- one exact LexLean compiler semantics ID;
- one exact `lexlean.uor.atlas` package tree digest;
- one exact F1 migration-oracle commit;
- Lean 4.32.1, matching the current LexLean verification policy.
```

The migration oracle for the current frontier is:

```text
UOR-Foundation/F1
4778d9e4a5b83e9aa02607189153dafcc13d5fb2
```

The oracle is historical evidence during migration. It is not a second semantic authority after the LexLean migration is proven complete.

The live dependency direction must be:

```text
LexLean UOR Atlas
      |
      v
F1 generic analytic library
      |
      v
F1 normalized Weil layer
      |
      v
Atlas coupling dominance
      |
      v
explicit formula / Li endpoint
```

No dependency may run from the positivity core back into the RH endpoint.

---

# 4. Correct use of the current UOR Atlas

The current UOR Atlas `Places` formalization supplies the following relevant facts.

```text
D34     global rational carrier in the simple-root basis
Place   local ring / ambient ring / structure-map record
D35     scalar extension/localization
D36     local lattice predicates
V69     local self-duality
V72     local integral action preservation
V74     localization commutes with linear action
D38     finite restricted-product address
D39     diagonal address
T69     diagonal injectivity
RP1     rational scalar action on addresses
PlaceIx one Archimedean index plus one finite index per prime
FullSystem
```

Two limits of the current theorem must be respected.

## 4.1 The exhibited Archimedean place is not the F1 completed real line

The Atlas module deliberately works ring-parametrically. Its exhibited `archPlace` is sufficient for the algebraic localization statements used by the Atlas; it is not a proof that the F1 constructive `Real` carrier is definitionally the same object.

Therefore the final F1 formalization must not contain an unexplained map of the form

```lean
Atlas D34 -> F1 Hilbert space
```

and claim that `V74` proves it correct.

`V74` proves localization/action commutation inside the Atlas scalar-extension setting. It does not construct the analytic representation used by F1.

## 4.2 Atlas lattice self-duality is not automatically F1 Fourier/Sonine self-duality

`V69` is a theorem about the local lattice and its bilinear dual after base change.

It does not, by itself, imply that the F1 test-function Sonine subspace is an orthogonal complement of an Atlas lattice image.

Any connection between the two must be a separate proved transport theorem.

These two corrections remove the largest hidden assumptions in the first draft.

---

# 5. Module graph

The corrected LexLean layer is:

```text
F1/AtlasClosure/
  SourceBindings.lex.tex
  RationalBridge.lex.tex
  PlaceScaleBridge.lex.tex
  NormalizedScale.lex.tex
  ClosedArchimedean.lex.tex
  ClosedWeil.lex.tex
  CoupledOperator.lex.tex
  AtlasCoupling.lex.tex
  AtlasDominance.lex.tex
  ExplicitFormula.lex.tex
  Positivity.lex.tex
  RiemannHypothesis.lex.tex
```

The modules have the following import fence.

```text
SourceBindings
RationalBridge
PlaceScaleBridge
NormalizedScale
ClosedArchimedean
ClosedWeil
CoupledOperator
AtlasCoupling
AtlasDominance
Positivity
```

may not import:

```text
AllZerosOnLine
genuine zero enumerations
RHWitness
any theorem whose hypothesis or conclusion is RH-equivalent
normAutocorr_positivity_iff_RH
```

`ExplicitFormula` may import the established zeta/Li analytic stack because its purpose is to identify the already-defined zero-free Weil functional with the genuine Li sequence.

`RiemannHypothesis` is the only final endpoint module.

---

# 6. `SourceBindings.lex.tex`

This module contains no mathematics. It fixes the exact semantic declarations used from the migrated F1 oracle and Atlas package.

It must bind the current declarations corresponding to:

```text
F1 Real
F1 Complex
F1 Q
Req
Rle
Rnonneg
L2Test
NormCtx
WeilTest
normWeight
normWeight_congr
normAutocorrTest
acPt
acNormFold
acNormFold_collapse
weilPrimePart
weilPrimePart_normAutocorr
weilPrimePart_normAutocorr_collapsed
weilValue
weilValue_normAutocorr
autocorr_recip
autocorr_recip_all
haarIntegral_dilate
completedInner
DLimCompletionRaw
SonineProjection machinery
CoupledWeilComplement signed/dominance theorems
GenuineLi / genuineLamSeq
genuineArithSeq
genuineArchSeq
normAutocorr_positivity_iff_RH
```

and Atlas declarations corresponding to:

```text
UorAtlas.Places.Place
UorAtlas.Places.Pl
UorAtlas.Places.PlaceIx
UorAtlas.Places.placeAt
UorAtlas.Places.fullSystem
UorAtlas.Places.D35
UorAtlas.Places.D38
UorAtlas.Places.D39
UorAtlas.Places.V69
UorAtlas.Places.V74
UorAtlas.Places.RP1
```

The binding gate is exhaustive:

```text
Every referenced semantic role has exactly one current declaration.
No role is satisfied by a historical/dead declaration when a newer genuine
replacement exists.
```

In particular, the following are forbidden as substitutes for the current prime-side identity:

```text
vFrom-based factorization
primeGram readback removed by the current WeilPrimeShift route
any generic Gram generated from the target W values
```

---

# 7. `RationalBridge.lex.tex`

The Atlas and F1 use different rational/real layers. This must be formalized rather than ignored.

Define a canonical conversion from an Atlas rational to the F1 rational representation.

The implementation must use the exact numerator/positive-denominator representation exposed by the two libraries.

Required definitions:

```text
atlasRatToF1Q
f1QToAtlasRat
atlasRatToF1Real
```

Required laws:

```text
RB-01  zero preservation
RB-02  one preservation
RB-03  addition preservation
RB-04  multiplication preservation
RB-05  negation preservation
RB-06  positive-rational inverse preservation
RB-07  AtlasRat -> F1Q -> AtlasRat equals the original Atlas rational
RB-08  F1Q -> AtlasRat -> F1Q is Qeq-congruent to the original F1Q
RB-09  positive order is preserved
RB-10  denominator-prime integrality is preserved
```

The final theorem must be packaged as a concrete ring embedding, not merely a list of equalities, if the existing F1 algebraic interfaces support that packaging.

No use of classical choice is needed: both rational representations carry explicit numerator/denominator data.

The bridge is accepted only after planted tests cover non-reduced F1 representations such as `1/2` and `2/4`, because the current F1 normalization specifically hardened representation invariance at this seam.

---

# 8. `PlaceScaleBridge.lex.tex`

This module does not embed E8 vectors into F1 test functions.

It realizes only the Atlas **place and multiplicative scale indices** in the F1 analytic action.

## 8.1 Finite places

For `p : UorAtlas.Places.Pl`, define the F1 positive scale corresponding to its residue characteristic:

```text
finiteScale(p) = positive rational p.
```

Prove that this definition depends only on the Atlas finite place and agrees with the scale used by the current F1 prime-shift action.

## 8.2 Archimedean index

The Archimedean Atlas place is realized analytically through the concrete rational-to-F1-Real bridge, then through the existing F1 real/log/Haar analytic layer.

No claim is made that Atlas `archPlace.Amb` is definitionally F1 `Real`.

## 8.3 Rational scale action

Define the analytic representation of positive rational scale by reusing the existing F1 dilation:

```text
atlasScale(q) := current F1 multiplicative dilation at q.
```

The term “Atlas” here means that the scale is the analytic representation of the same rational scalar that acts on Atlas addresses through `RP1`.

Prove the intertwining statement at the level that is actually shared by the two systems:

```text
Atlas rational multiplication
        |
        | rational bridge
        v
F1 positive rational multiplication
        |
        v
F1 dilation composition.
```

Required theorems:

```text
PS-01 scale-one law
PS-02 scale-composition law
PS-03 reciprocal-scale law
PS-04 Qeq congruence of the analytic action
```

All equalities must use the appropriate F1 setoid equality where the custom rational representation is noncanonical.

---

# 9. `NormalizedScale.lex.tex`

The current F1 theorem already establishes that the weight used by `normAutocorrTest` is the genuine total function

```text
q |-> q^(-1/2)
```

on the positive cone, and that it is Qeq-congruent.

This module does not redefine the weight.

It proves the operator-level form of the reciprocal symmetry already present in the scalar autocorrelation proof.

Let `U(q)` be the current F1 multiplicative dilation.

Define the half-density action

```text
N(q) = normWeight(q) * U(q).
```

Required theorem:

```text
NS-01
<N(q) x, y> = <x, N(q^-1) y>
```

for the exact dense/test domain on which the current Haar integral is defined.

The proof must be a direct operator-level lift of the already-used change of variables behind:

```text
autocorr_recip
autocorr_recip_all
```

and must consume the current representation-invariant `normWeight`.

This theorem is zero-free and RH-free.

If the current F1 inner product type is only available after completion, prove first on the dense test/core space and then transport by the existing completion-continuity theorem.

No statement that `1/2` is forced by RH is permitted. The only accepted characterization is analytic adjointness under reciprocal scale.

---

# 10. `ClosedArchimedean.lex.tex`

The latest normalized-autocorrelation chain currently leaves two Archimedean quantities as interface values.

They must be replaced by concrete definitions.

The F1 tree already contains a separately developed genuine Archimedean sequence and a gamma/digamma/integral stack. The closure must reuse that analysis rather than introduce a new formula.

## 10.1 Pole term

Define:

```lean
polesOf : NormCtx -> Real
```

as the exact pole/boundary contribution obtained by evaluating the current F1 pole functional on `normAutocorrTest C`.

The definition must expose the exact existing finite expression or convergent integral used by F1.

Required theorem:

```text
CA-01 polesOf_spec
```

showing that substituting `polesOf C` into the current `weilValue` pole slot gives the pole term of the same normalized test, not a merely equal-looking constant from another F1 route.

## 10.2 Archimedean tail

Define:

```lean
archTailOf : NormCtx -> Real
```

from the existing F1 gamma/digamma Archimedean integral for the same test.

Required proofs are explicit:

```text
CA-02 finite-window integrand congruence
CA-03 integrability / regularity on every finite window
CA-04 tail Cauchy property with an explicit modulus
CA-05 definition of the completed tail limit
CA-06 archTailOf_spec
```

If F1's integral representation is already a completed total integral with a theorem characterizing it, CA-03 through CA-05 are discharged by that existing theorem and must be cited semantically rather than reproved.

What is forbidden is:

```text
def archTailOf C := arbitraryReal
```

or a structure field carrying the desired value.

## 10.3 Closed scalar Weil value

Define:

```lean
closedWeilValue (C : NormCtx) : Real :=
  weilValue
    (normAutocorrTest C)
    (polesOf C)
    (archTailOf C)
```

using the actual argument order of the current F1 definition.

Prove:

```text
CA-07 closedWeilValue_expand
```

whose right-hand side is exactly the current established sign convention:

```text
polesOf C
-
(
  acNormFoldC C
  + weilArchConst
  + archTailOf C
).
```

The proof must use the current `weilValue_normAutocorr` and `weilPrimePart_normAutocorr` chain.

---

# 11. `ClosedWeil.lex.tex`

This module fixes the scalar side before any positivity is attempted.

Required theorems:

```text
CW-01
weilPrimePart(normAutocorrTest C) = acNormFoldC C

CW-02
acNormFoldC C = current collapsed Burnol-normalized prime sum

CW-03
closedWeilValue C =
  polesOf C - (prime_C + archConst + archTailOf C)
```

`CW-02` must consume the proven `autocorr_recip_all`; it may not assume reciprocal symmetry.

The finite sum is bounded by the current cutoff `C.X`. No infinite prime-sum convergence theorem is required at this layer.

The interpretation “finite-place contribution” requires one additional arithmetic grouping theorem if the proof or paper groups the von Mangoldt sum by places:

```text
CW-04 prime-power grouping
```

`CW-04` states that every nonzero von Mangoldt term is associated with a unique finite prime place and exponent, and that regrouping the bounded integer sum by `(p,k)` preserves the value.

If the formal proof never regroups the bounded sum, `CW-04` is not needed for the positivity theorem and the implementation must not pretend that the integer-indexed fold is already a place-indexed sum.

This resolves the earlier conflation between integer scales and finite places.

---

# 12. `CoupledOperator.lex.tex`

The current scalar formula should be lifted to a genuine quadratic-form/operator statement on the **current** normalized test space.

This is where the earlier draft incorrectly jumped to a norm-square.

## 12.1 Prime quadratic operator

The normalized autocorrelation satisfies schematically

```text
h_C(q) = <g_C, N(q) g_C>
```

with the reciprocal normalization supplied by the current F1 Haar-change-of-variables chain.

Define the bounded finite prime operator for cutoff `X`:

```text
PrimeOp(C)
=
finite sum over the exact current Weil prime scales
of the corresponding normalized reciprocal-symmetric scale operators,
weighted by the current von Mangoldt coefficients.
```

Do not define it through `primeGram` or `vFrom`.

Required theorem:

```text
CO-01 prime_readback
<g_C, PrimeOp(C) g_C>
=
prime_C.
```

The proof expands the finite operator sum and uses the current `ac_CC_normalization`, `autocorr_recip_all`, and collapsed prime-fold theorem term by term.

This theorem is the legitimate operator replacement for the removed fake Gram bridge.

## 12.2 Archimedean quadratic operator

Define `ArchOp(C)` from the current F1 Archimedean kernel/multiplier on the same test space.

Required theorem:

```text
CO-02 arch_readback
<g_C, ArchOp(C) g_C>
=
polesOf C - (weilArchConst + archTailOf C).
```

The exact sign must match `closedWeilValue_expand`.

`ArchOp(C)` may be represented as a multiplier form, integral operator, or the exact existing F1 Archimedean form. Do not change representation merely to make positivity easy.

## 12.3 Coupled operator

Define:

```text
CoupledOp(C) = ArchOp(C) - PrimeOp(C).
```

Prove:

```text
CO-03 coupled_readback
<g_C, CoupledOp(C) g_C>
=
closedWeilValue C.
```

This is algebra from CO-01, CO-02, and CW-03.

No positivity occurs in CO-03.

---

# 13. Relationship to existing Sonine/complement results

The existing F1 projection machinery remains useful, but its proven scope must be preserved exactly.

Reuse the current results establishing:

```text
- nonnegativity of the Archimedean multiplier on the Sonine/band complement;
- nonnegativity/PSD facts for historical prime Gram forms where applicable;
- the signed decomposition of the coupled form;
- coupled positivity iff the prime contribution is dominated by the Archimedean contribution.
```

Do **not** infer:

```text
CoupledOp >= 0
```

from the Archimedean complement theorem alone.

The kernel-checked F1 result says that inference is invalid.

The corrected use of Sonine projection is:

```text
Sonine removes the known negative Archimedean band.
After that removal, the remaining coupled sign is still the
Archimedean-vs-prime dominance problem.
```

This result is a prerequisite to Atlas Dominance, not its proof.

---

# 14. `AtlasCoupling.lex.tex`

This is the only module allowed to introduce genuinely new Atlas-to-F1 coupling structure.

It must not mention zeta zeros, Li coefficients, or RH.

The goal is to transport the stronger **new LexLean Atlas local-global structure** into the current F1 coupled operator.

The current Atlas supplies coherence/localization/self-duality. Those facts alone do not imply a norm inequality. Therefore this module must prove a concrete analytic statement, not merely invoke the words “self-dual” or “zero object.”

The required construction is an **Atlas coupling witness** for the current F1 scale representation.

A valid witness must be concrete data built from:

```text
- Atlas full place index;
- Atlas diagonal/localization maps;
- Atlas rational scale action;
- the rational bridge;
- the normalized F1 scale representation;
- the current F1 Archimedean and finite-prime operators.
```

It may not contain the desired inequality as a field.

The preferred concrete construction is an intertwining map or kernel `K_A` satisfying an operator factorization that forces dominance.

Two acceptable forms are listed below. The implementation must choose one and prove it; it may not take either as an assumption.

## 14.1 Factorization form

Construct an operator `B_A(C)` such that

```text
AC-01
CoupledOp(C) = B_A(C)^* * B_A(C)
```

on the exact admissible test/core domain.

Then dominance is immediate.

The definition of `B_A` must be prior to and independent of `closedWeilValue`.

It is forbidden to define `B_A` by taking a square root of `closedWeilValue C`.

## 14.2 Contraction/intertwiner form

Alternatively construct a canonical Atlas transfer/intertwiner `T_A(C)` proving that the finite-place operator is dominated by the Archimedean operator:

```text
AC-02
PrimeOp(C) <= ArchOp(C)
```

by an explicit factor/intertwiner calculation, for example

```text
PrimeOp(C) = V(C)^* V(C)
ArchOp(C)  = U(C)^* U(C)
V(C)       = T_A(C) * U(C)
T_A(C)^* T_A(C) <= I.
```

The exact factorization may differ if the current F1 operators are represented as multiplier forms rather than bounded operators; the mathematical content must be the same and must be proved in the current constructive order relation.

The crucial constraint is:

```text
The contractivity/factorization must follow from Atlas data plus already-proved
analytic identities; it cannot be inserted as a predicate field.
```

---

# 15. `AtlasDominance.lex.tex`

This module exposes the one theorem the rest of the proof needs.

Its statement contains no hypotheses beyond the ordinary admissibility data already inside `NormCtx`.

```lean
theorem atlas_arch_dominates_prime
    (C : NormCtx) :
    QuadraticFormLe (PrimeOp C) (ArchOp C)
```

or the exact equivalent relation available in the F1 constructive operator library.

At scalar level:

```lean
theorem atlas_coupled_nonneg
    (C : NormCtx) :
    Rnonneg
      (completedInnerReal
        C.g
        (CoupledOp C C.g))
```

and via `coupled_readback`:

```lean
theorem atlas_positivity
    (C : NormCtx) :
    Rnonneg (closedWeilValue C)
```

The proof order is fixed:

```text
Atlas factorization/intertwiner
        |
        v
operator dominance
        |
        v
quadratic-form nonnegativity
        |
        v
coupled_readback
        |
        v
closedWeilValue >= 0.
```

No proof may run in the opposite direction by first assuming or proving the scalar sign from a Li/RH theorem and then packaging it as operator dominance.

---

# 16. Why `AtlasDominance` is the exact honesty gate

The following existing F1 facts show that this theorem is neither generic nor dispensable.

```text
1. The finite Atlas spectral form is indefinite.
2. A difference of two PSD forms need not be PSD.
3. The Sonine complement only removes the known Archimedean negative band.
4. The prime term remains subtracted.
5. Positivity on the genuine coupled form is equivalent to Archimedean domination.
6. The project has proved individual low-n instances, but not the uniform theorem.
```

Therefore `atlas_arch_dominates_prime` is not a mere reorganization of Pythagoras.

If the newer LexLean Atlas place/localization theory contains enough structure to force it, this module is where that fact is formalized.

If it does not, then a real mathematical theorem remains to be discovered.

There is no logically valid way to remove this gate from the document.

---

# 17. `ExplicitFormula.lex.tex`

This module closes the other independent seam: identifying the closed normalized Weil family with the genuine Li sequence.

The latest current normalized-autocorrelation theorem exposes this as `hid`.

The new development must turn it into a theorem.

## 17.1 Do not invent `atlasNormCtx n`

The earlier draft assumed an unspecified canonical constructor

```text
atlasNormCtx : Nat -> NormCtx
```

whose Weil value happened to be the `n`-th Li coefficient.

That was a gap.

The corrected development must bind to the **actual test family used by the existing F1 explicit-formula / GenuineLi / TraceBridge chain**.

Call that existing family semantically:

```text
liTestData(n)
```

in this specification only.

`SourceBindings.lex.tex` must replace `liTestData` by the exact migrated declaration graph that already constructs the level-`n` Li/Weil datum.

If the current F1 tree does not construct a `NormCtx` from that datum, the implementation must prove a conversion theorem into `NormCtx`; it may not invent arbitrary window values.

## 17.2 Closed explicit formula

Define the actual closed family from the bound F1 level data:

```text
closedW(n) = closedWeilValue(contextOfLiData(n)).
```

Required theorem:

```lean
theorem closed_explicit_formula
    (E : StieltjesEta)
    (n : Nat)
    (hn : 0 < n) :
    Req (closedW E n) (genuineLamSeq E.eta n)
```

The proof must consume:

```text
- the current finite prime identity;
- polesOf / archTailOf specifications;
- the existing genuine Archimedean sequence;
- the current TraceBridge / GenuineLi explicit-formula algebra;
- the required zero-enumeration/Hadamard theorem if that part is not yet formalized.
```

If the existing zero-enumeration/Hadamard theorem is not present, it is an **analytic proof obligation**, not an axiom. The theorem cannot be marked closed until that construction is formalized.

This seam is classical explicit-formula mathematics. It is independent of Atlas positivity: it identifies the zero-free arithmetic/Archimedean formula with the genuine Li sequence but supplies no sign.

---

# 18. `Positivity.lex.tex`

Once `AtlasDominance` is proved, positivity is short.

```lean
theorem closedW_nonneg
    (E : StieltjesEta)
    (n : Nat)
    (hn : 0 < n) :
    Rnonneg (closedW E n) := by
  exact atlas_positivity (contextOfLiData E n)
```

Transport across the explicit-formula equality:

```lean
theorem genuineLi_nonneg
    (E : StieltjesEta) :
    LiNonneg (genuineLamSeq E.eta) := by
  intro n hn
  exact Rnonneg_congr
    (closed_explicit_formula E n hn)
    (closedW_nonneg E n hn)
```

No RH theorem is imported to prove either result.

---

# 19. `RiemannHypothesis.lex.tex`

This module imports the existing F1 endpoint.

Let `E` and `L : LiBridge E` be the already-constructed genuine analytic objects used by the current F1 program.

The final theorem is:

```lean
theorem riemann_hypothesis :
    AllZerosOnLine L.isZero := by
  exact
    (hodgeIndex_iff_RH E L).mp
      ((spectral_bridge_nonneg (genuineSpectralSquare E)).mp
        (genuineLi_nonneg E))
```

or the exact current equivalent chain.

If the current endpoint theorem `normAutocorr_positivity_iff_RH` is more direct after `closed_explicit_formula`, use it instead:

```lean
theorem riemann_hypothesis :
    AllZerosOnLine L.isZero := by
  exact
    (normAutocorr_positivity_iff_RH
      E L (closedW E)
      (closed_explicit_formula E)).mp
      (closedW_nonneg E)
```

The exact generated term must match the current theorem signature.

No hypothesis is permitted on `riemann_hypothesis`.

---

# 20. No-smuggling audit

The transitive dependency cone of

```text
atlas_arch_dominates_prime
atlas_coupled_nonneg
atlas_positivity
```

must reject any occurrence of:

```text
AllZerosOnLine
riemannHypothesis
LiNonneg
genuineLamSeq
zeroCayley
RHWitness
onLine_is_unit_modulus
strictRealizes or any structure whose field is the genuine target sign
ArchDominatesPrime as an input hypothesis
coupled positivity as an input hypothesis
closedWeilValue used to define its own Gram/factorization
sqrt(max(closedWeilValue,0)) or equivalent target-derived witness
vFrom / removed primeGram readback used without a new exact proof
native_decide
sorry
admit
author-declared axiom
```

The Atlas dominance proof may use:

```text
Atlas places/localization/self-duality
Atlas scales
F1 rational/real analysis
F1 Haar change of variables
F1 normalized autocorrelation
F1 projection/completion/operator infrastructure
von Mangoldt arithmetic
Gamma/digamma Archimedean analysis
```

because those are upstream of the RH endpoint.

The explicit-formula module has a separate audit: it may use the zeta/Li analytic stack but may not use RH or positivity.

---

# 21. Formal falsification gates

The implementing agent must not continue by semantic substitution when one of these gates fails.

## Gate F0 -- source binding

Every semantic role resolves to an exact current declaration.

**Failure:** a required role exists only in a historical rejected route.

**Action:** stop and expose the missing current bridge.

## Gate F1 -- rational bridge

Atlas rational operations and F1 Q operations commute exactly/up to Qeq.

**Failure:** the normalization depends on representation.

**Action:** fix the rational bridge; do not continue.

## Gate F2 -- normalized operator readback

The current scalar autocorrelation values are exactly quadratic reads of the normalized scale action.

**Failure:** the proposed operator is not the current F1 functional.

**Action:** reject that operator.

## Gate F3 -- closed Archimedean value

`polesOf` and `archTailOf` are constructed and satisfy the current Weil formula.

**Failure:** either remains an arbitrary Real.

**Action:** positivity cannot be claimed.

## Gate F4 -- current prime operator readback

The operator-level prime form equals `weilPrimePart(normAutocorrTest C)`.

**Failure:** only a `primeGram/vFrom` surrogate can be shown equal.

**Action:** reject the surrogate and return to the point-value operator expansion.

## Gate F5 -- Atlas coupling construction

A concrete factorization/intertwiner is built from Atlas + analytic data.

**Failure:** the only way to inhabit it is to add the desired inequality as a field.

**Action:** the Atlas dominance theorem remains genuinely open.

## Gate F6 -- Atlas dominance

`PrimeOp <= ArchOp` is kernel-proved with an RH-free dependency cone.

**Failure:** do not call the result Atlas Positivity.

## Gate F7 -- explicit formula

The closed normalized Weil family equals the genuine Li family.

**Failure:** `hid` remains a hypothesis.

**Action:** RH is not closed.

## Gate F8 -- final closure

`riemann_hypothesis` has no hypotheses and the axiom audit is within project policy.

---

# 22. Implementation order

The implementation must proceed in this order.

```text
AC-01  Freeze exact source bindings.
AC-02  Migrate/reuse current Atlas package.
AC-03  Prove Atlas Rat <-> F1 Q bridge.
AC-04  Realize Atlas rational scale in F1 dilation.
AC-05  Lift q^(-1/2) reciprocal adjointness to the operator level.
AC-06  Construct polesOf.
AC-07  Construct archTailOf and prove convergence/specification.
AC-08  Define closedWeilValue and prove exact current expansion.
AC-09  Define current point-value PrimeOp.
AC-10  Prove PrimeOp readback equals current genuine prime fold.
AC-11  Define current ArchOp.
AC-12  Prove ArchOp readback equals the closed Archimedean term.
AC-13  Define CoupledOp and prove scalar coupled readback.
AC-14  Import the exact existing Sonine/complement signed theorem.
AC-15  Build the concrete Atlas coupling factor/intertwiner.
AC-16  Prove Atlas operator dominance.
AC-17  Derive atlas_positivity.
AC-18  Bind the actual F1 Li/Weil test family; no invented NormCtx family.
AC-19  Discharge the closed explicit formula.
AC-20  Derive genuine Li nonnegativity.
AC-21  Apply the current RH equivalence endpoint.
AC-22  Run full kernel, leanchecker, axiom, no-smuggling, and reproducibility gates.
```

AC-15/AC-16 are the crux. They may be short if the newer Atlas coupling structure already provides the necessary contraction/factorization, but they may not be skipped.

---

# 23. The precise theorem to discover or assemble

The first draft called the missing theorem “Atlas Square Identity.”

That name hid too much.

The corrected central theorem is:

## Atlas Coupling Dominance

> Under the canonical analytic representation of the UOR Atlas place/scale system, the finite-place normalized prime operator is dominated by the Archimedean operator on every admissible normalized-autocorrelation state.

Formal shape:

```lean
theorem atlas_arch_dominates_prime
    (C : NormCtx) :
    forall x in AdmissibleAtlasSonine C,
      Rle
        (quad (PrimeOp C) x)
        (quad (ArchOp C) x)
```

The current target test `C.g` is a member of that subspace by a separate theorem:

```lean
theorem normAutocorr_in_atlas_sonine
    (C : NormCtx) :
    AdmissibleAtlasSonine C C.g
```

Only then derive:

```lean
theorem atlas_positivity
    (C : NormCtx) :
    Rnonneg (closedWeilValue C)
```

If the actual F1 Sonine constraints do not hold for every `NormCtx`, restrict `atlas_arch_dominates_prime` to the exact current admissible test class and prove that the Li/Weil test family belongs to it. Do not overstate the domain.

---

# 24. Optional stronger factorization theorem

If the Atlas coupling can be shown to factor the coupled operator, expose the stronger theorem:

Define `atlasDefectOp` by the concrete Atlas factor/intertwiner constructed in `AtlasCoupling.lex.tex`; its definition must mention only that upstream data and must not mention `closedWeilValue`, Li coefficients, zeros, or RH. Then prove:

```lean
theorem atlas_coupled_factorization
    (C : NormCtx) :
    CoupledOp C
    =
    adjoint (atlasDefectOp C) * atlasDefectOp C
```

Then:

```text
closedWeilValue C
=
||atlasDefectOp(C) g_C||^2
>= 0.
```

This recovers the intuitive “Atlas residual square” picture, but only **after** the factorization is actually proved.

It is not part of the base specification because F1 has already shown that the ordinary complement does not supply this factorization automatically.

---

# 25. Relationship to earlier Atlas positivity evidence

The earlier F1 `AtlasPositivityStructure` work remains useful evidence but not closure.

It establishes:

```text
- a conserved Atlas positivity balance;
- a positive-minus-reflection decomposition;
- both pieces PSD;
- the full finite Atlas spectral form indefinite;
- structural similarity to arch-minus-prime coupled Weil forms.
```

This tells us the correct algebraic category: **difference of positive forms**.

It does not establish the order relation between those forms.

Likewise the earlier Sonine work proves unconditional positivity after removing the negative band of the bare Archimedean multiplier, but the later coupled-complement theorem proves that the prime subtraction survives.

Therefore the role of these results in the final LexLean proof is:

```text
structure + decomposition + domain control + reusable projection machinery
```

not:

```text
preexisting proof of the final sign.
```

---

# 26. Relationship to the newer LexLean Atlas place coupling

The new Atlas formalization adds a much cleaner place/localization foundation than the older F1-local Atlas faceting.

That can materially simplify AC-15 because finite and Archimedean behavior can be required to arise from one global place/scale object rather than two unrelated formulas.

However the current Atlas theorems visible in the place layer establish:

```text
- localization;
- restricted-product coherence;
- diagonal injectivity;
- local self-duality;
- action/localization commutation.
```

These are **coherence theorems**.

They are not yet an inequality of analytic energies.

The required transport is therefore:

```text
Atlas local-global coherence
        +
F1 analytic scale representation
        +
current Arch/prime operator definitions
        |
        v
concrete contraction/factorization
        |
        v
operator dominance.
```

The formalization must exhibit the contraction/factorization. It cannot infer it from the word “self-dual.”

---

# 27. Exact logical dependency graph

The final proof graph must be:

```text
UOR Atlas places / scale / self-duality
               |
               v
       Rational + scale bridge
               |
               v
     normalized scale adjointness
               |
               +---------------------------+
               |                           |
               v                           v
        current finite operator      current Arch operator
               |                           |
               +-------------+-------------+
                             |
                             v
                  concrete Atlas coupling
                             |
                             v
                   PrimeOp <= ArchOp
                             |
                             v
                  closed Weil nonnegative
                             |
                             +--------------------+
                                                  |
classical explicit formula -----------------------+
                                                  |
                                                  v
                                      genuine Li nonnegative
                                                  |
                                                  v
                                          existing F1 RH iff
                                                  |
                                                  v
                                                 RH
```

There is no other hidden arrow.

---

# 28. Completion criterion

The document's formalization is implemented only when the repository contains the following closed declarations or exact equivalents:

```text
rational_bridge
normalized_scale_adjoint
polesOf
polesOf_spec
archTailOf
archTailOf_spec
closedWeilValue
closedWeilValue_expand
PrimeOp
prime_readback
ArchOp
arch_readback
CoupledOp
coupled_readback
atlasCoupling                -- concrete data, not a proposition field
atlas_arch_dominates_prime
atlas_positivity
closed_explicit_formula
genuineLi_nonneg
riemann_hypothesis
```

and all of these conditions hold:

```text
- no sorry;
- no admit;
- no native_decide;
- no author-declared axiom;
- no positivity/RH assumption hidden in a structure;
- no rejected historical surrogate on the live proof path;
- exact current normalized prime side;
- constructed Archimedean side;
- explicit formula is a theorem, not hid;
- Atlas dominance proof cone is RH-free;
- final RH theorem has no hypotheses;
- Lean kernel verification passes;
- same-kernel leanchecker replay passes;
- exact transitive axiom audit passes;
- migration equivalence to all reused F1 declarations passes.
```

---

# 29. Final assessment

After auditing the earlier document against the current F1 formal record, the complete and consistent conclusion is narrower than the first draft.

The project has already formalized nearly all of the **shape** of the desired closure:

```text
- Atlas difference-of-positive-form structure;
- genuine prime--Archimedean decomposition;
- normalized reciprocal autocorrelation;
- genuine current finite prime side;
- Sonine projection and complement analysis;
- constructive pre-Hilbert/completion/operator infrastructure;
- Li / Hodge / RH equivalence endpoint;
- multiple low-order positive coupling instances;
- explicit localization of the crux to the coupling sign.
```

But those results also formally rule out the shortcut used in the first draft:

```text
ordinary complement positivity != positivity of the full coupled Weil form.
```

The exact remaining mathematical content is therefore:

```text
UOR Atlas -> concrete analytic coupling -> ArchOp dominates PrimeOp.
```

If the newer LexLean Atlas coupling supplies a constructive factorization or contraction that F1 had not previously represented, the remaining work can indeed be a succinct assembly formalization.

If no such factorization/contraction follows from the Atlas declarations, then **Atlas Dominance is a real theorem still to be discovered**, and any document that simply writes

```text
Weil value = Atlas norm-square
```

has hidden RH inside an unsupported equality.

The corrected formal target is therefore not an assumed square identity but the falsifiable theorem:

```text
atlas_arch_dominates_prime
```

proved from the UOR Atlas place/scale coupling with an RH-free dependency cone.

Once that theorem and the independent explicit-formula seam are closed, the remaining path to RH is already formalized composition.
