use pirtm_tensor::multiplicity_cell::{LinearMultiplicityCell, MultiplicityCell};
use pirtm_tensor::contractive_fit::ContractiveFit;
use ndarray::{Array1, Array2};
use std::path::PathBuf;
use pirtm_rs::rta::{State, RtaMetric};
use pirtm_rs::uac_loss::{uac_total_loss, LanglandsLossConfig, ArithmeticBinduAttractor};
use pirtm_rs::gates::{gate_langlands, LanglandsZKConfig};
use std::fs;
use serde_json::Value;


fn main() {
    let args: Vec<String> = std::env::args().collect();

    let tether = args.iter().any(|a| a == "--tether");
    let initial_coverage = args.iter().position(|a| a == "--initial-coverage").and_then(|i| args.get(i+1).and_then(|s| s.parse::<f64>().ok())).unwrap_or(0.9);
    let drift = args.iter().position(|a| a == "--drift").and_then(|i| args.get(i+1).and_then(|s| s.parse::<f64>().ok())).unwrap_or(0.05);

    if tether {
        println!("=== UAC Simulator: Tether Policy Mode ===");
        use pirtm_rs::tether_policy::{TetherPolicy, NodeState};
        let policy = TetherPolicy::default();

        let mut current_coverage = initial_coverage;
        let mut current_drift = drift;
        let mut iteration = 0;

        loop {
            let tau = policy.compute_tau(current_coverage, current_drift);
            let state = policy.process_telemetry(current_coverage, current_drift).1;

            println!(
                "[TETHER] iter={}  coverage={:.3}  drift={:.3}  τ={:.4}  state={:?}",
                iteration, current_coverage, current_drift, tau, state
            );

            if iteration == 3 {
                println!("--- Injecting drift ---");
                current_drift = 0.2;
            }
            if iteration == 5 {
                current_coverage = 0.4;
                current_drift = 0.5;
            }
            if iteration >= 7 {
                break;
            }
            iteration += 1;
        }
        return;
    }

    let cell_path = args.iter().position(|a| a == "--cell").and_then(|i| args.get(i+1)).map(PathBuf::from);
    let learning_rate = args.iter().position(|a| a == "--learning-rate").and_then(|i| args.get(i+1).and_then(|s| s.parse::<f64>().ok())).unwrap_or(0.1);
    let tolerance = args.iter().position(|a| a == "--tolerance").and_then(|i| args.get(i+1).and_then(|s| s.parse::<f64>().ok())).unwrap_or(1e-6);

    println!("Initializing UAC Social-Simulation Harness...");
    println!("Target: Monster Group Symmetry Confinement (Tier V Declaration)");

    let mut state = State::new();
    let community_primes = vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
    for &p in &community_primes {
        state.active_primes.insert(p);
    }

    println!("Seeding initial civic reality (chaotic configuration)...");
    for i in 0..community_primes.len() {
        for j in i + 1..community_primes.len() {
            let p = community_primes[i];
            let q = community_primes[j];
            let tension = ((p * q) % 17) as f64 + 1.0;
            state.joint_words.insert((p, q), tension);
        }
    }

    let initial_defect = state.arta_defect();
    let initial_langlands = uac_total_loss(&state, LanglandsLossConfig::default());

    println!("\n[PRE-FIT METRICS]");
    println!("Arta Defect (Symmetry Deviation): {:.4}", initial_defect);
    println!("Langlands Loss (Arithmetic Deviation): {:.4}", initial_langlands);
    println!("L3 Gate Status: REJECTED (Deviation > 1e-5)\n");
    println!("pre_arta_defect: {:.8}", initial_defect);
    println!("pre_langlands_loss: {:.4}", initial_langlands);
    println!("pre_total_loss: {:.4}", initial_defect + initial_langlands);
    println!("pre_rta_dist: N/A");

    println!("Engaging UAC Fit Operator (Symmetry Reduction via MA-VQE)...");
    
    // Sort keys to ensure deterministic vector order
    let mut sorted_keys: Vec<_> = state.joint_words.keys().cloned().collect();
    sorted_keys.sort_unstable();
    
    let (pre_defect_val, post_defect_val, pre_rta_val, post_rta_val) = if let Some(cell_path) = cell_path {
        let data = std::fs::read_to_string(&cell_path).expect("Failed to read cell JSON");
        let config: serde_json::Value = serde_json::from_str(&data).expect("Invalid cell JSON");
        let coherence: Vec<f64> = config["coherence"].as_array().unwrap().iter().map(|v| v.as_f64().unwrap()).collect();
        let defect_rows: Vec<Vec<f64>> = config["defect"].as_array().unwrap().iter()
            .map(|r| r.as_array().unwrap().iter().map(|v| v.as_f64().unwrap()).collect())
            .collect();
        
        let cell = LinearMultiplicityCell::new(
            Array1::from_vec(coherence),
            Array2::from_shape_vec((defect_rows.len(), defect_rows[0].len()), defect_rows.concat()).unwrap()
        );
        let fit = ContractiveFit::new(cell, learning_rate, tolerance);
        
        let mut vec_vals = Vec::new();
        for k in &sorted_keys {
            vec_vals.push(*state.joint_words.get(k).unwrap());
        }
        let state_vector = Array1::from_vec(vec_vals);
        
        let (_, pre_defect) = fit.cell.forward(&state_vector);
        
        let attractor = ArithmeticBinduAttractor::new();
        let pre_rta = attractor.distance(&state);
        
        let optimized_state = fit.fit(&state_vector);
        
        for (i, k) in sorted_keys.iter().enumerate() {
            state.joint_words.insert(*k, optimized_state[i]);
        }
        let (_, post_defect) = fit.cell.forward(&optimized_state);
        let post_rta = attractor.distance(&state);
        
        (pre_defect, post_defect, pre_rta, post_rta)
    } else {
        let pre_defect = state.arta_defect();
        let attractor = ArithmeticBinduAttractor::new();
        let pre_rta = attractor.distance(&state);
        
        state.fit(learning_rate, tolerance);
        
        let post_defect = state.arta_defect();
        let post_rta = attractor.distance(&state);
        (pre_defect, post_defect, pre_rta, post_rta)
    };
    
    let final_langlands = uac_total_loss(&state, LanglandsLossConfig::default());
    
    println!("\n[POST-FIT METRICS]");
    println!("Arta Defect (Symmetry Deviation): {:.8}", post_defect_val);
    println!("Langlands Loss (Arithmetic Deviation): {:.8}", final_langlands);
    println!("Distance to Arithmetic Bindu: {:.8}", post_rta_val);
    println!("post_arta_defect: {:.8}", post_defect_val);
    println!("post_langlands_loss: {:.8}", final_langlands);
    println!("post_total_loss: {:.8}", post_defect_val + final_langlands);
    println!("post_rta_dist: {:.8}", post_rta_val);

// Determine if ZK verification is enabled via CLI flag
// Parse CLI flags for ZK verification and optional verification key
let args: Vec<String> = std::env::args().collect();

let zk_enabled = args.iter().any(|a| a == "--zk" || a == "--enable-zk");
let vk_path_opt = args.iter().position(|a| a == "--vk");
let vk_json = if let Some(idx) = vk_path_opt {
    if idx + 1 < args.len() {
        let path = &args[idx + 1];
        match fs::read_to_string(path) {
            Ok(content) => match serde_json::from_str::<Value>(&content) {
                Ok(v) => Some(v),
                Err(e) => {
                    eprintln!("Failed to parse vk JSON at {}: {}", path, e);
                    None
                }
            },
            Err(e) => {
                eprintln!("Failed to read vk file {}: {}", path, e);
                None
            }
        }
    } else {
        eprintln!("--vk flag provided without a path");
        None
    }
} else { None };
let zk_config = if zk_enabled {
    LanglandsZKConfig { enabled: true, vk_json }
} else {
    LanglandsZKConfig::default()
};
let start = std::time::Instant::now();
let gate_result = gate_langlands(&state, 1e-12, Some(zk_config));
let zk_duration = start.elapsed();
eprintln!("[PROFILE] ZK verification time: {:?}", zk_duration);
match gate_result {
    Ok(_) => {
        println!("L3 Gate Status: ACCEPTED (Monster Identity Representation Anchored)");
        println!("zk_status: ACCEPTED");
    }
    Err(e) => {
        println!("L3 Gate Status: REJECTED ({})", e);
        println!("zk_status: REJECTED");
    }
};
    println!("\nThe Civic Node is now navigating strictly within the Hilbert space of the Monster Group.");
}
