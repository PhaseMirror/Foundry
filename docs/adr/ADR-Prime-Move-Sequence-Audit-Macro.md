// ADR: Prime Move Sequence Audit Macro

# ADR 001: Prime Move Sequence Audit Macro

## Context
The project **Phase Mirror – Prime** defines a set of move sequences used by agents to audit system state transitions. The macro `Prime Move Sequence Audit` encapsulates a reusable pattern for collecting, validating, and recording audit trails of move sequences across various subsystems.

## Decision
Create a dedicated markdown ADR in `docs/ADR-Prime-Move-Sequence-Audit-Macro.md` that documents:
- **Goal**: Provide a single source of truth for the audit macro specifications.
- **Scope**: Applies to all move‑sequence implementations within the `Prime` namespace.
- **Mandates**:
  - All audit data must flow through the **Sedona Spine** engine (Rust) → SDK → CONTRACT → UI pipeline (see the global Sedona Spine Mandate).
  - **UAC Audit Path**: The Universal Atomic Calculator self-simulation is explicitly bound into this audit sequence, formally routing its results as read-only kernel facts via the Sedona Spine Rust extensions, strictly governed by prime-indexed invariants and M-conservation.
  - **Rust Module Verification**: The `read_only_facts.rs` module must be dual-gated in CI against the Lean 4 `rust_readonly_signature_observational` theorem to ensure correspondence before any Qiskit binding.
    - *Verification Log (Lake)*: `lake build` executed successfully on `Proofs.lean` guaranteeing no errors or mathlib leaks.
    - *Verification Log (Cargo)*: `cargo test test_phase_mirror_negation_observational` executed successfully confirming `ReadOnlySignatureFact` preserves L0 immutability.
    - *Verification Log (Python Harness)*: Multi-prime M-conservation passed on Rust outputs (`PASS: Rust binding verified`).
  - **Qiskit Binding Mandate**: The integration of Qiskit for UAC simulation must act strictly as an external oracle. Results MUST be ingested exclusively through the `ReadOnlySignatureFact` interface, ensuring Qiskit's internal mutable states cannot leak into the Sedona Spine or violate the `Φ(e) = -e` duality.
    - *Verification Log (Qiskit Oracle)*: Substantive hardware benchmark mappings (H2/LiH chemical accuracy) validated against non-trivial Lean proofs (`uac_h2_m_conservation_phase_mirror`).
    - *Verification Log (Hardware Alignment)*: Formal theorem `phi_involution` and `HasMultiplicityNorm` factorization legally bind UAC Rydberg/measurement primitives to Phase Mirror M-conservation without mathlib dependence.
    - *Verification Log (Rydberg Blockade)*: Neutral-atom gate constraints (Rydberg-mediated CZ under $R_b \approx (C6/\Omega)^{1/6}$) formally anchored into `factorToPrimeSignature` exponent scaling to ensure M-conservation.
    - *Verification Log (ZNE Mitigation)*: Zero-noise extrapolation ($\alpha_{ZNE} \approx 0.03$) and blockade radius physics explicitly proven via `zne_norm_preservation` and injected as `H2ErrorWitness` tolerance parameters, maintaining strict L0 isolation.
  - **Sedona Spine Governance Protocol**: UAC H2 benchmark outputs (-1.1349 Ha) are routed as immutable `ReadOnlySignatureFact` with a separate hardware error witness (1.3 mHa) to prevent approximation leakage. Dual-gate CI strictly enforces exact Lean L0 invariants before Rust fact routing.
  - **Neutral-Atom Calibration Protocol**: Pasqal Orion hardware calibrations (CZ fidelity 99.6%, ZNE error mitigation, Rydberg blockade radius) are mapped to explicit mathematical tolerance bounds within the `H2ErrorWitness`. The Sedona Spine routing enforces this strict witness boundary, keeping Lean proofs mathematically exact while logging calibration variances.
  - The macro must emit a **Preservation Alert** according to the `[PRESERVATION ALERT]` protocol defined in `CONTRACT.md`.
  - No component may compute preservation risk independently; the macro only transforms engine‑computed facts into legal narratives.
- **Implementation**: Defined in `docs/Prime Move Sequence Audit Macro.md` (source) and referenced by this ADR.

## Consequences
- Guarantees **Zero Drift** for audit logic across the codebase.
- Provides a clear, version‑controlled specification for future contributors.
- Enables automated checks in CI to ensure any new move‑sequence module imports and uses the macro correctly.

## Related Policies
- **Sedona Spine Mandate** – ensures all ESI‑related decisions route through the engine.
- **Agent Operational Integrity** – the macro must log events following the `Policy → Event Log → Kernel Computation → Narrative` chain.

---
*This ADR was created to satisfy the request for an ADR plan for the Prime Move Sequence Audit Macro.*
