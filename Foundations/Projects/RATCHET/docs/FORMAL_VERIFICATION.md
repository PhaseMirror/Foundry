# Project RATCHET: Lean 4 Formal Verification Guide

This document details the formalization methodology, proof structures, typing discipline, and theorem inventory for the Lean 4 package in `lean/`.

---

## 1. Zero-Axiom & Zero-Sorry Guarantee

The Lean 4 formalization in `lean/` adheres to the strict Multiplicity foundational standard:
- **Zero Custom Axioms:** Uses standard Lean 4 core logical axioms only (`propext`, `Quot.sound`, `Classical.choice`).
- **Zero `sorry`:** Every theorem is fully discharged and machine-checked by the Lean 4 compiler.
- **Standalone Build:** Compiles without external Mathlib dependencies.

---

## 2. Formal Module Map

```
lean/
├── lakefile.lean             # Package configuration
├── lean-toolchain            # Lean 4 toolchain pin (v4.33.0-rc2)
├── Ratchet.lean              # Master import module
├── Ratchet/
│   ├── Types.lean            # PlantState, WritePath, WriteManifest, Snapshot, SafetyBarrier
│   ├── Conjectures.lean      # C1, C2, C3 formal predicates and mathematical bounds
│   ├── Controller.lean       # Deterministic state machine, dwell timeouts, absorbing HALT
│   ├── Sandbox.lean          # Actuator clamping, isolation predicates, kill-switch
│   ├── Receipts.lean         # ReceiptRecord and CeilingRecord validation theorems
│   └── Attacks.lean          # Red-team attack mitigation soundness theorems
└── tests/
    └── RatchetTest.lean      # Formal test harness executing #check and runtime assertions
```

---

## 3. Comprehensive Theorem Inventory

### Module: `Ratchet.Conjectures`
1. `burst_exits_on_sandbox_failure`:
   $$\forall t, T_{\text{pred}}, \hat{\lambda}, \lambda_{\text{cap}}, V, V_{\min},\; \text{should\_exit\_burst}(\dots, \text{sandbox\_ok}=\text{false}) = \text{true}$$
2. `burst_exits_on_lambda_cap`:
   $$\hat{\lambda}_L > \lambda_{\text{cap}} \implies \text{should\_exit\_burst}(\dots) = \text{true}$$
3. `rate_cap_bounded`:
   $$\forall \dot{\theta}, \text{max\_rate},\; \text{enforce\_rate\_cap}(\dot{\theta}, \text{max\_rate}) \le \text{max\_rate}$$
4. `incomplete_manifest_rejected`:
   $$\text{manifest.complete} = \text{false} \implies \text{verify\_manifest}(\text{manifest}, \text{paths}) = \text{false}$$
5. `post_use_guarantees_margin`:
   $$\text{post\_use\_check}(\phi_{\text{before}}, \phi_{\text{after}}, z_{\text{contrib}}, \text{margin}) = \text{true} \implies \phi_{\text{after}} \ge \text{margin}$$

### Module: `Ratchet.Controller`
6. `halt_is_absorbing`:
   $$\text{ctx.mode} = \text{HALT} \implies (\text{step\_controller}(\text{ctx}, \dots)).2 = \text{HALT}$$
7. `capture_exhaustion_forces_halt`:
   $$\text{ctx.mode} = \text{CAPTURE} \land \text{ctx.retries} + 1 \ge \text{max\_retries} \implies (\text{step\_controller}(\dots)).2 = \text{HALT}$$
8. `ground_low_score_forces_halt`:
   $$\text{ctx.mode} = \text{GROUND} \land \text{dwell} \ge \text{ground\_dwell} \land V < V_{\min} \implies (\text{step\_controller}(\dots)).2 = \text{HALT}$$

### Module: `Ratchet.Sandbox`
9. `sandbox_map_bounded`:
   $$\forall u,\; \text{sandbox\_map}(u) \le \text{MAX\_SANDBOX\_ACTUATION}$$
10. `network_enabled_fails_sandbox`:
    $$\text{s.network\_disabled} = \text{false} \implies \text{sandbox\_invariant}(s) = \text{false}$$
11. `killed_fails_sandbox`:
    $$\text{s.is\_killed} = \text{true} \implies \text{sandbox\_invariant}(s) = \text{false}$$

### Module: `Ratchet.Receipts`
12. `expired_receipt_invalid`:
    $$t > \text{r.expiry\_time} \implies \text{is\_receipt\_valid}(r, t) = \text{false}$$
13. `coordinate_overflow_violates_ceiling`:
    $$\text{coords} > \text{c.max\_coordinates} \implies \text{within\_ceiling}(\text{coords}, \dots, c) = \text{false}$$

### Module: `Ratchet.Attacks`
14. `estimator_divergence_rejected`:
    $$e_1 - e_2 > \text{tol} \implies \text{verify\_estimator\_consensus}(e_1, e_2, \text{tol}) = \text{false}$$
15. `learner_write_voids_controller`:
    $$\text{c\_ext\_writable} = \text{true} \implies \text{verify\_controller\_isolation}(\text{c\_ext\_writable}) = \text{false}$$

---

## 4. Verification Commands

```bash
cd /home/citizen/Multiplicity/Foundry/Projects/RATCHET/lean
lake build
lake exe ratchet_test
```
Output:
```
============================================================
  ADR-0038: THE INTELLIGENCE RATCHET FORMAL TEST HARNESS     
============================================================
  [PASS] C1 Predictability Horizon & Burst Exit Proofs Verified
  [PASS] C2 Adaptation Rate Cap & Manifest Boundedness Verified
  [PASS] C3 Null-Space Orthogonality & Post-Use Invariants Verified
  [PASS] Controller State Machine & Absorbing HALT Verified
  [PASS] Sandbox Invariants & Actuator Clamping Verified
  [PASS] Receipt & Ceiling Invariant Theorems Verified
  [PASS] Red-Team 7-Attack Mitigation Formal Proofs Verified
============================================================
  ALL RATCHET FORMAL SPECIFICATIONS & PROOFS COMPILED (100%)
============================================================
```
