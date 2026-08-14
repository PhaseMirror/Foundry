# drmm_ir_parser

Production-grade Rust parser, validator, and canonical serializer for the **DRMM IR v1.0** format.

## Features

- **Parse**: Deserialize IR documents from JSON strings or files.
- **Validate**: Enforce version constraints, identifier patterns, tensor shape invariants, and iteration semantics.
- **Canonicalize**: Produce deterministic, sorted JSON output suitable for hashing.
- **Hash**: Compute SHA-256 hashes of canonical IR documents.
- **CLI**: Ready-to-use binary with `validate`, `canonical`, `hash`, and `ast` subcommands.

## Quick Start

```bash
# Validate an IR file
cargo run -- validate tests/valid/identity.json

# Canonicalize
cargo run -- canonical tests/valid/identity.json

# Hash
cargo run -- hash tests/valid/identity.json

# Run tests
cargo test
```

## Library Usage

```rust
use drmm_ir_parser::{parse_ir_file, validate_ir, canonical_hash};

let doc = parse_ir_file("my_model.ir.json")?;
let hash = canonical_hash(&doc)?;
println!("Canonical hash: {}", hash);
```

## Error Types

All library functions return `drmm_ir_parser::Result<T>` where the error type is a `thiserror`-derived enum covering:

- IO failures
- JSON deserialization failures
- Validation failures (version mismatch, invalid IDs, shape mismatches, etc.)

## File Layout

```
crates/drmm_ir_parser/
├── Cargo.toml
├── README.md
├── src/
│   ├── lib.rs
│   ├── ast.rs
│   ├── error.rs
│   ├── parser.rs
│   ├── canonical.rs
│   ├── cli.rs
│   └── main.rs
├── tests/
│   ├── parser_tests.rs
│   ├── valid/
│   │   └── identity.json
│   └── invalid/
│       ├── missing_version.json
│       └── bad_id.json
└── examples/
    └── simple_iterate.json
```

## License

MIT
