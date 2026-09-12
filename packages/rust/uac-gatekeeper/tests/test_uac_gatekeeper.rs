use uac_gatekeeper::*;

fn make_valid_token() -> Token {
    Token {
        token_id: 1001,
        proof_debt: ProofDebt {
            debt_count: 0,
            is_uncertified: false,
            lever_id: None,
        },
        expiry_timestamp: 1800000000,
        signature: "SIG_VALID_TOKEN_1001".to_string(),
    }
}

fn make_valid_cert() -> ALPCertificate {
    ALPCertificate {
        theorem_name: "PhaseMirror.CareViability.viable_circle_prevents_burnout".to_string(),
        is_axiom_clean: true,
        witness_hash: "WITNESS_HASH_ALP_001".to_string(),
    }
}

#[test]
fn test_inv_uac_01_proof_debt_rejection() {
    let mut gatekeeper = UacAlpGatekeeper::new(ManifestValidator::new());
    let st = UACState::default();

    let mut bad_token = make_valid_token();
    bad_token.proof_debt.debt_count = 3; // Active debt

    let cert = make_valid_cert();
    let decision = gatekeeper.evaluate_authorization(&st, &bad_token, &cert);

    match decision {
        GovernanceDecision::FailClosedHalt { conflict } => {
            assert_eq!(conflict.breach_kind, "PROOF_DEBT_GATE_BREACH");
            assert!(conflict.is_fail_closed);
        }
        GovernanceDecision::Lawful { .. } => panic!("Expected rejection on proof debt"),
    }
}

#[test]
fn test_inv_uac_01b_uncertified_lever_rejection() {
    let mut gatekeeper = UacAlpGatekeeper::new(ManifestValidator::new());
    let st = UACState::default();

    let mut uncertified_token = make_valid_token();
    uncertified_token.proof_debt.is_uncertified = true;

    let cert = make_valid_cert();
    let decision = gatekeeper.evaluate_authorization(&st, &uncertified_token, &cert);

    match decision {
        GovernanceDecision::FailClosedHalt { conflict } => {
            assert_eq!(conflict.breach_kind, "PROOF_DEBT_GATE_BREACH");
            assert!(conflict.is_fail_closed);
        }
        GovernanceDecision::Lawful { .. } => panic!("Expected rejection on uncertified lever"),
    }
}

#[test]
fn test_inv_uac_02_axiom_cleanness_required() {
    let mut gatekeeper = UacAlpGatekeeper::new(ManifestValidator::new());
    let st = UACState::default();

    let tok = make_valid_token();
    let mut dirty_cert = make_valid_cert();
    dirty_cert.is_axiom_clean = false; // Axiom violation

    let decision = gatekeeper.evaluate_authorization(&st, &tok, &dirty_cert);

    match decision {
        GovernanceDecision::FailClosedHalt { conflict } => {
            assert_eq!(conflict.breach_kind, "AXIOM_CLEANNESS_VIOLATION");
            assert!(conflict.is_fail_closed);
        }
        GovernanceDecision::Lawful { .. } => panic!("Expected rejection on dirty certificate"),
    }
}

#[test]
fn test_inv_uac_03_hardware_interlock_latching() {
    let mut interlock = InterlockClient::new();
    assert_eq!(interlock.step(false, false), InterlockStatus::Normal);

    // Assert drift warning -> triggers L0Halt
    assert_eq!(interlock.step(false, true), InterlockStatus::L0Halt);

    // Drift clears, but fault must remain LATCHED until explicit reset
    assert_eq!(interlock.step(false, false), InterlockStatus::L0Halt);

    // Reset clears the latch
    interlock.reset();
    assert_eq!(interlock.step(false, false), InterlockStatus::Normal);
}

#[test]
fn test_inv_uac_04_petc_reversibility() {
    let original_codes = vec![72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100];
    let prime_tokens = decompose_graphemes(&original_codes);
    let reconstructed = reassemble_tokens(&prime_tokens);
    assert_eq!(original_codes, reconstructed);
}

#[test]
fn test_manifest_validator_loading() {
    let manifest_json = r#"{
        "lean/Multiplicity/dynamics/StableCoin.lean": [
            { "file": "lean/Multiplicity/dynamics/StableCoin.lean", "line": 49, "deadline": "2026-09-01" }
        ]
    }"#;

    let validator = ManifestValidator::from_json_str(manifest_json).unwrap();
    assert!(validator.has_proof_debt("lean/Multiplicity/dynamics/StableCoin.lean"));
    assert!(!validator.has_proof_debt("Care.lean"));
}

#[test]
fn test_lawful_authorization_witness() {
    let mut gatekeeper = UacAlpGatekeeper::new(ManifestValidator::new());
    let st = UACState::default();
    let tok = make_valid_token();
    let cert = make_valid_cert();

    let decision = gatekeeper.evaluate_authorization(&st, &tok, &cert);
    match decision {
        GovernanceDecision::Lawful { witness } => {
            assert!(witness.is_authorized);
            assert_eq!(witness.token_id, 1001);
            assert!(!witness.signature_hash.is_empty());
        }
        GovernanceDecision::FailClosedHalt { .. } => panic!("Expected lawful authorization"),
    }
}

#[test]
fn test_hardware_verilog_model_equivalence() {
    let mut interlock = InterlockClient::new();

    // Model Verilog cycle: always_ff @(posedge clk or negedge rst_n)
    let verilog_sim = |fault_latched: &mut bool, rst_n: bool, rho: bool, drift: bool| -> (bool, u32) {
        if !rst_n {
            *fault_latched = false;
        } else if rho || drift {
            *fault_latched = true;
        }
        let l0_halt = *fault_latched;
        let tdata = (if rho { 1 } else { 0 }) | (if drift { 2 } else { 0 });
        (l0_halt, tdata)
    };

    let mut v_fault = false;

    // Run 1000 simulated clock ticks
    for tick in 0..1000 {
        let rst_n = tick % 100 != 0; // periodic reset
        let rho = tick == 42 || tick == 550;
        let drift = tick == 200 || tick == 800;

        let (v_halt, _tdata) = verilog_sim(&mut v_fault, rst_n, rho, drift);
        let r_halt = if !rst_n {
            interlock.reset();
            InterlockStatus::Normal
        } else {
            interlock.step(rho, drift)
        };

        let r_halt_bool = r_halt == InterlockStatus::L0Halt;
        assert_eq!(v_halt, r_halt_bool, "Divergence at tick {}", tick);
    }
}

