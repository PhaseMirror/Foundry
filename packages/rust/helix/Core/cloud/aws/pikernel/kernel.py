"""
Projection-first π-kernel with ACE safety and per-atom ledger.

The kernel implements the update loop:
    1. For each π-atom, extract coefficients
    2. Compute local proposal F_π(c)
    3. Project onto ACE safety set (weighted ℓ₁ ball)
    4. Emit ledger entry if touched
    5. Reconstruct state from projected atoms
"""

import numpy as np
from typing import Dict, Optional, Callable, Any

from .projectors import PiIndexGrid
from .l1proj import project_weighted_l1_ball
from .certificates import slope_upper_bound, gap_lower_bound
from .ledger import Ledger


class DefaultProposer:
    """Default local proposer: damped identity with small perturbation."""
    
    def __init__(self, damping: float = 0.9):
        """
        Initialize proposer.
        
        Args:
            damping: Damping factor in [0, 1]
        """
        self.damping = damping
    
    def __call__(self, c: np.ndarray) -> np.ndarray:
        """
        Compute proposal for coefficients c.
        
        Args:
            c: Current coefficients
        
        Returns:
            Proposed coefficients
        """
        return self.damping * c


class PiKernel:
    """
    π-kernel: projection-first update with ACE safety and PETC ledger.
    
    Each step:
    1. Projects state onto each π-atom
    2. Computes local proposal
    3. Projects proposal onto ACE safety set
    4. Reconstructs global state from projected atoms
    5. Emits ledger entries for touched atoms
    """
    
    def __init__(
        self,
        grid: PiIndexGrid,
        alphas: Dict[tuple, float],
        weights: Dict[tuple, np.ndarray],
        taus: Dict[tuple, float],
        K: np.ndarray,
        proposer: Optional[Callable] = None,
        ledger: Optional[Ledger] = None,
    ):
        """
        Initialize π-kernel.
        
        Args:
            grid: PiIndexGrid defining π-atoms
            alphas: Per-atom mixing rates {pi_id: alpha}
            weights: Per-atom ACE weights {pi_id: weight_vector}
            taus: Per-atom ℓ₁ budgets {pi_id: tau}
            K: Coupling matrix (m × m) for contraction certificate
            proposer: Local proposal function (defaults to DefaultProposer)
            ledger: Optional ledger for PETC entries
        """
        self.grid = grid
        self.piids = grid.piids
        self.alphas = alphas
        self.weights = weights
        self.taus = taus
        self.K = K
        self.proposer = proposer if proposer is not None else DefaultProposer()
        self.ledger = ledger
        
        # Verify dimensions
        m = len(self.piids)
        assert K.shape == (m, m), f"K must be {m}×{m}"
        assert len(alphas) == m, f"alphas must have {m} entries"
        assert len(weights) == m, f"weights must have {m} entries"
        assert len(taus) == m, f"taus must have {m} entries"
        
        # Initialize step counter
        self.step_count = 0
    
    def step(self, x: np.ndarray) -> Dict[str, Any]:
        """
        Execute one kernel step.
        
        Args:
            x: Current state vector (ambient dimension)
        
        Returns:
            Dictionary with:
            - xnew: Updated state
            - SlopeUB: Upper bound on slope
            - GapLB: Lower bound on contraction gap
            - touched: List of touched π-atoms
            - num_touched: Number of touched atoms
        """
        # Compute contraction certificates
        alphavec = np.array([self.alphas[pi] for pi in self.piids])
        slopeUB = slope_upper_bound(alphavec, self.K)
        gapLB = gap_lower_bound(slopeUB)
        
        # Initialize new state
        xnew = np.zeros_like(x)
        touched = []
        
        # Process each π-atom
        for i, pi in enumerate(self.piids):
            # Extract π-atom coefficients
            indices = self.grid.indices(pi)
            c = x[indices]
            
            # Compute local proposal
            prop = self.proposer(c)
            
            # Get ACE parameters for this atom (slice weights to atom size)
            w = self.weights[pi][indices] if len(self.weights[pi]) > len(indices) else self.weights[pi]
            tau = self.taus[pi]
            
            # Project onto ACE safety set
            csafe, lam = project_weighted_l1_ball(prop, w, tau)
            
            # Check if atom was modified
            if np.linalg.norm(csafe - c) > 1e-14:
                touched.append(pi)
                
                # Emit ledger entry if ledger is configured
                if self.ledger is not None:
                    record = {
                        "step": self.step_count,
                        "pi": list(pi),
                        "alpha": float(self.alphas[pi]),
                        "tau": float(tau),
                        "lambda_soft": float(lam),
                        "l1_weight_sum": float(np.sum(w * np.abs(csafe))),
                        "change_norm": float(np.linalg.norm(csafe - c)),
                    }
                    self.ledger.append(record)
            
            # Place projected coefficients into new state
            xnew[indices] = csafe
        
        self.step_count += 1
        
        return {
            "xnew": xnew,
            "SlopeUB": slopeUB,
            "GapLB": gapLB,
            "touched": touched,
            "num_touched": len(touched),
            "step": self.step_count - 1,
        }
    
    def run(self, x0: np.ndarray, num_steps: int) -> Dict[str, Any]:
        """
        Run kernel for multiple steps.
        
        Args:
            x0: Initial state
            num_steps: Number of steps to run
        
        Returns:
            Dictionary with trajectory and statistics
        """
        x = x0.copy()
        trajectory = [x.copy()]
        touched_history = []
        slope_history = []
        gap_history = []
        
        for _ in range(num_steps):
            result = self.step(x)
            x = result["xnew"]
            trajectory.append(x.copy())
            touched_history.append(result["num_touched"])
            slope_history.append(result["SlopeUB"])
            gap_history.append(result["GapLB"])
        
        return {
            "trajectory": trajectory,
            "final_state": x,
            "touched_history": touched_history,
            "slope_history": slope_history,
            "gap_history": gap_history,
            "total_steps": num_steps,
        }
