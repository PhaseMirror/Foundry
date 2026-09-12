from enum import Enum
from typing import List, Literal, Dict
from pydantic import BaseModel, Field
import uuid
from datetime import datetime

class EcologicalFragilityClass(str, Enum):
    ROBUST_UNDER_ADVERSARIAL_STRESS = "robust-under-adversarial-stress"
    STRONG_LOGISTIC_RECOVERY = "strong-logistic-recovery"
    TIPPING_THRESHOLD = "tipping-threshold"
    DISTURBANCE_AMPLIFICATION = "disturbance-amplification"
    RESILIENCE_COLLAPSE = "resilience-collapse"

class EcologicalShrapnelFragment(BaseModel):
    fragment_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    locus: Literal["carrying_capacity", "seasonal_cycle", "tipping_threshold", "multi_scale_feedback", "disturbance_recovery"]
    resilience: float
    adaptation_rate: float
    disturbance_load: float
    recovery_time: float
    fragility_class: EcologicalFragilityClass
    prime_band_signature: List[int]
    reconstruction_score: float
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    composite_coupling: Dict[str, float]
