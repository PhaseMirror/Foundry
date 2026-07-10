# security-rs: Multiplicity Security Core

High-performance Rust implementation of the security primitives for the Multiplicity substrate.

## Features
- **Audit Logging**: Asynchronous, JSON-serialized audit trails for state-changing actions.
- **CAS Registry**: Commitment Attestation State (CAS) registry for secure state attestation.
- **Type Safety**: Enforced serialization of cryptographic certificates and audit entries.

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
Aligned with **ADR-K-01: Poseidon2 CAS Commitment** and system-wide security policies for auditable state transitions.
