# ADR Pack: ALP / Sigma Native Integration Architecture

## Purpose

This pack proposes a coherent set of Architecture Decision Records for positioning **ALP** and **Sigma** as native control surfaces for legacy integrations, while preserving governance-first execution, two-key certification, and invariant-safe composition across the AGI-OS / Phase Mirror stack.[cite:20]

The pack assumes the current architectural direction already separates governance compliance, mathematical stability, oracle veto authority, and circuit enforcement into distinct but composable layers, rather than collapsing them into one integration surface.[cite:20]

---

## ADR Index

| ADR | Title | Status | Primary Outcome |
|---|---|---|---|
| ADR-ALP-001 | ALP as Native Policy and Contract Plane | Proposed | Makes ALP the canonical policy surface for external actions |
| ADR-SIG-001 | Sigma as Native Execution and Composition Kernel | Proposed | Makes Sigma the canonical runtime execution substrate |
| ADR-INT-001 | Legacy Integrations as Adapters, Not Authorities | Proposed | Relegates legacy systems to ingress/egress roles |
| ADR-WIT-001 | Unified Witness Requirement for Externalized Actions | Proposed | Binds external execution to compliance, stability, and veto evidence |
| ADR-MCP-001 | MCP Exposure Through Native Authority Boundaries | Proposed | Exposes tools outwardly without surrendering execution sovereignty |
| ADR-GTM-001 | Productization of Native Control Surfaces | Proposed | Defines how to package ALP and Sigma commercially |

---

## ADR-ALP-001

### Title
ALP as Native Policy and Contract Plane

### Status
Proposed

### Context
The current architectural trajectory already enforces governance-first behavior through mandatory ADR and contract references, daemon-level path validation, and fail-closed execution gates.[cite:20] At the same time, external systems still create pressure to let legacy interfaces define workflow semantics. That pressure risks relocating authority away from native governance and into adapter code.[cite:20]

### Decision
ALP will be the canonical policy, contract, and admissibility layer for all externally initiated actions.

All inbound actions from legacy platforms, operator dashboards, automation layers, and MCP tool surfaces must be normalized into ALP-native contracts before they are eligible for execution.

### Consequences
- Policy logic becomes native rather than inherited from legacy APIs.[cite:20]
- Teams gain one canonical place to define action admissibility, role semantics, contracts, and approval structure.[cite:20]
- Adapter complexity decreases because adapters translate requests into ALP contracts instead of reproducing domain logic independently.
- ALP becomes the durable control plane for governance-first product packaging.

### Files / Artifacts to Touch
- `docs/adr/ADR-ALP-001-alp-policy-plane.md`
- `docs/contracts/alp-action-contracts.md`
- `src/mcp/` or equivalent governance ingress package
- proposal schemas requiring ALP contract references

### Verification
- Every externally triggered action can be traced to an ALP contract ID.
- No execution path bypasses ALP normalization.
- CI rejects adapters lacking ALP contract bindings.

### Rollback
Revert ALP from mandatory ingress normalization to advisory mapping only; this is not recommended because it reintroduces split authority.

---

## ADR-SIG-001

### Title
Sigma as Native Execution and Composition Kernel

### Status
Proposed

### Context
The current stack already distinguishes composition from orchestration, and repeatedly prefers invariant-preserving pipelines over merged operators.[cite:20] It also formalizes hard inheritance and fail-closed execution for composite systems, preventing weaker downstream compositions from diluting stricter component guarantees.[cite:20]

### Decision
Sigma will be the canonical execution kernel for actions that have cleared ALP policy gating.

Sigma is responsible for deterministic runtime execution, workflow composition, state transition tracking, and enforcement of inherited execution constraints.

### Consequences
- Execution authority becomes native and compositional rather than scattered across scripts and third-party runtimes.
- Composite workflows inherit the strictest execution and verification requirements already present in the system's hard-inheritance model.[cite:20]
- Sigma becomes the natural destination for dashboards, operators, and non-technical interaction surfaces.

### Files / Artifacts to Touch
- `docs/adr/ADR-SIG-001-sigma-execution-kernel.md`
- `src/runtime/sigma/`
- workflow runner APIs
- execution receipt schemas

### Verification
- All approved actions execute through Sigma-managed state transitions.
- Sigma emits lifecycle status: queued, admitted, running, vetoed, failed, completed.
- No production workflow executes through unmanaged shell surfaces.

### Rollback
Allow mixed execution backends without Sigma centralization; this increases runtime ambiguity and weakens auditability.

---

## ADR-INT-001

### Title
Legacy Integrations as Adapters, Not Authorities

### Status
Proposed

### Context
The central architectural danger surfaced repeatedly in the current work is that integration layers can silently violate invariants more easily than core components themselves.[cite:20] The safe pattern is to keep external systems as bounded interfaces rather than as sovereign decision-makers.[cite:20]

### Decision
All legacy integrations will be modeled as thin adapters that perform one or more of the following roles only:
- ingress translation into ALP contracts,
- egress synchronization from Sigma receipts,
- read-only projection of native state into legacy systems.

Legacy systems may not define canonical workflow semantics, override veto logic, or serve as final execution authorities.

### Consequences
- External tools remain compatible without becoming sovereign.
- Native invariants remain centered in the platform instead of being distributed across adapter code.[cite:20]
- Migration off legacy systems becomes easier because business logic is no longer embedded in the integration layer.

### Files / Artifacts to Touch
- `docs/adr/ADR-INT-001-legacy-adapters.md`
- connector specifications for GitHub, Slack, CI, CRM, cloud APIs
- adapter test harnesses

