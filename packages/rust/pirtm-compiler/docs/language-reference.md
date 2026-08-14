# PIRTM Language Reference

## Overview

PIRTM/moc is a minimal language for expressing prime-recursive operations with contractivity proofs.

## Lexical Syntax

| Token | Description |
|-------|-------------|
| `let` | Variable binding keyword |
| `Ap(n)` | Prime atom with index `n` |
| `+` | Addition (binary exponentiation: `left^right`) |
| `-` | Subtraction |
| `if` | Conditional expression |
| Identifiers | `[a-zA-Z_][a-zA-Z0-9_]*` |
| Integers | `[0-9]+` |

## Expression Forms

### Literals
```
42          // Integer literal
```

### Prime Atoms
```
Ap(2)       // Prime atom with index 2
Ap(3)       // Prime atom with index 3
```

### Binary Operations
Binary expressions compute the multiplicity functor: `p^m` where `p` is the left operand and `m` is the right operand.

```
Ap(2) + 3    // 2^3 = 8
Ap(3) + 5    // 3^5 = 243
```

### Let Bindings
```
let x = Ap(2);
let y = x + 3;
y
```

## Semantics

- Every expression evaluates to a prime-indexed operator
- Binary operations use rational-exponentiation: `p^m`
- The multiplicity accumulator tracks the combined result
- Overflow protection: `2^64` triggers compile error

## Examples

```pirtm
// Simple expression
42

// Prime atom
Ap(2)

// Exponentiation
Ap(3) + 5  // 3^5 = 243

// Chained operations
let x = Ap(2);
let y = x + 3;
y
```