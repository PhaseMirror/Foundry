import pytest
import numpy as np
import logging

from .engine import (
    SpectralControlEngine,
    KernelTelemetry,
    mock_zeno_compute_kernel_telemetry,
    legacy_drift_metrics,
    gauge_fix,
    ArakelovParams,
    KernelTelemetryError,
    ParityContractViolation,
    InvalidTelemetryError,
    FeasibilityMapError,
    OperatorShapeError,
)
from .riemann_siegel import find_zeros_refined, hardy_z_block


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def engine_3x3():
    return SpectralControlEngine([np.eye(3)])


@pytest.fixture
def base_telemetry():
    return KernelTelemetry(
        xn_kernel=0.15,
        wt_max_kernel=0.92,
        protection_zeta=4.12,
        is_valid_kernel=True,
    )


@pytest.fixture
def random_hermitian():
    rng = np.random.default_rng(42)
    A = rng.standard_normal((3, 3)) + 1j * rng.standard_normal((3, 3))
    return 0.5 * (A + A.conj().T)


# ---------------------------------------------------------------------------
# 1. Parity runs: legacy drift vs kernel telemetry
# ---------------------------------------------------------------------------

def test_parity_legacy_vs_kernel_xn(random_hermitian):
    X_n, W_t, R_t = legacy_drift_metrics(random_hermitian)
    telemetry = mock_zeno_compute_kernel_telemetry(
        xn_kernel=X_n,
        wt_max_kernel=W_t,
        protection_zeta=R_t,
        is_valid_kernel=True,
        parity_mode=True,
        xn_reference=X_n,
        include_zero_shadow=False,
    )
    assert abs(telemetry.xn_kernel - X_n) < 1e-9


def test_parity_legacy_vs_kernel_wt(random_hermitian):
    X_n, W_t, R_t = legacy_drift_metrics(random_hermitian)
    telemetry = mock_zeno_compute_kernel_telemetry(
        xn_kernel=X_n,
        wt_max_kernel=W_t,
        protection_zeta=R_t,
        is_valid_kernel=True,
        parity_mode=True,
        xn_reference=X_n,
        include_zero_shadow=False,
    )
    assert abs(telemetry.wt_max_kernel - W_t) < 1e-9


# ---------------------------------------------------------------------------
# 2. Boundary cases
# ---------------------------------------------------------------------------

def test_invalid_telemetry_raises(engine_3x3, base_telemetry):
    invalid = KernelTelemetry(
        xn_kernel=base_telemetry.xn_kernel,
        wt_max_kernel=base_telemetry.wt_max_kernel,
        protection_zeta=base_telemetry.protection_zeta,
        is_valid_kernel=False,
    )
    raw = np.random.rand(3, 3) + 1j * np.random.rand(3, 3)
    with pytest.raises(ValueError, match="Pipeline aborted"):
        engine_3x3.run_control_pipeline(raw, invalid, mode=3, epsilon=1.0, eta=0.2)


def test_extreme_xn_kernel_near_one():
    telemetry = mock_zeno_compute_kernel_telemetry(
        xn_kernel=0.999999999,
        wt_max_kernel=0.5,
        protection_zeta=1.0,
        is_valid_kernel=True,
        include_zero_shadow=False,
    )
    assert telemetry.xn_kernel == pytest.approx(0.999999999)


def test_negative_protection_zeta_rejected():
    with pytest.raises(InvalidTelemetryError, match="protection_zeta must be non-negative"):
        telemetry = KernelTelemetry(
            xn_kernel=0.1,
            wt_max_kernel=0.5,
            protection_zeta=-1.0,
            is_valid_kernel=True,
        )
        telemetry.validate()


def test_wt_max_kernel_above_one_rejected():
    with pytest.raises(InvalidTelemetryError, match="wt_max_kernel must be in"):
        telemetry = KernelTelemetry(
            xn_kernel=0.1,
            wt_max_kernel=1.5,
            protection_zeta=1.0,
            is_valid_kernel=True,
        )
        telemetry.validate()


# ---------------------------------------------------------------------------
# 3. Mode switching
# ---------------------------------------------------------------------------

