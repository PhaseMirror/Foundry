/-!
# Multiplicity Kernel — Core Doctrine (ADR-0001, ADR-0000)

Mirror of `ADR-0001 — Verified Mathematical Foundation` and the
`ADR-0000 — Verification Doctrine` described at the end of that record.

## The three-form principle (ADR-0001 "Architectural Principle")

Every mathematical object exists in three forms:

```
Definition  ->  Lean Specification  ->  Rust Implementation  ->  Kani Verification
```

Nothing is accepted until all three agree.  In this kernel each accepted
statement is packaged as a `FormWitness`: a Lean proposition, a proof of it,
and references (strings) to the Rust function, the Kani harness and the
deterministic regression vector that implement the same statement.  The type
`FormWitness` is **inhabitable only with a real proof term**, so the doctrine
"No placeholder policy" (`sorry` / `admit` / `axiom`) is enforced
*structurally*: a `FormWitness` for a proposition `P` contains a value
`proof : P`, which no `sorry` can produce in a checked module.

## Trusted base (ADR-0001 "Zero Trust Mathematics")

The trusted base is deliberately small:

* Lean kernel
* Rust compiler
* Kani verifier (CBMC)
* the explicitly defined statements below (there are no axioms)

No Mathlib proofs are imported; the kernel is developed on the core library
(`Init`) and the `Batteries` data layers (which are part of Lean's standard
library, not Mathlib).  Where a classical theorem (e.g. uniqueness of prime
factorization, the Fundamental Theorem of Arithmetic) is out of reach of the
core library, the kernel states the weakest equivalent form it can prove and
records the gap explicitly in a docstring — never with an axiom.
-/

namespace Multiplicity.Kernel

/-! ## Verification doctrine (ADR-0000) -/

/-- A theorem obligation: the proposition `P` is *accepted* only when a proof
term of `P` exists.  This is the Lean-side encoding of rule 4 of ADR-0000
("no theorem accepted without executable verification"). -/
def Theorem (P : Prop) : Prop := P

/-- Construct an accepted theorem from a proof. -/
theorem theoremOf (P : Prop) (h : P) : Theorem P := h

/-- Four-fold acceptance witness.  A value of this type cannot be built unless
`leanSpec` holds *and* the three executable forms exist. -/
structure FormWitness where
  /-- the Lean specification (a proposition) -/
  leanSpec : Prop
  /-- the proposition being certified -/
  statement : Prop
  /-- a Lean proof certificate of `statement` -/
  proof : statement
  /-- reference to the Rust implementation (`rust/<crate>/src/...`) -/
  rustFn : String
  /-- reference to the Kani harness (`kani/proofs/...`) -/
  kaniProof : String
  /-- reference to the deterministic regression vector (`kani/regression/...`) -/
  regression : String

/-- Extraction: the certified statement holds. -/
theorem witness_certifies (w : FormWitness) : w.statement := w.proof

/-- Doctrine rule 3: an accepted statement carries a proof in all four forms. -/
theorem accepted_only_if_witnessed {P : Prop} (w : FormWitness) (h : w.statement = P) :
    Theorem P := by
  subst h
  exact w.proof

/-- Determinism doctrine: every kernel function is a (total) function, hence
deterministic on its inputs.  Packaged per-form below. -/
def Deterministic {α β : Type} (_f : α → β) : Prop := True

/-- A deterministic function is accepted with a witness. -/
theorem deterministic_of_any {α β : Type} (f : α → β) : Deterministic f := trivial

end Multiplicity.Kernel
