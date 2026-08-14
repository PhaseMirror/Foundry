# shell-rs: Multiplicity Shell Evaluator

High-performance Rust implementation of the Multiplicity Shell evaluation and conflict resolution protocol (ADR-003, ADR-008).

## Features
- **Deterministic Precedence**: Implements ADR-003 rank-based evaluation order for artifacts.
- **Conflict Resolution**: Implements ADR-008 conflict resolution lattice (Precedence/Security/Ethics).
- **Type Safety**: Enforced structured evaluation results and conflict records.
- **Traceability**: Audit-ready input/output hashing for all evaluation passes.

## Usage
### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```
