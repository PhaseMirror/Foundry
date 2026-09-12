"""Ξ∞/CSL Automorphic Learning: prime-structured inductive bias."""

__version__ = "0.1.0"

from .group import AglGroup, CrtEmbedding, legendre_symbol
from .mask import ResidueMask, AdditiveLogits, sinkhorn_eps
from .unitary import exp_unitary, cayley_unitary, unitary_residual
from .spectral import compute_eigen_phases, compare_satot_tate
from .projection import project_weighted_l1, softmax_ub, slopeub
