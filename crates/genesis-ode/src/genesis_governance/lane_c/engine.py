import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState

class LaneCCore(ScalarCore):
    """
    Lane C - Semiconductor Persistence Substrate (ADR-008).
    Extends Track A with threshold-sensitive switching and hysteresis.
    """
    
    def __init__(
        self,
        alpha_on: float = 0.1,
        alpha_off: float = 0.02,
        gamma_on: float = 0.1,
        gamma_off: float = 0.5,
        **kwargs
    ):
        super().__init__(**kwargs)
        self.alpha_on = alpha_on
        self.alpha_off = alpha_off
        self.gamma_on = gamma_on
        self.gamma_off = gamma_off

    def derivative(self, state: SurfaceState, external_coupling: float = 0.0) -> float:
        """
        Computes dCx/dt with state-dependent parameters.
        """
        # Select alpha and gamma based on logical state
        alpha = self.alpha_on if state.logical_state == "ON" else self.alpha_off
        gamma = self.gamma_on if state.logical_state == "ON" else self.gamma_off
        
        cx = state.coherence
        cx_star = state.stability_threshold
        gx = state.grounding
        s_eff = state.effective_stress
        ax = state.alignment
        
        # dCx/dt = alpha(Cx* - Cx) + beta*Gx - gamma*S_eff + eta*Ax + kappa*sum(wj(Cj-Ci)) - delta
        dc_dt = (
            alpha * (cx_star - cx) +
            self.beta * gx -
            gamma * s_eff +
            self.eta * ax +
            external_coupling -
            self.delta
        )
        return dc_dt

    def step(self, state: SurfaceState, dt: float, next_s_eff: float, external_coupling: float = 0.0) -> SurfaceState:
        """
        Performs Euler step with threshold switching.
        """
        # 1. Update Logical State (Hysteresis)
        v_th = state.switching_threshold or 0.5
        delta = state.hysteresis_band or 0.05
        current_logic = state.logical_state or "ON"
        
        new_logic = current_logic
        if next_s_eff > v_th + delta:
            new_logic = "OFF"
        elif next_s_eff < v_th - delta:
            new_logic = "ON"
            
        # 2. Compute Derivative using current logic
        temp_state = state.model_copy(update={"logical_state": new_logic})
        dc_dt = self.derivative(temp_state, external_coupling)
        
        new_coherence = state.coherence + dc_dt * dt
        new_coherence = max(0.0, min(new_coherence, state.stability_threshold))
        
        # 3. Update Impedance
        stress_state = temp_state.model_copy(update={"effective_stress": next_s_eff})
        imp_metrics = self.compute_impedance(stress_state)
        
        return state.model_copy(update={
            "coherence": new_coherence,
            "effective_stress": next_s_eff,
            "logical_state": new_logic,
            "impedance": imp_metrics["impedance"],
            "kinematic_drag": imp_metrics["kinematic_drag"],
            "timestamp": state.timestamp + dt
        })
