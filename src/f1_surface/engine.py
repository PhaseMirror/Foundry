import numpy as np
from dataclasses import dataclass
from typing import List, Tuple, Dict, Any

@dataclass(frozen=True)
class KernelTelemetry:
    xn_kernel: float
    wt_max_kernel: float
    protection_zeta: float
    is_valid_kernel: bool
    zeta_shadow: float = 1.0
    telemetry_version: int = 2

class SpectralControlEngine:
    def __init__(self, target_operators: List[np.ndarray]):
        self.operators = [np.array(op, dtype=complex) for op in target_operators]
        if len(self.operators) > 0:
            self.d = self.operators[0].shape[0]
            self._precompute_orthonormal_basis()
        else:
            self.d = 0
            self.basis_matrices = []

    def _precompute_orthonormal_basis(self):
        if not self.operators:
            return
        flat_ops = [op.flatten() for op in self.operators]
        matrix_stack = np.column_stack(flat_ops)
        q, _ = np.linalg.qr(matrix_stack)
        self.basis_matrices = [q[:, i].reshape((self.d, self.d)) for i in range(q.shape[1])]

    def project_to_span(self, X: np.ndarray) -> np.ndarray:
        projection = np.zeros_like(X, dtype=complex)
        for u in self.basis_matrices:
            coef = np.trace(np.conjugate(u).T @ X)
            projection += coef * u
        return projection

    def enforce_feasibility_map(self, delta_0: np.ndarray, mode: int, epsilon: float, eta: float = 0.0) -> np.ndarray:
        delta_prime = 0.5 * (delta_0 + np.conjugate(delta_0).T)
        if mode == 1:
            norm = np.linalg.norm(delta_prime, 'fro')
            scale = epsilon / max(norm, epsilon)
            return delta_prime * scale
        elif mode == 2:
            H = self.project_to_span(delta_prime)
            norm = np.linalg.norm(H, 'fro')
            scale = epsilon / max(norm, epsilon)
            return H * scale
        elif mode == 3:
            H = self.project_to_span(delta_prime)
            R = delta_prime - H
            r_norm = np.linalg.norm(R, 'fro')
            scale_r = 1.0 if r_norm == 0 else min(1.0, eta / r_norm)
            R_prime = R * scale_r
            delta_1 = H + R_prime
            d1_norm = np.linalg.norm(delta_1, 'fro')
            scale_final = epsilon / max(d1_norm, epsilon)
            return delta_1 * scale_final
        else:
            raise ValueError(f"Invalid feasibility mode: {mode}. Must be 1, 2, or 3.")

    def run_control_pipeline(self, raw_proposal: np.ndarray, telemetry: KernelTelemetry, mode: int, epsilon: float, eta: float = 0.0) -> Tuple[np.ndarray, Dict[str, Any]]:
        if not telemetry.is_valid_kernel:
            raise ValueError("Pipeline aborted: Kernel telemetry validity flag is False.")
        effective_epsilon = epsilon * max(0.0, 1.0 - telemetry.xn_kernel)
        effective_eta = eta / (1.0 + telemetry.zeta_shadow)
        constrained_delta = self.enforce_feasibility_map(raw_proposal, mode, effective_epsilon, effective_eta)
        payload = {
            "xn_kernel": telemetry.xn_kernel,
            "wt_max_kernel": telemetry.wt_max_kernel,
            "protection_zeta": telemetry.protection_zeta,
            "zeta_shadow": telemetry.zeta_shadow,
            "is_valid_kernel": int(telemetry.is_valid_kernel),
            "telemetry_version": telemetry.telemetry_version,
            "output_norm": float(np.linalg.norm(constrained_delta, 'fro'))
        }
        return constrained_delta, payload
