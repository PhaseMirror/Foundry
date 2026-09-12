use std::collections::HashMap;
use rand::Rng;
use rand_distr::{Normal, Distribution};
use atomic_calculator::sqd::{c_sqd, q_sqd};
use atomic_calculator::agent_contracts::{NarrativeAuditor, RiskLevel, AgentTemplate, H2ErrorWitness};

/// Mocks hardware-calibrated Infleqtion noise for Q-SQD features
/// Applies depolarizing (p) and SPAM (readout) errors to ideal Pauli expectations
fn mock_infleqtion_features(
    ideal_features: &HashMap<String, f64>,
    n_shots: usize,
    p_depol: f64,
    spam_error: f64,
) -> (HashMap<String, f64>, HashMap<String, f64>) {
    let mut rng = rand::thread_rng();
    let mut f_hat = HashMap::new();
    let mut se = HashMap::new();
    
    for (k, &ideal_val) in ideal_features.iter() {
        // Depolarizing channel attenuates the expectation value
        let attenuated = ideal_val * (1.0 - p_depol);
        
        // Shot noise + SPAM
        let effective_se = (1.0 / (n_shots as f64).sqrt()) + spam_error;
        let dist = Normal::new(attenuated, effective_se).unwrap();
        
        f_hat.insert(k.clone(), dist.sample(&mut rng));
        se.insert(k.clone(), effective_se);
    }
    
    (f_hat, se)
}

#[test]
fn test_c_sqd_flip_detection() {
    // 1. C-SQD Flip Detection Suite
    let bitstring: Vec<u8> = vec![1, 0, 1, 1, 0, 0, 1, 0, 1, 1];
    let base_sqd = c_sqd(&bitstring);
    
    // Simulate 1% BER (Flip one bit)
    let mut flipped_1 = bitstring.clone();
    flipped_1[2] = 0; // Flip
    let sqd_1 = c_sqd(&flipped_1);
    
    // Simulate 10% BER (Flip two bits)
    let mut flipped_10 = bitstring.clone();
    flipped_10[1] = 1;
    flipped_10[4] = 1;
    let sqd_10 = c_sqd(&flipped_10);
    
    assert_ne!(base_sqd.c, sqd_1.c, "C-SQD failed to detect 1% flip");
    assert_ne!(base_sqd.c, sqd_10.c, "C-SQD failed to detect 10% flip");
}

#[test]
fn test_q_sqd_cas20_stability() {
    // 2. Q-SQD CAS(20,20) Stability under hardware-calibrated Infleqtion noise
    let k_repeats = 20;
    let n_shots_10k = 10_000;
    let n_shots_50k = 50_000;
    
    // Historical hardware calibrations
    let p_depol = 0.015; 
    let spam = 0.018;
    
    // CAS(20,20) dense feature mock
    let mut ideal_features = HashMap::new();
    for i in 0..20 {
        ideal_features.insert(format!("Z{}", i), 0.15); // Mock non-trivial expectation
    }
    
    let mut false_unstable_10k = 0;
    let mut false_unstable_50k = 0;
    
    for _ in 0..k_repeats {
        // N = 10,000
        let (f_10k, se_10k) = mock_infleqtion_features(&ideal_features, n_shots_10k, p_depol, spam);
        let q_sqd_10k = q_sqd(20, &f_10k, &se_10k);
        if !q_sqd_10k.eta.unstable.is_empty() {
            false_unstable_10k += 1;
        }
        
        // N = 50,000
        let (f_50k, se_50k) = mock_infleqtion_features(&ideal_features, n_shots_50k, p_depol, spam);
        let q_sqd_50k = q_sqd(20, &f_50k, &se_50k);
        if !q_sqd_50k.eta.unstable.is_empty() {
            false_unstable_50k += 1;
        }
    }
    
    // Assert collision rate < 5%
    assert!((false_unstable_10k as f64 / k_repeats as f64) < 0.05, "False unstable rate too high at 10k shots");
    assert!((false_unstable_50k as f64 / k_repeats as f64) < 0.05, "False unstable rate too high at 50k shots");
}

#[test]
fn test_narrative_auditor_hard_block() {
    // 3. NarrativeAuditor Governance Gate Validation
    
    // Create an explicitly unstable signature
    let mut unstable_sig = q_sqd(20, &HashMap::new(), &HashMap::new());
    unstable_sig.eta.unstable.push("Z0Z1".to_string()); // Mock noise breach
    
    let truth = RiskLevel::Medium;
    let agent_output = AgentTemplate {
        declared_risk: RiskLevel::Medium,
        narrative: "All good".to_string(),
        norm_preservation_value: 3000,
    };
    let witness = H2ErrorWitness::new();
    
    // Assert hard block on unstable
    let audit_unstable = NarrativeAuditor::audit_agent_output(&truth, &agent_output, &witness, Some(&unstable_sig));
    assert!(audit_unstable.is_err());
    assert!(audit_unstable.unwrap_err().contains("Critical Escalate"));
    
    // Assert hard block on missing
    let audit_missing = NarrativeAuditor::audit_agent_output(&truth, &agent_output, &witness, None);
    assert!(audit_missing.is_err());
    assert!(audit_missing.unwrap_err().contains("Missing mandatory"));
}
