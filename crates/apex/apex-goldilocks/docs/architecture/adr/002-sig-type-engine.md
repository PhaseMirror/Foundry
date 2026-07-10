# ADR 102: Sig Type Engine and Multiplicity Conservation

## Status
Accepted

## Context
The PIRTM compiler must verify stability invariants at the type level.

## Decision
We implement a `Sig` struct using `HashMap<u64, i32>` to encode tensor signatures as prime-factorizations. The `multiplicity_functor` (M) calculates the exact rational multiplicity. All tensor operations (contraction, product) are validated against Multiplicity Conservation: $M(S_{new}) = M(Ap) \cdot M(S_{old})$.

## Consequences
- **Pros**: Ensures exact mathematical correctness via rational arithmetic; eliminates floating-point drift (Sedona Spine "No Floats" mandate).
- **Cons**: Requires explicit handling of tensor indices.
- **Sedona Spine Alignment**: Satisfies the governance requirement that all ESI-related decisions are routed through the kernel computation path.
