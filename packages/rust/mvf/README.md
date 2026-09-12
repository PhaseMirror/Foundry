# mvf-rs: Multiplicity Viability Flow

High-performance Rust implementation of the Multiplicity Viability Flow (MVF) core.

## Features
- **PIRTM Governance**: Implements the SPEC-Λm-GOV runtime contract and ADR-04 diagnostics.
- **Contractivity Enforcement**: Actively rescales coupling parameter $\lambda_m$ to enforce the $c(t) < \epsilon$ bound.
- **Prime Signature Score (PSS)**: Entropy-based proxy for sine-kernel coherence to monitor ontological drift.
- **Simulator**: `MvfSimulator` provides a complex-valued state-space environment for tracking trajectories and resonance projections.
- **Auditable Logging**: Emits machine-readable telemetry JSON logs for all governance events (e.g., `ADMISSIBLE`, `ONTOLOGICAL_DRIFT`, `STRESS_HALT`).

## Usage
### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```

## Alignment
Aligned with **ADR-04: Diagnostics** and **RFC-0001: MVF Governance**.
