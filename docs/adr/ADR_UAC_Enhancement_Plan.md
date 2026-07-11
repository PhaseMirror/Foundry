# ADR: UAC Enhancement Plan

Based on the comprehensive technical documents provided, here is a strategic enhancement plan that deepens and extends the operational layers of the Universal Atomic Calculator (UAC) architecture while preserving its core mathematical rigor and governance invariants.

---

## Executive Summary

The current UAC stack successfully delivers end-to-end provenance from Lean4 formal proofs through 100-concurrent FeMoco simulations to on-chain EVM finality. The following enhancement strategy focuses on **operational scale, governance automation, cryptographic agility, and physics expansion** without violating the locked production envelope.

---

## 1. Operational Layer Enhancements

### 1.1 Predictive Thermal Load Management

**Current State**: Reactive load-shedding via QuantumM::Collapse when aggregate FPGA utilization exceeds 90%.

**Enhancement**: Implement a predictive thermal scheduler using online learning.

- **Approach**: Train a lightweight LSTM or Gaussian Process model on historical Prometheus telemetry (utilization, error_rate, session count) to predict thermal spikes 30–60 seconds in advance.
- **Action**: Preemptively shift low-priority sessions to `d = 8` before breach, avoiding abrupt QuantumM::Collapse and preserving throughput.
- **Mathematical Guarantee**: Stay within `util < 0.90` with 99.5% confidence using conformal prediction.
- **Lean Integration**: Formalize the predictor's safety bounds in Lean4 as an extension to ThermalWindow.

### 1.2 SQD Signature Caching & Differential Verification

**Current State**: Each FeMoco run computes Q-SQD post-pulse independently, with unstable signatures rejected by NarrativeAuditor.

**Enhancement**: Introduce a caching layer for repeated or similar circuit signatures.

- **Approach**: Use a locality-sensitive hash (LSH) over quantized Q-SQD feature vectors. If a run yields a signature with Hamming distance ≤ ε from a previously attested stable signature, skip full verification.
- **Benefit**: Reduces ZK proof generation load and latency for near-identical runs.
- **Risk Mitigation**: Differential verification still enforced by NarrativeAuditor; cache hits require auditor approval and WORM logging of "fast-path" attestation.

### 1.3 Dynamic Lambda Guard-Band Calibration

**Current State**: Fixed `λ = 2.0` guard-band for Q-SQD instability detection.

**Enhancement**: Calibrate `λ` per qubit/dimension based on historical Infleqtion noise profiles.

- **Approach**: Maintain per-qudit shot noise histograms from runs. Adjust `λ` dynamically per session to maintain false-positive rate < 1% while keeping false-negative rate = 0%.
- **Lean Formalization**: Prove that dynamic `λ` remains within Sedona Spine bounds via a new theorem `lambda_adjustment_safe` in Circuits.lean.

---

## 2. Governance & Compliance Deepening

### 2.1 Automated ALP Policy Gate with Smart Contract Enforcement

**Current State**: ALP policy gate is a human-in-the-loop review for Critical Escalations.

**Enhancement**: Encode core ALP invariants (e.g., `H(ρ) ≤ 6.0`, `unstable = []`) directly as Solidity preconditions in AttestationRegistry.sol.

- **Approach**: Extend `submitAttestation` to validate a lightweight proof of entropy bound (e.g., via a zk-SNARK over `H(ρ)`).
- **Benefit**: On-chain enforcement eliminates human delay for routine runs; human review only for edge cases.
- **Lean Link**: Formalize the Solidity precondition logic in Contracts.lean and prove equivalence to Lean invariants.

### 2.2 Immutable SQD Provenance as Legal Evidence

**Current State**: WORM storage of SQD signatures and audit logs for 7 years.

**Enhancement**: Add cryptographic timestamping to the WORM archive via integration with a public blockchain (e.g., Ethereum or Arweave) as a secondary anchor.

- **Approach**: Periodically batch SQD hash digests and submit as a single Merkle root to a timestamping contract.
- **Benefit**: Provides court-admissible proof of data existence at a specific time, strengthening defensive publication claims.

---

## 3. Cryptographic & ZK Layer Extensions

### 3.1 Recursive ZK Proofs for Batch Attestation

**Current State**: One Groth16 proof per FeMoco run submitted to AttestationRegistry.

**Enhancement**: Aggregate multiple attestations into a single recursive proof (e.g., using Halo2 or Plonky2).

- **Benefit**: Reduces gas costs and on-chain load by 10–100×, enabling higher throughput without raising client fees.
- **Architecture**: Sidecar accumulates proofs over a time window (e.g., 5 minutes) and submits a single batch proof.
- **Lean Formalization**: Extend attestation.circom to support batch verification; prove that batch proof implies individual attestation validity.

### 3.2 Post-Quantum Secure Signatures

**Current State**: ECDSA keys used for provider signature in AttestationRegistry.

**Enhancement**: Add an optional post-quantum signature scheme (e.g., SPHINCS+ or Falcon) alongside ECDSA.

- **Approach**: Sidecar signs attestation with both classical and post-quantum keys; AttestationRegistry verifies both if client opts in.
- **Reasoning**: Future-proofs the system against quantum attacks on ECDSA, without breaking existing clients.

---

## 4. Physics & Simulation Layer Expansion

### 4.1 Multi-Target Molecular Simulation with Auto-Reduction

**Current State**: Locked to FeMoco CAS(114,114) to avoid 100-qudit boundary.

