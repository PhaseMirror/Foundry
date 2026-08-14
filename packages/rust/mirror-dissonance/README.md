# mirror-dissonance-rs: Core Dissonance Library

High-performance Rust implementation of the Mirror Dissonance Protocol core library.

## Features
- **Schema Definitions**: Typed structures for rule violations, oracle inputs, and machine decisions.
- **Policy Engine**: Implementation of the decision-making logic with configurable thresholds and circuit-breaker support.
- **Rules Registry**: Foundation for automated consistency checks across code and configuration.
- **Asynchronous Evaluation**: Built on `tokio` for efficient concurrent rule execution.

## Verification
```bash
cargo test
```

## Alignment
Aligned with **ADR-003: Hierarchical PMD Compute** and **ADR-009: Conflict Log Schema**.
