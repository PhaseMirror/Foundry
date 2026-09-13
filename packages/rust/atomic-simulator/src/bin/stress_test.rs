//! Port of `atomic-calculator/stress_test_protocol.py` — three stress
//! scenarios, printed with the same `{===} title {===}` separators.

use atomic_simulator::CivicSimulator;

fn separator(title: &str) {
    println!("\n========== {title} ==========");
}

/// Grouped parameters passed to a single simulation step.
struct StepParams {
    factors: [f64; 4],
    lambda_m: f64,
    res: f64,
    emb: f64,
    c_t: f64,
}

/// Run a slice of engine steps over `[t_start, t_end)` and print each step.
fn run_phase(sim: &mut CivicSimulator, p: &StepParams, supply: &mut f64, t_start: i64, t_end: i64) {
    for _ in t_start..t_end {
        *supply = sim.step(&p.factors, p.lambda_m, p.res, p.emb, p.c_t, *supply);
        let r = &sim.history[sim.history.len() - 1];
        println!(
            "t={:02} | Scivic: {:.2} | V_MSC: ${:.3} | Supply: {:.1}",
            r.time, r.s_civic, r.v_msc, r.supply
        );
    }
}

fn scenario_node_failure_cascade() {
    separator("Scenario 1: Node-Failure Cascade");
    // Simulate instantaneous loss of an entire "Tribe" level (27 nodes).
    let mut sim = CivicSimulator::new();
    let mut supply = 10000.0;
    let c_t = 0.5;
    let mut factors = [1.5, 1.5, 1.5, 1.5]; // Start at Hundian Ground State

    println!("Pre-Crash: Sustained Equilibrium");
    run_phase(
        &mut sim,
        &StepParams {
            factors,
            lambda_m: 0.5,
            res: 1.0,
            emb: 1.0,
            c_t,
        },
        &mut supply,
        0,
        5,
    );

    println!("Crash Event: Loss of 27 nodes (Massive Resonance & Agency drop)");
    factors = [0.6, 0.6, 1.5, 1.5]; // Sharp drop in Resonance and Agency
    supply *= 0.8; // Sudden loss of supply capacity
    run_phase(
        &mut sim,
        &StepParams {
            factors,
            lambda_m: 0.5,
            res: 1.0,
            emb: 1.0,
            c_t,
        },
        &mut supply,
        5,
        10,
    );

    println!("Recovery: System isolates the failure and stabilizes");
    factors = [1.2, 1.2, 1.5, 1.5]; // Re-routing resonance
    run_phase(
        &mut sim,
        &StepParams {
            factors,
            lambda_m: 0.5,
            res: 1.0,
            emb: 1.0,
            c_t,
        },
        &mut supply,
        10,
        15,
    );
}

fn scenario_factor_drop() {
    separator("Scenario 2: Systemic Factor-Drop Event");
    // Systemic loss of one of the 4 "Minimal Core" factors (Integrity→0).
    let mut sim = CivicSimulator::new();
    let mut supply = 10000.0;
    let c_t = 0.5;
    let mut factors = [1.5, 1.5, 1.5, 1.5];

    println!("Baseline State");
    run_phase(
        &mut sim,
        &StepParams {
            factors,
            lambda_m: 0.5,
            res: 1.0,
            emb: 1.0,
            c_t,
        },
        &mut supply,
        0,
        1,
    );

    println!("Crisis Event: Integrity and Resilience crash grid-wide");
    factors = [1.5, 1.5, 0.1, 0.2]; // Integrity and Viability drop
    run_phase(
        &mut sim,
        &StepParams {
            factors,
            lambda_m: 0.5,
            res: 0.6,
            emb: 0.6,
            c_t,
        },
        &mut supply,
        1,
        10,
    );
}

fn scenario_oversaturation() {
    separator("Scenario 3: Hundian Over-Saturation (Bubble Event)");
    // Force a rapid, non-governed expansion.
    let mut sim = CivicSimulator::new();
    let mut supply = 10000.0;
    let c_t = 0.5;
    let mut factors = [1.5, 1.5, 1.5, 1.5];

    println!("Baseline State");
    run_phase(
        &mut sim,
        &StepParams {
            factors,
            lambda_m: 0.5,
            res: 1.0,
            emb: 1.0,
            c_t,
        },
        &mut supply,
        0,
        1,
    );

    println!("Bubble Event: Massive non-resonant expansion");
    factors = [2.5, 2.5, 2.5, 2.5]; // Unnatural inflation
    supply *= 2.0; // Artificial inflation
    run_phase(
        &mut sim,
        &StepParams {
            factors,
            lambda_m: 0.5,
            res: 1.2,
            emb: 1.2,
            c_t,
        },
        &mut supply,
        1,
        6,
    );

    println!("Governed Contraction: Phase Mirror triggers algorithm to return to cap");
    factors = [1.5, 1.5, 1.5, 1.5]; // Governance restores factors to true state
    run_phase(
        &mut sim,
        &StepParams {
            factors,
            lambda_m: 0.5,
            res: 1.0,
            emb: 1.0,
            c_t,
        },
        &mut supply,
        6,
        15,
    );
}

fn main() {
    scenario_node_failure_cascade();
    scenario_factor_drop();
    scenario_oversaturation();
}
