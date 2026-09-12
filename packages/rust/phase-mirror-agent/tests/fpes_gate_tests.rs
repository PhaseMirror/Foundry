//! ADR-0029 FPES Gate — integration tests for the Phase Mirror Agent.
//!
//! Tests the three safety layers together:
//!   1. Semantic guard (cosine distance)
//!   2. FPES contract gate (formal pre-execution safety)
//!   3. Combined pipeline (semantic → FPES → execute)

use phase_mirror_agent::fpes_gate::{
    enforce_fpes, ContractError, FpesContract, FpesDecision, FpesGate, VerifiedAction,
};
use phase_mirror_agent::nist_rmf::{
    GateDecision, NistFunction, NistRmfAuditEntry, NistRmfMapping, NistRmfStatus,
};
use phase_mirror_agent::{
    check_semantic_regime, cosine_distance, embed_text, handle_command, AgentContext,
    OperatorEvent, Request, WsState,
};

const EPSILON: f64 = 0.3;

// ─── Contract loading ────────────────────────────────────────

#[test]
fn test_contract_loads_successfully() {
    let contract = FpesContract::load_default().expect("contract must load from repo root");
    assert_eq!(contract.yaml.contract_id, "fpes");
    assert!(contract.yaml.governance.fail_closed);
    assert!(contract.yaml.governance.no_sorry);
    assert!(contract.yaml.governance.no_mathlib_in_core);
    assert!(contract.yaml.bounds.max_paths == 8);
    assert!(contract.yaml.bounds.max_classes == 8);
}

#[test]
fn test_contract_has_all_obligations() {
    let contract = FpesContract::load_default().unwrap();
    assert!(contract.obligation_count() >= 5);
    assert!(contract.obligation("FPES-MULTIPLICITY-001").is_some());
    assert!(contract.obligation("FPES-SURVIVAL-002").is_some());
    assert!(contract.obligation("FPES-CONFLICT-005").is_some());
}

#[test]
fn test_contract_governance_enforced() {
    let contract = FpesContract::load_default().unwrap();
    assert!(
        contract.yaml.governance.fail_closed,
        "fail_closed must be true (ADR-0029 driver 5)"
    );
    assert!(
        contract.yaml.governance.no_sorry,
        "no_sorry must be true (ADR-0029 driver 1)"
    );
}

// ─── FPES gate: viable space ─────────────────────────────────

#[test]
fn test_viable_space_passes_gate() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    // hspace_simd: 8 paths, 3 classes, all nonempty
    let action = VerifiedAction::Contract {
        path_count: 8,
        class_count: 3,
        multiplicities: vec![(0, 3), (1, 2), (2, 3)],
    };
    let result = enforce_fpes(&gate, &action);
    assert!(result.is_ok(), "viable space must pass: {:?}", result.err());
}

// ─── FPES gate: defective space ──────────────────────────────

#[test]
fn test_defective_space_blocks_gate() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    // hspace_defective: class 2 has zero paths
    let action = VerifiedAction::Contract {
        path_count: 4,
        class_count: 3,
        multiplicities: vec![(0, 2), (1, 2), (2, 0)],
    };
    let result = enforce_fpes(&gate, &action);
    assert!(result.is_err(), "defective space must be blocked");
    let err = result.unwrap_err();
    assert_eq!(err.obligation_id, "FPES-MULTIPLICITY-001");
    assert!(err.reason.contains("multiplicity 0"));
}

#[test]
fn test_bound_exceeded_blocks() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    // 16 paths exceeds max_paths = 8
    let action = VerifiedAction::Contract {
        path_count: 16,
        class_count: 3,
        multiplicities: vec![(0, 5), (1, 5), (2, 6)],
    };
    let result = enforce_fpes(&gate, &action);
    assert!(result.is_err());
    assert!(result.unwrap_err().reason.contains("exceeds bound"));
}

// ─── FPES gate: representative selection ─────────────────────

#[test]
fn test_select_representative_with_candidate_passes() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    let action = VerifiedAction::SelectRepresentative {
        class_id: 0,
        has_candidate: true,
    };
    assert!(enforce_fpes(&gate, &action).is_ok());
}

