# csl-rs: Consent-Spectral-Limit Gating

Runtime drift enforcement and consent-based gating logic.

## Features
- **Drift Monitoring**: L1-norm based semantic drift calculation.
- **Silence Mechanism**: Enforces priming requirements before engine actuation.
- **Prime Gating**: Logic for application-layer commit validation ($commit \in \mathbb{P}$).

## Verification
```bash
cargo test
```
