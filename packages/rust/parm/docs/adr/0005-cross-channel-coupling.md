# ADR 0005: Cross-Channel Coupling Architecture

## Status
Accepted

## Context
The PARM engine operates on independent, orthogonal channels representing invariant properties of a symbol sequence: Shape ($\pi_s$), Numeric ($\pi_n$), and Phonetic ($\pi_p$). However, linguistic properties in classical semantics are often viewed synesthetically—where visual structure and numeric identity operate in synthesis, not merely in parallel. We needed a rigorous mathematical representation to compute this synchronous interaction.

## Decision
We implemented a **Cross-Channel Coupling** function within the PARM engine. 
Instead of calculating Resonance Quotients ($RQ$) for channels independently and then combining them (like the geometric mean $C = \sqrt{RQ_s \cdot RQ_n}$), the coupling occurs *within the recurrence relation itself*.

The coupled generator weight $w_i$ for a given position $i$ is the point-wise product of its respective channel primes:
$w_i = p_{s,i} \times p_{n,i}$

The Seed, Flow, and Seal recurrence is then evaluated over these synthetic composite weights:
- $V_1 = w_1^2$
- $V_i = w_i(V_{i-1} + w_i)$
- $V_N = w_N^2(V_{N-1} + w_N)$

Because the atoms being permuted are the symbols themselves, their channel properties ($p_s, p_n$) remain bound together during the permutation normalization space. The $O(N \log N)$ Extremal Heuristic continues to apply mathematically to the composite weights $w_i$.

## Consequences
- **True Synesthetic Metric**: Yields $RQ_{coupled}$, representing the resonance of the combined structural-numeric entity.
- **Factorial Bypass Preserved**: The extremal logic holds because the properties permute synchronously, making length constraints non-existent.
- **Architectural Flexibility**: This pattern can be generalized to couple any arbitrary number of channels (e.g., Shape + Numeric + Phonetic) via $w_i = p_{s,i} \times p_{n,i} \times p_{p,i}$.
