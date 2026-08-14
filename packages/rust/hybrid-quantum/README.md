# Hybrid Quantum-Classical Environment (Rust)

A high-performance, unified Rust execution environment for orchestrating contractive tensor dynamics, quantum circuit simulations, and classical numerical solvers. This project is a native Rust port of the `hybrid_quantum_env` Python environment, built for superior speed, memory safety, and formal verification alignment with the Ξ-Constitution.

## 🚀 Key Features

- **PIRTM Core Integration**: Native implementation of the PIRTM recurrence engine ($X_{t+1} = (1 - \lambda_m)X_t + \lambda_m P(\dots)$).
- **Spectral Analysis**: High-performance eigenvalue decompositions and spectral radius approximations powered by `faer` and `nalgebra`.
- **Quantum Simulation**: Optimized stabilizer simulator for large-scale circuit testing (GHZ, W-states) up to 5000+ qubits.
- **Formal Verification**: Designed to maintain Polynomial Sovereignty and bypass the exponential state-vector bottleneck.
- **Production-Grade Architecture**: Fully async core using `tokio`, structured logging with `tracing`, and professional CLI via `clap`.

## 🛠️ Components

- **`engine`**: The PIRTM recurrence machine core logic.
- **`quantum`**: Stabilizer-based quantum circuit simulator.
- **`numerical`**: High-performance linear algebra and spectral solvers.
- **`governance`**: Mechanized enforcement of Ξ-Constitutional invariants (L1-L2).

---

## ⚙️ User Setup Guide

Follow these steps to set up the environment on your machine.

### 1. Prerequisites

Before building `hybrid-quantum-rs`, ensure you have the following installed:

- **Rust Toolchain**: Install via [rustup](https://rustup.rs/). Rust **1.80+** is required.
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```
- **C/C++ Build Tools**: Required for high-performance math optimizations (SIMD).
  - **Linux**: `sudo apt install build-essential`
  - **macOS**: `xcode-select --install`
  - **Windows**: Install Visual Studio Build Tools with C++ workload.

### 2. Installation & Building

1. Navigate to the project directory:
   ```bash
   cd hybrid-quantum-rs
   ```

2. Build the production-optimized binary:
   ```bash
   cargo build --release
   ```

The compiled binary will be located at `./target/release/hybrid-quantum-rs`.

### 3. Verification

Run the built-in validation suite to ensure your environment is correctly configured (parity with ADR-087):

```bash
./target/release/hybrid-quantum-rs validate
```

---

## 📖 Usage Guide

The environment provides several subcommands for different hybrid tasks.

### Running the PIRTM Engine
Execute a recurrence step for a specific dimensionality. This simulates a single step of the contractive tensor dynamics:

```bash
./target/release/hybrid-quantum-rs engine --dim 4
```

### Large-Scale Quantum Simulation
Test the scaling of the stabilizer simulator. This example runs a 1000-qubit GHZ state simulation:

```bash
./target/release/hybrid-quantum-rs quantum --qubits 1000
```
*Note: The stabilizer simulator maintains polynomial complexity, allowing it to scale far beyond traditional state-vector simulators.*

### Environment Diagnostics
View detailed validation metrics and readiness for Phase 2:

```bash
./target/release/hybrid-quantum-rs validate
```

---

## 📊 Performance Comparison

| Feature | Python (`hybrid_quantum_env`) | Rust (`hybrid-quantum-rs`) |
| :--- | :--- | :--- |
| Startup Time | ~200ms (interpreter overhead) | < 1ms (native) |
| Tensor Contraction | Good (NumPy/MKL) | Exceptional (Faer/SIMD) |
| Multi-threading | Gated by GIL | Parallel (Tokio/Rayon) |
| State Vector Scaling | Exponential Bottleneck | Polynomial Sovereignty |
| Safety | Dynamic Types | Strict Compile-time Verification |

## 🛡️ Governance & Invariants

This environment strictly enforces the following invariants as defined in the **Ξ-Constitution**:
- **I1-I4 Stability**: Spectral radius must remain bounded within specific operational regimes.
- **Homological Persistence**: Verified via periodic Euler characteristic audits.
- **Polynomial Sovereignty**: Guaranteed by the underlying Constraint Nerve representation.

## 📄 License

MIT License. See `LICENSE` for details.
