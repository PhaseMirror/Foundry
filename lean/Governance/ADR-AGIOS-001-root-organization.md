# ADR-AGIOS-001: agi-os Root Directory Organization & Governance Mapping

**Status:** PROPOSED
**Date:** 2026-05-21
**Author:** Gemini CLI Agent
**Dependency:** ADR-020 (PhaseMirror-HQ Protocol Compliance)

## Context
As `agi-os` transitions to a governed child repository under `PhaseMirror-HQ` (the Governor), its internal root structure must reflect this relationship. The current root contains a mix of application logic, protocol-bound infrastructure, and legacy noise. We require a standardized organizational scaffold to clearly delineate application-level code from Governor-protocol consumers and to ensure institutional auditability.

## Decision
We establish a standardized root directory organization for `agi-os` that strictly separates governance, protocol, and application layers.

### 1. Mandatory Root Structure
```text
agi-os/
├── docs/                # Application-specific documentation (non-HQ)
├── gov/                 # Governance-compliance overrides (must link to HQ)
├── src/                 # Application-level logic (the "Governed" layer)
├── packages/            # Ephemeral/App-specific packages (not promoted to HQ)
├── tests/               # Local validation tests (must run against HQ protocol tests)
├── .governance-manifest # Linkage file to PhaseMirror-HQ protocol version
└── ...
```

### 2. Governance Mapping Rules
* **Protocol-Dependent Infrastructure:** Any code consuming protocols from `PhaseMirror-HQ` MUST be scoped to `src/governance_consumers/` and MUST NOT contain re-implementations of HQ-defined primitives.
* **Separation of Concerns:** 
    * `packages/`: Restricted to substrate-specific application logic.
    * `gov/`: Contains the `GovernancePolicy` overrides (if any) that this instance is allowed to hold, as authorized by HQ.
* **Manifest Binding:** The `.governance-manifest` file SHALL contain the pinning information for the `PhaseMirror-HQ` protocol version this instance is authorized to operate under.

## Consequences
- **Positive:** Enables structural auditability; prevents architectural divergence; simplifies CI integration with HQ protocol compliance tests.
- **Negative:** Requires an initial refactoring cost for the current sprawling root.
- **Tradeoff:** Structural conformity to the Governor hierarchy over rapid, ad-hoc organization.

## Implementation Requirements
- Create `gov/` directory.
- Relocate application-specific packages into a standardized sub-directory under `packages/` or `src/`.
- Generate `.governance-manifest` pinning the current HQ protocol version.
- Update CI pipeline to validate `src/` against `PhaseMirror-HQ/tests/compliance/`.
