Here is the formal Architecture Decision Record (ADR) codifying the locked epistemic boundary for NIST OSCAL integration, drafted as an optional, read-only export and packaging format.

---

# ADR-OSCAL-EXPORT: NIST OSCAL as Optional Read-Only Export Packaging Format

* **Status:** Proposed


* **Scope:** Governance, Compliance Packaging, and Export Pipelines


* **Supersedes:** None

## Context

Enterprise compliance frameworks (such as NIST SP 800-53, the NIST AI RMF, SOC, and HIPAA) require standardized machine-readable structures for reporting and auditing. NIST OSCAL provides an established schema syntax (Catalogs, Profiles, System Security Plans, Assessment Results, and POA&Ms) to modernize risk management.

However, a critical architectural tension exists: NIST OSCAL is a document model and syntax, not a cryptographic proof layer or a runtime enforcement engine. Wrapping human or script-based assertions inside an OSCAL JSON/YAML schema does not imbue them with Lean 4 formal proofs, Kani bounded checks, or cryptographic validity seals. Treating OSCAL fields as runtime attestation primitives creates a false join and reintroduces an honor system.

## Decision

1. **Strictly Packaging-Only Role:** NIST OSCAL is formally categorized as an **optional, read-only export and packaging format**. It shall serve solely as a narrative envelope for audit packets.


2. **Semantic Labeling & Pointers:** OSCAL Profiles, Catalogs, and System Security Plans (SSPs) may be used for IntentClass Registry (ICR) taxonomy mapping and as structural narrative pointers to repository paths, proposed ADR IDs, and CI execution logs.


3. **Mandatory `UNATTESTED` Marking:** Any Assessment Result (SAR) or compliance report generated via OSCAL export must explicitly mark its evidence as **`UNATTESTED`** wherever there is no verifiable, hashed R1CS compiler manifest or Lean proof hash backing the claim.


4. **Prohibition of Cryptographic Fakes:** No cryptographic seals (such as Poseidon2 digests, CRMF validity seals, or on-chain attestation hashes) may be embedded inside OSCAL property fields or data models. Compliance vocabulary is expressly forbidden from standing in for an unbuilt or unverified compiler.


5. **Glossary Alignment:** Architectural compliance layers must maintain strict homonym locks—specifically recognizing **Adaptive Constraint Enforcement (ACE)** and the **Constitutional / Cryptographic Record Management Framework (CRMF)** as the sole mathematical and runtime enforcement rail.



## Consequences

* **Positive:** Enables standardized, machine-readable regulatory traceability (e.g., NIST AI RMF and EU AI Act bindings) without corrupting or bypassing the L0 mathematical substrate.


* **Positive:** Enforces fail-closed organizational transparency by explicitly flagging unverified narrative claims as `UNATTESTED`.


* **Negative:** Requires strict discipline across documentation and compliance tooling to ensure that export formats are never misinterpreted as machine-checked proof objects.

## Links & Artifact References

* Epistemic Boundary Policy: Locked via Phase 0 review.
* Underlying Execution Rail: Sedona Spine & Adaptive Constraint Enforcement (ACE).