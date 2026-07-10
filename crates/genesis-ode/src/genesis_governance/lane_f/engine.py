import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState

class LaneFCore(ScalarCore):
    """
    Lane F - Biological Persistence Substrate (ADR-014).
    Models vitality and homeostatic coherence with adaptive recovery.
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
        Computes dC_F/dt = alpha(C_F* - C_F) - gamma*S_eff*C_F + beta(1 - C_F)(C_F* - C_F) + coupling - delta
        """
        c_f = state.coherence
        c_f_star = state.stability_threshold
        s_eff = state.effective_stress
        
        # dC/dt = alpha(Cx* - Cx) - gamma*S_eff*Cx + beta(1-Cx)(Cx* - Cx) + coupling - delta
        dc_dt = (
            self.alpha * (c_f_star - c_f) -
            self.gamma * s_eff * c_f +
            self.beta * (1.0 - c_f) * (c_f_star - c_f) +
            external_coupling -
            self.delta
        )
        return dc_dt

    def step(self, state: SurfaceState, dt: float, next_s_eff: float, external_coupling: float = 0.0) -> SurfaceState:
        """
        Performs Euler step for biological adaptive dynamics.
        """
        dc_dt = self.derivative(state, external_coupling)
        
        new_coherence = state.coherence + dc_dt * dt
        # Vitality is bounded [0, Cx*]
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
