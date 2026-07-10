use knot_in_time_core::{KnotHamiltonian, InvariantRegistry};

fn main() {
    let knot = KnotHamiltonian::new("3_1".to_string());
    println!("Coherence protection: {}", knot.get_coherence_protection());

    let drift = 0.10;
    match InvariantRegistry::audit_drift("CUSTODIAN_ITAR", "FACT", drift) {
        Ok(margin) => println!("Audit pass. Margin: {:.4}", margin),
        Err(e) => println!("Audit failed: {}", e),
    }
}
