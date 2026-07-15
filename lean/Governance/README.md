# Phase Mirror: Multiplicity Substrate

The Multiplicity Substrate is a high-performance, formally verified execution environment for contractive tensor dynamics, governed by the Ξ-Constitution.

## Architecture
The substrate consists of a unified, type-safe Rust core organized into a layered architecture:

- **L0 Execution**: `pirtm-rs` (recursive tensor engine), `arithmetic-kernel` (Goldilocks field), `operators-rs`.
- **L1 Governance**: `zeta-rs` (conflict resolution), `hcalc-rs` (state classification), `security-rs` (audit logs/CAS), `phase-mirror-rs` (L0 invariants).
- **L2 Stability**: `resonance-rs` (stability certification), `csl-rs` (runtime gating).
- **L3 Dynamics**: `zrsd-rs` (spectral dynamics), `alp-rs` (atomic language processing), `moonshine-rs` (formal validation engine).
- **ZK Layer**: `ace-zk-rs` (Plonky3/AIR constraints).

## Governance & Compliance
The system is anchored to the **Ξ-Constitution** (see `Ξ-Constitution.md`).
- **Mechanized Enforcement**: Governance states are materialized in `agiOS/state/`, providing filesystem-anchored lawfulness.
- **Verification**: The `PREP-2026` conformance standard provides a machine-executable compliance path.
- **Reproducibility**: System integrity is verifiable via the `prep-conform` binary, which generates auditable evidence bundles.

## Documentation
- **ADRs**: Found in `docs/adr/`.
- **Invariants**: Defined in `specs/`.
- **Conformance**: Detailed in `packages/pirtm-rs/CONFORMANCE_KIT.md`.

## Quickstart
1. Ensure Rust (1.78+) and Python (for harnesses) are installed.
2. Build the substrate: `cd packages && cargo build --release`
3. Run conformance checks: `cd packages/pirtm-rs && cargo run --bin prep_conform -- --out-dir ./evidence --json`
