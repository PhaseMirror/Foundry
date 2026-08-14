"""Minimal DHT state engine with optional ACFL explainability hook."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, Any

from packages.operators.crmf import issue_certificate
from packages.reasoning.acfl import ACFLExplainer


@dataclass
class DHTState:
    patient_id: str
    metrics: Dict[str, float]
    acfl_explanation: Dict[str, Any] | None = None


@dataclass
class DHTConfig:
    enable_acfl: bool = True


class DigitalHealthcareTwinStateEngine:
    def __init__(self, config: DHTConfig | None = None) -> None:
        self.config = config or DHTConfig()
        self.acfl_explainer = ACFLExplainer()
        self.audit_log: list[dict] = []

    def step(self, state: DHTState, spectral_radius: float, prime_decomposition: Dict[int, float]) -> DHTState:
        cert = issue_certificate(
            trace_id=f"trace-{state.patient_id}",
            spectral_radius=spectral_radius,
            metadata={"patient_metric_count": float(len(state.metrics))},
        )

        if self.config.enable_acfl:
            explanation = self.acfl_explainer.explain_certificate(
                certificate={
                    "trace_id": cert.trace_id,
                    "spectral_radius": cert.spectral_radius,
                    "is_stable": cert.is_stable,
                },
                patient_state={"metrics": state.metrics},
                crmf_decomposition=prime_decomposition,
            )
            state.acfl_explanation = self.acfl_explainer.as_dict(explanation)

        self.audit_log.append(
            {
                "trace_id": cert.trace_id,
                "is_stable": cert.is_stable,
                "acfl_enabled": self.config.enable_acfl,
            }
        )
        return state
