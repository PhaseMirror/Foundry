import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState

class LaneGCore(ScalarCore):
    """
    Lane G - Ecological Composite Persistence Substrate (ADR-015).
    Models resilience with logistic growth and composite coupling.
    """
    
    def __init__(
        self,
        alpha: float = 0.1,
        gamma: float = 0.1,
        beta: float = 0.05,
        **kwargs
    ):
        super().__init__(**kwargs)
        self.alpha = alpha
        self.gamma = gamma
        self.beta = beta

    def derivative(self, state: SurfaceState, external_coupling: float = 0.0) -> float:
        """
        Computes dC_G/dt = alpha(C_G* - C_G) - gamma*S_eff*C_G + beta*C_G(1 - C_G/C_G*) + coupling - delta
        """
        c_g = state.coherence
        c_g_star = state.stability_threshold
        s_eff = state.effective_stress
        
        # dC/dt = alpha(Cx* - Cx) - gamma*S_eff*Cx + beta*Cx(1 - Cx/Cx*) + coupling - delta
        # Avoid division by zero in logistic term
        logistic_term = self.beta * c_g * (1.0 - (c_g / max(c_g_star, 1e-6)))
        
        dc_dt = (
            self.alpha * (c_g_star - c_g) -
            self.gamma * s_eff * c_g +
            logistic_term +
            external_coupling -
            self.delta
        )
        return dc_dt

    def step(self, state: SurfaceState, dt: float, next_s_eff: float, external_coupling: float = 0.0) -> SurfaceState:
        """
        Performs Euler step for ecological composite dynamics.
        """
        dc_dt = self.derivative(state, external_coupling)
        
        new_coherence = state.coherence + dc_dt * dt
        # Resilience is bounded [0, Cx*]
        new_coherence = max(0.0, min(new_coherence, state.stability_threshold))
        
        # Update Impedance based on stress
        stress_state = state.model_copy(update={"effective_stress": next_s_eff})
        imp_metrics = self.compute_impedance(stress_state)
        
        return state.model_copy(update={
            "coherence": new_coherence,
            "effective_stress": next_s_eff,
            "impedance": imp_metrics["impedance"],
            "kinematic_drag": imp_metrics["kinematic_drag"],
            "timestamp": state.timestamp + dt
        })
