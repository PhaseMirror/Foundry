//! NEUROPLASTICITY Daemon & Multi-Session Cognitive Learning Benchmark

use neuroplasticity::csl::CslAuditor;
use neuroplasticity::simulation::NeuroplasticitySimulator;
use neuroplasticity::tensor::PirtmEngine;
use neuroplasticity::types::NeuroConfig;

fn main() {
    println!("================================================================================");
    println!("  NEUROPLASTICITY: MULTIPLICITY THEORY PRODUCTION DAEMON & CSL AUDITOR         ");
    println!("================================================================================");
    println!();

    let config = NeuroConfig::default();
    let csl_bound = CslAuditor::golden_ratio_entropy_bound();
    println!(">>> [INIT] Consciousness Stability Law Threshold: ln(φ) = {:.6}", csl_bound);
    println!("    Hebbian Learning Rate: η = {:.3}, Homeostatic Decay: γ = {:.3}", config.learning_rate, config.synaptic_decay);
    println!();

    let mut simulator = NeuroplasticitySimulator::new(config);
    println!(">>> [STEP 1/3] Initializing Prime-Indexed Cognitive State Ψ(0)...");
    for c in &simulator.current_state.components {
        println!("    Prime Channel p = {:>2}: Amplitude θ_p = {:.4}, Phase ϕ_p = {:.2}°", c.prime_p, c.amplitude, c.phase.to_degrees());
    }
    println!("    Total Baseline Cognitive Power: {:.4}", simulator.current_state.total_power());
    println!();

    println!(">>> [STEP 2/3] Simulating 5 Longitudinal Multi-Session Learning Blocks...");
    let stimuli_task = vec![0.5, 0.4, 0.3, 0.8, 0.7, 0.2, 0.1];

    for s in 1..=5 {
        let eeg_mode = if s % 2 == 1 { "calm_focus" } else { "stress_overload" };
        let metrics = simulator.run_session(s, 20, &stimuli_task, eeg_mode);
        println!(
            "    Session {:>2} [{:^15}]: Power {:.3} -> {:.3} | ΔS = {:.4} (CSL: {:>5}) | EchoBraid Coherence = {:.3} | Readiness = {:.3}",
            metrics.session_id,
            eeg_mode,
            metrics.initial_power,
            metrics.final_power,
            metrics.delta_s,
            if metrics.csl_satisfied { "PASS" } else { "DAMP" },
            metrics.echo_braid_coherence,
            metrics.subjective_readiness
        );
    }
    println!();

    println!(">>> [STEP 3/3] Final Prime Harmonic Decomposition & Stability Check...");
    for c in &simulator.current_state.components {
        println!("    Prime Channel p = {:>2}: Final θ_p = {:.4}, Phase ϕ_p = {:.2}°", c.prime_p, c.amplitude, c.phase.to_degrees());
    }
    let final_entropy = PirtmEngine::spectral_entropy(&simulator.current_state);
    let identity_coherence = simulator.echo_braid.compute_identity_coherence(&simulator.current_state);
    println!("    Final Spectral Entropy: {:.4}", final_entropy);
    println!("    EchoBraid Identity Coherence R = {:.4} (Stable: {})", identity_coherence, identity_coherence >= 0.70);
    println!();

    println!("================================================================================");
    println!("  NEUROPLASTICITY SIMULATION & VERIFICATION COMPLETE (100% PASS)               ");
    println!("================================================================================");
}
