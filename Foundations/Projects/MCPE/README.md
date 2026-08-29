# MCPE — Formal Verification Framework

Production-grade Rust framework for verifying perception, robotics and intelligent machines protocols with bit-precision using Kani.

## Structure

```
MCPE/
├── rust/                    -- Production Rust implementation
│   ├── Cargo.toml
│   ├── src/
│   │   ├── lib.rs
│   │   ├── main.rs
│   │   ├── error.rs
│   │   ├── numeric.rs
│   │   ├── state.rs
│   │   ├── protocol.rs
│   │   ├── codec.rs
│   │   └── kani_proofs.rs
│   ├── tests/
│   │   └── integration.rs
│   └── README.md
├── docs/                    -- LaTeX paper templates
│   ├── templateArxiv.tex
│   └── templatePRIME.tex
├── formalization.lean       -- Lean 4 placeholder
└── lakefile.lean            -- Lean 4 placeholder
```

## Quick Start

```bash
cd rust
cargo build
cargo test
cargo kani -- kani_proofs.rs
```

## Documentation

See `rust/README.md` for full API documentation and usage guide.
