# MEA Rust Crate

Formal verification framework for monodial ensemble aggregation.

## Modules

- `monodial` — Monoidal category structures (objects, morphisms, ⊗, I)
- `ensemble` — Weighted ensembles with tensor product
- `aggregate` — Aggregation operations (sum, product, weighted average, max, min)
- `verify` — Algebraic law verification (associativity, identity, commutativity)
- `codec` — Serialization with round-trip proofs
- `kani_proofs` — Kani formal verification proofs

## Usage

```rust
use monodial_ensemble_aggregation::{Ensemble, WeightedElement, AggregateOp, aggregate};

// Create an ensemble
let mut ensemble: Ensemble<i32> = Ensemble::new(1);
ensemble.add(WeightedElement::new(10, 0.3));
ensemble.add(WeightedElement::new(20, 0.7));

// Aggregate
let result = aggregate(&ensemble, AggregateOp::WeightedAverage).unwrap();
println!("Result: {}", result.value());
```

## Verification

```bash
cargo test
cargo kani -- kani_proofs.rs
```

## CLI

```bash
cargo run -- aggregate avg 10 20 30
cargo run -- verify
cargo run -- monodial
```
