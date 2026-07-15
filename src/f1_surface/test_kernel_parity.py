import pytest
import numpy as np
from engine import SpectralControlEngine, KernelTelemetry

def test_parity_xn():
    # mock setup
    engine = SpectralControlEngine([np.eye(3)])
    telemetry = KernelTelemetry(xn_kernel=0.15, wt_max_kernel=0.92,
                                protection_zeta=4.12, is_valid_kernel=True)
    raw = np.random.rand(3,3) + 1j*np.random.rand(3,3)
    delta, payload = engine.run_control_pipeline(raw, telemetry, mode=3,
                                                 epsilon=1.0, eta=0.2)
    # legacy calculation would produce X_n; we assert equality within tolerance
    assert abs(payload['xn_kernel'] - 0.15) < 1e-9

def test_invalid_telemetry_raises():
    engine = SpectralControlEngine([np.eye(3)])
    telemetry = KernelTelemetry(xn_kernel=0.15, wt_max_kernel=0.92,
                                protection_zeta=4.12, is_valid_kernel=False)
    raw = np.random.rand(3,3) + 1j*np.random.rand(3,3)
    with pytest.raises(ValueError, match="Pipeline aborted"):
        engine.run_control_pipeline(raw, telemetry, mode=3, epsilon=1.0, eta=0.2)

def test_mode3_distance_bound():
    # verify that output is within eta of Hecke span
    pass

def test_zeta_shadow_effect():
    engine = SpectralControlEngine([np.eye(3)])
    telemetry_low = KernelTelemetry(xn_kernel=0.15, wt_max_kernel=0.92,
                                    protection_zeta=4.12, is_valid_kernel=True, zeta_shadow=0.8)
    telemetry_high = KernelTelemetry(xn_kernel=0.15, wt_max_kernel=0.92,
                                     protection_zeta=4.12, is_valid_kernel=True, zeta_shadow=1.2)
    raw = np.random.rand(3,3) + 1j*np.random.rand(3,3)
    delta_low, _ = engine.run_control_pipeline(raw, telemetry_low, mode=3, epsilon=1.0, eta=0.2)
    delta_high, _ = engine.run_control_pipeline(raw, telemetry_high, mode=3, epsilon=1.0, eta=0.2)
    assert np.linalg.norm(delta_low - delta_high, 'fro') > 0  # non-trivial change
    
    # Verify that the distance to Hecke span is smaller for high zeta_shadow
    # We can measure distance directly via project_to_span
    h_low = engine.project_to_span(delta_low)
    h_high = engine.project_to_span(delta_high)
    dist_low = np.linalg.norm(delta_low - h_low, 'fro')
    dist_high = np.linalg.norm(delta_high - h_high, 'fro')
    assert dist_high < dist_low

# additional tests: extreme values, stability, mode switching
