## 001 – Sedona Spine Mandate

**Status**: Accepted

**Context**:
The PhaseMirror‑Legal project requires a single source of truth for all ESI retention and litigation‑hold logic. The Rust engine + WASM SDK (Sedona Spine) provides this authority.

**Decision**:
All preservation risk calculations and retention durations MUST be performed exclusively by the Sedona Spine engine, routed through the Rust → TS/WASM → CONTRACT.md → UI chain.

**Consequences**:
- Guarantees zero drift across UI and backend.
- Agents only transform engine facts; they cannot override risk levels.
- Policy variations must be encoded in YAML, not hard‑coded logic.

**References**:
- `models/legalese-scopist/CONTRACT.md`
- User global rule "Sedona Spine Mandate".
