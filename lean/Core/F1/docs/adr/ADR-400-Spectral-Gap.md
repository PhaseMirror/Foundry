# ADR-400: Spectral Gap — Scope Clarification for F₁-Square

## Status
**Accepted** — 2026-06-24

## Context
The F₁-Square scaffold operates on a fundamental distinction between **algebraic negativity** (proven) and **analytic bridge to zeros** (open). This ADR clarifies the spectral gap that separates the proven finite-N Arakelov negativity from any RH implication.

## Decision
Scope the deliverables explicitly:

### Deliverable A: Algebraic Negativity (Proven, Constructive)
- The finite-N Arakelov pairing matrix `diag(-log p_i)` on Δ^⊥ is negative-definite
- For any finite set of primes with ∑ v_i = 0, the pairing `v² = -∑ log(p_i) v_i² < 0`
- This is a straightforward linear-algebra fact, proven in `ArakelovHodge.lean`
- The archimedean rank-one term vanishes on Δ^⊥ when normalized by degree

### Deliverable B: Analytic Bridge (Open)
The passage from algebraic negativity to the critical line requires three unproven steps:

1. **Spectral Identification**: The discrete object Θ on the F₁-square has eigenvalues `log p`, not `p`. Therefore:
   - `Tr(Θ^{-s}) = Σ (log p)^{-s}` (prime-log zeta)
   - This does NOT equal `ζ(s) = Σ p^{-s}`
   - The switch `(log p)^{-s} → p^{-s}` is the spectral gap

2. **Regularized Determinant**: Even if eigenvalues were `log p`, the determinant identity:
   - `det(I - Θ^{-s}) = Π (1 - p^{-s})^{-1} · Γ(s)`
   - requires unpublished regularization procedures
   - The Gamma factor `Γ(s)` is asserted, not derived from the geometry

3. **Lefschetz Trace Bridge**: Connecting the intersection pairing to the explicit formula requires:
   - A Lefschetz trace formula relating cup-product to ζ zeros
   - The signed Möbius refinement must produce the von Mangoldt weights
   - This bridge is not established; see `weil_coupling_sign_from_template` as the conditional

## Consequences
- `hodgeIndexHolds = none` remains the honest status
- `F1Square_implies_RH` stays conditional on surface axioms
- ADR-400 serves as the governing boundary: algebraic negativity is **proven**, RH bridge is **open**
- Defensive publication must scope claims to finite-N algebraic negativity + framework

## References
- ADR-100 (F1-Square Conditional Proof Scaffold)
- ADR-103 (T3 Intersection Harness)
- ADR-104 (Weil Explicit Formula Docking)
- `F1Square/ArakelovHodge.lean` (finite negativity)
- `F1Square/WeilBridge.lean` (conditional coupling)