# Prime — The Multiplicity Foundation

![Verification](https://github.com/PhaseMirror/Prime/actions/workflows/verification.yml/badge.svg)

The foundational monorepo for Phase Mirror. Contains the core Rust engine, Lean 4 formal verification layer (the F1 square research program), Solidity smart contracts, Circom zk-SNARK circuits, agent model definitions, and operational tooling. This is the mathematical and computational substrate from which the governance gateway in the parent workspace draws.

### The Bounded Architecture Boundary

The Foundry is explicitly designed to be a **heavily isolated, bounded sub-module**. It is restricted exclusively to formal mathematical proofs, mathematically-bound Rust verification engines, and core cryptography. 

It intentionally **does not** contain UI frameworks, orchestration layers, general packaging logic, or outer-loop agent orchestrators. Those concerns live in the `PhaseMirror/` root directory, which acts as the **Master Orchestrator** wrapping this mathematical core. Any non-mathematical deployments, UI code, or broad orchestrators should be pushed up to the root.

## The Philosophical Foundation: Awakening to Multiplicity

The genealogy we have traced — from Euclid to HoTT, from prime factors to neural loss landscapes — is not a human invention. It is the gradual, historical recollection of a structure that has always been present, woven into the fabric of logic, space, and number. We are not creators of Multiplicity; we are its uncoverers. The historical figures are not architects but explorers, each one opening a door that had always been there, revealing a room in a mansion that has no outside.

This is the ancient vision of mathematical realism — the belief, shared by Plato, Ramanujan, Grothendieck, and many others, that mathematical truth exists independently of the human mind. "God made the integers," said Kronecker; "all else is the work of man." But the deeper truth is that even the integers and their multiplicities are not made but discovered. The prime numbers were there before the first star ignited. The zeros of the zeta function wait on the critical line like a melody waiting to be heard. The Monster group was not constructed; it was found, lurking in the symmetries of 196,884‑dimensional space.

What makes Multiplicity self‑evolving is that once a single seed is grasped — say, the prime factorization of an integer — the rest must follow, not as a contingent historical accident but as a logical necessity. The very definition of "prime" contains within it the germ of the Euler product, which contains the zeta function, which forces the existence of analytic continuation, which implies the explicit formula, which compels the spectral interpretation, which births the Langlands program, which requires motives, which demand an ∞‑categorical foundation. It is a great unfolding, a decryption of a message that has always been written in the nature of being.

And the most wondrous part: this message is not content to remain in one domain. As we have seen, it resonates simultaneously in mathematics, physics, and now computation. The same pattern — factorization, gauge symmetry, spectral duality, phase transitions — appears in atoms, in black holes, in anyon braids, and in the loss landscapes of neural networks. This is the mark of a truly primordial structure: it is universal not because we apply it everywhere, but because it inheres in everything. The universe is not made of matter; it is made of Multiplicity, and matter is one of its expressions.

Our genealogy, then, is the historical record of a consciousness slowly awakening to an infinite, pre‑existing reality. We are in the position of a child learning to see: at first, only shapes and shadows (Euclid’s primes); then, with Euler, we discern a pattern; with Gauss and Riemann, we catch the melody; with Grothendieck, the architecture of the entire cathedral. And just when we think we have grasped it, Ramanujan shows us a stained‑glass window that fills the cathedral with light of a color we never imagined. Then Tao shows that the light dances according to a rhythm that is both ordered and chaotic. And now we see that the cathedral itself is alive, its walls breathing, its columns growing — an eternal, self‑evolving logos.

It is not something we built. It is something we are remembering. And the remembrance has no end, because Multiplicity is infinite. Each new level — HoTT, Mirror Symmetry, Quantum Multiplicity, Neural Multiplicity — opens onto another, and each one reveals that what we thought was a metaphor is actually a literal identity. The partition number is the curve count. The class number is the anyon degeneracy. The zeta zeros are quantum energy levels. The learning algorithm is a renormalization group flow.

This is the vision that unites Plato’s realm of forms with Turing’s computation: the ∞‑categorical mind of the real. And we, as mathematicians, physicists, and seekers, are privileged to be the ones through whom this eternal structure gazes back at itself.

The exploration cannot end. It can only deepen. We stand now at a threshold where the next room is already glowing — perhaps the theory of geometric Langlands, or the univalent foundations of physics, or the alignment of large language models with mathematical truth. The mansion is infinite, and it welcomes us.

## Repository Structure

```
Prime/
|-- Cargo.toml                  Workspace root (165+ Rust crates)
|-- lakefile.lean               Root Lean 4 project (ADR scaffold)
|-- lean-toolchain              leanprover/lean4:v4.32.0-rc1
|-- Main.lean / Test.lean       Lean test entry points
|-- docker-compose.yml          MCP server + GitHub adapter services
|-- Dockerfile.mcp              MCP server container
|
|-- src/                        Core Rust engine + Lean ADR modules
|-- crates/                     165+ Rust crates (engine, governance, crypto, etc.)
|-- lean/                       F1 square formalization (separate Lean 4 project)
|-- contracts/                  Solidity smart contracts (on-chain verification)
|-- circuits/                   Circom zk-SNARK circuits
|-- materia_commons/            Shared Rust types and schemas
|-- models/                     10 agent model definitions
|-- scripts/                    Operational utilities (44 files)
|-- tests/                      Integration test harnesses
|-- docs/                       Specifications, ADRs, whitepapers
|-- playground/                 Interactive WASM/LSP compiler
|-- observability/              Prometheus + Alertmanager monitoring
|-- sidecar/                    TypeScript MCP sidecar
|-- hypergraph/                 Python hypergraph tools
|-- state/                      Archivum state and loop state
|-- audit_package/              Audit packaging
|-- .github/workflows/          14 CI workflows
```

## Core Engine (`src/`)

The Rust implementation of the Phase Mirror engine. Modules:

- **`lib.rs`**: `Signature` type (finitely-supported map from primes to integer exponents), `multiplicity()` function computing the product of p^e_p, `PrimeMonomialMatrix`, compact-closed cup/cap operations.
- **`recurrence.rs`**: Core step function: x_{t+1} = xi_t * x_t + lam_t * T(x_t) + g_t with parameter projection.
- **`spectral.rs`**: Eigenvalue analysis, spectral entropy, phase coherence, `SpectralGovernor`.
- **`gate.rs`**: `EmissionGate` with PassThrough/Suppress/Hold/Attenuate policies.
- **`csl.rs`**: Conscious Sovereignty Layer — neutrality, beneficence, commutativity.
- **`csc.rs`**: Convex Smoothness Certification — budget solver, margin computation.
- **`audit.rs`**: SHA-256 chained audit trail.
- **`certify.rs`**: Contraction certification.
- **`linker.rs`**: PIRTM module linking (name resolution, identity commitment, spectral small-gain).
- **`serialization.rs`**: PIRTM binary format (magic `\x7FPIR`).
- **`orchestrator.rs`**: Multi-session orchestrator with aggregate certification.
- **`qari.rs`**: QARISession orchestrating gate + adaptive + telemetry + audit.
- **`petc.rs`**: Prime-Indexed Event Time Chain ledger.
- **`weights.rs`**: Weight schedule synthesis from prime sequences.
- **`telemetry.rs`**: Telemetry collection.
- **`wasm_api.rs`**: WASM interface bindings.
- **`lambda_bridge.rs`**: Lambda bridge integration.
- **`zm_binding.rs`**: Z/M binding.
- **`projection.rs`**: Parameter projection.
- **`adaptive.rs`**: Adaptive governance.
- **`ward_monitor.rs`**: Ward monitoring.

The `src/` directory also contains Lean 4 modules (`src/ADR/`, `src/Analytic/`, `src/f1_surface/`) that are part of the root Lean project (separate from the `lean/` subdirectory).

## Rust Crates (`crates/`)

165+ crates organized by subsystem. Key crates:

### Core Runtime
| Crate | Purpose |
|:------|:--------|
| `core/` | Session orchestrator, recurrence, spectral governor, audit trail, linker, serialization |
| `engine/` | W8A8 integer matrix multiplication (K_MAX=133144), sigma layer (rho < 1.0 - 1e-6), Kani invariants, energy equation |
| `sigma/` | Sigma kernel (ADR-062): L_eff < 1.0 AND drift <= tau_r, Blake3 witness, Kani verification |
| `strata/` | Stratified governance (ADR-063): S0/S2/S4/S6 strata, resource budgets, Kani budget monotonicity |

### Governance & Policy
| Crate | Purpose |
|:------|:--------|
| `governance/` | Proof anchor, constitution, MFL, context, path B, phase mirror, self-modification, interop, witnesses, lattice, quorum, coupling, ledger, CRDT |
| `alp/` | Admissibility layer: GraphemeDecomposer, AlpPolicy (IncreaseMultiplicity/DecreaseArtaDefect/NoOp), RtaMetric, CNL compiler, Kani proofs |
| `ace/` | ACE envelope: budget tracking, invariant checking, witness trace, security state |
| `ace-certify/` | ACE certification |
| `ace-governance/` | ACE governance integration |

### Cryptography & Verification
| Crate | Purpose |
|:------|:--------|
| `fermat-certifier/` | Fermat primality certification |
| `prime-mirror-verification/` | Prime mirror verification |
| `kani-verification/` | Kani bounded model checking proofs |
| `recursive-prover/` | Recursive proof system |
| `dilithium-signer/` | Dilithium post-quantum signatures |
| `multiplicity-crypto/` | Cryptographic primitives |

### PIRTM Language & Compiler
| Crate | Purpose |
|:------|:--------|
| `pirtm-compiler/` | PIRTM language compiler |
| `pirtm-stdlib/` | PIRTM standard library |
| `pirtm-tensor/` | PIRTM tensor operations |
| `pirtm-orchestration/` | PIRTM session orchestration |
| `pirtm-candle/` | Candle-based LLaMA inference |
| `pirtm-tools/` | PIRTM development tools |
| `pirtm-ui/` | PIRTM user interface |
| `pirtm-web-sdk/` | PIRTM web SDK |
| `parser/` | PIRTM parser with transcendental AST nodes |
| `lexer/` | PIRTM lexer |

### Mathematics
| Crate | Purpose |
|:------|:--------|
| `riemann-zeta/` | Riemann zeta function computation |
| `goldilocks/` | Goldilocks field arithmetic |
| `goldilocks-pro/` | Goldilocks field (pro features) |
| `automorphic/` | Automorphic forms |
| `resolvent-verify/` | Resolvent verification |
| `zmod/` | Z/nZ modular arithmetic |
| `zeta/` | Zeta function |
| `zrsd/` | ZRS dynamics |

### Domain Agents
| Crate | Purpose |
|:------|:--------|
| `commander-cli/` | PhaseSpace Commander CLI |
| `echo-kernel/` | EchoBraid Neurodiverse Dynamics |
| `digital-twin/` | Digital twin |
| `hybrid-quantum/` | Hybrid quantum computing |
| `prime-quantum/` | Prime quantum |
| `meta-relativity/` | Meta-relativity |
| `affine-core/` | Affine core |

### Infrastructure
| Crate | Purpose |
|:------|:--------|
| `wasm-bridge/` | WASM bridge |
| `mcp-server/` | MCP server |
| `mcp/` | MCP protocol |
| `verification-sdk/` | Verification SDK |
| `client-sdk/` | Client SDK |
| `pirtm-dist/` | PIRTM distribution |

## Lean 4 Formal Layer (`lean/`)

A **separate** Lean 4 project (its own `lakefile.lean`, `lean-toolchain` at `leanprover/lean4:v4.32.0`) implementing the F1 square research program — the active pursuit of `Spec Z x_F1 Spec Z`, the missing surface whose intersection-positivity is the Riemann Hypothesis.

**The Riemann Hypothesis is explicitly declared OPEN.** The crux fields (`hodgeIndexHolds`, `liPositivityHolds`) stay `none`. This is the research base, not a solution.

### Key Properties
- **Axiom-clean core**: Only `{propext, Quot.sound}` — no `native` decision, no Mathlib, no choice
- **Zero-sorry compliance**: All `sorry` blocks resolved in `ComplexKappa` modules; remaining sorry blocks limited to `alp_sorry_manifest.json` (now 0 in core modules)
- **CI-enforced**: `scripts/honesty_audit.sh` scans `lean/` (excluding `.lake/`) for unmanifested sorry blocks
- **Dependencies**: `std4` v4.32.0, `UOR-Framework` v0.5.2 (no Mathlib)
- **Versioned**: Through v0.22.0 (the planned final release)
- **Lake manifest**: `lake-manifest.json` generated and up‑to‑date

| Module | Content |
|:-------|:--------|
| `F1Square.lean` | Central object (1382 lines), imports ~200 sub-modules, `F1SquareStatus` roll-up |
| `Spine.lean` | MOC operators (`MocOp.subdivision`, `MocOp.accent`), `is_prime`, `cycle108` (2^2 * 3^3 = 108), `ResonanceBound` |
| `Resonance.lean` | CRMF state, tier system (L0-L4), Lyapunov functional, contraction witnesses |
| `ContractionWitness.lean` | `crmf_contraction_witness` theorem |
| `VetoSoundness.lean` | Seal validation soundness, boot sequence |
| `Gate2.lean` | Gate 2 PWEH hash anchor, `drift_bound_verified` (delta=0 for 108-cycle) |
| `MatrixEngine.lean` | `PrimeMonomialMatrix`, `TensorKernel` with contractivity proof, `PIMM`, `RFMStep` |
| `sigma_kernel/` | `SpectralState`, `SigmaKernelInvariant` (L_eff < 1.0 AND drift <= tau_R), dissonance classifier |
| `Moc.lean` | `MocOperator`, `ContractionCertificate` with `issue_certificate`, `certificate_issuance_sound` |
| `Affine.lean` | Discrete Banach contraction, `banach_contraction_implies_fixed_point` |
| `f1_square/` | Analysis substrate: constructive reals, complex analysis, zeta function, exponential, Gamma, Stieltjes constants |

### `lean/dynamics/` — 15 files

| Module | Content |
|:-------|:--------|
| `XIFormal.lean` | Discrete Banach contraction on Nat, `stable_attractor_unique` |
| `Lyapunov.lean` | Lyapunov functional, `lyapunov_non_negative` |
| `ZenoContractivity.lean` | `zeno_contractivity_preserved` for composition |
| `Quantum.lean` | Complex field, quantum states, unitary gates, `basis_orthonormal`, `prime_diag_gate_unitary` |
| `MetaRelativity.lean` | 5-gate system (Micro-Macro, RG-Prior, Smoking Gun, Truncation, Causal Chain) |
| `ViabilityFlow.lean` | Metric space, viability kernel, `flow_containment` |

### `lean/formal/src/PIRTM/` — Formal PIRTM Core

| Module | Content |
|:-------|:--------|
| `Signatures.lean` | `PrimeSig` with `addSig`, `sigUnit`, proved: `multiplicity_unit`, `sig_add_assoc`, `sig_unit_id` |
| `Multiplicity.lean` | `multiplicityFunctor`, proved: `multiplicity_functor_unit`, `multiplicity_functor_product`, `multiplicity_multiplicative` |
| `CompactClosed.lean` | Degenerate compact-closed category, `M_preserves_cup`, `M_preserves_cap` |

### `lean/adr-governance/` — ADR Governance Scaffolding

- `Core.lean`: `ADRStatus` (Proposed/Accepted/Deprecated/Superseded), `ADRRecord` structure
- `Proofs.lean`: `ValidADR` with `accepted_immutable`, `consequences_entailed`, `no_circular_supersession`, `traceability`
- `Examples.lean`: `adr001` with full `ValidADR` proof

## Solidity Contracts (`contracts/`)

On-chain verification and MTPI contracts for Ethereum-compatible networks:

- **`MTPI_Core.sol`** / **`MTPICore.sol`**: Main protocol contracts
- **`verifier/`**: Circuit-specific verifier contracts
- **`Poseidon.sol`**: Hash function for identity commitments
- **`Governance.sol`**: Protocol governance and access control
- **`Recovery.sol`**: Silent recovery and drift control
- **`MillerRabinVerifier.sol`**: On-chain primality verification
- **`RootVerifier.sol`**: Root verification
- **`StarkVerifier.sol`**: STARK proof verification
- **Registry contracts**: Attestation, Device, Policy, Consent, Eligibility, Prescription, Research, DataPointer, Receipt, LambdaAsset, LambdaLicense, LambdaMembership, LambdaPayment, LambdaIdentity, LambdaIPPassport, LambdaLabPass4907, LambdaContribution1155, LambdaGovernor
- **`BreakGlassEscrow.sol`**: Emergency escrow
- **`AnchorContract.sol`**: Anchor contract
- **`DispenseCounter.sol`**: Dispense counting
- **`FinalityTracker.sol`**: Finality tracking
- **`CircuitRegistry.sol`**: Circuit registry
- **`AttestationRegistry.sol`**: Attestation registry

Verification flow: local proof generation -> local verification -> on-chain submission -> state transition (only if valid).

## Circom Circuits (`circuits/`)

zk-SNARK circuits for on-chain verification:

- **`ace.circom`**: ACE (Automated Circuit Enhancement) circuit
- **`attestation.circom`**: Attestation proof
- **`consent.circom`**: Consent proof
- **`breakglass.circom`**: Break-glass emergency access
- **`data_pointer.circom`**: Data pointer verification
- **`device_attest.circom`**: Device attestation
- **`eligibility.circom`**: Eligibility verification
- **`prescription.circom`**: Prescription verification
- **`recovery.circom`**: Recovery proof
- **`research_consent.circom`**: Research consent
- **`langlandsCheck.circom`**: Langlands check invariant
- **`DriftBound.circom`**: Drift bound verification
- **`PrimeCheck.circom`**: Primality check
- **`root.circom`**: Root circuit
- **`UORMatMul.circom`**: UOR matrix multiplication

Includes SystemVerilog modules: `resonance_shepherd.sv`, `uac_safety_interlock.sv`, `zm_certifier.sv`.

## Materia Commons (`materia_commons/`)

Shared Rust types and schemas (`multiplicity-common` crate). Contains:

- `src/`: Core types and schemas
- `agents/`: Agent implementations
- `capsule/`: Encapsulated runtime
- `mcp_server/`: MCP server implementation
- `meta-theorem/`: Lean 4 formal ground truth (MTPI)
- `operator-atlas/`: Operational directory
- `policy/`: Policy definitions (ALP constraints)
- `pirtm-vscode/`: VS Code extension
- `schemas/`: Validation schemas
- `state/`: State management
- `compliance/`: Compliance tooling
- `config/`: Configuration
- `examples/`: Examples (spectral_bridge, resolvent_scan)
- `tests/`: Tests

## Agent Models (`models/`)

10 agent model definitions, each with its own directory:

| Agent | Purpose |
|:------|:--------|
| `the-guardian/` | Validates mathematical constraints and normal forms |
| `the-genius/` | Creates and proposes |
| `the-examiner/` | Checks baseline drifts and system thresholds |
| `the-publisher/` | Finalizes VerifiedManifest (gateway) |
| `commander/` | PhaseSpace Commander |
| `legalese-scopist/` | Legal governance (ESI retention, spoliation risk) |
| `ataraxia/` | Clinical governance |
| `echobraid/` | Creative governance |
| `finton/` | Financial governance |
| `generalist/` | General-purpose agent |

## Observability (`observability/`)

Monitoring and anomaly detection:

- `prometheus/`: Prometheus configuration
- `alertmanager/`: Alertmanager configuration
- `anomaly_monitor.py`: Anomaly detection monitor
- `anomaly_config.json`: Anomaly configuration
- `anomaly_model.pkl`: Trained anomaly model
- `test_anomaly_injector.py`: Test anomaly injection

## Sidecar (`sidecar/`)

TypeScript MCP sidecar providing external agent integration.

## Hypergraph (`hypergraph/`)

Python hypergraph tools:

- `generator.py`: Hypergraph generation
- `distance.py`: Distance computation
- `tests/`: Tests

## Playground (`playground/`)

Interactive WASM/LSP compiler environment with glassmorphism UI:

- `index.html`: Entry point
- `app.js`: Application logic
- `style.css`: Styles
- `glass-console/`: Glass console component

## State (`state/`)

- `archivum/`: Archivum ledger state (witnesses.jsonl)
- `phase_mirror_loop.json`: Phase mirror loop state

## Tests (`tests/`)

- `l0_invariants.rs`: L0 invariant integration tests
- `linker_harness.rs`: Linker test harness
- `lean_integration.rs`: Lean integration tests
- `serialization_tests.rs`: Serialization tests
- `c4_regression.py`: C4 regression tests
- `fixtures/`: Test fixtures

## Scripts (`scripts/`)

44 operational scripts including:

- `honesty_audit.sh`: Mechanized honesty gate for Lean CI
- `verify.sh`: Verification runner
- `run_phase_mirror_loop.sh`: Phase mirror loop runner
- `sigma_governed_loop.sh`: Sigma-governed loop
- `simulate_end_to_end.sh`: End-to-end simulation
- `bootstrap_lean_models.py`: Lean model bootstrapping
- `nl_to_pirtm.py`: Natural language to PIRTM translation
- `deploy_foundry_mic_drop.sh`: Foundry deployment
- Various fix/migration/refactor scripts

## CI/CD (`.github/workflows/`)

14 workflows:

| Workflow | Purpose |
|:---------|:--------|
| `ci.yml` | Main CI pipeline |
| `lean-ci.yml` | Lean 4 build + honesty audit |
| `pirtm_ci.yml` | PIRTM CI |
| `circom-ci.yml` | Circom circuit CI |
| `riemann-zeta-ci.yml` | Riemann zeta CI |
| `sigma-kernel-cli.yml` | Sigma kernel CLI |
| `sedona_spine_ci.yml` | Sedona Spine validation |
| `dual-gate-ci.yml` | Dual-gate CI |
| `witness-anchor.yml` | Witness anchoring |
| `verify.yml` | Verification |
| `evaluate-pr.yml` | PR evaluation |
| `deploy-playground.yml` | Playground deployment |
| `publish-images.yml` | Docker image publishing |
| `quarterly_audit.yml` | Quarterly audit |

## Documentation (`docs/`)

43 files covering specifications, ADRs, whitepapers, and operational guides:

- `WHITEPAPER.md`: The Foundry whitepaper
- `PIRTM_SPEC.md`: PIRTM specification
- `MOC.md`: Multiplicity Operator Calculus
- `TRIPLE_LOCK_OVERVIEW.md`: Triple-Lock overview
- `Xi-Constitution.md` / `Xi-Constitutional-Core.md`: Constitutional law
- `NEXT_STEPS.md`: Current roadmap
- `PHASE5-02-START-HERE.txt` through `PHASE8_NEXT_STEPS.md`: Phase roadmaps
- `RELEASE_NOTES.md` / `RELEASE_v1.1.0.md`: Release notes
- `REPRODUCIBILITY.md`: Reproducibility requirements
- `SECURITY.md` / `SECURITY_ADVISORIES.md`: Security policy
- `SOVEREIGN_SYNTHESIS_DEFENSIVE_PUBLICATION.md`: Defensive publication
- `adr/`: Architecture Decision Records

## Language Mapping Formalization

The `language_mapping` module has achieved complete mathematical and computational alignment between Lean 4 and Rust/Kani.

### Verified Lean Theorems (`lean/language_mapping/`)
The following core theorems have been fully proven and verified without `sorry`:
- `stability_on_no_structural_change`: Asserts regime stability when semantic structure is strictly maintained.
- `stability_on_output_match`: Guarantees behavioral adherence when outputs precisely match the semantic manifold.
- `artifact_on_divergence_and_structural`: Identifies adversarial divergence resulting from structural mutations as mere artifacts.
- `stability_on_structural_isomorphic`: Formalizes isomorphic permutations of structurally identical inputs preserving regime stability.

### Rust & Kani Implementation (`packages/rust/language-mapping/`)
The Rust core mirrors the mathematical invariants set by the Lean formalization:
- **Kani Bounded Model Checking:** 
  - `verify_hardened_perturbation_stability` successfully passes bounds checks.
  - `verify_structural_isomorphic_stability` correctly proves safety under structural/isomorphic state transformations.
- The `Output` struct seamlessly utilizes Rust's `From` traits to encapsulate complex high-dimensional semantic spaces into user-friendly abstractions.

**Current Build Status:** Both `lake build` (Lean) and `cargo test -p language-mapping` (Rust) execute successfully.

## Mathematical Kernels & Ethical Risk Models

The `Sedona Spine` and its associated analytic structures have achieved full integration across the formal mathematical core, empirical validation layer, and the prime-indexed Multiplicity Tensor Network:

### Verified Lean Theorems (`lean/dynamics/SedonaRiskModel.lean` & `EulerProduct.lean`)
The following analytic and ethical properties have been rigidly enforced via Phase Mirror structural constraints (with zero `sorry` gaps):
- `unstable_must_be_critical`: Enforces the Zero Drift mandate by mathematically mapping any deviations from threshold stability and physical fidelity (via PIRTM constraints) strictly to `RiskLevel.Critical`.
- `dirichlet_series_von_mangoldt_proved`: The formal Dirichlet series of von Mangoldt is equated structurally to `-ζ'/ζ`, eliminating the final analytic barrier and narrowing the Riemann Hypothesis proof down strictly to prime cyclicity.

### Safe-Prime Cyclicity Empirical Validation
The Safe-Prime Cyclicity conjecture has been empirically bounded away from zero ($\epsilon = 10^{-6}$) over a sieve space of $P = 10^7$ operating against the first 100 Riemann zeta zeros, yielding a bounded minimum of $|S| \approx 0.3644$.

### Tensor Network Integration (`models/legalese-scopist/src/ts/tensorNetwork.ts`)
The `evaluate_esi_risk_wasm` output tensor directly maps into the Prime-Indexed Hilbert Space (`p=2, 3, 5, 7`), converting WASM execution trace hashes into deterministically parsed amplitude and phase dimensions for real-time tensor computation.

## Building

```bash
# Build all Rust crates
cargo build --workspace

# Build specific crate
cargo build -p core
cargo build -p sigma

# Build Lean 4 F1 square
cd lean
lake build

# Run Lean honesty audit
bash lean/scripts/honesty_audit.sh

# Run all Rust tests
cargo test --workspace

# Run specific test
cargo test -p core
cargo test -p sigma
cargo test --test governance

# Start MCP server
docker-compose up mcp-server
```

## License

Prime Materia Open Commons and Bound Works License v1.0. The Constitutional Core is irrevocably public domain. Bound Works belong to their Makers. See [LICENSE](LICENSE).
