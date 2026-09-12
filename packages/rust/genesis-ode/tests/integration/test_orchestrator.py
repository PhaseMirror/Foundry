import pytest
from genesis_governance.lane_d.schema import MetaShrapnelFragment, MetaContext
from genesis_governance.lane_d.orchestrator import MetaOrchestrator

def test_cross_lane_contingency():
    orchestrator = MetaOrchestrator(protected_lanes=["A"])
    
    # 1. Simulate Quantum Crisis (Lane E)
    # E triggers contingency: F -> recovery_mode
    e_frag = MetaShrapnelFragment(
        source_run_id="run_E",
        context=MetaContext(),
        max_drift_observed=0.0,
        reconstruction_fidelity=0.9,
        overall_tau=0.5,
        cd_overall=0.9,
        governance_decision="ACCEPTED",
        meta_fragility_class="COLLAPSE_PRECURSOR",
        suggested_action="STABLE"
    )
    
    # 2. Add other lanes
    f_frag = MetaShrapnelFragment(
        source_run_id="run_F",
        context=MetaContext(),
        max_drift_observed=0.0,
        reconstruction_fidelity=0.9,
        overall_tau=0.5,
        cd_overall=0.9,
        governance_decision="ACCEPTED",
        meta_fragility_class="META_STABLE_UNDER_ADVERSARIAL_STRESS",
        suggested_action="STABLE"
    )
    
    fragments = {"E": e_frag, "F": f_frag}
    
    # Generate meta map
    meta_map = orchestrator.create_meta_map(fragments, MetaContext())
    
    # Verify action triggered
    actions = [a for a in meta_map.recommended_actions if a.lane_id == "F"]
    assert len(actions) == 1
    assert actions[0].commanded_profile == "recovery_mode"
    
def test_global_circuit_breaker():
    orchestrator = MetaOrchestrator()
    
    # 2 lanes in COLLAPSE
    collapse_frag = MetaShrapnelFragment(
        source_run_id="run_X",
        context=MetaContext(),
        max_drift_observed=0.0,
        reconstruction_fidelity=0.0,
        overall_tau=0.1,
        cd_overall=0.1,
        governance_decision="REJECTED",
        meta_fragility_class="META_GOVERNANCE_COLLAPSE",
        suggested_action="FREEZE_INNOVATION_BUDGET"
    )
    
    fragments = {"E": collapse_frag, "F": collapse_frag}
    
    meta_map = orchestrator.create_meta_map(fragments, MetaContext())
    
    # Verify global pause triggered
    actions = [a for a in meta_map.recommended_actions if a.lane_id == "GLOBAL"]
    assert len(actions) == 1
    assert actions[0].commanded_profile == "paused"
