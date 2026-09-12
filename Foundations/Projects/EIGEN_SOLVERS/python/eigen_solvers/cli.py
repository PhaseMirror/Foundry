"""
Command Line Interface for Prime-Encoded Eigen Solvers.
"""

import argparse
import json
import math

try:
    from .prime_lanczos import PrimeWeightedLanczos
    from .invariants import SpectralInvariants
    from .prime_tensor import PrimeTensorModule, QuantumPhaseEstimator
    from .feedback import RecursiveFeedbackSolver
    from .linalg import Matrix, lanczos_sane
except ImportError:
    from eigen_solvers.prime_lanczos import PrimeWeightedLanczos
    from eigen_solvers.invariants import SpectralInvariants
    from eigen_solvers.prime_tensor import PrimeTensorModule, QuantumPhaseEstimator
    from eigen_solvers.feedback import RecursiveFeedbackSolver
    from eigen_solvers.linalg import Matrix, lanczos_sane


def generate_test_matrix(n: int) -> Matrix:
    """Generate a symmetric tridiagonal test matrix."""
    A = [[0.0] * n for _ in range(n)]
    for i in range(n):
        A[i][i] = float(i + 2)
        if i + 1 < n:
            A[i][i + 1] = 1.0
            A[i + 1][i] = 1.0
    return A


def main():
    parser = argparse.ArgumentParser(description="Prime-Encoded Eigen Solvers CLI")
    parser.add_argument("--dim", type=int, default=3, help="Matrix dimension")
    parser.add_argument("--depth", type=int, default=3, help="Lanczos Krylov depth")
    parser.add_argument("--json", action="store_true", help="Output results as JSON")
    args = parser.parse_args()

    A = generate_test_matrix(args.dim)
    solver = PrimeWeightedLanczos(A)
    res = solver.decompose(m_max=args.depth)
    inv = SpectralInvariants.analyze(res)

    # Sanity guard
    if not lanczos_sane(res.ritz_values, res.residual_bounds, dim=args.dim):
        raise RuntimeError("Lanczos sanity guard failed: Ritz overflow or residual divergence detected.")

    tensor_mod = PrimeTensorModule(res.primes, res.ritz_values, res.ritz_vectors)
    qpe_dist = QuantumPhaseEstimator.measure_distribution(tensor_mod)

    feedback_solver = RecursiveFeedbackSolver(res.primes, [0.5] * len(res.primes))
    feedback_traj = feedback_solver.run(float(res.ritz_values[0]), steps=5)

    output = {
        "matrix_dim": args.dim,
        "krylov_depth": res.iterations,
        "alphas": res.alphas,
        "effective_betas": res.effective_betas,
        "ritz_values": res.ritz_values,
        "residual_bounds": res.residual_bounds,
        "invariants": {
            "trace": inv.trace,
            "off_diagonal_energy": inv.off_diagonal_energy,
            "coupling_ratios": inv.coupling_ratios,
            "exponent_signature": inv.exponent_signature,
        },
        "qpe_distribution": qpe_dist,
        "feedback_trajectory": feedback_traj,
    }

    if args.json:
        print(json.dumps(output, indent=2))
    else:
        print("=================================================================")
        print("   PRIME-ENCODED EIGEN SOLVER EXECUTION REPORT                  ")
        print("=================================================================")
        print(f"Matrix Dimension:     {args.dim}")
        print(f"Krylov Depth:         {res.iterations}")
        print(f"Alphas (diag):        {[round(x, 4) for x in res.alphas]}")
        print(f"Effective Betas:      {[round(x, 4) for x in res.effective_betas]}")
        print(f"Ritz Values:          {[round(x, 4) for x in res.ritz_values]}")
        print(f"Residual Bounds:      {[round(x, 6) for x in res.residual_bounds]}")
        print(f"Trace Invariant:      {inv.trace:.4f}")
        print(f"Off-Diagonal Energy:  {inv.off_diagonal_energy:.4f}")
        print(f"Coupling Ratios:      {[round(x, 4) for x in inv.coupling_ratios]}")
        print(f"Exponent Signature:   {inv.exponent_signature:.4f}")
        print(f"QPE Distribution:     {{{', '.join(f'p={k}: {v:.4f}' for k, v in qpe_dist.items())}}}")
        print(f"Feedback Trajectory:  {[round(x, 4) for x in feedback_traj]}")
        print("=================================================================")


if __name__ == "__main__":
    main()
