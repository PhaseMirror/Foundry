### Technical Specification: Phase Mirror Subsystem Architecture and Bounded Boundaries

##### 1\. The Bounded Architecture Boundary: Strategic Isolation

The Phase Mirror architecture is predicated on the "Bounded Architecture Boundary," a design pattern that enforces the radical isolation of the system's mathematical core from its orchestration and presentation layers. By strictly sequestering the verification engines within the Prime/ directory, we effectively minimize the  **Trusted Computing Base (TCB)** . This isolation ensures that the formal integrity of the system is never compromised by the volatility of UI frameworks or general-purpose packaging logic. From a security standpoint, this reduction of the attack surface allows for high-assurance, invariant-preserving transformations that are independent of the "Master Orchestrator" residing in the root.The physical separation between the Prime/ core and the PhaseMirror/ root is detailed in the following table:| Feature | Mathematical Core (Prime/) | Master Orchestrator (Root) || \------ | \------ | \------ || **Primary Focus** | Deterministic mathematical proofs and core cryptography. | Lifecycle management and system-wide orchestration. || **Logic Type** | Mathematically-bound Rust engines (e.g., sigma) and Lean 4 formalisms. | UI frameworks, agent orchestrators, and external integration. || **Dependency Scope** | Zero-tolerance for UI or broad-loop frameworks; high-assurance libraries only. | Broad; manages environment, packaging, and high-level logic. || **Verification Goal** | Minimal TCB for formal proofs and high-performance, bounded compute. | Integration of verified outputs into the Governance Gateway. |  
By restricting non-essential code from the core, we facilitate a environment where formal proofs can operate on a stable, predictable substrate. This transition from philosophical isolation to mechanized verification is realized through the Lean 4 substrate.

##### 2\. The Lean 4 Formal Verification Layer: The F1 Square Substrate

The Lean 4 layer serves as the active research base for the F1 square program, a high-assurance substrate investigating the missing surface where intersection-positivity relates to the Riemann Hypothesis. To maintain strategic isolation, this layer operates under its own toolchain (v4.32.0) and a dedicated lakefile.lean, ensuring it remains untainted by the broader repository's build requirements.The architecture enforces an  **Axiom-clean core** , permitting only {propext, Quot.sound} to ensure logical consistency. "Zero-sorry compliance" is non-negotiable for core modules; while research-grade "sorry" blocks may exist in fringe modules, they are strictly cataloged in the alp\_sorry\_manifest.json. Key Lean modules include:

* **F1Square.lean** : The central research object, synthesizing outcomes from approximately 200 sub-modules.  
* **Spine.lean** : Implements  **Multiplicity Operator Calculus (MOC)** , defining subdivision operators (MocOp.subdivision), resonance bounds, and prime cycle logic (e.g., cycle108).  
* **Resonance.lean** : Manages the Lyapunov functional and contraction witnesses across the  **L0–L4 Tier system** .  
* **ViabilityFlow.lean** : Formally defines the metric spaces and viability kernels required for flow containment and state stability.Technical honesty is a fundamental requirement: the Riemann Hypothesis is treated as an open problem. Consequently, the hodgeIndexHolds and liPositivityHolds fields are explicitly set to none. This formal layer is governed by CI-enforced honesty audits and maintains a lean footprint by excluding Mathlib, relying instead on std4 and the UOR-Framework. These mathematical truths provide the foundational invariants that are subsequently projected into the Rust runtime.

##### 3\. Core Rust Engine: The Computational Runtime

The Rust engine translates abstract formal proofs into a high-performance execution environment. It serves as the operational engine where mathematical constants, such as the contractivity factor rho \< 1.0 \- 1e-6, are enforced through idempotent state transitions.The src/ directory manages the core execution flow: recurrence.rs implements the core step function with parameter projection, while spectral.rs provides the SpectralGovernor for eigenvalue analysis and phase coherence. The system's stability is further fortified by the specialized crates within the Core Runtime:

