I actually think this is a stronger architectural decision if your goal is a **production-verifiable implementation** rather than a purely formalized mathematics library.

However, it changes the philosophy of the project substantially.

Instead of

> **Lean + Mathlib as trusted mathematics**

you are choosing

> **Lean as the specification language**
>
> **Rust as the executable semantics**
>
> **Kani as the proof engine**

That means the trusted base shifts from Mathlib to a combination of:

* Lean kernel
* Rust compiler
* Kani verifier (CBMC)
* Your explicitly defined axioms (ideally none)

I would rewrite ADR-0001 accordingly.

---

# ADR-0001 — Verified Mathematical Foundation

## Decision

Multiplicity SHALL NOT depend upon Mathlib.

Instead the mathematical foundation will be implemented directly in Rust and verified using Kani.

Lean serves as the formal specification layer and proof orchestration language.

Rust is the reference implementation.

Kani is the executable verifier.

---

# Architectural Principle

Every mathematical object must exist in three forms.

```
Definition
      │
      ▼
Lean Specification
      │
      ▼
Rust Implementation
      │
      ▼
Kani Verification
```

Nothing is accepted until all three agree.

---

# Zero Trust Mathematics

The project intentionally avoids opaque dependencies.

Therefore

* no Mathlib proofs
* no imported multiplicity theorems
* no black-box algebra

Every theorem required by Multiplicity is either

* re-derived

or

* imported only after independent verification.

---

# No Placeholder Policy

The repository SHALL reject

```lean
sorry
```

```lean
admit
```

```lean
axiom
```

except for the Lean kernel itself.

Likewise Rust SHALL reject

```rust
unsafe
```

unless accompanied by a machine-checked safety proof.

---

# Proof Philosophy

Every theorem requires

1. Lean specification
2. executable Rust implementation
3. Kani verification
4. deterministic regression tests

A theorem is considered accepted only when all four succeed.

---

# Production Layout

```
multiplicity/

    lean/
        Spec/
        Proofs/

    rust/
        multiplicity-core/
        multiplicity-primes/
        multiplicity-algebra/

    kani/
        proofs/
        regression/

    ci/
        verify.yml
```

---

# Mathematical Scope (Phase 1)

Rather than reproducing all of Mathlib, the verified kernel should remain intentionally small:

```
Natural Numbers

Integers

Finite Sets

Multisets

Prime Predicate

Divisibility

GCD

LCM

Prime Factorization

Polynomial Evaluation

Polynomial Root Multiplicity
```

Everything else is layered above these.

---

## Verification Rules

Every public function must satisfy one or more of:

* Totality
* Functional correctness
* Invariant preservation
* Boundary safety
* Overflow freedom
* Determinism

using Kani proofs.

Example:

```rust
#[kani::proof]
fn factorization_reconstructs_original() {
    let n: u64 = kani::any();

    kani::assume(n > 1);

    let f = factor(n);

    assert_eq!(product(&f), n);
}
```

---

## Additional ADR I'd Add

Given this philosophy, I'd actually insert another ADR before everything else.

### ADR-0000 — Verification Doctrine

This document establishes immutable project rules:

1. No `sorry`.
2. No `admit`.
3. No unchecked `unsafe`.
4. No theorem accepted without executable verification.
5. Every proof has an executable witness.
6. CI fails if any proof or verification is incomplete.
7. Specifications and implementations must remain synchronized.

This becomes the constitutional document for the repository, with ADR-0001 then defining the mathematical kernel built under those rules.

One point I would still recommend reconsidering is the complete replacement of Mathlib. Mathlib contains many mature, mechanically verified results that can be valuable as a reference, even if they are not part of your trusted implementation. You can maintain a zero-trust production policy while still using Mathlib as an external oracle for cross-validation during development, without making it a runtime or proof dependency. That gives you an independent benchmark while preserving your requirement that every accepted theorem be proved and verified within your own Rust/Kani/Lean stack.
