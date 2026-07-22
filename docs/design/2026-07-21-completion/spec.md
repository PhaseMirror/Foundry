# Completion Adjunction Design Spec

**Date**: 2026-07-21
**Status**: Implemented

## Overview

The completion functor C : PartialUC → UC constructs the free total system
from a partial system. It is the left adjoint to the forgetful functor
U : UC → PartialUC.

## Construction

### 1. Term Algebra

```
inductive Term (X : Type) : Type
  | var : X → Term X
  | compose : Term X → Term X → Term X
  | closure : Term X → Term X
```

### 2. Lawful Congruence

The smallest equivalence relation containing:
- Composition axiom: if compose_p x y = some z, then Comp(Var x, Var y) ~ Var z
- Closure axiom: if closure_p x = some y, then Close(Var x) ~ Var y
- Congruence: if t₁ ~ t₂, then Comp(t₁, t₃) ~ Comp(t₂, t₃) and Close(t₁) ~ Close(t₂)

### 3. Quotient Completion

```
def Carrier (P : PartialUC X) : Type :=
  Quotient (lawful_setoid P)
```

### 4. Lifted Operations

- compose_q: lifts Term.compose to the quotient
- closure_q: lifts Term.closure to the quotient

## Properties

- **Universal**: Any map P → V factors through C(P)
- **Injective unit**: var_embed is injective
- **Preserves structure**: compose_q and closure_q are well-defined on equivalence classes

## Rust Implementation

The completion is implemented via Union-Find with path compression and union-by-rank.
The saturation loop closes the congruence by applying composition, closure, and
congruence rules until fixpoint.

## Verification

- **Lean**: 5 theorems proven (zero sorry)
- **Kani**: 3 harnesses (composition, congruence, termination)
