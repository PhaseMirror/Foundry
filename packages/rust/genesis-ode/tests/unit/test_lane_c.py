import pytest
from genesis_governance.lane_c.engine import LaneCCore
from genesis_governance.types import SurfaceState

def test_lane_c_switching():
    core = LaneCCore(alpha_on=0.1, alpha_off=0.01)
    
    # State near threshold
    state = SurfaceState(
        substrate="Semi",
        coherence=1.0,
        stability_threshold=1.0,
        effective_stress=0.4,
        switching_threshold=0.5,
        hysteresis_band=0.05,
        logical_state="ON"
    )
    
    # Stress remains below V_th - delta (0.4 < 0.45) -> stays ON
    next_state = core.step(state, dt=0.1, next_s_eff=0.4)
    assert next_state.logical_state == "ON"
    
    # Stress goes above V_th + delta (0.6 > 0.55) -> switches OFF
    next_state = core.step(state, dt=0.1, next_s_eff=0.6)
    assert next_state.logical_state == "OFF"
    
    # Stress stays in hysteresis band (0.5) while ON -> stays ON
    next_state = core.step(state, dt=0.1, next_s_eff=0.5)
    assert next_state.logical_state == "ON"
    
    # Stress stays in hysteresis band (0.5) while OFF -> stays OFF
    state_off = state.model_copy(update={"logical_state": "OFF"})
    next_state = core.step(state_off, dt=0.1, next_s_eff=0.5)
    assert next_state.logical_state == "OFF"

def test_lane_c_dynamics_shift():
    # Recovery should be slower in OFF state
    # Setting delta_p=0 (from base ScalarCore) to make calculations simple
    core = LaneCCore(alpha_on=0.5, alpha_off=0.01, delta=0.0)
    
    state_on = SurfaceState(
        substrate="Semi",
        coherence=0.5,
        stability_threshold=1.0,
        effective_stress=0.5,
        logical_state="ON"
    )
    
    state_off = state_on.model_copy(update={"logical_state": "OFF"})
    
    # Stress at 0.5 stays in hysteresis band, preserving ON/OFF
    # Derivative will use initial effective_stress = 0.5
    next_on = core.step(state_on, dt=1.0, next_s_eff=0.5)
    next_off = core.step(state_off, dt=1.0, next_s_eff=0.5)
    
    # In ON state: dC/dt = 0.5*(1.0-0.5) - gamma_on*0.5 = 0.25 - 0.1*0.5 = 0.20
    # next_on.coherence = 0.5 + 0.2 = 0.7
    
    # In OFF state: dC/dt = 0.01*(1.0-0.5) - gamma_off*0.5 = 0.005 - 0.5*0.5 = -0.245
    # next_off.coherence = 0.5 - 0.245 = 0.255
    
    assert next_on.coherence > next_off.coherence
    assert next_on.coherence == pytest.approx(0.7)
    assert next_off.coherence == pytest.approx(0.255)
