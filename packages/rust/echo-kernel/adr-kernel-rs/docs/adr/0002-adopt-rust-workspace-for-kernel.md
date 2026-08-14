# 0002. Adopt Rust workspace for kernel

Date: 2026-05-24

## Status
Accepted

## Context
The kernel requires a stable core library, a thin operational CLI, and automatable repository tasks.

## Decision
Use a Cargo workspace with three crates: `kernel-core`, `kernel-cli`, and `xtask`.

## Consequences
Compile boundaries stay clean.
Testing and release automation scale without mixing orchestration code into the core crate.
