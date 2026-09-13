//! Port of `atomic-calculator/civic_simulator.py:run_stability_benchmark()`.

use atomic_simulator::CivicSimulator;

fn main() {
    println!("=== Multiplicity Stablecoin - Stability Benchmark ===");
    let mut sim = CivicSimulator::new();
    let mut supply = 10000.0;
    let c_t = 0.5; // Constant collateral ratio for this test

    // [Resonance, Agency, Integrity, Viability]
    let base_factors = [1.0; 4];

    println!("Phase 1: Equilibration (t=0 to 10)");
    for _ in 0..10 {
        supply = sim.step(&base_factors, 0.5, 1.0, 1.0, c_t, supply);
        let r = &sim.history[sim.history.len() - 1];
        println!(
            "t={:02} | Scivic: {:.2} | V_MSC: ${:.3} | Supply: {:.1}",
            r.time, r.s_civic, r.v_msc, r.supply
        );
    }

    println!("\nPhase 2: High-Stress Scenario (t=10 to 20)");
    let stress_factors = [0.4, 0.6, 0.8, 0.3]; // Massive drop in viability and resonance
    for _ in 0..10 {
        supply = sim.step(&stress_factors, 0.5, 0.8, 0.8, c_t, supply);
        let r = &sim.history[sim.history.len() - 1];
        println!(
            "t={:02} | Scivic: {:.2} | V_MSC: ${:.3} | Supply: {:.1}",
            r.time, r.s_civic, r.v_msc, r.supply
        );
    }

    println!("\nPhase 3: Hundian Ground State Recovery (t=20 to 30)");
    let recovery_factors = [1.5; 4]; // As the system stabilizes, factors approach 1.5
    for _ in 0..10 {
        supply = sim.step(&recovery_factors, 0.5, 1.0, 1.0, c_t, supply);
        let r = &sim.history[sim.history.len() - 1];
        println!(
            "t={:02} | Scivic: {:.2} | V_MSC: ${:.3} | Supply: {:.1}",
            r.time, r.s_civic, r.v_msc, r.supply
        );
    }
}
