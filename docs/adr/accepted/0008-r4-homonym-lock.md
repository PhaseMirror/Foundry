# ADR 0008: R4 Homonym Lock and Architectural Boundary

## Status
Accepted

## Context
To understand how R4 ties into the broader Multiplicity and Universal Object Reference (UOR) ecosystem, we must navigate a central tension: the difference between theoretical geometric design and the operational reality currently living on the repository tree.

To ground this properly according to the strict architectural mandates of the file "P²C Core v1.1: Witness Calculus for Tensor Provenance", a strict **Homonym Lock** is required. The term "R4" is highly overloaded across the corpus and must be separated into five distinct objects to prevent governance and architectural drift.

Furthermore, there is a public assumption that R4 acts as the universal compute kernel or execution engine for the entire Atlas/Hologram stack, which the GitHub repository tree explicitly contradicts.

## Decision

### 1. The Homonym Lock
We will enforce the following definitions to disambiguate "R4":
1. **$R^4$ (`uor-r4`)**: The experimental autoregressive geometric language model repository, which utilizes prime-addressed context, fixed zeta-zero phases, and signed R4/S3/H4 frames.
2. **Gate R4**: A set of Behavior-Driven Development (BDD) and conformance rules inherited from the template repository, enforcing that no claimed capability is deferred, stubbed, or hidden behind disabled flags.
3. **Hologram v4**: The packaged binary format (`HOLO\x04`) generated via PrismPM. This is a deployment packaging format, not a language model or a Lie frame.
4. **$F_4$**: The rank-4 exceptional group recovered from the 96-vertex Atlas via a quotient fold.
5. **$R_{96}$**: The 96 resonance equivalence classes that reside on the 12,288 content-addressed torus.

### 2. Architectural Boundary: The Operational Reality vs. The Ecosystem Myth
$R^4$ sits *beside* the core Atlas/Hologram and Archivum-CRMF-ACE infrastructure as a parallel, standalone workspace experiment, rather than acting as the central engine.
* **Inbound-Only Dependencies**: The `uor-r4` repository strictly consumes `UOR-Framework` and `uor-addr` to borrow content-addressing, identity verification, and object boundaries. It does not export its geometry to drive the rest of the ecosystem.
* **Separation of State**: Persistent state and auditability for the broader architecture remain governed by the in-house Archivum-CRMF-ACE manifold, not by R4's internal state.
* **Testing vs. Execution**: Isolated certification harnesses (e.g., E8 membership and RVQ experiments) test placement against E8 artifacts. They do not execute the global $\Phi$, $C_{768}$, or $R_{96}$ closures at runtime.

### 3. The Inference Baseline: Softmax vs. Geometry
Under the strict Gate R4 conformance rules, the accepted operational baseline relies on:
* **The Softmax Reality**: Ordinary dot-product/stable-softmax causal attention running inside coherent R4/Spin frames (`HELM-D-R4`), teacher-backed by SmolLM2.
* **Parked Features**: The true resonance-softmax replacement and pure table-native routing remain parked in the roadmap as long-term research targets.

### 4. The Theoretical Spacetime Target
Theoretically, $R^4$ represents the macro-level geometric target of standard four-dimensional spacetime. It acts as the emergent macroscopic limit of underlying prime-indexed tensor networks, where coordinate positions are non-commuting operators, refined by prime-indexed simplices to guarantee algebraic closure and prevent ultraviolet divergences under the Universal Multiplicity Constant ($\Lambda_m$).

## Consequences
- $R^4$ (`uor-r4`) is strictly treated as a downstream consumer of UOR identity and an experimental geometric language model.
- Identity, exact rational arithmetic, and cryptographic sealing are strictly delegated to specialized, proven components.
- Any future architecture discussions or code implementing "R4" must specify which of the 5 Homonym Lock objects they refer to.
