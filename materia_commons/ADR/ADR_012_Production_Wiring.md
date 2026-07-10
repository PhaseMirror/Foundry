# ADR 012: Production-Grade Wiring of the Universal Atomic Calculator Stack

**Date:** July 2026
**Status:** Proposed / Active
**Domain:** `Prime/materia_commons/ADR/`

## 1. Context & Motivation

Following the massive repository consolidation and the introduction of `UORMatMul.lean`, the Foundry stack now possesses a perfect architectural hierarchy:

1. **`Prime/lean/`**: Formal invariants and topological constraints (MOC, Arta, UOR MatMul).
2. **`Prime/crates/`**: Operational Rust engines executing within those invariants (`engine`, `core`, `pirtm-candle`).
3. **`Prime/circuits/`**: Zero-Knowledge proving architecture (`air-mr64`, `prover`).
4. **`Prime/contracts/`**: Ethereum/Sepolia settlement layer (`AnchorContract`, `JubileeBridge`).
5. **`Prime/materia_commons/`**: Declarative governance and schemas.

To reach production grade, we must rigorously wire these layers together such that data flows in only one direction: **Axiom → Engine → Circuit → Contract**. There can be no "side-channel" state transitions.

## 2. Decision: The Rigid Integration Pathways

We will implement a four-stage pipeline that physically enforces the boundaries between formal theory, execution, and consensus.

### Pathway 1: Formal to Rust (The Compile Boundary)
*The mathematical limits proven in Lean must mechanically constrain the Rust engine.*
- **Action**: Bind the constants proven in `UORMatMul.lean` (e.g., `w8a8KMax_value = 133144`) directly into the Rust engine's build script or Kani test harness.
- **Rule**: If the Rust `engine` attempts to accumulate a tensor dimension exceeding the Lean-proven ceiling, the `cargo build` must fail or the runtime must panic before generating a trace.

### Pathway 2: Rust to ZK Circuits (The Witness Boundary)
*The engine's deterministic output must be provable.*
- **Action**: The Rust `engine` will output an exact execution trace (the `CRMFWitness`) of the `Fit` operation and the `L3_MonsterSymmetryConfinement` clamp.
- **Rule**: This trace is fed directly into `Prime/circuits/prover`. Because `UORMatMul` guarantees bit-exact integer accumulation, the ZK circuit does not need to simulate floating-point logic; it only verifies the `i32` arithmetic over the declared codebook.

### Pathway 3: ZK Circuits to Contracts (The Consensus Boundary)
*Proofs become permanent, immutable reality.*
- **Action**: The ZK circuit outputs a SNARK/STARK proof. The `JubileeBridge` submits this proof to `Prime/contracts/AnchorContract.sol`.
- **Rule**: The EVM contract *only* accepts state updates (e.g., a community reaching Monstrous alignment) if a valid ZK proof of the `Fit` trace is attached. 

### Pathway 4: Governance to Execution (The Policy Boundary)
*Parameters are dictated by the Operator Atlas, not hardcoded.*
- **Action**: The Kubernetes `PhaseMirrorOperator` reads the declarative YAML policies from `Prime/operator-atlas/` (e.g., Tier IV/V Declarations) and feeds the target symmetries to the Rust engine.

## 3. Immediate Action Plan

To physically wire this up, we will execute the following technical sequence:

1. **Kani Harness Integration**: Write `Prime/crates/engine/src/kani_invariants.rs` to enforce the $k \le 133144$ bound on the W8A8 matmul loop, structurally linking it to `UORMatMul.lean`.
2. **Circuit Adapters**: Update the `air-mr64` circuits to natively parse the `CRMFWitness` JSON emitted by the Rust engine. 
3. **Contract Deployment Pipeline**: Formalize the Hardhat deployment scripts in `Prime/contracts/` to deploy the `AnchorContract` and store its address in the `materia_commons` registry.
4. **End-to-End Test (The Final Drill)**: Run the `uac_simulator`, pipe the output to the prover, generate the ZK proof, and settle it on a local Hardhat node in a single automated integration test.

## 4. Consequences
- **Positive**: Complete elimination of software supply chain and floating-point vulnerabilities. The entire DAO / community / node state is mathematically proven from axiom to blockchain.
- **Negative/Risk**: ZK proving overhead. Tracing thousands of tensor accumulations to generate a proof can be computationally heavy, though the exact-integer nature of UOR drastically reduces this cost.
