import json
import os
import sys
import numpy as np
from datetime import datetime

# Add src to sys.path
sys.path.append(os.path.abspath("src"))

from genesis_governance.lane_d.schema import MetaShrapnelFragment, MetaShrapnelMap, MultiSubstrateMetaMap, MetaContext, GlobalAssessment, GovernanceAction
from genesis_governance.lane_d.history import MetaHistoryStore
from genesis_governance.lane_d.policy import DEFAULT_POLICY

def generate_meta_telemetry(input_path: str, output_path: str, context: MetaContext = MetaContext()):
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found.")
        return

    with open(input_path, "r") as f:
        data = json.load(f)

    # Extract metrics from ShrapnelMap
    run_id = data.get("run_id")
    fragments = data.get("fragments", [])
    overall_tau = data.get("overall_tau", 0.0)
    
    drifts = [f.get("observed_drift", {}).get("coherence_drift", 0.0) for f in fragments]
    max_drift = max(drifts) if drifts else 0.0
    
    recon_scores = []
    for f in fragments:
        score = f.get("metadata", {}).get("multiplicity", {}).get("reconstruction_score")
        if score is not None:
            recon_scores.append(score)
    
    avg_recon = np.mean(recon_scores) if recon_scores else 0.0
    
    # Near failure defined as drift > 0.8 * epsilon (assuming epsilon=0.5 for metallurgy)
    near_failures = len([d for d in drifts if d > 0.4])
    
    # --- Lane D Meta-Metrics Formula (ADR-012) ---
    cd_tau = min(1.0, overall_tau / 0.7)
    cd_recon = avg_recon
    cd_fail = 1.0 - min(1.0, near_failures / 10.0)
    
    cd_state = (0.5 * cd_tau + 0.5 * cd_recon) * cd_fail
    
    # Identify Primary Bottleneck
    bottleneck_vals = {"TETHER": cd_tau, "RECON": cd_recon, "FAILURE": cd_fail}
    bottleneck = min(bottleneck_vals, key=bottleneck_vals.get)
    if bottleneck_vals[bottleneck] > 0.9:
        bottleneck = "NONE"

    # Evaluate SLO Status
    slo_status = {
        "TETHER": "NOMINAL" if cd_tau >= 0.70 else ("CRITICAL" if cd_tau < 0.30 else "DEGRADED"),
        "RECON": "NOMINAL" if cd_recon >= 0.85 else ("CRITICAL" if cd_recon < 0.75 else "DEGRADED"),
        "FAILURE": "NOMINAL" if cd_fail >= 1.0 else ("CRITICAL" if cd_fail < 0.80 else "DEGRADED")
    }

    # Meta Fragility Classification
    if cd_state >= 0.8 and overall_tau >= 0.7:
        meta_class = "META_STABLE_UNDER_ADVERSARIAL_STRESS"
    elif overall_tau < 0.3:
        meta_class = "META_TETHER_BORDERLINE"
    elif cd_state < 0.4:
        meta_class = "META_GOVERNANCE_COLLAPSE"
    else:
        meta_class = "META_RECOVERY_LATENCY"

    # Heuristic suggested action
    if meta_class == "META_TETHER_BORDERLINE":
        suggested_action = "REFINE_TEST_SCHEDULE (High Tension)"
    elif avg_recon < 0.85:
        suggested_action = "RECALIBRATE_PRIME_MAPPING"
    elif meta_class == "META_GOVERNANCE_COLLAPSE":
        suggested_action = "FREEZE_INNOVATION_BUDGET"
    else:
        suggested_action = "STABLE"

    # --- Circuit Breaker Enforcement (ADR-016) ---
    profile = context.config_profile_id
    allowed_classes = DEFAULT_POLICY.allowed_zones.get(profile, [])
    
    is_compliant = (meta_class in allowed_classes) and (meta_class not in DEFAULT_POLICY.strict_no_go_zones)
    violation_reason = None
    if not is_compliant:
        violation_reason = f"Fragility class '{meta_class}' not allowed for profile '{profile}'."
        print(f"!!! CIRCUIT BREAKER TRIPPED: {violation_reason} !!!")

    # Create Meta Fragment
    meta_fragment = MetaShrapnelFragment(
        source_run_id=run_id,
        context=context,
        max_drift_observed=max_drift,
        near_failure_events=near_failures,
        reconstruction_fidelity=avg_recon,
        overall_tau=overall_tau,
        cd_overall=cd_state,
        cd_tau=cd_tau,
        cd_recon=cd_recon,
        cd_fail=cd_fail,
        bottleneck=bottleneck,
        slo_status=slo_status,
        is_policy_compliant=is_compliant,
        violation_reason=violation_reason,
        governance_decision="ACCEPTED" if (overall_tau > 0.2 and is_compliant) else "REJECTED",
        meta_fragility_class=meta_class,
        suggested_action=suggested_action
    )
    # Set artifact hash for fragment
    meta_fragment.artifact_hash = meta_fragment.compute_hash()
    
    # Persist to MetaHistoryStore
    history_store = MetaHistoryStore()
    history_store.add_fragment(meta_fragment)
    
    # Create Meta Map
    meta_map = MultiSubstrateMetaMap(
        meta_fragments={"A": meta_fragment}, # Assuming A as lane_id for now
        global_context=context,
        global_assessment=GlobalAssessment(
            cd_global=cd_state,
            dominant_bottleneck=bottleneck,
            collapse_count=1 if meta_class == "META_GOVERNANCE_COLLAPSE" else 0,
            protected_lane_violations=0
        ),
        recommended_actions=[GovernanceAction(
            lane_id=action.lane_id,
            commanded_profile=action.commanded_profile,
            target_fragility_class=action.target_fragility_class,
            trace=action.trace
        ) for action in [GovernanceAction(lane_id="A", commanded_profile="nominal", target_fragility_class=meta_class)]]
    )
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write(meta_map.model_dump_json(indent=2))
        
    print(f"Meta-telemetry generated: {output_path}")
    print(f"Meta Suggested Action: {suggested_action}")
    print(f"Fragment added to meta-history.")



if __name__ == "__main__":
    generate_meta_telemetry(
        "output/metallurgical_validation_results.json",
        "output/lane_d_meta_telemetry.json"
    )