def test_mode_switch_same_proposal(engine_3x3, base_telemetry, random_hermitian):
    raw = random_hermitian
    epsilon = 1.0
    eta = 0.2

    delta1, _ = engine_3x3.run_control_pipeline(raw, base_telemetry, mode=1, epsilon=epsilon, eta=eta)
    delta2, _ = engine_3x3.run_control_pipeline(raw, base_telemetry, mode=2, epsilon=epsilon, eta=eta)
    delta3, _ = engine_3x3.run_control_pipeline(raw, base_telemetry, mode=3, epsilon=epsilon, eta=eta)

    for delta in [delta1, delta2, delta3]:
        assert np.allclose(delta, delta.conj().T), "Output must be Hermitian"
        assert np.linalg.norm(delta, 'fro') <= epsilon + 1e-9, "Frobenius norm must respect epsilon"

    dist3 = engine_3x3.distance_to_span(delta3)
    assert dist3 <= eta + 1e-9, "Mode 3 distance to span must respect eta"


def test_mode3_distance_bound_analytic(engine_3x3, base_telemetry):
    rng = np.random.default_rng(0)
    raw = rng.standard_normal((3, 3)) + 1j * rng.standard_normal((3, 3))
    raw = 0.5 * (raw + raw.conj().T)
    eta = 0.5
    _, payload = engine_3x3.run_control_pipeline(
        raw, base_telemetry, mode=3, epsilon=2.0, eta=eta
    )
    assert payload["distance_to_span"] <= eta + 1e-9


# ---------------------------------------------------------------------------
# 4. Stability: small perturbations
# ---------------------------------------------------------------------------

def test_stability_small_perturbation(engine_3x3, base_telemetry):
    rng = np.random.default_rng(7)
    raw1 = rng.standard_normal((3, 3)) + 1j * rng.standard_normal((3, 3))
    raw1 = 0.5 * (raw1 + raw1.conj().T)

    eps = 1e-6
    raw2 = raw1 + eps * rng.standard_normal((3, 3)) + 1j * eps * rng.standard_normal((3, 3))
    raw2 = 0.5 * (raw2 + raw2.conj().T)

    delta1, payload1 = engine_3x3.run_control_pipeline(raw1, base_telemetry, mode=3, epsilon=1.0, eta=0.2)
    delta2, payload2 = engine_3x3.run_control_pipeline(raw2, base_telemetry, mode=3, epsilon=1.0, eta=0.2)

    diff_norm = float(np.linalg.norm(delta1 - delta2, 'fro'))
    assert diff_norm < 1.0, "Small input perturbations should produce bounded output changes"


# ---------------------------------------------------------------------------
# 5. Hermitian enforcement
# ---------------------------------------------------------------------------

def test_hermitian_enforced_all_modes(engine_3x3, base_telemetry):
    rng = np.random.default_rng(99)
    raw = rng.standard_normal((3, 3)) + 1j * rng.standard_normal((3, 3))
    for mode in [1, 2, 3]:
        delta, _ = engine_3x3.run_control_pipeline(raw, base_telemetry, mode=mode, epsilon=1.0, eta=0.2)
        assert np.allclose(delta, delta.conj().T), f"Mode {mode} output must be Hermitian"


def test_non_square_input_rejected(engine_3x3, base_telemetry):
    raw = np.random.rand(2, 3) + 1j * np.random.rand(2, 3)
    with pytest.raises(OperatorShapeError):
        engine_3x3.run_control_pipeline(raw, base_telemetry, mode=1, epsilon=1.0)


# ---------------------------------------------------------------------------
# 6. gaugeFix
# ---------------------------------------------------------------------------

def test_gauge_fix_produces_positive_params(base_telemetry):
    params = gauge_fix(base_telemetry)
    assert isinstance(params, ArakelovParams)
    assert params.gamma > 0.0
    assert params.scale > 0.0
    assert params.is_normalized is True


def test_gauge_fix_gamma_matches_formula(base_telemetry):
    params = gauge_fix(base_telemetry)
    expected_gamma = np.exp(-base_telemetry.protection_zeta)
    assert params.gamma == pytest.approx(expected_gamma)


