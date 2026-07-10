# ADR: Constitutional Governance Implementation

## 1. Executive Summary
This ADR defines how the theoretical mandates outlined in `Ξ-Constitution.md` map to tangible policy enforcement within the Sedona Spine stack.

## 2. Policy Enforcement Scope
- The Constitutional rules implemented in the `crates/governance/` and `crates/alp/` modules apply to the entirety of the system's decision-making loop.
- **Triple-Lock Verification:** Decisions made by agentic protocols are cross-examined against both the `mirror-dissonance` engine and the Constitutional core.

## 3. Acceptance Criteria
- Any transaction explicitly violating the defined articles in `Ξ-Constitution.md` must be rejected by the governance pipeline.
- Witness entries generated for rejections must accurately reference the violated Constitutional article.
