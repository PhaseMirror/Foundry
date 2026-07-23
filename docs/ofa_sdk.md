# Operator-First Arithmetic SDK (OFA-SDK v0.3.0)

## Overview
The **OFA-SDK** provides the Rust and WebAssembly (WASM) implementation of **Operator-First Arithmetic (OFA-ii)**, a foundational paradigm within Multiplicity Theory. Rather than treating numbers as primitive static sets (e.g., von Neumann ordinals), OFA-ii constructs natural numbers as operational iterates ($\Phi^n$) of lawful endomorphisms. 

This SDK ensures that numerical state evolution across client shells, TypeScript layers, and backend runtimes complies with the **Sedona Spine** zero-drift contract.

---

## Architecture & Core Abstractions

1. **`Operator` Trait**
   Defines the basic executable transformation interface, requiring strict adherence to state transformation and admissibility checking.
2. **`EndomorphismRule`**
   Encapsulates rule identification, step increments, and contractive bounding (enforcing norm bounds $c < 1$ to prevent energy inflation).
3. **`OFANumeral`**
   Exposed via WASM bindings to enable UI and scripting runtimes to perform safe, authenticated incremental operations backed by immutable fusion hashes.

---

## Quickstart & Usage

### Rust Core Usage
```rust
use pirtm_engine::ofa::{EndomorphismRule, OFANumeral};

// Initialize an endomorphism rule with a contractive norm bound
let rule = EndomorphismRule::new(String::from("zeta_scale_op"), 1, 0.4);

// Create a base numeral with a cryptographic fusion provenance tag
let numeral = OFANumeral::new(0, String::from("0x_genesis_lattice"));

// Evolve the numeral via iteration
let evolved = numeral.iterate(5);
assert_eq!(evolved.get_value(), 5);
```

### TypeScript / WASM Integration
```javascript
import { executeOFAIteration } from 'ofa_sdk.js';

// Execute a bounded invariant iteration from the frontend UI
const executionResult = executeOFAIteration(0, 5, "0x_lattice_hash");

if (executionResult.status === "PASS") {
    console.log(`OFA Iteration successful. New value: ${executionResult.resultValue}`);
}
```

---

## Compliance & CI Verification Gate

Under the **Sedona Spine Mandate**, all preservation‑risk and invariant computations are locked to the Rust/WASM engine. The CI pipeline executes `scripts/validate_zero_drift.sh` on every pull request to verify:

* Clean compilation of Lean 4 initial algebra proofs (`OperatorFirstArithmetic.lean`).
* Byte‑exact parity and test execution in the Rust test suite (`ofa_integration.rs`).
* Absence of numerical or structural drift across state transitions.

```
```

---

*This file is part of the official PhaseMirror‑Prime documentation suite.*
