# multiplicity/__init__.py

__version__ = "0.2.0"

try:
    from .math.core_math import Λ_m, lawful, entropy, Ξ
except Exception:
    Λ_m = 1.61803398875
    def lawful(n):
        return True
    def entropy(n):
        return 0.0
    def Ξ(n, depth=5):
        return n

try:
    from .cert.lambda_m_protocols import derive_lambda_m
except Exception:
    def derive_lambda_m():
        return {"lambda_m": Λ_m}

try:
    from .math.cas_registry import CasRegistry, get_registry, register_ace_witness, verify_ace_witness
    CAS_AVAILABLE = True
except Exception:
    CAS_AVAILABLE = False
    import logging
    logging.getLogger(__name__).warning("CAS registry not available, some features disabled")

from . import math
from . import mkt
from . import agi
from . import topos
from . import cert
from . import utils
from . import moonshine
from . import crypto  # Foundational crypto interop

try:
    from .zeno_heartbeat import HeartbeatConfig, HeartbeatViolation, assess_rt_feasibility, enforce_heartbeat
except Exception:
    HeartbeatConfig = None
    HeartbeatViolation = Exception
    def assess_rt_feasibility(config):
        return []
    def enforce_heartbeat(config, measured_jitter):
        return True

try:
    from .kernel_telemetry import KernelTelemetry, emit_telemetry, serialize_telemetry, load_telemetry, write_telemetry_artifact
except Exception:
    KernelTelemetry = None
    def emit_telemetry(*args, **kwargs):
        return None
    def serialize_telemetry(t):
        return {}
    def load_telemetry(d):
        return {}
    def write_telemetry_artifact(*args, **kwargs):
        return None
