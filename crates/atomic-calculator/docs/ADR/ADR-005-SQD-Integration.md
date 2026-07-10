# ADR-005: SQD (Signature of Quantum Data) Integration

## Status
Proposed

## Context
The Universal Atomic Calculator (UAC) currently executes MA-VQE compiler output on the Infleqtion $d=16$ FPGA orchestrator, relying on the `NarrativeAuditor` for governance. However, we lack a formal, noise-robust cryptographic signature for the produced quantum states ($\rho$) and their corresponding classical measurement bitstrings. Standard cryptographic hashes (like SHA-256) are chaotic and not robust to quantum noise, meaning two identical quantum preparations with slight thermal noise will yield completely different hashes. 

To solve this, we will integrate the **Signature of Quantum Data (SQD) V1.0** specification, consisting of:
- **C-SQD**: A microstate/multiplicity/checksum signature for classical measurement bitstrings.
- **Q-SQD**: A quantized Pauli-feature signature with instability flags for noise-robust fingerprinting of the physical quantum state.

## Decision
We will enforce SQD signatures as mandatory provenance fields across the UAC pipeline:

1. **FpgaOrchestrator (Primary Q-SQD Binding)**: After microwave pulse execution, the FPGA will perform post-pulse Pauli feature measurements ($\text{Tr}(\rho O_k)$) to compute the quantized Q-SQD fingerprint of the hardware state.
2. **C-SQD Binding**: The final measurement bitstrings will be canonicalized and hashed via C-SQD (incorporating Hamming multiplicity) before being returned to the classical orchestrator.
3. **NarrativeAuditor (Governance Gate)**: The auditor will be extended to parse the SQD JSON. It will strictly reject any output containing `unstable` Q-SQD flags or missing signatures, enforcing Sedona Spine ALP policies.
4. **Lean4 Foundations**: Constants for quantization ($B$), guard-bands ($\lambda$), and max-weight will be formally extracted from `SQD.lean`.

## Consequences
- **Positive**: Provides immutable, noise-robust cryptographic provenance for every FeMoco simulation, ensuring complete auditability for QaaS clients. Eliminates classical/quantum conflation.
- **Negative**: Adds measurement overhead to the FPGA edge node to compute Pauli features for Q-SQD, slightly reducing total QaaS throughput.

## Next Steps
1. Formalize SQD structures and constants in `lean/SNAPKITTY/SnapKitty/SQD.lean`.
2. Implement `sqd.rs` matching the V1.0 reference schemas.
3. Wire Q-SQD and C-SQD generation into `fpga_pulse.rs`.
4. Update `qaas_endpoints.rs` and `agent_contracts.rs` (`NarrativeAuditor`) to mandate SQD validation.
