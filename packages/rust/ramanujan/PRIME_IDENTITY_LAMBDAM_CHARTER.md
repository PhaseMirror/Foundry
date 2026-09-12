# Prime Identity & Lambda-m Charter (MOC)

This charter defines the core invariants, extensions, and governance rules for the ≡-Compiler and the Multiplicity Operator Calculus (MOC) representations on the Λᵖ‑Archivum.

## 1. Core MOC Predicates

The fundamental properties of any lawful state transition within the calculus:

*   **Canonical Determinism (NF(Q,p))**: All evaluations require canonical witness selection during state reduction (e.g., lex-min choice of primitive orthogonal vectors during `BLOWDOWN`). Syntactic cancellation alone is insufficient; state normalization must include lattice reduction (N2 LLL) and prime-local Jordan decomposition (N3).
*   **Contractive Core ($c < 1$)**: The local contraction operators must strictly shrink the norm radius under the Archival Contraction Entropy limits.

## 2. Extension Rules (Governance Bounding)

The following bounds are not native theorems of the MOC rewriting logic, but are strict governance extensions required by the AGI-OS runtime to guarantee sparsity and finite execution limits:

*   **CSL Sparsity Bound (`|w| <= 12`)**: A syntactic constraint bounding the maximum length of an operator word. This is an operational gate to prevent runaway circuit complexity, distinct from algebraic convergence.
*   **RamanujanBound Predicate**: Elevated from a syntactic intuition flag to a derived, machine-checkable algebraic invariant. It asserts that the word's prime support behaves as a Hecke eigen-operator.

## 3. RamanujanBound as a Provenance-Traced Certificate

The `RamanujanBound` is now a layered, provenance-traced certificate that moves beyond a simple flag to enforce deep mathematical properties of the operator word. It consists of:

1.  **Hecke Eigen-operator Predicate**: The normalized word’s prime-power subwords must satisfy the recurrence $U_p^{k+1} = U_p U_p^k - p^{11} U_p^{k-1}$ (scaled to the lawful subspace). This is checked in `validator/admissible.rs` and enables algebraic lifting of repeated prime factors during N1 stabilization.
2.  **Deligne-bound Contraction Certificate**: The Deligne inequality $|\tau(p)| \le 2p^{11/2}$ supplies a concrete Lipschitz constant for each prime-channel operator $U_p$. The contraction test $\sup_p \lambda_p (L_{A,p}+L_{B,p}+L_{E,p}) < 1$ is now evaluable and machine-checkable.

These properties are parametrised by the following optional provenance tags. The highest available provenance tag determines the tightness and rigor of the bound:

*   **`deligne_justification`**: When asserted, the validator demands that every prime channel carries a declared compatible system of l-adic Galois representations whose Frobenius eigenvalues satisfy purity of weight ($w=11$ for tau). Absence forces a strictly larger conservative bound.
*   **`etale_realization`**: `{weight: integer, purity_bound: string}`. Links the exponent $11/2$ directly to the weight of étale cohomology (purity theorem). The sharp bound is only accepted when this tag supplies $weight=11$; otherwise, the validator falls back to a generic Lipschitz estimate.
*   **`eichler_shimura_realization`**: `{level: integer, weight: 2, newform_label: string}`. For weight-2 modular forms, this tag requires the effective operator to satisfy $\operatorname{Tr}(\operatorname{Frob}_p) = a_p$ and $\det = p$ (or the scaled analogue). This enforces **newform provenance**, grounding the weight-2 recurrence in the specific geometry of $J_0(N)$ and its l-adic Tate module, distinguishing it from purely algebraic polynomial checks by verifying against known Fourier coefficients of the specified newform.
*   **`modular_abelian_variety`**: `{newform_label: string, cm_field: optional string}`. For weight-2 newforms, this tag enforces that the prime-channel operators arise from the endomorphism algebra of the associated modular abelian variety $A_f$. If a CM field is declared, additional commutation relations and eigenvalue constraints are imposed, further tightening the bound.

Any claim of sharp Ramanujan compliance must carry the appropriate tag; otherwise, the bound is flagged as conservative. This ensures that any "Ramanujan compliance" is cryptographically linked to the geometric justification actually supplied in the `LawfulRecursionHash`.
