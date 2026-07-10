# Agent Development Guidelines: Apex-Goldilocks

This document provides foundational mandates for all AI agents (Task, Explore, and Plan agents) working on the Apex-Goldilocks workspace. It enforces the Sedona Spine mandate and ensures mathematical coherence across the entire stack.

## 1. THE GOLDEN RULE: MATHEMATICAL INTEGRITY (NO FLOATS)

**ABSOLUTELY FORBIDDEN: Direct usage of floating-point types (`f32`, `f64`) in L0 core crates.**

The Goldilocks Zone is a strictly exact mathematical environment. All kernel computations, invariants, and structural proofs must utilize exact arithmetic.

### Absolute Prohibitions
1. **NO `f32`/`f64` in `crates/`**: Core logic must use `GoldilocksField` (prime field arithmetic) or `Rational` (Ratio<i128>).
2. **NO floating-point heuristics**: All stability and contractivity checks must be certified via exact rational bounds.
3. **NO implicit rounding**: Precision loss is equivalent to spoliation.

### Acceptable Floating-Point Usage
Floating-point types are permitted **ONLY** in:
- **UI/Display Layers**: Rendering the `Stability Dashboard` or human-readable logs.
- **WASM Interop**: Converting exact results to floats for JavaScript consumption at the final boundary.
- **Heuristic Audits**: MUB drift detection (e.g., `mub_audit.rs`) where spectral energy is monitored as a statistical heuristic.

---

## 2. OPERATIONAL INTEGRITY: NO PLACEHOLDERS

**NEVER LEAVE PLACEHOLDERS, TODOs, OR INCOMPLETE IMPLEMENTATIONS.**

### Mandatory Requirements
1. **Complete Implementations**: If you define a trait or function, implement it fully. No `todo!()` or `unimplemented!()`.
2. **Deterministic Certification**: Every transformation (e.g., in `apex-pikernel`) must generate a machine-checkable certificate (SlopeUB, GapLB).
3. **Traceable Provenance**: Code must reflect the provenance chain: **Policy → Event Log → Kernel Computation → Narrative**.

---

## 3. PERFORMANCE-FIRST DESIGN (O(1) & ZERO-COPY)

Apex-Goldilocks is optimized for low-latency updates in high-dimensional state spaces.

1. **O(1) Resolution**: Prefer hash-based or indexed lookups (e.g., `PhiAddress`) over linear scans.
2. **Zero-Copy Views**: Utilize `ndarray` views and slices to prevent unnecessary allocations.
3. **Parallel Lane Arithmetic**: Design for carry-free computation using the `RNS` (Residue Number System) module.

---

## 4. WORKSPACE CONVENTIONS

### Crate Hierarchy
- `crates/`: Standalone, internalized core logic (The "Spine").
- `packages/`: Domain-specific integrations and managed extensions.
- `src/`: Tauri/React frontend (The "Narrative").

### Validation Mandate
Before marking a task as complete, you MUST execute:
```bash
bash scripts/validate_stack.sh
```
This script enforces the zero-float policy, runs workspace tests, and performs a combinatorial audit of the 12,288-cell complex.

---

**Remember: Incomplete work is a spoliation risk. Meet or exceed the computational purpose of the legacy stack in the new exact architecture.**
