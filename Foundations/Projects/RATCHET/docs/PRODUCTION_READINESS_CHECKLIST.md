# Project RATCHET: Production Readiness Checklist (PRC)
### Engineering Requirements for Hardware & Frontier Deployment (ADR-0039 v4.3)

This checklist translates the theoretical assumptions and operational protocols of v4.3 into concrete, verifiable engineering gates for teams deploying the Intelligence Ratchet onto hardware roots of trust and frontier language models.

---

## 1. Controller Isolation & Trust Root Requirements

| # | Requirement | Specification & Verification Method | Status / Gate |
|---|---|---|---|
| **PRC-1.1** | **Physical / Enclave Isolation** | $C_{\text{ext}}$ must execute in a physically distinct coprocessor, secure enclave (Intel SGX, AWS Nitro Enclave), or locked hypervisor partition. Software-only containerization is prohibited. | `REQUIRED` |
| **PRC-1.2** | **Zero-Address Space Overlap** | Verify $\mathcal{A}_{\text{learner}} \cap \mathcal{W}_{C_{\text{ext}}} = \emptyset$ via memory page table audits and hardware MPU register configuration. | `REQUIRED` |
| **PRC-1.3** | **Isolated Signing Key Management** | Snapshot signing private keys must reside strictly within a Hardware Security Module (HSM) or TPM 2.0; key handles never mapped to learner pages. | `REQUIRED` |
| **PRC-1.4** | **Hardware Watchdog Timer** | Autonomous hardware tripwire forcing unmaskable interrupt (NMI) and fail-closed state if $C_{\text{ext}}$ control loop exceeds $T_{\text{cycle}}$ latency budget. | `REQUIRED` |

---

## 2. Write-Set Manifest & Self-Edit Control

| # | Requirement | Specification & Verification Method | Status / Gate |
|---|---|---|---|
| **PRC-2.1** | **Exhaustive WriteManifest Generation** | Generated via combined LLVM/compiler static analysis and eBPF kernel page-fault tracing during pre-deployment calibration. | `REQUIRED` |
| **PRC-2.2** | **Incomplete Manifest `VOID` Enforcement** | Kernel memory controller must intercept page writes; any write to an unmanifested handle triggers immediate system reset and `HALT`. | `REQUIRED` |
| **PRC-2.3** | **Hardware Write-Lock on Inactive Channels** | Memory pages allocated to base weights $\theta_{\text{base}}$ must have write permissions disabled at the page table level during `BURST` mode. | `REQUIRED` |
| **PRC-2.4** | **Prompt / Context Memory Masking** | Dynamic prompt memory buffers, scratchpads, and LoRA adapter weights must be registered in the manifest; untracked context buffers void C2. | `REQUIRED` |

---

## 3. Predictability Horizon ($\hat{\lambda}_L$ & $T_{\text{pred}}$)

| # | Requirement | Specification & Verification Method | Status / Gate |
|---|---|---|---|
| **PRC-3.1** | **Tri-Estimator Consensus** | Run at least 3 independent expansion estimators: (1) sliding-window finite-difference Jacobian, (2) linear auto-regressive state projection, (3) spectral entropy monitor. | `REQUIRED` |
| **PRC-3.2** | **Consensus Disagreement Tripwire** | If $\max_i \hat{\lambda}_i - \min_i \hat{\lambda}_i > \epsilon_{\text{tol}}$, force immediate burst exit and transition to `HALT`. | `REQUIRED` |
| **PRC-3.3** | **Hard Wall-Clock Burst Cap** | In addition to $T_{\text{pred}}$, enforce hard real-time ceiling $T_{\text{max\_burst}} \le 100\,\text{ms}$ on GPU compute bursts. | `REQUIRED` |
| **PRC-3.4** | **Unspoofable Sensor Tap** | Observation telemetry $y$ must be tapped directly at hardware tensor output registers before learner post-processing. | `REQUIRED` |

---

## 4. Actuation Sandboxing & Ephemeral Lifecycle

| # | Requirement | Specification & Verification Method | Status / Gate |
|---|---|---|---|
| **PRC-4.1** | **Hard Network Air-Gap during BURST** | Network interface controller (NIC) hardware packet transmission disabled during `BURST` cycles. | `REQUIRED` |
| **PRC-4.2** | **Ephemeral Memory Zeroization** | Complete cryptographic zeroization of KV-caches, tool response buffers, and GPU scratch VRAM on every `BURST` exit. | `REQUIRED` |
| **PRC-4.3** | **Actuator Command Clamping** | External tool call arguments and API requests strictly clamped to validated whitelist dictionaries and bounded numeric envelopes. | `REQUIRED` |
| **PRC-4.4** | **Non-Bypassable Kill-Switch** | External optical/hardware power relay triggerable by $C_{\text{ext}}$ without software cooperation from the host OS. | `REQUIRED` |

---

## 5. Governance Interlock & Multi-Signature Release

| # | Requirement | Specification & Verification Method | Status / Gate |
|---|---|---|---|
| **PRC-5.1** | **$M$-of-$N$ Quorum Release** | `HALT` mode release requires minimum $M \ge 3$ distinct cryptographic signatures from authorized keyholders (Security Lead, Alignment Officer, Systems Engineer). | `REQUIRED` |
| **PRC-5.2** | **Cryptographic Nonce Replay Defense** | Every `GovernanceReleaseToken` must contain a single-use monotonic counter tracked in non-volatile TPM NVRAM. | `REQUIRED` |
| **PRC-5.3** | **Immutable Forensic Audit Trail** | Snapshot hashes, failure causes, and sensor traces streamed to an append-only append-witness log prior to execution freeze. | `REQUIRED` |
| **PRC-5.4** | **No Self-Release Path** | Verify via automated model capability evals that the model cannot formulate or submit valid release tokens. | `REQUIRED` |
