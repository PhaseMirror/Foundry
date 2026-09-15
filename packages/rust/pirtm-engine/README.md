# pirtm-engine

PIRTM **Arithmetic Control Engine (ACE)** — the ADR-0066 production
implementation of the PrismPM ↔ PIRTM interoperability veto gate.

Implements, in dependency-light, standalone Rust:

| ADR-0066 requirement | Module |
| --- | --- |
| Prime-indexed tensor overlay + 2×2 `GainMatrix`, spectral radius ρ(Ψ) | `tensor` |
| `SIG_GOV_KILL` veto: `ρ(Ψ) ≥ 1−ε` ⇒ kill (fail-closed, even on valid semantics) | `ace` |
| Fixed-point `Λ_m` governance over CRMF envelopes | `ace` |
| `UnsignedCrmfEnvelope` byte-exact canonical BCS packing (`bcs`-crate compatible) | `canonical` |
| `EnsembleManifest` + `.holo` compile veto (Add→2 / Multiply→3 overlay) | `manifest` |
| Poseidon2-shaped sponge (`t=9, r=8`) → 256-bit `crmf_validity_seal` | `poseidon2` |
| Phase D: gap payload, dual Ed25519 authorization, 9-step ACE gate | `recovery` |

## Build & test

```console
cd packages/rust/pirtm-engine
cargo build
cargo test          # invariants + intentional failure cases + property sweep
cargo kani          # bounded-model-checking harnesses under tests/
```

Kani requires the `kani` Rust verifier. On Nix/elan setups the repository's
stub proc-macro (`../kani`) satisfies `cargo check`; `cargo kani` substitutes
the real verifier per the repository convention.

## Guarantees enforced by the harnesses

1. **The veto** (`tests/prism_interop_harness.rs`): a semantically valid model
   is vetoed when the adversarial gain matrix `[[1, .5], [.5, 1]]` (ρ = 1.5)
   breaches the contractivity bound.
2. **BCS injectivity** (`tests/prism_interop_bcs_harness.rs`):
   `bcs::to_bytes(a) == bcs::to_bytes(b)` iff `a == b`, and likewise for the
   canonical wire format; both round-trip losslessly.
3. **Fail-closed halting**: `metrics.lambda_m ≥ CONTRACTIVITY_SCALE` (Λ_m ≥ 1.0)
   is always rejected by the governance gate — proved symbolically by Kani.
4. **Phase D** (`tests/phase_d_recovery_test.rs`): the 9-step ACE resumption
   gate releases L0_HALT only under dual, non-self-dealing authorization with
   chain continuity, epoch freshness, and window bounds.

## Deliberate seams

- The `poseidon2` permutation is a byte-stable M61 backend; the BN254
  arkworks substitution point is documented at the module seam.
- The float→fixed-point radius conversion happens at the telemetry boundary
  (`ace::radius_scaled`); every gate downstream is integer-only.