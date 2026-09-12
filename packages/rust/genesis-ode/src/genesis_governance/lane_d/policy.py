from pydantic import BaseModel, Field
from typing import Dict, List, Any, Literal

class GovernancePolicy(BaseModel):
    """
    Operational governance rules for substrate-run combinations.
    """
    # Zone thresholds based on (CD, Fragility)
    allowed_zones: Dict[str, List[str]] # {profile: [allowed_fragility_classes]}
    strict_no_go_zones: List[str] = ["META_GOVERNANCE_COLLAPSE"]
    requires_adr_justification: List[str] = ["META_RECOVERY_LATENCY"]
    
    # Contingency rules
    # lane_id -> trigger_condition -> action
    contingency_rules: Dict[str, List[Dict[str, Any]]] = Field(default_factory=dict)
    global_collapse_threshold: int = 2

# Default Policy (Calibrated to current metallurgical and E/F/G observations)
DEFAULT_POLICY = GovernancePolicy(
    allowed_zones={
        "baseline": ["META_STABLE_UNDER_ADVERSARIAL_STRESS", "META_RECOVERY_LATENCY"],
        "exploration": ["META_STABLE_UNDER_ADVERSARIAL_STRESS", "META_RECOVERY_LATENCY", "META_TETHER_BORDERLINE"],
        "production": ["META_STABLE_UNDER_ADVERSARIAL_STRESS"]
    },
    contingency_rules={
        "E": [{"if": "COLLAPSE_PRECURSOR", "command": {"lane_id": "F", "commanded_profile": "recovery_mode", "target_fragility_class": "META_RECOVERY_LATENCY"}}],
        "G": [{"if_cd_lt": 0.5, "command": {"lane_id": "A", "commanded_profile": "capped_50", "target_fragility_class": "META_STABLE_UNDER_ADVERSARIAL_STRESS"}}]
    }
)
