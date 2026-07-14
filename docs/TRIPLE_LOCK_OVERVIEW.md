# Triple‑Lock Overview

This document provides a concise, pragmatic guide to the **Triple‑Lock** verification pipeline used by the Phase Mirror project.

## 1️⃣ Axiomatic Core (Lean 4)
- **SemanticArithmetic** defines the `Ξ(t)` operator and proves `semantic_trace_unique` – every integer’s prime factorisation yields a unique, immutable atomic trace.
- The Lean source lives under `models/legalese-scopist/` and is built with `lake build && lake test`.
- **No `mathlib` dependencies** – the core is axiom‑clean and suitable for compilation to WASM.

## 2️⃣ Bounded Model Checking (Kani)
- Rust implementation (`materia_commons/`) mirrors the Lean model via a JSON bridge (`basis_factors.json`).
- The `kani` feature flag enables Kani proofs (`cargo kani --all-features`).
- Proven properties include:
  - No overflow in valuation matrix construction.
  - Correctness of the resolvent trace identity.

## 3️⃣ High‑Performance Runtime (Rust / nalgebra)
- Fast spectral‑density computation using LU decomposition (`src/spectral_resolvent.rs`).
- Generates a static `VALS` array (`src/generated_vals_array.rs`).
- Compiles to WASM for deployment (`cargo +nightly build --release --target wasm32-unknown-unknown`).

---
### How to run the full verification locally
```bash
# 1. Lean core
cd /home/multiplicity/Multiplicity/PhaseMirror/Prime
lake build && lake test

# 2. Generate Rust data
cd materia_commons
python3 generate_rust_vals.py

# 3. Kani checks (requires nightly Rust + Kani binary)
cargo kani --all-features

# 4. Run Rust test suite (includes example)
cargo test --all

# 5. Build WASM artifact
cargo +nightly build --release --target wasm32-unknown-unknown
```

You can also invoke the convenience wrapper:
```bash
scripts/verify.sh
```
---
### CI Pipeline (GitHub Actions)
The workflow defined in `.github/workflows/ci.yml` executes the same steps automatically on every push/PR, guaranteeing end‑to‑end integrity.

---
**When adding new mathematical components**:
1. Extend the Lean model and re‑run `lake test`.
2. Export the updated JSON via `export_basis.py`.
3. Regenerate the Rust static array (`generate_rust_vals.py`).
4. Add or update Kani proofs in `src/proofs.rs`.
5. Verify locally, then push – CI will catch any regression.
