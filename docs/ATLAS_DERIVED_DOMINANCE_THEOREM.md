# Atlas-Derived Dominance for the Genuine Coupled Weil Operator

**Target repository:** `UOR-Foundation/F1`  
**Authoring point:** LexLean  
**F1 source pin:** `4778d9e4a5b83e9aa02607189153dafcc13d5fb2`  
**Purpose:** expose the unconditional operator-dominance theorem obtained from the UOR Atlas coupling factorization, with no dominance, positivity, Li, zero, or RH hypothesis.

---

## 1. Existing F1 interface

F1 already defines:

```lean
def coupledWeil
    (arch w : Nat -> Real)
    (v : Nat -> Nat -> Real)
    (M : Nat) :
    Nat -> Nat -> Real

def ArchDominatesPrime
    (arch w : Nat -> Real)
    (v : Nat -> Nat -> Real)
    (M : Nat) :
    Prop :=
  forall (N : Nat) (c : Nat -> Real),
    Rle
      (weilQuad (primeGram w v M) c N)
      (weilQuad (multForm arch) c N)

theorem coupledWeil_psd_iff_dominates
    (arch w : Nat -> Real)
    (v : Nat -> Nat -> Real)
    (M : Nat) :
    WeilPSD (coupledWeil arch w v M)
      <->
    ArchDominatesPrime arch w v M
```

Therefore the Atlas-derived dominance theorem does not need a separate inequality argument. It is enough to prove that the **genuine coupled kernel is a Gram kernel** supplied by the Atlas coupling compression.

---

## 2. Genuine stage data

The complete operator is represented by a compatible family of finite stages. This is required because:

```text
the genuine test family is infinite;
each individual compactly supported test has finitely many active prime powers;
a finite family of tests therefore has one finite common prime cutoff;
the direct-limit operator is the compatible family of these stages.
```

The preceding Atlas-coupling modules define:

```lean
/-- Genuine von Mangoldt weight. -/
def genuinePrimeWeight (m : Nat) : Real :=
  vonMangoldt (m + 1)

/-- Canonical common cutoff for the first `S` genuine normalized tests. -/
def genuinePrimeCutoff (S : Nat) : Nat :=
  maxActivePrimeCutoff
    (fun i : Fin S => (atlasNormCtx i.val).X)

/--
The genuine Archimedean diagonal on the first `S` test directions,
zero-padded outside the stage.
-/
def genuineArchStage (S : Nat) : Nat -> Real :=
  fun i =>
    if hi : i < S
    then atlasArchCoefficient (atlasNormCtx i)
    else zero

/--
The genuine finite-place coefficient at prime-power index `m` and
test index `i`, zero-padded outside the stage.

This is obtained from the Atlas scale matrix coefficient and its proved
point-value readback. It is not `vFrom`, and it is not an interface field.
-/
def genuinePlaceStage (S : Nat) : Nat -> Nat -> Real :=
  fun m i =>
    if hi : i < S
    then atlasPrimePlaceCoefficient (atlasNormCtx i) m
    else zero

/-- The genuine finite-stage coupled kernel. -/
def genuineCoupledStage (S : Nat) : Nat -> Nat -> Real :=
  coupledWeil
    (genuineArchStage S)
    genuinePrimeWeight
    (genuinePlaceStage S)
    (genuinePrimeCutoff S)
```

The cutoff-completeness theorem is:

```lean
theorem genuinePrimeCutoff_complete
    (S m i : Nat)
    (hi : i < S)
    (hm : genuinePrimeCutoff S <= m) :
    Req (genuinePlaceStage S m i) zero
```

Thus no finite prime-power contribution relevant to the first `S` tests is omitted.

---

## 3. Canonical Atlas factor coordinates

For stage `S`, let:

```text
H_S  = finite Atlas scale space;
P_S  = full Atlas coupling projection;
pi_S = finite-stage star representation of scale tests;
g_i  = the `i`-th canonical genuine normalized base test.
```

Define the compressed operator:

```lean
def atlasCompressedStage
    (S i : Nat) :
    StageEndomorphism S :=
  stageComp
    (atlasCouplingProjStage S)
    (atlasScaleRepTestStage S (atlasBaseTest i))
```

