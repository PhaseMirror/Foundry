"""
Projector families and π-atom construction.

Each family is a disjoint partition of coordinate indices. π-atoms are formed
by intersecting blocks from commuting families. For orthogonal families, π-atom
projectors are themselves orthogonal projectors.
"""

import numpy as np
from typing import List, Tuple, Dict


def intersect_many(sets: List[List[int]]) -> List[int]:
    """Compute intersection of multiple lists of integers."""
    if not sets:
        return []
    result = set(sets[0])
    for s in sets[1:]:
        result &= set(s)
    return sorted(list(result))


class ProjectorFamily:
    """
    A family of orthogonal coordinate projectors defined by disjoint index sets.
    
    Each family partitions the ambient dimension into non-overlapping blocks.
    The projector R_i extracts coordinates indexed by the i-th block.
    """
    
    def __init__(self, indexsets: List[List[int]], name: str):
        """
        Initialize a projector family.
        
        Args:
            indexsets: List of index lists, must be disjoint
            name: Human-readable name for this family
        """
        self.name = name
        self.indexsets = [sorted(list(s)) for s in indexsets]
        
        # Enforce disjointness
        allidx = [i for S in self.indexsets for i in S]
        assert len(allidx) == len(set(allidx)), \
            f"Index sets for {name} are not disjoint"
        
        self.dim = len(allidx)
        self.numblocks = len(self.indexsets)
    
    def blockindices(self, block_id: int) -> List[int]:
        """Get the coordinate indices for a specific block."""
        return self.indexsets[block_id]
    
    def project(self, x: np.ndarray, block_id: int) -> np.ndarray:
        """Extract coordinates corresponding to a block."""
        indices = self.indexsets[block_id]
        return x[indices]
    
    def embed(self, coeffs: np.ndarray, block_id: int, ambient_dim: int) -> np.ndarray:
        """Embed block coefficients back into ambient space (zero elsewhere)."""
        result = np.zeros(ambient_dim)
        indices = self.indexsets[block_id]
        result[indices] = coeffs
        return result


class PiIndexGrid:
    """
    Multi-family π-atom grid.
    
    Takes multiple commuting projector families and builds π-atoms as non-empty
    intersections of their blocks. Each π-atom is indexed by a tuple 
    (family0_block, family1_block, ...).
    """
    
    def __init__(self, families: List[ProjectorFamily]):
        """
        Initialize π-atom grid from multiple families.
        
        Args:
            families: List of ProjectorFamily instances
        """
        # All families must share same ambient dimension
        assert len(set(f.dim for f in families)) == 1, \
            "All families must have the same ambient dimension"
        
        self.families = families
        self.dim = families[0].dim
        
        # Build π-atoms: multi-index → coordinate subset
        self.atoms = []  # list of (pi_tuple, indices)
        self.map = {}    # pi_tuple → indices
        
        # Iterate over all combinations of family blocks
        block_counts = tuple(f.numblocks for f in families)
        for idxtuple in np.ndindex(block_counts):
            # Get coordinate sets for each family's block
            sets = [families[j].blockindices(idxtuple[j]) 
                    for j in range(len(families))]
            # Compute intersection
            inter = intersect_many(sets)
            if len(inter) > 0:
                pi_id = tuple(idxtuple)
                self.atoms.append((pi_id, inter))
                self.map[pi_id] = inter
        
        self.piids = [pi for pi, _ in self.atoms]
    
    def indices(self, pi_id: tuple) -> List[int]:
        """Get coordinate indices for a π-atom."""
        return self.map[pi_id]
    
    def project(self, x: np.ndarray, pi_id: tuple) -> np.ndarray:
        """Extract π-atom coefficients from state vector."""
        indices = self.map[pi_id]
        return x[indices]
    
    def embed(self, coeffs: np.ndarray, pi_id: tuple) -> np.ndarray:
        """Embed π-atom coefficients into ambient space."""
        result = np.zeros(self.dim)
        indices = self.map[pi_id]
        result[indices] = coeffs
        return result
    
    def orthogonality_defect(self, pi1: tuple, pi2: tuple) -> float:
        """
        Compute orthogonality defect between two π-atoms.
        
        For orthogonal families, this should be 0 (atoms have disjoint supports).
        For tight frames, this quantifies the overlap.
        
        Returns:
            ||R_{pi1} R_{pi2}|| where the norm is the operator norm
        """
        if pi1 == pi2:
            return 1.0  # Self-composition gives identity on support
        
        indices1 = set(self.map[pi1])
        indices2 = set(self.map[pi2])
        overlap = indices1 & indices2
        
        # For coordinate projectors, overlap = 0 means orthogonal
        return float(len(overlap))
    
    def recomposition_error(self, x: np.ndarray) -> float:
        """
        Verify that sum of all π-atom projections equals x.
        
        For orthogonal families with complete coverage:
            x = sum_{π} P_π x
        
        Returns:
            ||x - sum_{π} P_π x||
        """
        reconstruction = np.zeros(self.dim)
        for pi in self.piids:
            reconstruction[self.map[pi]] += x[self.map[pi]]
        
        return float(np.linalg.norm(x - reconstruction))
