from enum import Enum
from typing import List, Literal
from pydantic import BaseModel, Field
import uuid
from datetime import datetime

class BiologicalFragilityClass(str, Enum):
    ROBUST_UNDER_ADVERSARIAL_STRESS = "robust-under-adversarial-stress"
    STRONG_ADAPTATION = "strong-adaptation"
    RECOVERY_LATENCY = "recovery-latency"
    FATIGUE_ACCUMULATION = "fatigue-accumulation"
    TIPPING_POINT_COLLAPSE = "tipping-point-collapse"

class BiologicalShrapnelFragment(BaseModel):
    fragment_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    locus: Literal["homeostasis", "adaptation", "immune_threshold", "fatigue_accumulation", "recovery_latency"]
    vitality: float
    adaptation_rate: float
    stress_load: float
    recovery_time: float
    fragility_class: BiologicalFragilityClass
    prime_band_signature: List[int]
    reconstruction_score: float
    timestamp: datetime = Field(default_factory=datetime.utcnow)
