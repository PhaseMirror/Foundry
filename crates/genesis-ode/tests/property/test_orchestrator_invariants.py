from hypothesis import given, strategies as st
from genesis_governance.lane_d.schema import MetaShrapnelFragment, MetaContext, GovernanceAction, GlobalAssessment
from genesis_governance.lane_d.orchestrator import MetaOrchestrator
from genesis_governance.lane_d.policy import DEFAULT_POLICY

# Strategy for generating fragments
frag_strategy = st.builds(
    MetaShrapnelFragment,
    source_run_id=st.text(),
    context=st.builds(MetaContext),
    max_drift_observed=st.floats(0.0, 1.0),
    reconstruction_fidelity=st.floats(0.0, 1.0),
    overall_tau=st.floats(0.0, 1.0),
    cd_overall=st.floats(0.0, 1.0),
    governance_decision=st.just("ACCEPTED"),
    meta_fragility_class=st.sampled_from([
        "META_STABLE_UNDER_ADVERSARIAL_STRESS",
        "META_TETHER_BORDERLINE",
        "META_RECOVERY_LATENCY",
        "META_GOVERNANCE_COLLAPSE"
    ]),
    suggested_action=st.just("STABLE")
)

@given(st.dictionaries(st.text(), frag_strategy, min_size=1))
def test_precedence_invariants(fragments):
    orchestrator = MetaOrchestrator()
    assessment = orchestrator.compute_global_assessment(fragments)
    actions = orchestrator.generate_actions(fragments, assessment)
    
    # Invariant 1: Global Precedence (Circuit Breaker)
    if assessment.collapse_count >= DEFAULT_POLICY.global_collapse_threshold:
        # Check that GLOBAL:paused is in actions
        global_actions = [a for a in actions if a.lane_id == "GLOBAL"]
        assert len(global_actions) == 1
        assert global_actions[0].commanded_profile == "paused"
        
        # Verify no conflicting exploratory actions
        # (Assuming 'exploration' implies potentially lane-specific modifications)
        # For simplicity, check that NO other lane-specific actions exist during global pause
        lane_actions = [a for a in actions if a.lane_id != "GLOBAL"]
        assert len(lane_actions) == 0

@given(st.dictionaries(st.text(), frag_strategy, min_size=1))
def test_no_contradictory_actions(fragments):
    orchestrator = MetaOrchestrator()
    assessment = orchestrator.compute_global_assessment(fragments)
    actions = orchestrator.generate_actions(fragments, assessment)
    
    # Check for lane-specific contradictions (one profile per lane)
    lane_map = {}
    for action in actions:
        if action.lane_id == "GLOBAL": continue
        if action.lane_id in lane_map:
            # Contradiction check: e.g., same lane being told to do different things
            assert lane_map[action.lane_id] == action.commanded_profile
        lane_map[action.lane_id] = action.commanded_profile
