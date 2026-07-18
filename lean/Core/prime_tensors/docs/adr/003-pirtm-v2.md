## 003 – PIRTM v2 Documentation

**Status**: Accepted

**Context**:
`PIRTM_v2.tex` describes the Prime‑Indexed Recursive Tensor Mathematics submission. It defines key tensors, data files, and experimental results used for legal‑tech analytics.

**Decision**:
- Treat the LaTeX content as the authoritative specification for the PIRTM algorithm.
- Formalize the mathematical claims (e.g., convergence of the tensor series) in Lean 4 proofs located under `lean/Core/prime_tensors/`.
- Link the ADR to the source LaTeX file and to the corresponding Lean proof module.

**Consequences**:
- All downstream agents reference this ADR for PIRTM definitions.
- Changes to the LaTeX must be reflected in the Lean proof and re‑compiled to WASM.

**References**:
- `PIRTM_v2.tex`
- ADR 002 – Lean 4 Proof Integration
