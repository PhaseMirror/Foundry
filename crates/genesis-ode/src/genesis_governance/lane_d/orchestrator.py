from typing import List, Dict
from genesis_governance.lane_d.schema import MetaShrapnelFragment, MultiSubstrateMetaMap, GlobalAssessment, GovernanceAction, MetaContext, GovernanceActionTrace
from genesis_governance.lane_d.policy import DEFAULT_POLICY
import numpy as np

class MetaOrchestrator:
    """
    Orchestrates cross-lane governance policies (Phase 3).
    """
    def __init__(self, protected_lanes: List[str] = ["A"]):
        self.protected_lanes = protected_lanes
        self.epsilon = 0.1

    def compute_global_assessment(self, fragments: Dict[str, MetaShrapnelFragment]) -> GlobalAssessment:
        if not fragments:
            return GlobalAssessment(cd_global=1.0, dominant_bottleneck="NONE", collapse_count=0, protected_lane_violations=0)
        
        # Global Meta-Coherence Formula: min(weighted_sum, protected_floor + epsilon)
        w = 1.0 / len(fragments)
        sum_weighted_cd = sum(w * frag.cd_overall for frag in fragments.values())
        
        protected_scores = [fragments[lane].cd_overall for lane in self.protected_lanes if lane in fragments]
        floor_score = min(protected_scores) + self.epsilon if protected_scores else 1.0
        
        cd_global = min(sum_weighted_cd, floor_score)
        
        # Bottleneck detection
        all_bottlenecks = [frag.bottleneck for frag in fragments.values() if frag.bottleneck != "NONE"]
        dominant_bottleneck = max(set(all_bottlenecks), key=all_bottlenecks.count) if all_bottlenecks else "NONE"
        
        collapse_count = sum(1 for frag in fragments.values() if frag.meta_fragility_class == "META_GOVERNANCE_COLLAPSE")
        
        return GlobalAssessment(
            cd_global=cd_global,
            dominant_bottleneck=dominant_bottleneck,
            collapse_count=collapse_count,
            protected_lane_violations=0
        )

    def generate_actions(self, fragments: Dict[str, MetaShrapnelFragment], assessment: GlobalAssessment) -> List[GovernanceAction]:
        actions = []
        
        # 1. Global Circuit Breaker (highest precedence)
        if assessment.collapse_count >= DEFAULT_POLICY.global_collapse_threshold:
            actions.append(GovernanceAction(
                lane_id="GLOBAL", 
                commanded_profile="paused", 
                target_fragility_class="COLLAPSE_ZONE",
                trace=GovernanceActionTrace(
                    rule_id="ADR-017.R1.GlobalPause",
                    rule_source="ADR-017",
                    condition_predicate=f"collapse_count >= {DEFAULT_POLICY.global_collapse_threshold}",
                    evidence_refs=[f.meta_fragment_id for f in fragments.values() if f.meta_fragility_class == "META_GOVERNANCE_COLLAPSE"],
                    justification=f"Global collapse count reached {assessment.collapse_count}."
                )
            ))
            
        # 2. Cross-Substrate Contingency Rules
        for lane_id, frag in fragments.items():
            if lane_id in DEFAULT_POLICY.contingency_rules:
                for rule in DEFAULT_POLICY.contingency_rules[lane_id]:
                    # Rule evaluation (simplified for prototype)
                    triggered = False
                    if "if" in rule and rule["if"] == frag.meta_fragility_class:
                        triggered = True
                        condition = f"fragility_class == '{rule['if']}'"
                    elif "if_cd_lt" in rule and frag.cd_overall < rule["if_cd_lt"]:
                        triggered = True
                        condition = f"cd_overall < {rule['if_cd_lt']}"
                    
                    if triggered:
                        actions.append(GovernanceAction(
                            lane_id=rule["command"]["lane_id"],
                            commanded_profile=rule["command"]["commanded_profile"],
                            target_fragility_class=rule["command"]["target_fragility_class"],
                            trace=GovernanceActionTrace(
                                rule_id="ADR-017.R2.Contingency",
                                rule_source="ADR-017",
                                condition_predicate=condition,
                                evidence_refs=[frag.meta_fragment_id],
                                justification=f"Contingency triggered by Lane {lane_id} state."
                            )
                        ))
        return actions

    def create_meta_map(self, fragments: Dict[str, MetaShrapnelFragment], context: MetaContext) -> MultiSubstrateMetaMap:
        assessment = self.compute_global_assessment(fragments)
        actions = self.generate_actions(fragments, assessment)
        
        return MultiSubstrateMetaMap(
            meta_fragments=fragments,
            global_context=context,
            global_assessment=assessment,
            recommended_actions=actions
        )