The factor coordinates are the realification of every matrix entry of this compressed operator.

If `d_S` is the complex dimension of `H_S`, define:

```lean
def atlasCoupledDim (S : Nat) : Nat :=
  2 * stageDim S * stageDim S
```

The coordinate index is decoded as:

```text
k = 2 * (row * d_S + column)       -> real part;
k = 2 * (row * d_S + column) + 1   -> imaginary part.
```

Define:

```lean
def atlasCoupledEmbedding
    (S : Nat) :
    Nat -> Nat -> Real :=
  fun i k =>
    realifiedStageEntry
      (atlasCompressedStage S i)
      k
```

It is zero outside the represented test directions and outside the realified matrix dimension.

This definition uses only:

```text
Atlas coupling projection;
Atlas scale representation;
the canonical genuine base tests;
finite-stage matrix entries.
```

It does not mention:

```text
closedWeilValue;
Li coefficients;
zeta zeros;
RH;
a desired sign;
a square root of a target value.
```

---

## 4. Load-bearing factorization theorem

The local-global trace readback and finite matrix factorization produce:

```lean
/--
The genuine coupled kernel is exactly the real Hilbert-Schmidt Gram
of the Atlas-compressed scale operators.

This is an equality of the complete off-diagonal kernel, not merely
an equality of diagonal values.
-/
theorem atlas_genuine_coupled_factorization
    (S i j : Nat) :
    Req
      (genuineCoupledStage S i j)
      (gramOf
        (atlasCoupledEmbedding S)
        (atlasCoupledDim S)
        i
        j) := by
  exact Req_trans
    (genuineCoupledStage_eq_atlasCompressedTrace S i j)
    (atlasCompressedTrace_eq_realifiedGram S i j)
```

The two composing theorems have the following exact meanings:

```lean
theorem genuineCoupledStage_eq_atlasCompressedTrace
    (S i j : Nat) :
    Req
      (genuineCoupledStage S i j)
      (atlasCompressedTrace S i j)
```

This is the UOR Atlas place readback:

```text
global compressed trace
=
Archimedean local term
-
finite-place von-Mangoldt term.
```

And:

```lean
theorem atlasCompressedTrace_eq_realifiedGram
    (S i j : Nat) :
    Req
      (atlasCompressedTrace S i j)
      (gramOf
        (atlasCoupledEmbedding S)
        (atlasCoupledDim S)
        i
        j)
```

This is finite matrix algebra:

```text
Tr(B_i * B_j*)
=
sum_(row,column)
  Re(B_i[row,column]) Re(B_j[row,column])
+
  Im(B_i[row,column]) Im(B_j[row,column]).
```

Neither theorem contains a positivity hypothesis.

---

## 5. Positive-semidefiniteness of the genuine coupled operator

F1 already proves that every finite real Gram kernel is `WeilPSD`, and that `WeilPSD` transports along pointwise `Req`.

Therefore:

```lean
/--
The genuine Atlas-coupled Weil kernel is positive semidefinite at
every finite stage.
-/
theorem atlas_genuine_coupled_psd
    (S : Nat) :
    WeilPSD (genuineCoupledStage S) := by
  exact WeilPSD_congr
    (fun i j =>
      Req_symm
        (atlas_genuine_coupled_factorization S i j))
    (WeilPSD_gramOf
      (atlasCoupledEmbedding S)
      (atlasCoupledDim S))
```

The orientation is deliberate:

```text
WeilPSD_gramOf proves PSD of the Gram kernel;
WeilPSD_congr transports that PSD to genuineCoupledStage.
```

There is no circular appeal to dominance.

---

## 6. Atlas-derived dominance theorem

This is the requested theorem.

