# Phase Mirror Sovereign Operational Contract (CONTRACT.md)

**Status:** Ratified & Locked  
**Date:** 2026-08-22  
**Governing Authority:** Sedona Spine Steward + Legal / Formal Methods Steward  
**Statutory Membrane:** Wyoming DUNA / Autonomous DAO Membrane (Zero Residual Human Discretion)  

---

## 1. Constitutional & Code-Identity Mandate (Layer Separation)

The architecture establishes a strict separation across four orthogonal layers (A / B / C / D). Compliance with this taxonomy is mandatory for all agentic workflows, quantum circuits, and governance filings.

### 1.1 Non-Identity of Groth16 / Layer-A Arithmetic
- **Explicit Prohibition:** Zero-knowledge SNARK proofs (Groth16 / Plonk) prove only that an arithmetic circuit trace satisfies a relation ($C(x, w) = 1$). **Groth16 proofs MUST NEVER be claimed, submitted, or construed as proof of code identity, compiler provenance, or supply-chain integrity.**
- Layer A verifies arithmetic execution correctness only.

### 1.2 Explicit Layer-B Requirement (Prerequisite Gate)
- **Mandatory Identification:** Prior to the execution of any Layer-C quantum circuit, MA-VQE pulse schedule, or Wyoming statutory filing, a content-addressed **Layer-B identity** must exist and be cryptographically verified:
  1. An immutable Git release tag (`refs/tags/v*`).
  2. A Content-Addressed Identifier (`CID` / Git Tree SHA-256) binding source files, dependencies, and build toolchains.
  3. A Dilithium Post-Quantum / Ed25519 signature anchoring the CID to the `AttestationRegistry`.
- **Blocking Invariant:** The absence of a verified Layer-B tag and CID blocks all Layer-C governance execution and statutory filings.

### 1.3 Wyoming Membrane & Zero Residual Human Authority
- Under the Wyoming DUNA statutory framework, no discretionary human authority may override engine-generated truth.
- All state transitions require machine-checked mathematical witnesses (`PhaseMirror.ADR`, `sedona_spine`, `AttestationRegistry`).

### 1.4 Layer-D zkVM Sequencing
- General recursive zkVM rollups (Layer D) are **strictly forbidden** from operational deployment until Layers B and C are active, attested, and locked.

---

## 2. Hardware Concurrency & Operational Envelopes

The operational execution envelope is strictly bound to the following parameters:

| Parameter | Symbol | Value | Enforcement Mechanism |
| :--- | :--- | :--- | :--- |
| **Max Concurrency** | $N$ | $\le 100$ sessions | FPGA Orchestrator session table |
| **Max Qudits (Active-Space Cap)** | $q$ | $\le 69$ qudits | Allocation cap (CAS(114,114) compression envelope; NOT ground-state proof) |
| **Energy Error Bound (Cap, not measurement)** | $\epsilon$ | $< 15.0$ mHa (target $\le 14.5$) | Policy filter / complexity cap (NOT a measured physical energy without named Hamiltonian and $E_{\mathrm{ref}}$) |
| **State Entropy Cap** | $S$ | $\le 5.9$ (hard ceiling $6.0$) | ThermalWindow / HSEC admission gate |
| **Native $d=16$ Ratio** | — | $\ge 80\%$ of active sessions | QCFI multiplexor telemetry |
| **Aggregate Utilization** | — | $< 90\%$ | Prometheus core observer |
| **NarrativeAuditor Drift** | — | $0.0$ (strictly zero) | HSEC consensus checksum |
| **Audit & Retention** | — | 7 years (2555 days) | CRMF + ACE Telemetry |

### 2.1 Concurrency & Molecular Lock Clause (Policy Envelopes)
- **Policy Envelopes (Not Empirical Measurements):** Concurrency is strictly bounded at $N = 100$ concurrent sessions, qudit allocations are capped at $q = 69$ (CAS(114,114) compression envelope), energy error threshold is a policy cap at $\epsilon < 15.0$ mHa, and state entropy is bounded at $S \le 5.9$ ($H(\rho) \le 6.0$). In accordance with ADR-010 (Claim/Evidence Split), these values constitute admission filters and complexity bounds, NOT verified physical measurements of ground-state chemical accuracy.
- **No Molecular Scaling:** Any attempt to simulate molecular active spaces exceeding 69 qudits is rejected at the admission gate to prevent catastrophic thermodynamic/entropy collapse.
- **No Empirical Ground-State Claims:** Empirical tuning or capacity testing cannot assert chemical accuracy or physical ground-state convergence while a named published Hamiltonian $H_{\mathrm{named}}$, reference energy $E_{\mathrm{ref}}$, and Layer-B identity remain missing.

---

## 3. Sedona Spine Source of Truth Hierarchy

```mermaid
flowchart LR
    Engine[Engine (Rust: sedona_spine)] --> SDK[SDK (TS/WASM)] --> Contract[Contract (CONTRACT.md)] --> UI[UI / Agent / DAO]
    classDef engine fill:#1E3A8A,color:#fff,stroke:#2563EB,stroke-width:2px;
    classDef sdk fill:#10B981,color:#fff,stroke:#059669,stroke-width:2px;
    classDef contract fill:#F59E0B,color:#fff,stroke:#D97706,stroke-width:2px;
    classDef ui fill:#6B21A8,color:#fff,stroke:#7C3AED,stroke-width:2px;
    class Engine engine;
    class SDK sdk;
    class Contract contract;
    class UI ui;
```

1. **Zero Drift:** Agents MUST NOT independently compute or override risk levels (`Critical`, `High`, `Medium`).
2. **Fail-Closed Escalation:** In the event of a detected preservation breach or parameter drift, the system triggers immediate fail-closed state locks.
