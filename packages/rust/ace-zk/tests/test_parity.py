"""
Mathematical parity tests: Python Track A ↔ Rust Track B Type bindings

These tests validate that the Rust FFI bindings produce mathematically equivalent
outputs to the Python reference implementations, ensuring cross-platform trust
and cryptographic soundness of the Type system.

Requires: ace_zk binary compiled via `maturin develop`
"""

import pytest
import json
from typing import Any

# Import Python Track A types for comparison
import sys
sys.path.insert(0, '../src')
from ace.types import ThetaBase as PyThetaBase, ThetaC6 as PyThetaC6, StepInfo as PyStepInfo

# Import Rust Track B FFI bindings (once compiled)
# from ace_zk import ThetaBase, ThetaC6, StepInfo


class TestThetaBaseEquivalence:
    """Validate ThetaBase Rust ↔ Python parity"""

    def get_golden_params(self) -> dict[str, Any]:
        """Golden test vector matching both Python and Rust implementations"""
        return {
            "epsilon": 0.5,
            "supp_epsilon": 0.05,
            "delta": 1.0,
            "N_0": 100,
            "K": 10,
            "M": 2,
            "beta": 0.8,
            "tau_min": 0.1,
            "alpha_M": 0.95,
            "retry_nonce": 0,
            "wac_mode": "windowed",
        }

    def test_python_construction_valid(self):
        """Python ThetaBase construction with golden vector"""
        params = self.get_golden_params()
        theta_py = PyThetaBase(
            epsilon=params["epsilon"],
            supp_epsilon=params["supp_epsilon"],
            delta=params["delta"],
            N_0=params["N_0"],
            K=params["K"],
            M=params["M"],
            beta=params["beta"],
            tau_min=params["tau_min"],
            alpha_M=params["alpha_M"],
            retry_nonce=params["retry_nonce"],
            wac_mode=params["wac_mode"],
        )

        # Verify fields
        assert theta_py.epsilon == 0.5
        assert theta_py.beta == 0.8
        assert theta_py.wac_mode == "windowed"

    def test_python_invariant_beta_zero(self):
        """Python ThetaBase rejects beta = 0"""
        with pytest.raises(ValueError):
            PyThetaBase(
                epsilon=0.5,
                supp_epsilon=0.05,
                delta=1.0,
                N_0=100,
                K=10,
                M=2,
                beta=0.0,  # Invalid
                tau_min=0.1,
                alpha_M=0.95,
                wac_mode="windowed",
            )

    def test_python_invariant_epsilon_out_of_range(self):
        """Python ThetaBase rejects epsilon outside (0, 1)"""
        with pytest.raises(ValueError):
            PyThetaBase(
                epsilon=1.5,  # Invalid
                supp_epsilon=0.05,
                delta=1.0,
                N_0=100,
                K=10,
                M=2,
                beta=0.8,
                tau_min=0.1,
                alpha_M=0.95,
                wac_mode="windowed",
            )

    def test_python_windowed_m_constraint(self):
        """Python ThetaBase rejects M < 2 for windowed mode"""
        with pytest.raises(ValueError):
            PyThetaBase(
                epsilon=0.5,
                supp_epsilon=0.05,
                delta=1.0,
                N_0=100,
                K=10,
                M=1,  # Invalid for windowed
                beta=0.8,
                tau_min=0.1,
                alpha_M=0.95,
                wac_mode="windowed",
            )

    def test_python_strict_m_constraint(self):
        """Python ThetaBase allows M >= 1 for strict mode"""
        theta = PyThetaBase(
            epsilon=0.5,
            supp_epsilon=0.05,
            delta=1.0,
            N_0=100,
            K=10,
            M=1,  # Valid for strict
            beta=0.8,
            tau_min=0.1,
            alpha_M=0.95,
            wac_mode="strict",
        )
        assert theta.wac_mode == "strict"
        assert theta.M == 1

    def test_python_immutability(self):
        """Python ThetaBase is frozen (immutable)"""
        theta = PyThetaBase(
            epsilon=0.5,
            supp_epsilon=0.05,
            delta=1.0,
            N_0=100,
            K=10,
            M=2,
            beta=0.8,
            tau_min=0.1,
            alpha_M=0.95,
            wac_mode="windowed",
        )

        # Frozen dataclass should prevent field modification
        with pytest.raises(AttributeError):
            theta.epsilon = 0.6


