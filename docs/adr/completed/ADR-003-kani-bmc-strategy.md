---
status: completed
date: 2026-07-21
decision-maker: PhaseMirror Team
---

# ADR-003: Kani BMC Strategy

## Context

Bounded model checking is needed to verify Rust implementation properties that cannot be checked by the type system alone.

## Decision

Use Kani with the following bounds:
- **MAX_TERMS = 32**: maximum number of term nodes
- **MAX_QUBITS = 4**: maximum number of qubits

Seven verification harnesses:
1. `verify_composition_preserved`: composition axioms are respected
2. `verify_congruence_closure`: equivalence classes are closed
3. `verify_termination`: completion algorithm terminates
4. `verify_associator_bounded`: associator defect is non-negative
5. `verify_blockade_enforced`: Rydberg blockade prevents unlawful compositions
6. `verify_union_find_no_panic`: Union-Find operations don't panic
7. `verify_no_index_out_of_bounds`: array indices are within bounds

## Consequences

- Provides bit-precise verification of core algorithms
- No runtime overhead in production (Kani code is behind #[cfg(kani)])
- Limits apply to verification only; production can use dynamic sizes
