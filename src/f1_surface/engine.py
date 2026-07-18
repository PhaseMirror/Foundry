import logging
from dataclasses import dataclass, asdict
from typing import List, Tuple, Dict, Any, Optional
import numpy as np

from .riemann_siegel import compute_zero_shadow_metrics

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Custom exceptions
# ---------------------------------------------------------------------------

class KernelTelemetryError(Exception):
    """Base exception for kernel telemetry errors."""
    pass


class ParityContractViolation(KernelTelemetryError):
    """Raised when the 1e-9 parity contract between legacy and kernel drift is violated."""
    pass


class InvalidTelemetryError(KernelTelemetryError):
    """Raised when KernelTelemetry fails validation."""
    pass


class FeasibilityMapError(KernelTelemetryError):
    """Raised when a feasibility map produces an invalid output."""
    pass


class OperatorShapeError(KernelTelemetryError):
    """Raised when operator matrices have incompatible shapes."""
    pass


# ---------------------------------------------------------------------------
# KernelTelemetry dataclass
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class KernelTelemetry:
    """
    Versioned kernel telemetry contract (Θkernel).

    This is the single semantic authority for drift and protection metrics
    consumed by ACE, SCN, and CSC layers. Fields are immutable once constructed.
    """
    xn_kernel: float
    wt_max_kernel: float
    protection_zeta: float
    is_valid_kernel: bool
    zeta_shadow: float = 1.0
    telemetry_version: int = 2
    # Analytic shadow (Riemann-Siegel / Odlyzko-style)
    first_zero_approx: float = 0.0
    mean_spacing: float = 1.0
    gue_deviation: float = 0.0

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to a JSON-compatible dictionary."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "KernelTelemetry":
        """Deserialize from a dictionary."""
        return cls(**data)

    def validate(self) -> None:
        """
        Validate semantic constraints on telemetry fields.

        Raises:
            InvalidTelemetryError: If any field violates its expected range.
        """
        if not (0.0 <= self.xn_kernel <= 1.0):
            raise InvalidTelemetryError(
                f"xn_kernel must be in [0, 1], got {self.xn_kernel}"
            )
        if not (0.0 <= self.wt_max_kernel <= 1.0):
            raise InvalidTelemetryError(
                f"wt_max_kernel must be in [0, 1], got {self.wt_max_kernel}"
            )
        if self.protection_zeta < 0.0:
            raise InvalidTelemetryError(
                f"protection_zeta must be non-negative, got {self.protection_zeta}"
            )
        if self.zeta_shadow < 0.0:
            raise InvalidTelemetryError(
                f"zeta_shadow must be non-negative, got {self.zeta_shadow}"
            )
        if self.telemetry_version < 1:
            raise InvalidTelemetryError(
                f"telemetry_version must be positive, got {self.telemetry_version}"
            )
        if self.first_zero_approx < 0.0:
            raise InvalidTelemetryError(
                f"first_zero_approx must be non-negative, got {self.first_zero_approx}"
            )
        if self.mean_spacing <= 0.0:
            raise InvalidTelemetryError(
                f"mean_spacing must be positive, got {self.mean_spacing}"
            )
        if not (0.0 <= self.gue_deviation <= 1.0):
            raise InvalidTelemetryError(
                f"gue_deviation must be in [0, 1], got {self.gue_deviation}"
            )


# ---------------------------------------------------------------------------
# Legacy drift computation (Track A parity reference)
# ---------------------------------------------------------------------------

