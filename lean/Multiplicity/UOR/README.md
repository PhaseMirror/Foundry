# Universal Object Reference (UOR)

This directory contains the formal Lean 4 model for the **Universal Object Reference (UOR)** framework.

## Overview

UOR provides a cryptographically rigorous, absolute addressing scheme for the Multiplicity Sovereign Core. It establishes:
- **Canonical Identity:** Abstract types, values, and theorems are mapped to verifiable hash identities.
- **Cross-Boundary Stability:** Ensures that a state transition or proof structure in Lean strictly matches its counterpart in Rust or WebAssembly.
- **Foundational Roots:** Directly integrates with `PWEH` and `PIRTM` validation layers, serving as the topological anchor for all governance certificates.

## Sedona Spine Compliance

UOR structures form the bedrock of the Archivum Ledger. By ensuring that every object in the system (from a policy evaluation context to a resonance trace) has a fixed, canonical reference, UOR makes the "Zero Drift" requirement of the Sedona Spine mathematically provable. Any divergence in execution between the Rust engine and the Lean formalization is immediately caught as a UOR hash mismatch.
