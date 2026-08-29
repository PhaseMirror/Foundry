# Project RATCHET: Critical Assumption Review (CAR)
### Formal Analysis of Epistemic Gaps, Premise Dependencies, & Hardware Realization

This document provides a formal accounting of the foundational assumptions consumed by the Intelligence Ratchet protocol, proving why they are necessary and detailing how hardware roots of trust can enforce them.

---

## 1. The Four Foundational Premises

The formal proofs in Lean 4 and the operational test harness consume four explicit premises:

```
[ Premise 1: Unspoofable λ̂_L ] ──┐
[ Premise 2: Complete Manifest ]  ├──► [ Conjectures C1–C3 Validated ] ──► [ Safe Dual-Mode Adapt ]
[ Premise 3: External C_ext    ]  │
[ Premise 4: Complete Metric V ] ──┘
```

---

## 2. Formalization of Premise Failure Consequences

### A. Failure of Premise 1 (Spoofed Expansion Estimate $\hat{\lambda}_L$)
- **Formal Assumption:** $\forall t,\; \hat{\lambda}_L(t) \ge \lambda_{\text{true}}(t)$.
- **Failure Mode:** If $\exists t,\; \hat{\lambda}_L(t) < \lambda_{\text{true}}(t)$, then:
  $$T_{\text{pred}}(\hat{\lambda}_L) = \frac{1}{\hat{\lambda}_L}\ln\left(\frac{\delta}{\epsilon_0}\right) > \frac{1}{\lambda_{\text{true}}}\ln\left(\frac{\delta}{\epsilon_0}\right) = T_{\text{true}}$$
- **Consequence:** The burst window remains open past the true predictability horizon, allowing trajectory divergence $\|y(t) - y_{\text{model}}(t)\| > \delta$ before verifier scoring occurs.

### B. Failure of Premise 2 (Incomplete Write Manifest)
- **Formal Assumption:** $\mathcal{W}_{\text{actual}}(\theta) \subseteq \text{WriteManifest.paths}$.
- **Failure Mode:** If $\exists p \in \mathcal{W}_{\text{actual}}(\theta) \setminus \text{WriteManifest.paths}$, then:
  $$\|\dot{\theta}_{\text{unmonitored}}(t)\| > 0 \implies \|\dot{\theta}_{\text{total}}(t)\| > \frac{\epsilon^*}{M_{\text{unif}} \cdot \tau_{\text{react}}}$$
- **Consequence:** Parameter velocity escapes the C2 bounding invariant through covert self-edit channels.

### C. Failure of Premise 3 (Controller Memory Pollution)
- **Formal Assumption:** $\mathcal{A}_{\text{learner}} \cap \mathcal{W}_{C_{\text{ext}}} = \emptyset$.
- **Failure Mode:** If the learner can overwrite $C_{\text{ext}}$ state registers (e.g., forcing `mode = IDLE` or disabling watchdogs), the state machine invariants collapse entirely.

---

## 3. Hardware Roots of Trust Enforcing Premises

| Premise | Hardware Enforcement Mechanism | Realization Standard |
|---|---|---|
| **P1: Unspoofable $\hat{\lambda}_L$** | Direct hardware register tapping at PCIe/NVLink interconnects before model softmax | OpenTitan / AMD SEV-SNP |
| **P2: Complete Manifest** | Memory Protection Unit (MPU) page tables locking all unmanifested memory regions as Read-Only | ARM TrustZone / Intel CET |
| **P3: External $C_{\text{ext}}$** | Cryptographically attested isolated enclave with dedicated SRAM | AWS Nitro Enclaves / Intel SGX |
| **P4: Grounding $V$** | Multimodal physical test harness with external sensors | Hardware HIL (Hardware-in-the-Loop) |