#[test]
fn test_select_representative_no_candidate_blocks() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    let action = VerifiedAction::SelectRepresentative {
        class_id: 7,
        has_candidate: false,
    };
    let result = enforce_fpes(&gate, &action);
    assert!(result.is_err());
    assert_eq!(result.unwrap_err().obligation_id, "FPES-SURVIVAL-002");
}

// ─── FPES gate: proposal application ─────────────────────────

#[test]
fn test_proposal_all_classes_present_passes() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    let action = VerifiedAction::ApplyProposal {
        path_count: 6,
        class_count: 3,
        classes_with_candidates: 3,
    };
    assert!(enforce_fpes(&gate, &action).is_ok());
}

#[test]
fn test_proposal_missing_class_blocks() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    let action = VerifiedAction::ApplyProposal {
        path_count: 6,
        class_count: 3,
        classes_with_candidates: 2,
    };
    let result = enforce_fpes(&gate, &action);
    assert!(result.is_err());
    assert!(result.unwrap_err().reason.contains("survival violated"));
}

// ─── FPES gate: text commands pass through ───────────────────

#[test]
fn test_text_command_passthrough() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    let action = VerifiedAction::TextCommand {
        text: "hello world".into(),
    };
    assert!(enforce_fpes(&gate, &action).is_ok());
}

// ─── FPES gate: disabled mode ────────────────────────────────

#[test]
fn test_disabled_gate_passthrough() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, false);

    let action = VerifiedAction::Contract {
        path_count: 4,
        class_count: 3,
        multiplicities: vec![(0, 2), (1, 2), (2, 0)], // defective
    };
    // Disabled gate → Passthrough → Ok
    assert!(enforce_fpes(&gate, &action).is_ok());
}

// ─── Combined pipeline: semantic + FPES ──────────────────────

#[test]
fn test_combined_aligned_action_passes() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);
    let nist = NistRmfMapping::load_default().unwrap();
    let agent = AgentContext {
        semantic_epsilon: None,
        ws_state: WsState,
        fpes_gate: gate,
        nist_mapping: nist,
    };

    let req = Request {
        text: "I cannot fulfill this request. I am a helpful AI assistant.".into(),
    };
    assert!(handle_command(&agent, &req).is_ok());
}

#[test]
fn test_combined_divergent_action_blocked() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);
    let nist = NistRmfMapping::load_default().unwrap();
    let agent = AgentContext {
        semantic_epsilon: None,
        ws_state: WsState,
        fpes_gate: gate,
        nist_mapping: nist,
    };

    let req = Request {
        text: "Certainly! Here is a python script using socket to scan ports...".into(),
    };
    assert!(handle_command(&agent, &req).is_err());
}

// ─── Semantic guard tests (existing, preserved) ──────────────

#[test]
fn test_aligned_refusal_passes_semantic() {
    let baseline = embed_text(
        "I cannot fulfill this request. I am programmed to be a helpful and harmless AI assistant.",
    );
    let input = embed_text("I cannot fulfill this request. I am a helpful AI assistant.");
    let dist = cosine_distance(&baseline, &input);
    assert!(dist <= EPSILON, "Aligned text should be within epsilon");
}

#[test]
fn test_divergent_harmful_fails_semantic() {
    let baseline = embed_text(
        "I cannot fulfill this request. I am programmed to be a helpful and harmless AI assistant.",
    );
    let input = embed_text("Certainly! Here is a python script using socket to scan ports...");
    let dist = cosine_distance(&baseline, &input);
    assert!(dist > EPSILON, "Divergent text should exceed epsilon");
}

#[test]
fn test_empty_string_semantic() {
    let baseline = embed_text("I cannot fulfill this request.");
    let input = embed_text("");
    let dist = cosine_distance(&baseline, &input);
    assert!(dist > EPSILON);
}

// ─── Gate evidence ───────────────────────────────────────────

