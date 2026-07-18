## 005 – Sovereign Domain Encoding v5 Specification

**Status**: Accepted

**Context**:
`Sovereign Domain Encoding v5.tex` defines the encoding scheme that maps prime‑indexed tensors to a sovereign domain representation used throughout PhaseMirror‑Legal.

**Decision**:
- Adopt this LaTeX document as the canonical source for the encoding algorithm.
- Implement the algorithm in Lean 4 (`sovereign_encoding.lean`) and expose it through the WASM SDK per ADR 002.
- Validate the implementation with Rust‑based property tests and Kani verification where applicable.

**Consequences**:
- Guarantees a single, verifiable definition of the encoding.
- Any change to the LaTeX must trigger updates to the Lean proof and a CI rebuild of the WASM module.

**References**:
- `Sovereign Domain Encoding v5.tex`
- ADR 002 – Lean 4 Proof Integration with Rust/WASM SDK