**Enhancement**: Introduce a capability to automatically reduce larger target molecules to FeMoco-compatible subspaces using active-space selection via CAS(20,20) proxy.

- **Approach**: For a target molecule, run a classical pre-screening to identify a CAS(20,20) subspace that dominates the chemistry; validate via Q-SQD similarity to full-space results.
- **Benefit**: Enables a limited set of new molecules without busting the 100-qudit hard boundary.
- **Governance**: Any new target requires an ADR and a Lean proof that the reduced subspace preserves HSEC entropy and chemical accuracy.

### 4.2 Noise-Aware Circuit Compilation

**Current State**: Fixed `d = 16` / `d = 8` dimension shifting based on thermal feedback.

**Enhancement**: Compile MA-VQE circuits adaptively to minimize noise impact, using the Q-SQD `unstable` flags as a training signal.

- **Approach**: Use reinforcement learning or Bayesian optimization to choose circuit layouts (e.g., qubit mapping, gate scheduling) that minimize Q-SQD instability for a given thermal state.
- **Lean Formalization**: Prove that any optimized layout stays within `d16_frac ≥ 0.80` using a new theorem in SQD.lean.

---

## 5. Client & API Layer Upgrades

### 5.1 Self-Service Client Dashboard with SQD Verification

**Current State**: Clients receive JSON SimulationResponse with SQD signatures.

**Enhancement**: Provide a web dashboard where clients can verify Q-SQD signatures against the AttestationRegistry on-chain record.

- **Approach**: Dashboard fetches the AttestationRegistry event log, computes the Q-SQD digest from client-provided data, and compares.
- **Benefit**: Gives clients cryptographic proof of run validity without requiring local infrastructure.

### 5.2 SLA Monitoring & Automated Refunds

**Current State**: SLA guarantees `< 15.0 mHa` and `> 95%` convergence.

**Enhancement**: Build an automated monitoring system that checks convergence accuracy and, if SLA is breached, triggers a smart contract-based refund.

- **Approach**: If a run's `energy` exceeds the SLA bound, the sidecar submits a "failed attestation" proof to a RefundContract, which automatically issues client credits.
- **Lean Formalization**: Prove that the refund logic cannot be gamed (e.g., client cannot falsely claim failure) using state machine invariants in Contracts.lean.

---

## 6. Observability & Incident Response

### 6.1 AI-Powered Anomaly Detection on Governance Logs

**Current State**: OTel/Elasticsearch logs are human-analyzed.

**Enhancement**: Deploy an unsupervised anomaly detection model (e.g., Isolation Forest) over log streams to flag unusual patterns (e.g., sudden spike in `unstable` rate, unexpected drift in `H(ρ)`).

- **Benefit**: Proactive identification of hardware degradation or malicious attempts before they trigger Critical Escalate.

### 6.2 Automated Incident Response Playbooks

**Current State**: Critical Escalate triggers human review.

**Enhancement**: Codify response playbooks as executable smart contracts or scripts.

- **Example**: If `util > 0.95` persists for 2 minutes, auto-scale to a secondary FPGA pool (if available) or trigger graceful shutdown of low-priority sessions.
- **Governance**: Playbooks must be approved via ALP policy and proven safe in Lean.

---

## 7. Formalization & Proof Expansion

### 7.1 Full EVM-Groth16 Integration Proof

**Current State**: Circuits.lean and Contracts.lean are zero-sorry for DriftBound and nullifier usage.

**Enhancement**: Formalize the entire Groth16 verification flow from R1CS to EVM opcode semantics.

- **Approach**: Model the bn128 curve pairing in Lean and prove that the Solidity `IGroth16Verifier` correctly implements the verification algorithm.
- **Benefit**: Closes the final gap in the "Lean → R1CS → EVM" chain.

### 7.2 Continuous Formal Verification CI Pipeline

**Current State**: Lean proofs are manually verified via `lake build`.

**Enhancement**: Integrate Lean verification into the CI/CD pipeline (GitHub Actions) with automatic regression testing on every commit to `circuits/` or `contracts/`.

- **Benefit**: Prevents accidental introduction of sorries or invariant violations during development.

---

## Summary of Enhancement Priorities

| **Layer**                | **Enhancement**                                  | **Impact**               | **Complexity** |
|--------------------------|--------------------------------------------------|--------------------------|----------------|
| Operational              | Predictive thermal scheduler                     | High (throughput)        | Medium         |
| Governance               | Automated ALP on-chain enforcement               | High (speed + security)  | High           |
| Cryptographic            | Batch ZK proofs                                  | High (gas cost)          | High           |
| Physics                  | Multi-target auto-reduction                      | Medium (scope)           | High           |
| Client                   | SQD verification dashboard                       | Medium (trust)           | Low            |
| Observability            | Anomaly detection on logs                        | Medium (proactive ops)   | Medium         |
| Formalization            | Full EVM-Groth16 proof                           | High (mathematical closure) | Very High   |

---

## Conclusion

The Universal Atomic Calculator is already a groundbreaking system. The proposed enhancements deepen its operational resilience, extend its cryptographic and governance layers, and open a controlled path toward physics expansion—all while preserving the locked Sedona Spine invariants. Each enhancement is designed to be incrementally introducible, with formal verification in Lean4 as the non-negotiable gate.

**Recommendation**: Prioritize **predictive thermal scheduling** and **batch ZK proofs** as immediate next steps, followed by **automated ALP enforcement** and **full EVM-Groth16 formalization**. This sequence maximizes impact while managing implementation risk.
