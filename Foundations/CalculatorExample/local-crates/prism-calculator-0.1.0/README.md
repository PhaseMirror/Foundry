# Calculator

A Lean-verified, Prism-generated checked i64 calculator.

This package is generated from the authoritative Prism application model. Do not edit generated Rust.

```rust
use prism_calculator::dispatchBytes;

assert_eq!(dispatchBytes(vec![49, 9, 97, 100, 100, 9, 48, 9, 48]), vec![49, 9, 111, 107, 9, 48]);
```