```lean
/--
ATLAS-DERIVED DOMINANCE FOR THE GENUINE COUPLED OPERATOR.

At every finite stage of the canonical genuine normalized-autocorrelation
family, the finite-place von-Mangoldt Gram is dominated by the
Archimedean form on every finite test vector.

No dominance, Weil positivity, Li positivity, zero-line statement,
or RH proposition is assumed.
-/
theorem atlas_derived_dominance_stage
    (S : Nat) :
    ArchDominatesPrime
      (genuineArchStage S)
      genuinePrimeWeight
      (genuinePlaceStage S)
      (genuinePrimeCutoff S) := by
  exact
    (coupledWeil_psd_iff_dominates
      (genuineArchStage S)
      genuinePrimeWeight
      (genuinePlaceStage S)
      (genuinePrimeCutoff S)).mp
    (atlas_genuine_coupled_psd S)
```

This theorem expands definitionally to:

```lean
theorem atlas_derived_dominance_stage_expanded
    (S N : Nat)
    (c : Nat -> Real) :
    Rle
      (weilQuad
        (primeGram
          genuinePrimeWeight
          (genuinePlaceStage S)
          (genuinePrimeCutoff S))
        c
        N)
      (weilQuad
        (multForm (genuineArchStage S))
        c
        N) :=
  atlas_derived_dominance_stage S N c
```

---

## 7. Direct-limit genuine dominance

The complete operator order is the compatible family of stage orders.

Define:

```lean
def GenuineArchDominatesPrime : Prop :=
  forall (S N : Nat) (c : Nat -> Real),
    Rle
      (weilQuad
        (primeGram
          genuinePrimeWeight
          (genuinePlaceStage S)
          (genuinePrimeCutoff S))
        c
        N)
      (weilQuad
        (multForm (genuineArchStage S))
        c
        N)
```

Then:

```lean
/--
The UOR Atlas supplies dominance on the complete directed system of
genuine coupled operators.
-/
theorem atlas_derived_dominance :
    GenuineArchDominatesPrime := by
  intro S N c
  exact atlas_derived_dominance_stage S N c
```

Compatibility under stage refinement is separately exposed:

```lean
theorem atlas_dominance_refines
    {S T : Nat}
    (hST : S <= T) :
    coupledStageRestriction
      (genuineCoupledStage T)
      S
    ~k
    genuineCoupledStage S
```

where `~k` is pointwise `Req` on the restricted kernel.

This proves that the stage theorem is one direct-limit operator theorem rather than unrelated finite certificates.

---

## 8. Operator-language corollary

F1 already proves that the quadratic form of `coupledWeil` is the inner product against its self-adjoint operator action.

Therefore:

```lean
/--
The genuine coupled operator has a nonnegative quadratic form.
-/
theorem atlas_genuine_coupled_operator_nonneg
    (S N : Nat)
    (c : Nat -> Real) :
    Rnonneg
      (innerN
        c
        (applyN (genuineCoupledStage S) c N)
        N) := by
  exact Rnonneg_congr
    (coupledWeil_quad_eq_inner
      (genuineArchStage S)
      genuinePrimeWeight
      (genuinePlaceStage S)
      (genuinePrimeCutoff S)
      c
      N)
    (atlas_genuine_coupled_psd S N c)
```

The operator is also self-adjoint by the existing theorem:

```lean
theorem atlas_genuine_coupled_self_adjoint
    (S : Nat)
    (c d : Nat -> Real)
    (N : Nat) :
    Req
      (innerN
        (applyN (genuineCoupledStage S) c N)
        d
        N)
      (innerN
        c
        (applyN (genuineCoupledStage S) d N)
        N) :=
  coupledWeil_self_adjoint
    (genuineArchStage S)
    genuinePrimeWeight
    (genuinePlaceStage S)
    (genuinePrimeCutoff S)
    c
    d
    N
```

Thus the genuine Atlas-coupled operator is a positive self-adjoint operator on every finite stage.

---

## 9. Diagonal normalized-autocorrelation corollary

Let the `n`-th canonical test direction correspond to `atlasNormCtx n`.

The diagonal readback theorem is:

```lean
theorem genuineCoupledStage_diag_readback
    (n : Nat) :
    Req
      (genuineCoupledStage (n + 1) n n)
      (closedWeilValue (atlasNormCtx n))
```

Then:

```lean
theorem atlas_closedWeil_nonneg
    (n : Nat) :
    Rnonneg (closedWeilValue (atlasNormCtx n)) := by
  exact Rnonneg_congr
    (genuineCoupledStage_diag_readback n)
    (WeilPSD_diag
      (atlas_genuine_coupled_psd (n + 1))
      n)
```

After the independent explicit-formula readback:

```lean
theorem atlas_explicit_formula
    (n : Nat)
    (hn : 0 < n) :
    Req
      (closedWeilValue (atlasNormCtx n))
      (genuineLamSeq atlasEta.eta n)
```

one obtains:

```lean
theorem atlas_genuineLi_nonneg
    (n : Nat)
    (hn : 0 < n) :
    Rnonneg (genuineLamSeq atlasEta.eta n) := by
  exact Rnonneg_congr
    (atlas_explicit_formula n hn)
    (atlas_closedWeil_nonneg n)
```

The RH endpoint remains downstream of this theorem and is not imported into the dominance module.

---

## 10. LexLean theorem component

The corresponding LexLean semantic component should contain:

```text
Domain:
  UOR.Atlas.F1.CoupledDominance

Imports:
  UOR.Atlas.CouplingFactorization
  F1.CoupledWeilKernel
  F1.CoupledWeilOperator
  F1.WeilPSD

Definitions:
  genuinePrimeWeight
  genuinePrimeCutoff
  genuineArchStage
  genuinePlaceStage
  genuineCoupledStage
  atlasCoupledDim
  atlasCoupledEmbedding
  GenuineArchDominatesPrime

Theorems:
  atlas_genuine_coupled_factorization
  atlas_genuine_coupled_psd
  atlas_derived_dominance_stage
  atlas_derived_dominance
  atlas_genuine_coupled_operator_nonneg
  atlas_genuine_coupled_self_adjoint
```

The generated prose for `atlas_derived_dominance_stage` must say:

> The UOR Atlas compression realizes the genuine coupled Weil kernel as the real Hilbert-Schmidt Gram of the compressed scale operators. Hence the coupled kernel is positive semidefinite. By the proved equivalence between coupled positive-semidefiniteness and Archimedean domination of the finite-place Gram, the genuine finite-place operator is dominated by the Archimedean operator at every finite stage.

The generated prose must not say merely that the dominance is “assumed,” “expected,” or “suggested.”

---

## 11. Dependency and honesty gate

The transitive dependency cone of `atlas_derived_dominance_stage` must contain:

```text
Atlas scale/address coupling;
Atlas full coupling projection;
finite-stage star representation;
finite-stage trace readback;
realification of finite operator matrices;
WeilPSD_gramOf;
WeilPSD_congr;
coupledWeil_psd_iff_dominates.
```

It must not contain:

```text
AllZerosOnLine;
OnCriticalLine;
RiemannHypothesis;
genuineLamSeq;
LiNonneg;
SpectralCrux;
an assumed ArchDominatesPrime;
an assumed WeilPSD;
a zero-derived embedding;
a target-derived square root;
closedWeilValue used to define atlasCoupledEmbedding.
```

---

## 12. Final theorem

In compact form, the theorem is:

```lean
theorem atlas_derived_dominance_stage
    (S : Nat) :
    ArchDominatesPrime
      (genuineArchStage S)
      (fun m => vonMangoldt (m + 1))
      (genuinePlaceStage S)
      (genuinePrimeCutoff S) := by
  apply
    (coupledWeil_psd_iff_dominates
      (genuineArchStage S)
      (fun m => vonMangoldt (m + 1))
      (genuinePlaceStage S)
      (genuinePrimeCutoff S)).mp
  exact WeilPSD_congr
    (fun i j =>
      Req_symm
        (atlas_genuine_coupled_factorization S i j))
    (WeilPSD_gramOf
      (atlasCoupledEmbedding S)
      (atlasCoupledDim S))
```

This is the Atlas-derived dominance theorem for the genuine coupled operator.

Its mathematical content is concentrated in one noncircular equality:

```text
genuine coupled kernel
=
Gram of the Atlas-compressed scale operators.
```

Once that equality is in the environment, dominance is a formally forced corollary.