class TestThetaC6Equivalence:
    """Validate ThetaC6 Rust ↔ Python parity"""

    def test_python_construction(self):
        """Python ThetaC6 construction with base + seed"""
        theta_base = PyThetaBase(
            epsilon=0.5,
            supp_epsilon=0.05,
            delta=1.0,
            N_0=100,
            K=10,
            M=2,
            beta=0.8,
            tau_min=0.1,
            alpha_M=0.95,
            wac_mode="windowed",
        )

        shuffle_seed = b"\x01\x02\x03\x04\x05"
        tc6 = PyThetaC6(base=theta_base, shuffle_seed=shuffle_seed)

        assert tc6.base.epsilon == 0.5
        assert tc6.shuffle_seed == shuffle_seed

    def test_python_serialization(self):
        """Python ThetaC6 serializable as dataclass"""
        theta_base = PyThetaBase(
            epsilon=0.5,
            supp_epsilon=0.05,
            delta=1.0,
            N_0=100,
            K=10,
            M=2,
            beta=0.8,
            tau_min=0.1,
            alpha_M=0.95,
            wac_mode="windowed",
        )

        shuffle_seed = b"\x01\x02\x03\x04\x05"
        tc6 = PyThetaC6(base=theta_base, shuffle_seed=shuffle_seed)

        # Serialize to dict (dataclass)
        data = {
            "base": {
                "epsilon": tc6.base.epsilon,
                "supp_epsilon": tc6.base.supp_epsilon,
                "delta": tc6.base.delta,
                "N_0": tc6.base.N_0,
                "K": tc6.base.K,
                "M": tc6.base.M,
                "beta": tc6.base.beta,
                "tau_min": tc6.base.tau_min,
                "alpha_M": tc6.base.alpha_M,
                "retry_nonce": tc6.base.retry_nonce,
                "wac_mode": tc6.base.wac_mode,
            },
            "shuffle_seed": shuffle_seed.hex(),
        }

        # Verify round-trip
        json_str = json.dumps(data)
        restored = json.loads(json_str)
        assert restored["base"]["epsilon"] == 0.5
        assert restored["shuffle_seed"] == "0102030405"


class TestStepInfoEquivalence:
    """Validate StepInfo Rust ↔ Python parity"""

    def test_python_construction(self):
        """Python StepInfo construction"""
        step = PyStepInfo(
            step=1,
            q=0.95,
            epsilon=0.5,
            kkt_residual=1e-6,
            wac_product=0.98,
            xi_telemetry=0.01,
            delta_sigma=0.002,
            delta_M=0.003,
            projected=False,
            residual=1e-7,
        )

        assert step.step == 1
        assert step.q == 0.95
        assert step.projected is False
        assert abs(step.residual - 1e-7) < 1e-15

    def test_python_list_of_steps(self):
        """Python StepInfo trajectory collection"""
        trajectory = []
        for i in range(5):
            step = PyStepInfo(
                step=i,
                q=0.95 ** (i + 1),  # Converging Q
                epsilon=0.5,
                kkt_residual=1e-6 / (i + 1),
                wac_product=0.98,
                xi_telemetry=0.01,
                delta_sigma=0.002,
                delta_M=0.003,
                projected=(i > 2),
                residual=1e-7 / (i + 1),
            )
            trajectory.append(step)

        assert len(trajectory) == 5
        assert trajectory[0].step == 0
        assert trajectory[4].step == 4
        assert trajectory[3].projected is True


class TestParity:
    """High-level parity validation between Python and Rust (once compiled)"""

    @pytest.mark.skip(reason="Requires compiled Rust bindings (maturin develop)")
    def test_rust_theta_base_golden(self):
        """Rust ThetaBase matches Python golden vector construction"""
        # This test will be enabled once ace_zk binary is compiled
        #
        # from ace_zk import ThetaBase
        #
        # rust_theta = ThetaBase(
        #     epsilon=0.5,
        #     supp_epsilon=0.05,
        #     delta=1.0,
        #     n_0=100,
        #     k=10,
        #     m=2,
        #     beta=0.8,
        #     tau_min=0.1,
        #     alpha_m=0.95,
        #     retry_nonce=0,
        #     wac_mode="windowed",
        # )
        #
        # # Verify all fields match
        # assert rust_theta.epsilon == 0.5
        # assert rust_theta.beta == 0.8
        # assert rust_theta.wac_mode == "windowed"
        pass

    @pytest.mark.skip(reason="Requires compiled Rust bindings (maturin develop)")
    def test_rust_theta_base_error_handling(self):
        """Rust ThetaBase error messages match Python validation logic"""
        # This test will be enabled once ace_zk binary is compiled
        #
        # from ace_zk import ThetaBase
        # import ValueError
        #
        # with pytest.raises(ValueError) as exc_info:
        #     ThetaBase(
        #         epsilon=0.0,
        #         supp_epsilon=0.05,
        #         delta=1.0,
        #         n_0=100,
        #         k=10,
        #         m=2,
        #         beta=0.8,
        #         tau_min=0.1,
        #         alpha_m=0.95,
        #         retry_nonce=0,
        #         wac_mode="windowed",
        #     )
        #
        # assert "epsilon" in str(exc_info.value).lower()
        pass

    @pytest.mark.skip(reason="Requires compiled Rust bindings (maturin develop)")
    def test_rust_theta_c6_serialization_roundtrip(self):
        """Rust ThetaC6 serialization round-trip (serde_json)"""
        # Once compiled, this validates:
        # 1. Rust ThetaC6 → JSON (via serde_json)
        # 2. JSON → Rust ThetaC6 (deserialization)
        # 3. Numerical equivalence within ε < 1e-9
        pass


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
