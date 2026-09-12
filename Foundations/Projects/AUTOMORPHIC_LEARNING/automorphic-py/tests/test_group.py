"""Tests for automorphic.group module."""

import pytest
import numpy as np
from automorphic.group import AglGroup, AglElement, CrtEmbedding, legendre_symbol


class TestLegendreSymbol:
    def test_zero(self):
        assert legendre_symbol(0, 7) == 0

    def test_quadratic_residue(self):
        # 2 is a QR mod 7 since 3^2 = 9 ≡ 2 (mod 7)
        assert legendre_symbol(2, 7) == 1

    def test_quadratic_non_residue(self):
        # 3 is QNR mod 7
        assert legendre_symbol(3, 7) == -1

    def test_euler_criterion(self):
        # Verify Euler's criterion for p=11
        residues = [1, 3, 4, 5, 9]
        non_residues = [2, 6, 7, 8, 10]
        for r in residues:
            assert legendre_symbol(r, 11) == 1
        for nr in non_residues:
            assert legendre_symbol(nr, 11) == -1


class TestAglElement:
    def test_apply(self):
        g = AglElement(2, 1, 7)
        assert g.apply(3) == (2 * 3 + 1) % 7

    def test_inverse(self):
        g = AglElement(2, 1, 7)
        g_inv = g.inverse()
        # g * g_inv should be identity
        for i in range(7):
            assert g.apply(g_inv.apply(i)) == i

    def test_compose(self):
        g = AglElement(2, 1, 7)
        h = AglElement(3, 2, 7)
        gh = g.compose(h)
        for i in range(7):
            assert gh.apply(i) == g.apply(h.apply(i))

    def test_permutation_matrix(self):
        g = AglElement(2, 1, 7)
        P = g.permutation_matrix(7)
        assert P.shape == (7, 7)
        # Each column should have exactly one 1
        for j in range(7):
            assert np.sum(P[:, j]) == 1.0
        # Each row should have exactly one 1
        for i in range(7):
            assert np.sum(P[i, :]) == 1.0


class TestAglGroup:
    def test_order(self):
        g = AglGroup(7)
        assert g.order == 42  # (p-1) * p = 6 * 7

    def test_conjugation_preserves_trace(self):
        g = AglGroup(5)
        A = np.array([[1, 2], [3, 4]])
        # Conjugation by permutation preserves trace
        # (trace is invariant under similarity transform)
        for elem in g.elements[:5]:  # Test first 5 elements
            P = elem.permutation_matrix(A.shape[0])
            B = P @ A @ P.T
            assert np.isclose(np.trace(B), np.trace(A))


class TestCrtEmbedding:
    def test_basic(self):
        crt = CrtEmbedding(5, 7, 35)
        assert crt.embed(0) == (0, 0)
        assert crt.embed(1) == (1, 1)
        assert crt.embed(5) == (0, 5)

    def test_injectivity(self):
        crt = CrtEmbedding(5, 7, 35)
        seen = set()
        for i in range(35):
            e = crt.embed(i)
            assert e not in seen
            seen.add(e)