def legacy_drift_metrics(state: np.ndarray) -> Tuple[float, float, float]:
    """
    Compute legacy Track A drift metrics from a system state matrix.

    This provides the reference values against which kernel telemetry
    is compared for parity testing.

    Args:
        state: System state matrix (will be Hermitianized).

    Returns:
        (X_n, W_t, R_t) drift metrics.
    """
    if state.ndim != 2 or state.shape[0] != state.shape[1]:
        raise OperatorShapeError("State must be a square matrix.")

    H = 0.5 * (state + state.conj().T)
    eigenvalues = np.linalg.eigvalsh(H)
    eigenvalues = np.sort(eigenvalues)[::-1]

    if len(eigenvalues) == 0:
        return 0.0, 0.0, 0.0

    lambda_max = float(eigenvalues[0])
    lambda_min = float(eigenvalues[-1])
    gap = max(lambda_max - lambda_min, 1e-12)

    X_n = float(np.sum(np.abs(eigenvalues) ** 2) ** 0.5 / max(gap, 1e-12))
    X_n = min(X_n, 1.0)

    W_t = float(lambda_max / max(abs(lambda_min), 1e-12))
    W_t = min(W_t, 1.0)

    trace_H = float(np.trace(H))
    R_t = float(abs(trace_H) / max(gap, 1e-12))
    R_t = min(R_t, 1.0)

    return X_n, W_t, R_t


# ---------------------------------------------------------------------------
# gaugeFix: KernelTelemetry -> Arakelov normalization
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class ArakelovParams:
    """
    Arakelov normalization parameters derived from KernelTelemetry.

    gamma = exp(-protection_zeta) is the archimedean weight.
    scale normalizes the diagonal contribution.
    """
    gamma: float
    scale: float
    is_normalized: bool = True

    def validate(self) -> None:
        if self.gamma <= 0.0:
            raise InvalidTelemetryError(f"Arakelov gamma must be positive, got {self.gamma}")
        if self.scale <= 0.0:
            raise InvalidTelemetryError(f"Arakelov scale must be positive, got {self.scale}")


def gauge_fix(telemetry: KernelTelemetry) -> ArakelovParams:
    """
    Map kernel telemetry to Arakelov normalization parameters.

    Args:
        telemetry: Validated KernelTelemetry record.

    Returns:
        ArakelovParams with archimedean weight gamma and scale factor.

    Raises:
        InvalidTelemetryError: If telemetry fields are out of valid range.
    """
    telemetry.validate()
    gamma = np.exp(-telemetry.protection_zeta)
    scale = 1.0 / (telemetry.xn_kernel + telemetry.protection_zeta + 1e-12)
    params = ArakelovParams(gamma=float(gamma), scale=float(scale), is_normalized=True)
    params.validate()
    return params


# ---------------------------------------------------------------------------
# SpectralControlEngine
# ---------------------------------------------------------------------------