### Verification
- Each integration declares whether it is ingress, egress, or projection.
- No adapter contains policy authority beyond mapping and transport.
- Adapter audits confirm one-way translation into native contracts and receipts.

### Rollback
Permit legacy-specific decision logic inside adapters; this is explicitly disallowed because it creates hidden governance forks.

---

## ADR-WIT-001

### Title
Unified Witness Requirement for Externalized Actions

### Status
Proposed

### Context
The current Pro-tier direction establishes that governance compliance and mathematical stability are distinct domains, and that a unified witness is required before state transitions are approved.[cite:20] The Oracle veto is meaningful precisely because it binds these domains rather than allowing one to subsume the other.[cite:20]

### Decision
Every externally visible or externally triggered action must produce a Unified Witness composed of:
- governance compliance evidence,
- runtime execution receipt,
- mathematical or invariant certification where applicable,
- veto decision status where applicable.

No action is considered authoritative unless its witness is complete for its class.

### Consequences
- External consumers get one auditable artifact rather than fragmented logs.[cite:20]
- ALP and Sigma remain connected by evidence, not by informal trust.
- Future MCP, dashboard, and API surfaces can expose native trust outputs directly.

### Files / Artifacts to Touch
- `docs/adr/ADR-WIT-001-unified-witness.md`
- `src/witnesses/`
- receipt schema definitions
- external verification interfaces

### Verification
- Witness completeness checks exist for each action tier.
- CI blocks release if a Pro-tier workflow can execute without a complete witness.
- Witness format is machine-consumable for dashboards and external verifiers.

### Rollback
Return to multi-log, multi-surface evidence; this weakens audit clarity and makes external verification harder.

---

## ADR-MCP-001

### Title
MCP Exposure Through Native Authority Boundaries

### Status
Proposed

### Context
MCP servers are useful as outward-facing tool interfaces, but exposing tools directly to execution surfaces would allow clients and connectors to bypass native authority. The current architecture instead favors explicit authority boundaries and validated execution gates.[cite:20]

### Decision
MCP servers will expose capability surfaces outwardly, but all actionable tool invocations must route through ALP admission and Sigma execution.

In this pattern, MCP is a protocol shell, not the policy or execution authority.

### Consequences
- External agents can consume capabilities without bypassing governance.
- MCP becomes a distribution layer for native tools rather than a replacement for native architecture.
- Tool monetization becomes possible without surrendering runtime sovereignty.

### Files / Artifacts to Touch
- `docs/adr/ADR-MCP-001-mcp-native-boundaries.md`
- MCP tool gateway package
- auth and tool-policy middleware
- execution proxy interfaces

### Verification
- Every MCP tool that mutates state references an ALP contract.
- Every mutating MCP action returns or links to a Sigma receipt / Unified Witness.
- Read-only tools are explicitly classified and separated from mutating tools.

### Rollback
Allow direct MCP-to-execution paths for convenience; this is disallowed because it bypasses governance-first design.

---

## ADR-GTM-001

### Title
Productization of Native Control Surfaces

### Status
Proposed

### Context
The differentiator emerging from the architecture is not mere compatibility with legacy systems, but native compatibility under stronger governance, witness, and execution guarantees.[cite:20] The commercial moat is therefore native authority with adapter compatibility, not adapter sprawl.[cite:20]

### Decision
ALP and Sigma will be packaged as named product modules:
- **ALP**: policy, contracts, approvals, admissibility, governance APIs.
- **Sigma**: execution kernel, workflow runtime, orchestration receipts, operator UX.

Legacy connectors, MCP servers, and dashboards will be packaged as extension layers around these modules.

### Consequences
- Commercial messaging becomes clearer: customers keep existing systems while shifting authority into the native stack.
- Sales motion can focus on replacing brittle glue-code governance with auditable native control surfaces.
- Internal architecture and external packaging remain aligned.

### Files / Artifacts to Touch
- `docs/adr/ADR-GTM-001-native-control-surfaces.md`
- product architecture overview
- packaging matrix for Core / Pro / Oracle tiers
- connector catalog

### Verification
- Pricing and packaging map cleanly to architectural authority boundaries.
- Sales and docs language distinguish adapters from native modules.
- Product artifacts preserve the governance-first framing established in architecture documents.[cite:20]

### Rollback
Expose connectors as primary products and ALP/Sigma as hidden internals; this weakens strategic differentiation.

---

## Suggested sequencing

The clean implementation order is:
1. ADR-ALP-001
2. ADR-SIG-001
3. ADR-INT-001
4. ADR-WIT-001
5. ADR-MCP-001
6. ADR-GTM-001

That ordering preserves the architecture-first rule already active in the governance layer: define authority, then execution, then adapter boundaries, then evidence, then exposure, then commercialization.[cite:20]

## Proposed immediate next files

- `ADR-ALP-001-alp-policy-plane.md`
- `ADR-SIG-001-sigma-execution-kernel.md`
- `ADR-INT-001-legacy-adapters.md`
- `ADR-WIT-001-unified-witness.md`
- `ADR-MCP-001-mcp-native-boundaries.md`
- `ADR-GTM-001-native-control-surfaces.md`

## Draft naming guidance

For public-facing language, ALP and Sigma work best when described as:
- **ALP** = admission, law, policy
- **Sigma** = state transition, execution, composition

That preserves the internal architectural distinction already present in the system between governance admissibility and executable state transition.[cite:20]
