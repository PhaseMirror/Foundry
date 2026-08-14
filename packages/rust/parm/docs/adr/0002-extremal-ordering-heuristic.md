# ADR 0002: Extremal Ordering Heuristic Optimization

## Status
Accepted

## Context
As defined in ADR 0001, calculating the Resonance Quotient ($RQ$) required mapping the entire permutation space of a symbol multiset to find $V_{\min}$ and $V_{\max}$. This $O(N!)$ factorial complexity became an absolute bottleneck, preventing the analysis of longer words, phrases, or verses, and significantly slowing down corpus-scale ingestion. *(Reference: `docs/The Formal Theorem Statement.md`)*

## Decision
We adopted the **Extremal Ordering Theorem**, replacing brute-force combinatorial generation with algebraic heuristics derived from the $V_N$ sequence expansion. The exact algebraic mapping relies on the fact that only the outer terms ($p_1$ and $p_N$) are squared in the final expression. 

The $O(N \log N)$ heuristic logic is defined as:
- **$V_{\max}$**: Sort primes in descending order, then move the absolute largest prime to the final position (`Descending-Largest-Last`).
- **$V_{\min}$**: Sort primes in ascending order, then move the absolute smallest prime to the final position (`Ascending-Smallest-Last`).

## Consequences
- **Elimination of Factorial Bound**: Sequences of arbitrary length can now be processed instantly.
- **Empirical Success**: Validation across 8,000 randomized multisets ($N=3..6$) and 6,242 biblical Hebrew roots yielded 100% accuracy.
- **Architecture Simplification**: The engine defaults to this heuristic approach but retains the exact $O(N!)$ permutation generation via an `exact_fallback` toggle for regression testing.
