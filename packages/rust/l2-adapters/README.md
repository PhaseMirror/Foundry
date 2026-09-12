# l2-adapters-rs: Layer 2 Rollup Network Adapters

High-performance Rust implementation of the blockchain adapters for deploying and verifying Multiplicity STARK proofs on Ethereum Layer 2 networks.

## Features
- **IChainAdapter Trait**: Standardized, asynchronous interface for interacting with EVM-compatible rollups.
- **Supported Networks**:
    - **Base**: `L2BaseAdapter` for interacting with the Coinbase L2 ecosystem.
    - **Arbitrum One**: `ArbitrumAdapter` for high-throughput EVM proof verification.
- **Proof Submission**: Handles packaging `ProofSubmission` structs and evaluating `TransactionResult` state updates.
- **Contract Addressing**: Native tracking of deployed Multiplicity verifier architectures (`root_verifier`, `miller_rabin_verifier`, etc.).

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
Aligned with the **Multiplicity Ecosystem Substrate**. Ported from `@mtpi/l2-adapters` to integrate directly with the `arithmetic-kernel` and `prover` components.
