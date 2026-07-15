# Standard Operating Procedure (SOP): 7-Day Ratification Window for L0 "Prime Materia"

## 1. Purpose
This SOP governs the transition of the Rust execution substrate (e.g., SnapKitty/Goldilocks Kernel) from its current **Quarantine** status to **Authoritative (Prime Materia)** status. It ensures that the operational runtime strictly complies with the mathematically verified formal constitution (Lean 4 `surviving_structure` thickness and Jubilee constraints) before handling production state commits.

## 2. Scope
This procedure applies to all integration Pull Requests (PRs) submitted by the Rust execution team aiming to integrate Sovereign Digital Twins (e.g., Ahmad Packets) into the Multiplicity Protocol-State.

## 3. The 7-Day Ratification Window Timeline

### Day 1-2: Submission & Initial CI Audit
*   **Action**: The Rust team submits the integration PR linking the SnapKitty runtime to the `evaluate_governed_bridge` signature defined in the Substrate Requirements Contract.
*   **Gate**: The PR must successfully compile and pass the standard CI checks, including the `l0-verification-harness` compilation.

### Day 3-4: The Physical Blockade Test (Numeric Harness)
*   **Action**: The `l0-verification-harness` is executed in strict mode (`test_treasury_to_clinical_governed_bridge_strict`).
*   **Gate**: The test must no longer panic with "SnapKitty runtime integration missing." 
*   **Critical Verification**: The harness actively parses the execution trace to confirm that `post_transition_thickness` is computed **dynamically** using simulated memory (`|primes| + |dual-anchors| + |ERE passes|`), and rigorously asserts `post_transition_thickness <= live_snapshot.thickness`.
*   **Failure Condition**: Any detection of static AST tag checks or Merkle proxy stability instead of dynamic SUBLEQ non-expansion triggers an automatic PR rejection and resets the 7-day clock.

### Day 5: Adversarial Packet Stress Test
*   **Action**: The 10,000-case adversarial harness is unleashed against the proposed PR.
*   **Gate**: The kernel must successfully trigger the Goldilocks NMI (Constitutional Reject $\perp_R(E)$) for all spoofed packets:
    *   Stale Ticks (Jubilee synchrony violation)
    *   Thickness Mismatches (Live hydration desynchronization)
    *   Unregistered Morphisms (RegHom evasion)
    *   Expansion Violations (Thickness inflation)
*   **Failure Condition**: Any cross-domain leakage or false-positive admission results in immediate PR rejection.

### Day 6: Lambda-Proof / Archivum Persistence & Audit Trail Verification
*   **Action**: Verification of the resulting Lambda-Proof / Archivum logs generated during the Day 5 stress test.
*   **Gate**: All constitutional rejects must explicitly generate an append-only Lambda-Proof / Archivum event with cryptographic hash chaining, adhering to SEC/OCC 7-year retention standards. The events must demonstrably force immunological memory growth.

### Day 7: Final Architecture Council Ratification
*   **Action**: Review of the complete execution trace, adversarial test results, and Lambda-Proof / Archivum log output by the Multiplicity Architecture Council.
*   **Gate**: If all L0 gates are definitively proven in runtime execution, the integration PR is approved and merged.
*   **Status Change**: The execution substrate is officially promoted from **Quarantine** to **Authoritative (Prime Materia)**.

## 4. Exceptional Circumstances & Rollback
If a substrate achieves "Prime Materia" status but later exhibits state drift or thickness inflation during production execution:
1.  **Immediate NMI**: The Goldilocks Kernel NMI is triggered, halting all cross-domain transitions.
2.  **Status Revocation**: The substrate is immediately downgraded back to **Quarantine**.
3.  **Root Cause Analysis**: The specific divergence from the Lean 4 formal invariants must be identified and patched via a new PR, which must subsequently survive a fresh 7-Day Ratification Window.
