---
title: "ADR-087: UOR Primitives Type Family as Core Ontology"
status: "Adopted"
date: "2026-07-15"
deciders:
  - "Multiplicity Core Team"
tags:
  - "UOR"
  - "Core Ontology"
  - "Production"
---

## Status
**Adopted** (2026-07-15)

## Table of Contents
- [Context](#context)
- [Decision](#decision)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative](#negative)
- [Implementation Steps](#implementation-steps)
- [References](#references)

## Context
The `Prime/lean/UOR/` directory defines the **Universal Object Reference (UOR)** ontology:
- `Primitives.lean` — XSD primitive type family (`String`, `Integer`, `NonNegativeInteger`, `PositiveInteger`, `Decimal`, `Boolean`)
- `Structures.lean` — Generated structures including `IOBoundary`, `Certificate`, `BornRuleVerification`, `ChainAuditTrail`, `CompletenessAuditTrail`, `GenericImpossibilityCertificate`, `GeodesicEvidenceBundle`
- `Enums.lean`, `Individuals.lean`, `Pipeline.lean` — Supporting ontology infrastructure

UOR provides the **type‑theoretic foundation** for the entire Multiplicity knowledge representation layer. It is referenced by:
- `verification-sdk` Rust crate (WASM verification SDK)
- `archivum` Rust crate (immutable witness ledger)
- `sigma` Rust crate (serialization layer)
- `models/` directory (agent model implementations)

Currently, UOR exists as a standalone Lean package without:
- Integration into `Prime/lean/Core/` as a base ontology
- ADR ratification of its production role
- Formal proof that the primitive type family is complete and consistent
- CI enforcement that all generated structures compile and pass tests

Without formal integration into `Core/`, the UOR ontology risks:
- **Type drift**: Different modules may define incompatible versions of `String`, `Integer`, etc.
- **Incomplete primitives**: The XSD primitive family may lack types required by downstream consumers.
- **Structural inconsistency**: Generated structures (`Certificate`, `BornRuleVerification`, etc.) may diverge from their Rust counterparts.

## Decision
We will integrate UOR Primitives as a **foundational Core ontology** with the following mandates:

### 1. Core Integration
- Move `UOR/Primitives.lean` into `Prime/lean/Core/UOR.lean` as the canonical base module for primitive types.
- All other Lean modules requiring primitive types must import `Core.UOR`.
- The `Standard` instance (`String := String`, `Integer := Int`, etc.) becomes the **global primitive mapping**.

### 2. Formal Proof Expansion
- Extend `Core/UOR.lean` with proofs:
  - `primitive_types_complete`: The six XSD primitives cover all required base types.
  - `standard_instance_sound`: `UOR.Prims.Standard` satisfies all `Primitives` class axioms.
  - `certificate_well_formed`: Every `Certificate` structure is well‑typed under `Standard`.

### 3. Rust Engine Parity
- The `Prime/crates/verification-sdk/`, `Prime/crates/archivum/`, and `Prime/crates/sigma/` crates must use types compatible with `Core.UOR.Primitives`.
- Implement serialization tests proving Rust ↔ Lean type correspondence.

### 4. CI/CD and Triple‑Lock Integration
- CI must run `lake build` on `Prime/lean/Core/` and `lake test` on `Prime/lean/UOR/` on every PR.
- The **Guardian** lock must verify UOR type compliance before approving knowledge graph mutations.
- The **Examiner** lock must audit `Certificate` structures for completeness.
- The **Publisher** lock must sign UOR configurations into `Archivum`.

## Consequences
### Positive
- **Type‑Theoretic Foundation**: UOR Primitives become the single source of truth for all base types in the Multiplicity stack.
- **Knowledge Graph Consistency**: All `Certificate`, `BornRuleVerification`, and `GeodesicEvidenceBundle` structures are guaranteed well‑typed.
- **Rust Interop**: The `Standard` instance maps directly to Rust types, enabling zero‑drift serialization.
- **Audit‑Ready Ontology**: Every UOR type usage emits a witness to `Archivum`.

### Negative
- **Import Restructuring**: Moving UOR into `Core/` requires updating imports across all dependent modules.
- **Primitive Limitation**: The six XSD primitives may be insufficient for advanced mathematical types (e.g., complex numbers, matrices); extensions require ADR ratification.
- **Generated Code Sync**: The `Structures.lean` file is auto‑generated; manual edits must be synchronized with the `uor-lean` generator.

## Implementation Steps
1. **Refactor `UOR/Primitives.lean` into `Core/UOR.lean`.
2. **Prove primitive completeness** and `Standard` soundness in `Core/UOR.lean`.
3. **Update all imports** in dependent modules.
4. **Implement Rust serialization tests** proving type correspondence.
5. **Wire Triple‑Lock integration**: Guardian → type compliance → Examiner → `UORCertificateWitness` → Publisher → `Archivum`.
6. **Update CI** to enforce `lake build` + `lake test`.
7. **Emit Archivum witness** `UORTypeProof` on every type registration.

## References
- `Prime/lean/UOR/Primitives.lean` — Source module
- `Prime/lean/UOR/Structures.lean` — Generated structures
- `Prime/crates/verification-sdk/` — WASM verification SDK
- `Prime/crates/archivum/` — Immutable witness ledger
- `Prime/crates/sigma/` — Serialization layer
- [ADR-067 (Archivum)](../adr/ADR-067-Archivum.md) — Immutable ledger production deploymentble ledger production deployment
