"""pytest configuration for automorphic tests."""

import pytest
import numpy as np


@pytest.fixture(autouse=True)
def set_random_seed():
    """Set random seed for reproducibility."""
    np.random.seed(42)


@pytest.fixture
def small_prime():
    """Small prime for testing."""
    return 7


@pytest.fixture
def medium_prime():
    """Medium prime for testing."""
    return 31


@pytest.fixture
def large_prime():
    """Large prime for testing."""
    return 997
