from typing import List
from genesis_governance.schemas.shrapnel import ShrapnelMap
from genesis_governance.schemas.governance import RollbackTrigger

def evaluate_rollback(shrapnel_map: ShrapnelMap) -> List[RollbackTrigger]:
    """
    Evaluates a ShrapnelMap for rollback triggers (ADR-002, ADR-006).
    """
    triggers = []
    
    # 1. Check for critical fragility classes
    critical_classes = ["impedance-spike-precursor"]
    
    for fragment in shrapnel_map.fragments:
        if fragment.fragility_class in critical_classes:
            triggers.append(RollbackTrigger(
                trigger_type="FRAGILITY_SPIKE",
                severity="CRITICAL",
                affected_substrate=fragment.target_id,
                reason=f"Detected critical fragility: {fragment.fragility_class}",
                tier=shrapnel_map.tier
            ))
            
    # 2. Check for extreme drift (regardless of tau)
    # If any fragment shows drift > 0.9 (saturation threshold approaching)
    for fragment in shrapnel_map.fragments:
        drift = fragment.observed_drift.get("coherence_drift", 0.0)
        if drift > 0.9:
            triggers.append(RollbackTrigger(
                trigger_type="DRIFT_EXCESS",
                severity="CRITICAL",
                affected_substrate=fragment.target_id,
                reason=f"Excessive drift detected: {drift:.2f}",
                tier=shrapnel_map.tier
            ))
            
    return triggers
