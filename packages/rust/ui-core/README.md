# ui-core-rs: UI Logic Core

Core logic ported from the `ui` TypeScript package, providing high-performance, verifiable implementations of frontend hooks and utilities for the Multiplicity substrate.

## Features
- **PrimeGate**: High-performance Rust implementation of the Miller-Rabin prime test used in front-end gating.
- **Wasm-Ready**: Designed to be compiled to WebAssembly for seamless integration with the existing React/TypeScript frontend.

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
Direct port of TypeScript `usePrimeGate` logic, providing a high-performance, audited engine for frontend components.
