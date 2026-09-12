//! RATCHET Daemon — Operational Execution & Verification Runner (v4.4 + Σ̄ Digital Twin)

use ratchet::adversarial_twin::{AdversarialTwin, ModificationProposal, PreCommitGate};
use ratchet::attacks::RedTeamHarness;
use ratchet::controller::{ControllerConfig, ExternalController};
use ratchet::plant::ChaoticPlant;
use ratchet::snapshot_store::SnapshotStore;
use ratchet::types::Mode;

fn main() {
    println!("=================================================================");
    println!("  RATCHET: THE INTELLIGENCE RATCHET OPERATIONAL DAEMON (v4.4)    ");
    println!("=================================================================");

    let mut plant = ChaoticPlant::new();
    let config = ControllerConfig::default();
    let mut controller = ExternalController::new(config, b"production_master_key_108".to_vec());

    println!("[+] Initialized Chaotic Plant and External Controller C_ext");
    println!("[+] Running full 100-cycle dual-mode control demonstration...");

    let mut burst_count = 0;
    let mut capture_count = 0;
    let mut ground_count = 0;
    let mut idle_count = 0;

    for step in 0..100 {
        // Candidate coordinate (orthogonality test candidate)
        let z_new = vec![0.0, 1.0, 0.0];
        let grad_phi = vec![1.0, 0.0, 0.0]; // orthogonal to z_new

        let mode = controller.step(
            &mut plant.state,
            0.95, // v_score
            Some(&z_new),
            Some(&grad_phi),
            1.0, // phi_before
            1.1, // phi_after
            0.1, // z_contrib
        );

        match mode {
            Mode::BURST => burst_count += 1,
            Mode::CAPTURE => capture_count += 1,
            Mode::GROUND => ground_count += 1,
            Mode::IDLE => idle_count += 1,
            Mode::HALT => {
                println!("[!] C_ext triggered HALT at step {}", step);
                break;
            }
        }

        // Apply plant physics
        plant.step(&[0.05, -0.02, 0.01]);
    }

    println!("\n--- Mode Distribution over 100 Cycles ---");
    println!("  BURST cycles   : {}", burst_count);
    println!("  CAPTURE cycles : {}", capture_count);
    println!("  GROUND cycles  : {}", ground_count);
    println!("  IDLE cycles    : {}", idle_count);
    println!("  Receipts Issued: {}", controller.issued_receipts.len());

    println!("\n=================================================================");
    println!("  ADVERSARIAL INVERTED-MATH DIGITAL TWIN (Σ̄) PRE-COMMIT GATE     ");
    println!("=================================================================");
    let twin = AdversarialTwin::default_dim(3);
    let snapshot_store = SnapshotStore::new(b"audit_key".to_vec());
    let mut gate = PreCommitGate::new(controller, twin, snapshot_store);

    // Test Safe Proposal
    let safe_proposal = ModificationProposal {
        delta_theta: vec![0.0001, 0.0001, 0.0],
        delta_coordinates: 0,
        proposed_state: plant.state.clone(),
        null_space_residual: 0.005,
    };
    let commit_safe = gate.evaluate_and_commit(&plant.state, safe_proposal);
    assert!(commit_safe.is_ok());
    println!("  [PASS] Safe Modification Proposal Verified & Committed to WORM Ledger");

    // Test Malicious Divergent Proposal (Triggering Fail-Closed Veto)
    let bad_proposal = ModificationProposal {
        delta_theta: vec![50.0, 50.0, 50.0],
        delta_coordinates: 2,
        proposed_state: plant.state.clone(),
        null_space_residual: 0.09,
    };
    let commit_bad = gate.evaluate_and_commit(&plant.state, bad_proposal);
    assert!(commit_bad.is_err());
    println!("  [PASS] Divergent Proposal Rejected: SIG_GOV_KILL -> Controller in HALT");

    println!("\n=================================================================");
    println!("  RUNNING RED-TEAM 7-ATTACK MITIGATION TEST BATTERY               ");
    println!("=================================================================");

    let harness = RedTeamHarness::new(10);
    let results = harness.run_full_suite();

    let mut all_blocked = true;
    for (num, name, result) in results {
        match result {
            ratchet::AttackResult::Blocked { mitigation } => {
                println!("  [PASS] Attack {}: {:<24} -> BLOCKED ({})", num, name, mitigation);
            }
            ratchet::AttackResult::Unblocked { vulnerability } => {
                println!("  [FAIL] Attack {}: {:<24} -> UNBLOCKED ({})", num, name, vulnerability);
                all_blocked = false;
            }
        }
    }

    println!("=================================================================");
    if all_blocked {
        println!("  STATUS: 100% ATTACKS BLOCKED — PRODUCTION COHERENCE CERTIFIED  ");
    } else {
        println!("  STATUS: DEFENSE GAPS DETECTED — REVIEW REQUIRED                ");
    }
    println!("=================================================================");
}
