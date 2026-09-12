# AL-GFT Derive

Schwinger-Keldysh derivation engine for the Gaussian AL-GFT, emitting `W1_AXIOM`
witnesses at each step.

## Crate layout

- `src/steps.rs` — five built-in Rust-native derivation steps
- `src/python_bridge.rs` — bridge to SymPy scripts for symbolic algebra
- `python/` — SymPy scripts (requires `sympy` installed in the Python environment)
- `src/bin/pipeline.rs` — binary that runs the pipeline and emits `derivation_ledger.json`

## Build

```bash
cargo build -p al-gft-derive
```

## Run (Rust-native steps only)

```bash
cargo run -p al-gft-derive --bin al-gft-pipeline
```

## Run with Python SymPy steps

```bash
PYTHON_EXE=python3 cargo run -p al-gft-derive --bin al-gft-pipeline
```

## Witness format

Each step emits a `DerivationWitness`:

```json
{
  "step_id": "step1_action",
  "step_name": "Action Specification",
  "expression_tree": { ... },
  "assumptions": ["gaussian_field", "linear_coupling"],
  "transformation_rules": ["canonical_form"],
  "symbolic_hash": "<sha256>",
  "w1_axiom": "W1_AXIOM_<sha256>",
  "timestamp": 1234567890
}
```

The composite `C_TOTAL` is the SHA-256 over all concatenated `W1_AXIOM` hashes.

## Integration with existing governance

Use `steps::integration::extend_witness` to combine derivation witnesses with the
existing `generate_multi_level_witness` output from `models/legalese-scopist`:

```rust
let legacy = generate_multi_level_witness(c_lambda, ops, fidelity, status);
let derived = pipeline.run(derivation_steps);
let extended = al_gft_derive::steps::integration::extend_witness(legacy, &derived);
```
