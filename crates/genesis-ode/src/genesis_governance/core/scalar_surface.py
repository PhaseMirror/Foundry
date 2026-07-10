import numpy as np
from typing import Dict, List
from genesis_governance.types import SurfaceState

class ScalarCore:
    """
    Canonical Scalar Core Engine (Lane A) as per ADR-001.
    Implements the substrate-indexed persistence ODE and impedance bridge.
    """
    
    def __init__(
        self,
        alpha: float = 0.1,
        beta: float = 0.05,
        gamma: float = 0.1,
        eta: float = 0.05,
        kappa: float = 0.0,
        delta: float = 0.01,
        lambda_param: float = 0.1
    ):
        self.alpha = alpha
        self.beta = beta
        self.gamma = gamma
        self.eta = eta
        self.kappa = kappa
        self.delta = delta
        self.lambda_param = lambda_param
        self._validate_params()

    def _validate_params(self):
        """
        Ensures parameters are within Track A canonical bounds.
        """
        if any(p < 0 for p in [self.alpha, self.beta, self.gamma, self.eta, self.delta, self.lambda_param]):
            raise ValueError("Track A invariants: Dissipative and coupling parameters must be non-negative.")
        if self.alpha > 1.0:
            raise ValueError("Track A invariants: Alpha (recovery rate) > 1.0 risk numerical instability.")

    def compute_impedance(self, state: SurfaceState) -> Dict[str, float]:
        """
        Computes rho, Omega, and D_k based on effective stress.
        """
        cx_star = state.stability_threshold
        s_eff = state.effective_stress
        
        # rho_X = C_X* (1 - e^(-lambda * S_eff))
        rho = cx_star * (1 - np.exp(-self.lambda_param * s_eff))
        
        # Avoid division by zero and imaginary numbers near saturation
        ratio = min(rho / cx_star, 0.999) 
        
        # Omega_X = 1 / sqrt(1 - (rho/cx_star)^2)
        omega = 1.0 / np.sqrt(1.0 - ratio**2)
        
        # D_k,X = Omega_X - 1
        drag = omega - 1.0
        
        return {"impedance": omega, "kinematic_drag": drag}

    def derivative(self, state: SurfaceState, external_coupling: float = 0.0) -> float:
        """
        Computes dCx/dt.
        """
        cx = state.coherence
        cx_star = state.stability_threshold
        gx = state.grounding
        s_eff = state.effective_stress
        ax = state.alignment
        
        # dCx/dt = alpha(Cx* - Cx) + beta*Gx - gamma*S_eff + eta*Ax + kappa*sum(wj(Cj-Ci)) - delta
        dc_dt = (
            self.alpha * (cx_star - cx) +
            self.beta * gx -
            self.gamma * s_eff +
            self.eta * ax +
            external_coupling - # Already includes kappa * sum(...)
            self.delta
        )
        return dc_dt

    def step(self, state: SurfaceState, dt: float, next_s_eff: float, external_coupling: float = 0.0) -> SurfaceState:
        """
        Performs a single Euler integration step.
        """
        dc_dt = self.derivative(state, external_coupling)
        
        new_coherence = state.coherence + dc_dt * dt
        # Persistence is bounded [0, Cx*]
        new_coherence = max(0.0, min(new_coherence, state.stability_threshold))
        
        # Update impedance based on the next stress state
        # In a real simulation, S_eff evolves too.
        temp_state = state.model_copy(update={"effective_stress": next_s_eff})
        imp_metrics = self.compute_impedance(temp_state)
        
        return SurfaceState(
            substrate=state.substrate,
            coherence=new_coherence,
            stability_threshold=state.stability_threshold,
            effective_stress=next_s_eff,
            grounding=state.grounding,
            alignment=state.alignment,
            impedance=imp_metrics["impedance"],
            kinematic_drag=imp_metrics["kinematic_drag"],
            timestamp=state.timestamp + dt
        )
