"""
Spectral band projectors via eigendecomposition.

Constructs projectors onto eigenspaces corresponding to specified eigenvalue bands.
"""

import numpy as np
from typing import Tuple, List
from .projectors import ProjectorFamily


def eigh_projectors(
    A: np.ndarray, 
    bands: List[Tuple[float, float]]
) -> List[np.ndarray]:
    """
    Construct spectral band projectors from symmetric matrix.
    
    For each band (λ_min, λ_max), constructs the projector onto the subspace
    spanned by eigenvectors with eigenvalues in [λ_min, λ_max].
    
    Args:
        A: Symmetric matrix (n × n)
        bands: List of (λ_min, λ_max) tuples defining eigenvalue bands
    
    Returns:
        List of projection matrices, one per band
    """
    A = np.asarray(A, dtype=float)
    assert A.shape[0] == A.shape[1], "Matrix must be square"
    
    # Eigendecomposition
    eigvals, eigvecs = np.linalg.eigh(A)
    n = A.shape[0]
    
    projectors = []
    
    for lambda_min, lambda_max in bands:
        # Find eigenvectors in this band
        mask = (eigvals >= lambda_min) & (eigvals <= lambda_max)
        
        if not np.any(mask):
            # Empty band: zero projector
            projectors.append(np.zeros((n, n)))
        else:
            # Construct projector: P = U_band @ U_band^T
            U_band = eigvecs[:, mask]
            P = U_band @ U_band.T
            projectors.append(P)
    
    return projectors


def spectral_projector_family(
    A: np.ndarray,
    bands: List[Tuple[float, float]],
    name: str = "SpectralBands"
) -> ProjectorFamily:
    """
    Create a ProjectorFamily from spectral bands.
    
    This constructs coordinate-based projectors by identifying which coordinates
    have the most energy in each spectral band.
    
    Args:
        A: Symmetric matrix
        bands: List of eigenvalue bands
        name: Name for the projector family
    
    Returns:
        ProjectorFamily instance
    """
    projectors = eigh_projectors(A, bands)
    n = A.shape[0]
    
    # For each band, find the coordinates with highest projection energy
    indexsets = []
    used_indices = set()
    
    for P in projectors:
        # Diagonal elements of P give the "energy" per coordinate
        energies = np.abs(np.diag(P))
        
        # Threshold: coordinates with non-negligible energy
        threshold = np.max(energies) * 0.1  # 10% of max
        indices = [i for i in range(n) 
                   if energies[i] >= threshold and i not in used_indices]
        
        if indices:
            indexsets.append(indices)
            used_indices.update(indices)
    
    # Add any remaining unused indices as a final block
    remaining = [i for i in range(n) if i not in used_indices]
    if remaining:
        indexsets.append(remaining)
    
    return ProjectorFamily(indexsets, name)


def mask_band_projector(U: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """
    Construct band projector: U @ diag(mask) @ U^T.
    
    Args:
        U: Orthogonal matrix (eigenvectors)
        mask: Binary mask selecting bands (1 = include, 0 = exclude)
    
    Returns:
        Projection matrix
    """
    U = np.asarray(U, dtype=float)
    mask = np.asarray(mask, dtype=float)
    
    assert U.shape[0] == U.shape[1], "U must be square"
    assert len(mask) == U.shape[1], "mask must match U dimension"
    
    # P = U @ diag(mask) @ U^T
    return U @ np.diag(mask) @ U.T
