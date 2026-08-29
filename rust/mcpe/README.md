# MCPE — Formal Verification Framework

Production-grade Rust framework for verifying perception, robotics and intelligent machines protocols with bit-precision using Kani.

## Architecture

```
MCPE/
├── rust/
│   ├── Cargo.toml          -- Package manifest with Kani dependency
│   ├── src/
│   │   ├── lib.rs          -- Library root, module declarations
│   │   ├── main.rs         -- CLI entry point
│   │   ├── error.rs        -- Error types and recovery strategies
│   │   ├── numeric.rs      -- Fixed-point and UInt256 types
│   │   ├── state.rs        -- State vectors and transitions
│   │   ├── protocol.rs     -- Messages, sessions, invariants
│   │   ├── codec.rs        -- Serialization with round-trip proofs
│   │   └── kani_proofs.rs  -- Kani formal verification proofs
│   ├── tests/
│   │   └── integration.rs  -- Integration tests
│   └── README.md
├── docs/
│   ├── templateArxiv.tex
│   └── templatePRIME.tex
├── formalization.lean      -- Lean 4 placeholder (optional)
├── lakefile.lean           -- Lean 4 placeholder (optional)
└── README.md               -- Project root README
```

## Build

```bash
# Build library and CLI
cd rust
cargo build
cargo test

# Run Kani formal verification proofs
cd rust
cargo kani -- kani_proofs.rs
```

## Verification Strategy

| Layer | Tool | Scope |
|-------|------|-------|
| Unit tests | `cargo test` | Functional correctness |
| Proofs | `cargo kani` | Bit-precision, memory safety, protocol invariants |
| Fuzzing | `cargo fuzz` (optional) | Property-based stress testing |

## Key Concepts

| Concept | Description |
|---------|-------------|
| **FixedPoint** | Qm.n fixed-point arithmetic with overflow checking |
| **UInt256** | 256-bit unsigned integers for cryptographic operations |
| **StateVector** | Typed state vectors with dimension invariants |
| **Transition** | Verified state machine transitions (linear, repair) |
| **Session** | Protocol session lifecycle with state machine |
| **Message** | Wire protocol messages with verified serialization |

## Status

- **Build**: `cargo build` succeeds
- **Tests**: `cargo test` passes (11/11 integration tests)
- **Kani**: Bit-precise proofs in `src/kani_proofs.rs`
- **No mathlib dependency**: Verification via Rust/Kani only

## Usage

```rust
use mcpe::{StateVector, StateId, RepairTransition, Session, Message};

// Create a state vector
let id = StateId::new(1);
let state = StateVector::from_array(id, [100, -100, 0]);

// Apply a repair transition
let transition = RepairTransition::new(-10, -50, 50);
let next = transition.apply(&state).unwrap();

// Verify protocol session
let mut session = Session::new(42);
session.activate(99).unwrap();
let msg = Message::new(MessageType::Data, 42, 0, vec![]);
session.process_message(&msg).unwrap();
```
