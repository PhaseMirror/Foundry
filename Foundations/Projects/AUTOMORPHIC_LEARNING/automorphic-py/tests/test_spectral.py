"""Tests for automorphic.spectral module."""

import pytest
import numpy as np
from automorphic.spectral import (
    satot_tate_cdf, satot_tate_pdf, sample_satot_tate,
    wasserstein_2, ks_statistic, cvm_statistic,
    bca_bootstrap, compare_satot_tate
)


class TestSatoTateCDF:
    def test_at_zero(self):
        assert np.isclose(satot_tate_cdf(0.0), 0.0)

    def test_at_pi(self):
        assert np.isclose(satot_tate_cdf(np.pi), 1.0)

    def test_monotonic(self):
        xs = np.linspace(0, np.pi, 100)
        cdfs = [satot_tate_cdf(x) for x in xs]
        for i in range(len(cdfs) - 1):
            assert cdfs[i] <= cdfs[i + 1]


class TestSatoTatePDF:
    def test_at_zero(self):
        assert np.isclose(satot_tate_pdf(0.0), 0.0)

    def test_at_pi(self):
        assert np.isclose(satot_tate_pdf(np.pi), 0.0)

    def test_positive(self):
        xs = np.linspace(0.1, np.pi - 0.1, 100)
        for x in xs:
            assert satot_tate_pdf(x) > 0


class TestSampleSatoTate:
    def test_shape(self):
        rng = np.random.default_rng(42)
        samples = sample_satot_tate(1000, rng)
        assert len(samples) == 1000

    def test_in_range(self):
        rng = np.random.default_rng(42)
        samples = sample_satot_tate(1000, rng)
        assert np.all(samples >= 0)
        assert np.all(samples <= np.pi)


class TestWasserstein2:
    def test_same_distribution(self):
        rng = np.random.default_rng(42)
        samples = rng.uniform(0, 1, 1000)
        w2 = wasserstein_2(samples, samples)
        assert np.isclose(w2, 0.0, atol=1e-6)


class TestKSStatistic:
    def test_same_distribution(self):
        rng = np.random.default_rng(42)
        samples = rng.uniform(0, 1, 1000)
        ks = ks_statistic(samples, samples)
        assert np.isclose(ks, 0.0, atol=1e-6)


class TestBCaBootstrap:
    def test_output_shape(self):
        rng = np.random.default_rng(42)
        samples = rng.normal(0, 1, 1000)
        lower, upper, median, width = bca_bootstrap(
            samples, np.mean, resamples=100, rng=rng
        )
        assert lower <= median <= upper
        assert width >= 0


class TestCompareSatoTate:
    def test_same_distribution(self):
        rng = np.random.default_rng(42)
        phases = sample_satot_tate(1000, rng)
        st_samples = sample_satot_tate(1000, rng)
        result = compare_satot_tate(phases, st_samples, rng=rng)
        assert result.passes
