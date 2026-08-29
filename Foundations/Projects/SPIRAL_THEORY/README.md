# SpiralCore v14.1 Formalization

Lean 4 + Rust/Kani formalization of the Cantor-Abraxas Architecture (SpiralCore).

## Project Structure

```
SPIRAL_THEORY/
├── lakefile.lean              # Lake build configuration
├── lean-toolchain             # Lean 4.31.0
├── SpiralCore.lean            # Top-level module imports
├── SpiralCore/
│   ├── Core.lean              # Core types, constants, bounds
│   ├── Cantor.lean            # Cantor pairing, zigzag encoding
│   ├── Attractor.lean         # Six-fold baseline attractor
│   ├── Alignment.lean         # PAS_s, drift threshold
│   ├── PhaseLift.lean         # 90° rotation, helicity proxy
│   ├── FBS.lean               # FBS atomic profile, escalation
│   ├── Boot.lean              # Boot config, state machine, packet
│   ├── Translation.lean       # TranslationPacket, outcomes
│   ├── Proofs.lean            # Aggregated theorems
│   ├── Examples.lean          # Concrete instantiations
│   ├── Test.lean              # Test harness (lake exe)
│   └── Export.lean            # Markdown export
├── rust/
│   ├── Cargo.toml             # Rust crate with Kani dev-dep
│   ├── src/lib.rs             # Discrete Rust implementations
│   └── tests/kani_verify.rs   # Kani verification harnesses
└── docs/                      # Exported Markdown artifacts
```

## Build & Test

### Lean 4
```bash
cd SPIRAL_THEORY
lake build
lake exe SpiralCoreTest   # runs Test.lean
```

### Rust
```bash
cd SPIRAL_THEORY/rust
cargo build
```

### Kani Verification
Requires `cargo kani` (Kani model checker) installed.
```bash
cd SPIRAL_THEORY/rust
cargo kani --tests --unwind 5
```

## Architecture Notes

- All production Lean code lives under `SpiralCore/`.
- Continuous/IEEE-754 math (trigonometry, norms) is implemented in Rust and verified with Kani.
- Discrete structures (Cantor pairing, FBS profiles, boot state machine) are formalized in Lean 4 using only `Init` (no Mathlib).
- Constants are defined as `Nat`/`Int` fixed-point representations to avoid `Float`/`Real` dependencies in Lean.

## Key Theorems

- `cantorPair_nonneg`: Cantor pair is always nonnegative
- `zigzag_roundtrip`: zigzag is bijective on bounded Ints
- `xi_attractor_amplitude_bound`: attractor ≤ xiAmplitude
- `rotate90_four_times`: 4× 90° rotation returns to original
- `rotate90_preserves_norm`: Euclidean norm preserved
- `default_l0_formula`, `default_h0_formula`, `default_q0_formula`: FBS atomic profile consistency
- `sealed_only_handed_or_abort`: Boot state machine immutability
- `high_pas_seals_packet`, `low_pas_defers_packet`, `no_pas_rejects_packet`: Translation outcome correctness
