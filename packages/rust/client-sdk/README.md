# client-sdk-rs: Multiplicity Client SDK

High-performance Rust client SDK for interacting with the Multiplicity substrate services.

## Features
- **ZK Proof Submission**: Asynchronous API to submit Zero-Knowledge proofs for chain verification.
- **System Health Checks**: Built-in health check endpoints for engine observability.
- **Type-Safe**: Uses `serde` for all request/response serialization.
- **Asynchronous**: Built on `reqwest` and `tokio` for efficient network I/O.

## Usage
### Build
```bash
cargo build --release
```

## Alignment
Designed to provide a native Rust interface to the Multiplicity governance and proving infrastructure.
