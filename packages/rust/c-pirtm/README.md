# c-pirtm: C-Interop Tensor Dynamics

`c-pirtm` provides high-performance, contractive tensor operations designed for C-interop and low-level FFI integration. It is a critical component of the Sedona Spine, ensuring that high-speed execution environments adhere to fundamental safety and contractive tensor invariants.

## Architecture & Integration
`c-pirtm` is refactored to depend on `pirtm-core` for fundamental safety primitives.

- **Fundamental Invariants**: Relies on `pirtm-core::math::ContractiveOperator` and related traits to ensure that all operators maintain contractivity (Lipschitz constant < 1).
- **Core Operations**: Implements high-performance spectral linear layers (`SpectralLinear`), resonance gates for cross-modal tensor mixing, and contractive mixers.
- **FFI Boundary**: Designed for compatibility with C-based runtimes, ensuring that safety-critical invariants are maintained when crossing the FFI boundary.

## Key Components
- `math/`: Implements specialized operators and gates, leveraging `pirtm-core` primitives.
- `core/`: Defines high-level structures like `CROFLC` (Contractive Resonant Operator Field with Lawful Channels) and audit tracing (`OmegaTrace`).

## Development & Testing
To ensure the integrity of the FFI boundary and operator safety:
- **Unit Tests**: Verify contractive properties (e.g., `GroupSort2` 1-Lipschitz property).
- **Integration Tests**: Validate end-to-end `CROFLC` forward passes.

Run tests:
```bash
cargo test --manifest-path Cargo.toml
```
