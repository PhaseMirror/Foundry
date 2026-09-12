"""Tests for automorphic.unitary module."""

import pytest
import numpy as np
from automorphic.unitary import (
    exp_unitary, cayley_unitary, unitary_residual,
    compute_eigen_phases, permutation_ks
)


class TestExpUnitary:
    def test_output_is_unitary(self):
        n = 8
        B = np.random.rand(n, n)
        # Make bistochastic
        B = B / B.sum(axis=1, keepdims=True)
        U = exp_unitary(B)
        # Check unitarity: U†U ≈ I
        UHU = U.conj().T @ U
        assert np.allclose(UHU, np.eye(n), atol=1e-6)

    def test_permutation_equivariance(self):
        n = 8
        B = np.random.rand(n, n)
        B = B / B.sum(axis=1, keepdims=True)
        # Conjugate B by permutation, then unitarize
        P = np.eye(n)[np.random.permutation(n)]
        B_perm = P @ B @ P.T
        U1 = exp_unitary(B)
        U2 = exp_unitary(B_perm)
        # U_perm should be P U P^T
        U_perm = P @ U1 @ P.T
        assert np.allclose(U2, U_perm, atol=1e-6)


class TestCayleyUnitary:
    def test_safe_path(self):
        n = 8
        B = np.random.rand(n, n)
        B = (B - B.T) / 2  # Antisymmetric S
        U, safe = cayley_unitary(B)
        if safe:
            assert np.allclose(U.conj().T @ U, np.eye(n), atol=1e-6)


class TestUnitaryResidual:
    def test_identity_has_zero_residual(self):
        n = 8
        I = np.eye(n, dtype=complex)
        res = unitary_residual(I)
        assert np.isclose(res, 0.0)


class TestEigenPhases:
    def test_output_shape(self):
        n = 8
        U = exp_unitary(np.eye(n))
        phases = compute_eigen_phases(U)
        assert phases.shape == (n,)


class TestPermutationKS:
    def test_same_distribution(self):
        rng = np.random.default_rng(42)
        phases = rng.uniform(0, 2 * np.pi, 1000)
        ks, val = permutation_ks(phases, phases)
        assert ks is True
        assert np.isclose(val, 0.0)
