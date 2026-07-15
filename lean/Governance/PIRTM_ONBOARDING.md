# PIRTM Governance Pipeline: Developer Onboarding Manual

This manual provides guidance for developers on diagnosing and remediating failures within the PIRTM governance pipeline. The pipeline operates under the principle of **Governance-as-Compilation**; build failures are not mere obstructions, but necessary safety interventions to preserve system stability.

## 1. Governance Gates Overview

| Gate | Stage | Failure Type | Governance Invariant |
| :--- | :--- | :--- | :--- |
| **A** | Parsing | Structural | Prime Successor Predicate |
| **B** | Type Check | Logic/Tensor | Multiplicity Conservation |
| **C** | Link-time | Spectral/Stability | ACE Invariants ($r(\Lambda) < 1-\varepsilon$) |

---

## 2. Error Remediation Workflow

### Gate A: StructuralViolationError (Parsing)
*   **Symptom**: `StructuralViolationError: PrimeIndexContinuityError`
*   **Cause**: The sequence of prime-indexed operators violates the Successor Predicate ($\sigma: p_n ightarrow p_{n+1}$).
*   **Remediation**:
    1.  Inspect the offending operator sequence in your source file.
    2.  Verify the prime indices against the required successor sequence defined for the module's Stratum.
    3.  Adjust the sequence to maintain index continuity.

### Gate B: TypeSafetyError (Multiplicity/Tensor)
*   **Symptom**: `TypeSafetyError: MultiplicityMismatch`
*   **Cause**: The application of an operator violates multiplicity conservation: $M(S_{new}) 
eq M(Ap) \cdot M(S_{old})$.
*   **Remediation**:
    1.  Inspect the tensor signature transformation.
    2.  Check the prime-exponent mapping of the input tensor, the operator, and the expected output.
    3.  Ensure the tensor contraction preserves the overall multiplicity of the prime sector.

### Gate C: LinkTimeVeto (ACE/Spectral)
*   **Symptom**: `LinkTimeVeto: StabilityConstraintViolated` or `SpectralRadiusViolation`
*   **Cause**: The module is either non-contractive ($\sum F_i + \varepsilon \geq 1$) or violates the spectral small-gain condition ($r(\Lambda) \geq 1 - \varepsilon$).
*   **Remediation**:
    1.  **Analyze Norms**: Examine the `op_norm_T` and `epsilon` attributes extracted from the `pirtm.module`.
    2.  **Verify Governance Constant**: Ensure the epsilon value provides sufficient margin for the module's operator norms.
    3.  **Refine Constraints**: Reduce the norm of internal operators or increase the governance margin ($\varepsilon$) if the logic permits.
    4.  **Proof Generation**: If the stability check passes but formal proof generation fails, verify that the Lean 4 proof template is correctly configured for your specific signature type.
    5.  **Systemic Engine Audit**: If stability or spectral violations occur across multiple independent modules, perform a mandatory audit of the `models/legalese-scopist/` engine core. The Rust Engine is the sole source of truth; do not attempt to bypass engine-computed stability bounds.

---

## 3. Gate Failure Ethics: The `[PRESERVATION ALERT]` Protocol
If a compilation failure (specifically in Gate B or C) involves modules managing ESI, Spoliation Risk, or Litigation Hold data, you **MUST** trigger the `[PRESERVATION ALERT]` protocol as defined in `models/legalese-scopist/CONTRACT.md`. Do not bypass the engine's risk assessment to resolve a build failure.

---

## 4. Compliance and Parity
*   **No Floats**: All governance constants must utilize `SCALE_BASE = 1,000,000`. Never use floating-point types for stability attributes.
*   **Archivum Bound**: All modules MUST have an associated `UnifiedWitness` event in the Archivum Ledger. If a module fails to link due to "Identity Dissonance," ensure the `prime_index` matches the ledger commitment.

For further assistance, consult the Sedona Spine ADRs (ADR-004, ADR-088) or the `Lean 4` formalization documentation in `crates/pirtm-compiler/templates/`.
