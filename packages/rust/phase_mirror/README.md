# phase-mirror-rs: Mirror Dissonance Protocol

High-performance Rust implementation of the Mirror Dissonance Protocol (Phase Mirror).

## Features
- **L0 Invariants**: Foundation-tier validation checks (schema hash, permission bits, drift magnitude, nonce freshness).
- **Flexible Validator**: Class-based interface for validating individual or multiple L0 invariants with configurable thresholds.
- **Performance**: Targeted at sub-100ns execution for critical paths.
- **Auditable Evidence**: Detailed violation messages and evidence reports in JSON format.

## Verification
```bash
cargo test
```

## Alignment
Aligned with **ADR-003: Hierarchical PMD Compute** and **ADR-005: Nonce Rotation**.
