# Lean ↔ Rust FFI Bridge (lean-rs-host)

Integration skeleton for the Lean ↔ Rust bridge using [`lean-rs-host`](https://github.com/jcreinhold/lean-rs).

## Architecture

```
┌──────────────────────┐      @[export]       ┌──────────────────────┐
│  lean/FFI/Bridge.lean│ ───────────────────► │   crates/lean-ffi    │
│  (Lean 4)            │   typed FFI symbols   │   (Rust)             │
│                      │ ◄─────────────────── │                      │
│  aceBound,            │   lean-rs-host call  │  FFIBridge::new()    │
│  cycle108 cert, ...   │                       │  ace_bound()         │
└──────────────────────┘                       │  verify_proof()      │
       ▲                                        └──────────┬───────────┘
       │                                                     │ depends on
       │                                        ┌────────────▼───────────┐
       │                                        │   crates/lean-sdk      │
       │                                        │   (pure Rust, no FFI)  │
       │                                        │   ACE_BOUND, verify_   │
       │                                        │   certificate, IRWord  │
       │                                        └───────────────────────┘
```

## lean-rs-host API surface used

| Rust type / method | Role |
|---|---|
| `LeanRuntime::init()` | Brings the Lean runtime up (process-once, idempotent). |
| `LeanHost::from_lake_project(runtime, &lake_root)` | Opens the `lean/` Lake project as a capability anchor. |
| `host.load_capabilities("Prime", "FFI")` | Loads the `FFI` shared library built by Lake. |
| `caps.session(&["FFI"], None, None)?` | Opens a fresh `LeanSession` for one unit of work. |
| `session.exported::<Args, Ret>("symbol")?` | Typed lookup of an `@[export]` Lean symbol. |
| `export.call(args)?` | Calls the Lean export with first-class type marshalling. |
| `host.load_shims_only()?` | Shortcut when only scalar reads are needed (no user code path). |
| `LeanElabOptions` | Elaboration options for `session.elaborate(...)`. |

## Build integration

### Build script (`crates/lean-ffi/build.rs`)

```rust
fn main() -> Result<(), Box<dyn std::error::Error>> {
    lean_toolchain::CargoLeanCapability::new("lean", "FFI")
        .package("Prime")
        .module("FFI")
        .build()?;
    Ok(())
}
```

This invokes `lake build FFI:shared` and emits `cargo:rustc-link-*` directives
so the compiled `.so` / `.dylib` is found at link time.

### Lake configuration (`lean/lakefile.lean`)

```lean
lean_lib FFI where
  srcDir := "FFI"
  defaultFacets := #[LeanLib.sharedFacet]
```

The `defaultFacets := #[LeanLib.sharedFacet]` line is what causes Lake to
build the `FFI` library as a shared dylib — the exact artifact `lean-rs-host`
needs to `dlopen`.

### Workspace wiring (`Cargo.toml`)

```toml
[workspace]
members = [
    ...
    "crates/lean-sdk",
    "crates/lean-ffi",   # ← new
]

[workspace.dependencies]
lean-rs = "0.4"
lean-rs-host = "0.2"
lean-toolchain = "0.4"
```

## Exported Lean symbols

All live in `lean/FFI/Bridge.lean` inside the `FFI` namespace and are
annotated `@[export ...]` so `lean-rs-host` can discover them.

| Lean export name | Lean type | Rust call signature | Description |
|---|---|---|---|
| `lean_ace_bound` | `Float` | `FFIBridge::ace_bound() -> f64` | ACE bound for dim-108 cycle (0.6). |
| `lean_cycle108_admissible` | `Prop` | `FFIBridge::cycle108_admissible() -> bool` | True iff cycle108 is ACE-stable. |
| `lean_cycle108_dimension` | `Nat` | `FFIBridge::cycle108_dimension() -> u64` | Dimension = 108. |
| `lean_cycle108_lambda_eff` | `Float` | `FFIBridge::cycle108_lambda_eff() -> f64` | Effective Lipschitz constant. |
| `lean_uc_compose_opt` | `UC X → X → X → Option X` | session call | Partial universal closure compose. |
| `lean_uc_closure_opt` | `UC X → X → Option X` | session call | Partial universal closure close. |
| `lean_defect_mu` | `HasDefect U → X → Nat` | session call | Defect measure at point x. |

## Example usage

```rust
use lean_ffi::FFIBridge;

fn main() -> anyhow::Result<()> {
    // Open the Lean runtime and load the FFI capability.
    let bridge = FFIBridge::new()?;

    // Read a verified constant.
    let ace_bound = bridge.ace_bound()?;
    println!("ACE_BOUND = {}", ace_bound);

    // Read the dimension.
    let dim = bridge.cycle108_dimension()?;
    println!("cycle108 dimension = {}", dim);

    // Verify the proof certificate round-trips through Rust.
    let valid = bridge.verify_cycle108_proof()?;
    assert!(valid, "Lean-proved certificate failed Rust re-verification");

    Ok(())
}
```

## Proof-certificate preservation

The critical invariant is that a theorem proved in Lean can be consumed by
Rust **without loss of proof evidence**.

1. **Lean proves** `cycle108_admissible : Prop` (theorem in `Bridge.lean`).
2. **Lean exports** the verified constants: `aceBound` (0.6), `dimension` (108),
   `lambda_eff`, and the admissibility `Prop`.
3. **Rust reads** those constants through `lean-rs-host` typed FFI.
4. **Rust generates** the canonical 108-cycle certificate bytes via
   `lean_sdk::generate_canonical_word()`.
5. **Rust re-verifies** using `lean_sdk::verify_certificate`, which checks:
   - Hecke recurrence `a_{p^{r+2}} = a_p * a_{p^{r+1}} - p^11 * a_{p^r}`
   - Deligne bound `a_p^2 ≤ 4 * p^11`
   - Effective Lipschitz constant `λ_eff ≤ ACE_BOUND`
6. **Rust cross-checks** that the computed `λ_eff` matches the Lean-exported
   `cycle108_lambda_eff`, confirming the Lean proof and Rust verification
   describe the same mathematical object.

## Building

```bash
# Build the Lean FFI shared library
cd lean && lake build FFI:shared

# Build the Rust side (triggers build.rs → lake build FFI:shared)
cd crates/lean-ffi && cargo build

# Run integration tests
cargo test -p lean-ffi
```

## Prerequisites

- **Lean 4.32.0-rc1** (or any 4.27.0–4.33.0-rc1 as per lean-rs-host version matrix)
- **Lake** (shipped with Lean)
- **Rust 1.70+**