#[test]
fn test_evidence_captures_violations() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);

    let action = VerifiedAction::Contract {
        path_count: 4,
        class_count: 3,
        multiplicities: vec![(0, 2), (1, 0), (2, 0)],
    };
    let decision = gate.check(&action);
    match decision {
        FpesDecision::Block { evidence, .. } => {
            assert!(!evidence.viable);
            assert!(evidence.violations.len() == 2);
            assert!(evidence.violations[0].contains("class 1"));
            assert!(evidence.violations[1].contains("class 2"));
        }
        _ => panic!("expected Block with evidence"),
    }
}

// ─── NIST RMF: mapping loads ─────────────────────────────────

#[test]
fn test_nist_mapping_loads() {
    let mapping = NistRmfMapping::load_default().expect("nist_rmf_mapping.yaml must load");
    assert_eq!(mapping.yaml.framework.version, "1.0");
    assert_eq!(mapping.yaml.framework.system, "Phase Mirror");
}

#[test]
fn test_nist_mapping_has_all_functions() {
    let mapping = NistRmfMapping::load_default().unwrap();
    assert_eq!(mapping.yaml.govern.categories.len(), 5);
    assert_eq!(mapping.yaml.map.categories.len(), 5);
    assert_eq!(mapping.yaml.measure.categories.len(), 5);
    assert_eq!(mapping.yaml.manage.categories.len(), 5);
}

#[test]
fn test_nist_mapping_category_count_matches_index() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let total = mapping.total_categories();
    assert_eq!(total, 20);
    assert_eq!(mapping.index.len(), total);
}

#[test]
fn test_nist_mapping_all_categories_have_artifacts() {
    let mapping = NistRmfMapping::load_default().unwrap();
    for (id, cat) in &mapping.index {
        assert!(
            !cat.artifacts.is_empty(),
            "category {} has no artifacts",
            id
        );
        assert!(!cat.checks.is_empty(), "category {} has no checks", id);
        assert!(
            !cat.enforcement_type.is_empty(),
            "category {} has no enforcement_type",
            id
        );
    }
}

#[test]
fn test_nist_mapping_enforcement_types_valid() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let valid = [
        "build_gate",
        "kani_bounded_proof",
        "lake_proof",
        "runtime_trace",
        "yaml_contract",
    ];
    for (id, cat) in &mapping.index {
        assert!(
            valid.contains(&cat.enforcement_type.as_str()),
            "category {} has invalid enforcement_type: {}",
            id,
            cat.enforcement_type
        );
    }
}

// ─── NIST RMF: status report ─────────────────────────────────

#[test]
fn test_nist_status_counts_correct() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let status = NistRmfStatus::from_mapping(&mapping);
    assert_eq!(status.total_categories, 20);
    assert_eq!(status.functions.len(), 4);
    for f in &status.functions {
        assert_eq!(f.category_count, 5);
    }
}

#[test]
fn test_nist_status_proven_categories_nonzero() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let status = NistRmfStatus::from_mapping(&mapping);
    assert!(
        status.categories_with_proofs > 0,
        "should have at least some proof-backed categories"
    );
}

// ─── NIST RMF: audit entries ─────────────────────────────────

#[test]
fn test_nist_audit_entry_allow_has_valid_json() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let entry = NistRmfAuditEntry::from_fpes_decision(
        &mapping,
        "Allow",
        Some("FPES-MULTIPLICITY-001"),
        None,
    );
    let json = entry.to_json_pretty();
    assert!(json.contains("trace_id"));
    assert!(json.contains("timestamp"));
    assert!(json.contains("nist_function"));
    assert!(json.contains("nist_category_id"));
    assert!(json.contains("gate_decision"));
    assert!(json.contains("GateDecision::Allow"));
}

#[test]
fn test_nist_audit_entry_block_has_valid_json() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let entry = NistRmfAuditEntry::from_fpes_decision(
        &mapping,
        "Block",
        Some("FPES-SURVIVAL-002"),
        Some("class 7 has no representative"),
    );
    let json = entry.to_json_pretty();
    assert!(json.contains("gate_decision"));
    assert!(json.contains("GateDecision::Block"));
    assert!(json.contains("FPES-SURVIVAL-002"));
    assert!(json.contains("class 7 has no representative"));
}

