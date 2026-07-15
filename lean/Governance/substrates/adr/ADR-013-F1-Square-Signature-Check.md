# ADR-013: F1 Square Signature Check on T1 Truncation

## Status
Proposed

## Context
The strategic analysis of the current $F_1$ state space reveals that local analytic methods are insufficient to resolve global geometric pairing constraints. To bridge this gap, we must convert the core geometric problem into a computable artifact. 

The $T_1$ truncation, comprising a finite set of primes $P = \{p_1, \dots, p_n\}$, allows for the construction of a distinguished divisor lattice. The previous 10-dimensional model is refined into a more expressive $(3n+1)$-dimensional basis.

## Decision
We will implement a signature check on the conjectured intersection form of the $F_1$-square using a multi-prime basis $\{H_i, V_i, \Delta, \Gamma_i\}_{i=1 \dots n}$ in Lean. This implementation targets the **full-space $(1, \rho-1)$ signature**, where $\rho = 3n+1$. This aligns with the standard Hodge Index Theorem for surfaces, where the restriction to the orthogonal complement of an ample class is negative-definite.

### Implementation Details
1.  **Lattice Basis:** 
    - Horizontal rulings: $H_i$ for each prime $p_i$.
    - Vertical rulings: $V_i$ for each prime $p_i$.
    - The diagonal: $\Delta$.
    - Scaling graphs: $\Gamma_i$ for each prime $p_i$.
2.  **Intersection Relations:**
    - $\langle H_i, H_j \rangle = 0, \langle V_i, V_j \rangle = 0$.
    - $\langle H_i, V_j \rangle = \delta_{ij}$.
    - $\langle H_i, \Delta \rangle = 1, \langle V_i, \Delta \rangle = 1$.
    - $\langle \Delta, \Delta \rangle = d$ (self-intersection parameter).
    - $\Gamma_i$ intersections derived from the explicit formula trace parameters.
3.  **Signature Theorem:** The full $(3n+1)$-dimensional space is verified to have signature $(1, 3n)$ via a symbolic basis construction $\{E_i, F, G_i, K_i\}$ and the trace condition.
4.  **Hodge Index Corollary:** Derive the negative-definiteness on $H^\perp$ (signature $(0, 3n)$) assuming $H^2 > 0$ for an ample class $H$.
5.  **Substrate Integrity:** The implementation is located in `F1Square/IntersectionTemplate.lean` and relies exclusively on `UOR.Bridge.F1Square.Analysis` primitives.

## Consequences
- **Architectural Alignment:** Directly implements the Hodge-Lefschetz signature pattern, providing the necessary global constraints for the arithmetic site.
- **Verification Artifact:** Produces a formal symbolic proof and a concrete instantiation for any finite prime set truncation.
- **Analytic Resolution:** Formally resolves the "crowding" of spectral invariants as a corollary of the global geometric pairing.

## Verification
- Successful elaboration of the `full_space_signature` theorem in `IntersectionTemplate.lean`.
- Successful instantiation and test validation for the $T_1$ truncation in `tests/SignatureCheckTest.lean`.
- Manual audit of intersection relations against sourced analytic properties of the $F_1$-square.

<!-- LawfulRecursionVersion:1.0 -->
