# ADR 0001: PARM Core Mathematical Architecture

## Status
Accepted

## Context
The PARM project requires a rigorous, mathematically stable framework for analyzing sequence-dependent meaning in Hebrew roots (and other symbolic systems). Early iterations relied on ad-hoc numeric comparisons. We needed a model that guarantees unique factorization (traceability) and order-sensitivity without producing unbounded exponential explosions, while yielding a normalized score for cross-root comparison. *(Reference: `docs/Geometric Language Processing.md`)*

## Decision
We implemented a **prime-indexed, position-aware recursive multiplicity (PARM)** engine with the following properties:
1. **Prime Generators ($\pi$)**: Each symbol is mapped to a distinct prime (e.g., $\pi_s$ for shape, $\pi_n$ for small gematria).
2. **Tri-phasic Recurrence**:
   - **Seed**: $V_1 = p_1^2$
   - **Flow**: $V_i = p_i(V_{i-1} + p_i)$ for $1 < i < N$
   - **Seal**: $V_N = p_N^2(V_{N-1} + p_N)$
3. **Resonance Quotient (RQ)**: Actual sealed state $V_{\text{actual}}$ is normalized against its multiset permutation space: $RQ = \frac{V_{\text{actual}} - V_{\min}}{V_{\max} - V_{\min}}$.

## Consequences
- **Traceability**: Primes guarantee unique factorization at every step (proven via lemma).
- **Polynomial Bound**: The use of a quadratic seal operator restricts sequence growth to polynomial bounds, specifically $O(p_{\max}^{N+2})$, preventing memory overflow.
- **Complexity Trade-off**: The RQ denominator relies on permutation space ($O(N!)$), which strictly limits computation to short sequences (e.g., triliteral roots, $N \le 6$) without mathematical bypasses.
- **Semantic Mapping**: Yields predictable 0 to 1 Phase bands correlated with semantic domains (e.g., $RQ \approx 1.0$ mapping to "wholeness/peace").