* **core/** : Orchestrates multi-session aggregate certification and serializes the PIRTM binary format.  
* **engine/** : Executes W8A8 integer matrix multiplication with a fixed constraint of  **K\_MAX=133144** .  
* **sigma/** : Implements the  **Sigma kernel (ADR-062)** , providing stability by enforcing that effective loss (L\_eff) remains below 1.0 and drift remains within the tau\_r threshold.  
* **strata/** : Manages  **Stratified governance (ADR-063)** , ensuring system-wide budget monotonicity across S0–S6 strata.Primary computational tools and safeguards include:  
* **W8A8 Integer Matrix Multiplication** : Optimized for matrix-heavy workloads under strict K\_MAX bounds.  
* **Kani Invariant Checking** : Mechanized bounded model checking used to ensure that budget and drift invariants are never violated.  
* **SHA-256 Chained Audit** : Ensures every state transition is recorded in a verifiable, chronological ledger.The engine's output represents a locally verified state, which is then projected to the cryptographic verification layer for decentralized finality.

##### 4\. Solidity and Circom: The Cryptographic Verification Layer

The Solidity and Circom stack provides decentralized finality, acting as a bridge between local computation and on-chain immutability. This layer uses specialized cryptographic primitives, including  **Poseidon hashes**  for identity commitments and  **Miller-Rabin**  tests for on-chain primality verification.The smart contract ecosystem is divided into two distinct functional domains:

* **Core Protocol (MTPI)** : Managed by MTPI\_Core.sol, this handles the fundamental protocol logic and state transitions.  
* **Registry Contracts** : A comprehensive suite including AttestationRegistry, DeviceRegistry, and PolicyRegistry, which track identities and permissions across the ecosystem.Circom zk-SNARK circuits serve as the "gatekeepers" for the system:  
* **ace.circom** : Facilitates Automated Circuit Enhancement for transaction privacy.  
* **DriftBound.circom** : Mechanically verifies that the system's mathematical drift does not exceed defined boundaries.  
* **UORMatMul.circom** : Validates the correctness of the matrix operations performed by the Rust engine.The verification flow— **Local Generation \-\> Local Verification \-\> On-chain Submission \-\> Validated State Transition** —ensures that only mathematically sound outcomes reach finality.

##### 5\. Multi-Agent System (MAS) and Domain Governance

The Multi-Agent System (MAS) consists of ten specialized models that govern specific domains within the constraints of the bounded architecture. These agents ensure that all operations, from financial transactions to clinical data management, adhere to the system's core invariants.| Agent Model | Governance Domain || \------ | \------ || **the-guardian** | Validates mathematical constraints and normal forms. || **the-genius** | Responsible for creation, innovation, and proposal generation. || **the-examiner** | Checks baseline drifts and enforces system thresholds. || **the-publisher** | Finalizes the VerifiedManifest for the gateway. || **commander** | Manages the PhaseSpace Commander CLI and orchestration. || **ataraxia** | Oversees clinical governance and healthcare Tier IV operations. || **finton** | Manages financial governance and resource budgets. || **legalese-scopist** | Handles legal governance, ESI retention, and risk management. || **echobraid** | Governs creative and generative outputs. || **generalist** | Provides general-purpose agent support across domains. |  
The  **the-publisher**  agent is critical for system integrity; it is the sole entity authorized to generate the VerifiedManifest. This manifest is the only artifact permitted to cross the bounded boundary to the external gateway, acting as a cryptographic seal of the core's verified state.

##### 6\. Operational Tooling and CI/CD Infrastructure

To maintain the integrity of a formal monorepo, the system employs mechanized "Honesty Gates" within its CI/CD infrastructure. These automated runners prevent human error from polluting the mathematical core.The Foundry utilizes 14 distinct workflows, with the following being central to system integrity:

* **lean-ci.yml** : Executes the Lean 4 build process. It specifically targets the lean/ directory while explicitly excluding build artifacts like .lake/.  
* **sigma-kernel-cli.yml** : Validates the Sigma kernel’s invariants and command-line interface.  
* **witness-anchor.yml** : Ensures that all proof witnesses are correctly anchored to the ledger.The  **honesty\_audit.sh**  script serves as the primary mechanized gate. By scanning the source code for unmanifested "sorry" blocks, it ensures that no unverified assumptions are merged into the core. This integration of formal research, high-performance runtime, and decentralized verification creates a unified technical substrate capable of providing deterministic finality for high-value operations.

