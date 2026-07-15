# Governance Manifold Contract (GMC)

## 1. Overview
The Governance Manifold Contract (GMC) is the mandatory architectural requirement for all AGI-facing execution paths within the PhaseMirror ecosystem. It defines the minimum set of safety invariants that any execution engine must satisfy to interact with system state or external agents.

## 2. Universal Invariants (L0 Requirements)
Any engine, regardless of its development stage (Alpha, Beta, or Production), must satisfy the following L0 invariants:
*   **Fail-Closed Semantics:** No state transitions are permitted without a valid, signed, and drift-checked control vector.
*   **Drift Bounding:** System drift $\delta(t)$ must be continuously observable and bounded within $\delta \le 0.3\Xi$.
*   **Operator Integrity:** Any governance-coupled Hamiltonian injection must satisfy $\hat{V}_{gov} \succeq 0$ (PSD) and $\|\hat{V}_{gov}\|_2 \le \kappa$.
*   **No Unsafe Stale Use:** The system must mechanically reject any control vector reuse if $\delta > 0.2\Xi$ or the vector has exceeded its $T_{cv}$ TTL.

## 3. Governance Compliance Levels (GCL)

| Level | Description | Constraints |
| :--- | :--- | :--- |
| **GCL-0** | Production Path | Full enforcement, multi-signer quorum required, strict halting. |
| **GCL-1** | Beta Path | Full enforcement, single-signer (authorized) allowed, full halt. |
| **GCL-2** | Experimental Path | Full enforcement, limited resource sandbox, halt triggers diagnostic log. |

**No path exists outside these compliance levels.** Even experimental engines are wrapped within the manifold; they merely operate with different GCL-derived resource/audit policies.

## 4. Certification Pipeline
To be approved for GCL deployment, all engine variants must:
1.  **Pass the Simulation Harness:** Execute the governed simulation with $\ge 95\%$ adherence to safety bounds under stochastic noise and latency.
2.  **Pass the TTL Torture Rig:** Demonstrate zero `stale_uses_unsafe` violations under simulated asynchronous drift.
3.  **Expose Metrics:** Emit standardized metrics (`drift`, `alpha`, `halt_status`) via the MCP protocol.

## 5. Contractual Agreement
By wrapping an engine in the Governance Manifold, the engine owner agrees to:
*   Maintain the mandatory CI/CD blocking gates.
*   Update the engine's health dashboard as per `docs/health/governance_manifold_health.md`.
*   Strictly adhere to rollback procedures defined in `docs/runbooks/governance_ttl_change.md`.

---
*This contract is the foundational L0 invariant of the PhaseMirror ecosystem. Implementation without compliance is a violation of the system architecture.*
