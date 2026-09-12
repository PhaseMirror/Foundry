# Prime-Encoded Eigen Solvers as Categorical Prime Flows

[![Lean 4 Verification](https://img.shields.io/badge/Lean%204-Axiom--Clean-brightgreen)](EigenSolvers/)
[![Python Tests](https://img.shields.io/badge/Python%20Tests-5%2F5%20Passing-success)](python/tests/)
[![Sanity Guard](https://img.shields.io/badge/Lanczos%20Sanity%20Guard-Enforced-blue)](python/eigen_solvers/linalg.py)

Production-grade formalization and numerical engine for Prime-Encoded Eigenvalue Decomposition (PEED), Prime-Weighted Lanczos flows, and Prime-Tensor quantum states.

Reference: `docs/templateArxiv.tex` (*Prime-Encoded Eigen Solvers as Categorical Prime Flows: A Multiplicity-Theoretic and Tensor-Quantum Framework*).

---

## 1. Overview & Architecture

```
                                  Hermitian Matrix A
                                          │
                        ┌─────────────────┴─────────────────┐
                        ▼                                   ▼
             Category PrimeMod_A                   Category PrimeTen_A
          (Krylov Modules M_m)                  (Tensor Modules N_m)
                        │                                   │
      ┌─────────────────┴─────────────────┐                 │
      ▼                                   ▼                 ▼
Lanczos Step Functor F_p             Invariants         Tensor State
M_m ──> M_{m+1}                   Tr(M_m) = ∑ α_k       Ψ(t) = ∑ λ_i |p_i⟩⊗|e_i⟩
Natural Inc: ι : Id => F_p        E(M_m) = ∑ (β_k p_k)²     │
T_m with off-diagonals β_k p_k    Coupling Ratios r_k       ▼
                                  Exponent Sig s_m      QPE Functor P
                                  Feedback Dynamics R   Prob: P(p_i) = |λ_i|²/||Ψ||²
```

---

## 2. Mathematical Formalization (Lean 4)

Located in `EigenSolvers/`:

| Module | Purpose |
|:---|:---|
| [`EigenSolvers/Core.lean`](EigenSolvers/Core.lean) | Formal category $\mathbf{PrimeMod}_A$, prime-weighted Lanczos recurrence, Tridiagonal matrix $T_m$, and functors $(\mathrm{Tr}, E, r_k, s_m, \mathcal{R})$. |
| [`EigenSolvers/Tensor.lean`](EigenSolvers/Tensor.lean) | Category $\mathbf{PrimeTen}_A$, prime-tensor state $\Psi(t)$, quantum evolution $\mathcal{Q}$, and phase estimation $\mathcal{P}$. |
| [`EigenSolvers/Proofs.lean`](EigenSolvers/Proofs.lean) | Machine-checked theorems: category identity/associativity laws, energy monotonicity $E(M_{m+1}) \ge E(M_m)$, trace linearity, and state norm bounds. |
| [`EigenSolvers/Examples.lean`](EigenSolvers/Examples.lean) | Concrete 3x3 evaluation instance with exact arithmetic verification. |
| [`EigenSolvers/Test.lean`](EigenSolvers/Test.lean) | Executable test driver (`eigen_test`) validating all 4 formal verification gates. |

### Build & Run Formal Verification:
```bash
lake build eigen_test
lake exe eigen_test
```

---

## 3. Production Numerical Engine (Python)

Located in `python/eigen_solvers/` (Zero external dependencies, self-contained pure standard library with `lanczos_sane` overflow guard):

| File | Purpose |
|:---|:---|
| [`python/eigen_solvers/linalg.py`](python/eigen_solvers/linalg.py) | Stable Jacobi eigensolver for symmetric tridiagonals and `lanczos_sane` guard rejecting Ritz divergence. |
| [`python/eigen_solvers/prime_lanczos.py`](python/eigen_solvers/prime_lanczos.py) | `PrimeWeightedLanczos` solver producing tridiagonals $T_m$, Ritz pairs $(\theta_j, u_j)$, residual bounds $\|r_j\| \le |\beta_m p_m| |e_m^T y_j|$, and Gershgorin disks. |
| [`python/eigen_solvers/invariants.py`](python/eigen_solvers/invariants.py) | `SpectralInvariants` computing Trace, Energy $E(M_m)$, scale-free coupling ratios $r_k$, and exponent signatures $s_m$. |
| [`python/eigen_solvers/prime_tensor.py`](python/eigen_solvers/prime_tensor.py) | `PrimeTensorModule` & `QuantumPhaseEstimator` simulating quantum phase estimation distributions and expectation values $\mathbb{E}_{\mathcal{O}}$. |
| [`python/eigen_solvers/feedback.py`](python/eigen_solvers/feedback.py) | `RecursiveFeedbackSolver` computing eigenvalue refinement trajectories $\lambda_{t+1} = \lambda_t + \alpha_t \sum p_i e^{-\beta_i t}$. |
| [`python/eigen_solvers/cli.py`](python/eigen_solvers/cli.py) | Interactive CLI for matrix decomposition and invariant reporting with automated sanity checks. |

### Run Python Tests & CLI:
```bash
# Run unit tests (5/5 tests passing)
PYTHONPATH=python python3 python/tests/test_eigen_solvers.py

# Run CLI decomposition
PYTHONPATH=python python3 -m eigen_solvers.cli --dim 3 --depth 3
```

---

## 4. Verification Gate Results

### Lean Formal Verification:
```
=================================================================
  PRIME-ENCODED EIGEN SOLVERS: FORMAL VERIFICATION SUITE         
=================================================================

[1] Testing Prime-Weighted Krylov Module Flow...
    Krylov Depth = 3 (expected 3)
    Alphas = [4.000000, 3.000000, 2.000000]
    Raw Betas = [1.000000, 1.000000]
    Primes = [2, 3, 5]
    Effective Betas (β_k * p_k) = [2.000000, 3.000000] (expected [2.0, 3.0])
    [+] PASSED: Prime-weighted Lanczos step functor verified.

[2] Testing Spectral & Dynamical Invariants...
    Trace Tr(M_3) = 9.000000 (expected 9.0)
    Off-Diagonal Energy E(M_3) = 13.000000 (expected 13.0)
    Coupling Ratios r_k = [1.500000] (expected [1.5])
    Exponent Signature s_3 = 2.000000 (expected 2.0)
    [+] PASSED: All categorical invariants verified.

[3] Testing Recursive Feedback Eigenvalue Refinement...
    Refined λ after 5 steps = 7.332876
    [+] PASSED: Recursive feedback dynamics verified.

[4] Testing Prime Tensor Module & Quantum Phase Estimation...
    Tensor State Components = [(2, 5.214000), (3, 3.000000), (5, 0.786000)]
    Squared Norm ||Ψ||^2 = 36.803592
    QPE Probabilities = [(2, 0.738672), (3, 0.244541), (5, 0.016786)]
    Sum of QPE Probabilities = 1.000000 (expected 1.0)
    [+] PASSED: Quantum phase estimation functor verified.

=================================================================
  ALL 4/4 GATES PASSED: CATEGORICAL PRIME FLOW VERIFIED (100%)    
=================================================================
```

### Python Numerical Execution:
```
=================================================================
   PRIME-ENCODED EIGEN SOLVER EXECUTION REPORT                  
=================================================================
Matrix Dimension:     3
Krylov Depth:         3
Alphas (diag):        [4.3333, 2.1667, 2.5]
Effective Betas:      [1.8856, 2.5981]
Ritz Values:          [-0.6718, 3.5889, 6.0829]
Residual Bounds:      [1.5806, 1.7121, 1.1492]
Trace Invariant:      9.0000
Off-Diagonal Energy:  10.3056
Coupling Ratios:      [1.3778]
Exponent Signature:   1.7841
QPE Distribution:     {p=2: 0.0090, p=3: 0.2559, p=5: 0.7351}
Feedback Trajectory:  [-0.6718, -0.1718, 0.1314, 0.3154, 0.4269, 0.4946]
=================================================================
```