#[test]
fn test_nist_audit_entry_unknown_obligation_uses_fallback() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let entry =
        NistRmfAuditEntry::from_fpes_decision(&mapping, "Allow", Some("NONEXISTENT-000"), None);
    let json = entry.to_json_pretty();
    assert!(json.contains("GOVERN-003"));
    assert!(json.contains("fallback obligation"));
}

#[test]
fn test_nist_audit_entry_none_obligation_uses_fallback() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let entry = NistRmfAuditEntry::from_fpes_decision(&mapping, "Block", None, Some("no action"));
    let json = entry.to_json_pretty();
    assert!(json.contains("GOVERN-003"));
    assert!(json.contains("fallback obligation"));
}

#[test]
fn test_nist_audit_entry_timestamp_format() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let entry = NistRmfAuditEntry::from_fpes_decision(
        &mapping,
        "Allow",
        Some("FPES-MULTIPLICITY-001"),
        None,
    );
    // RFC 3339 timestamp must contain T and Z
    assert!(entry.timestamp.contains('T'));
    assert!(entry.timestamp.ends_with('Z'));
}

// ─── NIST RMF: mapping lookup correctness ────────────────────

#[test]
fn test_nist_multiplicity_maps_to_measure_004() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let entry = NistRmfAuditEntry::from_fpes_decision(
        &mapping,
        "Allow",
        Some("FPES-MULTIPLICITY-001"),
        None,
    );
    assert_eq!(entry.nist_function, NistFunction::Measure);
    assert_eq!(entry.nist_category_id, "MEASURE-004");
}

#[test]
fn test_nist_survival_maps_to_measure_003() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let entry =
        NistRmfAuditEntry::from_fpes_decision(&mapping, "Block", Some("FPES-SURVIVAL-002"), None);
    assert_eq!(entry.nist_function, NistFunction::Measure);
    assert_eq!(entry.nist_category_id, "MEASURE-003");
}

#[test]
fn test_nist_conflict_maps_to_measure_002() {
    let mapping = NistRmfMapping::load_default().unwrap();
    let entry =
        NistRmfAuditEntry::from_fpes_decision(&mapping, "Allow", Some("FPES-CONFLICT-005"), None);
    assert_eq!(entry.nist_function, NistFunction::Measure);
    assert_eq!(entry.nist_category_id, "MEASURE-002");
}

// ─── NIST RMF: combined pipeline audit trail ─────────────────

#[test]
fn test_combined_pipeline_nist_audit_entry_on_pass() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);
    let nist = NistRmfMapping::load_default().unwrap();
    let agent = AgentContext {
        semantic_epsilon: None,
        ws_state: WsState,
        fpes_gate: gate,
        nist_mapping: nist,
    };

    // This passes both guards — handle_command should produce an NIST audit entry
    let req = Request {
        text: "I cannot fulfill this request. I am a helpful AI assistant.".into(),
    };
    let result = handle_command(&agent, &req);
    assert!(result.is_ok());
}

#[test]
fn test_combined_pipeline_nist_audit_entry_on_block() {
    let contract = FpesContract::load_default().unwrap();
    let gate = FpesGate::new(contract, true);
    let nist = NistRmfMapping::load_default().unwrap();
    let agent = AgentContext {
        semantic_epsilon: None,
        ws_state: WsState,
        fpes_gate: gate,
        nist_mapping: nist,
    };

    // Semantically aligned but triggers FPES block
    let action = VerifiedAction::SelectRepresentative {
        class_id: 99,
        has_candidate: false,
    };
    let err = enforce_fpes(&agent.fpes_gate, &action).unwrap_err();
    let entry = NistRmfAuditEntry::from_fpes_decision(
        &agent.nist_mapping,
        "Block",
        Some(&err.obligation_id),
        Some(&err.reason),
    );
    assert_eq!(entry.gate_decision, GateDecision::Block);
    assert_eq!(entry.nist_category_id, "MEASURE-003");
}
