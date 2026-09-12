# Sigma Kernel

> **PiKernel Successor.** Sigma is the Rust successor to the Python PiKernel experimental substrate. All PiKernel primitives — contraction certificates (GapLB, SlopeUB), ACE safety projection, PETC ledgering, Lean-verified thresholds, and spectral dissonance checks — are reified as machine-checked Rust types in this crate.

## PiKernel Lineage Map

| PiKernel Concept | Sigma Rust Primitive | Location |
| :--- | :--- | :--- |
| Contraction certificates (GapLB=0.225, SlopeUB=0.775) | `Thresholds.contractivity_margin`, `Thresholds.l_eff_max` | `src/generated/thresholds.rs`, `src/lib.rs` |
| ACE safety projection | `PolicyEngine::run` + `sigma_check` invariant | `src/lib.rs:80-88`, `src/lib.rs:330-355` |
| PETC ledger | `WitnessLedger`, `TransitionBlock` | re-exported from `archivum` |
| Lean-verified bounds (Rpi ≤ 7, λ₁ > 0, atlas=(10,14)) | `Thresholds` validation in `build.rs` + `validate()` | `src/lib.rs:37-63`, `build.rs` |
| Spectral dissonance levels (Safe/Warning/Critical) | `DissonanceLevel` enum + `sigma_check` | `src/lib.rs:311-355` |
| Prime-indexed attention | `StateTransition.r_sc` resonance functional | `src/lib.rs:13-17` |
| Dissonance trap logging | `log_dissonance_trap!` macro | `src/logging.rs` |

## Architecture

```
SigmaKernel
  ├── PolicyEngine        — evaluates StateTransition against Thresholds
  ├── WitnessLedger       — PETC ledger (archivum)
  └── Thresholds          — Lean-verified bounds (postcard/bincode/JSON)
```

### Invariants (Lean-verified)
- `rpi_upper ≤ 7`
- `lambda1_positive == true`
- `atlas_signature == (10, 14)`
- `0 < contractivity_margin < 1`
- `0 < l_eff_max < 10`
- `0 < tau_r < 100`

### Dissonance Check
```rust
let witness = sigma_check(&spectral_state, thresholds.tau_r)?;
// invariant_holds = l_eff < 1.0 && drift <= tau_r
// dissonance_level = Critical if l_eff >= 1.0 || drift > tau_r
```

## Integration with Helix

Sigma's `Thresholds` and `sigma_check` are the canonical contractivity enforcement layer consumed by:
- `helix/knot-in-time` — knot Hamiltonian + FZS-MK physics engine
- `helix/Multiplicity/core` — constitutional runtime + policy compiler
- `helix/Multiplicity/kernel` — memory kernel + Zeno-Ward projector

## Build
```bash
cargo build -p sigma
cargo test -p sigma
cargo build -p sigma --features lean-gen   # regenerate thresholds from Lean
```
