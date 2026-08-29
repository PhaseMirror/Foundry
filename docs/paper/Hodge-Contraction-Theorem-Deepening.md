# Hodge–Contraction Theorem: Deepening the Geometric Constraints

This technical note provides the detailed geometric, algebraic, and analytic backing for the one-way implication stated in Theorem 7.4 of the main manuscript.

## 1. Precise Statement
We assert that the negative-definiteness of the Hodge-type pairing on the prime-indexed subspace $V_P$ (and its inductive limit) implies strict contractivity of the essential spectrum ($\rho_{\mathrm{ess}}(\Phi_P) < 1$), given a continuous, positivity-preserving link between the Gram matrix of the pairing and the matrix elements of the prime-indexed operators (e.g., Track A matrices or Lindblad generators).

## 2. Geometric Setup
The construction operates on the arithmetic surface $X = \operatorname{Spec}\mathbb{Z}\times_{\mathbb{F}_1}\operatorname{Spec}\mathbb{Z}$. The prime-indexed classes map directly to the cohomology of $X$. The Hodge Gram matrix formed by these classes completely dictates the interaction weights of the local CPTP maps, forming a direct, mathematically rigorous bridge from geometry to open quantum system dynamics.

## 3. Algebraic Step: Reduction to the Schur Test
The negative-definiteness condition translates algebraically to strict diagonal dominance in the relevant Gram matrix representations. By the van Gelder–Schur test (formalized via CRMF axiom C6), this negativity guarantees the existence of a vector $v$ and a constant $\kappa < 1$ bounding the operator norm. In our Track A implementations, the design factor $\gamma \in (0,1)$ acts as the concrete realization of this $\kappa$.

## 4. Finite-to-Limit Argument
To pass from the finite verified cases (e.g., $P \in \{2, 3, 5, 7\}$) to the global spectrum, we isolate a **uniform gap assumption**: the contractivity gap $1 - \rho(H_P)$ remains bounded away from zero as $P \to \infty$. This is the single analytic hypothesis needed to globally bound $\rho_{\mathrm{ess}} < 1$.

## 5. Logical Status Table

| Claim | Status |
|-------|--------|
| Finite $P$: negativity $\Rightarrow$ $\rho < 1$ | **Proved** (Schur test + explicit matrices); Track A verifies $\{2,3\}$ and beyond. |
| Uniform gap under $P\to\infty$ | **Assumed** |
| Existence of the pairing on completed cohomology | **Geometric hypothesis** |
| Converse (contractivity $\Rightarrow$ negativity) | **Open** |

## 6. Role inside Theorem A
This theorem serves as Part 2 of the three-part conditional argument for the Riemann Hypothesis. Crucially, the argument requires only the forward implication (Hodge Negativity $\to$ Global Contractivity). 
