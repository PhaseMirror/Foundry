# ZRSD Specification

## Purpose
`zrsd` (Zero-Resonance Signal Dynamics) provides the mathematical models and differential operator matrices used by the PhaseSpace OS to evaluate and govern resonance constraints across system simulations.

## Core Components
1. **Multiplicity Operator**: Evaluates constraints by projecting high-dimensional matrices through defined null-spaces.
2. **ZRSD Evaluator**: Computes step-wise evaluations of dynamic systems to detect resonance anomalies before they are instantiated.
3. **Euler Steps Integrator**: Core mathematical building block utilizing `nalgebra` structures to compute matrix derivatives and states.

## Invariants
- All integrations must be deterministically reproducible under the fixed precision of `f64`.
- The Multiplicity Operator must properly classify singular anomalies and bounded constraints correctly.
- Must remain structurally decoupled from external untrusted inputs, pulling numerical signals exclusively from governed data pipelines.
