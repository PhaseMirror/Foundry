"""
Unit tests for Prime-Encoded Eigen Solvers Python package.
Self-contained standard library unittest.
"""

import unittest
import math
from eigen_solvers import (
    PrimeWeightedLanczos,
    LanczosResult,
    SpectralInvariants,
    PrimeTensorModule,
    PrimeTensorState,
    QuantumPhaseEstimator,
    RecursiveFeedbackSolver,
    lanczos_sane,
)


class TestEigenSolvers(unittest.TestCase):

    def setUp(self):
        # 3x3 symmetric matrix
        self.A = [
            [4.0, 1.0, 0.0],
            [1.0, 3.0, 1.0],
            [0.0, 1.0, 2.0]
        ]

    def test_lanczos_decomposition_and_sanity(self):
        solver = PrimeWeightedLanczos(self.A, primes=[2, 3, 5])
        res = solver.decompose(m_max=3)

        self.assertIsInstance(res, LanczosResult)
        self.assertEqual(res.iterations, 3)
        self.assertEqual(len(res.alphas), 3)
        self.assertEqual(len(res.effective_betas), 2)
        self.assertEqual(len(res.T), 3)

        # Enforce lanczos_sane guard
        is_sane = lanczos_sane(res.ritz_values, res.residual_bounds, dim=3, energy_scale=100.0)
        self.assertTrue(is_sane, f"Ritz values diverged: {res.ritz_values}, residuals: {res.residual_bounds}")

        # True eigenvalues of A are approximately [1.2679, 3.0000, 4.7321]
        # In prime-weighted tridiagonal T_3, eigenvalues must be bounded within Gershgorin disks
        for ritz in res.ritz_values:
            self.assertGreater(ritz, -5.0)
            self.assertLess(ritz, 15.0)

    def test_lanczos_sane_rejects_divergence(self):
        # Must reject runaway Ritz values
        self.assertFalse(lanczos_sane([0.0, 2.99e8, 6.60e17], [1.2e7, 3.4e6, 9.0e6], dim=3))
        # Must reject NaN residuals
        self.assertFalse(lanczos_sane([1.0, 2.0, 3.0], [float('nan'), 0.1, 0.2], dim=3))
        # Must pass bounded values
        self.assertTrue(lanczos_sane([1.2, 3.0, 4.8], [0.05, 0.02, 0.01], dim=3))

    def test_invariants(self):
        solver = PrimeWeightedLanczos(self.A, primes=[2, 3, 5])
        res = solver.decompose(m_max=3)
        inv = SpectralInvariants.analyze(res)

        self.assertIsInstance(inv.trace, float)
        self.assertGreaterEqual(inv.off_diagonal_energy, 0.0)
        self.assertIsInstance(inv.exponent_signature, float)
        # Trace preservation
        self.assertAlmostEqual(inv.trace, sum(self.A[i][i] for i in range(3)))

    def test_prime_tensor_and_qpe(self):
        primes = [2, 3, 5]
        eigenvalues = [4.0, 2.0, 1.0]
        eigenvectors = [
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.0, 0.0, 1.0]
        ]

        module = PrimeTensorModule(primes, eigenvalues, eigenvectors)
        self.assertAlmostEqual(module.state.norm_squared, 16.0 + 4.0 + 1.0)

        # Test QPE distribution sums to 1.0
        qpe = QuantumPhaseEstimator.measure_distribution(module)
        total_prob = sum(qpe.values())
        self.assertAlmostEqual(total_prob, 1.0)
        self.assertAlmostEqual(qpe[2], 16.0 / 21.0)
        self.assertAlmostEqual(qpe[3], 4.0 / 21.0)
        self.assertAlmostEqual(qpe[5], 1.0 / 21.0)

        # Test quantum evolution preserves state norm
        evolved = module.evolve(time=1.5)
        self.assertAlmostEqual(evolved.state.norm_squared, module.state.norm_squared)

    def test_recursive_feedback(self):
        primes = [2, 3, 5]
        scales = [0.5, 0.5, 0.5]
        solver = RecursiveFeedbackSolver(primes, scales, learning_rate=0.1)

        traj = solver.run(lambda_0=1.0, steps=4)
        self.assertEqual(len(traj), 5)
        self.assertEqual(traj[0], 1.0)
        self.assertGreater(traj[-1], traj[0])


if __name__ == "__main__":
    unittest.main()
