# ADR 104: PIRTM Compiler Governance and Production Gating

## Status
Accepted

## Context
The PIRTM compiler must bridge compile-time mathematical validation with deployment-time governance gating, ensuring that no non-contractive or uncertified module is linked, executed, or deployed. To prevent **Governance Drift** and maintain the **Sedona Spine** "Zero Drift" mandate, the compiler must act as the deterministic, fail-closed gate of the system. We need a unified architectural specification that maps compile-time validation, stateless editor feedback (LSP), and CI/CD/Ledger verification into a single, non-bypassable path of integrity.

## Decision
We implement a production-grade compiler governance and gating pipeline structured into five core components:

1. **Context-Agnostic Parsing (Tree-sitter)**
   - Keep the Tree-sitter grammar context-agnostic. Parse operator words structurally without evaluating prime validation or tower constraints at the parser level.
   - Delegate all value-level, prime-successor, and mathematical constraints to the validator.

2. **Unified Semantic Validator (`AdmissibilityValidator`)**
   - The validator maps AST structures to exact mathematical and topological invariants, collecting all issues in a single pass.
   - It enforces the following canonical diagnostic codes as **hard failures**:
     - `SUCCESSOR_PREDICATE_VIOLATION`: Triggered if the prime-index towers violate successor rules.
     - `MULTIPLICITY_VIOLATION`: Triggered if tensor identity multiplicity conservation fails.
     - `STRATUM_CROSS_BOUNDARY_VIOLATION`: Triggered if prime indices cross hierarchical stratum boundaries.
     - `CIRCUIT_BUDGET_EXCEEDED`: Triggered if the circuit exceeds the assigned computational capacity limits.
     - `CONTRACTIVITY_INVARIANT_BREACH`: Triggered if spectral stability or contractivity constraints are violated ($\varepsilon \cdot \|T\|_{\text{op}} \ge 1$).

3. **WASM Gating Boundary (`validate_source`)**
   - Expose the compiler validation logic via a Rust-WASM bridge using `wasm-bindgen`.
   - The bridge returns a versioned `DiagnosticEnvelope` JSON object, ensuring a stable, forward-compatible contract between Rust and TS platforms.

4. **Stateless LSP Adapter (`lsp_handler.ts`)**
   - The LSP diagnostic provider operates as a stateless pass-through. It validates source code on change/save, maps the `DiagnosticEnvelope` directly to editor warnings/errors, and performs no independent reinterpretation.

5. **CI Gating and Archivum Ledger Anchoring**
   - The CI pipeline executes the validator as a non-bypassable gate. Builds fail-closed if `diagnostics.len() > 0` or if Lean 4 proof materialization fails.
   - Successful builds automatically generate a `ContractivityReceipt` and `UnifiedWitness` record, anchoring the build provenance in the Archivum Ledger.

## Consequences

- **Pros**:
  - **Single Source of Truth**: All IDE diagnostics, CI tests, and ledger proofs share the same compiler validation engine.
  - **Zero Drift**: Eliminates runtime variations by performing exact, fixed-point verification in the Rust kernel and passing results via WASM.
  - **Fail-Closed Protection**: Prevents uncertified states from proceeding to execution or linking.

- **Cons**:
  - **Build Latency**: Multi-pass checks (parsing -> validation -> proof verification) increase compile and check time.
  - **Toolchain Dependency**: Requires active Rust, WebAssembly, and Lean 4 toolchains to satisfy verification pipelines.

## Sedona Spine Provenance
- **Policy**: [PIRTM Compiler Roadmap.md](file:///home/multiplicity/crates/pirtm-compiler/docs/PIRTM%20Compiler%20Roadmap.md)
- **Event Log**: [Latest ADR Roadmap.md](file:///home/multiplicity/crates/pirtm-compiler/docs/Latest%20ADR%20Roadmap.md)
- **Kernel Computation**: [validator.rs](file:///home/multiplicity/crates/pirtm-compiler/src/validator.rs)
- **Narrative**: [CONTRACT.md](file:///home/multiplicity/models/legalese-scopist/CONTRACT.md)
