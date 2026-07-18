## 002 – Lean 4 Proof Integration with Rust/WASM SDK

**Status**: Accepted

**Context**:
The project uses Lean 4 for formal proofs of mathematical properties (e.g., convergence of \(\Lambda_m\)). To make these proofs usable by the Rust engine, they must be compiled to WASM and exposed via the TypeScript SDK.

**Decision**:
- Write Lean 4 proof files under `lean/Core/prime_tensors/`.
- Use `lake build` to compile to WASM (`.wasm` module).
- Provide a thin TS wrapper in `models/legalese-scopist/` that loads the WASM module and offers functions such as `proveConvergence(params): Promise<ProofResult>`.
- Rust engine calls the TS SDK (via wasm-bindgen) to retrieve proof outcomes.

**Consequences**:
- Proofs become part of the runtime verification pipeline.
- Agents can query proof results but cannot modify them.
- Requires CI step to rebuild WASM on each proof change.

**References**:
- Lean 4 documentation
- `models/legalese-scopist/CONTRACT.md`
- Rust ↔ WASM interop guidelines
