# zeta-rs: Conflict Resolution & Evaluation Order

Tier-based reconciliation and safety veto enforcement.

## Features
- **Conflict Logging**: ADR-009 compliant 7-step reconciliation logs (JSONL).
- **Tier Precedence**: Implements Spectral > Structural > Predictive > Theoretical > Safety.
- **Safety Veto**: ADR-008 circuit-breaker for Tier-5 artifacts.
- **Traceability**: Automated UUID-v4 trace tracking for all resolution events.

## Verification
```bash
cargo test
```
