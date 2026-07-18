from dataclasses import dataclass
from typing import Protocol, Any
import json

@dataclass(frozen=True)
class KernelTelemetry:
    xn_kernel: float
    wt_max_kernel: float
    protection_zeta: float
    is_valid_kernel: bool
    telemetry_version: int = 1

class KernelTelemetryProvider(Protocol):
    def compute_kernel_telemetry(self, step_state: Any) -> KernelTelemetry: ...

class MockZeno:
    def compute_kernel_telemetry(self, step_state: Any) -> KernelTelemetry:
        return KernelTelemetry(
            xn_kernel=step_state.get('xn', 0.0),
            wt_max_kernel=0.0,
            protection_zeta=0.0,
            is_valid_kernel=True
        )

zeno = MockZeno()

def compute_legacy_xn(step_state: Any) -> float:
    return step_state.get('xn', 0.0)

def load_kernel_telemetry(step_state: Any) -> KernelTelemetry:
    return zeno.compute_kernel_telemetry(step_state)

def get_drift_metrics(step_state: Any, parity_mode: bool = False) -> KernelTelemetry:
    kt = load_kernel_telemetry(step_state)
    if parity_mode:
        legacy_xn = compute_legacy_xn(step_state)
        assert abs(legacy_xn - kt.xn_kernel) < 1e-9
    return kt

def serialize_theta(theta_base: bytes) -> list[int]:
    return list(theta_base)

def certificate_payload(theta_base: bytes, telemetry: KernelTelemetry, outputs: bytes) -> dict:
    return {
        "theta": serialize_theta(theta_base),
        "xn_kernel": telemetry.xn_kernel,
        "wt_max_kernel": telemetry.wt_max_kernel,
        "protection_zeta": telemetry.protection_zeta,
        "is_valid_kernel": int(telemetry.is_valid_kernel),
        "telemetry_version": telemetry.telemetry_version,
        "outputs": list(outputs),
    }

if __name__ == "__main__":
    import sys
    # For testing python-rust serialization
    if len(sys.argv) > 1 and sys.argv[1] == "test_roundtrip":
        step_state = {'xn': 0.123}
        kt = get_drift_metrics(step_state, parity_mode=True)
        payload = certificate_payload(b"theta_base_mock", kt, b"outputs_mock")
        print(json.dumps(payload))
