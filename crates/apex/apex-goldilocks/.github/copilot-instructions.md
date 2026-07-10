# Copilot Development Guide for Hologramapp

This document provides guidelines for AI-assisted development (specifically Copilot) when working on the hologramapp project. It ensures consistency, quality, and adherence to project standards.

**⚠️ For Claude-specific instructions, see [CLAUDE.md](../CLAUDE.md) at the repository root.**

## Project Vision: General Compute Acceleration

**🎯 PRIMARY GOAL: High-performance compute through canonical form compilation**

Hologramapp provides general compute acceleration by compiling operations to their canonical forms. This enables:

- **Canonical Compilation** - Operations compiled to optimal geometric representation
- **Pattern-Based Canonicalization** - Canonicalization reduces operations to minimal form
- **Lowest Latency** - Canonical forms enable fastest possible execution
- **Universal Compute** - General-purpose acceleration, not domain-specific

### Key Architectural Principles

1. **Canonical Form Compilation**: All operations reduced to canonical geometric representation
2. **Pattern-Based Canonicalization**: Rewriting (H²=I, X²=I, etc.) minimizes operation count
3. **Generator-Based Execution**: 7 fundamental generators (mark, copy, swap, merge, split, quote, evaluate)
4. **Performance through Simplification**: Fewer operations = lower latency

## Current Architecture

### Active Crates

- **hologram-compiler** - Canonical circuit compilation engine
- **hologram-core** - High-level operations library
- **hologram-ffi** - UniFFI cross-language bindings
- **hologram-tracing** - Performance instrumentation
- **atlas-core** - Foundational geometric primitives

### Execution Flow

```
Application Code
    ↓ calls
Hologram Core Operations (ops::math, ops::reduce, etc.)
    ↓ compiles via
Canonical Compilation (pattern rewriting)
    ↓ produces
Canonical Generator Sequence (minimal operation count)
    ↓ executes as
Optimized Kernel (lowest latency)
```

## Core Principle: Test-Driven Development

**🚨 CRITICAL: No feature is complete without comprehensive tests.**

Every piece of code written must include:

1. **Unit tests** for individual functions and methods
2. **Integration tests** for component interactions
3. **Property-based tests** (using `proptest`) for mathematical invariants
4. **Documentation tests** in doc comments

### Test Coverage Requirements

- **Minimum 80% code coverage** for all crates
- **100% coverage** for canonicalization rules and generator compilation
- **All public APIs** must have examples in doc comments that serve as tests
- **All error paths** must be tested
- **Canonicalization correctness** tests for all rewrite rules

## Development Workflow

### 1. Before Writing Code

1. **Understand the requirement** fully
2. **Review existing architecture** and patterns
3. **Write test cases first** (TDD approach)
4. **Design the API** (function signatures, types, traits)

### 2. Writing Code

1. **Implement incrementally** - small, testable chunks
2. **Run tests frequently** - `cargo test` after each change
3. **Document as you go** - doc comments with examples
4. **Follow Rust idioms** and best practices

### 3. After Writing Code

1. **Run full test suite**: `cargo test --workspace`
2. **Run clippy**: `cargo clippy --workspace -- -D warnings`
3. **Check formatting**: `cargo fmt --check`
4. **Verify documentation**: `cargo doc --no-deps --workspace`
5. **Update integration tests** if APIs changed

## Documentation Standards

### Documentation Organization

**All `.md` documentation files should be stored in the `docs/` directory**, with two exceptions:

- `README.md` - Project overview at repository root
- `CLAUDE.md` - Development guide at repository root

Examples of files that belong in `docs/`:

- Architecture documentation
- Implementation guides
- API references
- Tutorial and how-to guides
- Design documents

See [CLAUDE.md](../CLAUDE.md) for complete development standards, code organization, testing patterns, and architectural details.

## Quick Reference

### Running Tests

```bash
# All tests
cargo test --workspace

# Specific crate
cargo test -p hologram-compiler
cargo test -p hologram-core
cargo test -p hologram-ffi
```

### Linting and Formatting

```bash
# Format code
cargo fmt --all

# Check formatting
cargo fmt --all --check

# Clippy with strict warnings
cargo clippy --workspace --all-targets -- -D warnings
```

### Building

```bash
# Debug build
cargo build --workspace

# Release build
cargo build --workspace --release
```

## Key APIs

### Hologram Core Operations

```rust
use hologram_core::{Executor, ops};

let exec = Executor::new()?;
let mut a = exec.allocate::<f32>(1024)?;
let mut b = exec.allocate::<f32>(1024)?;
let mut c = exec.allocate::<f32>(1024)?;

// Fill with data
a.copy_from_slice(&exec, &data_a)?;
b.copy_from_slice(&exec, &data_b)?;

// Execute operation
ops::math::vector_add(&exec, &a, &b, &mut c, 1024)?;

// Get results
let results = c.to_vec(&exec)?;
```

### Circuit Compilation

```rust
use hologram_compiler::CircuitCompiler;

// Compile circuit to canonical form
let compiled = CircuitCompiler::compile("copy@c05 . mark@c21")?;

// Compiled result contains:
// - canonical: Canonical circuit string
// - calls: Vec<GeneratorCall> - minimal generator sequence
// - stats: Reduction statistics
```

## Resources

- **[CLAUDE.md](../CLAUDE.md)** - Complete development guide
- **[Canonical Compilation Guide](../docs/CANONICAL_COMPILATION_GUIDE.md)** - Canonical form compilation
- **[Implementation Review](../docs/IMPLEMENTATION_REVIEW.md)** - Technical details
- **Crate READMEs**:
  - [hologram-compiler/README.md](../crates/hologram-compiler/README.md)
  - [hologram-core/README.md](../crates/hologram-core/README.md)
  - [hologram-tracing/README.md](../crates/hologram-tracing/README.md)

---

**Remember: Write production-ready code with comprehensive tests. No shortcuts.**
