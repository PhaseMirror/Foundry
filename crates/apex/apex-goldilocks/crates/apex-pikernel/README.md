# π-kernel-rs: Rust Kernel-Multiplicity Runtime Bridge

A high-performance Rust port of the π-kernel, featuring ACE safety, contraction certificates, and PETC ledger for the Hologram-APEX Multiplicity Runtime.

## Overview

The π-kernel is a **strong monoidal functor** F:(A,⊗)→(C,⊕) from the atom category to the prime-channel category. This Rust implementation provides:

1. **Atom Registration**: Orthogonal projector families and π-atoms via efficient intersection.
2. **ACE Safety**: Weighted ℓ₁-ball projection via bisection (KKT-optimized).
3. **Contraction Certificates**: Real-time SlopeUB and GapLB verification.
4. **PETC Ledger**: Cryptographic commitments using SHA-256 and Poseidon (BN254).
5. **MUB Drift Audit**: Walsh-Hadamard based energy concentration detection.

## Module Structure

- `projectors`: `ProjectorFamily`, `PiIndexGrid`, and atom construction.
- `l1proj`: Weighted ℓ₁-ball projection.
- `certificates`: Contraction verification (Theorem 3.1).
- `ledger`: Append-only ledger with SHA-256 and Poseidon support.
- `kernel`: Core `PiKernel` update loop.
- `mub_audit`: MUB drift detection via Fast Walsh-Hadamard Transform.
- `poseidon`: Educational Poseidon hash implementation.
- `routing`: Semantic channel routing and aggregation.
- `hologram_adapter`: Managed bridge for Hologram vGPU ↔ Multiplicity Runtime.

## Quick Start

### Basic Usage

```rust
use pikernel_rs::{ProjectorFamily, PiIndexGrid, PiKernel, DefaultLedger};
use ndarray::{Array1, Array2};
use std::collections::HashMap;

// 1. Define projector families
let a = ProjectorFamily::new(vec![vec![0, 2, 4, 6], vec![1, 3, 5, 7]], "A")?;
let b = ProjectorFamily::new(vec![vec![0, 1, 2, 3], vec![4, 5, 6, 7]], "B")?;

// 2. Build grid
let grid = PiIndexGrid::new(vec![a, b])?;

// 3. Configure and Run
// (See examples/basic_usage.rs for full setup)
```

### Running Examples

```bash
# Baseline example
cargo run --example basic_usage

# Managed Hologram bridge with Poseidon and MUB audit
cargo run --example hologram_bridge
```

## Mathematical Guarantees

### Contraction Certificate
Verified via iteration matrix $A = \text{diag}(1-\alpha) + \text{diag}(\alpha)|K|$.
- **SlopeUB** $= \|A\|_\infty \le 0.9$
- **GapLB** $= 1 - \text{SlopeUB} > 0$

### ACE Safety
Projection onto $S_t = \{x : \sum w_i|x_i| \le \tau\}$ ensures bounded energy and stability.

## Performance
Built on `ndarray` and optimized for low-latency kernel updates in high-dimensional state spaces.

## License
Released under MIT OR Apache-2.0.