class SpectralControlEngine:
    """
    Spectral control engine implementing the ACE feasibility maps.

    Consumes KernelTelemetry as the single semantic authority for drift
    and protection metrics. Projects raw proposals onto Hecke-span subspaces
    and enforces constraint sets C_epsilon, C_epsilon^{H_r}, C_near_{epsilon, eta}.
    """

    def __init__(self, target_operators: List[np.ndarray]):
        """
        Initialize the engine with target operators.

        Args:
            target_operators: List of square, Hermitian matrices representing
                              Hecke operators or other arithmetic operators.

        Raises:
            OperatorShapeError: If operators are not square or have mismatched shapes.
        """
        if not target_operators:
            self.operators = []
            self.d = 0
            self.basis_matrices = []
            return

        shapes = [op.shape for op in target_operators]
        if len(set(shapes)) > 1:
            raise OperatorShapeError(
                f"All target operators must have the same shape, got {shapes}"
            )
        if any(op.shape[0] != op.shape[1] for op in target_operators):
            raise OperatorShapeError("Target operators must be square matrices.")

        self.operators = [np.array(op, dtype=complex) for op in target_operators]
        self.d = self.operators[0].shape[0]
        self._precompute_orthonormal_basis()

    def _precompute_orthonormal_basis(self) -> None:
        """Precompute an orthonormal basis for the span of target operators."""
        if not self.operators:
            return
        flat_ops = [op.flatten() for op in self.operators]
        matrix_stack = np.column_stack(flat_ops)
        if matrix_stack.shape[1] == 0:
            self.basis_matrices = []
            return
        q, _ = np.linalg.qr(matrix_stack)
        self.basis_matrices = [q[:, i].reshape((self.d, self.d)) for i in range(q.shape[1])]
        logger.debug("Precomputed %d orthonormal basis vectors.", len(self.basis_matrices))

    def _enforce_hermitian(self, X: np.ndarray) -> np.ndarray:
        """Force a matrix to be exactly Hermitian."""
        return 0.5 * (X + X.conj().T)

    def project_to_span(self, X: np.ndarray) -> np.ndarray:
        """
        Project X onto the span of target operators.

        Args:
            X: Input matrix.

        Returns:
            Projection of X onto the span.
        """
        projection = np.zeros_like(X, dtype=complex)
        for u in self.basis_matrices:
            coef = float(np.trace(np.conjugate(u).T @ X))
            projection += coef * u
        return projection

    def distance_to_span(self, X: np.ndarray) -> float:
        """
        Compute the Frobenius-norm distance from X to the span of target operators.

        Args:
            X: Input matrix.

        Returns:
            ||X - project_to_span(X)||_F.
        """
        H = self.project_to_span(X)
        return float(np.linalg.norm(X - H, 'fro'))

    def enforce_feasibility_map(
        self,
        delta_0: np.ndarray,
        mode: int,
        epsilon: float,
        eta: float = 0.0,
    ) -> np.ndarray:
        """
        Apply the feasibility map F_m for the given mode.

        Modes:
            1: F_1(delta) = (epsilon / ||delta||_F) * delta  (Frobenius ball)
            2: F_2(delta) = (epsilon / ||H||_F) * H  (Hecke-span projection)
            3: F_3(delta) = H + clip(R, eta), then Frobenius clip  (near-mode)

        Args:
            delta_0: Raw proposal matrix.
            mode: Feasibility mode (1, 2, or 3).
            epsilon: Frobenius-norm bound.
            eta: Distance-to-Hecke-span bound (mode 3 only).

        Returns:
            Constrained delta satisfying the mode's constraint set.

        Raises:
            ValueError: If mode is not 1, 2, or 3.
            FeasibilityMapError: If output violates Hermiticity or other invariants.
        """
        if delta_0.ndim != 2 or delta_0.shape[0] != delta_0.shape[1]:
            raise OperatorShapeError("delta_0 must be a square matrix.")

        delta_prime = self._enforce_hermitian(delta_0)

        if mode == 1:
            norm = np.linalg.norm(delta_prime, 'fro')
            scale = epsilon / max(norm, epsilon)
            result = delta_prime * scale
        elif mode == 2:
            H = self.project_to_span(delta_prime)
            norm = np.linalg.norm(H, 'fro')
            scale = epsilon / max(norm, epsilon)
            result = H * scale
        elif mode == 3:
            H = self.project_to_span(delta_prime)
            R = delta_prime - H
            r_norm = np.linalg.norm(R, 'fro')
            scale_r = 1.0 if r_norm == 0 else min(1.0, eta / r_norm)
            R_prime = R * scale_r
            delta_1 = H + R_prime
            d1_norm = np.linalg.norm(delta_1, 'fro')
            scale_final = epsilon / max(d1_norm, epsilon)
            result = delta_1 * scale_final
        else:
            raise ValueError(f"Invalid feasibility mode: {mode}. Must be 1, 2, or 3.")

        result = self._enforce_hermitian(result)

        if not np.allclose(result, result.conj().T):
            raise FeasibilityMapError("Feasibility map output is not Hermitian.")

        return result

    def run_control_pipeline(
        self,
        raw_proposal: np.ndarray,
        telemetry: KernelTelemetry,
        mode: int,
        epsilon: float,
        eta: float = 0.0,
    ) -> Tuple[np.ndarray, Dict[str, Any]]:
        """
        Run the full control pipeline: validate telemetry, scale parameters,
        apply feasibility map, and return constrained delta with telemetry payload.

        Args:
            raw_proposal: Raw perturbation matrix from SCN.
            telemetry: KernelTelemetry record (single semantic authority).
            mode: Feasibility mode (1, 2, or 3).
            epsilon: Frobenius-norm bound.
            eta: Distance-to-Hecke-span bound (mode 3).

        Returns:
            (constrained_delta, payload_dict)

        Raises:
            InvalidTelemetryError: If telemetry is invalid.
            ValueError: If is_valid_kernel is False.
            FeasibilityMapError: If feasibility map produces invalid output.
        """
        if not telemetry.is_valid_kernel:
            raise ValueError("Pipeline aborted: Kernel telemetry validity flag is False.")

        telemetry.validate()

        effective_epsilon = epsilon * max(0.0, 1.0 - telemetry.xn_kernel)
        spacing_factor = telemetry.mean_spacing
        dissonance_damp = 1.0 - telemetry.gue_deviation * 0.15
        effective_eta = eta / (1.0 + telemetry.zeta_shadow) * spacing_factor * dissonance_damp

        constrained_delta = self.enforce_feasibility_map(
            raw_proposal, mode, effective_epsilon, effective_eta
        )

        payload = {
            "xn_kernel": telemetry.xn_kernel,
            "wt_max_kernel": telemetry.wt_max_kernel,
            "protection_zeta": telemetry.protection_zeta,
            "zeta_shadow": telemetry.zeta_shadow,
            "is_valid_kernel": int(telemetry.is_valid_kernel),
            "telemetry_version": telemetry.telemetry_version,
            "first_zero_approx": telemetry.first_zero_approx,
            "mean_spacing": telemetry.mean_spacing,
            "gue_deviation": telemetry.gue_deviation,
            "effective_epsilon": effective_epsilon,
            "effective_eta": effective_eta,
            "output_norm": float(np.linalg.norm(constrained_delta, 'fro')),
            "distance_to_span": float(self.distance_to_span(constrained_delta)),
        }
        return constrained_delta, payload


