use knot_in_time::sovereign_engine::FzsMkEngine;
use knot_in_time::{InvariantRegistry, KnotHamiltonian, StateTransition, Thresholds};

fn main() {
    let knot = KnotHamiltonian::new("3_1".to_string());
    println!("Coherence protection: {}", knot.get_coherence_protection());

    let thresholds = Thresholds::default();
    let drift = 0.10;
    match InvariantRegistry::audit_drift_with_thresholds(
        &thresholds,
        "CUSTODIAN_ITAR",
        "FACT",
        drift,
    ) {
        Ok(margin) => println!("Audit pass. Margin: {:.4}", margin),
        Err(e) => println!("Audit failed: {}", e),
    }

    let transition = StateTransition {
        id: "tx-helix-001".to_string(),
        r_sc: 47.06998778,
        l_eff: 0.15,
    };
    match InvariantRegistry::evaluate_transition(&thresholds, &transition) {
        Ok(state) => {
            println!(
                "Spectral state: r_sc={}, drift={}, l_eff={}",
                state.resonance_functional, state.drift, state.effective_lipschitz
            );
        }
        Err(e) => println!("Transition failed: {}", e),
    }

    let mut engine = FzsMkEngine::new(2);
    match engine.evaluate_spectral_state(&thresholds, transition) {
        Ok(state) => println!(
            "FZS-MK spectral evaluation passed: l_eff={}",
            state.effective_lipschitz
        ),
        Err(e) => println!("FZS-MK spectral evaluation failed: {}", e),
    }
}
