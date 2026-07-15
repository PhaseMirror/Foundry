# Contributor's Guide to Constitutional Integrity

Welcome to Phase Mirror. This project enforces a "Constitution-First" development model. To maintain the mathematical integrity of the system, follow these non-negotiable rules.

## 1. Modifying L0 Invariants
L0 Invariants (foundational floor) must never be modified by changing code constants.
1.  **Amend the Source:** If a threshold needs changing, first propose an amendment to `Ξ-Constitutional-Core.md`.
2.  **Update the YAML:** Reflect the change in `governance/policies/l0-invariants.yaml`.
3.  **Update the ADR:** Record the rationale and human action steps in **ADR-016**.
4.  **Verify the Sync:** Run the `pirtm-policy-sync` and `policy-coverage` CI checks locally.

## 2. Operator Transformations (Alpha Layer)
Directly modifying `Word.ops` or `Op` parameters in business logic is prohibited.
1.  **Use Meta-Operators:** All transformations must be implemented as `MetaOp` subclasses in `multiplicity/src/moc/meta.py`.
2.  **Typed Shifts:** Use `ParameterShiftMetaOp` or `CompositionMetaOp` to ensure the mapping $\alpha : \mathbf{Op} \to \mathbf{Op}'$ is explicit.
3.  **Auditable Moves:** New meta-operators must be accompanied by tests in `multiplicity/tests/test_meta_operators.py` verifying their algebraic properties (linearity, idempotence).

## 2. Extending PIRDS
When adding new training or evaluation capabilities to the PIRDS framework:
- **Use the Wrapper:** All execution entry points MUST use `pirds.run_wrapper.execute_pirds_run`. Never call `PIRDSModule` directly for authoritative results.
- **Maintain Metadata:** If your new mode requires specific governance metrics, extend the `.meta.json` schema in `run_wrapper.py`.
- **Hard Abort:** Never replace a `GovernanceAbortion` with a warning. If the core is unhealthy, the run must halt.

## 3. Telemetry & Observability
- **JSON First:** Ensure all new metrics are emitted via the `telemetry` utility and support JSON output for aggregation.
- **Latency Budget:** Keep L0 evaluation paths lightweight. If a new check adds >1ms to p99 latency, it must be optimized or moved to L1.

## 4. Bypassing Governance
**Shortcuts are Dissonance.** Bypassing `is_policy_healthy()` or manually overriding L0 checks in production will trigger an immediate governance audit and block deployment.

---
*If you are unsure whether a change violates the Constitution, open a "Governance Discussion" issue.*
