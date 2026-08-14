import pytest
from genesis_governance.tether.metric import compute_tau
from genesis_governance.governance.review import generate_resistance_certificate
from genesis_governance.schemas.shrapnel import ShrapnelMap

def test_tau_calculation_boundaries():
    # Perfect coverage, zero drift
    tau = compute_tau(coverage=1.0, required_coverage=1.0, drift_norm=0.0, epsilon_x=1.0)
    assert tau == 1.0
    
    # Zero coverage
    tau = compute_tau(coverage=0.0, required_coverage=1.0, drift_norm=0.0, epsilon_x=1.0)
    assert tau == 0.0
    
    # Drift exceeds epsilon
    tau = compute_tau(coverage=1.0, required_coverage=1.0, drift_norm=1.5, epsilon_x=1.0)
    assert tau == 0.0
    
    # Half coverage, half drift
    tau = compute_tau(coverage=0.5, required_coverage=1.0, drift_norm=0.5, epsilon_x=1.0)
    assert tau == 0.25 # 0.5 * (1.0 - 0.5)

def test_certificate_issuance_logic():
    # Map with high tau and high coverage
    smap = ShrapnelMap(
        fragments=[],
        overall_tau=0.85,
        coverage=0.9
    )
    cert = generate_resistance_certificate(smap)
    assert cert is not None
    assert "0.90" in cert.scope
    
    # Low tau
    smap_low_tau = ShrapnelMap(
        fragments=[],
        overall_tau=0.5,
        coverage=0.9
    )
    assert generate_resistance_certificate(smap_low_tau) is None
    
    # Low coverage
    smap_low_cov = ShrapnelMap(
        fragments=[],
        overall_tau=0.85,
        coverage=0.5
    )
    assert generate_resistance_certificate(smap_low_cov) is None
