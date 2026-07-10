import numpy as np
from genesis_governance.core.scalar_surface import ScalarCore
from genesis_governance.types import SurfaceState

class LaneECore(ScalarCore):
    """
    Lane E - Quantum Persistence Substrate (ADR-013).
    Models complex-valued quantum coherence dynamics.
    """
    
    def __init__(
        self,
        alpha: float = 0.1,
        gamma_decoh: float = 0.05,
        omega: float = 0.1,
        lambda_meas: float = 0.05,
        **kwargs
    ):
        super().__init__(**kwargs)
        self.alpha = alpha
        self.gamma_decoh = gamma_decoh
        self.omega = omega
        self.lambda_meas = lambda_meas

    def derivative(self, state: SurfaceState, phase: float, external_coupling: float = 0.0) -> complex:
        """
        Computes dC_Q/dt as a complex-valued derivative.
        C_Q = r * exp(i*phase)
        """
        # Complex coherence state
        c_q = state.coherence * np.exp(1j * phase)
        cx_star = state.stability_threshold
        s_meas = state.effective_stress # S_meas(t)
        
        # dC_Q/dt = alpha(C_Q* - C_Q) - gamma*C_Q - i*omega*C_Q - lambda*S_meas*C_Q + coupling
        # Note: Coupling is treated as real here for simplicity, or complex in future
        coupling = external_coupling # kappa * sum(...)
        
        # C_Q* is the target amplitude (scalar)
        term1 = self.alpha * (cx_star - c_q)
        term2 = -self.gamma_decoh * c_q
        term3 = -1j * self.omega * c_q
        term4 = -self.lambda_meas * s_meas * c_q
        term5 = coupling
        
        return term1 + term2 + term3 + term4 + term5

    def step(self, state: SurfaceState, phase: float, dt: float, next_s_eff: float, external_coupling: float = 0.0) -> tuple[SurfaceState, float]:
        """
        Euler integration for complex coherence.
        """
        dc_dt = self.derivative(state, phase, external_coupling)
        
        # Complex integration: C_Q(t+dt) = C_Q(t) + (dC_Q/dt)*dt
        c_q_old = state.coherence * np.exp(1j * phase)
        c_q_new = c_q_old + (dc_dt * dt)
        
        # Extract new amplitude and phase
        new_amplitude = abs(c_q_new)
        new_phase = float(np.angle(c_q_new))
        
        # Bound amplitude [0, Cx*]
        new_amplitude = max(0.0, min(new_amplitude, state.stability_threshold))
        
        # Return updated state and phase
        new_state = state.model_copy(update={
            "coherence": new_amplitude,
            "effective_stress": next_s_eff,
            "timestamp": state.timestamp + dt
        })
        return new_state, new_phase

