---
status: completed
date: 2026-07-21
decision-maker: PhaseMirror Team
---

# ADR-004: Lean-Rust FFI Bridge

## Context

The Lean 4 formal core and Rust implementation must share verified types and theorems.

## Decision

Use `@[extern]` annotations in Lean and trait-based bindings in Rust:
- Lean exports: `lean_uc_compose`, `lean_uc_closure`, `lean_defect_mu`
- Rust imports: `LeanFfi` trait with matching signatures
- Bridge type: `LeanCarrierBridge` for type conversion

## Consequences

- Enables end-to-end verification from Lean proofs to Rust execution
- FFI boundary is the only trusted component
- All other code is verified by Lean (theorems) or Kani (implementation)
