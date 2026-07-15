# Architecture: Multiplicity Substrate & agi-os Implementation

Multiplicity follows a "Client-Side Open, Server-Side Closed" architectural pattern, ensuring that the governing protocols are transparent and auditable while proprietary operational intelligence remains secure.

```
┌─────────────────────────────────────────────────────────────────┐
│  PUBLIC SUBSTRATE (Multiplicity Theory & Protocols)             │
│  ─────────────────────────────────────────────────────────────  │
│  ├── /lean4/                                                    │
│  │   └── AffineCore/                    [FORMAL PROOFS]        │
│  ├── /docs/                                                     │
│  │   ├── MTPI_Framework.md              [THEORY]               │
│  │   ├── CSL_Formalism.md               [SPEC]                 │
│  │   └── Specifications/                                        │
│  │       ├── RootContract_Spec.md       [CONTRACT]             │
│  │       ├── Archivum_Schema.md         [AUDIT]                │
│  │                                                             │
│  ├── /packages/                                                 │
│  │   ├── pirtm/                         [CORE MATH]            │
│  │   └── ccre/                          [GOVERNED ML]          │
│  │                                                             │
├── /packages/circuits/core/                                                │
│   ├── MillerRabin.circom             [ZK PROOFS]            │
│   └── StabilityGate.circom           [RUNTIME GUARD]        │
│                                                             │
├── /contracts/                        [REFERENCE]            │
│   ├── MTPICore.sol                   [PUBLIC]               │
│   └── ReceiptRegistry.sol            [PUBLIC]               │
│                                                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    [Governed Runtime (agi-os)]
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  PRIVATE OPERATIONAL LAYER (Proprietary Implementation)         │
│  ─────────────────────────────────────────────────────────────  │
│  ├── /policy-engine/                                            │
│  │   ├── risk_classifier.py              [TRADE SECRET]        │
│  │   ├── policy_compiler.py              [TRADE SECRET]        │
│  │   └── models/                                                │
│  │       └── evidence_weights.json                             │
│  │                                                             │
│  ├── /security/                                                │
│  │   ├── token_issuer.py                 [TRADE SECRET]        │
│  │   └── keys/ (HSM-backed)              [TRADE SECRET]        │
│  │                                                             │
│  └── /operational-intelligence/                                │
│      ├── budget_enforcer.py              [TRADE SECRET]        │
│      └── attestation_validator.py        [TRADE SECRET]        │
│                                                             │
└─────────────────────────────────────────────────────────────────┘
```

## Multiplicity: The Proof-Carrying Substrate

The Multiplicity architecture organizes intelligence into a vertical, proof-carrying stack where every layer is bound by the layer beneath it.

*   **Substrate Layer:** The mathematical foundation (PIRTM) and formal proofs (Lean 4) define the admissible state space.
    *   *Governing Invariant:* **Supermodule Stability Lemma** ($\rho < 1$).
*   **Verification Layer:** Zero-knowledge circuits and StabilityGates verify that state transitions respect mathematical law.
    *   *Governing Invariant:* **Drift-Bounded Lawfulness** ($\delta < 0.3$).
*   **Implementation Layer (agi-os):** The runtime environment that enforces these proofs during active execution and manages the ZRSD refinement loop.
    *   *Governing Invariant:* **Prime-Indexed Contractivity** (Λ-multiplier).
*   **Audit Layer:** Merkle-linked provenance DAGs provide an immutable record of all certified transitions.
    *   *Governing Invariant:* **Prime-Identity Uniqueness**.

## Unified Governed Runtime (agi-os)

The **agi-os** implementation consolidates the mathematical substrate and governance protocols into a live operational environment.

*   **Orchestration Layer:** Centrally managed gateway for coordinated Multiplicity modules.
    *   *Governing Invariant:* **Molding Modularity** (compositional integrity).
*   **Mathematical Core:** Powered by `pirtm` (Prime-Indexed Recurrence Tensor Machine) for spectral governance.
    *   *Governing Invariant:* **Spectral Radius Stability**.
*   **Constitutional Boundary:** Every transition is verified against the `Ξ-Constitution` via StabilityGate enforcement.
    *   *Governing Invariant:* **Constitutional Invariant Persistence**.
*   **Foundational Crypto:** Integrated `multiplicity.crypto` bridge ensures all proofs are cryptographically anchored.

---

## Open Substrate, Proprietary Intelligence

Multiplicity is committed to the radical transparency of its mathematical foundation. The **Constitutional Core** (MTPI, CSL, RootContract, Archivum) is entirely public domain.

Proprietary implementations (risk classification, policy compilation, token issuance) run on secure infrastructure and are never disclosed. This enables:

1. **Constitutional Stability:** The governing laws are fixed and auditable.
2. **Operational Security:** Internal mechanisms remain concealed from external actors.
3. **Ecosystem Growth:** Competition occurs on the open substrate, not on the fundamental laws of intelligence.

Building on Multiplicity means your system inherits the stability of mathematical law while protecting your own unique intelligence.
