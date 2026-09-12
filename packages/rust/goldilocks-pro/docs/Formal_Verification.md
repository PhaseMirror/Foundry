# Goldilocks Arithmetic Kernel: Formal Verification (Lean 4)

This document describes the formal verification of the Goldilocks field arithmetic using the Lean 4 theorem prover.

## ✦ 1. Scope of Verification

The formal proof targets the **Lever 1 Arithmetic Kernel**, specifically the correctness of the modular reduction logic used for field multiplication.

### The Goldilocks Prime
The field is defined over the prime $p$:
$$p = 2^{64} - 2^{32} + 1$$

In hexadecimal: `0xFFFFFFFF00000001`.

## ✦ 2. Proved Invariants

### 2.1 The Reduction Invariant
The multiplication kernel relies on the following property to perform fast modular reduction:
$$2^{64} \equiv 2^{32} - 1 \pmod p$$

**Lean 4 Theorem:** `reduction_invariant`
```lean
theorem reduction_invariant : (2^64 : Field) = (2^32 - 1 : Field)
```

### 2.2 Multiplication Correctness
For any 128-bit product $x = hi \cdot 2^{64} + lo$, the reduced form is:
$$x \equiv hi \cdot (2^{32} - 1) + lo \pmod p$$

**Lean 4 Theorem:** `mul_red_correct`
```lean
theorem mul_red_correct (hi lo : ℕ) : 
  (hi * 2^64 + lo : Field) = (hi * (2^32 - 1) + lo : Field)
```
This theorem formally guarantees that substituting the high bits with the shifted low bits (as implemented in `scalar.rs`) results in a mathematically equivalent value in $\mathbb{F}_p$.

## ✦ 3. Lean 4 Source

The full source code for the proof is located at:
`goldilocks-kernel/arithmetic-kernel/lean-proofs/Goldilocks.lean`

## ✦ 4. Assumptions

1.  **Mathlib:** The proof assumes the availability of the Lean mathematical library (Mathlib), specifically `Data.ZMod.Basic`.
2.  **Primality:** The primality of $p$ is treated as an axiom (`p_prime`). While $p$ is a known prime (the Solinas prime used in Goldilocks), proving it from first principles in Lean would require a dedicated primality prover.

---
*Multiplicity Theory / Phase Mirror Oracle Pro*
