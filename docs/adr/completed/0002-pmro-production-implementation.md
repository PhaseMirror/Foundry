# ADR-PMRO-002: Production-Grade Implementation of Prime-Multiplicity Recursive Operators (PMRO)

## Status
Proposed

## Date
April 26, 2026

## Context
The defensive publication `Prime-Multiplicity_Recursive_Operator.tex` establishes a formal framework for PMROs. The core theorem dictates that global contraction is guaranteed when $F + c < 1$, where $F = \sup_t \|\Xi(t)\|_{\mathrm{op}}$ is the operator norm and $c = \sup_t |m(t)| L_T$ is the coupling constant. Initial baseline implementations using generic basis mixing (Fourier, Permutation, Random) failed this condition ($F = 1.253$). Optimization via signed weights in Fourier-conjugated prime operators successfully reduced $F$ to $0.500$, achieving the strict contraction regime ($F + c = 0.510 < 1$). 

We now require a production-grade implementation that incorporates this optimization step natively, enabling reliable operation within the Multiplicity Sovereign Core at scale ($d_t \ge 1000$). 

## Decision
We will implement the PMRO framework natively in Rust as a core module (`pirtm-tensor` / `core`), structured around the following constraints:

1. **Operator-Norm Objective Optimization Engine:** 
   - Implement an SLSQP-equivalent iterative solver in Rust (or leverage `ndarray` with a port of `scipy.optimize.minimize`) that actively optimizes the weight vector $\mathbf{w}$ to minimize $F = \|\Xi(t)\|_{\mathrm{op}}$.
   - Ensure the solver adheres to the bounds: $\|\mathbf{w}\|_2^2 \le 5$ (bounded magnitude) and $\|\mathbf{w}\|_2 \ge 0.5$ (non-trivial evolution).
2. **Fourier-Conjugated Prime Operators:** 
   - Adopt Fourier-conjugated operators ($U_p = F^* D_p F$) with signed weights as the default basis, as proven by the empirical optimization results.
3. **Real-Part Projection:** 
   - Enforce the required construction step $\Xi(t) = \operatorname{Re}(\sum_p w_p U_p)$ firmly at the tensor layer before evaluating the non-linear coupling.
4. **Sparse Block Structure:** 
   - Transition from direct spectral norm computation ($O(d^3)$) to sparse representation and Power Iteration methodologies for operator norm approximation to support $d_t > 100$.

## Consequences
- **Positive:** System guarantees global contraction for prime-indexed evolutions, sealing the empirical observations into a stable Rust pipeline.
- **Positive:** Aligns seamlessly with the established `ContractiveFit` optimization engine used in the UAC Simulator.
- **Negative/Risk:** The optimization step adds runtime computational overhead; power iteration must be strictly bounded. 
- **Risk:** Verifying $F+c<1$ analytically over dynamically changing weights $w_p(t)$ will require dynamic invariant checks at runtime.