def test_gauge_fix_invalid_telemetry_raises():
    bad = KernelTelemetry(
        xn_kernel=-0.1,
        wt_max_kernel=0.5,
        protection_zeta=1.0,
        is_valid_kernel=True,
    )
    with pytest.raises(InvalidTelemetryError):
        gauge_fix(bad)


# ---------------------------------------------------------------------------
# 7. Serialization round-trip
# ---------------------------------------------------------------------------

def test_telemetry_serialization_round_trip(base_telemetry):
    data = base_telemetry.to_dict()
    restored = KernelTelemetry.from_dict(data)
    assert restored == base_telemetry


# ---------------------------------------------------------------------------
# 8. Parity contract violation
# ---------------------------------------------------------------------------

def test_parity_contract_violation_raises():
    with pytest.raises(ParityContractViolation):
        mock_zeno_compute_kernel_telemetry(
            xn_kernel=0.1,
            wt_max_kernel=0.5,
            protection_zeta=1.0,
            is_valid_kernel=True,
            parity_mode=True,
            xn_reference=0.2,
            include_zero_shadow=False,
        )


# ---------------------------------------------------------------------------
# 9. Existing analytic-shadow tests
# ---------------------------------------------------------------------------

def test_zero_shadow_populated():
    telemetry = mock_zeno_compute_kernel_telemetry(
        xn_kernel=0.15,
        wt_max_kernel=0.92,
        protection_zeta=4.12,
        is_valid_kernel=True,
        include_zero_shadow=True,
        zero_shadow_window=(14.0, 30.0),
        search_step=0.2,
    )
    assert telemetry.first_zero_approx > 0.0
    assert telemetry.mean_spacing > 0.0
    assert 0.0 <= telemetry.gue_deviation <= 1.0


def test_parity_preserved_with_shadow():
    telemetry = mock_zeno_compute_kernel_telemetry(
        xn_kernel=0.123456789,
        wt_max_kernel=0.92,
        protection_zeta=4.12,
        is_valid_kernel=True,
        parity_mode=True,
        xn_reference=0.123456789,
        include_zero_shadow=True,
        zero_shadow_window=(14.0, 25.0),
        search_step=0.2,
    )
    assert abs(telemetry.xn_kernel - 0.123456789) < 1e-9
    assert telemetry.first_zero_approx > 0.0


def test_block_path_coverage():
    zeros = find_zeros_refined(14.0, 20.0, search_step=0.2, newton_iters=8)
    assert len(zeros) > 0
    for z in zeros:
        assert 14.0 <= z <= 20.0
        assert abs(hardy_z_block(z)) < 0.1


def test_end_to_end_pipeline_accepts_shadow(engine_3x3):
    telemetry = mock_zeno_compute_kernel_telemetry(
        xn_kernel=0.15,
        wt_max_kernel=0.92,
        protection_zeta=4.12,
        is_valid_kernel=True,
        include_zero_shadow=True,
        zero_shadow_window=(14.0, 30.0),
        search_step=0.2,
    )
    raw = np.random.rand(3, 3) + 1j * np.random.rand(3, 3)
    delta, payload = engine_3x3.run_control_pipeline(raw, telemetry, mode=3, epsilon=1.0, eta=0.2)
    assert abs(payload['xn_kernel'] - 0.15) < 1e-9
    assert payload['first_zero_approx'] == pytest.approx(telemetry.first_zero_approx)
    assert payload['mean_spacing'] == pytest.approx(telemetry.mean_spacing)
    assert payload['gue_deviation'] == pytest.approx(telemetry.gue_deviation)


