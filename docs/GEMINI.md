# Project Mandates: Multiplicity Sovereign Core

## 1. The Sedona Spine Mandate
The **Sedona Spine** (Rust Engine + WASM SDK) is the **sole mandatory source of truth** for all ESI retention, litigation hold, and spoliation risk logic.

### Governance Rules:
- **Zero Drift:** No agent, UI component, or backend service may independently calculate preservation risk levels or retention durations. 
- **Path of Integrity:** All ESI-related decisions MUST route through the path: `Engine (Rust)` → `CompilationResult` → `UnifiedWitness` → `Ledger Anchor` → `UI/Agent`.
- **Axiom-Clean Core:** All recursive stability proofs must be anchored to the canonical Lean 4 `MOC/Core.lean` (found in `lean/`) and satisfy the axiom-clean mandate (No Mathlib, No Sorry).
- **Structural Segregation:**
    - `lean/`: Canonical, axiom-clean lawful core.
    - `lean/legacy/`: Exploratory/theatrical modules dependent on Mathlib (Non-binding, non-production).

## 2. Agent Operational Integrity
- All AI-generated work product touching ESI must satisfy the provenance chain: **Policy** → **Event Log** → **Kernel Computation** → **UnifiedWitness** → **Narrative**.
- Every preservation alert must adhere to the `[PRESERVATION ALERT]` protocol defined in `CONTRACT.md`.

## 3. PIRTM-lang Roadmap (Governance-as-Compilation)
PIRTM-lang formalizes legal governance into a programmable language.
- **Phase A (Grammar):** Enforce the **Prime Successor Predicate** via `tree-sitter`.
- **Phase B (Type System):** Implement the `Sig` library (Multiplicity Functor) in `crates/pirtm-compiler`. (Ratified)
- **Phase C (Constraint Verification):** Implement ACE invariant and budget checks. (Ratified)
- **Phase D (Recovery):** Formalize the **UnifiedWitness** and Dual-Signature Protocol for re-certification. (Ratified)
- **Production Pipeline:** Enforce mandatory witness-to-ledger anchoring in CI. (Ratified)

## 4. Reference Artifacts
- **Engine Core:** `models/legalese-scopist/`
- **PIRTM Substrate:** `pirtm-website/GEMINI.md`
- **Agent Contract:** `models/legalese-scopist/CONTRACT.md`
- **Counsel Guide:** `models/legalese-scopist/GUIDE.md`
- **Matter Playbooks:** `models/legalese-scopist/PLAYBOOK-*.md`

<!-- LawfulRecursionVersion:1.0 -->
