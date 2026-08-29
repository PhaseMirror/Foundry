"""Tests for automorphic.projection module."""

import pytest
import numpy as np
from automorphic.projection import (
    project_weighted_l1, softmax, softmax_ub, slopeub,
    ProjectionCertificate
)


class TestProjectWeightedL1:
    def test_already_feasible(self):
        v = np.array([0.1, 0.1, 0.1])
        omega = np.array([1.0, 1.0, 1.0])
        T = 1.0  # mass is 0.3, well within budget
        x, cert = project_weighted_l1(v, omega, T)
        assert cert.feasible
        assert np.allclose(x, v)

    def test_projection_reduces_mass(self):
        v = np.array([0.5, 0.5, 0.5])
        omega = np.array([1.0, 1.0, 1.0])
        T = 0.5
        x, cert = project_weighted_l1(v, omega, T)
        assert cert.feasible
        assert cert.mass <= T + 1e-6

    def test_kkt_complementary_slackness(self):
        v = np.array([0.3, 0.4, 0.3])
        omega = np.array([1.0, 1.0, 1.0])
        T = 0.5
        x, cert = project_weighted_l1(v, omega, T)
        assert cert.complementary_slackness

    def test_zero_budget(self):
        v = np.array([0.5, 0.5, 0.5])
        omega = np.array([1.0, 1.0, 1.0])
        T = 0.0
        x, cert = project_weighted_l1(v, omega, T)
        assert cert.feasible
        assert np.allclose(x, 0.0, atol=1e-6)


class TestSoftmax:
    def test_sums_to_one(self):
        logits = np.array([1.0, 2.0, 3.0])
        probs = softmax(logits)
        assert np.isclose(np.sum(probs), 1.0)

    def test_numerical_stability(self):
        logits = np.array([1000.0, 1001.0, 1002.0])
        probs = softmax(logits)
        assert np.isclose(np.sum(probs), 1.0)
        assert not np.any(np.isnan(probs))


class TestSoftmaxUB:
    def test_uniform_distribution(self):
        logits = np.array([0.0, 0.0, 0.0])
        ub = softmax_ub(logits)
        # For uniform, s_i = 1/3, so 2*s*(1-s) = 2/3 * 2/3 = 4/9
        assert np.isclose(ub, 4 / 9, atol=1e-6)

    def test_peaked_distribution(self):
        logits = np.array([100.0, 0.0, 0.0])
        ub = softmax_ub(logits)
        # For peaked, max s_i ≈ 1, so 2*s*(1-s) ≈ 0
        assert ub < 0.1


class TestSlopeUB:
    def test_simple(self):
        linear_norms = [1.0, 1.0, 1.0]
        softmax_ubs = [0.5, 0.5, 0.5]
        result = slopeub(linear_norms, softmax_ubs)
        assert np.isclose(result, 0.125)  # 1 * 1 * 1 * 0.5 * 0.5 * 0.5