def test_effective_eta_modulated_by_analytic_shadow(engine_3x3):
    base = KernelTelemetry(
        xn_kernel=0.1,
        wt_max_kernel=0.9,
        protection_zeta=2.0,
        is_valid_kernel=True,
        first_zero_approx=14.1347,
        mean_spacing=1.0,
        gue_deviation=0.0,
        zeta_shadow=1.0,
        telemetry_version=2,
    )
    shadow = KernelTelemetry(
        xn_kernel=0.1,
        wt_max_kernel=0.9,
        protection_zeta=2.0,
        is_valid_kernel=True,
        first_zero_approx=14.1347,
        mean_spacing=0.8,
        gue_deviation=0.3,
        zeta_shadow=1.0,
        telemetry_version=2,
    )
    raw = np.random.rand(3, 3) + 1j * np.random.rand(3, 3)
    _, payload_base = engine_3x3.run_control_pipeline(raw, base, mode=3, epsilon=1.0, eta=0.2)
    _, payload_shadow = engine_3x3.run_control_pipeline(raw, shadow, mode=3, epsilon=1.0, eta=0.2)
    assert payload_shadow['effective_eta'] < payload_base['effective_eta']
    assert payload_shadow['effective_eta'] == pytest.approx(
        0.2 / (1.0 + 1.0) * 0.8 * (1.0 - 0.3 * 0.15)
    )


# ---------------------------------------------------------------------------
# 10. Constraint set respect (deterministic seeds)
# ---------------------------------------------------------------------------

def test_mode1_frobenius_ball():
    engine = SpectralControlEngine([np.eye(3)])
    telemetry = KernelTelemetry(xn_kernel=0.0, wt_max_kernel=0.5, protection_zeta=1.0, is_valid_kernel=True)
    rng = np.random.default_rng(123)
    raw = rng.standard_normal((3, 3)) + 1j * rng.standard_normal((3, 3))
    raw = 0.5 * (raw + raw.conj().T)
    delta, _ = engine.run_control_pipeline(raw, telemetry, mode=1, epsilon=1.5)
    assert np.linalg.norm(delta, 'fro') <= 1.5 + 1e-9


def test_mode2_hecke_span_projection():
    engine = SpectralControlEngine([np.eye(3)])
    telemetry = KernelTelemetry(xn_kernel=0.0, wt_max_kernel=0.5, protection_zeta=1.0, is_valid_kernel=True)
    rng = np.random.default_rng(456)
    raw = rng.standard_normal((3, 3)) + 1j * rng.standard_normal((3, 3))
    raw = 0.5 * (raw + raw.conj().T)
    delta, _ = engine.run_control_pipeline(raw, telemetry, mode=2, epsilon=1.5)
    residual = delta - engine.project_to_span(delta)
    assert np.linalg.norm(residual, 'fro') < 1e-9


def test_mode3_near_arithmetic_fidelity():
    engine = SpectralControlEngine([np.eye(3)])
    telemetry = KernelTelemetry(xn_kernel=0.0, wt_max_kernel=0.5, protection_zeta=1.0, is_valid_kernel=True)
    rng = np.random.default_rng(789)
    raw = rng.standard_normal((3, 3)) + 1j * rng.standard_normal((3, 3))
    raw = 0.5 * (raw + raw.conj().T)
    delta, payload = engine.run_control_pipeline(raw, telemetry, mode=3, epsilon=1.5, eta=0.3)
    assert payload["distance_to_span"] <= 0.3 + 1e-9
    assert np.linalg.norm(delta, 'fro') <= 1.5 + 1e-9


# ---------------------------------------------------------------------------
# 11. NaN / Inf guarding
# ---------------------------------------------------------------------------

def test_nan_input_rejected():
    engine = SpectralControlEngine([np.eye(3)])
    telemetry = KernelTelemetry(xn_kernel=0.1, wt_max_kernel=0.5, protection_zeta=1.0, is_valid_kernel=True)
    raw = np.full((3, 3), np.nan, dtype=complex)
    with pytest.raises((FeasibilityMapError, FloatingPointError, ValueError)):
        engine.run_control_pipeline(raw, telemetry, mode=1, epsilon=1.0)


def test_inf_input_rejected():
    engine = SpectralControlEngine([np.eye(3)])
    telemetry = KernelTelemetry(xn_kernel=0.1, wt_max_kernel=0.5, protection_zeta=1.0, is_valid_kernel=True)
    raw = np.full((3, 3), np.inf, dtype=complex)
    with pytest.raises((FeasibilityMapError, FloatingPointError, ValueError)):
        engine.run_control_pipeline(raw, telemetry, mode=1, epsilon=1.0)
