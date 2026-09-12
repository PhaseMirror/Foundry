"""Tests for automorphic.mask module."""

import pytest
import numpy as np
from automorphic.mask import ResidueMask, AdditiveLogits, sinkhorn_eps


class TestResidueMask:
    def test_from_crt(self):
        mask = ResidueMask.from_crt(5, 7, 35)
        assert mask.mask.shape == (35, 35)
        # Diagonal should be all 1s (self-similar)
        for i in range(35):
            assert mask.mask[i, i] == 1.0


class TestAdditiveLogits:
    def test_compute(self):
        mask = ResidueMask.from_crt(5, 7, 35)
        logits = AdditiveLogits(alpha=0.0, beta=20.0)
        n = 35
        d = 16
        Q = np.random.randn(n, d)
        K = np.random.randn(n, d)
        L = logits.compute(Q, K, mask)
        assert L.shape == (n, n)

    def test_softmax_sums_to_one(self):
        mask = ResidueMask.from_crt(5, 7, 10)
        logits = AdditiveLogits()
        n = 10
        d = 8
        Q = np.random.randn(n, d)
        K = np.random.randn(n, d)
        L = logits.compute(Q, K, mask)
        P = logits.softmax(L)
        # Each row should sum to 1
        for i in range(n):
            assert np.isclose(np.sum(P[i, :]), 1.0)


class TestSinkhorn:
    def test_converges(self):
        A = np.random.rand(10, 10)
        B, resid = sinkhorn_eps(A)
        assert resid < 0.1  # Should be close to bistochastic
        # Check row sums
        for i in range(10):
            assert np.isclose(np.sum(B[i, :]), 1.0, atol=0.1)
        # Check col sums
        for j in range(10):
            assert np.isclose(np.sum(B[:, j]), 1.0, atol=0.1)
