# ADR-041: MOC Integration into Phase Mirror Oracle

## Status
Proposed

## Owner
[Governance]

## Horizon
7 Days

## Context
The core verified mathematical substrate (Lean 4 MOC + Ξ-Constitution L0 invariants) currently exists in isolation. It delivers axiom-clean contraction dynamics and prime-gated identity under the Sedona Spine mandate (no `sorry`, no Mathlib). However, it must be integrated into deployable Phase Mirror artifacts (AI Agent UI, MCP tools, SaaS Oracle, defensive publications). Formal verification satisfies sovereignty claims but needs to produce consumable governance signals for the dissonance engine.

## Decision
We will expose the L0 invariant verification via an MCP interface `validate_l0_invariants` and enforce strict fail-closed behavior if the spectral drift $\delta_c$ exceeds $\epsilon$.

The MOC verifier will emit machine-checkable contraction certificates (incorporating prime decomposition and spectral radius) that the Phase Mirror dissonance engine can directly consume without human interpretation.

## L0 Binding Points
- `validate_l0_invariants` MCP tool: Acts as the unified gateway for checking system drift and prime gates.
- `DissonanceAgentOrchestrator`: Consumes the output (prime decomposition, spectral radius bound, ethical drift $\delta_c$) and translates it into typed `Tension` / `Lever` signals.
- `MOC Core` \(\rightarrow\) `WASM Binding`: Core Rust engine outputs serialized JSON certificates consumed by TS agent layers.

## Metrics
- Signed ADR committed.
- L0 checks wired to `analyze_dissonance`.
- 100% green PR builds in the CI matrix (Lean, Rust, Python Harness).
