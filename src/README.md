# Prime / Source (src)

This directory houses the core Rust implementation of the Phase Mirror engine and the Multiplicity Sovereign framework.

## Overview

While the formal proofs and axioms live in `lean/`, the actual execution engine, policy gates, and WASM bindings live here in `src/`. The Rust engine acts as the operational counterpart to the Lean formalizations, ensuring that the theoretically sound rules are strictly enforced at runtime.

### Key Modules

- **Core Operations:** `lib.rs`, `main.rs`, `orchestrator.rs`, `prime_recursive.rs`
- **Policy & Governance:** `gate.rs`, `csl.rs` (Conscious Sovereignty Layer), `audit.rs`, `certify.rs`, `prime_move_audit_macro.rs`
- **Interfaces & Bindings:** `wasm_api.rs` (WASM interface), `lambda_bridge.rs`, `zm_binding.rs`
- **Data Structures & Telemetry:** `types.rs`, `serialization.rs`, `telemetry.rs`
- **Math & Logic:** `spectral.rs`, `pmat.rs`, `csc.rs`

All components in this directory strictly adhere to the **Sedona Spine** mandate: the Rust engine is the sole source of truth for execution logic. Policy bypass is cryptographically prohibited, and every state mutation must be witnessed.
