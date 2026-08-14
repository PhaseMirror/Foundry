from enum import Enum
from typing import List, Literal, Optional
from pydantic import BaseModel, Field
import uuid
from datetime import datetime

class QuantumFragilityClass(str, Enum):
    COHERENT_UNDER_MEASUREMENT = "coherent-under-measurement"
    COLLAPSE_PRECURSOR = "collapse-precursor"
    ENTANGLEMENT_FRAGILE = "entanglement-fragile"
    PHASE_JITTER_ONLY = "phase-jitter-only"
    TETHER_COLLAPSE = "tether-collapse"

class QuantumShrapnelFragment(BaseModel):
    fragment_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    locus: Literal["amplitude", "phase", "measurement", "entanglement", "decoherence"]
    coherence_amplitude: float
    phase: float
    measurement_stress: float
    entanglement_proxy: float
    fragility_class: QuantumFragilityClass
    prime_band_signature: List[int]
    reconstruction_score: float
    timestamp: datetime = Field(default_factory=datetime.utcnow)
