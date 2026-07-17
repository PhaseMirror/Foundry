# ADR-003: WASM SDK for the Path of Integrity

## Status
**Proposed**

## Context
In **ADR-002**, we established the Sedona Spine (Rust Kernel) as the sole mandatory source of truth for the system's legal and physical state. However, the system's UI layer is written in TypeScript (e.g., React, Next.js), and the intelligent agent layer often operates in Python or Node.js environments.

We must bridge the gap between the Rust Kernel and the higher-level applications securely. Re-implementing the core logic in TypeScript or Python would immediately reintroduce the risk of architectural drift, violating the core mandate. A secure, mathematically sound, and zero-drift communication channel must be established.

## Decision
We will expose the Rust Engine's logic by compiling it into a **WebAssembly (WASM) SDK**.

1. **Strict Path of Integrity:** The full data pipeline must follow: `Rust Engine → WASM SDK → CONTRACT.md Definitions → UI/Agent Consumption`.
2. **Read-Only Interfaces:** The WASM SDK will act primarily as a read-only projection of the engine's state. It will expose pure functions that query the state (e.g., `get_preservation_risk(matter_id)`), guaranteeing that mutations only happen within the certified Rust environment via explicit event logs.
3. **Universal Deployment:** Compiling to WASM ensures that both the browser-based client UI and the Node.js/Python agent runtimes can load the exact same compiled binary logic.
4. **Agent Contract:** Agents interact with the WASM interface following the strict format defined in `CONTRACT.md` (e.g., `[PRESERVATION ALERT]`).

## Formal Proof Obligations

To maintain the rigorous standards of Multiplicity Social Physics, we must prove that the WASM projection does not introduce logical deviations from the Rust source of truth.

### 1. Functional Isomorphism
We must guarantee that querying the state via the WASM SDK yields the exact same logical result as querying the native Rust Kernel directly.

**Lean 4 Formalization Sketch:**
```lean
import ADR.Core
import ADR.SedonaSpine

namespace ADR.WasmSDK

/-- Represents the native query execution in the Rust Engine -/
def nativeQuery (state : EngineState) (query : QueryParams) : QueryResult :=
  -- internal engine query resolution
  sorry

/-- Represents the WASM boundary projection -/
def wasmQuery (state : EngineState) (query : QueryParams) : QueryResult :=
  -- WASM serialization and execution path
  sorry

/-- Theorem: The WASM SDK is perfectly isomorphic to the native engine for read-only queries -/
@[proof]
theorem wasm_isomorphism (s : EngineState) (q : QueryParams) : 
  wasmQuery s q = nativeQuery s q := by
  -- Proof by exhaustion that the serialization/deserialization boundary 
  -- preserves the exact structural integrity of the output.
  -- Demonstrates that the WASM SDK is a faithful projection.
  sorry
```

## Consequences

### Positive
- **Guaranteed Consistency**: Eliminates "duplicate logic" bugs. If the Rust Engine calculates a `Critical` risk, the TS frontend and the LLM agent using the WASM SDK will identically see `Critical`.
- **High Performance**: WebAssembly executes at near-native speeds, ensuring complex ecological and social-physics calculations (e.g., MQEM prime-indexed recursion) do not bottleneck UI rendering.
- **Portability**: The same compiled SDK serves the browser, the server, and the agent runtime environments.

### Negative
- **Build Complexity**: Introduces a multi-language build pipeline (`cargo` -> `wasm-pack` -> `npm`).
- **Debugging Opacity**: Debugging cross-boundary issues between TypeScript and the WASM binary can be difficult compared to debugging native TS.
- **Serialization Overhead**: Complex nested structs must be serialized across the WASM boundary, which requires careful type mapping (e.g., using `serde-wasm-bindgen`).

## Implementation Steps
1. Configure `Cargo.toml` to support the `cdylib` crate type for the Sedona Spine.
2. Introduce `wasm-bindgen` annotations to the `src/engine.rs` module's public structs and pure query functions.
3. Use `wasm-pack build --target web` for the browser UI and `--target nodejs` for the agent environment.
4. Write integration tests that assert parity between a native Rust test execution and the output from the compiled WASM module running in a headless JS environment.
5. Formalize the serialization/deserialization isomorphism proof in Lean 4 to statically guarantee boundary integrity.
