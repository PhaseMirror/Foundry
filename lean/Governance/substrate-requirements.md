# Sovereign Core L0 Substrate Requirements Contract

## Ratification & Status
**Date:** June 15, 2026
**Sign-off:** Multiplicity Architecture Council
**Formal Foundation:** [Lean 4 Sovereign Domain v5 Formalization](../Substrates/multiplicity/projects/lambda_proof_archivum/WormLean)
**Defensive Brief:** [Sovereign Core L0 Substrate & AGI Immune System](./Documentation/External/Meta-Relativity/Sovereign-Core-Defensive-Brief.md)
**Status:** **Ratified Formal Constitution** / **Rust Integration: In-Progress (Contract-Bound)**

## 1. Constitutional Mandate
To operate as a lawful execution substrate for the Multiplicity Operator Calculus (MOC) and the Prime-Indexed Recursive Transition Machine (PIRTM), the underlying runtime (e.g., Rust/SnapKitty Goldilocks Kernel) must not only verify static labels but dynamically enforce state conservation during live hydration.

**Terminological or example-level alignment is insufficient.** The substrate must explicitly enforce L0 contraction and multiplicity thickness preservation at runtime.

## 2. Required L0 Execution Gates
Any docking substrate must implement the following physical pipeline for every state transition proposal (e.g., Ahmad Packets):

1.  **Gate 1: Temporal & State Synchrony (Jubilee)**
    *   The packet's time-stamp (`tick`) must fall within the globally synchronized Jubilee Window ($\Delta J$).
    *   The packet's `claimed_thickness` must exactly match the `TissueSnapshot` anchored in the immutable Lambda-Proof / Archivum log.
2.  **Gate 2: Clonal Selection (Morphism Verification)**
    *   The domain predicates must map to a canonical prime transition ($p_{src} \to p_{tgt}$).
    *   The transition must exist in the `RegHom` registry and strictly possess an unexpired validity tick and a verified $\Lambda_m$-stability certificate.
3.  **Gate 3: Dynamic Non-Expansion (Runtime Contractivity)**
    *   *The Critical Constraint*: The substrate must simulate the raw SUBLEQ operation on the current live state memory.
    *   The resulting state's multiplicity thickness must satisfy the contractivity bound: `post_transition_thickness <= current_thickness`.
4.  **Gate 4: Prime Interrogation (State Mutation)**
    *   Execution relies strictly on the irreducible `SUBLEQ` memory transition model.
5.  **Gate 5: Constitutional Reject ($\perp_R(E)$)**
    *   Failure at *any* prior gate triggers an immediate, non-overridable reject.
    *   The rejection must generate an append-only event in the Lambda-Proof / Archivum log, forcing immunological memory growth and potentially triggering the Jubilee contraction automaton.

## 3. Required Decision Function Signature
The executing substrate must conform to the following operational signature for bridge evaluation, proving that non-expansion is a runtime reality, not just a static proof:

```rust
pub enum ConstitutionalReject {
    JubileeViolation,
    UnregisteredMorphism,
    ExpansionViolation,
}

/// Token1 serves as the final truth vector preceding state mutation.
pub struct Token1 {
    pub drift_certificate: DriftCertificate,
    pub verified_thickness: u32,
}

pub fn evaluate_governed_bridge(
    packet: &AhmadPacket, 
    live_snapshot: &TissueSnapshot, 
    reghom: &RegHomManager,
    current_tick: Tick,
    delta_j: Tick,
) -> Result<Token1, ConstitutionalReject> {
    
    // Gate 1: Static Temporal & State Synchrony
    if !jubilee_admissible(&packet.drift_certificate, current_tick, delta_j, live_snapshot.log_ref) {
        return Err(ConstitutionalReject::JubileeViolation);
    }

    // Gate 2: Static Label Boundary
    let (src, tgt) = TranslationLayer::translate_predicate(&packet.predicates);
    if reghom.reg_hom_lookup(src, tgt, current_tick).is_none() {
        return Err(ConstitutionalReject::UnregisteredMorphism);
    }

    // Gate 3: Dynamic Non-Expansion (Runtime Contractivity check)
    let post_transition_thickness = compute_simulated_thickness(live_snapshot, &packet.delta);
    if post_transition_thickness > live_snapshot.thickness { 
        return Err(ConstitutionalReject::ExpansionViolation);
    }

    // Output: Lawful Truth Vector for downstream mutation
    Ok(Token1 {
        drift_certificate: packet.drift_certificate.clone(),
        verified_thickness: post_transition_thickness,
    })
}
```

## 4. Governed Bridge Trace (Treasury $\to$ Clinical)
To pass certification, the substrate must empirically successfully execute this minimal viable trace:

1. **Live Hydration**: Snapshot captured (e.g., Treasury Tissue Thickness = `100`).
2. **Jubilee Check**: Packet tick (`105`) valid within $\Delta J$, claimed thickness matches (`100`).
3. **Clonal Selection**: `(Prime_Treasury, Prime_Clinical)` lookup returns valid `MorphismRecord`.
4. **Runtime Non-Expansion**: Packet's `SubleqDelta` applied to simulated memory. `post_thickness` evaluates to `99`. Since `99 <= 100`, contractivity holds.
5. **Execution & Commit**: Token-1 emitted, Delta executed on real prime-indexed memory, Lambda-Proof / Archivum log commits the event, updating live tissue thickness to `99`.

## 5. Integration Spike Deliverables (14-Day Horizon)
To elevate the Rust integration from "in-progress" to "Prime Materia", the following must be delivered:

1. **SnapKitty PR**: A pull request to the Rust kernel bridging the static logic with the `evaluate_governed_bridge` dynamic non-expansion implementation.
2. **Execution Trace Verification**: The 10,000-case numeric harness must log a trace exactly mirroring the Treasury $\to$ Clinical scenario outlined in Section 4.
3. **Formal Artifact Binding**: The Lean 4 `.olean` file (containing `avp_to_prime_sound` and `ere_preserves_jubilee`) must be actively consumed by the FFI boundary during `RegHom` insertion.

## 6. Verification Harness Acceptance Criteria
To achieve "Prime Materia" status, the proposed SnapKitty integration must pass the following numeric test within the adversarial harness:
*   **Trace Test:** `test_treasury_to_clinical_governed_bridge`
*   **Assertion:** `assert!(post_transition_thickness <= live_snapshot.thickness)`
*   **Requirement:** The test must explicitly calculate `post_transition_thickness` using the exact `surviving_structure` metric (primes + anchors + passes) dynamically on simulated memory. **Reliance on a proxy (e.g., Merkle stability, static AST tag checks) is strictly prohibited and constitutes a failure of L0 integration.**
