# ADR-MC-001: The MultiplicityCell Manifest

## Status
Proposed

## Context
The Λ-RMAM-ZΞ 7.3 architecture requires a standardized, configuration-sealed deployment unit: the **MultiplicityCell**. This cell must encapsulate its own mathematical law, execution parameters, and governance constraints to ensure autonomous and verifiable operation.

## Decision
We will define a `MultiplicityCellManifest` as the canonical entry point for every cell boot. This manifest is a cryptographically signed JSON/YAML document.

### Manifest Schema
1. **Cell Identity**: UUID and public key for πnative digest binding.
2. **Kernel Profile**:
    - `pirtm_version`: Target PIRTM dialect version (7.3).
    - `prime_set`: The $P_N$ set used for recursive updates.
    - `stability_constants`: $\Lambda_m$ and $\alpha$ parameters.
3. **Governance Profile**:
    - `constitution_anchor`: Reference to the governing constitution (e.g., Ξ-Constitution).
    - `veto_predicates`: List of formal conditions under which the cell must refuse activation.
4. **Capability Class**:
    - `class`: One of `Oracle`, `Witness`, `Bridge`, `Governor`, or `Substrate`.
5. **Security Seal**:
    - `seal_hash`: Hash of the entire configuration, pinned to the ledger.

## Consequences
- **Configuration Sealing**: Any modification to the manifest invalidates the cell's "Ready" state.
- **Auditability**: The manifest provides the "Expected State" against which ZK-traces are verified.
- **Portability**: MultiplicityCells can be migrated across nodes while maintaining their integrity.
