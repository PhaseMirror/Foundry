# Project Mandates: PhaseMirror-Legal

## 1. The Sedona Spine Mandate
The **Sedona Spine** (Rust Engine + WASM SDK) is the **sole mandatory source of truth** for all ESI retention, litigation hold, and spoliation risk logic.

### Governance Rules:
- **Zero Drift:** No agent, UI component, or backend service may independently calculate preservation risk levels or retention durations. 
- **Path of Integrity:** All ESI-related decisions MUST route through the path: `Engine (Rust)` → `SDK (TS/WASM)` → `Contract (CONTRACT.md)` → `UI/Agent`.
- **Transformation Only:** Agents are permitted only to *transform* engine-computed facts into legal narratives and motion skeletons. They are strictly forbidden from overriding or re-interpreting engine risk levels (`Critical`, `High`, `Medium`).
- **Policy-Driven Variation:** All domain-specific legal variation must live in declarative YAML policies (e.g., `templates/*.yaml`), not in hardcoded logic.

## 2. Agent Operational Integrity
- All AI-generated work product touching ESI must satisfy the provenance chain: **Policy** → **Event Log** → **Kernel Computation** → **Narrative**.
- Every preservation alert must adhere to the `[PRESERVATION ALERT]` protocol defined in `CONTRACT.md`.

## 3. Reference Artifacts
- **Engine Core:** `models/legalese-scopist/`
- **Agent Contract:** `models/legalese-scopist/CONTRACT.md`
- **Counsel Guide:** `models/legalese-scopist/GUIDE.md`
- **Matter Playbooks:** `models/legalese-scopist/PLAYBOOK-*.md`