# ---------------------------------------------------------------------------
# mock_zeno_compute_kernel_telemetry (single semantic authority)
# ---------------------------------------------------------------------------

def mock_zeno_compute_kernel_telemetry(
    xn_kernel: float,
    wt_max_kernel: float,
    protection_zeta: float,
    is_valid_kernel: bool,
    *,
    parity_mode: bool = True,
    xn_reference: Optional[float] = None,
    include_zero_shadow: bool = True,
    zero_shadow_window: Tuple[float, float] = (14.0, 50.0),
    search_step: float = 0.1,
) -> KernelTelemetry:
    """
    Single semantic authority for constructing KernelTelemetry records.

    This function is the canonical constructor for KernelTelemetry. It enforces
    the parity contract (1e-9 tolerance between legacy and kernel drift) and
    optionally populates analytic-shadow metrics from the Riemann-Siegel evaluator.

    Args:
        parity_mode: When True, enforce |xn_kernel - xn_reference| < 1e-9.
        xn_reference: Expected reference value for parity check. Defaults to xn_kernel.
        include_zero_shadow: Populate first_zero_approx, mean_spacing, gue_deviation.
        zero_shadow_window: (t_start, t_end) for the Riemann-Siegel zero search.
        search_step: Coarse step size for sign-change detection.

    Returns:
        Validated KernelTelemetry record.

    Raises:
        ParityContractViolation: If parity_mode=True and |xn_kernel - ref| >= 1e-9.
    """
    ref = xn_reference if xn_reference is not None else xn_kernel
    if parity_mode and abs(float(xn_kernel) - float(ref)) >= 1e-9:
        raise ParityContractViolation(
            f"Parity contract violated: |xn_kernel - {ref}| = "
            f"{abs(float(xn_kernel) - float(ref))} >= 1e-9"
        )

    if include_zero_shadow:
        first_zero, mean_spacing, gue_dev = compute_zero_shadow_metrics(
            t_start=zero_shadow_window[0],
            t_end=zero_shadow_window[1],
            search_step=search_step,
        )
    else:
        first_zero, mean_spacing, gue_dev = 0.0, 1.0, 0.0

    telemetry = KernelTelemetry(
        xn_kernel=float(xn_kernel),
        wt_max_kernel=float(wt_max_kernel),
        protection_zeta=float(protection_zeta),
        is_valid_kernel=bool(is_valid_kernel),
        zeta_shadow=1.0,
        telemetry_version=2,
        first_zero_approx=float(first_zero),
        mean_spacing=float(mean_spacing),
        gue_deviation=float(gue_dev),
    )
    telemetry.validate()
    return telemetry
