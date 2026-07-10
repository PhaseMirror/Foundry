# hcalc-rs: Health State Terminal Classifier

Rust port of the H-Calculator for terminal state determination in multiplicity-aware systems.

## Features
- **4-Gate Enforcement**: Physio, Contraction, Epistemic, and Runtime gating.
- **Brain Aging Model**: Dynamical system simulation for healthspan monitoring.
- **Extended Kalman Filter (EKF)**: High-precision state estimation with SVD-based pseudo-inverse.
- **CLI Interface**: JSON-native input/output for standalone or pipeline execution.

## Verification
```bash
cargo test
cargo run -- --input sample.json
```
